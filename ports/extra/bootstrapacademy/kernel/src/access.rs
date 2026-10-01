//! `academy_auth`: `Authentication`'s checks (contracts/src/lib.rs),
//! `AuthServiceImpl` (impl/src/lib.rs), and the cache half of
//! `AuthAccessTokenServiceImpl` (impl/src/access_token.rs).
use crate::{valkey, cache_write, repo, generate, Authentication, CacheKey, CacheValue, Config, Ctx, Env, Error,
    User, UserIdOrSelf, Write};

/// `Authentication::ensure_admin`.
pub fn ensure_admin(auth: &Authentication) -> Result<(), Error> {
    if !auth.admin {
        return Err(Error::Admin);
    }
    if auth.mfa_verified { Ok(()) } else { Err(Error::AdminMfa) }
}

/// `Authentication::ensure_email_verified`.
pub fn ensure_email_verified(auth: &Authentication) -> Result<(), Error> {
    if auth.email_verified { Ok(()) } else { Err(Error::EmailVerified) }
}

/// `Authentication::ensure_self_or_admin`.
pub fn ensure_self_or_admin(auth: &Authentication, user_id: u64) -> Result<(), Error> {
    if auth.user_id == user_id {
        return Ok(());
    }
    ensure_admin(auth)
}

/// `UserIdOrSelf::unwrap_or`.
pub fn unwrap_or(user_id: UserIdOrSelf, self_user_id: u64) -> u64 {
    match user_id {
        UserIdOrSelf::UserId(u) => u,
        UserIdOrSelf::Slf => self_user_id,
    }
}

/// `AuthAccessTokenServiceImpl::invalidate`.
pub fn invalidate(c: &Config, ctx: &mut Ctx, env: &Env, refresh_token_hash: u64) {
    let e = valkey::entry(env.now, CacheKey::Invalidated(refresh_token_hash), CacheValue::Unit, Some(c.access_token_ttl));
    cache_write(ctx, Write::CacheSet(e));
}

/// `AuthAccessTokenServiceImpl::is_invalidated`.
pub fn is_invalidated(ctx: &Ctx, env: &Env, refresh_token_hash: u64) -> bool {
    match valkey::get(&ctx.cache, env.now, &CacheKey::Invalidated(refresh_token_hash)) {
        Some(_) => true,
        None => false,
    }
}

/// `AuthServiceImpl::authenticate`. `token` is `verify`'s result.
pub fn authenticate(ctx: &Ctx, env: &Env, token: &Option<Authentication>) -> Result<Authentication, Error> {
    let auth = match token {
        Some(a) => *a,
        None => return Err(Error::InvalidToken),
    };
    if is_invalidated(ctx, env, auth.refresh_token_hash) {
        return Err(Error::InvalidToken);
    }
    // Ordinary authority requires a current live session and an enabled account.
    let user = match repo::get_composite(&ctx.db, auth.user_id) {
        Some(u) => {
            if u.user.enabled {
                u
            } else {
                return Err(Error::InvalidToken);
            }
        }
        None => return Err(Error::InvalidToken),
    };
    let session = match repo::get_by_refresh_token_hash(&ctx.db, auth.refresh_token_hash) {
        Some(s) => {
            if s.id == auth.session_id && s.user_id == auth.user_id {
                s
            } else {
                return Err(Error::InvalidToken);
            }
        }
        None => return Err(Error::InvalidToken),
    };
    Ok(Authentication {
        user_id: auth.user_id,
        session_id: auth.session_id,
        refresh_token_hash: auth.refresh_token_hash,
        admin: user.user.admin,
        email_verified: user.user.email_verified,
        mfa_verified: session.mfa_verified,
    })
}

fn argon2_verify(env: &Env, password: &[u8], hash: &[u8]) -> bool {
    let mut i = 0;
    while i < env.argon2_ok.len() {
        if crate::bytes_eq(&env.argon2_ok[i].0, password) && crate::bytes_eq(&env.argon2_ok[i].1, hash) {
            return true;
        }
        i += 1;
    }
    false
}

/// `AuthServiceImpl::authenticate_by_password`.
pub fn authenticate_by_password(ctx: &Ctx, env: &Env, user_id: u64, password: &[u8]) -> Result<(), Error> {
    let password_hash = match repo::get_password_hash(&ctx.db, user_id) {
        Some(h) => h,
        None => return Err(Error::InvalidCredentials),
    };
    if argon2_verify(env, password, &password_hash) { Ok(()) } else { Err(Error::InvalidCredentials) }
}

/// `AuthenticateByRefreshTokenError`, without `Other`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RefreshTokenError {
    Invalid,
    Expired(u64),
}

/// `AuthRefreshTokenServiceImpl::hash`: SHA-256, taken as injective.
pub fn refresh_token_hash(refresh_token: u64) -> u64 {
    refresh_token
}

/// `AuthServiceImpl::authenticate_by_refresh_token`.
pub fn authenticate_by_refresh_token(
    c: &Config,
    ctx: &Ctx,
    env: &Env,
    refresh_token: u64,
) -> Result<u64, RefreshTokenError> {
    let hash = refresh_token_hash(refresh_token);
    let session = match repo::get_by_refresh_token_hash(&ctx.db, hash) {
        Some(s) => s,
        None => return Err(RefreshTokenError::Invalid),
    };
    if env.now >= session.updated_at.saturating_add(c.refresh_token_ttl) {
        return Err(RefreshTokenError::Expired(session.id));
    }
    Ok(session.id)
}

/// `auth_contracts::Tokens`; the access token is given by its claims.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Tokens {
    pub access_token: Authentication,
    pub refresh_token: u64,
    pub refresh_token_hash: u64,
}

/// `AuthServiceImpl::issue_tokens`, with `AuthRefreshTokenServiceImpl::issue`
/// and `AuthAccessTokenServiceImpl::issue`.
pub fn issue_tokens(ctx: &mut Ctx, user: &User, session_id: u64, mfa_verified: bool) -> Tokens {
    let refresh_token = generate(ctx);
    let refresh_token_hash = refresh_token_hash(refresh_token);
    let access_token = Authentication {
        user_id: user.id,
        session_id,
        refresh_token_hash,
        admin: user.admin,
        email_verified: user.email_verified,
        mfa_verified,
    };
    Tokens { access_token, refresh_token, refresh_token_hash }
}

/// `AuthServiceImpl::list_refresh_token_hashes`.
pub fn list_refresh_token_hashes(ctx: &Ctx, user_id: u64) -> Vec<u64> {
    repo::list_refresh_token_hashes_by_user(&ctx.db, user_id)
}

/// `AuthServiceImpl::invalidate_access_tokens_of`.
pub fn invalidate_access_tokens_of(c: &Config, ctx: &mut Ctx, env: &Env, hashes: &Vec<u64>) {
    let mut i = 0;
    while i < hashes.len() {
        invalidate(c, ctx, env, hashes[i]);
        i += 1;
    }
}

/// `AuthServiceImpl::invalidate_access_tokens`.
pub fn invalidate_access_tokens(c: &Config, ctx: &mut Ctx, env: &Env, user_id: u64) {
    let hashes = list_refresh_token_hashes(ctx, user_id);
    invalidate_access_tokens_of(c, ctx, env, &hashes);
}
