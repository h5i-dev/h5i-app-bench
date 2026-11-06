//! The Anova-oven scheduler kernel's HTTP API, running under the verified
//! `h5i-app-embedded` shell (the same shell that would replace `picoserve` on
//! the inbound path).
//!
//! ```text
//! GET  /sched                 poll health (fail_count, interval, offline)  [open]
//! POST /poll/ok                                                            [key]
//! POST /poll/fail                                                          [key]
//! PUT  /enqueue/{k}  "1234"    schedule kind k (0..=5) at time (seconds)    [key]
//! POST /pop          "1234"    pop the soonest-due event at time=now        [key]
//! ```
//!
//! Mutations need `Authorization: Bearer <key>`. Decoding requests and encoding
//! replies is trusted (A2, A3); the kernel's theorems hold for every command.

#![no_std]

use core::fmt::Write as _;

use anova_oven_kernel::{Command, Kind, Queue, Reply, Error};
use h5i_app_core::{Kernel, TenantId};
use h5i_app_embedded::kernel::{Api, Authenticator, DeviceEngine, PskAuth, respond};
use h5i_app_embedded::{Request, Response, Router, Routes};

/// The one principal. Writes require the bearer key; reads are open.
#[derive(Clone, Copy)]
pub struct Device;

/// The kernel, as the shell sees it.
pub struct Oven;

impl Kernel for Oven {
    type Principal = Device;
    type Snapshot = Queue;
    type Command = Command;
    type WriteSet = Option<Queue>;
    type Reply = Reply;
    type Error = Error;

    fn tenant(_: &Device) -> TenantId {
        TenantId(0)
    }

    fn transition(_: &Device, snap: &Queue, cmd: &Command) -> Result<(Option<Queue>, Reply), Error> {
        anova_oven_kernel::transition(snap, cmd)
    }

    fn apply(snap: &Queue, w: &Option<Queue>) -> Queue {
        anova_oven_kernel::apply(snap, w)
    }

    fn read_only(cmd: &Command) -> bool {
        anova_oven_kernel::read_only(cmd)
    }
}

/// The device's scheduler state and key.
pub struct App {
    pub engine: DeviceEngine<Oven>,
    pub auth: PskAuth<Device>,
}

impl App {
    pub const fn new(key: &'static [u8]) -> App {
        App {
            engine: DeviceEngine::new(anova_oven_kernel::EMPTY),
            auth: PskAuth { key, principal: Device },
        }
    }
}

/// Anyone may read poll health.
struct Open;

impl Authenticator<Oven> for Open {
    fn authenticate(&self, _: &Request<'_>) -> Result<Device, u16> {
        Ok(Device)
    }
}

/// Text bodies: an unsigned decimal.
pub struct Wire;

fn parse_u64(b: &[u8]) -> Option<u64> {
    let b = b.trim_ascii();
    if b.is_empty() || b.len() > 20 || !b.iter().all(u8::is_ascii_digit) {
        return None;
    }
    let mut v: u64 = 0;
    for &c in b {
        v = v.checked_mul(10)?.checked_add((c - b'0') as u64)?;
    }
    Some(v)
}

fn kind_of_id(id: u32) -> Option<Kind> {
    match id {
        0 => Some(Kind::PollStatus),
        1 => Some(Kind::PollCurrentCook),
        2 => Some(Kind::PollRecipes),
        3 => Some(Kind::UserStart),
        4 => Some(Kind::UserStop),
        5 => Some(Kind::UserNextStage),
        _ => None,
    }
}

impl Api<Oven> for Wire {
    fn decode_command(req: &Request<'_>) -> Result<Command, u16> {
        match req.path {
            b"/sched" => Ok(Command::Peek),
            b"/poll/ok" => Ok(Command::PollOk),
            b"/poll/fail" => Ok(Command::PollFail),
            b"/pop" => parse_u64(req.body).map(|now| Command::PopDue { now }).ok_or(400),
            _ => {
                // /enqueue/{k}: the router matched it; k is 0..=5.
                let id = req.param_u32(0).ok_or(404u16)?;
                let kind = kind_of_id(id).ok_or(404u16)?;
                let time = parse_u64(req.body).ok_or(400u16)?;
                Ok(Command::Enqueue { kind, time, replace: false })
            }
        }
    }

    fn encode_reply(reply: &Reply, out: &mut [u8]) -> Option<usize> {
        let mut w = Cursor { buf: out, at: 0 };
        match reply {
            Reply::Queued => write!(w, "{{\"ok\":true}}").ok()?,
            Reply::Popped(k) => {
                let name = match k {
                    None => "none",
                    Some(k) => kind_name(*k),
                };
                write!(w, "{{\"popped\":\"{}\"}}", name).ok()?
            }
            Reply::Health { fail_count, interval, offline } => {
                write!(
                    w,
                    "{{\"fail_count\":{},\"interval_secs\":{},\"offline\":{}}}",
                    fail_count, interval, offline
                )
                .ok()?
            }
        }
        Some(w.at)
    }

    fn encode_error(_err: &Error, out: &mut [u8]) -> (u16, usize) {
        // The kernel refuses nothing (`Error::Never` is uninhabited in practice).
        let msg = b"{\"error\":\"never\"}";
        let n = msg.len().min(out.len());
        out[..n].copy_from_slice(&msg[..n]);
        (500, n)
    }
}

fn kind_name(k: Kind) -> &'static str {
    match k {
        Kind::PollStatus => "poll_status",
        Kind::PollCurrentCook => "poll_current_cook",
        Kind::PollRecipes => "poll_recipes",
        Kind::UserStart => "user_start",
        Kind::UserStop => "user_stop",
        Kind::UserNextStage => "user_next_stage",
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
    respond::<Oven, Wire>(&app.engine, &Open, req, out)
}

async fn write(req: &Request<'_>, app: &App, out: &mut [u8]) -> Response {
    respond::<Oven, Wire>(&app.engine, &app.auth, req, out)
}

/// The routes.
pub fn router() -> Router<impl Routes<App>> {
    Router::new()
        .get(b"/sched", read)
        .post(b"/poll/ok", write)
        .post(b"/poll/fail", write)
        .put(b"/enqueue/{k}", write)
        .post(b"/pop", write)
}
