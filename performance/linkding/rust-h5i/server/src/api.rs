//! The linkding REST API (`/api/...`): each handler turns a request into a
//! kernel command and renders the reply in linkding's JSON shapes.
//!
//! Besides decoding, the shell validates request bodies (Django REST
//! framework's field errors), normalizes URLs, splits tag strings, parses
//! dates, reads the clock, builds the paging links, and counts a paged
//! listing with the read the kernel names (`list_count`). It reads nothing
//! else from the database. Every decision about the state is the kernel's,
//! including who the token belongs to.

use crate::logic::{
    archive_url, auth_detail, bookmark_tag_names, classify_auth, fmt_time, json_detail, normalize_url, page_links, page_params,
    parse_time, query_get, query_map, sort_names, validate_bookmark, validate_bundle, validate_tag, BookmarkIn, BundleIn,
    VERSION,
};
use crate::{principal, Linkding, LinkdingStore, LIST_COUNT};
use axum::body::Body;
use axum::extract::{Path, State};
use axum::http::{header, HeaderMap, Request, StatusCode};
use axum::response::{IntoResponse, Response};
use axum::routing::{get, post};
use axum::Router;
use chrono::{DateTime, Utc};
use h5i_app_pg::Engine;
use linkding_kernel as k;
use serde_json::{json, Map, Value};
use std::cell::Cell;
use std::sync::Arc;

#[derive(Clone)]
pub struct App {
    pub engine: Arc<Engine<Linkding, LinkdingStore>>,
}

pub fn router(app: App) -> Router {
    Router::new()
        .route("/healthz", get(|| async { "ok" }))
        .route(
            "/api/user/profile/",
            get(profile).put(profile_method).patch(profile_method).post(profile_method).delete(profile_method),
        )
        .route("/api/bookmarks/", get(bookmarks).post(bookmark_create))
        .route("/api/bookmarks/archived/", get(archived))
        .route("/api/bookmarks/shared/", get(shared))
        .route("/api/bookmarks/check/", get(bookmark_check))
        .route("/api/bookmarks/{id}/", get(bookmark_get).put(bookmark_write).patch(bookmark_write).delete(bookmark_delete))
        .route("/api/bookmarks/{id}/archive/", post(archive))
        .route("/api/bookmarks/{id}/unarchive/", post(unarchive))
        .route("/api/tags/", get(tags).post(tag_create))
        .route("/api/tags/{id}/", get(tag_get).delete(tag_delete))
        .route("/api/bundles/", get(bundles).post(bundle_create))
        .route("/api/bundles/{id}/", get(bundle_get).put(bundle_write).patch(bundle_write).delete(bundle_delete))
        .with_state(app)
}

/* Responses */

fn json_response(status: StatusCode, payload: Value, extra: &[(&str, &str)]) -> Response {
    let body = serde_json::to_vec(&payload).unwrap_or_else(|_| b"{}".to_vec());
    let mut response = Response::builder().status(status).header(header::CONTENT_TYPE, "application/json");
    for (key, value) in extra {
        response = response.header(*key, *value);
    }
    response
        .body(Body::from(body))
        .unwrap_or_else(|_| (StatusCode::INTERNAL_SERVER_ERROR, "server error").into_response())
}

fn auth_response(kind: &str) -> Response {
    json_response(StatusCode::UNAUTHORIZED, json!({"detail": auth_detail(kind)}), &[("WWW-Authenticate", "Token")])
}

#[derive(Clone, Copy)]
enum Kind {
    Bookmark,
    Tag,
    Bundle,
}

fn not_found(kind: Kind) -> Response {
    let message = match kind {
        Kind::Tag => "No Tag matches the given query.",
        Kind::Bundle => "No BookmarkBundle matches the given query.",
        Kind::Bookmark => "No Bookmark matches the given query.",
    };
    json_response(StatusCode::NOT_FOUND, json!({"detail": message}), &[])
}

fn server_error(err: impl std::fmt::Display) -> Response {
    eprintln!("request error: {err}");
    json_response(StatusCode::INTERNAL_SERVER_ERROR, json!({"detail": "Server error."}), &[])
}

fn refusal(err: k::Error, kind: Kind) -> Response {
    match err {
        k::Error::Unauthenticated => auth_response("absent"),
        k::Error::BadToken => auth_response("bad"),
        k::Error::NotFound => not_found(kind),
        k::Error::DuplicateUrl => {
            json_response(StatusCode::BAD_REQUEST, json!({"url": ["A bookmark with this URL already exists."]}), &[])
        }
        k::Error::Overflow => server_error("id overflow"),
    }
}

/* Requests */

/// The caller's token from `Authorization`: empty for a guest. A malformed
/// header is refused here, as linkding does before any lookup.
fn token(headers: &HeaderMap) -> Result<Vec<u8>, Response> {
    let raw = headers.get(header::AUTHORIZATION).and_then(|v| v.to_str().ok()).unwrap_or("");
    let (kind, token) = classify_auth(raw);
    match kind {
        "absent" => Ok(Vec::new()),
        "token" => Ok(token.into_bytes()),
        other => Err(auth_response(other)),
    }
}

async fn run(app: &App, token: &[u8], cmd: &k::Command) -> Result<Result<k::Reply, k::Error>, Response> {
    app.engine.execute(&principal(token.to_vec()), cmd).await.map_err(server_error)
}

/// A paged listing's reply with the count `load_for` took in its transaction.
async fn run_counted(app: &App, token: &[u8], cmd: &k::Command) -> (Result<Result<k::Reply, k::Error>, Response>, Option<u64>) {
    LIST_COUNT
        .scope(Cell::new(None), async {
            let r = run(app, token, cmd).await;
            (r, LIST_COUNT.with(Cell::get))
        })
        .await
}

/// Why a request with an invalid body is refused, when the kernel would
/// refuse it anyway: linkding checks the caller and the object first.
async fn refused_first(app: &App, token: &[u8], probe: k::Command, kind: Kind) -> Option<Response> {
    match run(app, token, &probe).await {
        Ok(Ok(_)) => None,
        Ok(Err(e)) => Some(refusal(e, kind)),
        Err(r) => Some(r),
    }
}

fn request_url(req: &Request<Body>) -> String {
    let host = req.headers().get(header::HOST).and_then(|v| v.to_str().ok()).unwrap_or("127.0.0.1");
    let path = req.uri().path_and_query().map(|v| v.as_str()).unwrap_or("/");
    format!("http://{host}{path}")
}

fn query_pairs(req: &Request<Body>) -> Vec<(String, String)> {
    query_map(req.uri().query().unwrap_or(""))
}

/// A path id; anything that is not a number names nothing (id 0).
fn path_id(raw: &str) -> u64 {
    if raw.is_empty() || !raw.bytes().all(|b| b.is_ascii_digit()) {
        return 0;
    }
    raw.parse::<u64>().unwrap_or(0)
}

async fn read_body(req: Request<Body>) -> Result<Map<String, Value>, Response> {
    let media = req
        .headers()
        .get(header::CONTENT_TYPE)
        .and_then(|v| v.to_str().ok())
        .unwrap_or("")
        .split(';')
        .next()
        .unwrap_or("")
        .trim()
        .to_ascii_lowercase();
    if media.is_empty() {
        return Ok(Map::new());
    }
    if media != "application/json" {
        return Err(json_response(
            StatusCode::UNSUPPORTED_MEDIA_TYPE,
            json!({"detail": format!("Unsupported media type \"{media}\" in request.")}),
            &[],
        ));
    }
    let bytes = axum::body::to_bytes(req.into_body(), 2 * 1024 * 1024).await.map_err(server_error)?;
    if bytes.is_empty() {
        return Ok(Map::new());
    }
    let value: Value = match serde_json::from_slice(&bytes) {
        Ok(v) => v,
        Err(_) => return Err(json_response(StatusCode::BAD_REQUEST, json!({"detail": json_detail(&bytes)}), &[])),
    };
    if value.is_null() {
        return Err(json_response(StatusCode::BAD_REQUEST, json!({"non_field_errors": ["No data provided"]}), &[]));
    }
    if let Value::Object(map) = value {
        return Ok(map);
    }
    let type_name = match &value {
        Value::Array(_) => "list",
        Value::String(_) => "str",
        Value::Bool(_) => "bool",
        Value::Number(n) if n.as_f64().is_some_and(|x| x.fract() != 0.0) => "float",
        Value::Number(_) => "int",
        _ => "str",
    };
    Err(json_response(
        StatusCode::BAD_REQUEST,
        json!({"non_field_errors": [format!("Invalid data. Expected a dictionary, but got {type_name}.")]}),
        &[],
    ))
}

/* Times */

fn micros(t: DateTime<Utc>) -> u64 {
    t.timestamp_micros().max(0) as u64
}

fn time_of(us: u64) -> DateTime<Utc> {
    DateTime::from_timestamp_micros(us as i64).unwrap_or_default()
}

fn now() -> u64 {
    micros(Utc::now())
}

/* Rendering */

fn text(t: &[u8]) -> String {
    String::from_utf8_lossy(t).into_owned()
}

fn bookmark_json(v: &k::BookmarkView) -> Value {
    let b = &v.bookmark;
    let mut names: Vec<String> = v.tags.iter().map(|t| text(t)).collect();
    sort_names(&mut names);
    let url = text(&b.url);
    json!({
        "id": b.id,
        "url": url,
        "title": text(&b.title),
        "description": text(&b.description),
        "notes": text(&b.notes),
        "web_archive_snapshot_url": archive_url(&url, time_of(b.added)),
        "favicon_url": Value::Null,
        "preview_image_url": Value::Null,
        "is_archived": b.archived,
        "unread": b.unread,
        "shared": b.shared,
        "tag_names": names,
        "date_added": fmt_time(time_of(b.added)),
        "date_modified": fmt_time(time_of(b.modified)),
        "website_title": Value::Null,
        "website_description": Value::Null,
    })
}

fn tag_json(t: &k::Tag) -> Value {
    json!({"id": t.id, "name": text(&t.name), "date_added": fmt_time(time_of(t.added))})
}

fn bundle_json(b: &k::Bundle) -> Value {
    json!({
        "id": b.id,
        "name": text(&b.name),
        "search": text(&b.search),
        "any_tags": text(&b.any_tags),
        "all_tags": text(&b.all_tags),
        "excluded_tags": text(&b.excluded_tags),
        "filter_unread": text(&b.filter_unread),
        "filter_shared": text(&b.filter_shared),
        "order": b.order as i64 - k::ORDER_BIAS as i64,
        "date_created": fmt_time(time_of(b.created)),
        "date_modified": fmt_time(time_of(b.modified)),
    })
}

fn profile_json(u: &k::User) -> Value {
    let prefs: Value = serde_json::from_slice(&u.search_prefs).unwrap_or_else(|_| json!({}));
    json!({
        "theme": text(&u.theme),
        "bookmark_date_display": text(&u.date_display),
        "bookmark_link_target": text(&u.link_target),
        "web_archive_integration": text(&u.web_archive),
        "tag_search": if u.lax { "lax" } else { "strict" },
        "enable_sharing": u.sharing,
        "enable_public_sharing": u.public_sharing,
        "enable_favicons": u.favicons,
        "display_url": u.display_url,
        "permanent_notes": u.permanent_notes,
        "search_preferences": prefs,
        "version": VERSION,
    })
}

fn page_json(url: &str, pairs: &[(String, String)], count: u64, results: Vec<Value>) -> Value {
    let (limit_bad, limit, offset_bad, offset) = page_params(pairs);
    let (next, prev) = page_links(url, count as i64, limit_bad, limit, offset_bad, offset);
    json!({"count": count, "next": next, "previous": prev, "results": results})
}

/// `limit` and `offset` as `page_of` settles them (they do not depend on the count).
fn limit_offset(pairs: &[(String, String)]) -> (u64, u64) {
    let (limit_bad, limit, offset_bad, offset) = page_params(pairs);
    let p = k::page_of(limit_bad, limit, offset_bad, offset, 0);
    (p.limit, p.offset)
}

/* Commands from requests */

fn bytes(s: &str) -> Vec<u8> {
    s.as_bytes().to_vec()
}

fn bookmark_fields(c: &BookmarkIn) -> k::BookmarkFields {
    let text_field = |name: &str, v: &String| if c.has(name) { Some(bytes(v)) } else { None };
    let flag = |name: &str, v: bool| if c.has(name) { Some(v) } else { None };
    let url = text_field("url", &c.url);
    k::BookmarkFields {
        url_norm: url.as_ref().map(|_| bytes(&normalize_url(&c.url))),
        url,
        title: text_field("title", &c.title),
        description: text_field("description", &c.description),
        notes: text_field("notes", &c.notes),
        unread: flag("unread", c.unread),
        shared: flag("shared", c.shared),
        archived: flag("is_archived", c.is_archived),
        tags: if c.has("tag_names") { Some(bookmark_tag_names(&c.tag_names).iter().map(|n| bytes(n)).collect()) } else { None },
        added: if c.has("date_added") { c.date_added.map(micros) } else { None },
        modified: if c.has("date_modified") { c.date_modified.map(micros) } else { None },
    }
}

fn bundle_fields(c: &BundleIn) -> k::BundleFields {
    let field = |name: &str, v: &String| if c.has(name) { Some(bytes(v)) } else { None };
    k::BundleFields {
        name: field("name", &c.name),
        search: field("search", &c.search),
        any_tags: field("any_tags", &c.any_tags),
        all_tags: field("all_tags", &c.all_tags),
        excluded_tags: field("excluded_tags", &c.excluded_tags),
        filter_unread: field("filter_unread", &c.filter_unread),
        filter_shared: field("filter_shared", &c.filter_shared),
        order: if c.has("order") { Some((c.order as i64 + k::ORDER_BIAS as i64) as u64) } else { None },
    }
}

fn flag(raw: Option<&str>) -> u8 {
    match raw {
        Some("yes") => k::FLAG_YES,
        Some("no") => k::FLAG_NO,
        _ => k::FLAG_ANY,
    }
}

fn sort(raw: Option<&str>) -> u8 {
    match raw {
        Some("added_asc") => k::SORT_ADDED_ASC,
        Some("modified_asc") => k::SORT_MODIFIED_ASC,
        Some("modified_desc") => k::SORT_MODIFIED_DESC,
        Some("title_asc") => k::SORT_TITLE_ASC,
        Some("title_desc") => k::SORT_TITLE_DESC,
        _ => k::SORT_ADDED_DESC,
    }
}

fn since(raw: Option<&str>) -> Option<u64> {
    raw.filter(|r| !r.is_empty()).and_then(parse_time).map(micros)
}

fn filter(scope: u8, pairs: &[(String, String)]) -> k::Filter {
    k::Filter {
        scope,
        q: bytes(query_get(pairs, "q").unwrap_or("")),
        user: query_get(pairs, "user").map(bytes),
        unread: flag(query_get(pairs, "unread")),
        shared: flag(query_get(pairs, "shared")),
        added_since: since(query_get(pairs, "added_since")),
        modified_since: since(query_get(pairs, "modified_since")),
        sort: sort(query_get(pairs, "sort")),
        bundle: query_get(pairs, "bundle").and_then(|b| b.parse::<i64>().ok()).filter(|b| *b >= 0).map(|b| b as u64),
    }
}

macro_rules! tri {
    ($e:expr) => {
        match $e {
            Ok(v) => v,
            Err(r) => return r,
        }
    };
}

/* Handlers */

async fn profile(State(app): State<App>, headers: HeaderMap) -> Response {
    let t = tri!(token(&headers));
    match tri!(run(&app, &t, &k::Command::Profile).await) {
        Ok(k::Reply::Profile(u)) => json_response(StatusCode::OK, profile_json(&u), &[]),
        Ok(_) => server_error("unexpected reply"),
        Err(e) => refusal(e, Kind::Bookmark),
    }
}

async fn profile_method(req: Request<Body>) -> Response {
    let method = req.method().as_str().to_string();
    json_response(
        StatusCode::METHOD_NOT_ALLOWED,
        json!({"detail": format!("Method \"{method}\" not allowed.")}),
        &[("Allow", "GET, HEAD, OPTIONS")],
    )
}

async fn listing(app: App, req: Request<Body>, scope: u8) -> Response {
    let t = tri!(token(req.headers()));
    let pairs = query_pairs(&req);
    let url = request_url(&req);
    let (limit, offset) = limit_offset(&pairs);
    let cmd = k::Command::List { filter: filter(scope, &pairs), limit, offset };
    let (r, counted) = run_counted(&app, &t, &cmd).await;
    match tri!(r) {
        Ok(k::Reply::Bookmarks { items, count }) => {
            let results = items.iter().map(bookmark_json).collect();
            let total = count.or(counted).unwrap_or(items.len() as u64);
            json_response(StatusCode::OK, page_json(&url, &pairs, total, results), &[])
        }
        Ok(_) => server_error("unexpected reply"),
        Err(e) => refusal(e, Kind::Bookmark),
    }
}

async fn bookmarks(State(app): State<App>, req: Request<Body>) -> Response {
    listing(app, req, k::SCOPE_ACTIVE).await
}

async fn archived(State(app): State<App>, req: Request<Body>) -> Response {
    listing(app, req, k::SCOPE_ARCHIVED).await
}

async fn shared(State(app): State<App>, req: Request<Body>) -> Response {
    listing(app, req, k::SCOPE_SHARED).await
}

async fn bookmark_create(State(app): State<App>, req: Request<Body>) -> Response {
    let t = tri!(token(req.headers()));
    if t.is_empty() {
        return auth_response("absent");
    }
    let data = match read_body(req).await {
        Ok(d) => d,
        Err(r) => return refused_first(&app, &t, k::Command::Profile, Kind::Bookmark).await.unwrap_or(r),
    };
    let (errors, cleaned) = validate_bookmark(&data, false);
    if !errors.is_empty() {
        let bad = json_response(StatusCode::BAD_REQUEST, Value::Object(errors), &[]);
        return refused_first(&app, &t, k::Command::Profile, Kind::Bookmark).await.unwrap_or(bad);
    }
    let cmd = k::Command::CreateBookmark { fields: bookmark_fields(&cleaned), now: now() };
    match tri!(run(&app, &t, &cmd).await) {
        Ok(k::Reply::Bookmark(v)) => {
            let location = text(&v.bookmark.url);
            json_response(StatusCode::CREATED, bookmark_json(&v), &[("Location", &location)])
        }
        Ok(_) => server_error("unexpected reply"),
        Err(e) => refusal(e, Kind::Bookmark),
    }
}

async fn bookmark_check(State(app): State<App>, req: Request<Body>) -> Response {
    let t = tri!(token(req.headers()));
    let pairs = query_pairs(&req);
    let raw = query_get(&pairs, "url").map(str::to_string);
    let cmd = match &raw {
        Some(u) => k::Command::Check { url: bytes(u), url_norm: bytes(&normalize_url(u)) },
        None => k::Command::Profile,
    };
    let bookmark = match tri!(run(&app, &t, &cmd).await) {
        Ok(k::Reply::Found(Some(v))) => bookmark_json(&v),
        Ok(_) => Value::Null,
        Err(e) => return refusal(e, Kind::Bookmark),
    };
    let meta_url = raw.map(Value::String).unwrap_or(Value::Null);
    json_response(
        StatusCode::OK,
        json!({
            "bookmark": bookmark,
            "metadata": {"url": meta_url, "title": Value::Null, "description": Value::Null, "preview_image": Value::Null},
            "auto_tags": [],
        }),
        &[],
    )
}

async fn bookmark_get(State(app): State<App>, Path(id): Path<String>, headers: HeaderMap) -> Response {
    let t = tri!(token(&headers));
    match tri!(run(&app, &t, &k::Command::GetBookmark { id: path_id(&id) }).await) {
        Ok(k::Reply::Bookmark(v)) => json_response(StatusCode::OK, bookmark_json(&v), &[]),
        Ok(_) => server_error("unexpected reply"),
        Err(e) => refusal(e, Kind::Bookmark),
    }
}

async fn bookmark_write(State(app): State<App>, Path(id): Path<String>, req: Request<Body>) -> Response {
    let partial = req.method() == axum::http::Method::PATCH;
    let t = tri!(token(req.headers()));
    let id = path_id(&id);
    let probe = k::Command::GetBookmark { id };
    let data = match read_body(req).await {
        Ok(d) => d,
        Err(r) => return refused_first(&app, &t, probe, Kind::Bookmark).await.unwrap_or(r),
    };
    let (errors, cleaned) = validate_bookmark(&data, partial);
    if !errors.is_empty() {
        let bad = json_response(StatusCode::BAD_REQUEST, Value::Object(errors), &[]);
        return refused_first(&app, &t, probe, Kind::Bookmark).await.unwrap_or(bad);
    }
    let cmd = k::Command::UpdateBookmark { id, fields: bookmark_fields(&cleaned), now: now() };
    match tri!(run(&app, &t, &cmd).await) {
        Ok(k::Reply::Bookmark(v)) => json_response(StatusCode::OK, bookmark_json(&v), &[]),
        Ok(_) => server_error("unexpected reply"),
        Err(e) => refusal(e, Kind::Bookmark),
    }
}

async fn done(app: &App, t: &[u8], cmd: k::Command, kind: Kind) -> Response {
    match tri!(run(app, t, &cmd).await) {
        Ok(_) => StatusCode::NO_CONTENT.into_response(),
        Err(e) => refusal(e, kind),
    }
}

async fn bookmark_delete(State(app): State<App>, Path(id): Path<String>, headers: HeaderMap) -> Response {
    let t = tri!(token(&headers));
    done(&app, &t, k::Command::DeleteBookmark { id: path_id(&id) }, Kind::Bookmark).await
}

async fn archive(State(app): State<App>, Path(id): Path<String>, headers: HeaderMap) -> Response {
    let t = tri!(token(&headers));
    done(&app, &t, k::Command::Archive { id: path_id(&id), archived: true, now: now() }, Kind::Bookmark).await
}

async fn unarchive(State(app): State<App>, Path(id): Path<String>, headers: HeaderMap) -> Response {
    let t = tri!(token(&headers));
    done(&app, &t, k::Command::Archive { id: path_id(&id), archived: false, now: now() }, Kind::Bookmark).await
}

async fn tags(State(app): State<App>, req: Request<Body>) -> Response {
    let t = tri!(token(req.headers()));
    let pairs = query_pairs(&req);
    let url = request_url(&req);
    let (limit, offset) = limit_offset(&pairs);
    let (r, counted) = run_counted(&app, &t, &k::Command::ListTags { limit, offset }).await;
    match tri!(r) {
        Ok(k::Reply::Tags(ts)) => {
            let total = counted.unwrap_or(ts.len() as u64);
            json_response(StatusCode::OK, page_json(&url, &pairs, total, ts.iter().map(tag_json).collect()), &[])
        }
        Ok(_) => server_error("unexpected reply"),
        Err(e) => refusal(e, Kind::Tag),
    }
}

async fn tag_create(State(app): State<App>, req: Request<Body>) -> Response {
    let t = tri!(token(req.headers()));
    if t.is_empty() {
        return auth_response("absent");
    }
    let data = match read_body(req).await {
        Ok(d) => d,
        Err(r) => return refused_first(&app, &t, k::Command::Profile, Kind::Tag).await.unwrap_or(r),
    };
    let (errors, name) = validate_tag(&data);
    if !errors.is_empty() {
        let bad = json_response(StatusCode::BAD_REQUEST, Value::Object(errors), &[]);
        return refused_first(&app, &t, k::Command::Profile, Kind::Tag).await.unwrap_or(bad);
    }
    match tri!(run(&app, &t, &k::Command::CreateTag { name: bytes(&name), now: now() }).await) {
        Ok(k::Reply::Tag(tag)) => json_response(StatusCode::CREATED, tag_json(&tag), &[]),
        Ok(_) => server_error("unexpected reply"),
        Err(e) => refusal(e, Kind::Tag),
    }
}

async fn tag_get(State(app): State<App>, Path(id): Path<String>, headers: HeaderMap) -> Response {
    let t = tri!(token(&headers));
    match tri!(run(&app, &t, &k::Command::GetTag { id: path_id(&id) }).await) {
        Ok(k::Reply::Tag(tag)) => json_response(StatusCode::OK, tag_json(&tag), &[]),
        Ok(_) => server_error("unexpected reply"),
        Err(e) => refusal(e, Kind::Tag),
    }
}

async fn tag_delete(State(app): State<App>, Path(id): Path<String>, headers: HeaderMap) -> Response {
    let t = tri!(token(&headers));
    done(&app, &t, k::Command::DeleteTag { id: path_id(&id) }, Kind::Tag).await
}

async fn bundles(State(app): State<App>, req: Request<Body>) -> Response {
    let t = tri!(token(req.headers()));
    let pairs = query_pairs(&req);
    let url = request_url(&req);
    let (limit, offset) = limit_offset(&pairs);
    match tri!(run(&app, &t, &k::Command::ListBundles { limit, offset }).await) {
        Ok(k::Reply::Bundles { items, count }) => {
            json_response(StatusCode::OK, page_json(&url, &pairs, count, items.iter().map(bundle_json).collect()), &[])
        }
        Ok(_) => server_error("unexpected reply"),
        Err(e) => refusal(e, Kind::Bundle),
    }
}

async fn bundle_create(State(app): State<App>, req: Request<Body>) -> Response {
    let t = tri!(token(req.headers()));
    if t.is_empty() {
        return auth_response("absent");
    }
    let data = match read_body(req).await {
        Ok(d) => d,
        Err(r) => return refused_first(&app, &t, k::Command::Profile, Kind::Bundle).await.unwrap_or(r),
    };
    let (errors, cleaned) = validate_bundle(&data, false);
    if !errors.is_empty() {
        let bad = json_response(StatusCode::BAD_REQUEST, Value::Object(errors), &[]);
        return refused_first(&app, &t, k::Command::Profile, Kind::Bundle).await.unwrap_or(bad);
    }
    match tri!(run(&app, &t, &k::Command::CreateBundle { fields: bundle_fields(&cleaned), now: now() }).await) {
        Ok(k::Reply::Bundle(b)) => json_response(StatusCode::CREATED, bundle_json(&b), &[]),
        Ok(_) => server_error("unexpected reply"),
        Err(e) => refusal(e, Kind::Bundle),
    }
}

async fn bundle_get(State(app): State<App>, Path(id): Path<String>, headers: HeaderMap) -> Response {
    let t = tri!(token(&headers));
    match tri!(run(&app, &t, &k::Command::GetBundle { id: path_id(&id) }).await) {
        Ok(k::Reply::Bundle(b)) => json_response(StatusCode::OK, bundle_json(&b), &[]),
        Ok(_) => server_error("unexpected reply"),
        Err(e) => refusal(e, Kind::Bundle),
    }
}

async fn bundle_write(State(app): State<App>, Path(id): Path<String>, req: Request<Body>) -> Response {
    let partial = req.method() == axum::http::Method::PATCH;
    let t = tri!(token(req.headers()));
    let id = path_id(&id);
    let probe = k::Command::GetBundle { id };
    let data = match read_body(req).await {
        Ok(d) => d,
        Err(r) => return refused_first(&app, &t, probe, Kind::Bundle).await.unwrap_or(r),
    };
    let (errors, cleaned) = validate_bundle(&data, partial);
    if !errors.is_empty() {
        let bad = json_response(StatusCode::BAD_REQUEST, Value::Object(errors), &[]);
        return refused_first(&app, &t, probe, Kind::Bundle).await.unwrap_or(bad);
    }
    match tri!(run(&app, &t, &k::Command::UpdateBundle { id, fields: bundle_fields(&cleaned), now: now() }).await) {
        Ok(k::Reply::Bundle(b)) => json_response(StatusCode::OK, bundle_json(&b), &[]),
        Ok(_) => server_error("unexpected reply"),
        Err(e) => refusal(e, Kind::Bundle),
    }
}

async fn bundle_delete(State(app): State<App>, Path(id): Path<String>, headers: HeaderMap) -> Response {
    let t = tri!(token(&headers));
    done(&app, &t, k::Command::DeleteBundle { id: path_id(&id) }, Kind::Bundle).await
}
