//! Falsification tests for the statements in proofs/Properties.lean. Each
//! checks the property on random requests and counts how often its premises
//! hold, so a statement that is false, or true only because its premises
//! never hold, fails here. The helpers transcribe proofs/Spec.lean.
use bootstrapacademy_kernel::*;

use crate::tests::{Rng, T0, env, request, snapshot};

const N: usize = 1_000_000;
/// Each property's premises must hold in at least this many cases.
const MIN_HITS: usize = 500;

fn user_of(db: &Db, u: u64) -> Option<&User> {
    db.users.iter().find(|x| x.id == u)
}
fn session_of(db: &Db, sid: u64) -> Option<&Session> {
    db.sessions.iter().find(|x| x.id == sid)
}
fn session_by_hash(db: &Db, h: u64) -> Option<&Session> {
    db.refresh_tokens.iter().find(|r| r.hash == h).and_then(|r| session_of(db, r.session_id))
}
fn wf(db: &Db) -> bool {
    fn nodup(v: Vec<u64>) -> bool {
        let mut w = v.clone();
        w.sort();
        w.dedup();
        w.len() == v.len()
    }
    nodup(db.users.iter().map(|x| x.id).collect())
        && nodup(db.sessions.iter().map(|x| x.id).collect())
        && nodup(db.totp_devices.iter().map(|x| x.id).collect())
}
fn lookup(c: &[CacheEntry], now: u64, p: impl Fn(&CacheKey) -> bool) -> Option<CacheValue> {
    let e = c.iter().find(|e| p(&e.key))?;
    if e.expires.is_none_or(|t| now < t) { Some(e.value.clone()) } else { None }
}
fn authenticates(s: &Snapshot, now: u64, a: &Authentication) -> bool {
    lookup(&s.cache, now, |k| *k == CacheKey::Invalidated(a.refresh_token_hash)).is_none()
        && user_of(&s.db, a.user_id).is_some_and(|u| u.enabled)
        && session_by_hash(&s.db, a.refresh_token_hash).is_some_and(|x| x.id == a.session_id && x.user_id == a.user_id)
}
fn admin_mfa(s: &Snapshot, a: &Authentication) -> bool {
    user_of(&s.db, a.user_id).is_some_and(|u| u.admin) && session_of(&s.db, a.session_id).is_some_and(|x| x.mfa_verified)
}
fn needs_token(c: &Command) -> bool {
    !matches!(c, Command::CreateSession { .. } | Command::ProveRecipient { .. } | Command::RefreshSession { .. })
}
fn admin_only(c: &Command) -> bool {
    matches!(c, Command::Impersonate { .. } | Command::AddCoins { .. })
}
fn target(c: &Command) -> Option<UserIdOrSelf> {
    match c {
        Command::ListSessions { user_id }
        | Command::DeleteSession { user_id, .. }
        | Command::DeleteSessionsByUser { user_id }
        | Command::MfaInitialize { user_id }
        | Command::MfaEnable { user_id, .. }
        | Command::MfaDisable { user_id }
        | Command::GetBalance { user_id }
        | Command::GetHearts { user_id } => Some(*user_id),
        _ => None,
    }
}
fn resolve(t: UserIdOrSelf, me: u64) -> u64 {
    match t {
        UserIdOrSelf::UserId(u) => u,
        UserIdOrSelf::Slf => me,
    }
}
fn totp_accepts(env: &Env, code: u64, secret: u64) -> bool {
    env.totp.iter().find(|t| t.0 == code && t.1 == secret).map(|t| t.2) == Some(TotpCheck::Ok)
}
fn lowered(v: &[u8]) -> Vec<u8> {
    v.iter().map(|c| c.to_ascii_lowercase()).collect()
}
fn login_bytes(n: &NameOrEmail) -> &[u8] {
    match n {
        NameOrEmail::Name(v) | NameOrEmail::Email(v) => v,
    }
}
fn ip_count(s: &Snapshot, now: u64, ip: u64) -> u64 {
    match lookup(&s.cache, now, |k| *k == CacheKey::ThrottleIp(ip)) {
        Some(CacheValue::Attempts(a)) => a.count,
        _ => 0,
    }
}
fn touches(db: &Db, u: u64, w: &Write) -> bool {
    match w {
        Write::CacheSet(e) => match e.key {
            CacheKey::Invalidated(h) => db
                .refresh_tokens
                .iter()
                .any(|r| r.hash == h && db.sessions.iter().any(|x| x.id == r.session_id && x.user_id == u)),
            _ => false,
        },
        Write::CacheRemove(_) => false,
        Write::CreateSession(x) => x.user_id == u,
        Write::UpdateSessionUpdatedAt { session_id: sid, .. }
        | Write::DeleteSession { session_id: sid }
        | Write::SaveRefreshTokenHash { session_id: sid, .. } => {
            db.sessions.iter().all(|x| x.id != *sid || x.user_id == u)
        }
        Write::ClearMfaVerified { user_id: v }
        | Write::DeleteSessionsByUser { user_id: v }
        | Write::UpdateLastLogin { user_id: v, .. }
        | Write::DeleteTotpDevicesByUser { user_id: v }
        | Write::SaveRecoveryCodeHash { user_id: v, .. }
        | Write::DeleteRecoveryCodeHash { user_id: v }
        | Write::AddCoins { user_id: v, .. }
        | Write::SetHearts { user_id: v, .. } => *v == u,
        Write::CreateTotpDevice(d) => d.user_id == u,
        Write::UpdateTotpDeviceEnabled { id, .. } | Write::SaveTotpDeviceSecret { id, .. } => {
            db.totp_devices.iter().all(|d| d.id != *id || d.user_id == u)
        }
        Write::CreateTransaction(t) => t.user_id == u,
        Write::CreateConsent(c) => c.user_id == u,
    }
}
fn merge_coins(rows: &mut Vec<(u64, i128, i128)>, u: u64, c: i128, w: i128) {
    match rows.iter_mut().find(|r| r.0 == u) {
        Some(r) => {
            r.1 += c;
            r.2 += w;
        }
        None => rows.push((u, c, w)),
    }
}
fn coins_after(db: &Db, ws: &[Write]) -> Vec<(u64, i128, i128)> {
    let mut rows: Vec<_> = db.coins.iter().map(|r| (r.user_id, r.coins as i128, r.withheld_coins as i128)).collect();
    for w in ws {
        if let Write::AddCoins { user_id, coins, withheld_coins } = w {
            merge_coins(&mut rows, *user_id, *coins as i128, *withheld_coins as i128);
        }
    }
    rows
}

type Out = (Vec<Write>, Result<Reply, Error>);

/// Runs `check` on N random requests; `check` returns whether the premises held.
fn property(seed: u64, check: impl Fn(&Snapshot, &Env, &Request, &Out) -> bool) {
    let mut r = Rng(seed);
    let mut hits = 0;
    for _ in 0..N {
        let now = T0 + r.below(200_000);
        let s = snapshot(&mut r, now);
        let env = env(&mut r, &s, now);
        let req = request(&mut r, &s);
        assert!(wf(&s.db));
        let out = transition(&s, &env, &req);
        if check(&s, &env, &req, &out) {
            hits += 1;
        }
    }
    assert!(hits >= MIN_HITS, "premises held only {hits} times");
}

#[test]
fn unauthenticated_writes_nothing() {
    property(1, |s, env, req, (ws, r)| {
        if !needs_token(&req.cmd) || req.token.is_some_and(|a| authenticates(s, env.now, &a)) {
            return false;
        }
        assert!(ws.is_empty() && r.is_err(), "{req:?} {ws:?} {r:?}");
        true
    });
}

#[test]
fn self_or_admin() {
    property(2, |s, env, req, (_, r)| {
        let Some(t) = target(&req.cmd) else { return false };
        if r.is_err() {
            return false;
        }
        let a = req.token.expect("a token");
        assert!(authenticates(s, env.now, &a));
        assert!(resolve(t, a.user_id) == a.user_id || admin_mfa(s, &a));
        // Count only an administrator acting on another account.
        resolve(t, a.user_id) != a.user_id
    });
}

#[test]
fn admin_needs_mfa() {
    property(3, |s, env, req, (_, r)| {
        if r.is_err() || !admin_only(&req.cmd) {
            return false;
        }
        let a = req.token.expect("a token");
        assert!(authenticates(s, env.now, &a) && admin_mfa(s, &a));
        true
    });
}

#[test]
fn token_claims_ignored() {
    let mut r = Rng(4);
    let mut hits = 0;
    for _ in 0..N {
        let now = T0 + r.below(200_000);
        let s = snapshot(&mut r, now);
        let env = env(&mut r, &s, now);
        let req = request(&mut r, &s);
        let Some(a) = req.token else { continue };
        let b = Authentication { admin: !a.admin, email_verified: r.chance(50), mfa_verified: !a.mfa_verified, ..a };
        let x = transition(&s, &env, &req);
        let y = transition(&s, &env, &Request { token: Some(b), cmd: req.cmd.clone() });
        assert_eq!(x, y);
        if x.1.is_ok() && needs_token(&req.cmd) {
            hits += 1;
        }
    }
    assert!(hits >= MIN_HITS, "{hits}");
}

#[test]
fn impersonation_without_mfa() {
    property(5, |_, _, req, (ws, r)| {
        if !matches!(req.cmd, Command::Impersonate { .. }) {
            return false;
        }
        for w in ws {
            if let Write::CreateSession(x) = w {
                assert!(!x.mfa_verified);
            }
        }
        if let Ok(Reply::Login(l)) = r {
            assert!(!l.session.mfa_verified && !l.access_token.mfa_verified);
            // Premises that matter: an admin with MFA made a session.
            return true;
        }
        false
    });
}

#[test]
fn mfa_session_needs_totp() {
    property(6, |s, env, req, (ws, _)| {
        let mut hit = false;
        for w in ws {
            let Write::CreateSession(x) = w else { continue };
            if !x.mfa_verified {
                continue;
            }
            hit = true;
            let Command::CreateSession { cmd } = &req.cmd else { panic!("{req:?}") };
            let code = cmd.mfa.totp_code.expect("a totp code");
            assert!(s.db.totp_devices.iter().any(|d| d.user_id == x.user_id && d.enabled && totp_accepts(env, code, d.secret)));
        }
        hit
    });
}

#[test]
fn writes_confined() {
    property(7, |s, _, req, (ws, _)| {
        let (Some(a), Some(t)) = (req.token, target(&req.cmd)) else { return false };
        let u = resolve(t, a.user_id);
        for w in ws {
            assert!(touches(&s.db, u, w), "{w:?} {req:?}");
        }
        !ws.is_empty()
    });
}

#[test]
fn coins_nonnegative() {
    property(8, |s, _, _, (ws, _)| {
        assert!(s.db.coins.iter().all(|r| r.coins >= 0 && r.withheld_coins >= 0));
        let after = coins_after(&s.db, ws);
        assert!(after.iter().all(|r| r.1 >= 0 && r.2 >= 0));
        ws.iter().any(|w| matches!(w, Write::AddCoins { .. }))
    });
}

#[test]
fn no_minting() {
    property(9, |s, _, _, (ws, _)| {
        assert!(s.config.hearts_refill_price < 1 << 63);
        let mut hit = false;
        for w in ws {
            if let Write::AddCoins { coins, withheld_coins, .. } = w {
                assert!(*coins <= 0 && *withheld_coins <= 0);
                hit = true;
            }
        }
        hit
    });
}

#[test]
fn refill_is_paid() {
    property(10, |s, env, req, (ws, _)| {
        if !matches!(req.cmd, Command::RefillHearts { .. }) {
            return false;
        }
        let Some(u) = ws.iter().find_map(|w| match w {
            Write::SetHearts { user_id, .. } => Some(*user_id),
            _ => None,
        }) else {
            return false;
        };
        let a = req.token.expect("a token");
        assert!(authenticates(s, env.now, &a) && u == a.user_id);
        assert!(ws.iter().any(|w| matches!(w, Write::AddCoins { user_id, coins, withheld_coins: 0 }
            if *user_id == u && *coins as i128 == -(s.config.hearts_refill_price as i128))));
        assert!(ws.iter().any(|w| matches!(w, Write::CreateConsent(k) if k.user_id == u && k.text_version == b"2026-09")));
        true
    });
}

#[test]
fn locked_login_refused() {
    property(11, |s, env, req, (ws, r)| {
        let cmd = match &req.cmd {
            Command::CreateSession { cmd } | Command::ProveRecipient { cmd } => cmd,
            _ => return false,
        };
        let key = lowered(login_bytes(&cmd.name_or_email));
        let Some(CacheValue::Attempts(FailedAttempts { blocked_until: Some(b), .. })) =
            lookup(&s.cache, env.now, |k| *k == CacheKey::ThrottleAccount(key.clone()))
        else {
            return false;
        };
        if env.now > b {
            return false;
        }
        assert!(ws.is_empty());
        assert_eq!(*r, Err(Error::TooManyFailedAttempts(b - env.now)));
        true
    });
}

#[test]
fn failed_login_counted() {
    property(12, |s, env, req, (ws, r)| {
        if !matches!(req.cmd, Command::CreateSession { .. }) || *r != Err(Error::InvalidCredentials) {
            return false;
        }
        let want = ip_count(s, env.now, env.client_ip).saturating_add(1);
        assert!(ws.iter().any(|w| matches!(w, Write::CacheSet(e) if e.key == CacheKey::ThrottleIp(env.client_ip)
            && matches!(e.value, CacheValue::Attempts(a) if a.count == want))));
        true
    });
}

#[test]
fn mfa_disable_revokes() {
    property(13, |s, _, req, (ws, r)| {
        let (Some(a), Command::MfaDisable { user_id: t }) = (req.token, &req.cmd) else { return false };
        if r.is_err() {
            return false;
        }
        let u = resolve(*t, a.user_id);
        assert!(ws.contains(&Write::ClearMfaVerified { user_id: u }));
        assert!(ws.contains(&Write::DeleteTotpDevicesByUser { user_id: u }));
        for rt in &s.db.refresh_tokens {
            if s.db.sessions.iter().any(|y| y.id == rt.session_id && y.user_id == u) {
                assert!(ws.iter().any(|w| matches!(w, Write::CacheSet(e) if e.key == CacheKey::Invalidated(rt.hash))));
            }
        }
        true
    });
}

#[test]
fn refresh_needs_live_session() {
    property(14, |s, env, req, (_, r)| {
        let (Command::RefreshSession { refresh_token }, Ok(Reply::Login(l))) = (&req.cmd, r) else { return false };
        let x = session_by_hash(&s.db, *refresh_token).expect("a session");
        assert!((env.now as u128) < x.updated_at as u128 + s.config.refresh_token_ttl as u128);
        assert!(user_of(&s.db, x.user_id).is_some_and(|u| u.enabled));
        assert!(l.session.id == x.id && l.access_token.mfa_verified == x.mfa_verified);
        true
    });
}

#[test]
fn disabled_accounts_get_no_session() {
    property(15, |s, _, _, (ws, _)| {
        let mut hit = false;
        for w in ws {
            if let Write::CreateSession(x) = w {
                assert!(user_of(&s.db, x.user_id).is_some_and(|u| u.enabled));
                hit = true;
            }
        }
        hit
    });
}

#[test]
fn transition_total() {
    // The kernel panics where the Lean function fails; `property` would stop.
    property(16, |_, _, _, _| true);
}
