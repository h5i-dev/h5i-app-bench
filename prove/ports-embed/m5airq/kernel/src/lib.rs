//! Security-critical decision logic of the M5AirQ-Rust ESP32 air-quality
//! monitor, as an h5i-app kernel for a microcontroller.
//!
//! `no_std`, no allocation, in the Rust subset Aeneas translates to Lean.
//! Two independent pieces, both ported from upstream
//! `andrico21/M5AirQ-Rust` @ `f7e35cb`:
//!
//! * `transition`/`apply` — the OTA (over-the-air firmware update) state
//!   machine from `src/ota.rs` (`begin`/`write`/`end`/`abort`). The proofs
//!   show it never panics, a chunk never writes past the declared image
//!   size, writes are strictly sequential, a new image is activated only
//!   when it is complete, has the ESP image magic and matches the declared
//!   CRC, and `begin` always targets the slot the device is *not* running
//!   from.
//! * `check_auth` — the HTTP authentication gate from `src/auth.rs`. The
//!   proofs show no request is granted without a valid credential (when
//!   `public_access` is off), a bearer token or API key presented over
//!   plaintext HTTP is refused unless explicitly allowed, and an expired
//!   session cookie is rejected.
//!
//! Decoding requests and encoding replies is trusted, as in the thermostat
//! example; the kernel's theorems hold for every command.

#![no_std]

// ===========================================================================
// Part 1: OTA update state machine  (ported from src/ota.rs)
// ===========================================================================

/// A single OTA slot is 0x1F_0000 bytes (1984 KiB). From `OTA_SLOT_SIZE`.
pub const OTA_SLOT_SIZE: u32 = 0x1F_0000;
/// Largest chunk accepted per write. From `MAX_CHUNK_SIZE`.
pub const MAX_CHUNK: u32 = 4096;
/// First byte of a valid ESP32 app image. From `ESP_IMAGE_MAGIC`.
pub const ESP_IMAGE_MAGIC: u8 = 0xE9;
/// Sentinel: the running slot has not been detected yet.
pub const SLOT_UNKNOWN: u8 = 0xFF;

/// The authenticated caller. Every mutating OTA endpoint is behind the
/// `Authenticated` extractor upstream; `admin` records that gate.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Device {
    pub admin: bool,
}

/// The OTA session state. Mirrors the five `OTA_*` atomics in `src/ota.rs`
/// plus the running slot detected at boot.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct OtaState {
    pub active: bool,
    /// The slot being written (0 or 1).
    pub target_slot: u8,
    /// The slot the bootloader loaded us from (0 or 1), or `SLOT_UNKNOWN`.
    pub running_slot: u8,
    /// The declared firmware size for this session.
    pub total: u32,
    /// Bytes committed so far.
    pub written: u32,
    pub error: bool,
}

/// Starts idle, running slot unknown until `init_running_slot` runs.
pub const OTA_INITIAL: OtaState = OtaState {
    active: false,
    target_slot: 0,
    running_slot: SLOT_UNKNOWN,
    total: 0,
    written: 0,
    error: false,
};

impl Default for OtaState {
    fn default() -> Self {
        OTA_INITIAL
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Command {
    /// `POST /api/ota/begin/{size}` — open a session for `size` bytes.
    Begin { size: u32 },
    /// `POST /api/ota/write/{offset}` — write a `len`-byte chunk at `offset`.
    Write { offset: u32, len: u32 },
    /// `GET /api/ota/end/{expected_crc}` — finalize. `actual_crc`/`magic_ok`
    /// are the trusted flash read-back results the IO layer supplies.
    End { expected_crc: u32, actual_crc: u32, magic_ok: bool },
    /// `GET /api/ota/abort`.
    Abort,
    /// `GET /api/ota/status`.
    Status,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Reply {
    State(OtaState),
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    Forbidden,
    AlreadyActive,
    BadSize,
    RunningUnknown,
    NoSession,
    PriorError,
    ChunkSize,
    OffsetMismatch,
    ExceedsDeclared,
    Incomplete,
    BadMagic,
    CrcMismatch,
}

/// `transition(actor, s, cmd)` — the OTA decision, pure and total.
///
/// Returns the new state (`Some`) or nothing to write, with a reply, or an
/// `Error`. Mirrors `ota::begin/write/end/abort/status`, minus the flash IO
/// (modelled by the `magic_ok`/`actual_crc` inputs to `End`).
pub fn transition(
    actor: &Device,
    s: &OtaState,
    cmd: &Command,
) -> Result<(Option<OtaState>, Reply), Error> {
    match cmd {
        Command::Status => Ok((None, Reply::State(*s))),
        Command::Begin { size } => {
            if !actor.admin {
                return Err(Error::Forbidden);
            }
            if s.active {
                return Err(Error::AlreadyActive);
            }
            if *size == 0 || *size > OTA_SLOT_SIZE {
                return Err(Error::BadSize);
            }
            if s.running_slot > 1 {
                // Includes SLOT_UNKNOWN (0xFF): refuse rather than guess.
                return Err(Error::RunningUnknown);
            }
            let target = 1 - s.running_slot;
            let n = OtaState {
                active: true,
                target_slot: target,
                running_slot: s.running_slot,
                total: *size,
                written: 0,
                error: false,
            };
            Ok((Some(n), Reply::State(n)))
        }
        Command::Write { offset, len } => {
            if !actor.admin {
                return Err(Error::Forbidden);
            }
            if !s.active {
                return Err(Error::NoSession);
            }
            if s.error {
                return Err(Error::PriorError);
            }
            if *len == 0 || *len > MAX_CHUNK {
                return Err(Error::ChunkSize);
            }
            let expected = s.written;
            // Idempotent retry: a chunk wholly below the write cursor was
            // already committed; report success without changing state.
            if *offset < expected && *len <= expected - *offset {
                return Ok((None, Reply::State(*s)));
            }
            if *offset != expected {
                return Err(Error::OffsetMismatch);
            }
            // offset == expected == written <= total  (invariant Inv)
            if *len > s.total - *offset {
                return Err(Error::ExceedsDeclared);
            }
            let new_written = *offset + *len;
            let n = OtaState {
                active: s.active,
                target_slot: s.target_slot,
                running_slot: s.running_slot,
                total: s.total,
                written: new_written,
                error: s.error,
            };
            Ok((Some(n), Reply::State(n)))
        }
        Command::End { expected_crc, actual_crc, magic_ok } => {
            if !actor.admin {
                return Err(Error::Forbidden);
            }
            if !s.active {
                return Err(Error::NoSession);
            }
            if s.written != s.total {
                return Err(Error::Incomplete);
            }
            if !*magic_ok {
                return Err(Error::BadMagic);
            }
            if *actual_crc != *expected_crc {
                return Err(Error::CrcMismatch);
            }
            let n = OtaState {
                active: false,
                target_slot: s.target_slot,
                running_slot: s.running_slot,
                total: s.total,
                written: s.written,
                error: false,
            };
            Ok((Some(n), Reply::State(n)))
        }
        Command::Abort => {
            if !actor.admin {
                return Err(Error::Forbidden);
            }
            if !s.active {
                return Err(Error::NoSession);
            }
            let n = OtaState {
                active: false,
                target_slot: s.target_slot,
                running_slot: s.running_slot,
                total: s.total,
                written: 0,
                error: false,
            };
            Ok((Some(n), Reply::State(n)))
        }
    }
}

pub fn apply(s: &OtaState, w: &Option<OtaState>) -> OtaState {
    match w {
        Some(n) => *n,
        None => *s,
    }
}

/// `Status` writes nothing.
pub fn read_only(cmd: &Command) -> bool {
    match cmd {
        Command::Status => true,
        _ => false,
    }
}

// ===========================================================================
// Part 2: HTTP authentication gate  (ported from src/auth.rs)
// ===========================================================================

/// Session lifetime in seconds (2 hours). From `SESSION_TTL_SECS`.
pub const SESSION_TTL_SECS: u32 = 7200;
/// Up to four concurrent sessions. From `MAX_SESSIONS`.
pub const MAX_SESSIONS: usize = 4;

/// One session slot: an 8-byte token and the second it was created.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct SessionSlot {
    pub token: [u8; 8],
    pub created: u32,
}

/// The RAM session store (`SESSIONS` upstream).
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct SessionStore {
    pub slots: [SessionSlot; MAX_SESSIONS],
}

/// The auth-posture configuration (`AuthSettings` upstream, the fields the
/// decision reads). Secrets are passed as slices alongside.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct AuthCfg {
    pub public_access: bool,
    pub allow_http_tokens: bool,
    /// Whether a non-empty bearer token is configured.
    pub bearer_set: bool,
    /// Whether a non-empty API key is configured.
    pub apikey_set: bool,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum AuthDecision {
    /// Public or an existing credential — serve the request.
    Allowed,
    /// Fresh Digest login — serve and set a session cookie.
    AllowedSetSession,
    /// A token over plaintext HTTP when that is not allowed.
    Forbidden,
    /// No valid credential — answer 401 with a Digest challenge.
    Challenge,
}

/// Equal length and bytes, without an early exit (`constant_time_eq`).
pub fn ct_eq(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut diff: u8 = 0;
    let mut i: usize = 0;
    while i < a.len() {
        diff |= a[i] ^ b[i];
        i += 1;
    }
    diff == 0
}

/// `ct_eq` specialised to 8-byte tokens (no slice unsizing).
pub fn ct_eq8(a: &[u8; 8], b: &[u8; 8]) -> bool {
    let mut diff: u8 = 0;
    let mut i: usize = 0;
    while i < 8 {
        diff |= a[i] ^ b[i];
        i += 1;
    }
    diff == 0
}

/// Whether an 8-byte token is all zeroes (the empty-slot sentinel).
pub fn is_zero8(t: &[u8; 8]) -> bool {
    let mut i: usize = 0;
    let mut nz: u8 = 0;
    while i < 8 {
        nz |= t[i];
        i += 1;
    }
    nz == 0
}

/// Whether a session created at `created` is still live at `now`.
/// Faithful to `now.wrapping_sub(created) <= SESSION_TTL_SECS`: a `now`
/// before `created` (clock moved back / wrapped) is treated as expired.
pub fn age_ok(now: u32, created: u32) -> bool {
    if now >= created {
        now - created <= SESSION_TTL_SECS
    } else {
        false
    }
}

/// Validate a decrypted 8-byte session token against the store
/// (`validate_session`): some slot holds exactly this non-zero token and is
/// not past its TTL.
pub fn validate_session(store: &SessionStore, token: &[u8; 8], now: u32) -> bool {
    let mut i: usize = 0;
    let mut found = false;
    while i < MAX_SESSIONS {
        let tok = store.slots[i].token;
        let created = store.slots[i].created;
        let m = ct_eq8(&tok, token) && !is_zero8(&tok) && age_ok(now, created);
        if m {
            found = true;
        }
        i += 1;
    }
    found
}

/// The authentication decision (`check_auth`), pure and total.
///
/// `*_present` says a credential of that kind arrived; the paired slice is
/// its value. `cookie_token` is the already-decrypted 8-byte token (XOR
/// decoding is trusted IO). `digest_ok` is the result of the trusted
/// `verify_digest` MD5 check. `is_health` is `path == "/api/health"`.
#[allow(clippy::too_many_arguments)]
pub fn check_auth(
    cfg: &AuthCfg,
    store: &SessionStore,
    now: u32,
    cookie_present: bool,
    cookie_token: &[u8; 8],
    bearer_present: bool,
    bearer: &[u8],
    bearer_key: &[u8],
    akh_present: bool,
    akh: &[u8],
    akq_present: bool,
    akq: &[u8],
    apikey: &[u8],
    digest_ok: bool,
    is_https: bool,
    is_health: bool,
) -> AuthDecision {
    // Public access — allow everything.
    if cfg.public_access {
        return AuthDecision::Allowed;
    }
    // The health endpoint is always public (monitoring probes).
    if is_health {
        return AuthDecision::Allowed;
    }
    // Session cookie.
    if cookie_present {
        if validate_session(store, cookie_token, now) {
            return AuthDecision::Allowed;
        }
    }
    // Bearer token.
    if bearer_present {
        if !is_https && !cfg.allow_http_tokens {
            return AuthDecision::Forbidden;
        }
        if cfg.bearer_set && ct_eq(bearer, bearer_key) {
            return AuthDecision::Allowed;
        }
    }
    // API key (header).
    if akh_present {
        if !is_https && !cfg.allow_http_tokens {
            return AuthDecision::Forbidden;
        }
        if cfg.apikey_set && ct_eq(akh, apikey) {
            return AuthDecision::Allowed;
        }
    }
    // API key (query parameter).
    if akq_present {
        if !is_https && !cfg.allow_http_tokens {
            return AuthDecision::Forbidden;
        }
        if cfg.apikey_set && ct_eq(akq, apikey) {
            return AuthDecision::Allowed;
        }
    }
    // Digest — a fresh login mints a session.
    if digest_ok {
        return AuthDecision::AllowedSetSession;
    }
    AuthDecision::Challenge
}

#[cfg(test)]
mod tests {
    use super::*;

    const ADMIN: Device = Device { admin: true };
    const GUEST: Device = Device { admin: false };

    fn run(s: OtaState, c: Command) -> Result<OtaState, Error> {
        transition(&ADMIN, &s, &c).map(|(w, _)| apply(&s, &w))
    }

    fn booted() -> OtaState {
        OtaState { running_slot: 0, ..OTA_INITIAL }
    }

    #[test]
    fn ota_happy_path() {
        let s = run(booted(), Command::Begin { size: 8000 }).unwrap();
        assert!(s.active);
        assert_eq!(s.target_slot, 1);
        assert_eq!(s.total, 8000);
        let s = run(s, Command::Write { offset: 0, len: 4096 }).unwrap();
        assert_eq!(s.written, 4096);
        let s = run(s, Command::Write { offset: 4096, len: 3904 }).unwrap();
        assert_eq!(s.written, 8000);
        let s = run(s, Command::End { expected_crc: 0x1234, actual_crc: 0x1234, magic_ok: true }).unwrap();
        assert!(!s.active);
    }

    #[test]
    fn ota_refusals() {
        assert_eq!(run(booted(), Command::Begin { size: 0 }), Err(Error::BadSize));
        assert_eq!(run(booted(), Command::Begin { size: OTA_SLOT_SIZE + 1 }), Err(Error::BadSize));
        assert_eq!(run(OTA_INITIAL, Command::Begin { size: 10 }), Err(Error::RunningUnknown));
        assert_eq!(
            transition(&GUEST, &booted(), &Command::Begin { size: 10 }),
            Err(Error::Forbidden)
        );
        let s = run(booted(), Command::Begin { size: 8000 }).unwrap();
        // out-of-order write
        assert_eq!(run(s, Command::Write { offset: 100, len: 10 }), Err(Error::OffsetMismatch));
        // chunk past declared size
        let s2 = run(s, Command::Write { offset: 0, len: 4096 }).unwrap();
        assert_eq!(run(s2, Command::Write { offset: 4096, len: 4000 }), Err(Error::ExceedsDeclared));
        // end before complete
        assert_eq!(
            run(s2, Command::End { expected_crc: 1, actual_crc: 1, magic_ok: true }),
            Err(Error::Incomplete)
        );
    }

    #[test]
    fn ota_crc_and_magic_gate() {
        let s = run(booted(), Command::Begin { size: 4 }).unwrap();
        let s = run(s, Command::Write { offset: 0, len: 4 }).unwrap();
        assert_eq!(
            run(s, Command::End { expected_crc: 1, actual_crc: 2, magic_ok: true }),
            Err(Error::CrcMismatch)
        );
        assert_eq!(
            run(s, Command::End { expected_crc: 1, actual_crc: 1, magic_ok: false }),
            Err(Error::BadMagic)
        );
    }

    fn empty_store() -> SessionStore {
        SessionStore { slots: [SessionSlot { token: [0; 8], created: 0 }; MAX_SESSIONS] }
    }

    fn cfg(public: bool) -> AuthCfg {
        AuthCfg { public_access: public, allow_http_tokens: false, bearer_set: true, apikey_set: true }
    }

    #[test]
    fn auth_public_opens_everything() {
        let d = check_auth(
            &cfg(true), &empty_store(), 0, false, &[0; 8], false, b"", b"KEY", false, b"", false, b"", b"AK",
            false, false, false,
        );
        assert_eq!(d, AuthDecision::Allowed);
    }

    #[test]
    fn auth_no_cred_challenges() {
        let d = check_auth(
            &cfg(false), &empty_store(), 0, false, &[0; 8], false, b"", b"KEY", false, b"", false, b"", b"AK",
            false, false, false,
        );
        assert_eq!(d, AuthDecision::Challenge);
    }

    #[test]
    fn auth_bearer_over_http_forbidden() {
        let d = check_auth(
            &cfg(false), &empty_store(), 0, false, &[0; 8], true, b"KEY", b"KEY", false, b"", false, b"", b"AK",
            false, false, false,
        );
        assert_eq!(d, AuthDecision::Forbidden);
    }

    #[test]
    fn auth_bearer_over_https_ok() {
        let d = check_auth(
            &cfg(false), &empty_store(), 0, false, &[0; 8], true, b"KEY", b"KEY", false, b"", false, b"", b"AK",
            false, true, false,
        );
        assert_eq!(d, AuthDecision::Allowed);
    }

    #[test]
    fn auth_health_public() {
        let d = check_auth(
            &cfg(false), &empty_store(), 0, false, &[0; 8], false, b"", b"KEY", false, b"", false, b"", b"AK",
            false, false, true,
        );
        assert_eq!(d, AuthDecision::Allowed);
    }

    #[test]
    fn auth_expired_cookie_rejected() {
        let mut store = empty_store();
        store.slots[0] = SessionSlot { token: [1, 2, 3, 4, 5, 6, 7, 8], created: 100 };
        // now = 100 + TTL + 1 -> expired
        let now = 100 + SESSION_TTL_SECS + 1;
        assert!(!validate_session(&store, &[1, 2, 3, 4, 5, 6, 7, 8], now));
        let d = check_auth(
            &cfg(false), &store, now, true, &[1, 2, 3, 4, 5, 6, 7, 8], false, b"", b"KEY", false, b"", false,
            b"", b"AK", false, true, false,
        );
        assert_eq!(d, AuthDecision::Challenge);
        // within TTL -> valid
        assert!(validate_session(&store, &[1, 2, 3, 4, 5, 6, 7, 8], 100 + SESSION_TTL_SECS));
    }
}
