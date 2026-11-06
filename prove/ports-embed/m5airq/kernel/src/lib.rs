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
            // offset == expected == written. Guard the subtraction below so
            // `transition` is total for every state (upstream's
            // `offset + len > total` check rejects this case the same way).
            if *offset > s.total {
                return Err(Error::ExceedsDeclared);
            }
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

/// The RAM session store (`SESSIONS` upstream), four fixed slots.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct SessionStore {
    pub s0: SessionSlot,
    pub s1: SessionSlot,
    pub s2: SessionSlot,
    pub s3: SessionSlot,
}

/// The auth-posture configuration (`AuthSettings` upstream, the fields the
/// decision reads).
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

/// Equal bytes without an early exit (`constant_time_eq`, for 8-byte
/// tokens). Kept for the constant-time comparison property; the auth
/// decision takes the comparison *result* as a trusted bool, as it does for
/// the Digest MD5.
pub fn ct_eq8(a: &[u8; 8], b: &[u8; 8]) -> bool {
    let mut diff: u8 = 0;
    diff |= a[0] ^ b[0];
    diff |= a[1] ^ b[1];
    diff |= a[2] ^ b[2];
    diff |= a[3] ^ b[3];
    diff |= a[4] ^ b[4];
    diff |= a[5] ^ b[5];
    diff |= a[6] ^ b[6];
    diff |= a[7] ^ b[7];
    diff == 0
}

/// Whether an 8-byte token is all zeroes (the empty-slot sentinel).
pub fn is_zero8(t: &[u8; 8]) -> bool {
    let mut nz: u8 = 0;
    nz |= t[0];
    nz |= t[1];
    nz |= t[2];
    nz |= t[3];
    nz |= t[4];
    nz |= t[5];
    nz |= t[6];
    nz |= t[7];
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

/// Whether one slot accepts `token` at `now` (`validate_session`'s predicate):
/// the slot holds exactly this non-zero token and is not past its TTL.
pub fn slot_valid(slot: &SessionSlot, token: &[u8; 8], now: u32) -> bool {
    ct_eq8(&slot.token, token) && !is_zero8(&slot.token) && age_ok(now, slot.created)
}

/// Validate a decrypted 8-byte session token against the store
/// (`validate_session`), unrolled over the four fixed slots.
pub fn validate_session(store: &SessionStore, token: &[u8; 8], now: u32) -> bool {
    slot_valid(&store.s0, token, now)
        || slot_valid(&store.s1, token, now)
        || slot_valid(&store.s2, token, now)
        || slot_valid(&store.s3, token, now)
}

/// Whether a token credential must be refused on this transport:
/// plaintext HTTP with token-over-HTTP disabled (`!is_https && !allow`).
pub fn transport_blocks(is_https: bool, allow_http_tokens: bool) -> bool {
    !is_https && !allow_http_tokens
}

/// The authentication decision (`check_auth`), pure and total.
///
/// `*_present` says a credential of that kind arrived. `cookie_token` is the
/// already-decrypted 8-byte token (XOR decoding is trusted IO).
/// `bearer_match`/`akh_match`/`akq_match` are the trusted constant-time
/// comparison results of the presented token against the configured secret
/// (upstream's `constant_time_eq`), and `digest_ok` is the trusted
/// `verify_digest` MD5 result. `is_health` is `path == "/api/health"`.
///
/// This is the flattened but behaviourally identical form of upstream's
/// nested `check_auth`: the transport (`is_https`, `allow_http_tokens`) is
/// fixed for a request, so a blocked token credential is refused with
/// `Forbidden` before any lower-priority credential, exactly as the nested
/// original short-circuits.
#[allow(clippy::too_many_arguments)]
pub fn check_auth(
    cfg: &AuthCfg,
    store: &SessionStore,
    now: u32,
    cookie_present: bool,
    cookie_token: &[u8; 8],
    bearer_present: bool,
    bearer_match: bool,
    akh_present: bool,
    akh_match: bool,
    akq_present: bool,
    akq_match: bool,
    digest_ok: bool,
    is_https: bool,
    is_health: bool,
) -> AuthDecision {
    let blocked = transport_blocks(is_https, cfg.allow_http_tokens);
    let valid_cookie = cookie_present && validate_session(store, cookie_token, now);
    let bearer_block = bearer_present && blocked;
    let bearer_ok = bearer_present && cfg.bearer_set && bearer_match;
    let akh_block = akh_present && blocked;
    let akh_ok = akh_present && cfg.apikey_set && akh_match;
    let akq_block = akq_present && blocked;
    let akq_ok = akq_present && cfg.apikey_set && akq_match;
    if cfg.public_access {
        AuthDecision::Allowed
    } else if is_health {
        AuthDecision::Allowed
    } else if valid_cookie {
        AuthDecision::Allowed
    } else if bearer_block {
        AuthDecision::Forbidden
    } else if bearer_ok {
        AuthDecision::Allowed
    } else if akh_block {
        AuthDecision::Forbidden
    } else if akh_ok {
        AuthDecision::Allowed
    } else if akq_block {
        AuthDecision::Forbidden
    } else if akq_ok {
        AuthDecision::Allowed
    } else if digest_ok {
        AuthDecision::AllowedSetSession
    } else {
        AuthDecision::Challenge
    }
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
        assert_eq!(run(s, Command::Write { offset: 100, len: 10 }), Err(Error::OffsetMismatch));
        let s2 = run(s, Command::Write { offset: 0, len: 4096 }).unwrap();
        assert_eq!(run(s2, Command::Write { offset: 4096, len: 4000 }), Err(Error::ExceedsDeclared));
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
        let z = SessionSlot { token: [0; 8], created: 0 };
        SessionStore { s0: z, s1: z, s2: z, s3: z }
    }

    fn cfg(public: bool) -> AuthCfg {
        AuthCfg { public_access: public, allow_http_tokens: false, bearer_set: true, apikey_set: true }
    }

    #[test]
    fn auth_public_opens_everything() {
        let d = check_auth(&cfg(true), &empty_store(), 0, false, &[0; 8], false, false, false, false, false, false, false, false, false);
        assert_eq!(d, AuthDecision::Allowed);
    }

    #[test]
    fn auth_no_cred_challenges() {
        let d = check_auth(&cfg(false), &empty_store(), 0, false, &[0; 8], false, false, false, false, false, false, false, false, false);
        assert_eq!(d, AuthDecision::Challenge);
    }

    #[test]
    fn auth_bearer_over_http_forbidden() {
        let d = check_auth(&cfg(false), &empty_store(), 0, false, &[0; 8], true, true, false, false, false, false, false, false, false);
        assert_eq!(d, AuthDecision::Forbidden);
    }

    #[test]
    fn auth_bearer_over_https_ok() {
        let d = check_auth(&cfg(false), &empty_store(), 0, false, &[0; 8], true, true, false, false, false, false, false, true, false);
        assert_eq!(d, AuthDecision::Allowed);
    }

    #[test]
    fn auth_health_public() {
        let d = check_auth(&cfg(false), &empty_store(), 0, false, &[0; 8], false, false, false, false, false, false, false, false, true);
        assert_eq!(d, AuthDecision::Allowed);
    }

    #[test]
    fn auth_expired_cookie_rejected() {
        let mut store = empty_store();
        store.s0 = SessionSlot { token: [1, 2, 3, 4, 5, 6, 7, 8], created: 100 };
        let now = 100 + SESSION_TTL_SECS + 1;
        assert!(!validate_session(&store, &[1, 2, 3, 4, 5, 6, 7, 8], now));
        let d = check_auth(&cfg(false), &store, now, true, &[1, 2, 3, 4, 5, 6, 7, 8], false, false, false, false, false, false, false, true, false);
        assert_eq!(d, AuthDecision::Challenge);
        assert!(validate_session(&store, &[1, 2, 3, 4, 5, 6, 7, 8], 100 + SESSION_TTL_SECS));
    }
}
