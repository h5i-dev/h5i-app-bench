//! Integration between i5h and axum.
//!
//! You can mount i5h in any axum application. A handler takes an [`Actor`],
//! which authenticates the request, builds a kernel command from the request,
//! and calls [`I5h::respond`], which runs the command and renders the reply.
//! If JSON commands are enough, merge [`rpc_router`] to get a ready-made
//! `POST /rpc` route instead.
//!
//! Decoding requests into commands is trusted rather than verified, although
//! the kernel's theorems hold for every command, so a wrong decoding cannot do
//! anything a client could not ask for directly. Token parsing and reply
//! rendering use the verified `i5h-token` and `i5h-json` crates.
//!
//! # Example
//!
//! ```ignore
//! async fn approve(State(app): State<App>, actor: Actor<DocsApp>, Path(doc): Path<u64>, h: HeaderMap) -> Response {
//!     app.respond(&actor, Command::Approve { doc }, &h).await
//! }
//!
//! let router = Router::new()
//!     .route("/documents/{id}/approve", post(approve))
//!     .with_state(app.clone())
//!     .merge(rpc_router(app));
//! ```

use axum::extract::{FromRef, FromRequestParts, State};
use axum::http::request::Parts;
use axum::http::{header, HeaderMap, StatusCode};
use axum::response::{IntoResponse, Response};
use axum::routing::post;
use axum::{Json, Router};
use i5h::Kernel;
use i5h_pg::{DbError, Engine, ReplyCodec, Store};
use i5h_json::Value;
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Debug)]
pub struct AuthError(pub String);

pub trait Authenticator<K: Kernel>: Send + Sync + 'static {
    fn authenticate(&self, headers: &HeaderMap) -> Result<K::Principal, AuthError>;
}

pub trait Api<K: Kernel>: Send + Sync + 'static {
    fn decode_command(body: serde_json::Value) -> Result<K::Command, String>;
    fn encode_reply(reply: &K::Reply) -> Value;
    fn encode_error(err: &K::Error) -> (StatusCode, Value);
}

/// Bearer tokens of the form `v1.<tenant>.<user>.<expiry-unix>.<hex hmac-sha256>`.
pub struct HmacAuth<K: Kernel> {
    secret: Vec<u8>,
    principal: fn(tenant: u64, user: u64) -> K::Principal,
}

impl<K: Kernel> HmacAuth<K> {
    pub fn new(secret: impl Into<Vec<u8>>, principal: fn(u64, u64) -> K::Principal) -> Self {
        HmacAuth { secret: secret.into(), principal }
    }

    fn tag(&self, payload: &[u8]) -> Vec<u8> {
        libcrux_hmac::hmac(libcrux_hmac::Algorithm::Sha256, &self.secret, payload, None)
    }

    pub fn issue(&self, tenant: u64, user: u64, ttl_secs: u64) -> String {
        let payload = i5h_token::encode_payload(tenant, user, now() + ttl_secs);
        let token = i5h_token::join(&payload, &self.tag(&payload));
        String::from_utf8(token).expect("tokens are ascii")
    }

    /// Parsing is verified (`i5h-token/proofs`): the signed payload names
    /// exactly one tenant, user and expiry.
    fn verify(&self, token: &str) -> Result<(u64, u64), AuthError> {
        let err = |m: &str| AuthError(m.to_string());
        let t = i5h_token::parse(token.as_bytes()).ok_or_else(|| err("malformed token"))?;
        if !ct_eq(&self.tag(&t.payload), &t.sig) {
            return Err(err("bad signature"));
        }
        if t.exp < now() {
            return Err(err("token expired"));
        }
        Ok((t.tenant, t.user))
    }
}

/// Constant-time equality, so the comparison does not leak the tag.
fn ct_eq(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    a.iter().zip(b).fold(0u8, |acc, (x, y)| acc | (x ^ y)) == 0
}

impl<K: Kernel> Authenticator<K> for HmacAuth<K> {
    fn authenticate(&self, headers: &HeaderMap) -> Result<K::Principal, AuthError> {
        let h = headers.get("authorization").ok_or_else(|| AuthError("missing authorization".into()))?;
        let h = h.to_str().map_err(|_| AuthError("bad authorization header".into()))?;
        let token = h.strip_prefix("Bearer ").ok_or_else(|| AuthError("expected bearer token".into()))?;
        let (tenant, user) = self.verify(token)?;
        Ok((self.principal)(tenant, user))
    }
}

fn now() -> u64 {
    SystemTime::now().duration_since(UNIX_EPOCH).map(|d| d.as_secs()).unwrap_or(0)
}

/// Shared authenticator, extracted from your axum state via `FromRef`.
pub struct Auth<K: Kernel>(pub Arc<dyn Authenticator<K>>);

impl<K: Kernel> Clone for Auth<K> {
    fn clone(&self) -> Self {
        Auth(self.0.clone())
    }
}

/// The authenticated caller. Use as an axum extractor in your own handlers.
pub struct Actor<K: Kernel>(pub K::Principal);

impl<K: Kernel, St: Send + Sync> FromRequestParts<St> for Actor<K>
where
    Auth<K>: FromRef<St>,
{
    type Rejection = Response;

    async fn from_request_parts(parts: &mut Parts, state: &St) -> Result<Self, Self::Rejection> {
        let auth = Auth::<K>::from_ref(state);
        auth.0.authenticate(&parts.headers).map(Actor).map_err(|AuthError(m)| {
            reply(StatusCode::UNAUTHORIZED, error_body(&m))
        })
    }
}

/// Handle to the engine for axum handlers. It is the only way to reach the
/// database, so every route goes through the kernel.
pub struct I5h<K: Kernel, S: Store<K>> {
    engine: Arc<Engine<K, S>>,
    auth: Auth<K>,
}

impl<K: Kernel, S: Store<K>> Clone for I5h<K, S> {
    fn clone(&self) -> Self {
        I5h { engine: self.engine.clone(), auth: self.auth.clone() }
    }
}

impl<K: Kernel, S: Store<K>> FromRef<I5h<K, S>> for Auth<K> {
    fn from_ref(i: &I5h<K, S>) -> Self {
        i.auth.clone()
    }
}

impl<K: Kernel, S: Store<K>> I5h<K, S> {
    pub fn new(engine: Arc<Engine<K, S>>, auth: impl Authenticator<K>) -> Self {
        I5h { engine, auth: Auth(Arc::new(auth)) }
    }

    pub fn engine(&self) -> &Engine<K, S> {
        &self.engine
    }

    /// Run `cmd` and render the result. Honors the `Idempotency-Key` header.
    pub async fn respond(&self, actor: &Actor<K>, cmd: K::Command, headers: &HeaderMap) -> Response
    where
        S: ReplyCodec<K> + Api<K>,
    {
        let key = headers.get("idempotency-key").and_then(|v| v.to_str().ok());
        let result = match key {
            Some(k) => self.engine.execute_idempotent(&actor.0, k, &cmd).await,
            None => self.engine.execute(&actor.0, &cmd).await,
        };
        match result {
            Ok(Ok(r)) => reply(StatusCode::OK, S::encode_reply(&r)),
            Ok(Err(refusal)) => {
                let (status, body) = S::encode_error(&refusal);
                reply(status, body)
            }
            Err(DbError::IdempotencyConflict) => reply(StatusCode::UNPROCESSABLE_ENTITY, error_body("idempotency key reused")),
            Err(e) => {
                tracing::error!(error = %e, "request failed");
                reply(StatusCode::SERVICE_UNAVAILABLE, error_body("unavailable"))
            }
        }
    }
}

/// Ready-made `POST /rpc` taking a JSON command. Merge or nest it into your router.
pub fn rpc_router<K, S>(i5h: I5h<K, S>) -> Router
where
    K: Kernel,
    S: Store<K> + ReplyCodec<K> + Api<K>,
{
    Router::new().route("/rpc", post(rpc::<K, S>)).with_state(i5h)
}

async fn rpc<K, S>(
    State(i5h): State<I5h<K, S>>,
    actor: Actor<K>,
    headers: HeaderMap,
    body: Json<serde_json::Value>,
) -> Response
where
    K: Kernel,
    S: Store<K> + ReplyCodec<K> + Api<K>,
{
    match S::decode_command(body.0) {
        Ok(cmd) => i5h.respond(&actor, cmd, &headers).await,
        Err(m) => reply(StatusCode::BAD_REQUEST, error_body(&m)),
    }
}

/// Every response body goes through the verified writer (`i5h-json`).
pub fn reply(status: StatusCode, body: Value) -> Response {
    (status, [(header::CONTENT_TYPE, "application/json")], body.to_bytes()).into_response()
}

/// `{"error": <message>}`.
pub fn error_body(msg: &str) -> Value {
    Value::obj([("error", Value::str(msg))])
}
