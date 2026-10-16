//! Who may see what in a tuwunel room (matrix-construct/tuwunel @ 7801b8e)
//! in the Aeneas subset: the history-visibility checks of
//! `service/rooms/state_accessor`, the state-cache, timeline, relation and
//! thread reads they sit on, and the client endpoints that apply them
//! (`/messages`, `/context`, `/relations`, `/threads`, state reads, members,
//! `initialSync`, `/event`). Each function follows the upstream function of
//! the same name, in upstream's order; ../DEVIATIONS.md lists the deviations.
//!
//! A request runs against a `Snapshot` of the database: the rooms, every PDU
//! (timeline events with their count, and outliers), the state snapshots,
//! the state-cache membership indexes, the relation and thread indexes, the
//! ignore lists and the server name configuration. The reply carries event
//! ids and pagination tokens; the presentation of events (`unsigned`, bundled
//! aggregations, lazy loading) is not modeled.

pub mod svc_cache;
pub mod svc_timeline;
pub mod svc_accessor;
pub mod svc_relations;
pub mod svc_threads;
pub mod filters;
pub mod api_message;
pub mod api_context;
pub mod api_relations;
pub mod api_threads;
pub mod api_state;
pub mod api_members;
pub mod api_room;

/// `PduCount` in its signed form (`into_signed`): positive values are
/// `Normal`, zero and below `Backfilled`. Ordering is that of `PduCount`.
pub type Count = i64;

/// `PduCount::max()`.
pub const COUNT_MAX: i64 = i64::MAX;
/// `PduCount::min()`.
pub const COUNT_MIN: i64 = i64::MIN;

/// `TimelineEventType` / `StateEventType`. `Custom(n)` is `x.custom{n}`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Kind {
    Create,
    Member,
    PowerLevels,
    JoinRules,
    HistoryVisibility,
    Encryption,
    Name,
    Message,
    Reaction,
    Encrypted,
    Sticker,
    Redaction,
    /// `org.matrix.dummy_event`.
    Dummy,
    Custom(u64),
}

pub fn kind_eq(a: Kind, b: Kind) -> bool {
    match a {
        Kind::Create => matches!(b, Kind::Create),
        Kind::Member => matches!(b, Kind::Member),
        Kind::PowerLevels => matches!(b, Kind::PowerLevels),
        Kind::JoinRules => matches!(b, Kind::JoinRules),
        Kind::HistoryVisibility => matches!(b, Kind::HistoryVisibility),
        Kind::Encryption => matches!(b, Kind::Encryption),
        Kind::Name => matches!(b, Kind::Name),
        Kind::Message => matches!(b, Kind::Message),
        Kind::Reaction => matches!(b, Kind::Reaction),
        Kind::Encrypted => matches!(b, Kind::Encrypted),
        Kind::Sticker => matches!(b, Kind::Sticker),
        Kind::Redaction => matches!(b, Kind::Redaction),
        Kind::Dummy => matches!(b, Kind::Dummy),
        Kind::Custom(x) => match b {
            Kind::Custom(y) => x == y,
            _ => false,
        },
    }
}

/// `MembershipState`. `Custom(n)` is an unknown string.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Membership {
    Join,
    Invite,
    Leave,
    Ban,
    Knock,
    Custom(u64),
}

pub fn membership_eq(a: Membership, b: Membership) -> bool {
    match a {
        Membership::Join => matches!(b, Membership::Join),
        Membership::Invite => matches!(b, Membership::Invite),
        Membership::Leave => matches!(b, Membership::Leave),
        Membership::Ban => matches!(b, Membership::Ban),
        Membership::Knock => matches!(b, Membership::Knock),
        Membership::Custom(x) => match b {
            Membership::Custom(y) => x == y,
            _ => false,
        },
    }
}

/// `content.membership`: `Absent` when the content does not deserialize as
/// `RoomMemberEventContent`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum MemberField {
    Absent,
    Is(Membership),
}

/// `HistoryVisibility`. `Custom(n)` is an unknown string.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum HistoryVisibility {
    WorldReadable,
    Shared,
    Invited,
    Joined,
    Custom(u64),
}

/// `content.history_visibility`: `Absent` when the content does not
/// deserialize as `RoomHistoryVisibilityEventContent`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum HvField {
    Absent,
    Is(HistoryVisibility),
}

/// `RelationType`. `Custom(n)` is an unknown string.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RelType {
    Annotation,
    Reference,
    Replacement,
    Thread,
    Custom(u64),
}

pub fn rel_type_eq(a: RelType, b: RelType) -> bool {
    match a {
        RelType::Annotation => matches!(b, RelType::Annotation),
        RelType::Reference => matches!(b, RelType::Reference),
        RelType::Replacement => matches!(b, RelType::Replacement),
        RelType::Thread => matches!(b, RelType::Thread),
        RelType::Custom(x) => match b {
            RelType::Custom(y) => x == y,
            _ => false,
        },
    }
}

/// `content["m.relates_to"]` with its `rel_type` and `event_id`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Relates {
    None,
    To(RelType, u64),
}

/// A short state hash, or none recorded.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum StateRef {
    None,
    Hash(u64),
}

/// A PDU (`PduEvent`) with the fields the ported code reads. User ids are
/// numbers whose server is `server_name`; state key `0` is the empty
/// string, any other the user id with that number.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Pdu {
    pub event_id: u64,
    pub room: u64,
    pub sender: u64,
    pub kind: Kind,
    pub has_state_key: bool,
    pub state_key: u64,
    pub membership: MemberField,
    pub history_visibility: HvField,
    pub relates_to: Relates,
    /// `content.url` is a string.
    pub has_url: bool,
    /// Stored in `eventid_outlierpdu`, not in the timeline.
    pub outlier: bool,
    /// The timeline count (`pduid_pdu` key); unused for outliers.
    pub count: i64,
    /// `shorteventid_shortstatehash`: the state before the event.
    pub state: StateRef,
}

/// `@u:s` has server `s`: user number `u` has server `u / 1000`.
pub fn server_name(user: u64) -> u64 {
    user / 1000
}

/// A room: `roomid_shortroomid` and `roomid_shortstatehash`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Room {
    pub id: u64,
    pub short: u64,
    pub state: StateRef,
}

/// One state entry: `(event type, state key)` and the event.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct StateEntry {
    pub kind: Kind,
    pub state_key: u64,
    pub event_id: u64,
}

/// A state snapshot: the full state of `load_full_state`, in short state
/// key order.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct StateSet {
    pub hash: u64,
    pub entries: Vec<StateEntry>,
}

/// A `(user, room)` row of a state-cache index.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct UserRoom {
    pub user: u64,
    pub room: u64,
}

/// `userroomid_leftstate` with `roomuserid_leftcount`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct LeftRow {
    pub user: u64,
    pub room: u64,
    pub count: u64,
}

/// A `tofrom_relation` key: `[to, from]` counts.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Relation {
    pub to: u64,
    pub from: u64,
}

/// A `threadactivityid_rootid` row: `(shortroomid, count)` to the root's
/// count in the same room.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ThreadActivity {
    pub room_short: u64,
    pub count: u64,
    pub root: u64,
}

/// A `threadrootid_latestcount` row.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ThreadLatest {
    pub room_short: u64,
    pub root: u64,
    pub latest: u64,
}

/// A `threadid_userids` row.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ThreadParticipants {
    pub room_short: u64,
    pub root: u64,
    pub users: Vec<u64>,
}

/// `user` ignores `ignored` (`m.ignored_user_list`).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Ignore {
    pub user: u64,
    pub ignored: u64,
}

/// The configuration the ported code reads. The two server name lists are
/// exact names (upstream: regex sets).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Config {
    pub server_name: u64,
    pub forbidden_remote_server_names: Vec<u64>,
    pub allowed_remote_server_names: Vec<u64>,
}

/// The database, as the ported code reads it. Tables keyed by bytes upstream
/// are kept in key order: `pdus` by count, `relations` by `(to, from)`,
/// `thread_activity` by `(room_short, count)`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Snapshot {
    pub rooms: Vec<Room>,
    pub pdus: Vec<Pdu>,
    pub states: Vec<StateSet>,
    /// `userroomid_joinedcount`.
    pub joined: Vec<UserRoom>,
    /// `userroomid_invitestate`.
    pub invited: Vec<UserRoom>,
    /// `userroomid_knockedstate`.
    pub knocked: Vec<UserRoom>,
    pub left: Vec<LeftRow>,
    /// `roomuseroncejoinedids`.
    pub once_joined: Vec<UserRoom>,
    pub relations: Vec<Relation>,
    pub thread_activity: Vec<ThreadActivity>,
    pub thread_latest: Vec<ThreadLatest>,
    pub thread_participants: Vec<ThreadParticipants>,
    pub ignored: Vec<Ignore>,
    pub config: Config,
    /// `globals.current_count()`.
    pub current_count: i64,
}

/// A pagination token: absent, a parsed `PduCount`, or a string that does
/// not parse.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Token {
    Absent,
    At(i64),
    Invalid,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Dir {
    Forward,
    Backward,
}

/// `filter.url_filter`.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum UrlFilter {
    Any,
    WithUrl,
    WithoutUrl,
}

/// `RoomEventFilter`, without `limit` and lazy loading (disabled).
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Filter {
    pub senders: Option<Vec<u64>>,
    pub not_senders: Vec<u64>,
    pub types: Option<Vec<Kind>>,
    pub not_types: Vec<Kind>,
    pub rooms: Option<Vec<u64>>,
    pub not_rooms: Vec<u64>,
    pub url_filter: UrlFilter,
    pub related_by_senders: Vec<u64>,
    pub related_by_rel_types: Vec<RelType>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Op {
    /// `GET /rooms/{room}/messages`; the route always passes a limit.
    Messages { room: u64, from: Token, to: Token, dir: Dir, limit: u64, filter: Filter },
    /// `GET /rooms/{room}/context/{event}`.
    Context { room: u64, event: u64, limit: u64, filter: Filter },
    /// `GET /rooms/{room}/relations/{event}[/{rel_type}[/{event_type}]]`.
    Relations {
        room: u64,
        event: u64,
        rel_type: Option<RelType>,
        event_type: Option<Kind>,
        from: Token,
        to: Token,
        limit: Option<u64>,
        recurse: bool,
        dir: Dir,
    },
    /// `GET /rooms/{room}/threads`.
    Threads { room: u64, from: Token, limit: Option<u64>, participated: bool },
    /// `GET /rooms/{room}/state`.
    State { room: u64 },
    /// `GET /rooms/{room}/state/{kind}/{state_key}`.
    StateEvent { room: u64, kind: Kind, state_key: u64 },
    /// `GET /rooms/{room}/members`.
    Members { room: u64, at: Token, membership: Option<Membership>, not_membership: Option<Membership> },
    /// `GET /rooms/{room}/joined_members`.
    JoinedMembers { room: u64 },
    /// `GET /rooms/{room}/initialSync`.
    InitialSync { room: u64, limit: Option<u64> },
    /// `GET /rooms/{room}/event/{event}`.
    RoomEvent { room: u64, event: u64 },
    /// Federation: `server_can_see_event`.
    ServerCanSee { origin: u64, room: u64, event: u64 },
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Request {
    pub user: u64,
    pub op: Op,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Reply {
    Messages { start: i64, end: Option<i64>, chunk: Vec<u64> },
    Context {
        event: u64,
        start: i64,
        end: i64,
        events_before: Vec<u64>,
        events_after: Vec<u64>,
        state: Vec<u64>,
    },
    Relations { chunk: Vec<u64>, next_batch: Option<i64>, prev_batch: Option<i64>, recursion_depth: Option<u64> },
    Threads { chunk: Vec<u64>, next_batch: Option<i64> },
    State { events: Vec<u64> },
    StateEvent { event: u64 },
    Members { chunk: Vec<u64> },
    /// The member event senders, in state order (upstream: a map by user id).
    JoinedMembers { joined: Vec<u64> },
    InitialSync { membership: Option<Membership>, state: Vec<u64>, chunk: Vec<u64>, start: Option<i64>, end: i64 },
    RoomEvent { event: u64 },
    CanSee(bool),
}

/// Upstream's error kinds: `Request(Forbidden | NotFound | InvalidParam)`,
/// the `M_SENDER_IGNORED` reply, `Database`, and a token or content that
/// fails to parse.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    Forbidden,
    NotFound,
    InvalidParam,
    SenderIgnored,
    Database,
    Parse,
}

/// Runs one request.
pub fn transition(s: &Snapshot, req: &Request) -> Result<Reply, Error> {
    let user = req.user;
    match &req.op {
        Op::Messages { room, from, to, dir, limit, filter } => {
            api_message::get_message_events_route(s, user, *room, *from, *to, *dir, *limit, filter)
        }
        Op::Context { room, event, limit, filter } => {
            api_context::get_context_route(s, user, *room, *event, *limit, filter)
        }
        Op::Relations { room, event, rel_type, event_type, from, to, limit, recurse, dir } => {
            api_relations::paginate_relations_with_filter(
                s, user, *room, *event, *event_type, *rel_type, *from, *to, *limit, *recurse, *dir,
            )
        }
        Op::Threads { room, from, limit, participated } => {
            api_threads::get_threads_route(s, user, *room, *from, *limit, *participated)
        }
        Op::State { room } => api_state::get_state_events_route(s, user, *room),
        Op::StateEvent { room, kind, state_key } => {
            api_state::get_state_events_for_key_route(s, user, *room, *kind, *state_key)
        }
        Op::Members { room, at, membership, not_membership } => {
            api_members::get_member_events_route(s, user, *room, *at, *membership, *not_membership)
        }
        Op::JoinedMembers { room } => api_members::joined_members_route(s, user, *room),
        Op::InitialSync { room, limit } => api_room::room_initial_sync_route(s, user, *room, *limit),
        Op::RoomEvent { room, event } => api_room::get_room_event_route(s, user, *room, *event),
        Op::ServerCanSee { origin, room, event } => {
            Ok(Reply::CanSee(svc_accessor::server_can_see_event(s, *origin, *room, *event)))
        }
    }
}

pub fn contains_u64(v: &[u64], x: u64) -> bool {
    let mut i = 0;
    while i < v.len() {
        if v[i] == x {
            return true;
        }
        i += 1;
    }
    false
}
