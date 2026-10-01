//! `academy_core/heart/impl`: `HeartFeatureServiceImpl` (lib.rs),
//! `HeartServiceImpl` (heart.rs), and `WithdrawalConsentServiceImpl::record`
//! (withdrawal/impl/src/consent.rs).
use crate::access::{authenticate, ensure_self_or_admin, unwrap_or};
use crate::coin::service_add_coins;
use crate::{
    bytes_eq, commit, repo, db_write, generate, Authentication, Config, Consent, Ctx, Declaration, Env, Error, Hearts,
    Reply, UserIdOrSelf, Write,
};

const DAY: u64 = 86400;

/// `HeartServiceImpl::last_auto_refill`: today's refill time if it has
/// passed, else yesterday's.
pub fn last_auto_refill(c: &Config, env: &Env) -> u64 {
    let now = env.now;
    let today_with_time = (now - now % DAY).saturating_add(c.auto_refill_time);
    if today_with_time <= now { today_with_time } else { today_with_time.saturating_sub(DAY) }
}

/// `HeartServiceImpl::apply_auto_refill`.
pub fn apply_auto_refill(c: &Config, env: &Env, hearts: Option<Hearts>) -> Hearts {
    let last_auto_refill = last_auto_refill(c, env);
    match hearts {
        Some(h) => {
            if h.last_refill >= last_auto_refill {
                return h;
            }
        }
        None => {}
    }
    Hearts { hearts: c.hearts_max, last_refill: last_auto_refill }
}

fn stored(ctx: &Ctx, user_id: u64) -> Option<Hearts> {
    match repo::get_hearts(&ctx.db, user_id) {
        Some(r) => Some(Hearts { hearts: r.hearts, last_refill: r.last_refill }),
        None => None,
    }
}

/// `HeartServiceImpl::get`.
pub fn heart_get(c: &Config, ctx: &Ctx, env: &Env, user_id: u64) -> Hearts {
    apply_auto_refill(c, env, stored(ctx, user_id))
}

/// `HeartServiceImpl::add` for a non-negative amount, the only one the ported
/// callers pass.
pub fn heart_add(c: &Config, ctx: &mut Ctx, env: &Env, user_id: u64, hearts: u64) -> Hearts {
    let current = apply_auto_refill(c, env, stored(ctx, user_id));
    let sum = current.hearts.saturating_add(hearts);
    let hearts = Hearts {
        hearts: if sum < c.hearts_max { sum } else { c.hearts_max },
        last_refill: current.last_refill,
    };
    db_write(ctx, Write::SetHearts { user_id, hearts: hearts.hearts, last_refill: hearts.last_refill });
    hearts
}

/// `withdrawal.rs` `WITHDRAWAL_TEXT_VERSION`.
pub fn withdrawal_text_version() -> Vec<u8> {
    let mut v = Vec::new();
    v.push(b'2');
    v.push(b'0');
    v.push(b'2');
    v.push(b'6');
    v.push(b'-');
    v.push(b'0');
    v.push(b'9');
    v
}

/// `WithdrawalConsentDeclaration::text_version`.
pub fn text_version(d: &Declaration) -> Option<Vec<u8>> {
    if !d.given {
        return None;
    }
    match &d.text_version {
        Some(v) => {
            if bytes_eq(v, &withdrawal_text_version()) {
                Some(v.clone())
            } else {
                None
            }
        }
        None => None,
    }
}

/// `WithdrawalConsentServiceImpl::record` for `WithdrawalSubject::Hearts`.
pub fn record(ctx: &mut Ctx, env: &Env, user_id: u64, text_version: Vec<u8>) -> Consent {
    let consent = Consent { id: generate(ctx), user_id, text_version, consented_at: env.now };
    db_write(ctx, Write::CreateConsent(consent.clone()));
    consent
}

/// `HeartFeatureServiceImpl::get`.
pub fn get(c: &Config, ctx: &mut Ctx, env: &Env, token: &Option<Authentication>, user_id: UserIdOrSelf) -> Result<Reply, Error> {
    let auth = authenticate(ctx, env, token)?;
    let user_id = unwrap_or(user_id, auth.user_id);
    ensure_self_or_admin(&auth, user_id)?;
    if !repo::user_exists(&ctx.db, user_id) {
        return Err(Error::UserNotFound);
    }
    Ok(Reply::Hearts(heart_get(c, ctx, env, user_id)))
}

fn hearts_description() -> Vec<u8> {
    let mut v = Vec::new();
    v.push(b'H');
    v.push(b'e');
    v.push(b'a');
    v.push(b'r');
    v.push(b't');
    v.push(b's');
    v
}

/// `HeartFeatureServiceImpl::refill`: a purchase of digital content, so only
/// with the withdrawal declarations.
pub fn refill(c: &Config, ctx: &mut Ctx, env: &Env, token: &Option<Authentication>, declaration: &Declaration) -> Result<Reply, Error> {
    let withdrawal_text_version = match text_version(declaration) {
        Some(v) => v,
        None => return Err(Error::WithdrawalConsentMissing),
    };
    let auth = authenticate(ctx, env, token)?;
    let user_id = auth.user_id;
    let hearts = heart_get(c, ctx, env, user_id);
    if hearts.hearts >= c.hearts_max {
        return Ok(Reply::Hearts(hearts));
    }
    // `-(price as i64)`, wrapping as in a release build.
    let price = 0i64.wrapping_sub(c.hearts_refill_price as i64);
    match service_add_coins(ctx, env, user_id, price, false, Some(hearts_description()), false) {
        Ok(_) => {}
        Err(Error::NotEnoughCoins) => return Err(Error::NotEnoughCoins),
        Err(e) => return Err(e),
    }
    let hearts = heart_add(c, ctx, env, user_id, c.hearts_max);
    record(ctx, env, user_id, withdrawal_text_version);
    commit(ctx);
    Ok(Reply::Hearts(hearts))
}
