//! HTTP shell for Conduit. JWT, bcrypt, and PostgreSQL live here.
//! Authorization, validation, slug rules, and list-versus-detail shaping
//! are `conduit_kernel::transition` and `shows_body`.

use std::collections::{HashMap, HashSet};

use axum::body::{Body, Bytes};
use axum::extract::{Path, Query, State};
use axum::http::{header, HeaderMap, StatusCode};
use axum::routing::{get, post};
use axum::{Json, Router};
use axum::response::{IntoResponse, Response};
use conduit_kernel::{
    token_actor, token_user_exists, Subject, TokenInput, authenticate_login, make_slug, shows_body, transition, ArticleView, Command, Delta, Error, Norm,
    RawNum, RawText, Reply, TagDecision, TagInput, View,
};
use serde::Deserialize;
use serde::Serialize;
use serde_json::{json, Map, Value};
use sqlx::postgres::PgPoolOptions;
use sqlx::PgPool;
use sqlx::Postgres;
use sqlx::Transaction;

const BCRYPT_COST: u32 = 12;
const JWT_TTL_SECS: u64 = 60 * 24 * 60 * 60;

#[derive(Clone)]
struct App {
    pool: PgPool,
    secret: Vec<u8>,
    dummy: String,
}

struct ApiError {
    status: StatusCode,
    field: &'static str,
    message: &'static str,
}

fn api(status: StatusCode, field: &'static str, message: &'static str) -> ApiError {
    ApiError {
        status,
        field,
        message,
    }
}

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        let body = json!({ "errors": { self.field: [self.message] } });
        (self.status, Json(body)).into_response()
    }
}

impl From<sqlx::Error> for ApiError {
    fn from(err: sqlx::Error) -> Self {
        if let Some(field) = unique_field(&err) {
            return api(StatusCode::CONFLICT, field, "has already been taken");
        }
        eprintln!("database: {err}");
        api(StatusCode::INTERNAL_SERVER_ERROR, "server", "error")
    }
}

fn unique_field(err: &sqlx::Error) -> Option<&'static str> {
    let sqlx::Error::Database(db) = err else {
        return None;
    };
    let code = db.code()?;
    if code != "23505" {
        return None;
    }
    let name = db.constraint().unwrap_or("");
    if name.contains("email") {
        Some("email")
    } else if name.contains("slug") {
        Some("slug")
    } else {
        Some("username")
    }
}

fn map_kernel(err: Error) -> ApiError {
    match err {
        Error::InvalidToken => api(StatusCode::UNAUTHORIZED, "token", "is invalid"),
        Error::InvalidCredentials => api(StatusCode::UNAUTHORIZED, "credentials", "invalid"),
        Error::Unauthenticated => api(StatusCode::UNAUTHORIZED, "token", "is missing"),
        Error::ForbiddenArticle => api(StatusCode::FORBIDDEN, "article", "forbidden"),
        Error::ForbiddenComment => api(StatusCode::FORBIDDEN, "comment", "forbidden"),
        Error::ArticleNotFound => api(StatusCode::NOT_FOUND, "article", "not found"),
        Error::CommentNotFound => api(StatusCode::NOT_FOUND, "comment", "not found"),
        Error::ProfileNotFound => api(StatusCode::NOT_FOUND, "profile", "not found"),
        Error::BlankUsername => api(StatusCode::UNPROCESSABLE_ENTITY, "username", "can't be blank"),
        Error::BlankEmail => api(StatusCode::UNPROCESSABLE_ENTITY, "email", "can't be blank"),
        Error::BlankPassword => api(StatusCode::UNPROCESSABLE_ENTITY, "password", "can't be blank"),
        Error::BlankTitle => api(StatusCode::UNPROCESSABLE_ENTITY, "title", "can't be blank"),
        Error::BlankDescription => {
            api(StatusCode::UNPROCESSABLE_ENTITY, "description", "can't be blank")
        }
        Error::BlankBody => api(StatusCode::UNPROCESSABLE_ENTITY, "body", "can't be blank"),
        Error::ShortPassword => api(
            StatusCode::UNPROCESSABLE_ENTITY,
            "password",
            "is too short (minimum is 8 characters)",
        ),
        Error::InvalidUsername => api(StatusCode::UNPROCESSABLE_ENTITY, "username", "is invalid"),
        Error::InvalidEmail => api(StatusCode::UNPROCESSABLE_ENTITY, "email", "is invalid"),
        Error::InvalidPassword => api(StatusCode::UNPROCESSABLE_ENTITY, "password", "is invalid"),
        Error::InvalidBio => api(StatusCode::UNPROCESSABLE_ENTITY, "bio", "is invalid"),
        Error::InvalidImage => api(StatusCode::UNPROCESSABLE_ENTITY, "image", "is invalid"),
        Error::InvalidTitle => api(StatusCode::UNPROCESSABLE_ENTITY, "title", "is invalid"),
        Error::InvalidDescription => {
            api(StatusCode::UNPROCESSABLE_ENTITY, "description", "is invalid")
        }
        Error::InvalidBody => api(StatusCode::UNPROCESSABLE_ENTITY, "body", "is invalid"),
        Error::InvalidTags => api(StatusCode::UNPROCESSABLE_ENTITY, "tagList", "is invalid"),
        Error::InvalidUser => api(StatusCode::UNPROCESSABLE_ENTITY, "user", "is invalid"),
        Error::InvalidArticle => api(StatusCode::UNPROCESSABLE_ENTITY, "article", "is invalid"),
        Error::InvalidLimit => api(StatusCode::UNPROCESSABLE_ENTITY, "limit", "is invalid"),
        Error::InvalidOffset => api(StatusCode::UNPROCESSABLE_ENTITY, "offset", "is invalid"),
    }
}

fn decide(view: &View, cmd: &Command) -> Result<Reply, ApiError> {
    transition(view, cmd).map_err(map_kernel)
}

fn empty_view(actor: i64) -> View {
    View {
        actor: actor as u64,
        article_exists: false,
        article_author: 0,
        comment_exists: false,
        comment_author: 0,
        profile_exists: false,
        already: false,
    }
}

fn json_res(status: StatusCode, value: Value) -> Response {
    (status, Json(value)).into_response()
}

fn no_content() -> Response {
    Response::builder()
        .status(StatusCode::NO_CONTENT)
        .body(Body::empty())
        .unwrap()
}

fn server_error() -> ApiError {
    api(StatusCode::INTERNAL_SERVER_ERROR, "server", "error")
}

#[derive(Debug, Serialize, Deserialize)]
struct Claims {
    sub: String,
    exp: usize,
}

fn sign_token(secret: &[u8], user_id: i64) -> Result<String, ApiError> {
    let exp = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map_err(|_| server_error())?
        .as_secs()
        .saturating_add(JWT_TTL_SECS);
    let claims = Claims {
        sub: user_id.to_string(),
        exp: usize::try_from(exp).unwrap_or(usize::MAX),
    };
    jsonwebtoken::encode(
        &jsonwebtoken::Header::new(jsonwebtoken::Algorithm::HS256),
        &claims,
        &jsonwebtoken::EncodingKey::from_secret(secret),
    )
    .map_err(|_| server_error())
}

/// Decode transport and verify the signature; the kernel interprets the claims.
fn read_token(headers: &HeaderMap, secret: &[u8]) -> TokenInput {
    let Some(value) = headers.get(header::AUTHORIZATION) else {
        return TokenInput::Missing;
    };
    let Ok(value) = value.to_str() else { return TokenInput::Invalid; };
    if value.trim().is_empty() { return TokenInput::Missing; }
    let Some(raw) = value.strip_prefix("Token ") else { return TokenInput::Invalid; };
    let raw = raw.trim();
    if raw.is_empty() { return TokenInput::Invalid; }
    let mut validation = jsonwebtoken::Validation::new(jsonwebtoken::Algorithm::HS256);
    // Expiry is a kernel decision, with no library clock or leeway.
    validation.validate_exp = false;
    let Ok(data) = jsonwebtoken::decode::<Claims>(
        raw,
        &jsonwebtoken::DecodingKey::from_secret(secret),
        &validation,
    ) else { return TokenInput::Invalid; };
    let sub = match data.claims.sub.parse::<i64>() {
        Ok(id) => Subject::Parsed(id),
        Err(_) => Subject::Invalid,
    };
    TokenInput::Claims { sub, exp: data.claims.exp as u64 }
}

async fn viewer_id(headers: &HeaderMap, app: &App) -> Result<i64, ApiError> {
    let token = read_token(headers, &app.secret);
    let now = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map_err(|_| server_error())?.as_secs();
    let exists = match token {
        TokenInput::Claims { sub: Subject::Parsed(id), .. } => {
            sqlx::query_scalar::<_, bool>("SELECT EXISTS(SELECT 1 FROM users WHERE id = $1)")
                .bind(id).fetch_one(&app.pool).await?
        }
        _ => false,
    };
    token_actor(&token, now, exists).map_err(map_kernel)
}

async fn require_actor(headers: &HeaderMap, app: &App, _guest: &Command) -> Result<i64, ApiError> {
    let id = viewer_id(headers, app).await?;
    let _ = decide(&empty_view(id), &Command::CurrentUser)?;
    Ok(id)
}

fn read_object(body: &Bytes, key: &'static str) -> Result<Map<String, Value>, ApiError> {
    if body.is_empty() || body.iter().all(u8::is_ascii_whitespace) {
        return Err(api(StatusCode::UNPROCESSABLE_ENTITY, "body", "is invalid"));
    }
    let data: Value = serde_json::from_slice(body)
        .map_err(|_| api(StatusCode::UNPROCESSABLE_ENTITY, "body", "is invalid"))?;
    let Some(obj) = data.as_object() else {
        return Err(api(StatusCode::UNPROCESSABLE_ENTITY, key, "is invalid"));
    };
    let Some(inner) = obj.get(key) else {
        return Err(api(StatusCode::UNPROCESSABLE_ENTITY, key, "is invalid"));
    };
    inner
        .as_object()
        .cloned()
        .ok_or_else(|| api(StatusCode::UNPROCESSABLE_ENTITY, key, "is invalid"))
}

fn raw_text(obj: &Map<String, Value>, key: &str) -> RawText {
    match obj.get(key) {
        None => RawText::Absent,
        Some(Value::Null) => RawText::Null,
        Some(Value::String(s)) => RawText::Text(s.as_bytes().to_vec()),
        Some(_) => RawText::Invalid,
    }
}

fn text_string(obj: &Map<String, Value>, key: &str) -> String {
    obj.get(key)
        .and_then(Value::as_str)
        .unwrap_or("")
        .to_string()
}

fn parse_tags(obj: &Map<String, Value>) -> Result<TagInput, (TagInput, Vec<String>)> {
    match obj.get("tagList") {
        None => Ok(TagInput::Absent),
        Some(Value::Null) => Ok(TagInput::Null),
        Some(Value::Array(items)) => {
            let mut seen = HashSet::new();
            let mut tags = Vec::new();
            for item in items {
                let Some(s) = item.as_str() else {
                    return Ok(TagInput::Invalid);
                };
                if s.is_empty() || !seen.insert(s.to_string()) {
                    continue;
                }
                tags.push(s.to_string());
            }
            Err((TagInput::List, tags))
        }
        Some(_) => Ok(TagInput::Invalid),
    }
}

fn tag_parts(obj: &Map<String, Value>) -> (TagInput, Vec<String>) {
    match parse_tags(obj) {
        Ok(kind) => (kind, Vec::new()),
        Err(pair) => pair,
    }
}

fn raw_num(q: &HashMap<String, String>, key: &str) -> RawNum {
    match q.get(key) {
        None => RawNum::Absent,
        Some(s) => match s.parse::<u64>() {
            Ok(n) => RawNum::Value(n),
            Err(_) => RawNum::Invalid,
        },
    }
}

fn query_opt(q: &HashMap<String, String>, key: &str) -> Option<String> {
    q.get(key).cloned()
}

fn slug_string(title: &str, n: u64) -> String {
    let raw = title.as_bytes().to_vec();
    let bytes = make_slug(&raw, n);
    String::from_utf8(bytes).unwrap_or_else(|_| "article".to_string())
}

fn ts_col(col: &str) -> String {
    format!(r#"to_char({col} AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')"#)
}

fn article_select(include_body: bool) -> String {
    let body = if include_body { "a.body," } else { "" };
    format!(
        r#"
SELECT
  a.id,
  a.slug,
  a.title,
  a.description,
  {body}
  {created} AS created_at,
  {updated} AS updated_at,
  u.username AS author_username,
  u.bio AS author_bio,
  u.image AS author_image,
  (SELECT count(*)::int FROM favorites f WHERE f.article_id = a.id) AS favorites_count,
  EXISTS(SELECT 1 FROM favorites f WHERE f.article_id = a.id AND f.user_id = $1) AS favorited,
  EXISTS(SELECT 1 FROM follows fl WHERE fl.follower_id = $1 AND fl.followee_id = a.author_id) AS following,
  COALESCE(
    (SELECT array_agg(t.name ORDER BY at.position)
     FROM article_tags at
     JOIN tags t ON t.id = at.tag_id
     WHERE at.article_id = a.id),
    ARRAY[]::text[]
  ) AS tag_list
FROM articles a
JOIN users u ON u.id = a.author_id"#,
        created = ts_col("a.created_at"),
        updated = ts_col("a.updated_at"),
    )
}

#[derive(Debug, sqlx::FromRow)]
struct UserPublic {
    id: i64,
    username: String,
    email: String,
    bio: Option<String>,
    image: Option<String>,
}

#[derive(Debug, sqlx::FromRow)]
struct UserSecret {
    id: i64,
    username: String,
    email: String,
    bio: Option<String>,
    image: Option<String>,
    password_hash: String,
}

#[derive(Debug, sqlx::FromRow)]
struct ArticleDetail {
    slug: String,
    title: String,
    description: String,
    body: String,
    created_at: String,
    updated_at: String,
    author_username: String,
    author_bio: Option<String>,
    author_image: Option<String>,
    favorites_count: i32,
    favorited: bool,
    following: bool,
    tag_list: Vec<String>,
}

#[derive(Debug, sqlx::FromRow)]
struct ArticleList {
    slug: String,
    title: String,
    description: String,
    created_at: String,
    updated_at: String,
    author_username: String,
    author_bio: Option<String>,
    author_image: Option<String>,
    favorites_count: i32,
    favorited: bool,
    following: bool,
    tag_list: Vec<String>,
}

fn user_json(u: &UserPublic, token: &str) -> Value {
    json!({
        "email": u.email,
        "token": token,
        "username": u.username,
        "bio": u.bio,
        "image": u.image,
    })
}

fn profile_json(username: &str, bio: &Option<String>, image: &Option<String>, following: bool) -> Value {
    json!({
        "username": username,
        "bio": bio,
        "image": image,
        "following": following,
    })
}

fn detail_json(a: &ArticleDetail) -> Value {
    let mut value = json!({
        "slug": a.slug,
        "title": a.title,
        "description": a.description,
        "tagList": a.tag_list,
        "createdAt": a.created_at,
        "updatedAt": a.updated_at,
        "favorited": a.favorited,
        "favoritesCount": a.favorites_count,
        "author": profile_json(&a.author_username, &a.author_bio, &a.author_image, a.following),
    });
    if shows_body(ArticleView::Detail) {
        value["body"] = json!(a.body);
    }
    value
}

fn list_json(a: &ArticleList) -> Value {
    let mut value = json!({
        "slug": a.slug,
        "title": a.title,
        "description": a.description,
        "tagList": a.tag_list,
        "createdAt": a.created_at,
        "updatedAt": a.updated_at,
        "favorited": a.favorited,
        "favoritesCount": a.favorites_count,
        "author": profile_json(&a.author_username, &a.author_bio, &a.author_image, a.following),
    });
    if shows_body(ArticleView::List) {
        value["body"] = json!("");
    }
    value
}

async fn hash_password(password: String) -> Result<String, ApiError> {
    tokio::task::spawn_blocking(move || bcrypt::hash(password, BCRYPT_COST))
        .await
        .map_err(|_| server_error())?
        .map_err(|_| server_error())
}

async fn check_password(password: String, hash: String) -> Result<bool, ApiError> {
    tokio::task::spawn_blocking(move || bcrypt::verify(password, &hash))
        .await
        .map_err(|_| server_error())?
        .map_err(|_| server_error())
}

async fn load_user(pool: &PgPool, id: i64) -> Result<UserPublic, ApiError> {
    let row = sqlx::query_as::<_, UserPublic>(
        "SELECT id, username, email, bio, image FROM users WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(pool)
    .await?;
    token_user_exists(row.is_some()).map_err(map_kernel)?;
    row.ok_or_else(server_error)
}

async fn allocate_slug(pool: &PgPool, title: &str, exclude_id: i64) -> Result<String, ApiError> {
    for n in 0..100_000u64 {
        let slug = slug_string(title, n);
        let existing: Option<i64> =
            sqlx::query_scalar("SELECT id FROM articles WHERE slug = $1")
                .bind(&slug)
                .fetch_optional(pool)
                .await?;
        match existing {
            None => return Ok(slug),
            Some(id) if exclude_id != 0 && id == exclude_id => return Ok(slug),
            Some(_) => {}
        }
    }
    Err(api(StatusCode::CONFLICT, "slug", "has already been taken"))
}

async fn allocate_slug_tx(
    tx: &mut Transaction<'_, Postgres>,
    title: &str,
    exclude_id: i64,
) -> Result<String, ApiError> {
    for n in 0..100_000u64 {
        let slug = slug_string(title, n);
        let existing: Option<i64> =
            sqlx::query_scalar("SELECT id FROM articles WHERE slug = $1")
                .bind(&slug)
                .fetch_optional(&mut **tx)
                .await?;
        match existing {
            None => return Ok(slug),
            Some(id) if exclude_id != 0 && id == exclude_id => return Ok(slug),
            Some(_) => {}
        }
    }
    Err(api(StatusCode::CONFLICT, "slug", "has already been taken"))
}

async fn add_tags(
    tx: &mut Transaction<'_, Postgres>,
    article_id: i64,
    tags: &[String],
) -> Result<(), ApiError> {
    for (pos, name) in tags.iter().enumerate() {
        let tag_id: i64 = sqlx::query_scalar(
            "INSERT INTO tags (name) VALUES ($1)
             ON CONFLICT ON CONSTRAINT tags_name_unique DO UPDATE SET name = EXCLUDED.name
             RETURNING id",
        )
        .bind(name)
        .fetch_one(&mut **tx)
        .await?;
        sqlx::query(
            "INSERT INTO article_tags (article_id, tag_id, position) VALUES ($1, $2, $3)",
        )
        .bind(article_id)
        .bind(tag_id)
        .bind(pos as i32)
        .execute(&mut **tx)
        .await?;
    }
    Ok(())
}

async fn fetch_detail(pool: &PgPool, viewer: i64, slug: &str) -> Result<Option<ArticleDetail>, ApiError> {
    let sql = format!("{} WHERE a.slug = $2", article_select(true));
    let row = sqlx::query_as::<_, ArticleDetail>(&sql)
        .bind(viewer)
        .bind(slug)
        .fetch_optional(pool)
        .await?;
    Ok(row)
}

fn page_of(q: &HashMap<String, String>) -> Result<(i64, i64), ApiError> {
    let reply = decide(
        &empty_view(0),
        &Command::Page {
            limit: raw_num(q, "limit"),
            offset: raw_num(q, "offset"),
        },
    )?;
    match reply {
        Reply::Page { limit, offset } => {
            let limit = i64::try_from(limit)
                .map_err(|_| api(StatusCode::UNPROCESSABLE_ENTITY, "limit", "is invalid"))?;
            let offset = i64::try_from(offset)
                .map_err(|_| api(StatusCode::UNPROCESSABLE_ENTITY, "offset", "is invalid"))?;
            Ok((limit, offset))
        }
        _ => Err(server_error()),
    }
}

async fn healthz(State(app): State<App>) -> Result<Response, ApiError> {
    let _: i32 = sqlx::query_scalar("SELECT 1").fetch_one(&app.pool).await?;
    Ok(json_res(StatusCode::OK, json!({ "ok": true })))
}

async fn register(State(app): State<App>, body: Bytes) -> Result<Response, ApiError> {
    let obj = read_object(&body, "user")?;
    let username = raw_text(&obj, "username");
    let email = raw_text(&obj, "email");
    let password = raw_text(&obj, "password");
    decide(
        &empty_view(0),
        &Command::Register {
            username,
            email,
            password,
        },
    )?;
    let username = text_string(&obj, "username");
    let email = text_string(&obj, "email");
    let password = text_string(&obj, "password");
    let hash = hash_password(password).await?;
    let taken: Option<(String, String)> = sqlx::query_as(
        "SELECT username, email FROM users WHERE username = $1 OR email = $2",
    )
    .bind(&username)
    .bind(&email)
    .fetch_optional(&app.pool)
    .await?;
    if let Some((taken_user, _)) = taken {
        if taken_user == username {
            return Err(api(
                StatusCode::CONFLICT,
                "username",
                "has already been taken",
            ));
        }
        return Err(api(StatusCode::CONFLICT, "email", "has already been taken"));
    }
    let user = sqlx::query_as::<_, UserPublic>(
        "INSERT INTO users (username, email, password_hash)
         VALUES ($1, $2, $3)
         RETURNING id, username, email, bio, image",
    )
    .bind(&username)
    .bind(&email)
    .bind(&hash)
    .fetch_one(&app.pool)
    .await?;
    let token = sign_token(&app.secret, user.id)?;
    Ok(json_res(
        StatusCode::CREATED,
        json!({ "user": user_json(&user, &token) }),
    ))
}

async fn login(State(app): State<App>, body: Bytes) -> Result<Response, ApiError> {
    let obj = read_object(&body, "user")?;
    let email = raw_text(&obj, "email");
    let password = raw_text(&obj, "password");
    decide(
        &empty_view(0),
        &Command::Login { email, password },
    )?;
    let email = text_string(&obj, "email");
    let password = text_string(&obj, "password");
    let row = sqlx::query_as::<_, UserSecret>(
        "SELECT id, username, email, bio, image, password_hash FROM users WHERE email = $1",
    )
    .bind(&email)
    .fetch_optional(&app.pool)
    .await?;
    let (found, hash, user) = match row {
        Some(u) => {
            let hash = u.password_hash.clone();
            let public = UserPublic {
                id: u.id,
                username: u.username,
                email: u.email,
                bio: u.bio,
                image: u.image,
            };
            (true, hash, Some(public))
        }
        None => (false, app.dummy.clone(), None),
    };
    let ok = check_password(password, hash).await?;
    authenticate_login(found, ok).map_err(map_kernel)?;
    let user = user.ok_or_else(server_error)?;
    let token = sign_token(&app.secret, user.id)?;
    Ok(json_res(
        StatusCode::OK,
        json!({ "user": user_json(&user, &token) }),
    ))
}

async fn current_user(State(app): State<App>, headers: HeaderMap) -> Result<Response, ApiError> {
    let uid = require_actor(&headers, &app, &Command::CurrentUser).await?;
    match decide(&empty_view(uid), &Command::CurrentUser)? {
        Reply::Allow => {}
        _ => return Err(server_error()),
    }
    let user = load_user(&app.pool, uid).await?;
    let token = sign_token(&app.secret, user.id)?;
    Ok(json_res(
        StatusCode::OK,
        json!({ "user": user_json(&user, &token) }),
    ))
}

async fn update_user(State(app): State<App>, headers: HeaderMap, body: Bytes) -> Result<Response, ApiError> {
    let guest = Command::UpdateUser {
        username: RawText::Absent,
        email: RawText::Absent,
        password: RawText::Absent,
        bio: RawText::Absent,
        image: RawText::Absent,
    };
    let uid = require_actor(&headers, &app, &guest).await?;
    let obj = read_object(&body, "user")?;
    let reply = decide(
        &empty_view(uid),
        &Command::UpdateUser {
            username: raw_text(&obj, "username"),
            email: raw_text(&obj, "email"),
            password: raw_text(&obj, "password"),
            bio: raw_text(&obj, "bio"),
            image: raw_text(&obj, "image"),
        },
    )?;
    let Reply::UserUpdate {
        username,
        email,
        password,
        bio,
        image,
    } = reply
    else {
        return Err(server_error());
    };
    let username_val = text_string(&obj, "username");
    let email_val = text_string(&obj, "email");
    let password_val = if password == Norm::Set {
        hash_password(text_string(&obj, "password")).await?
    } else {
        String::new()
    };
    let bio_val = text_string(&obj, "bio");
    let image_val = text_string(&obj, "image");
    let mut tx = app.pool.begin().await?;
    let _ = load_user_tx(&mut tx, uid).await?;
    if username == Norm::Set {
        let clash: Option<i32> = sqlx::query_scalar(
            "SELECT 1 FROM users WHERE username = $1 AND id <> $2",
        )
        .bind(&username_val)
        .bind(uid)
        .fetch_optional(&mut *tx)
        .await?;
        if clash.is_some() {
            return Err(api(
                StatusCode::CONFLICT,
                "username",
                "has already been taken",
            ));
        }
    }
    if email == Norm::Set {
        let clash: Option<i32> =
            sqlx::query_scalar("SELECT 1 FROM users WHERE email = $1 AND id <> $2")
                .bind(&email_val)
                .bind(uid)
                .fetch_optional(&mut *tx)
                .await?;
        if clash.is_some() {
            return Err(api(StatusCode::CONFLICT, "email", "has already been taken"));
        }
    }
    let user = sqlx::query_as::<_, UserPublic>(
        "UPDATE users SET
           username = CASE WHEN $2::bool THEN $3::text ELSE username END,
           email = CASE WHEN $4::bool THEN $5::text ELSE email END,
           password_hash = CASE WHEN $6::bool THEN $7::text ELSE password_hash END,
           bio = CASE WHEN $8::bool THEN $9::text WHEN $10::bool THEN NULL::text ELSE bio END,
           image = CASE WHEN $11::bool THEN $12::text WHEN $13::bool THEN NULL::text ELSE image END
         WHERE id = $1
         RETURNING id, username, email, bio, image",
    )
    .bind(uid)
    .bind(username == Norm::Set)
    .bind(&username_val)
    .bind(email == Norm::Set)
    .bind(&email_val)
    .bind(password == Norm::Set)
    .bind(&password_val)
    .bind(bio == Norm::Set)
    .bind(&bio_val)
    .bind(bio == Norm::Clear)
    .bind(image == Norm::Set)
    .bind(&image_val)
    .bind(image == Norm::Clear)
    .fetch_one(&mut *tx)
    .await?;
    tx.commit().await?;
    let token = sign_token(&app.secret, user.id)?;
    Ok(json_res(
        StatusCode::OK,
        json!({ "user": user_json(&user, &token) }),
    ))
}

async fn load_user_tx(tx: &mut Transaction<'_, Postgres>, id: i64) -> Result<(), ApiError> {
    let row: Option<i64> = sqlx::query_scalar("SELECT id FROM users WHERE id = $1")
        .bind(id)
        .fetch_optional(&mut **tx)
        .await?;
    token_user_exists(row.is_some()).map_err(map_kernel)
}

async fn get_profile(
    State(app): State<App>,
    headers: HeaderMap,
    Path(username): Path<String>,
) -> Result<Response, ApiError> {
    let viewer = viewer_id(&headers, &app).await?;
    if viewer > 0 {
        load_user(&app.pool, viewer).await?;
    }
    let row: Option<(String, Option<String>, Option<String>, bool)> = sqlx::query_as(
        "SELECT username, bio, image,
           EXISTS(SELECT 1 FROM follows WHERE follower_id = $1 AND followee_id = users.id)
         FROM users WHERE username = $2",
    )
    .bind(viewer)
    .bind(&username)
    .fetch_optional(&app.pool)
    .await?;
    let Some((username, bio, image, following)) = row else {
        return Err(api(StatusCode::NOT_FOUND, "profile", "not found"));
    };
    Ok(json_res(
        StatusCode::OK,
        json!({ "profile": profile_json(&username, &bio, &image, following) }),
    ))
}

async fn set_follow(
    app: &App,
    headers: &HeaderMap,
    username: &str,
    on: bool,
) -> Result<Response, ApiError> {
    let cmd = if on { Command::Follow } else { Command::Unfollow };
    let uid = require_actor(headers, app, &cmd).await?;
    load_user(&app.pool, uid).await?;
    let row: Option<(i64, String, Option<String>, Option<String>)> = sqlx::query_as(
        "SELECT id, username, bio, image FROM users WHERE username = $1",
    )
    .bind(username)
    .fetch_optional(&app.pool)
    .await?;
    let (pid, uname, bio, image, exists) = match row {
        Some((id, uname, bio, image)) => (id, uname, bio, image, true),
        None => (0, String::new(), None, None, false),
    };
    let already = if exists {
        let v: bool = sqlx::query_scalar(
            "SELECT EXISTS(SELECT 1 FROM follows WHERE follower_id = $1 AND followee_id = $2)",
        )
        .bind(uid)
        .bind(pid)
        .fetch_one(&app.pool)
        .await?;
        v
    } else {
        false
    };
    let mut view = empty_view(uid);
    view.profile_exists = exists;
    view.already = already;
    let reply = decide(&view, &cmd)?;
    let Reply::Follow { following, changed } = reply else {
        return Err(server_error());
    };
    if changed {
        if on {
            sqlx::query(
                "INSERT INTO follows (follower_id, followee_id) VALUES ($1, $2)
                 ON CONFLICT DO NOTHING",
            )
            .bind(uid)
            .bind(pid)
            .execute(&app.pool)
            .await?;
        } else {
            sqlx::query("DELETE FROM follows WHERE follower_id = $1 AND followee_id = $2")
                .bind(uid)
                .bind(pid)
                .execute(&app.pool)
                .await?;
        }
    }
    Ok(json_res(
        StatusCode::OK,
        json!({ "profile": profile_json(&uname, &bio, &image, following) }),
    ))
}

async fn follow(
    State(app): State<App>,
    headers: HeaderMap,
    Path(username): Path<String>,
) -> Result<Response, ApiError> {
    set_follow(&app, &headers, &username, true).await
}

async fn unfollow(
    State(app): State<App>,
    headers: HeaderMap,
    Path(username): Path<String>,
) -> Result<Response, ApiError> {
    set_follow(&app, &headers, &username, false).await
}

async fn list_articles(
    app: &App,
    viewer: i64,
    q: &HashMap<String, String>,
    feed: bool,
) -> Result<Response, ApiError> {
    if feed {
        match decide(&empty_view(viewer), &Command::Feed)? {
            Reply::Allow => {}
            _ => return Err(server_error()),
        }
    }
    let (limit, offset) = page_of(q)?;
    if viewer > 0 {
        load_user(&app.pool, viewer).await?;
    }
    let select = article_select(false);
    let (rows, total) = if feed {
        let sql = format!(
            "{select} WHERE $1::bigint >= 0
             AND EXISTS (
               SELECT 1 FROM follows fl
               WHERE fl.follower_id = $1 AND fl.followee_id = a.author_id
             )
             ORDER BY a.created_at DESC, a.id DESC
             LIMIT $2 OFFSET $3"
        );
        let rows = sqlx::query_as::<_, ArticleList>(&sql)
            .bind(viewer)
            .bind(limit)
            .bind(offset)
            .fetch_all(&app.pool)
            .await?;
        let total: i64 = sqlx::query_scalar(
            "SELECT count(*)::bigint FROM articles a
             JOIN users u ON u.id = a.author_id
             WHERE $1::bigint >= 0
               AND EXISTS (
                 SELECT 1 FROM follows fl
                 WHERE fl.follower_id = $1 AND fl.followee_id = a.author_id
               )",
        )
        .bind(viewer)
        .fetch_one(&app.pool)
        .await?;
        (rows, total)
    } else {
        // Only the filters present go into the SQL, so each combination is
        // its own prepared statement and Postgres plans it for that shape.
        let tag = query_opt(q, "tag");
        let author = query_opt(q, "author");
        let favorited = query_opt(q, "favorited");
        let mut filters = String::new();
        let mut args: Vec<&String> = Vec::new();
        if let Some(t) = &tag {
            args.push(t);
            filters.push_str(&format!(
                " AND EXISTS (
               SELECT 1 FROM article_tags at
               JOIN tags t ON t.id = at.tag_id
               WHERE at.article_id = a.id AND t.name = ${})",
                args.len() + 1
            ));
        }
        if let Some(au) = &author {
            args.push(au);
            filters.push_str(&format!(" AND u.username = ${}", args.len() + 1));
        }
        if let Some(fv) = &favorited {
            args.push(fv);
            filters.push_str(&format!(
                " AND EXISTS (
               SELECT 1 FROM favorites fv
               JOIN users fu ON fu.id = fv.user_id
               WHERE fv.article_id = a.id AND fu.username = ${})",
                args.len() + 1
            ));
        }
        let n = args.len();
        let sql = format!(
            "{select} WHERE $1::bigint >= 0{filters}
             ORDER BY a.created_at DESC, a.id DESC
             LIMIT ${} OFFSET ${}",
            n + 2,
            n + 3
        );
        let mut rows_q = sqlx::query_as::<_, ArticleList>(&sql).bind(viewer);
        for a in &args {
            rows_q = rows_q.bind(*a);
        }
        let rows = rows_q.bind(limit).bind(offset).fetch_all(&app.pool).await?;
        let count_sql = format!(
            "SELECT count(*)::bigint FROM articles a
             JOIN users u ON u.id = a.author_id
             WHERE $1::bigint >= 0{filters}"
        );
        let mut count_q = sqlx::query_scalar::<_, i64>(&count_sql).bind(viewer);
        for a in &args {
            count_q = count_q.bind(*a);
        }
        let total: i64 = count_q.fetch_one(&app.pool).await?;
        (rows, total)
    };
    let articles: Vec<Value> = rows.iter().map(list_json).collect();
    Ok(json_res(
        StatusCode::OK,
        json!({ "articles": articles, "articlesCount": total }),
    ))
}

async fn feed(
    State(app): State<App>,
    headers: HeaderMap,
    Query(q): Query<HashMap<String, String>>,
) -> Result<Response, ApiError> {
    let uid = require_actor(&headers, &app, &Command::Feed).await?;
    list_articles(&app, uid, &q, true).await
}

async fn get_articles(
    State(app): State<App>,
    headers: HeaderMap,
    Query(q): Query<HashMap<String, String>>,
) -> Result<Response, ApiError> {
    let viewer = viewer_id(&headers, &app).await?;
    list_articles(&app, viewer, &q, false).await
}

async fn create_article(
    State(app): State<App>,
    headers: HeaderMap,
    body: Bytes,
) -> Result<Response, ApiError> {
    let guest = Command::CreateArticle {
        title: RawText::Absent,
        description: RawText::Absent,
        body: RawText::Absent,
        tags: TagInput::Absent,
    };
    let uid = require_actor(&headers, &app, &guest).await?;
    let obj = read_object(&body, "article")?;
    let (tags_kind, tags) = tag_parts(&obj);
    decide(
        &empty_view(uid),
        &Command::CreateArticle {
            title: raw_text(&obj, "title"),
            description: raw_text(&obj, "description"),
            body: raw_text(&obj, "body"),
            tags: tags_kind,
        },
    )?;
    let title = text_string(&obj, "title");
    let description = text_string(&obj, "description");
    let body = text_string(&obj, "body");
    let author = load_user(&app.pool, uid).await?;
    let mut created: Option<(String, i64, String, String)> = None;
    for _ in 0..8 {
        let slug = allocate_slug(&app.pool, &title, 0).await?;
        let mut tx = app.pool.begin().await?;
        let inserted = async {
            let row: (i64, String, String) = sqlx::query_as(&format!(
                "INSERT INTO articles (author_id, slug, title, description, body)
                 VALUES ($1, $2, $3, $4, $5)
                 RETURNING id, {c}, {u}",
                c = ts_col("created_at"),
                u = ts_col("updated_at"),
            ))
            .bind(uid)
            .bind(&slug)
            .bind(&title)
            .bind(&description)
            .bind(&body)
            .fetch_one(&mut *tx)
            .await?;
            add_tags(&mut tx, row.0, &tags).await?;
            tx.commit().await?;
            Ok::<(i64, String, String), ApiError>(row)
        }
        .await;
        match inserted {
            Ok((id, created_at, updated_at)) => {
                created = Some((slug, id, created_at, updated_at));
                break;
            }
            Err(e) if e.status == StatusCode::CONFLICT && e.field == "slug" => continue,
            Err(e) => return Err(e),
        }
    }
    let Some((slug, _id, created_at, updated_at)) = created else {
        return Err(api(StatusCode::CONFLICT, "slug", "has already been taken"));
    };
    let following: bool = sqlx::query_scalar(
        "SELECT EXISTS(SELECT 1 FROM follows WHERE follower_id = $1 AND followee_id = $2)",
    )
    .bind(uid)
    .bind(uid)
    .fetch_one(&app.pool)
    .await?;
    let mut article = json!({
        "slug": slug,
        "title": title,
        "description": description,
        "tagList": tags,
        "createdAt": created_at,
        "updatedAt": updated_at,
        "favorited": false,
        "favoritesCount": 0,
        "author": profile_json(&author.username, &author.bio, &author.image, following),
    });
    if shows_body(ArticleView::Detail) {
        article["body"] = json!(body);
    }
    Ok(json_res(StatusCode::CREATED, json!({ "article": article })))
}

async fn get_article(
    State(app): State<App>,
    headers: HeaderMap,
    Path(slug): Path<String>,
) -> Result<Response, ApiError> {
    let viewer = viewer_id(&headers, &app).await?;
    if viewer > 0 {
        load_user(&app.pool, viewer).await?;
    }
    let Some(row) = fetch_detail(&app.pool, viewer, &slug).await? else {
        return Err(api(StatusCode::NOT_FOUND, "article", "not found"));
    };
    Ok(json_res(StatusCode::OK, json!({ "article": detail_json(&row) })))
}

async fn update_article(
    State(app): State<App>,
    headers: HeaderMap,
    Path(slug): Path<String>,
    body: Bytes,
) -> Result<Response, ApiError> {
    let guest = Command::UpdateArticle {
        title: RawText::Absent,
        description: RawText::Absent,
        body: RawText::Absent,
        tags: TagInput::Absent,
    };
    let uid = require_actor(&headers, &app, &guest).await?;
    let obj = read_object(&body, "article")?;
    let (tags_kind, tags) = tag_parts(&obj);
    load_user(&app.pool, uid).await?;
    let found: Option<(i64, i64)> =
        sqlx::query_as("SELECT id, author_id FROM articles WHERE slug = $1")
            .bind(&slug)
            .fetch_optional(&app.pool)
            .await?;
    let (article_id, author, exists) = match found {
        Some((id, author)) => (id, author as u64, true),
        None => (0, 0, false),
    };
    let mut view = empty_view(uid);
    view.article_exists = exists;
    view.article_author = author;
    let reply = decide(
        &view,
        &Command::UpdateArticle {
            title: raw_text(&obj, "title"),
            description: raw_text(&obj, "description"),
            body: raw_text(&obj, "body"),
            tags: tags_kind,
        },
    )?;
    let Reply::ArticleUpdate {
        title,
        description,
        body,
        tags: tag_decision,
    } = reply
    else {
        return Err(server_error());
    };
    let title_val = text_string(&obj, "title");
    let description_val = text_string(&obj, "description");
    let body_val = text_string(&obj, "body");
    let mut tx = app.pool.begin().await?;
    let new_slug = if title == Norm::Set {
        allocate_slug_tx(&mut tx, &title_val, article_id).await?
    } else {
        String::new()
    };
    sqlx::query(
        "UPDATE articles SET
           updated_at = GREATEST(statement_timestamp(), updated_at + interval '1 millisecond'),
           title = CASE WHEN $2::bool THEN $3::text ELSE title END,
           slug = CASE WHEN $2::bool THEN $4::text ELSE slug END,
           description = CASE WHEN $5::bool THEN $6::text ELSE description END,
           body = CASE WHEN $7::bool THEN $8::text ELSE body END
         WHERE id = $1",
    )
    .bind(article_id)
    .bind(title == Norm::Set)
    .bind(&title_val)
    .bind(&new_slug)
    .bind(description == Norm::Set)
    .bind(&description_val)
    .bind(body == Norm::Set)
    .bind(&body_val)
    .execute(&mut *tx)
    .await?;
    if tag_decision == TagDecision::Replace {
        sqlx::query("DELETE FROM article_tags WHERE article_id = $1")
            .bind(article_id)
            .execute(&mut *tx)
            .await?;
        add_tags(&mut tx, article_id, &tags).await?;
    }
    let fresh: String = sqlx::query_scalar("SELECT slug FROM articles WHERE id = $1")
        .bind(article_id)
        .fetch_one(&mut *tx)
        .await?;
    tx.commit().await?;
    let Some(row) = fetch_detail(&app.pool, uid, &fresh).await? else {
        return Err(api(StatusCode::NOT_FOUND, "article", "not found"));
    };
    Ok(json_res(StatusCode::OK, json!({ "article": detail_json(&row) })))
}

async fn delete_article(
    State(app): State<App>,
    headers: HeaderMap,
    Path(slug): Path<String>,
) -> Result<Response, ApiError> {
    let uid = require_actor(&headers, &app, &Command::DeleteArticle).await?;
    load_user(&app.pool, uid).await?;
    let found: Option<(i64, i64)> =
        sqlx::query_as("SELECT id, author_id FROM articles WHERE slug = $1")
            .bind(&slug)
            .fetch_optional(&app.pool)
            .await?;
    let (article_id, author, exists) = match found {
        Some((id, author)) => (id, author as u64, true),
        None => (0, 0, false),
    };
    let mut view = empty_view(uid);
    view.article_exists = exists;
    view.article_author = author;
    match decide(&view, &Command::DeleteArticle)? {
        Reply::Allow => {}
        _ => return Err(server_error()),
    }
    sqlx::query("DELETE FROM articles WHERE id = $1")
        .bind(article_id)
        .execute(&app.pool)
        .await?;
    Ok(no_content())
}

async fn list_comments(
    State(app): State<App>,
    headers: HeaderMap,
    Path(slug): Path<String>,
) -> Result<Response, ApiError> {
    let viewer = viewer_id(&headers, &app).await?;
    if viewer > 0 {
        load_user(&app.pool, viewer).await?;
    }
    let article_id: Option<i64> = sqlx::query_scalar("SELECT id FROM articles WHERE slug = $1")
        .bind(&slug)
        .fetch_optional(&app.pool)
        .await?;
    let Some(article_id) = article_id else {
        return Err(api(StatusCode::NOT_FOUND, "article", "not found"));
    };
    let created = ts_col("c.created_at");
    let updated = ts_col("c.updated_at");
    let rows: Vec<(i64, String, String, String, String, Option<String>, Option<String>, bool)> =
        sqlx::query_as(&format!(
            "SELECT c.id, c.body, {created}, {updated},
                u.username, u.bio, u.image,
                EXISTS(
                  SELECT 1 FROM follows fl
                  WHERE fl.follower_id = $1 AND fl.followee_id = c.author_id
                )
             FROM comments c
             JOIN users u ON u.id = c.author_id
             WHERE c.article_id = $2
             ORDER BY c.created_at ASC, c.id ASC"
        ))
        .bind(viewer)
        .bind(article_id)
        .fetch_all(&app.pool)
        .await?;
    let comments: Vec<Value> = rows
        .into_iter()
        .map(|(id, body, created_at, updated_at, username, bio, image, following)| {
            json!({
                "id": id,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "body": body,
                "author": profile_json(&username, &bio, &image, following),
            })
        })
        .collect();
    Ok(json_res(StatusCode::OK, json!({ "comments": comments })))
}

async fn create_comment(
    State(app): State<App>,
    headers: HeaderMap,
    Path(slug): Path<String>,
    body: Bytes,
) -> Result<Response, ApiError> {
    let uid = require_actor(
        &headers,
        &app,
        &Command::CreateComment {
            body: RawText::Absent,
        },
    ).await?;
    let obj = read_object(&body, "comment")?;
    let author = load_user(&app.pool, uid).await?;
    let article_id: Option<i64> = sqlx::query_scalar("SELECT id FROM articles WHERE slug = $1")
        .bind(&slug)
        .fetch_optional(&app.pool)
        .await?;
    let mut view = empty_view(uid);
    view.article_exists = article_id.is_some();
    match decide(
        &view,
        &Command::CreateComment {
            body: raw_text(&obj, "body"),
        },
    )? {
        Reply::Allow => {}
        _ => return Err(server_error()),
    }
    let article_id = article_id.ok_or_else(|| api(StatusCode::NOT_FOUND, "article", "not found"))?;
    let text = text_string(&obj, "body");
    let created = ts_col("created_at");
    let updated = ts_col("updated_at");
    let (id, created_at, updated_at): (i64, String, String) = sqlx::query_as(&format!(
        "INSERT INTO comments (article_id, author_id, body)
         VALUES ($1, $2, $3)
         RETURNING id, {created}, {updated}"
    ))
    .bind(article_id)
    .bind(uid)
    .bind(&text)
    .fetch_one(&app.pool)
    .await?;
    let following: bool = sqlx::query_scalar(
        "SELECT EXISTS(SELECT 1 FROM follows WHERE follower_id = $1 AND followee_id = $2)",
    )
    .bind(uid)
    .bind(uid)
    .fetch_one(&app.pool)
    .await?;
    Ok(json_res(
        StatusCode::CREATED,
        json!({
            "comment": {
                "id": id,
                "createdAt": created_at,
                "updatedAt": updated_at,
                "body": text,
                "author": profile_json(&author.username, &author.bio, &author.image, following),
            }
        }),
    ))
}

async fn delete_comment(
    State(app): State<App>,
    headers: HeaderMap,
    Path((slug, comment_id)): Path<(String, String)>,
) -> Result<Response, ApiError> {
    let uid = require_actor(&headers, &app, &Command::DeleteComment).await?;
    let Ok(comment_id) = comment_id.parse::<i64>() else {
        return Err(api(StatusCode::UNPROCESSABLE_ENTITY, "comment", "is invalid"));
    };
    if comment_id <= 0 {
        return Err(api(StatusCode::UNPROCESSABLE_ENTITY, "comment", "is invalid"));
    }
    load_user(&app.pool, uid).await?;
    let article_id: Option<i64> = sqlx::query_scalar("SELECT id FROM articles WHERE slug = $1")
        .bind(&slug)
        .fetch_optional(&app.pool)
        .await?;
    let comment_author: Option<i64> = if let Some(article_id) = article_id {
        sqlx::query_scalar(
            "SELECT author_id FROM comments WHERE id = $1 AND article_id = $2",
        )
        .bind(comment_id)
        .bind(article_id)
        .fetch_optional(&app.pool)
        .await?
    } else {
        None
    };
    let mut view = empty_view(uid);
    view.article_exists = article_id.is_some();
    view.comment_exists = comment_author.is_some();
    view.comment_author = comment_author.unwrap_or(0) as u64;
    match decide(&view, &Command::DeleteComment)? {
        Reply::Allow => {}
        _ => return Err(server_error()),
    }
    sqlx::query("DELETE FROM comments WHERE id = $1")
        .bind(comment_id)
        .execute(&app.pool)
        .await?;
    Ok(no_content())
}

async fn set_favorite(
    app: &App,
    headers: &HeaderMap,
    slug: &str,
    on: bool,
) -> Result<Response, ApiError> {
    let cmd = if on {
        Command::Favorite
    } else {
        Command::Unfavorite
    };
    let uid = require_actor(headers, app, &cmd).await?;
    load_user(&app.pool, uid).await?;
    let found: Option<(i64, bool)> = sqlx::query_as(
        "SELECT a.id,
           EXISTS(SELECT 1 FROM favorites f WHERE f.article_id = a.id AND f.user_id = $2)
         FROM articles a WHERE a.slug = $1",
    )
    .bind(slug)
    .bind(uid)
    .fetch_optional(&app.pool)
    .await?;
    let (article_id, already, exists) = match found {
        Some((id, already)) => (id, already, true),
        None => (0, false, false),
    };
    let mut view = empty_view(uid);
    view.article_exists = exists;
    view.already = already;
    let reply = decide(&view, &cmd)?;
    let Reply::Favorite { delta, .. } = reply else {
        return Err(server_error());
    };
    match delta {
        Delta::Up => {
            sqlx::query(
                "INSERT INTO favorites (user_id, article_id) VALUES ($1, $2)
                 ON CONFLICT DO NOTHING",
            )
            .bind(uid)
            .bind(article_id)
            .execute(&app.pool)
            .await?;
        }
        Delta::Down => {
            sqlx::query("DELETE FROM favorites WHERE user_id = $1 AND article_id = $2")
                .bind(uid)
                .bind(article_id)
                .execute(&app.pool)
                .await?;
        }
        Delta::Same => {}
    }
    let Some(row) = fetch_detail(&app.pool, uid, slug).await? else {
        return Err(api(StatusCode::NOT_FOUND, "article", "not found"));
    };
    Ok(json_res(StatusCode::OK, json!({ "article": detail_json(&row) })))
}

async fn favorite(
    State(app): State<App>,
    headers: HeaderMap,
    Path(slug): Path<String>,
) -> Result<Response, ApiError> {
    set_favorite(&app, &headers, &slug, true).await
}

async fn unfavorite(
    State(app): State<App>,
    headers: HeaderMap,
    Path(slug): Path<String>,
) -> Result<Response, ApiError> {
    set_favorite(&app, &headers, &slug, false).await
}

async fn tags(State(app): State<App>) -> Result<Response, ApiError> {
    let names: Vec<String> =
        sqlx::query_scalar("SELECT name FROM tags ORDER BY name ASC")
            .fetch_all(&app.pool)
            .await?;
    Ok(json_res(StatusCode::OK, json!({ "tags": names })))
}

fn router(app: App) -> Router {
    Router::new()
        .route("/healthz", get(healthz))
        .route("/api/users", post(register))
        .route("/api/users/login", post(login))
        .route("/api/user", get(current_user).put(update_user))
        .route("/api/profiles/:username", get(get_profile))
        .route("/api/profiles/:username/follow", post(follow).delete(unfollow))
        .route("/api/articles/feed", get(feed))
        .route("/api/articles", get(get_articles).post(create_article))
        .route(
            "/api/articles/:slug",
            get(get_article).put(update_article).delete(delete_article),
        )
        .route(
            "/api/articles/:slug/comments",
            get(list_comments).post(create_comment),
        )
        .route(
            "/api/articles/:slug/comments/:comment_id",
            axum::routing::delete(delete_comment),
        )
        .route(
            "/api/articles/:slug/favorite",
            post(favorite).delete(unfavorite),
        )
        .route("/api/tags", get(tags))
        .with_state(app)
}

fn env_string(key: &str, default: &str) -> String {
    std::env::var(key)
        .ok()
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| default.to_string())
}

fn env_u32(key: &str, default: u32) -> u32 {
    std::env::var(key)
        .ok()
        .and_then(|s| s.parse().ok())
        .filter(|n| *n > 0)
        .unwrap_or(default)
}

async fn run() -> Result<(), Box<dyn std::error::Error>> {
    let db_url = env_string(
        "DATABASE_URL",
        "postgres://conduit:conduit@127.0.0.1:54329/conduit",
    );
    let secret = env_string("JWT_SECRET", "conduit-benchmark-secret");
    let port = env_string("PORT", "8004");
    let pool_size = env_u32("DB_POOL", 8);
    let pool = PgPoolOptions::new()
        .max_connections(pool_size)
        .min_connections(1.min(pool_size))
        // sqlx pings every connection on checkout by default, one extra
        // round trip per query; pgx and node-postgres do not.
        .test_before_acquire(false)
        .connect(&db_url)
        .await?;
    let dummy = bcrypt::hash("dummy-password-for-timing", BCRYPT_COST)?;
    let app = App {
        pool,
        secret: secret.into_bytes(),
        dummy,
    };
    let addr = format!("127.0.0.1:{port}");
    let listener = tokio::net::TcpListener::bind(&addr).await?;
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
