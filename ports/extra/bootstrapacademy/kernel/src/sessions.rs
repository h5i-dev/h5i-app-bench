//! `academy_core/session/impl`: `SessionServiceImpl` (session.rs) and
//! `SessionFeatureServiceImpl` (lib.rs).
use crate::access::{
    authenticate, authenticate_by_password, authenticate_by_refresh_token, ensure_admin, ensure_self_or_admin,
    invalidate, invalidate_access_tokens, issue_tokens, unwrap_or, RefreshTokenError,
};
use crate::mfa::{self, MfaAuthenticateResult};
use crate::throttle;
use crate::{
    commit, repo, db_write, generate, Authentication, Config, Ctx, Env, Error, Login, NameOrEmail, Reply, Session,
    SessionCreateCommand, UserComposite, UserIdOrSelf, Write,
};

/// `SessionServiceImpl::create`.
pub fn create(
    ctx: &mut Ctx,
    env: &Env,
    user_composite: UserComposite,
    device_name: Option<Vec<u8>>,
    update_last_login: bool,
    mfa_verified: bool,
) -> Result<Login, Error> {
    let mut user_composite = user_composite;
    // `anyhow::ensure!`
    if !user_composite.user.enabled {
        return Err(Error::Internal);
    }
    let id = generate(ctx);
    let now = env.now;
    let session = Session {
        id,
        user_id: user_composite.user.id,
        device_name,
        created_at: now,
        updated_at: now,
        mfa_verified,
    };
    let tokens = issue_tokens(ctx, &user_composite.user, session.id, session.mfa_verified);
    db_write(ctx, Write::CreateSession(session.clone()));
    db_write(ctx, Write::SaveRefreshTokenHash { session_id: session.id, hash: tokens.refresh_token_hash });
    if update_last_login {
        db_write(ctx, Write::UpdateLastLogin { user_id: user_composite.user.id, last_login: now });
        user_composite.user.last_login = Some(now);
    }
    Ok(Login {
        user_composite,
        session,
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
    })
}

/// `SessionServiceImpl::refresh`; `Error::NotFound` is its `NotFound`.
pub fn refresh(c: &Config, ctx: &mut Ctx, env: &Env, session_id: u64) -> Result<Login, Error> {
    let refresh_token_hash = match repo::get_refresh_token_hash(&ctx.db, session_id) {
        Some(h) => h,
        None => return Err(Error::NotFound),
    };
    let session = match repo::get_session(&ctx.db, session_id) {
        Some(s) => s,
        None => return Err(Error::NotFound),
    };
    let user_composite = match repo::get_composite(&ctx.db, session.user_id) {
        Some(u) => u,
        None => return Err(Error::NotFound),
    };
    if !user_composite.user.enabled {
        return Err(Error::NotFound);
    }
    // invalidate old access token
    invalidate(c, ctx, env, refresh_token_hash);
    // issue new token pair
    let tokens = issue_tokens(ctx, &user_composite.user, session_id, session.mfa_verified);
    // update session
    if !repo::session_update_applies(&ctx.db, session.id) {
        return Err(Error::NotFound);
    }
    db_write(ctx, Write::UpdateSessionUpdatedAt { session_id: session.id, updated_at: env.now });
    let mut session = session;
    session.updated_at = env.now;
    db_write(ctx, Write::SaveRefreshTokenHash { session_id: session.id, hash: tokens.refresh_token_hash });
    Ok(Login {
        user_composite,
        session,
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
    })
}

/// `SessionServiceImpl::delete`: whether the session existed.
pub fn delete(c: &Config, ctx: &mut Ctx, env: &Env, session_id: u64) -> bool {
    match repo::get_refresh_token_hash(&ctx.db, session_id) {
        Some(h) => invalidate(c, ctx, env, h),
        None => {}
    }
    let existed = match repo::get_session(&ctx.db, session_id) {
        Some(_) => true,
        None => false,
    };
    db_write(ctx, Write::DeleteSession { session_id });
    existed
}

/// `SessionServiceImpl::delete_by_user`.
pub fn delete_user_sessions(c: &Config, ctx: &mut Ctx, env: &Env, user_id: u64) {
    invalidate_access_tokens(c, ctx, env, user_id);
    db_write(ctx, Write::DeleteSessionsByUser { user_id });
}

/// `SessionFeatureServiceImpl::get_current_session`.
pub fn get_current_session(ctx: &mut Ctx, env: &Env, token: &Option<Authentication>) -> Result<Reply, Error> {
    let auth = authenticate(ctx, env, token)?;
    match repo::get_session(&ctx.db, auth.session_id) {
        Some(s) => Ok(Reply::Session(s)),
        None => Err(Error::Internal),
    }
}

/// `SessionFeatureServiceImpl::list_by_user`.
pub fn list_by_user(ctx: &mut Ctx, env: &Env, token: &Option<Authentication>, user_id: UserIdOrSelf) -> Result<Reply, Error> {
    let auth = authenticate(ctx, env, token)?;
    let user_id = unwrap_or(user_id, auth.user_id);
    ensure_self_or_admin(&auth, user_id)?;
    Ok(Reply::Sessions(repo::list_sessions_by_user(&ctx.db, user_id)))
}

/// `SessionFeatureServiceImpl::create_session`.
pub fn create_session(c: &Config, ctx: &mut Ctx, env: &Env, cmd: &SessionCreateCommand) -> Result<Reply, Error> {
    let device_name = crate::clone_bytes_opt(&cmd.device_name);
    let (user_composite, mfa_verified) = prove_credentials(c, ctx, env, cmd)?;
    if !user_composite.user.enabled {
        return Err(Error::UserDisabled);
    }
    let login = create(ctx, env, user_composite, device_name, true, mfa_verified)?;
    commit(ctx);
    Ok(Reply::Login(login))
}

/// `SessionFeatureServiceImpl::prove_recipient`: works for a disabled account.
pub fn prove_recipient(c: &Config, ctx: &mut Ctx, env: &Env, cmd: &SessionCreateCommand) -> Result<Reply, Error> {
    let (user, _mfa_verified) = prove_credentials(c, ctx, env, cmd)?;
    commit(ctx);
    Ok(Reply::UserId(user.user.id))
}

/// `SessionFeatureServiceImpl::impersonate`.
pub fn impersonate(ctx: &mut Ctx, env: &Env, token: &Option<Authentication>, user_id: u64) -> Result<Reply, Error> {
    let auth = authenticate(ctx, env, token)?;
    ensure_admin(&auth)?;
    let user_composite = match repo::get_composite(&ctx.db, user_id) {
        Some(u) => u,
        None => return Err(Error::NotFound),
    };
    if !user_composite.user.enabled {
        return Err(Error::NotFound);
    }
    // Impersonation never involves the second factor of the impersonated user.
    let login = create(ctx, env, user_composite, None, false, false)?;
    commit(ctx);
    Ok(Reply::Login(login))
}

/// `SessionFeatureServiceImpl::refresh_session`.
pub fn refresh_session(c: &Config, ctx: &mut Ctx, env: &Env, refresh_token: u64) -> Result<Reply, Error> {
    let session_id = match authenticate_by_refresh_token(c, ctx, env, refresh_token) {
        Ok(id) => id,
        Err(RefreshTokenError::Invalid) => return Err(Error::InvalidRefreshToken),
        Err(RefreshTokenError::Expired(id)) => {
            // Deleted inside the transaction, which is then dropped: only the
            // cache invalidation stays.
            delete(c, ctx, env, id);
            return Err(Error::InvalidRefreshToken);
        }
    };
    let login = match refresh(c, ctx, env, session_id) {
        Ok(l) => l,
        Err(Error::NotFound) => return Err(Error::InvalidRefreshToken),
        Err(e) => return Err(e),
    };
    commit(ctx);
    Ok(Reply::Login(login))
}

/// `SessionFeatureServiceImpl::delete_session`.
pub fn delete_session(
    c: &Config,
    ctx: &mut Ctx,
    env: &Env,
    token: &Option<Authentication>,
    user_id: UserIdOrSelf,
    session_id: u64,
) -> Result<Reply, Error> {
    let auth = authenticate(ctx, env, token)?;
    let user_id = unwrap_or(user_id, auth.user_id);
    ensure_self_or_admin(&auth, user_id)?;
    let session = match repo::get_session(&ctx.db, session_id) {
        Some(s) => {
            if s.user_id == user_id {
                s
            } else {
                return Err(Error::NotFound);
            }
        }
        None => return Err(Error::NotFound),
    };
    delete(c, ctx, env, session.id);
    commit(ctx);
    Ok(Reply::Done)
}

/// `SessionFeatureServiceImpl::delete_current_session`.
pub fn delete_current_session(c: &Config, ctx: &mut Ctx, env: &Env, token: &Option<Authentication>) -> Result<Reply, Error> {
    let auth = authenticate(ctx, env, token)?;
    delete(c, ctx, env, auth.session_id);
    commit(ctx);
    Ok(Reply::Done)
}

/// `SessionFeatureServiceImpl::delete_by_user`.
pub fn delete_by_user(
    c: &Config,
    ctx: &mut Ctx,
    env: &Env,
    token: &Option<Authentication>,
    user_id: UserIdOrSelf,
) -> Result<Reply, Error> {
    let auth = authenticate(ctx, env, token)?;
    let user_id = unwrap_or(user_id, auth.user_id);
    ensure_self_or_admin(&auth, user_id)?;
    delete_user_sessions(c, ctx, env, user_id);
    commit(ctx);
    Ok(Reply::Done)
}

/// `get_composite_by_name_or_email` (`UserRepository`'s provided method).
pub fn get_composite_by_name_or_email(ctx: &Ctx, name_or_email: &NameOrEmail) -> Option<UserComposite> {
    match name_or_email {
        NameOrEmail::Name(n) => repo::get_composite_by_name(&ctx.db, n),
        NameOrEmail::Email(e) => repo::get_composite_by_email(&ctx.db, e),
    }
}

/// `SessionFeatureServiceImpl::record_failed_attempt`.
pub fn record_failed_attempt(c: &Config, ctx: &mut Ctx, env: &Env, logins: &Vec<NameOrEmail>) {
    throttle::record_ip_failure(c, ctx, env, env.client_ip);
    let mut i = 0;
    while i < logins.len() {
        throttle::record_account_failure(c, ctx, env, &logins[i]);
        i += 1;
    }
}

/// The `increment_failed_login_attempts` closure of `prove_credentials`.
fn increment_failed_login_attempts(c: &Config, ctx: &mut Ctx, env: &Env, logins: &Vec<NameOrEmail>) {
    let mut i = 0;
    while i < logins.len() {
        throttle::failed_auth_increment(ctx, env, &logins[i]);
        i += 1;
    }
    record_failed_attempt(c, ctx, env, logins);
}

/// Both spellings of the login.
fn logins_of(user_composite: &UserComposite) -> Vec<NameOrEmail> {
    let mut logins = Vec::new();
    logins.push(NameOrEmail::Name(user_composite.user.name.clone()));
    match &user_composite.user.email {
        Some(e) => logins.push(NameOrEmail::Email(e.clone())),
        None => {}
    }
    logins
}

fn reset_logins(ctx: &mut Ctx, logins: &Vec<NameOrEmail>) {
    let mut i = 0;
    while i < logins.len() {
        throttle::failed_auth_reset(ctx, &logins[i]);
        throttle::reset(ctx, &logins[i]);
        i += 1;
    }
}

/// `SessionFeatureServiceImpl::prove_credentials`.
pub fn prove_credentials(
    c: &Config,
    ctx: &mut Ctx,
    env: &Env,
    cmd: &SessionCreateCommand,
) -> Result<(UserComposite, bool), Error> {
    // The brake comes first: a locked login is refused before any password
    // is checked.
    throttle::check(ctx, env, &cmd.name_or_email, env.client_ip)?;
    let failed_login_attempts = throttle::failed_auth_get(ctx, env, &cmd.name_or_email);
    if failed_login_attempts >= c.login_fails_before_captcha {
        if !env.captcha_ok {
            return Err(Error::Recaptcha);
        }
    }
    let mut user_composite = match get_composite_by_name_or_email(ctx, &cmd.name_or_email) {
        Some(u) => u,
        None => {
            throttle::failed_auth_increment(ctx, env, &cmd.name_or_email);
            let mut one = Vec::new();
            one.push(cmd.name_or_email.clone());
            record_failed_attempt(c, ctx, env, &one);
            return Err(Error::InvalidCredentials);
        }
    };
    let logins = logins_of(&user_composite);
    match authenticate_by_password(ctx, env, user_composite.user.id, &cmd.password) {
        Ok(()) => {}
        Err(_) => {
            increment_failed_login_attempts(c, ctx, env, &logins);
            return Err(Error::InvalidCredentials);
        }
    }
    // Only a successful TOTP check marks the session as authenticated with a
    // second factor.
    let mut mfa_verified = false;
    if user_composite.mfa_enabled {
        let r = match mfa::authenticate(c, ctx, env, user_composite.user.id, &cmd.mfa) {
            Ok(r) => r,
            Err(_) => {
                increment_failed_login_attempts(c, ctx, env, &logins);
                return Err(Error::MfaFailed);
            }
        };
        match r {
            MfaAuthenticateResult::Ok => mfa_verified = true,
            MfaAuthenticateResult::Disabled => {}
            MfaAuthenticateResult::Reset => user_composite.mfa_enabled = false,
        }
    }
    // A successful login clears the account counter, not the address one.
    reset_logins(ctx, &logins);
    Ok((user_composite, mfa_verified))
}
