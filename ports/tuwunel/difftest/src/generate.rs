//! Random snapshots and requests. A snapshot is built by appending events
//! to a few rooms, keeping what upstream's append path keeps: the state
//! before each event, the room's current state, the state cache (as
//! `update_membership` leaves it), the relation index and the thread index.
//! A share of snapshots is then perturbed (cache rows, missing state,
//! outliers) so the tests also cover data the append path would not write.
use tuwunel_kernel::*;

use crate::world::shortstatekey;

pub struct Rng(pub u64);

impl Rng {
    pub fn next(&mut self) -> u64 {
        self.0 ^= self.0 << 13;
        self.0 ^= self.0 >> 7;
        self.0 ^= self.0 << 17;
        self.0
    }
    pub fn below(&mut self, n: u64) -> u64 {
        self.next() % n
    }
    /// True with probability `p` percent.
    pub fn pct(&mut self, p: u64) -> bool {
        self.below(100) < p
    }
    pub fn pick<T: Copy>(&mut self, v: &[T]) -> T {
        v[self.below(v.len() as u64) as usize]
    }
}

pub const USERS: [u64; 6] = [1001, 1002, 1003, 2001, 2002, 3001];
pub const SERVERS: [u64; 3] = [1, 2, 3];
/// A user and a room the snapshot does not know.
pub const STRANGER: u64 = 9001;
pub const NO_ROOM: u64 = 99;

fn membership(rng: &mut Rng) -> Membership {
    match rng.below(20) {
        0..=6 => Membership::Join,
        7..=10 => Membership::Leave,
        11..=13 => Membership::Invite,
        14..=16 => Membership::Ban,
        17..=18 => Membership::Knock,
        _ => Membership::Custom(rng.below(2)),
    }
}

fn history_visibility(rng: &mut Rng) -> HvField {
    match rng.below(12) {
        0..=2 => HvField::Is(HistoryVisibility::Shared),
        3..=4 => HvField::Is(HistoryVisibility::Joined),
        5..=6 => HvField::Is(HistoryVisibility::Invited),
        7..=9 => HvField::Is(HistoryVisibility::WorldReadable),
        10 => HvField::Is(HistoryVisibility::Custom(rng.below(2))),
        _ => HvField::Absent,
    }
}

fn rel_type(rng: &mut Rng) -> RelType {
    match rng.below(9) {
        0..=2 => RelType::Thread,
        3..=4 => RelType::Annotation,
        5 => RelType::Reference,
        6..=7 => RelType::Replacement,
        _ => RelType::Custom(rng.below(2)),
    }
}

fn message_kind(rng: &mut Rng) -> Kind {
    match rng.below(14) {
        0..=5 => Kind::Message,
        6..=7 => Kind::Reaction,
        8 => Kind::Encrypted,
        9 => Kind::Sticker,
        10 => Kind::Dummy,
        11 => Kind::Redaction,
        _ => Kind::Custom(rng.below(3)),
    }
}

/// The latest standard membership of each `(user, room)`, the counts of
/// their events, and whether they ever joined.
#[derive(Default)]
struct Cache {
    last: Vec<(u64, u64, Membership, i64)>,
    once: Vec<(u64, u64)>,
}

struct RoomSim {
    id: u64,
    short: u64,
    entries: Vec<StateEntry>,
    hash: u64,
    events: Vec<usize>,
}

pub struct Built {
    pub snapshot: Snapshot,
    /// No perturbation was applied: the snapshot is what appending its
    /// events leaves.
    pub consistent: bool,
}

pub fn snapshot(rng: &mut Rng) -> Built {
    let nrooms = 1 + rng.below(3);
    let mut s = Snapshot {
        rooms: Vec::new(),
        pdus: Vec::new(),
        states: vec![StateSet { hash: 1, entries: Vec::new() }],
        joined: Vec::new(),
        invited: Vec::new(),
        knocked: Vec::new(),
        left: Vec::new(),
        once_joined: Vec::new(),
        relations: Vec::new(),
        thread_activity: Vec::new(),
        thread_latest: Vec::new(),
        thread_participants: Vec::new(),
        ignored: Vec::new(),
        config: Config { server_name: 1, forbidden_remote_server_names: Vec::new(), allowed_remote_server_names: Vec::new() },
        current_count: 0,
    };
    let mut rooms: Vec<RoomSim> =
        (1..=nrooms).map(|r| RoomSim { id: r, short: 10 + 7 * r, entries: Vec::new(), hash: 1, events: Vec::new() }).collect();
    let mut cache = Cache::default();
    let mut count: i64 = 0;
    let mut next_event = 1u64;
    let mut next_hash = 2u64;
    let steps = 2 + rng.below(40);
    for step in 0..(steps + 2 * nrooms) {
        let ri = if step < 2 * nrooms { (step / 2) as usize } else { rng.below(nrooms) as usize };
        let r = &mut rooms[ri];
        count += 1 + rng.below(2) as i64;
        let creator = USERS[ri % USERS.len()];
        let mut p = Pdu {
            event_id: next_event,
            room: r.id,
            sender: rng.pick(&USERS),
            kind: Kind::Message,
            has_state_key: false,
            state_key: 0,
            membership: MemberField::Absent,
            history_visibility: HvField::Absent,
            relates_to: Relates::None,
            has_url: rng.pct(20),
            outlier: false,
            count,
            state: if rng.pct(3) { StateRef::None } else { StateRef::Hash(r.hash) },
        };
        next_event += 1;
        if r.events.is_empty() {
            p.kind = Kind::Create;
            p.sender = creator;
            p.has_state_key = true;
            p.has_url = false;
        } else if r.events.len() == 1 {
            p.kind = Kind::Member;
            p.sender = creator;
            p.has_state_key = true;
            p.state_key = creator;
            p.membership = MemberField::Is(Membership::Join);
        } else {
            match rng.below(10) {
                0..=2 => {
                    let t = rng.pick(&USERS);
                    let m = membership(rng);
                    p.kind = Kind::Member;
                    p.has_state_key = true;
                    p.state_key = t;
                    p.membership = if rng.pct(4) { MemberField::Absent } else { MemberField::Is(m) };
                    if matches!(m, Membership::Join | Membership::Leave | Membership::Knock) && rng.pct(80) {
                        p.sender = t;
                    }
                }
                3 => {
                    p.kind = Kind::HistoryVisibility;
                    p.has_state_key = true;
                    p.history_visibility = history_visibility(rng);
                }
                4 if rng.pct(30) => {
                    p.kind = rng.pick(&[Kind::Encryption, Kind::Name, Kind::JoinRules, Kind::PowerLevels, Kind::Custom(7)]);
                    p.has_state_key = true;
                    if rng.pct(20) {
                        p.state_key = rng.pick(&USERS);
                    }
                }
                _ => {
                    p.kind = message_kind(rng);
                    if rng.pct(45) {
                        // chains of relations, for `recurse`
                        let relating: Vec<u64> = r
                            .events
                            .iter()
                            .map(|i| &s.pdus[*i])
                            .filter(|x| matches!(x.relates_to, Relates::To(..)))
                            .map(|x| x.event_id)
                            .collect();
                        let target = if !relating.is_empty() && rng.pct(50) {
                            rng.pick(&relating)
                        } else if rng.pct(90) && !r.events.is_empty() {
                            s.pdus[r.events[rng.below(r.events.len() as u64) as usize]].event_id
                        } else {
                            1 + rng.below(next_event + 2)
                        };
                        p.relates_to = Relates::To(rel_type(rng), target);
                    }
                }
            }
        }
        // the state after this event
        if p.has_state_key {
            let key = shortstatekey(p.kind, p.state_key);
            let e = StateEntry { kind: p.kind, state_key: p.state_key, event_id: p.event_id };
            match r.entries.iter().position(|x| shortstatekey(x.kind, x.state_key) >= key) {
                Some(i) if shortstatekey(r.entries[i].kind, r.entries[i].state_key) == key => r.entries[i] = e,
                Some(i) => r.entries.insert(i, e),
                None => r.entries.push(e),
            }
            r.hash = next_hash;
            next_hash += 1;
            s.states.push(StateSet { hash: r.hash, entries: r.entries.clone() });
        }
        if let (Kind::Member, MemberField::Is(m)) = (p.kind, p.membership) {
            if !matches!(m, Membership::Custom(_)) {
                cache.last.retain(|x| !(x.0 == p.state_key && x.1 == r.id));
                cache.last.push((p.state_key, r.id, m, p.count));
                if matches!(m, Membership::Join) && !cache.once.contains(&(p.state_key, r.id)) {
                    cache.once.push((p.state_key, r.id));
                }
            }
        }
        // relation and thread indexes
        if let Relates::To(rt, target) = p.relates_to {
            if let Some(t) = s.pdus.iter().find(|x| x.event_id == target && !x.outlier) {
                s.relations.push(Relation { to: t.count as u64, from: p.count as u64 });
                if rt == RelType::Thread && t.room == p.room {
                    let (root, root_sender) = (t.count as u64, t.sender);
                    match s.thread_participants.iter_mut().find(|x| x.room_short == r.short && x.root == root) {
                        Some(x) => x.users.push(p.sender),
                        None => s.thread_participants.push(ThreadParticipants {
                            room_short: r.short,
                            root,
                            users: vec![root_sender, p.sender],
                        }),
                    }
                    s.thread_activity.push(ThreadActivity { room_short: r.short, count: p.count as u64, root });
                    match s.thread_latest.iter_mut().find(|x| x.room_short == r.short && x.root == root) {
                        Some(x) => x.latest = p.count as u64,
                        None => s.thread_latest.push(ThreadLatest { room_short: r.short, root, latest: p.count as u64 }),
                    }
                }
            }
        }
        r.events.push(s.pdus.len());
        s.pdus.push(p);
    }
    s.current_count = count + rng.below(3) as i64;
    for r in &rooms {
        s.rooms.push(Room { id: r.id, short: r.short, state: StateRef::Hash(r.hash) });
    }
    if rng.pct(20) {
        // a room this server knows of without timeline rows
        s.rooms.push(Room { id: 50, short: 77, state: StateRef::Hash(1) });
    }
    for (u, r, m, c) in &cache.last {
        let row = UserRoom { user: *u, room: *r };
        match m {
            Membership::Join => s.joined.push(row),
            Membership::Invite => s.invited.push(row),
            Membership::Knock => s.knocked.push(row),
            Membership::Leave | Membership::Ban => {
                // a forgotten room keeps no leave row
                if !rng.pct(10) {
                    s.left.push(LeftRow { user: *u, room: *r, count: *c as u64 });
                }
            }
            Membership::Custom(_) => {}
        }
    }
    for (u, r) in &cache.once {
        s.once_joined.push(UserRoom { user: *u, room: *r });
    }
    for _ in 0..rng.below(4) {
        let (u, i) = (rng.pick(&USERS), rng.pick(&USERS));
        if u != i {
            s.ignored.push(Ignore { user: u, ignored: i });
        }
    }
    if rng.pct(30) {
        s.config.forbidden_remote_server_names.push(rng.pick(&SERVERS));
    }
    if rng.pct(10) {
        s.config.allowed_remote_server_names.push(rng.pick(&SERVERS));
    }
    // outliers: events known from federation, outside the timeline
    for _ in 0..rng.below(3) {
        let room = if rng.pct(70) { 1 + rng.below(nrooms) } else { NO_ROOM };
        s.pdus.push(Pdu {
            event_id: next_event,
            room,
            sender: rng.pick(&USERS),
            kind: message_kind(rng),
            has_state_key: false,
            state_key: 0,
            membership: MemberField::Absent,
            history_visibility: HvField::Absent,
            relates_to: Relates::None,
            has_url: false,
            outlier: true,
            count: 0,
            state: if rng.pct(30) { StateRef::Hash(1 + rng.below(next_hash - 1)) } else { StateRef::None },
        });
        next_event += 1;
    }
    s.relations.sort_by_key(|x| (x.to, x.from));
    s.relations.dedup();
    s.thread_activity.sort_by_key(|x| (x.room_short, x.count));
    let consistent = !rng.pct(15);
    if !consistent {
        perturb(rng, &mut s);
    }
    Built { snapshot: s, consistent }
}

/// Rows the append path would not leave: random cache rows, a missing
/// room state, dangling state entries.
fn perturb(rng: &mut Rng, s: &mut Snapshot) {
    for _ in 0..1 + rng.below(3) {
        let row = UserRoom { user: rng.pick(&USERS), room: 1 + rng.below(3) };
        match rng.below(6) {
            0 => s.joined.push(row),
            1 => s.invited.push(row),
            2 => s.knocked.push(row),
            3 => s.once_joined.push(row),
            4 => {
                // keyed by (user, room): replace
                s.left.retain(|x| !(x.user == row.user && x.room == row.room));
                s.left.push(LeftRow { user: row.user, room: row.room, count: rng.below(80) });
            }
            _ => {
                if !s.left.is_empty() {
                    let i = rng.below(s.left.len() as u64) as usize;
                    s.left.remove(i);
                }
            }
        }
    }
    if rng.pct(30) && !s.rooms.is_empty() {
        let i = rng.below(s.rooms.len() as u64) as usize;
        s.rooms[i].state = StateRef::None;
    }
    if rng.pct(30) && s.states.len() > 1 {
        let i = 1 + rng.below(s.states.len() as u64 - 1) as usize;
        let e = 500 + rng.below(5);
        s.states[i].entries.push(StateEntry { kind: Kind::Custom(50), state_key: 0, event_id: e });
    }
}

fn token(rng: &mut Rng, s: &Snapshot) -> Token {
    match rng.below(20) {
        0..=7 => Token::Absent,
        8 => Token::Invalid,
        9 => Token::At(rng.pick(&[i64::MIN, i64::MAX, -1, 0])),
        _ => Token::At(rng.below(s.current_count as u64 + 3) as i64 - 1),
    }
}

fn some_users(rng: &mut Rng) -> Vec<u64> {
    (0..1 + rng.below(2)).map(|_| rng.pick(&USERS)).collect()
}

pub fn filter(rng: &mut Rng) -> Filter {
    let mut f = Filter {
        senders: None,
        not_senders: Vec::new(),
        types: None,
        not_types: Vec::new(),
        rooms: None,
        not_rooms: Vec::new(),
        url_filter: UrlFilter::Any,
        related_by_senders: Vec::new(),
        related_by_rel_types: Vec::new(),
    };
    if rng.pct(60) {
        return f;
    }
    if rng.pct(25) {
        f.senders = Some(some_users(rng));
    }
    if rng.pct(25) {
        f.not_senders = some_users(rng);
    }
    if rng.pct(25) {
        f.types = Some((0..1 + rng.below(2)).map(|_| message_kind(rng)).collect());
    }
    if rng.pct(25) {
        f.not_types = vec![rng.pick(&[Kind::Message, Kind::Member, Kind::Reaction, Kind::HistoryVisibility])];
    }
    if rng.pct(10) {
        f.rooms = Some(vec![1 + rng.below(3)]);
    }
    if rng.pct(10) {
        f.not_rooms = vec![1 + rng.below(3)];
    }
    if rng.pct(20) {
        f.url_filter = if rng.pct(50) { UrlFilter::WithUrl } else { UrlFilter::WithoutUrl };
    }
    if rng.pct(25) {
        f.related_by_senders = some_users(rng);
    }
    if rng.pct(25) {
        f.related_by_rel_types = (0..1 + rng.below(2)).map(|_| rel_type(rng)).collect();
    }
    f
}

fn limit(rng: &mut Rng) -> u64 {
    match rng.below(10) {
        0 => 0,
        1 => 2000,
        _ => 1 + rng.below(12),
    }
}

pub fn request(rng: &mut Rng, s: &Snapshot) -> Request {
    let rooms: Vec<u64> = s.rooms.iter().map(|r| r.id).collect();
    let room = if rng.pct(4) { NO_ROOM } else { rng.pick(&rooms) };
    // mostly users with some history in the room
    let members: Vec<u64> = s
        .pdus
        .iter()
        .filter(|p| p.room == room && p.kind == Kind::Member && !p.outlier)
        .map(|p| p.state_key)
        .collect();
    let user = if rng.pct(4) {
        STRANGER
    } else if !members.is_empty() && rng.pct(75) {
        rng.pick(&members)
    } else {
        rng.pick(&USERS)
    };
    let max_event = s.pdus.iter().map(|p| p.event_id).max().unwrap_or(0);
    let of_room: Vec<u64> = s.pdus.iter().filter(|p| p.room == room).map(|p| p.event_id).collect();
    let related: Vec<u64> = s
        .pdus
        .iter()
        .filter_map(|p| match p.relates_to {
            Relates::To(_, t) if p.room == room => Some(t),
            _ => None,
        })
        .collect();
    let event = if rng.pct(4) {
        max_event + 7
    } else if !related.is_empty() && rng.pct(40) {
        rng.pick(&related)
    } else if !of_room.is_empty() && rng.pct(85) {
        rng.pick(&of_room)
    } else {
        1 + rng.below(max_event.max(1))
    };
    let op = match rng.below(12) {
        0..=2 => Op::Messages {
            room,
            from: token(rng, s),
            to: if rng.pct(30) { token(rng, s) } else { Token::Absent },
            dir: if rng.pct(50) { Dir::Forward } else { Dir::Backward },
            limit: limit(rng),
            filter: filter(rng),
        },
        3 => Op::Context { room, event, limit: limit(rng), filter: filter(rng) },
        4 => {
            let rel_type = if rng.pct(40) { Some(rel_type(rng)) } else { None };
            let event_type = if rel_type.is_some() && rng.pct(40) { Some(message_kind(rng)) } else { None };
            Op::Relations {
                room,
                event,
                rel_type,
                event_type,
                from: token(rng, s),
                to: if rng.pct(30) { token(rng, s) } else { Token::Absent },
                limit: if rng.pct(30) { None } else { Some(limit(rng)) },
                recurse: rng.pct(40),
                dir: if rng.pct(50) { Dir::Forward } else { Dir::Backward },
            }
        }
        5 => Op::Threads {
            room,
            from: token(rng, s),
            limit: if rng.pct(30) { None } else { Some(limit(rng)) },
            participated: rng.pct(30),
        },
        6 => Op::State { room },
        7 => Op::StateEvent {
            room,
            kind: rng.pick(&[Kind::Member, Kind::HistoryVisibility, Kind::Create, Kind::Name, Kind::Encryption]),
            state_key: if rng.pct(50) { 0 } else { rng.pick(&USERS) },
        },
        8 => Op::Members {
            room,
            at: if rng.pct(50) { Token::Absent } else { token(rng, s) },
            membership: if rng.pct(30) { Some(membership(rng)) } else { None },
            not_membership: if rng.pct(30) { Some(membership(rng)) } else { None },
        },
        9 => Op::JoinedMembers { room },
        10 => Op::InitialSync { room, limit: if rng.pct(30) { None } else { Some(limit(rng)) } },
        _ => {
            if rng.pct(70) {
                Op::RoomEvent { room, event }
            } else {
                Op::ServerCanSee { origin: rng.pick(&SERVERS), room, event }
            }
        }
    };
    Request { user, op }
}
