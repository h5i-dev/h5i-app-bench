//! HTTP shell for the linkding API. Token lookup and SQL live here.
//! `transition`, `page_of`, `parse_search`, and `valid_url` decide policy.

mod db;
mod gpu_search;
mod logic;

use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::Arc;
use tokio::sync::Mutex;
use crate::gpu_search::SearchIndex;

use axum::body::Body;
use axum::extract::{Path, State};
use axum::http::{header, HeaderMap, Request, StatusCode};
use axum::response::{IntoResponse, Response};
use axum::routing::get;
use axum::middleware::{self, Next};
use axum::http::Method;
use axum::Router;
use linkding_kernel::{Command, Error as KernelError, Reply, View};
use serde_json::{json, Map, Value};
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;

use crate::db::{
    bundle_json, create_bookmark, create_bundle, create_tag, delete_bookmark, delete_bundle,
    delete_tag, get_bundle, get_by_id, get_tag, list_bookmarks, list_bundles, list_tags, load_user,
    ping, profile_json, serialize, set_archived, tag_json, update_bookmark, update_bundle,
    UpdateProblem, UserRow,
};
use crate::logic::{
    auth_detail, classify_auth, json_detail, query_map, validate_bookmark, validate_bundle,
    validate_tag,
};

#[derive(Clone)]
struct App {
    pool: PgPool,
    /// Per-owner GPU-resident search index, built on first search and dropped on
    /// a write to that owner. The benchmark's search scenarios are read-only, so
    /// the index stays warm across them.
    indices: Arc<Mutex<HashMap<i64, Arc<SearchIndex>>>>,
    /// The compiled device PTX (empty without the `gpu` feature; the CPU scan
    /// needs none).
    ptx: Arc<String>,
}

impl App {
    /// Search ids for `owner`'s bookmarks matching `q`, via the GPU index
    /// (built from PostgreSQL on first use). `None` on any error, so the caller
    /// falls back to the SQL predicate.
    async fn gpu_match_ids(&self, owner: i64, q: &str, lax: bool) -> Option<Vec<i64>> {
        let index = {
            let mut cache = self.indices.lock().await;
            match cache.get(&owner) {
                Some(index) => index.clone(),
                None => {
                    let facts = db::load_facts(&self.pool, owner).await.ok()?;
                    let index = Arc::new(SearchIndex::build(facts, &self.ptx).ok()?);
                    cache.insert(owner, index.clone());
                    index
                }
            }
        };
        index.matching_ids(q, lax).ok()
    }

    /// Drop a cached index so the next search rebuilds it. Call after a write.
    async fn forget(&self, owner: i64) {
        self.indices.lock().await.remove(&owner);
    }
}

fn empty_view(actor: u64) -> View {
    View {
        actor,
        bookmark_exists: false,
        bookmark_owner: 0,
        bookmark_shared: false,
        owner_sharing: false,
        owner_public: false,
        tag_exists: false,
        tag_owner: 0,
        bundle_exists: false,
        bundle_owner: 0,
    }
}

fn decide(view: &View, cmd: &Command) -> Result<(), KernelError> {
    match linkding_kernel::transition(view, cmd) {
        Ok(Reply::Allow) => Ok(()),
        Err(err) => Err(err),
    }
}

fn json_response(status: StatusCode, payload: Value, extra: &[(&str, &str)]) -> Response {
    let body = serde_json::to_vec(&payload).unwrap_or_else(|_| b"{}".to_vec());
    let mut response = Response::builder()
        .status(status)
        .header(header::CONTENT_TYPE, "application/json");
    for (key, value) in extra {
        response = response.header(*key, *value);
    }
    response.body(Body::from(body)).unwrap_or_else(|_| {
        (StatusCode::INTERNAL_SERVER_ERROR, "server error").into_response()
    })
}

fn auth_response(kind: &str) -> Response {
    json_response(
        StatusCode::UNAUTHORIZED,
        json!({"detail": auth_detail(kind)}),
        &[("WWW-Authenticate", "Token")],
    )
}

fn not_found(kind: &str) -> Response {
    let message = match kind {
        "tag" => "No Tag matches the given query.",
        "bundle" => "No BookmarkBundle matches the given query.",
        _ => "No Bookmark matches the given query.",
    };
    json_response(StatusCode::NOT_FOUND, json!({"detail": message}), &[])
}

fn server_error(err: impl std::fmt::Display) -> Response {
    eprintln!("request error: {err}");
    json_response(
        StatusCode::INTERNAL_SERVER_ERROR,
        json!({"detail": "Server error."}),
        &[],
    )
}

fn kernel_error(err: KernelError, kind: &str) -> Response {
    match err {
        KernelError::Unauthenticated => auth_response("absent"),
        KernelError::NotFound => not_found(kind),
    }
}

struct Auth {
    user: Option<UserRow>,
    actor: u64,
}

async fn authenticate(app: &App, headers: &HeaderMap) -> Result<Auth, Response> {
    let header = headers
        .get(header::AUTHORIZATION)
        .and_then(|value| value.to_str().ok())
        .unwrap_or("");
    let (kind, token) = classify_auth(header);
    if kind == "absent" {
        return Ok(Auth {
            user: None,
            actor: 0,
        });
    }
    if kind != "token" {
        return Err(auth_response(kind));
    }
    let user = load_user(&app.pool, &token)
        .await
        .map_err(server_error)?;
    let Some(user) = user else {
        return Err(auth_response("bad"));
    };
    let actor = user.id as u64;
    Ok(Auth {
        user: Some(user),
        actor,
    })
}

fn request_url(req: &Request<Body>) -> String {
    let host = req
        .headers()
        .get(header::HOST)
        .and_then(|value| value.to_str().ok())
        .unwrap_or("127.0.0.1");
    let path = req
        .uri()
        .path_and_query()
        .map(|value| value.as_str())
        .unwrap_or("/");
    format!("http://{host}{path}")
}

fn query_pairs(req: &Request<Body>) -> Vec<(String, String)> {
    let raw = req.uri().query().unwrap_or("");
    query_map(raw)
}

fn path_id(raw: &str) -> Option<i64> {
    if raw.is_empty() || !raw.bytes().all(|byte| byte.is_ascii_digit()) {
        return None;
    }
    raw.parse::<i64>().ok()
}

async fn read_body(req: Request<Body>) -> Result<Map<String, Value>, Response> {
    let headers = req.headers().clone();
    let media = headers
        .get(header::CONTENT_TYPE)
        .and_then(|value| value.to_str().ok())
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
    let bytes = axum::body::to_bytes(req.into_body(), 2 * 1024 * 1024)
        .await
        .map_err(server_error)?;
    if bytes.is_empty() {
        return Ok(Map::new());
    }
    let value: Value = match serde_json::from_slice(&bytes) {
        Ok(value) => value,
        Err(_) => {
            return Err(json_response(
                StatusCode::BAD_REQUEST,
                json!({"detail": json_detail(&bytes)}),
                &[],
            ));
        }
    };
    if value.is_null() {
        return Err(json_response(
            StatusCode::BAD_REQUEST,
            json!({"non_field_errors": ["No data provided"]}),
            &[],
        ));
    }
    if let Value::Object(map) = value {
        return Ok(map);
    }
    let type_name = match &value {
        Value::Array(_) => "list",
        Value::String(_) => "str",
        Value::Bool(_) => "bool",
        Value::Number(number) if number.as_f64().is_some_and(|n| n.fract() != 0.0) => "float",
        Value::Number(_) => "int",
        _ => "str",
    };
    Err(json_response(
        StatusCode::BAD_REQUEST,
        json!({"non_field_errors": [format!("Invalid data. Expected a dictionary, but got {type_name}.")]}),
        &[],
    ))
}

fn field_errors(errors: Map<String, Value>) -> Response {
    json_response(StatusCode::BAD_REQUEST, Value::Object(errors), &[])
}

async fn health(State(app): State<App>) -> Response {
    if let Err(err) = ping(&app.pool).await {
        return server_error(err);
    }
    Response::builder()
        .status(StatusCode::OK)
        .header(header::CONTENT_TYPE, "text/plain")
        .body(Body::from("ok"))
        .unwrap_or_else(|_| StatusCode::INTERNAL_SERVER_ERROR.into_response())
}

async fn profile(State(app): State<App>, req: Request<Body>) -> Response {
    let auth = match authenticate(&app, req.headers()).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    let view = empty_view(auth.actor);
    if let Err(err) = decide(&view, &Command::ReadProfile) {
        return kernel_error(err, "bookmark");
    }
    let Some(user) = auth.user else {
        return auth_response("absent");
    };
    json_response(StatusCode::OK, profile_json(&user), &[])
}

async fn profile_method(req: Request<Body>) -> Response {
    let method = req.method().as_str().to_string();
    json_response(
        StatusCode::METHOD_NOT_ALLOWED,
        json!({"detail": format!("Method \"{method}\" not allowed.")}),
        &[("Allow", "GET, HEAD, OPTIONS")],
    )
}

async fn bookmark_list(State(app): State<App>, req: Request<Body>, kind: &'static str, cmd: Command) -> Response {
    let auth = match authenticate(&app, req.headers()).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    let view = empty_view(auth.actor);
    if let Err(err) = decide(&view, &cmd) {
        return kernel_error(err, "bookmark");
    }
    let pairs = query_pairs(&req);
    let url = request_url(&req);
    // Only the active list is GPU-accelerated for now (the benchmark's search
    // scenario); other scopes keep the SQL predicate.
    let q = pairs.iter().find(|(k, _)| k == "q").map(|(_, v)| v.as_str()).unwrap_or("");
    let gpu_ids = if kind == "active" && !q.is_empty() {
        match auth.user.as_ref() {
            // GPU search implements linkding's modern query parser only; a user
            // on legacy search keeps the SQL path.
            Some(user) if !user.legacy_search => {
                app.gpu_match_ids(user.id, q, user.tag_search == "lax").await
            }
            _ => None,
        }
    } else {
        None
    };
    match list_bookmarks(&app.pool, kind, auth.user.as_ref(), &url, &pairs, gpu_ids.as_deref()).await {
        Ok(payload) => json_response(StatusCode::OK, payload, &[]),
        Err(err) => server_error(err),
    }
}

async fn bookmarks(state: State<App>, req: Request<Body>) -> Response {
    bookmark_list(state, req, "active", Command::ListOwn).await
}

async fn archived(state: State<App>, req: Request<Body>) -> Response {
    bookmark_list(state, req, "archived", Command::ListArchived).await
}

async fn shared(state: State<App>, req: Request<Body>) -> Response {
    bookmark_list(state, req, "shared", Command::ListShared).await
}

async fn bookmark_create(State(app): State<App>, req: Request<Body>) -> Response {
    let headers = req.headers().clone();
    let auth = match authenticate(&app, &headers).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    let view = empty_view(auth.actor);
    if let Err(err) = decide(&view, &Command::CreateBookmark) {
        return kernel_error(err, "bookmark");
    }
    let Some(user) = auth.user else {
        return auth_response("absent");
    };
    let data = match read_body(req).await {
        Ok(data) => data,
        Err(response) => return response,
    };
    let (errors, cleaned) = validate_bookmark(&data, false);
    if !errors.is_empty() {
        return field_errors(errors);
    }
    match create_bookmark(&app.pool, user.id, &cleaned).await {
        Ok(row) => {
            let location = row.url.clone();
            match serialize(&app.pool, &row).await {
                Ok(payload) => json_response(StatusCode::CREATED, payload, &[("Location", &location)]),
                Err(err) => server_error(err),
            }
        }
        Err(err) => server_error(err),
    }
}

async fn bookmark_check(State(app): State<App>, req: Request<Body>) -> Response {
    let auth = match authenticate(&app, req.headers()).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    // Checking a URL is allowed for any signed-in user. It is not an owner lookup.
    let view = empty_view(auth.actor);
    if let Err(err) = decide(&view, &Command::CreateBookmark) {
        return kernel_error(err, "bookmark");
    }
    let Some(user) = auth.user else {
        return auth_response("absent");
    };
    let pairs = query_pairs(&req);
    let mut bookmark = Value::Null;
    let mut meta_url = Value::Null;
    if let Some(raw) = crate::logic::query_get(&pairs, "url") {
        meta_url = Value::String(raw.to_string());
        match db::find_existing(&app.pool, user.id, raw).await {
            Ok(Some(row)) => match serialize(&app.pool, &row).await {
                Ok(payload) => bookmark = payload,
                Err(err) => return server_error(err),
            },
            Ok(None) => {}
            Err(err) => return server_error(err),
        }
    }
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

async fn bookmark_get(State(app): State<App>, Path(id_raw): Path<String>, req: Request<Body>) -> Response {
    let auth = match authenticate(&app, req.headers()).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    let mut view = empty_view(auth.actor);
    if let Some(id) = path_id(&id_raw) {
        match get_by_id(&app.pool, id).await {
            Ok(Some(row)) => {
                view.bookmark_exists = true;
                view.bookmark_owner = row.owner_id as u64;
                view.bookmark_shared = row.shared;
            }
            Ok(None) => {}
            Err(err) => return server_error(err),
        }
    }
    if let Err(err) = decide(&view, &Command::ReadBookmark) {
        return kernel_error(err, "bookmark");
    }
    let Some(id) = path_id(&id_raw) else {
        return not_found("bookmark");
    };
    match get_by_id(&app.pool, id).await {
        Ok(Some(row)) => match serialize(&app.pool, &row).await {
            Ok(payload) => json_response(StatusCode::OK, payload, &[]),
            Err(err) => server_error(err),
        },
        Ok(None) => not_found("bookmark"),
        Err(err) => server_error(err),
    }
}

async fn bookmark_write(State(app): State<App>, Path(id_raw): Path<String>, req: Request<Body>) -> Response {
    let partial = req.method() == axum::http::Method::PATCH;
    let headers = req.headers().clone();
    let auth = match authenticate(&app, &headers).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    let mut view = empty_view(auth.actor);
    if let Some(id) = path_id(&id_raw) {
        match get_by_id(&app.pool, id).await {
            Ok(Some(row)) => {
                view.bookmark_exists = true;
                view.bookmark_owner = row.owner_id as u64;
            }
            Ok(None) => {}
            Err(err) => return server_error(err),
        }
    }
    if let Err(err) = decide(&view, &Command::UpdateBookmark) {
        return kernel_error(err, "bookmark");
    }
    let Some(user) = auth.user else {
        return auth_response("absent");
    };
    let Some(id) = path_id(&id_raw) else {
        return not_found("bookmark");
    };
    let data = match read_body(req).await {
        Ok(data) => data,
        Err(response) => return response,
    };
    let (errors, cleaned) = validate_bookmark(&data, partial);
    if !errors.is_empty() {
        return field_errors(errors);
    }
    match update_bookmark(&app.pool, user.id, id, &cleaned).await {
        Ok(Ok(row)) => match serialize(&app.pool, &row).await {
            Ok(payload) => json_response(StatusCode::OK, payload, &[]),
            Err(err) => server_error(err),
        },
        Ok(Err(UpdateProblem::Duplicate)) => json_response(
            StatusCode::BAD_REQUEST,
            json!({"url": ["A bookmark with this URL already exists."]}),
            &[],
        ),
        Ok(Err(UpdateProblem::Missing)) => not_found("bookmark"),
        Err(err) => server_error(err),
    }
}

async fn bookmark_delete(State(app): State<App>, Path(id_raw): Path<String>, req: Request<Body>) -> Response {
    let auth = match authenticate(&app, req.headers()).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    let mut view = empty_view(auth.actor);
    if let Some(id) = path_id(&id_raw) {
        match get_by_id(&app.pool, id).await {
            Ok(Some(row)) => {
                view.bookmark_exists = true;
                view.bookmark_owner = row.owner_id as u64;
            }
            Ok(None) => {}
            Err(err) => return server_error(err),
        }
    }
    if let Err(err) = decide(&view, &Command::DeleteBookmark) {
        return kernel_error(err, "bookmark");
    }
    let Some(user) = auth.user else {
        return auth_response("absent");
    };
    let Some(id) = path_id(&id_raw) else {
        return not_found("bookmark");
    };
    match delete_bookmark(&app.pool, user.id, id).await {
        Ok(true) => StatusCode::NO_CONTENT.into_response(),
        Ok(false) => not_found("bookmark"),
        Err(err) => server_error(err),
    }
}

async fn archive_one(
    State(app): State<App>,
    Path(id_raw): Path<String>,
    req: Request<Body>,
    archived: bool,
) -> Response {
    let auth = match authenticate(&app, req.headers()).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    let cmd = if archived {
        Command::ArchiveBookmark
    } else {
        Command::UnarchiveBookmark
    };
    let mut view = empty_view(auth.actor);
    if let Some(id) = path_id(&id_raw) {
        match get_by_id(&app.pool, id).await {
            Ok(Some(row)) => {
                view.bookmark_exists = true;
                view.bookmark_owner = row.owner_id as u64;
            }
            Ok(None) => {}
            Err(err) => return server_error(err),
        }
    }
    if let Err(err) = decide(&view, &cmd) {
        return kernel_error(err, "bookmark");
    }
    let Some(user) = auth.user else {
        return auth_response("absent");
    };
    let Some(id) = path_id(&id_raw) else {
        return not_found("bookmark");
    };
    match set_archived(&app.pool, user.id, id, archived).await {
        Ok(Some(_)) => StatusCode::NO_CONTENT.into_response(),
        Ok(None) => not_found("bookmark"),
        Err(err) => server_error(err),
    }
}

async fn archive(state: State<App>, path: Path<String>, req: Request<Body>) -> Response {
    archive_one(state, path, req, true).await
}

async fn unarchive(state: State<App>, path: Path<String>, req: Request<Body>) -> Response {
    archive_one(state, path, req, false).await
}

async fn tags(State(app): State<App>, req: Request<Body>) -> Response {
    let auth = match authenticate(&app, req.headers()).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    let view = empty_view(auth.actor);
    if let Err(err) = decide(&view, &Command::ListOwn) {
        return kernel_error(err, "tag");
    }
    let Some(user) = auth.user else {
        return auth_response("absent");
    };
    let pairs = query_pairs(&req);
    let url = request_url(&req);
    match list_tags(&app.pool, user.id, &url, &pairs).await {
        Ok(payload) => json_response(StatusCode::OK, payload, &[]),
        Err(err) => server_error(err),
    }
}

async fn tag_create(State(app): State<App>, req: Request<Body>) -> Response {
    let headers = req.headers().clone();
    let auth = match authenticate(&app, &headers).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    let view = empty_view(auth.actor);
    if let Err(err) = decide(&view, &Command::CreateTag) {
        return kernel_error(err, "tag");
    }
    let Some(user) = auth.user else {
        return auth_response("absent");
    };
    let data = match read_body(req).await {
        Ok(data) => data,
        Err(response) => return response,
    };
    let (errors, name) = validate_tag(&data);
    if !errors.is_empty() {
        return field_errors(errors);
    }
    match create_tag(&app.pool, user.id, &name).await {
        Ok(row) => json_response(StatusCode::CREATED, tag_json(&row), &[]),
        Err(err) => server_error(err),
    }
}

async fn tag_get(State(app): State<App>, Path(id_raw): Path<String>, req: Request<Body>) -> Response {
    let auth = match authenticate(&app, req.headers()).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    let mut view = empty_view(auth.actor);
    if let Some(id) = path_id(&id_raw) {
        match get_tag(&app.pool, id).await {
            Ok(Some(row)) => {
                view.tag_exists = true;
                view.tag_owner = row.owner_id as u64;
            }
            Ok(None) => {}
            Err(err) => return server_error(err),
        }
    }
    if let Err(err) = decide(&view, &Command::ReadTag) {
        return kernel_error(err, "tag");
    }
    let Some(id) = path_id(&id_raw) else {
        return not_found("tag");
    };
    match get_tag(&app.pool, id).await {
        Ok(Some(row)) => json_response(StatusCode::OK, tag_json(&row), &[]),
        Ok(None) => not_found("tag"),
        Err(err) => server_error(err),
    }
}

async fn tag_delete(State(app): State<App>, Path(id_raw): Path<String>, req: Request<Body>) -> Response {
    let auth = match authenticate(&app, req.headers()).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    let mut view = empty_view(auth.actor);
    if let Some(id) = path_id(&id_raw) {
        match get_tag(&app.pool, id).await {
            Ok(Some(row)) => {
                view.tag_exists = true;
                view.tag_owner = row.owner_id as u64;
            }
            Ok(None) => {}
            Err(err) => return server_error(err),
        }
    }
    if let Err(err) = decide(&view, &Command::DeleteTag) {
        return kernel_error(err, "tag");
    }
    let Some(user) = auth.user else {
        return auth_response("absent");
    };
    let Some(id) = path_id(&id_raw) else {
        return not_found("tag");
    };
    match delete_tag(&app.pool, user.id, id).await {
        Ok(true) => StatusCode::NO_CONTENT.into_response(),
        Ok(false) => not_found("tag"),
        Err(err) => server_error(err),
    }
}

async fn bundles(State(app): State<App>, req: Request<Body>) -> Response {
    let auth = match authenticate(&app, req.headers()).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    let view = empty_view(auth.actor);
    if let Err(err) = decide(&view, &Command::ListOwn) {
        return kernel_error(err, "bundle");
    }
    let Some(user) = auth.user else {
        return auth_response("absent");
    };
    let pairs = query_pairs(&req);
    let url = request_url(&req);
    match list_bundles(&app.pool, user.id, &url, &pairs).await {
        Ok(payload) => json_response(StatusCode::OK, payload, &[]),
        Err(err) => server_error(err),
    }
}

async fn bundle_create(State(app): State<App>, req: Request<Body>) -> Response {
    let headers = req.headers().clone();
    let auth = match authenticate(&app, &headers).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    let view = empty_view(auth.actor);
    if let Err(err) = decide(&view, &Command::CreateBundle) {
        return kernel_error(err, "bundle");
    }
    let Some(user) = auth.user else {
        return auth_response("absent");
    };
    let data = match read_body(req).await {
        Ok(data) => data,
        Err(response) => return response,
    };
    let (errors, cleaned) = validate_bundle(&data, false);
    if !errors.is_empty() {
        return field_errors(errors);
    }
    match create_bundle(&app.pool, user.id, &cleaned).await {
        Ok(row) => json_response(StatusCode::CREATED, bundle_json(&row), &[]),
        Err(err) => server_error(err),
    }
}

async fn bundle_get(State(app): State<App>, Path(id_raw): Path<String>, req: Request<Body>) -> Response {
    let auth = match authenticate(&app, req.headers()).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    let mut view = empty_view(auth.actor);
    if let Some(id) = path_id(&id_raw) {
        match get_bundle(&app.pool, id).await {
            Ok(Some(row)) => {
                view.bundle_exists = true;
                view.bundle_owner = row.owner_id as u64;
            }
            Ok(None) => {}
            Err(err) => return server_error(err),
        }
    }
    if let Err(err) = decide(&view, &Command::ReadBundle) {
        return kernel_error(err, "bundle");
    }
    let Some(id) = path_id(&id_raw) else {
        return not_found("bundle");
    };
    match get_bundle(&app.pool, id).await {
        Ok(Some(row)) => json_response(StatusCode::OK, bundle_json(&row), &[]),
        Ok(None) => not_found("bundle"),
        Err(err) => server_error(err),
    }
}

async fn bundle_write(State(app): State<App>, Path(id_raw): Path<String>, req: Request<Body>) -> Response {
    let partial = req.method() == axum::http::Method::PATCH;
    let headers = req.headers().clone();
    let auth = match authenticate(&app, &headers).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    let mut view = empty_view(auth.actor);
    if let Some(id) = path_id(&id_raw) {
        match get_bundle(&app.pool, id).await {
            Ok(Some(row)) => {
                view.bundle_exists = true;
                view.bundle_owner = row.owner_id as u64;
            }
            Ok(None) => {}
            Err(err) => return server_error(err),
        }
    }
    if let Err(err) = decide(&view, &Command::UpdateBundle) {
        return kernel_error(err, "bundle");
    }
    let Some(user) = auth.user else {
        return auth_response("absent");
    };
    let Some(id) = path_id(&id_raw) else {
        return not_found("bundle");
    };
    let data = match read_body(req).await {
        Ok(data) => data,
        Err(response) => return response,
    };
    let (errors, cleaned) = validate_bundle(&data, partial);
    if !errors.is_empty() {
        return field_errors(errors);
    }
    match update_bundle(&app.pool, user.id, id, &cleaned).await {
        Ok(Some(row)) => json_response(StatusCode::OK, bundle_json(&row), &[]),
        Ok(None) => not_found("bundle"),
        Err(err) => server_error(err),
    }
}

async fn bundle_delete(State(app): State<App>, Path(id_raw): Path<String>, req: Request<Body>) -> Response {
    let auth = match authenticate(&app, req.headers()).await {
        Ok(auth) => auth,
        Err(response) => return response,
    };
    let mut view = empty_view(auth.actor);
    if let Some(id) = path_id(&id_raw) {
        match get_bundle(&app.pool, id).await {
            Ok(Some(row)) => {
                view.bundle_exists = true;
                view.bundle_owner = row.owner_id as u64;
            }
            Ok(None) => {}
            Err(err) => return server_error(err),
        }
    }
    if let Err(err) = decide(&view, &Command::DeleteBundle) {
        return kernel_error(err, "bundle");
    }
    let Some(user) = auth.user else {
        return auth_response("absent");
    };
    let Some(id) = path_id(&id_raw) else {
        return not_found("bundle");
    };
    match delete_bundle(&app.pool, user.id, id).await {
        Ok(true) => StatusCode::NO_CONTENT.into_response(),
        Ok(false) => not_found("bundle"),
        Err(err) => server_error(err),
    }
}

/// Drop the GPU search indices after any successful write, so the next search
/// rebuilds from the committed data. Reads (GET) leave the warm index in place.
async fn invalidate_on_write(State(app): State<App>, req: Request<Body>, next: Next) -> Response {
    let write = req.method() != Method::GET && req.method() != Method::HEAD;
    let resp = next.run(req).await;
    if write && resp.status().is_success() {
        app.indices.lock().await.clear();
    }
    resp
}

fn router(app: App) -> Router {
    Router::new()
        .route("/healthz", get(health))
        .route("/api/user/profile/", get(profile).put(profile_method).patch(profile_method).post(profile_method).delete(profile_method))
        .route("/api/bookmarks/", get(bookmarks).post(bookmark_create))
        .route("/api/bookmarks/archived/", get(archived))
        .route("/api/bookmarks/shared/", get(shared))
        .route("/api/bookmarks/check/", get(bookmark_check))
        .route("/api/bookmarks/:id/", get(bookmark_get).put(bookmark_write).patch(bookmark_write).delete(bookmark_delete))
        .route("/api/bookmarks/:id/archive/", axum::routing::post(archive))
        .route("/api/bookmarks/:id/unarchive/", axum::routing::post(unarchive))
        .route("/api/tags/", get(tags).post(tag_create))
        .route("/api/tags/:id/", get(tag_get).delete(tag_delete))
        .route("/api/bundles/", get(bundles).post(bundle_create))
        .route("/api/bundles/:id/", get(bundle_get).put(bundle_write).patch(bundle_write).delete(bundle_delete))
        .layer(middleware::from_fn_with_state(app.clone(), invalidate_on_write))
        .with_state(app)
}

fn env_string(key: &str, default: &str) -> String {
    std::env::var(key)
        .ok()
        .filter(|value| !value.is_empty())
        .unwrap_or_else(|| default.to_string())
}

fn env_u32(key: &str, default: u32) -> u32 {
    std::env::var(key)
        .ok()
        .and_then(|value| value.parse().ok())
        .filter(|value| *value > 0)
        .unwrap_or(default)
}

async fn run() -> Result<(), Box<dyn std::error::Error>> {
    let db_url = env_string(
        "DATABASE_URL",
        "postgres://linkding:linkding@127.0.0.1:5440/linkding",
    );
    let port = env_string("PORT", "8104");
    let pool_size = env_u32("DB_POOL", 32);
    let pool = PgPoolOptions::new()
        .max_connections(pool_size)
        .min_connections(1.min(pool_size))
        // sqlx pings every connection on checkout by default, one extra
        // round trip per query; pgx and node-postgres do not.
        .test_before_acquire(false)
        .after_connect(|conn, _meta| {
            Box::pin(async move {
                sqlx::query("SET TIME ZONE 'UTC'").execute(&mut *conn).await?;
                Ok(())
            })
        })
        .connect(&db_url)
        .await?;
    let ptx = env_string("H5I_GPU_PTX", "");
    let ptx = if ptx.is_empty() { String::new() } else { std::fs::read_to_string(&ptx).unwrap_or_default() };
    let app = App {
        pool,
        indices: Arc::new(Mutex::new(HashMap::new())),
        ptx: Arc::new(ptx),
    };
    let addr: SocketAddr = format!("127.0.0.1:{port}").parse()?;
    let listener = tokio::net::TcpListener::bind(addr).await?;
    eprintln!(
        "listening on {addr} pool={pool_size} workers={}",
        env_u32("WEB_CONCURRENCY", 4)
    );
    axum::serve(listener, router(app)).await?;
    Ok(())
}

fn main() {
    let workers = env_u32("WEB_CONCURRENCY", 4) as usize;
    let runtime = tokio::runtime::Builder::new_multi_thread()
        .worker_threads(workers)
        .enable_all()
        .build()
        .expect("tokio runtime");
    if let Err(err) = runtime.block_on(run()) {
        eprintln!("{err}");
        std::process::exit(1);
    }
}
