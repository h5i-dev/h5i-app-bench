//! `academy_core/mfa/impl`: `MfaAuthenticateServiceImpl` (authenticate.rs),
//! `MfaDisableServiceImpl` (disable.rs), `MfaTotpDeviceServiceImpl`
//! (totp_device.rs), `MfaRecoveryServiceImpl` (recovery.rs) and
//! `MfaFeatureServiceImpl` (lib.rs).
use crate::access::{authenticate as auth_authenticate, ensure_self_or_admin, invalidate_access_tokens, unwrap_or};
use crate::{
    commit, repo, db_write, generate, Authentication, Config, Ctx, Env, Error, MfaAuthentication, Reply, TotpCheck,
    TotpDevice, UserIdOrSelf, Write,
};

/// `MfaAuthenticateResult`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum MfaAuthenticateResult {
    Disabled,
    Ok,
    Reset,
}

/// `TotpService::check`, from the oracle table.
pub fn totp_check(env: &Env, code: u64, secret: u64) -> TotpCheck {
    let mut i = 0;
    while i < env.totp.len() {
        if env.totp[i].0 == code && env.totp[i].1 == secret {
            return env.totp[i].2;
        }
        i += 1;
    }
    TotpCheck::InvalidCode
}

/// The `for secret in totp_secrets` loop of `authenticate`.
fn any_secret_accepts(env: &Env, code: u64, secrets: &Vec<u64>) -> bool {
    let mut i = 0;
    while i < secrets.len() {
        match totp_check(env, code, secrets[i]) {
            TotpCheck::Ok => return true,
            TotpCheck::InvalidCode | TotpCheck::RecentlyUsed => {}
        }
        i += 1;
    }
    false
}

/// `MfaRecoveryCode` hashing: SHA-256, taken as injective.
pub fn recovery_code_hash(code: u64) -> u64 {
    code
}

/// `MfaAuthenticateServiceImpl::authenticate`; `Err` is `Failed`.
pub fn authenticate(
    c: &Config,
    ctx: &mut Ctx,
    env: &Env,
    user_id: u64,
    cmd: &MfaAuthentication,
) -> Result<MfaAuthenticateResult, Error> {
    let totp_secrets = repo::list_enabled_totp_device_secrets_by_user(&ctx.db, user_id);
    if totp_secrets.len() == 0 {
        return Ok(MfaAuthenticateResult::Disabled);
    }
    match cmd.recovery_code {
        Some(recovery_code) => match repo::get_mfa_recovery_code_hash(&ctx.db, user_id) {
            Some(hash) => {
                if recovery_code_hash(recovery_code) == hash {
                    disable(c, ctx, env, user_id);
                    return Ok(MfaAuthenticateResult::Reset);
                }
            }
            None => {}
        },
        None => {}
    }
    match cmd.totp_code {
        Some(code) => {
            if any_secret_accepts(env, code, &totp_secrets) {
                return Ok(MfaAuthenticateResult::Ok);
            }
        }
        None => {}
    }
    Err(Error::MfaFailed)
}

/// `MfaDisableServiceImpl::disable`: the second factor goes, and with it the
/// administrative authority of every session of the account.
pub fn disable(c: &Config, ctx: &mut Ctx, env: &Env, user_id: u64) {
    db_write(ctx, Write::DeleteTotpDevicesByUser { user_id });
    db_write(ctx, Write::DeleteRecoveryCodeHash { user_id });
    db_write(ctx, Write::ClearMfaVerified { user_id });
    invalidate_access_tokens(c, ctx, env, user_id);
}

/// `MfaTotpDeviceServiceImpl::create`; returns the secret (`TotpSetup`).
pub fn create(ctx: &mut Ctx, env: &Env, user_id: u64) -> u64 {
    let secret = generate(ctx);
    let totp_device = TotpDevice { id: generate(ctx), user_id, enabled: false, created_at: env.now, secret };
    db_write(ctx, Write::CreateTotpDevice(totp_device));
    secret
}

/// `MfaTotpDeviceServiceImpl::confirm`; `Err(InvalidCode)` is its `InvalidCode`.
pub fn confirm(ctx: &mut Ctx, env: &Env, totp_device: TotpDevice, code: u64) -> Result<TotpDevice, Error> {
    let secret = match repo::get_totp_device_secret(&ctx.db, totp_device.id) {
        Some(s) => s,
        None => return Err(Error::Internal),
    };
    match totp_check(env, code, secret) {
        TotpCheck::Ok => {}
        TotpCheck::InvalidCode | TotpCheck::RecentlyUsed => return Err(Error::InvalidCode),
    }
    db_write(ctx, Write::UpdateTotpDeviceEnabled { id: totp_device.id, enabled: true });
    let mut totp_device = totp_device;
    totp_device.enabled = true;
    Ok(totp_device)
}

/// `MfaTotpDeviceServiceImpl::reset`; returns the new secret.
pub fn reset(ctx: &mut Ctx, totp_device_id: u64) -> u64 {
    let secret = generate(ctx);
    db_write(ctx, Write::UpdateTotpDeviceEnabled { id: totp_device_id, enabled: false });
    db_write(ctx, Write::SaveTotpDeviceSecret { id: totp_device_id, secret });
    secret
}

/// `MfaRecoveryServiceImpl::setup`.
pub fn setup(ctx: &mut Ctx, user_id: u64) -> u64 {
    let recovery_code = generate(ctx);
    db_write(ctx, Write::SaveRecoveryCodeHash { user_id, hash: recovery_code_hash(recovery_code) });
    recovery_code
}

fn any_enabled(devices: &Vec<TotpDevice>) -> bool {
    let mut i = 0;
    while i < devices.len() {
        if devices[i].enabled {
            return true;
        }
        i += 1;
    }
    false
}

/// `MfaFeatureServiceImpl::initialize`.
pub fn initialize(ctx: &mut Ctx, env: &Env, token: &Option<Authentication>, user_id: UserIdOrSelf) -> Result<Reply, Error> {
    let auth = auth_authenticate(ctx, env, token)?;
    let user_id = unwrap_or(user_id, auth.user_id);
    ensure_self_or_admin(&auth, user_id)?;
    if !repo::user_exists(&ctx.db, user_id) {
        return Err(Error::NotFound);
    }
    let totp_devices = repo::list_totp_devices_by_user(&ctx.db, user_id);
    if any_enabled(&totp_devices) {
        return Err(Error::AlreadyEnabled);
    }
    let setup = if totp_devices.len() > 0 {
        reset(ctx, totp_devices[0].id)
    } else {
        create(ctx, env, user_id)
    };
    commit(ctx);
    Ok(Reply::TotpSetup(setup))
}

/// `MfaFeatureServiceImpl::enable`.
pub fn enable(
    ctx: &mut Ctx,
    env: &Env,
    token: &Option<Authentication>,
    user_id: UserIdOrSelf,
    code: u64,
) -> Result<Reply, Error> {
    let auth = auth_authenticate(ctx, env, token)?;
    let user_id = unwrap_or(user_id, auth.user_id);
    ensure_self_or_admin(&auth, user_id)?;
    if !repo::user_exists(&ctx.db, user_id) {
        return Err(Error::NotFound);
    }
    let totp_devices = repo::list_totp_devices_by_user(&ctx.db, user_id);
    if any_enabled(&totp_devices) {
        return Err(Error::AlreadyEnabled);
    }
    if totp_devices.len() == 0 {
        return Err(Error::NotInitialized);
    }
    let totp_device = totp_devices[0].clone();
    confirm(ctx, env, totp_device, code)?;
    let recovery_code = setup(ctx, user_id);
    commit(ctx);
    Ok(Reply::RecoveryCode(recovery_code))
}

/// `MfaFeatureServiceImpl::disable`.
pub fn disable_mfa(
    c: &Config,
    ctx: &mut Ctx,
    env: &Env,
    token: &Option<Authentication>,
    user_id: UserIdOrSelf,
) -> Result<Reply, Error> {
    let auth = auth_authenticate(ctx, env, token)?;
    let user_id = unwrap_or(user_id, auth.user_id);
    ensure_self_or_admin(&auth, user_id)?;
    if !repo::user_exists(&ctx.db, user_id) {
        return Err(Error::NotFound);
    }
    let totp_devices = repo::list_totp_devices_by_user(&ctx.db, user_id);
    if !any_enabled(&totp_devices) {
        return Err(Error::NotEnabled);
    }
    disable(c, ctx, env, user_id);
    commit(ctx);
    Ok(Reply::Done)
}
