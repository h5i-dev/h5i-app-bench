//! SpoolEase's inventory HTTP API, on the h5i-app-embedded trusted shell.
//!
//! Mirrors `examples/embedded/thermostat/app`: a `Kernel` marker delegating to
//! the verified `spoolease_kernel`, an `Api` doing the trusted request decode /
//! reply encode, and a tuple-typed `Router`. The kernel's theorems (allocator
//! non-aliasing, bounded file, fresh ids, panic freedom) hold for every command
//! the decoder can produce, so a bad decode can do no more than a client could.
//!
//! ```text
//! GET  /spools                 the record index (ids, offsets, lengths)
//! POST /spool/add    "tag,len"  add a spool (NFC tag id, serialized length)
//! POST /spool/edit/{id} "tag,len"  rewrite spool {id}
//! POST /spool/delete/{id}       delete spool {id}
//! ```
//! Mutating routes need `Authorization: Bearer <key>`; in the real firmware the
//! framework instead encrypts every body with a pre-shared key (A2/A3, trusted).

#![no_std]

extern crate alloc;

use core::fmt::Write as _;

use h5i_app_core::{Kernel, TenantId};
use h5i_app_embedded::kernel::{Api, Authenticator, DeviceEngine, PskAuth, respond};
use h5i_app_embedded::{Request, Response, Router, Routes};
use spoolease_kernel::{Command, Device, Error, Reply, Store};

/// The kernel, as the shell sees it.
pub struct SpoolStore;

impl Kernel for SpoolStore {
    type Principal = Device;
    type Snapshot = Store;
    type Command = Command;
    type WriteSet = Option<Store>;
    type Reply = Reply;
    type Error = Error;

    fn tenant(_: &Device) -> TenantId {
        TenantId(0)
    }

    fn transition(actor: &Device, snap: &Store, cmd: &Command) -> Result<(Option<Store>, Reply), Error> {
        spoolease_kernel::transition(actor, snap, cmd)
    }

    fn apply(snap: &Store, w: &Option<Store>) -> Store {
        spoolease_kernel::apply(snap, w)
    }

    fn read_only(cmd: &Command) -> bool {
        spoolease_kernel::read_only(cmd)
    }
}

/// The device's state and key.
pub struct App {
    pub engine: DeviceEngine<SpoolStore>,
    pub auth: PskAuth<Device>,
}

impl App {
    pub fn new(key: &'static [u8]) -> App {
        App {
            engine: DeviceEngine::new(Store::default()),
            auth: PskAuth { key, principal: Device { admin: true } },
        }
    }
}

/// Anyone may read the index.
struct Open;

impl Authenticator<SpoolStore> for Open {
    fn authenticate(&self, _: &Request<'_>) -> Result<Device, u16> {
        Ok(Device { admin: false })
    }
}

/// Text bodies: `tag,len` pairs and decimal ids.
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

/// Parse `"tag,len"`.
fn parse_tag_len(b: &[u8]) -> Option<(u32, u32)> {
    let mut it = b.split(|&c| c == b',');
    let tag = parse_u32(it.next()?.trim_ascii())?;
    let len = parse_u32(it.next()?.trim_ascii())?;
    if it.next().is_some() {
        return None;
    }
    Some((tag, len))
}

impl Api<SpoolStore> for Wire {
    fn decode_command(req: &Request<'_>) -> Result<Command, u16> {
        let body = req.body.trim_ascii();
        match req.path {
            b"/spools" => Ok(Command::Query),
            b"/spool/add" => {
                let (tag, len) = parse_tag_len(body).ok_or(400u16)?;
                Ok(Command::AddSpool { tag, len })
            }
            _ => {
                // /spool/edit/{id} or /spool/delete/{id}: the router matched a
                // trailing numeric segment.
                let id = req.param_u32(0).ok_or(404u16)?;
                if req.path.starts_with(b"/spool/delete/") {
                    Ok(Command::DeleteSpool { id })
                } else {
                    let (tag, len) = parse_tag_len(body).ok_or(400u16)?;
                    Ok(Command::EditSpool { id, tag, len })
                }
            }
        }
    }

    fn encode_reply(reply: &Reply, out: &mut [u8]) -> Option<usize> {
        let mut w = Cursor { buf: out, at: 0 };
        match reply {
            Reply::Added { id, plan } => write!(
                w,
                "{{\"added\":{},\"void\":[{},{}],\"data\":[{},{}]}}",
                id, plan.void.off, plan.void.len, plan.data.off, plan.data.len
            )
            .ok()?,
            Reply::Wrote { plan } => write!(
                w,
                "{{\"wrote\":true,\"void\":[{},{}],\"data\":[{},{}]}}",
                plan.void.off, plan.void.len, plan.data.off, plan.data.len
            )
            .ok()?,
            Reply::Deleted { plan } => {
                write!(w, "{{\"deleted\":true,\"void\":[{},{}]}}", plan.void.off, plan.void.len).ok()?
            }
            Reply::Listing => write!(w, "{{\"ok\":true}}").ok()?,
        }
        Some(w.at)
    }

    fn encode_error(err: &Error, out: &mut [u8]) -> (u16, usize) {
        let (status, msg): (u16, &[u8]) = match err {
            Error::BadLen => (422, b"{\"error\":\"bad_len\"}"),
            Error::Full => (507, b"{\"error\":\"full\"}"),
            Error::NotFound => (404, b"{\"error\":\"not_found\"}"),
            Error::Forbidden => (403, b"{\"error\":\"forbidden\"}"),
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
    respond::<SpoolStore, Wire>(&app.engine, &Open, req, out)
}

async fn write(req: &Request<'_>, app: &App, out: &mut [u8]) -> Response {
    respond::<SpoolStore, Wire>(&app.engine, &app.auth, req, out)
}

/// The routes.
pub fn router() -> Router<impl Routes<App>> {
    Router::new()
        .get(b"/spools", read)
        .post(b"/spool/add", write)
        .post(b"/spool/edit/{id}", write)
        .post(b"/spool/delete/{id}", write)
}
