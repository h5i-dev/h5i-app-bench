//! Loads a kernel `Snapshot` into the upstream services' columns, runs a
//! request through the copied route, and reads the reply back in kernel
//! terms.
use std::sync::Arc;

use ruma::{
    OwnedEventId, OwnedRoomId, OwnedServerName, OwnedUserId, UInt,
    api::{Direction, client as c},
    events::{StateEventType, TimelineEventType, relation::RelationType, room::member::MembershipState},
};
use serde_json::{Value, json};
use tuwunel_core::{
    Error as UpError, PduCount, PduId, RawPduId,
    config::{Config, RegexSet},
};
use tuwunel_database::Map;
use tuwunel_kernel::*;
use tuwunel_service::{OnceServices, Services, rooms::*};

pub fn user(u: u64) -> OwnedUserId {
    OwnedUserId::new(&format!("@u{}:s{}", u % 1000, server_name(u)))
}
pub fn server(s: u64) -> OwnedServerName {
    OwnedServerName::new(&format!("s{s}"))
}
pub fn room(r: u64) -> OwnedRoomId {
    OwnedRoomId::new(&format!("!r{r}:s0"))
}
pub fn event(e: u64) -> OwnedEventId {
    OwnedEventId::new(&format!("$e{e}"))
}

pub fn kind_str(k: Kind) -> String {
    match k {
        Kind::Create => "m.room.create".into(),
        Kind::Member => "m.room.member".into(),
        Kind::PowerLevels => "m.room.power_levels".into(),
        Kind::JoinRules => "m.room.join_rules".into(),
        Kind::HistoryVisibility => "m.room.history_visibility".into(),
        Kind::Encryption => "m.room.encryption".into(),
        Kind::Name => "m.room.name".into(),
        Kind::Message => "m.room.message".into(),
        Kind::Reaction => "m.reaction".into(),
        Kind::Encrypted => "m.room.encrypted".into(),
        Kind::Sticker => "m.sticker".into(),
        Kind::Redaction => "m.room.redaction".into(),
        Kind::Dummy => "org.matrix.dummy_event".into(),
        Kind::Custom(n) => format!("x.custom{n}"),
    }
}

pub fn membership_str(m: Membership) -> String {
    match m {
        Membership::Join => "join".into(),
        Membership::Invite => "invite".into(),
        Membership::Leave => "leave".into(),
        Membership::Ban => "ban".into(),
        Membership::Knock => "knock".into(),
        Membership::Custom(n) => format!("custom{n}"),
    }
}

pub fn hv_str(v: HistoryVisibility) -> String {
    match v {
        HistoryVisibility::WorldReadable => "world_readable".into(),
        HistoryVisibility::Shared => "shared".into(),
        HistoryVisibility::Invited => "invited".into(),
        HistoryVisibility::Joined => "joined".into(),
        HistoryVisibility::Custom(n) => format!("custom{n}"),
    }
}

pub fn rel_str(r: RelType) -> String {
    match r {
        RelType::Annotation => "m.annotation".into(),
        RelType::Reference => "m.reference".into(),
        RelType::Replacement => "m.replace".into(),
        RelType::Thread => "m.thread".into(),
        RelType::Custom(n) => format!("x.rel{n}"),
    }
}

pub fn state_key_str(k: u64) -> String {
    if k == 0 { String::new() } else { user(k).to_string() }
}

/// The short state key of `(kind, state_key)`: entries of a kernel state
/// set are kept in this order.
pub fn shortstatekey(k: Kind, key: u64) -> u64 {
    let c = match k {
        Kind::Create => 1,
        Kind::Member => 2,
        Kind::PowerLevels => 3,
        Kind::JoinRules => 4,
        Kind::HistoryVisibility => 5,
        Kind::Encryption => 6,
        Kind::Name => 7,
        Kind::Message => 8,
        Kind::Reaction => 9,
        Kind::Encrypted => 10,
        Kind::Sticker => 11,
        Kind::Redaction => 12,
        Kind::Dummy => 13,
        Kind::Custom(n) => 100 + n,
    };
    (c << 32) | key
}

pub fn pdu_json(p: &Pdu) -> Value {
    let mut content = serde_json::Map::new();
    if let MemberField::Is(m) = p.membership {
        content.insert("membership".into(), json!(membership_str(m)));
    }
    if let HvField::Is(v) = p.history_visibility {
        content.insert("history_visibility".into(), json!(hv_str(v)));
    }
    if let Relates::To(r, e) = p.relates_to {
        content.insert("m.relates_to".into(), json!({ "rel_type": rel_str(r), "event_id": event(e).to_string() }));
    }
    if p.has_url {
        content.insert("url".into(), json!("mxc://s1/x"));
    }
    let mut j = json!({
        "type": kind_str(p.kind),
        "content": content,
        "event_id": event(p.event_id).to_string(),
        "room_id": room(p.room).to_string(),
        "sender": user(p.sender).to_string(),
        "origin_server_ts": 0,
    });
    if p.has_state_key {
        j["state_key"] = json!(state_key_str(p.state_key));
    }
    j
}

fn short_of(s: &Snapshot, r: u64) -> Option<u64> {
    s.rooms.iter().find(|x| x.id == r).map(|x| x.short)
}

fn raw(short: u64, count: i64) -> RawPduId {
    PduId { shortroomid: short, count: PduCount::from_signed(count) }.into()
}

fn be(n: u64) -> Vec<u8> {
    n.to_be_bytes().to_vec()
}

fn svc() -> Arc<OnceServices> {
    Arc::new(OnceServices::default())
}

/// The upstream services holding `s`.
pub fn services(s: &Snapshot) -> Arc<Services> {
    let once = svc();
    let mut pduid_pdu = Map::default();
    let mut meta_pduid_pdu = Map::default();
    let mut eventid_pduid = Map::default();
    let mut eventid_outlierpdu = Map::default();
    let mut short = short::Service::default();
    let mut state_db = state::Data::default();
    for (i, p) in s.pdus.iter().enumerate() {
        let json = serde_json::to_vec(&pdu_json(p)).unwrap();
        let e = event(p.event_id);
        let sid = 1000 + i as u64;
        short.db.eventid_shorteventid.insert(&*e, be(sid));
        short.db.shorteventid_eventid.insert(&sid, e.as_bytes().to_vec());
        if let StateRef::Hash(h) = p.state {
            state_db.shorteventid_shortstatehash.insert(&sid, be(h));
        }
        if p.outlier {
            eventid_outlierpdu.insert(&*e, json);
        } else if let Some(short) = short_of(s, p.room) {
            let id = raw(short, p.count);
            pduid_pdu.insert(&id, json.clone());
            meta_pduid_pdu.insert(&id, json);
            eventid_pduid.insert(&*e, id.as_bytes().to_vec());
        }
    }
    let shortevent = |e: u64| -> u64 {
        match s.pdus.iter().position(|p| p.event_id == e) {
            Some(i) => 1000 + i as u64,
            None => 900_000 + e,
        }
    };
    let mut compressor = state_compressor::Service::default();
    for st in &s.states {
        let mut set = std::collections::BTreeSet::new();
        for en in &st.entries {
            let ssk = shortstatekey(en.kind, en.state_key);
            set.insert(state_compressor::compress_state_event(ssk, shortevent(en.event_id)));
            let key = format!("{}\u{ff}{}", kind_str(en.kind), state_key_str(en.state_key));
            let mut kb = kind_str(en.kind).into_bytes();
            kb.push(0xFF);
            kb.extend_from_slice(state_key_str(en.state_key).as_bytes());
            let _ = key;
            short.db.statekey_shortstatekey.data.insert(kb.clone(), be(ssk));
            short.db.shortstatekey_statekey.insert(&ssk, kb);
        }
        compressor.snapshots.insert(st.hash, Arc::new(set));
    }
    for r in &s.rooms {
        short.db.roomid_shortroomid.insert(&*room(r.id), be(r.short));
        if let StateRef::Hash(h) = r.state {
            state_db.roomid_shortstatehash.insert(&*room(r.id), be(h));
        }
    }
    let mut cache = state_cache::Data::default();
    for x in &s.joined {
        cache.userroomid_joinedcount.insert(&(&*user(x.user), &*room(x.room)), be(0));
        cache.roomuserid_joinedcount.insert(&(&*room(x.room), &*user(x.user)), be(0));
    }
    for x in &s.invited {
        cache.userroomid_invitestate.insert(&(&*user(x.user), &*room(x.room)), b"[]".to_vec());
    }
    for x in &s.knocked {
        cache.userroomid_knockedstate.insert(&(&*user(x.user), &*room(x.room)), b"[]".to_vec());
    }
    for x in &s.left {
        cache.userroomid_leftstate.insert(&(&*user(x.user), &*room(x.room)), b"[]".to_vec());
        cache.roomuserid_leftcount.insert(&(&*room(x.room), &*user(x.user)), be(x.count));
    }
    for x in &s.once_joined {
        cache.roomuseroncejoinedids.insert(&(&*user(x.user), &*room(x.room)), Vec::new());
    }
    let mut rel = pdu_metadata::Data::default();
    for r in &s.relations {
        let mut k = be(r.to);
        k.extend(be(r.from));
        rel.tofrom_relation.data.insert(k, Vec::new());
    }
    let mut th = threads::Data::default();
    for a in &s.thread_activity {
        th.threadactivityid_rootid
            .insert(&raw(a.room_short, a.count as i64), raw(a.room_short, a.root as i64).as_bytes().to_vec());
    }
    for l in &s.thread_latest {
        th.threadrootid_latestcount.insert(&raw(l.room_short, l.root as i64), be(l.latest));
    }
    for t in &s.thread_participants {
        let users: Vec<Vec<u8>> = t.users.iter().map(|u| user(*u).as_bytes().to_vec()).collect();
        th.threadid_userids.insert(&raw(t.room_short, t.root as i64), users.join(&[0xFF][..]));
    }
    let mut account_data = tuwunel_service::account_data::Service::default();
    let mut lists: std::collections::BTreeMap<u64, Vec<u64>> = Default::default();
    for i in &s.ignored {
        lists.entry(i.user).or_default().push(i.ignored);
    }
    for (u, l) in lists {
        let m: serde_json::Map<String, Value> = l.iter().map(|x| (user(*x).to_string(), json!({}))).collect();
        account_data
            .global
            .insert((user(u), "m.ignored_user_list".into()), json!({ "content": { "ignored_users": m } }));
    }
    let hosts = |v: &[u64]| RegexSet(v.iter().map(|x| server(*x).to_string()).collect());
    let services = Arc::new(Services {
        config: Config {
            server_name: server(s.config.server_name),
            forbidden_remote_server_names: hosts(&s.config.forbidden_remote_server_names),
            allowed_remote_server_names_experimental: hosts(&s.config.allowed_remote_server_names),
            fetch_unreceived_contexts_over_federation: false,
            allow_federation: false,
            allow_room_admins_to_request_unredacted_events: false,
        },
        globals: tuwunel_service::globals::Service { count: s.current_count as u64 },
        account_data,
        admin: tuwunel_service::admin::Service,
        users: tuwunel_service::users::Service { services: once.clone() },
        metadata: metadata::Service { db: metadata::Data { pduid_pdu: meta_pduid_pdu }, services: once.clone() },
        short,
        state: state::Service { db: state_db, services: once.clone() },
        state_accessor: state_accessor::Service { services: once.clone() },
        state_cache: state_cache::Service { db: cache, services: once.clone() },
        state_compressor: compressor,
        timeline: timeline::Service {
            db: timeline::Data { pduid_pdu, eventid_pduid, eventid_outlierpdu },
            services: once.clone(),
        },
        pdu_metadata: pdu_metadata::Service { db: rel, services: once.clone() },
        threads: threads::Service { db: th, services: once.clone() },
        lazy_loading: lazy_loading::Service,
        read_receipt: read_receipt::Service,
        directory: directory::Service,
        retention: retention::Service,
    });
    once.set(&services);
    services
}

fn token(t: Token) -> Option<String> {
    match t {
        Token::Absent => None,
        Token::At(c) => Some(c.to_string()),
        Token::Invalid => Some("x1".into()),
    }
}

fn dir(d: Dir) -> Direction {
    match d {
        Dir::Forward => Direction::Forward,
        Dir::Backward => Direction::Backward,
    }
}

fn uint(n: u64) -> UInt {
    UInt::new(n).expect("small limit")
}

pub fn filter(f: &Filter) -> c::filter::RoomEventFilter {
    c::filter::RoomEventFilter {
        not_types: f.not_types.iter().map(|k| kind_str(*k)).collect(),
        types: f.types.as_ref().map(|v| v.iter().map(|k| kind_str(*k)).collect()),
        not_rooms: f.not_rooms.iter().map(|r| room(*r)).collect(),
        rooms: f.rooms.as_ref().map(|v| v.iter().map(|r| room(*r)).collect()),
        not_senders: f.not_senders.iter().map(|u| user(*u)).collect(),
        senders: f.senders.as_ref().map(|v| v.iter().map(|u| user(*u)).collect()),
        url_filter: match f.url_filter {
            UrlFilter::Any => None,
            UrlFilter::WithUrl => Some(c::filter::UrlFilter::EventsWithUrl),
            UrlFilter::WithoutUrl => Some(c::filter::UrlFilter::EventsWithoutUrl),
        },
        lazy_load_options: Default::default(),
        related_by_senders: f.related_by_senders.iter().map(|u| user(*u)).collect(),
        related_by_rel_types: f.related_by_rel_types.iter().map(|r| rel_str(*r)).collect(),
    }
}

fn error(e: UpError) -> Error {
    match e {
        UpError::Request("Forbidden") => Error::Forbidden,
        UpError::Request("NotFound") => Error::NotFound,
        UpError::Request("InvalidParam") => Error::InvalidParam,
        UpError::HttpJson("NOT_FOUND") => Error::SenderIgnored,
        UpError::Database => Error::Database,
        UpError::Parse => Error::Parse,
        e => panic!("unmapped upstream error {e:?}"),
    }
}

fn event_num(id: &str) -> u64 {
    id.strip_prefix("$e").and_then(|x| x.parse().ok()).expect("event id")
}

fn ids<T>(v: Vec<ruma::serde::Raw<T>>) -> Vec<u64> {
    v.into_iter().map(|r| event_num(r.json["event_id"].as_str().unwrap())).collect()
}

fn count(s: &str) -> i64 {
    s.parse().expect("count token")
}

fn opt_count(s: Option<String>) -> Option<i64> {
    s.map(|x| count(&x))
}

fn user_num(u: &ruma::UserId) -> u64 {
    let s = u.as_str();
    let (l, r) = s[2..].split_once(":s").unwrap();
    r.parse::<u64>().unwrap() * 1000 + l.parse::<u64>().unwrap()
}

fn membership(m: &MembershipState) -> Membership {
    match m {
        MembershipState::Join => Membership::Join,
        MembershipState::Invite => Membership::Invite,
        MembershipState::Leave => Membership::Leave,
        MembershipState::Ban => Membership::Ban,
        MembershipState::Knock => Membership::Knock,
        MembershipState::_Custom(s) => Membership::Custom(s.strip_prefix("custom").unwrap().parse().unwrap()),
    }
}

fn membership_up(m: Membership) -> MembershipState {
    MembershipState::from(membership_str(m).as_str())
}

/// Runs `req` through the copied route.
pub fn upstream(s: &Snapshot, req: &Request) -> Result<Reply, Error> {
    let sv = services(s);
    let u = user(req.user);
    futures::executor::block_on(run(sv, &u, &req.op))
}

async fn run(sv: Arc<Services>, u: &ruma::UserId, op: &Op) -> Result<Reply, Error> {
    use tuwunel_api as api;
    match op {
        Op::Messages { room: r, from, to, dir: d, limit, filter: f } => {
            let b = c::message::get_message_events::v3::Request {
                room_id: room(*r),
                from: token(*from),
                to: token(*to),
                dir: dir(*d),
                limit: uint(*limit),
                filter: filter(f),
            };
            let x = api::messages(sv, u, b).await.map_err(error)?;
            assert!(x.state.is_empty());
            Ok(Reply::Messages { start: count(&x.start), end: opt_count(x.end), chunk: ids(x.chunk) })
        }
        Op::Context { room: r, event: e, limit, filter: f } => {
            let b = c::context::get_context::v3::Request { room_id: room(*r), event_id: event(*e), limit: uint(*limit), filter: filter(f) };
            let x = api::context(sv, u, b).await.map_err(error)?;
            let ev = x.event.expect("base event");
            Ok(Reply::Context {
                event: event_num(ev.json["event_id"].as_str().unwrap()),
                start: count(&x.start.unwrap()),
                end: count(&x.end.unwrap()),
                events_before: ids(x.events_before),
                events_after: ids(x.events_after),
                state: ids(x.state),
            })
        }
        Op::Relations { room: r, event: e, rel_type, event_type, from, to, limit, recurse, dir: d } => {
            let (room_id, event_id, from, to, limit, recurse, dir) =
                (room(*r), event(*e), token(*from), token(*to), limit.map(uint), *recurse, dir(*d));
            let x = match (rel_type, event_type) {
                (None, None) => {
                    let b = c::relations::get_relating_events::v1::Request { room_id, event_id, from, to, limit, recurse, dir };
                    api::relations(sv, u, b).await
                }
                (Some(rt), None) => {
                    let b = c::relations::get_relating_events_with_rel_type::v1::Request {
                        room_id,
                        event_id,
                        rel_type: RelationType::from(rel_str(*rt).as_str()),
                        from,
                        to,
                        limit,
                        recurse,
                        dir,
                    };
                    api::relations_with_rel_type(sv, u, b).await.map(|x| c::relations::get_relating_events::v1::Response {
                        chunk: x.chunk,
                        next_batch: x.next_batch,
                        prev_batch: x.prev_batch,
                        recursion_depth: x.recursion_depth,
                    })
                }
                (Some(rt), Some(k)) => {
                    let b = c::relations::get_relating_events_with_rel_type_and_event_type::v1::Request {
                        room_id,
                        event_id,
                        rel_type: RelationType::from(rel_str(*rt).as_str()),
                        event_type: TimelineEventType::from(kind_str(*k).as_str()),
                        from,
                        to,
                        limit,
                        recurse,
                        dir,
                    };
                    api::relations_with_rel_type_and_event_type(sv, u, b).await.map(|x| {
                        c::relations::get_relating_events::v1::Response {
                            chunk: x.chunk,
                            next_batch: x.next_batch,
                            prev_batch: x.prev_batch,
                            recursion_depth: x.recursion_depth,
                        }
                    })
                }
                (None, Some(_)) => panic!("no route takes an event type without a relation type"),
            };
            let x = x.map_err(error)?;
            Ok(Reply::Relations {
                chunk: ids(x.chunk),
                next_batch: opt_count(x.next_batch),
                prev_batch: opt_count(x.prev_batch),
                recursion_depth: x.recursion_depth.map(u64::from),
            })
        }
        Op::Threads { room: r, from, limit, participated } => {
            let b = c::threads::get_threads::v1::Request {
                room_id: room(*r),
                from: token(*from),
                limit: limit.map(uint),
                include: if *participated {
                    c::threads::get_threads::v1::IncludeThreads::Participated
                } else {
                    c::threads::get_threads::v1::IncludeThreads::All
                },
            };
            let x = api::threads(sv, u, b).await.map_err(error)?;
            Ok(Reply::Threads { chunk: ids(x.chunk), next_batch: opt_count(x.next_batch) })
        }
        Op::State { room: r } => {
            let x = api::state_events(sv, u, c::state::get_state_events::v3::Request { room_id: room(*r) }).await.map_err(error)?;
            Ok(Reply::State { events: ids(x.room_state) })
        }
        Op::StateEvent { room: r, kind, state_key } => {
            let b = c::state::get_state_event_for_key::v3::Request {
                room_id: room(*r),
                event_type: StateEventType::from(kind_str(*kind).as_str()),
                state_key: state_key_str(*state_key),
                format: c::state::get_state_event_for_key::v3::StateEventFormat::Event,
            };
            let x = api::state_event_for_key(sv, u, b).await.map_err(error)?;
            let v: Value = serde_json::from_str(x.event_or_content.get()).unwrap();
            Ok(Reply::StateEvent { event: event_num(v["event_id"].as_str().unwrap()) })
        }
        Op::Members { room: r, at, membership: m, not_membership: n } => {
            let b = c::membership::get_member_events::v3::Request {
                room_id: room(*r),
                at: token(*at),
                membership: m.map(membership_up),
                not_membership: n.map(membership_up),
            };
            let x = api::members(sv, u, b).await.map_err(error)?;
            Ok(Reply::Members { chunk: ids(x.chunk) })
        }
        Op::JoinedMembers { room: r } => {
            let x = api::joined_members(sv, u, c::membership::joined_members::v3::Request { room_id: room(*r) })
                .await
                .map_err(error)?;
            Ok(Reply::JoinedMembers { joined: x.joined.keys().map(|k| user_num(k)).collect() })
        }
        Op::InitialSync { room: r, limit } => {
            let b = c::room::initial_sync::v3::Request { room_id: room(*r), limit: limit.map(|l| l as usize) };
            let x = api::initial_sync(sv, u, b).await.map_err(error)?;
            let m = x.messages.unwrap();
            Ok(Reply::InitialSync {
                membership: x.membership.as_ref().map(membership),
                state: ids(x.state.unwrap()),
                chunk: ids(m.chunk),
                start: opt_count(m.start),
                end: count(&m.end),
            })
        }
        Op::RoomEvent { room: r, event: e } => {
            let b = c::room::get_room_event::v3::Request { room_id: room(*r), event_id: event(*e), include_unredacted_content: false };
            let x = api::room_event(sv, u, b).await.map_err(error)?;
            Ok(Reply::RoomEvent { event: event_num(x.event.json["event_id"].as_str().unwrap()) })
        }
        Op::ServerCanSee { origin, room: r, event: e } => {
            let ok = sv.state_accessor.server_can_see_event(&server(*origin), &room(*r), &event(*e)).await;
            Ok(Reply::CanSee(ok))
        }
    }
}
