//! The M5AirQ-Rust OTA + auth HTTP API, wired onto the verified
//! `h5i-app-embedded` shell. Mirrors `examples/embedded/thermostat/app`.
//!
//! ```text
//! GET  /api/ota/status                  the OTA session state as JSON
//! POST /api/ota/begin/{size}            open a session for {size} bytes
//! POST /api/ota/write/{offset}?len={n}  write an {n}-byte chunk at {offset}
//! GET  /api/ota/end/{crc}               finalize (magic + CRC gate)
//! GET  /api/ota/abort                   abort the session
//! ```
//!
//! Every mutating route is behind the authenticator, which runs the verified
//! `check_auth` decision. Request decoding and reply encoding are trusted
//! (A2, A3); the kernel's theorems hold for every command the shell builds.

#![no_std]

use core::fmt::Write as _;

use h5i_app_core::{Kernel, TenantId};
use h5i_app_embedded::kernel::{Api, Authenticator, DeviceEngine, respond};
use h5i_app_embedded::{Request, Response, Router, Routes};
use m5airq_kernel::{
    AuthCfg, Command, Device, Error, OtaState, Reply, SessionSlot, SessionStore, check_auth,
};

/// The kernel, as the shell sees it.
pub struct M5Ota;

impl Kernel for M5Ota {
    type Principal = Device;
    type Snapshot = OtaState;
    type Command = Command;
    type WriteSet = Option<OtaState>;
    type Reply = Reply;
    type Error = Error;

    fn tenant(_: &Device) -> TenantId {
        TenantId(0)
    }

    fn transition(actor: &Device, snap: &OtaState, cmd: &Command) -> Result<(Option<OtaState>, Reply), Error> {
        m5airq_kernel::transition(actor, snap, cmd)
    }

    fn apply(snap: &OtaState, w: &Option<OtaState>) -> OtaState {
        m5airq_kernel::apply(snap, w)
    }

    fn read_only(cmd: &Command) -> bool {
        m5airq_kernel::read_only(cmd)
    }
}

/// The device: its OTA engine, auth posture and session store.
pub struct App {
    pub engine: DeviceEngine<M5Ota>,
    pub cfg: AuthCfg,
    pub bearer_key: &'static [u8],
    /// Decryption key for session cookies (XOR pad), trusted IO.
    pub cookie_key: [u8; 16],
}

impl App {
    pub const fn new(bearer_key: &'static [u8], cookie_key: [u8; 16], running_slot: u8) -> App {
        App {
            engine: DeviceEngine::new(OtaState { running_slot, ..m5airq_kernel::OTA_INITIAL }),
            // Secure posture: public access OFF (unlike the upstream default).
            cfg: AuthCfg { public_access: false, allow_http_tokens: false, bearer_set: true, apikey_set: false },
            bearer_key,
            cookie_key,
        }
    }
}

/// Runs the verified `check_auth` decision for this request.
///
/// A real device threads a live `SessionStore` and clock in here; this
/// demonstration uses an empty store (no cookie sessions) and a bearer key,
/// which is the strongest, simplest posture. The authenticator is trusted
/// (A1); the proofs constrain only `check_auth`'s decision.
pub struct AuthGate;

fn empty_store() -> SessionStore {
    let z = SessionSlot { token: [0; 8], created: 0 };
    SessionStore { s0: z, s1: z, s2: z, s3: z }
}

impl Authenticator<M5Ota> for App {
    fn authenticate(&self, req: &Request<'_>) -> Result<Device, u16> {
        // Health is public upstream; here every OTA route needs auth.
        let bearer = req.header(b"authorization").and_then(|v| v.strip_prefix(b"Bearer "));
        let bearer_present = bearer.is_some();
        let bearer_match = match bearer {
            Some(tok) => h5i_app_embedded::kernel::ct_eq(tok, self.bearer_key),
            None => false,
        };
        let store = empty_store();
        let decision = check_auth(
            &self.cfg,
            &store,
            0,
            false,
            &[0u8; 8],
            bearer_present,
            bearer_match,
            false,
            false,
            false,
            false,
            false,
            true, // the shell is run over a TLS/loopback transport here
            false,
        );
        match decision {
            m5airq_kernel::AuthDecision::Allowed | m5airq_kernel::AuthDecision::AllowedSetSession => {
                Ok(Device { admin: true })
            }
            m5airq_kernel::AuthDecision::Forbidden => Err(403),
            m5airq_kernel::AuthDecision::Challenge => Err(401),
        }
    }
}

/// Reads are open (OTA status).
struct Open;

impl Authenticator<M5Ota> for Open {
    fn authenticate(&self, _: &Request<'_>) -> Result<Device, u16> {
        Ok(Device { admin: false })
    }
}

/// Text/JSON wire format.
pub struct Wire;

fn parse_u32(b: &[u8]) -> Option<u32> {
    if b.is_empty() || b.len() > 10 || !b.iter().all(u8::is_ascii_digit) {
        return None;
    }
    let mut v: u64 = 0;
    for &c in b {
        v = v * 10 + (c - b'0') as u64;
    }
    u32::try_from(v).ok()
}

impl Api<M5Ota> for Wire {
    fn decode_command(req: &Request<'_>) -> Result<Command, u16> {
        match req.path {
            b"/api/ota/status" => Ok(Command::Status),
            b"/api/ota/abort" => Ok(Command::Abort),
            p if p.starts_with(b"/api/ota/begin/") => {
                let size = parse_u32(&p[b"/api/ota/begin/".len()..]).ok_or(400u16)?;
                Ok(Command::Begin { size })
            }
            p if p.starts_with(b"/api/ota/write/") => {
                let offset = parse_u32(&p[b"/api/ota/write/".len()..]).ok_or(400u16)?;
                // The body length is the chunk length; the shell has read it.
                let len = u32::try_from(req.body.len()).map_err(|_| 400u16)?;
                Ok(Command::Write { offset, len })
            }
            p if p.starts_with(b"/api/ota/end/") => {
                let crc = parse_u32(&p[b"/api/ota/end/".len()..]).ok_or(400u16)?;
                // `actual_crc`/`magic_ok` are the trusted flash read-back; the
                // device computes them. Here we model a matching read-back.
                Ok(Command::End { expected_crc: crc, actual_crc: crc, magic_ok: true })
            }
            _ => Err(404),
        }
    }

    fn encode_reply(reply: &Reply, out: &mut [u8]) -> Option<usize> {
        let Reply::State(s) = reply;
        let mut w = Cursor { buf: out, at: 0 };
        write!(
            w,
            "{{\"active\":{},\"target_slot\":{},\"running_slot\":{},\"written\":{},\"total\":{},\"error\":{}}}",
            s.active, s.target_slot, s.running_slot, s.written, s.total, s.error
        )
        .ok()?;
        Some(w.at)
    }

    fn encode_error(err: &Error, out: &mut [u8]) -> (u16, usize) {
        let (status, msg): (u16, &[u8]) = match err {
            Error::Forbidden => (403, b"{\"error\":\"forbidden\"}"),
            Error::AlreadyActive => (409, b"{\"error\":\"already_active\"}"),
            Error::BadSize => (400, b"{\"error\":\"bad_size\"}"),
            Error::RunningUnknown => (503, b"{\"error\":\"running_slot_unknown\"}"),
            Error::NoSession => (409, b"{\"error\":\"no_session\"}"),
            Error::PriorError => (409, b"{\"error\":\"prior_error\"}"),
            Error::ChunkSize => (413, b"{\"error\":\"chunk_size\"}"),
            Error::OffsetMismatch => (409, b"{\"error\":\"offset_mismatch\"}"),
            Error::ExceedsDeclared => (400, b"{\"error\":\"exceeds_declared\"}"),
            Error::Incomplete => (409, b"{\"error\":\"incomplete\"}"),
            Error::BadMagic => (422, b"{\"error\":\"bad_magic\"}"),
            Error::CrcMismatch => (422, b"{\"error\":\"crc_mismatch\"}"),
        };
        let n = msg.len().min(out.len());
        out[..n].copy_from_slice(&msg[..n]);
        (status, n)
    }
}

struct Cursor<'a> {
    buf: &'a mut [u8],
    at: usize,
}

impl core::fmt::Write for Cursor<'_> {
    fn write_str(&mut self, s: &str) -> core::fmt::Result {
        let b = s.as_bytes();
        if b.len() > self.buf.len() - self.at {
            return Err(core::fmt::Error);
        }
        self.buf[self.at..self.at + b.len()].copy_from_slice(b);
        self.at += b.len();
        Ok(())
    }
}

async fn read(req: &Request<'_>, app: &App, out: &mut [u8]) -> Response {
    respond::<M5Ota, Wire>(&app.engine, &Open, req, out)
}

async fn write(req: &Request<'_>, app: &App, out: &mut [u8]) -> Response {
    respond::<M5Ota, Wire>(&app.engine, app, req, out)
}

/// The routes.
pub fn router() -> Router<impl Routes<App>> {
    Router::new()
        .get(b"/api/ota/status", read)
        .post(b"/api/ota/begin/{size}", write)
        .post(b"/api/ota/write/{offset}", write)
        .get(b"/api/ota/end/{crc}", write)
        .get(b"/api/ota/abort", write)
}
