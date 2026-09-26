//! axum integration. Mount i5h in your own axum app: extract [`Actor`], build a
//! kernel command, call [`I5h::respond`]. Or merge [`rpc_router`].
//!
//! The authenticator and the JSON codec are trusted, not verified. Keep them
//! small. Permission decisions belong in the kernel.

use axum::extract::{FromRef, FromRequestParts, State};
use axum::http::request::Parts;
use axum::http::{HeaderMap, StatusCode};
use axum::response::{IntoResponse, Response};
use axum::routing::post;
use axum::{Json, Router};
use i5h::Kernel;
use i5h_pg::{DbError, Engine, ReplyCodec, Store};
use serde_json::{json, Value};
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(Debug)]
pub struct AuthError(pub String);

pub trait Authenticator<K: Kernel>: Send + Sync + 'static {
    fn authenticate(&self, headers: &HeaderMap) -> Result<K::Principal, AuthError>;
}

pub trait Api<K: Kernel>: Send + Sync + 'static {
    fn decode_command(body: Value) -> Result<K::Command, String>;
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
            (StatusCode::UNAUTHORIZED, Json(json!({ "error": m }))).into_response()
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
            Ok(Ok(reply)) => (StatusCode::OK, Json(S::encode_reply(&reply))).into_response(),
            Ok(Err(refusal)) => {
                let (status, body) = S::encode_error(&refusal);
                (status, Json(body)).into_response()
            }
            Err(DbError::IdempotencyConflict) => {
                (StatusCode::UNPROCESSABLE_ENTITY, Json(json!({ "error": "idempotency key reused" }))).into_response()
            }
            Err(e) => {
                tracing::error!(error = %e, "request failed");
                (StatusCode::SERVICE_UNAVAILABLE, Json(json!({ "error": "unavailable" }))).into_response()
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

async fn rpc<K, S>(State(i5h): State<I5h<K, S>>, actor: Actor<K>, headers: HeaderMap, body: Json<Value>) -> Response
where
    K: Kernel,
    S: Store<K> + ReplyCodec<K> + Api<K>,
{
    match S::decode_command(body.0) {
        Ok(cmd) => i5h.respond(&actor, cmd, &headers).await,
        Err(m) => (StatusCode::BAD_REQUEST, Json(json!({ "error": m }))).into_response(),
    }
}
