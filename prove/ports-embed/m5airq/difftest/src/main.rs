//! Differential tests: the `m5airq-kernel` decision logic against a faithful
//! reimplementation of the *real upstream* decision logic from
//! `andrico21/M5AirQ-Rust` @ `f7e35cb`.
//!
//! Testing is evidence, not a proof of equivalence. The oracle below is a
//! line-for-line transcription of the control flow of `src/ota.rs`
//! (`begin`/`write`/`end`/`abort`) and `src/auth.rs` (`check_auth`), with the
//! flash IO and the MD5/XOR crypto abstracted exactly as the kernel abstracts
//! them (a `magic_ok`/`actual_crc` read-back result, and `*_match` booleans).
//! Each case uses a deterministic xorshift PRNG so runs are reproducible.
//!
//! Exits non-zero on any divergence.

use m5airq_kernel as k;

// ---------------------------------------------------------------------------
// Deterministic PRNG
// ---------------------------------------------------------------------------

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 {
        let mut x = self.0;
        x ^= x << 13;
        x ^= x >> 7;
        x ^= x << 17;
        self.0 = x;
        x
    }
    fn b(&mut self) -> bool {
        self.next() & 1 == 0
    }
    fn u32_in(&mut self, lo: u32, hi: u32) -> u32 {
        lo + (self.next() as u32) % (hi - lo + 1)
    }
}

// ===========================================================================
// Oracle 1: OTA state machine  (upstream src/ota.rs)
// ===========================================================================

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
struct Ota {
    active: bool,
    target: u8,
    running: u8,
    total: u32,
    written: u32,
    error: bool,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum OtaOut {
    Err(&'static str),
    Ok,
}

/// `ota::begin` (ota.rs:343-396): refuse when active, bad size, or running
/// slot unknown; otherwise target the OTHER slot.
fn oracle_begin(s: &mut Ota, size: u32) -> OtaOut {
    const SLOT: u32 = 0x1F_0000;
    if s.active {
        return OtaOut::Err("already");
    }
    if size == 0 || size > SLOT {
        return OtaOut::Err("size");
    }
    if s.running == 0xFF {
        return OtaOut::Err("running_unknown");
    }
    // upstream: let target = 1 - running   (running is 0 or 1)
    if s.running > 1 {
        return OtaOut::Err("running_unknown"); // kernel's defensive guard
    }
    s.active = true;
    s.target = 1 - s.running;
    s.total = size;
    s.written = 0;
    s.error = false;
    OtaOut::Ok
}

/// `ota::write` (ota.rs:400-470).
fn oracle_write(s: &mut Ota, offset: u32, len: u32) -> OtaOut {
    const MAX_CHUNK: u32 = 4096;
    if !s.active {
        return OtaOut::Err("no_session");
    }
    if s.error {
        return OtaOut::Err("prior");
    }
    if len == 0 || len > MAX_CHUNK {
        return OtaOut::Err("chunk");
    }
    let expected = s.written;
    // retry: chunk wholly below the cursor (uses u64 to avoid the upstream
    // release-mode wrap in `offset + len`; the kernel guards it instead).
    if offset < expected && (offset as u64 + len as u64) <= expected as u64 {
        return OtaOut::Ok; // no state change
    }
    if offset != expected {
        return OtaOut::Err("offset");
    }
    if (offset as u64 + len as u64) > s.total as u64 {
        return OtaOut::Err("exceeds");
    }
    s.written = offset + len;
    OtaOut::Ok
}

/// `ota::end` (ota.rs:474-553). `magic_ok`/`actual_crc` are the flash
/// read-back results (abstracted exactly as the kernel does).
fn oracle_end(s: &mut Ota, expected_crc: u32, actual_crc: u32, magic_ok: bool) -> OtaOut {
    if !s.active {
        return OtaOut::Err("no_session");
    }
    if s.written != s.total {
        return OtaOut::Err("incomplete");
    }
    if !magic_ok {
        return OtaOut::Err("magic");
    }
    if actual_crc != expected_crc {
        return OtaOut::Err("crc");
    }
    s.active = false;
    s.error = false;
    OtaOut::Ok
}

/// `ota::abort` (ota.rs:556-564).
fn oracle_abort(s: &mut Ota) -> OtaOut {
    if !s.active {
        return OtaOut::Err("no_session");
    }
    s.active = false;
    s.error = false;
    s.written = 0;
    OtaOut::Ok
}

fn kstate(o: &Ota) -> k::OtaState {
    k::OtaState {
        active: o.active,
        target_slot: o.target,
        running_slot: o.running,
        total: o.total,
        written: o.written,
        error: o.error,
    }
}

fn run_ota(rng: &mut Rng) -> Result<(), String> {
    let admin = k::Device { admin: true };
    // Start booted (running slot 0 or 1).
    let running = if rng.b() { 0u8 } else { 1u8 };
    let mut oracle = Ota { active: false, target: 0, running, total: 0, written: 0, error: false };

    for _step in 0..40 {
        // Pick a command biased toward a valid flow.
        let choice = rng.next() % 5;
        let kcmd;
        let kout: Result<(Option<k::OtaState>, k::Reply), k::Error>;
        let before = kstate(&oracle);
        let oout = match choice {
            0 => {
                let size = rng.u32_in(1, 20000);
                kcmd = k::Command::Begin { size };
                oracle_begin(&mut oracle, size)
            }
            1 => {
                let offset = if rng.b() { before.written } else { rng.u32_in(0, 20000) };
                let len = rng.u32_in(0, 5000);
                kcmd = k::Command::Write { offset, len };
                oracle_write(&mut oracle, offset, len)
            }
            2 => {
                let crc = rng.u32_in(0, 100);
                let actual = if rng.b() { crc } else { rng.u32_in(0, 100) };
                let magic = rng.b();
                kcmd = k::Command::End { expected_crc: crc, actual_crc: actual, magic_ok: magic };
                oracle_end(&mut oracle, crc, actual, magic)
            }
            3 => {
                kcmd = k::Command::Abort;
                oracle_abort(&mut oracle)
            }
            _ => {
                kcmd = k::Command::Status;
                OtaOut::Ok
            }
        };

        kout = k::transition(&admin, &before, &kcmd);

        // Compare ok/err classification.
        match (&oout, &kout) {
            (OtaOut::Ok, Ok((ws, _))) => {
                // When the oracle committed a change, the kernel's new state
                // must match (for Status/retry the oracle didn't change state).
                let knext = k::apply(&before, ws);
                if kstate(&oracle) != knext {
                    return Err(format!(
                        "OTA state mismatch after {:?}: oracle={:?} kernel={:?}",
                        kcmd,
                        oracle,
                        knext
                    ));
                }
            }
            (OtaOut::Err(_), Err(_)) => { /* both refused */ }
            _ => {
                return Err(format!(
                    "OTA outcome mismatch on {:?}: oracle={:?} kernel={:?}",
                    kcmd, oout, kout.is_ok()
                ));
            }
        }
    }
    Ok(())
}

// ===========================================================================
// Oracle 2: auth gate  (upstream src/auth.rs check_auth, lines 335-430)
// ===========================================================================

#[derive(Clone, Copy)]
struct AuthIn {
    public_access: bool,
    allow_http_tokens: bool,
    bearer_set: bool,
    apikey_set: bool,
    cookie_present: bool,
    cookie_valid: bool,
    bearer_present: bool,
    bearer_match: bool,
    akh_present: bool,
    akh_match: bool,
    akq_present: bool,
    akq_match: bool,
    digest_ok: bool,
    is_https: bool,
    is_health: bool,
}

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
enum Dec {
    Allowed,
    SetSession,
    Forbidden,
    Challenge,
}

/// Faithful transcription of upstream `check_auth` (auth.rs:335-430), with
/// `cookie_valid` standing for a decrypted cookie that `validate_session`
/// accepts, and `*_match` for `constant_time_eq` results.
fn oracle_check(a: AuthIn) -> Dec {
    if a.public_access {
        return Dec::Allowed;
    }
    if a.is_health {
        return Dec::Allowed;
    }
    // session cookie
    if a.cookie_present && a.cookie_valid {
        return Dec::Allowed;
    }
    // bearer
    if a.bearer_present {
        if !a.is_https && !a.allow_http_tokens {
            return Dec::Forbidden;
        }
        if a.bearer_set && a.bearer_match {
            return Dec::Allowed;
        }
    }
    // api key header
    if a.akh_present {
        if !a.is_https && !a.allow_http_tokens {
            return Dec::Forbidden;
        }
        if a.apikey_set && a.akh_match {
            return Dec::Allowed;
        }
    }
    // api key query
    if a.akq_present {
        if !a.is_https && !a.allow_http_tokens {
            return Dec::Forbidden;
        }
        if a.apikey_set && a.akq_match {
            return Dec::Allowed;
        }
    }
    if a.digest_ok {
        return Dec::SetSession;
    }
    Dec::Challenge
}

fn kdec(d: k::AuthDecision) -> Dec {
    match d {
        k::AuthDecision::Allowed => Dec::Allowed,
        k::AuthDecision::AllowedSetSession => Dec::SetSession,
        k::AuthDecision::Forbidden => Dec::Forbidden,
        k::AuthDecision::Challenge => Dec::Challenge,
    }
}

fn run_auth(rng: &mut Rng) -> Result<(), String> {
    let a = AuthIn {
        public_access: rng.b(),
        allow_http_tokens: rng.b(),
        bearer_set: rng.b(),
        apikey_set: rng.b(),
        cookie_present: rng.b(),
        cookie_valid: rng.b(),
        bearer_present: rng.b(),
        bearer_match: rng.b(),
        akh_present: rng.b(),
        akh_match: rng.b(),
        akq_present: rng.b(),
        akq_match: rng.b(),
        digest_ok: rng.b(),
        is_https: rng.b(),
        is_health: rng.b(),
    };
    let want = oracle_check(a);

    // Build a session store that `validate_session` accepts iff cookie_valid.
    let cfg = k::AuthCfg {
        public_access: a.public_access,
        allow_http_tokens: a.allow_http_tokens,
        bearer_set: a.bearer_set,
        apikey_set: a.apikey_set,
    };
    let token: [u8; 8] = [1, 2, 3, 4, 5, 6, 7, 8];
    let now = 1000u32;
    let z = k::SessionSlot { token: [0; 8], created: 0 };
    let live = k::SessionSlot { token, created: now }; // age 0 <= TTL
    let store = if a.cookie_valid {
        k::SessionStore { s0: live, s1: z, s2: z, s3: z }
    } else {
        k::SessionStore { s0: z, s1: z, s2: z, s3: z }
    };
    // When cookie not present we pass a zero token; present+valid uses `token`.
    let ctok = if a.cookie_present && a.cookie_valid { token } else { [0u8; 8] };

    let got = kdec(k::check_auth(
        &cfg,
        &store,
        now,
        a.cookie_present,
        &ctok,
        a.bearer_present,
        a.bearer_match,
        a.akh_present,
        a.akh_match,
        a.akq_present,
        a.akq_match,
        a.digest_ok,
        a.is_https,
        a.is_health,
    ));

    if got != want {
        return Err(format!("auth mismatch: want {:?} got {:?}", want, got));
    }
    Ok(())
}

fn main() {
    let mut rng = Rng(0x1234_5678_9abc_def0);
    let mut failures = 0usize;
    const N: usize = 200_000;
    for i in 0..N {
        if let Err(e) = run_ota(&mut rng) {
            eprintln!("[ota #{i}] {e}");
            failures += 1;
            if failures > 10 {
                break;
            }
        }
        if let Err(e) = run_auth(&mut rng) {
            eprintln!("[auth #{i}] {e}");
            failures += 1;
            if failures > 10 {
                break;
            }
        }
    }
    if failures == 0 {
        println!("difftest: {N} OTA sequences and {N} auth cases agree with the upstream oracle");
    } else {
        eprintln!("difftest: {failures} divergence(s)");
        std::process::exit(1);
    }
}
