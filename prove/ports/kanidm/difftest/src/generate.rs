//! Random inputs, built as kernel values, and their translation to
//! kanidm's own types.
use kanidm_kernel as k;
use kanidm_kernel::profiles as kp;
use kanidmd_lib::entry as ue;
use kanidmd_lib::filter::{DFilter, Filter};
use kanidmd_lib::modify as um;
use kanidmd_lib::server::access::profiles as up;
use kanidmd_lib::server::identity as ui;
use kanidmd_lib::value as uv;
use kanidmd_lib::valueset as uvs;
use kanidm_proto::attribute::Attribute;
use std::collections::{BTreeMap, BTreeSet};
use std::sync::Arc;
use uuid::Uuid;

pub struct Rng(pub u64);

impl Rng {
    pub fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9e3779b97f4a7c15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xbf58476d1ce4e5b9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94d049bb133111eb);
        z ^ (z >> 31)
    }
    pub fn below(&mut self, n: u64) -> u64 {
        self.next() % n
    }
    pub fn chance(&mut self, pct: u64) -> bool {
        self.below(100) < pct
    }
    pub fn pick<T: Copy>(&mut self, xs: &[T]) -> T {
        xs[self.below(xs.len() as u64) as usize]
    }
}

pub const ANON: u128 = 0xffffffffffff;
pub const GROUPS: &[u128] = &[0x1_0000_0000_0001, 0x1_0000_0000_0002, 0x1_0000_0000_0003, 0x1_0000_0000_0004];
pub const USERS: &[u128] = &[0x3_0000_0000_0001, 0x3_0000_0000_0002, ANON];
pub const ENTRIES: &[u128] = &[
    0xffffff000001, 0xffffff000123, ANON, 0x2_0000_0000_0001, 0x2_0000_0000_0002, 0x2_0000_0000_0003,
    0x2_0000_0000_0004, 0x2_0000_0000_0005, 0x3_0000_0000_0001, 0x1_0000_0000_0001,
];
pub const SYNC_ACCOUNTS: &[u128] = &[0x2_0000_0000_0001, 0x2_0000_0000_0002];

#[derive(Clone, Copy, PartialEq)]
pub enum Syn {
    Iutf8,
    Iname,
    Utf8,
    Uuid,
    Refer,
    Uint32,
    Scope,
}

pub const ATTRS: &[(&str, Syn)] = &[
    ("class", Syn::Iutf8),
    ("uuid", Syn::Uuid),
    ("name", Syn::Iname),
    ("displayname", Syn::Utf8),
    ("description", Syn::Utf8),
    ("mail", Syn::Utf8),
    ("memberof", Syn::Refer),
    ("member", Syn::Refer),
    ("entry_managed_by", Syn::Refer),
    ("sync_parent_uuid", Syn::Refer),
    ("linked_group", Syn::Refer),
    ("oauth2_rs_scope_map", Syn::Scope),
    ("oauth2_rs_origin_landing", Syn::Utf8),
    ("image", Syn::Utf8),
    ("sync_credential_portal", Syn::Utf8),
    ("gidnumber", Syn::Uint32),
    ("user_auth_token_session", Syn::Utf8),
    ("oauth2_session", Syn::Utf8),
    ("account_expire", Syn::Utf8),
    ("may", Syn::Iutf8),
    ("enabled", Syn::Utf8),
    ("legalname", Syn::Utf8),
    ("domain_display_name", Syn::Utf8),
    ("badlist_password", Syn::Utf8),
    ("delete_after", Syn::Utf8),
    ("mail_destination", Syn::Utf8),
    ("authsession_expiry", Syn::Utf8),
    ("credential_update_intent_token", Syn::Utf8),
    ("x_custom", Syn::Utf8),
];

pub const CLASSES: &[&str] = &[
    "object", "account", "person", "group", "dyngroup", "system", "domain_info", "system_info",
    "system_config", "sync_object", "tombstone", "recycled", "service_account", "oauth2_resource_server",
    "oauth2_resource_server_basic", "application", "sync_account", "classtype", "feature",
    "outbound_message", "account_signup_request", "posixaccount", "posixgroup", "account_policy",
    "memberof", "key_object", "key_object_internal", "memorial",
];

/// Class sets that reach the rarer branches.
pub const CLASS_SETS: &[&[&str]] = &[
    &["object", "account", "person"],
    &["object", "group"],
    &["object", "group", "posixgroup", "memberof"],
    &["object", "account", "service_account"],
    &["object", "oauth2_resource_server", "oauth2_resource_server_basic", "key_object"],
    &["object", "application"],
    &["object", "sync_account"],
    &["object", "sync_object", "account", "person"],
    &["object", "domain_info", "system"],
    &["object", "dyngroup", "group"],
    &["object", "recycled", "person"],
    &["object", "tombstone"],
    &["object", "classtype"],
    &["object", "feature"],
    &["object", "system_config"],
    &["object", "outbound_message"],
    &["object", "account_signup_request"],
    &["object", "account_policy", "group"],
];

const UTF8: &[&str] = &["Alice", "alice", "bob", "ALI", "li", "", "Bo"];
const IUTF8: &[&str] = &["object", "group", "person", "abc", "ab", ""];
const INAME: &[&str] = &["alice", "bob", "admin", "al", ""];

pub fn b(s: &str) -> Vec<u8> {
    s.as_bytes().to_vec()
}

fn dedup<T: PartialEq>(v: Vec<T>) -> Vec<T> {
    let mut out = Vec::new();
    for x in v {
        if !out.contains(&x) {
            out.push(x);
        }
    }
    out
}

fn some_uuids(r: &mut Rng, pool: &[u128], max: u64) -> Vec<u128> {
    dedup((0..1 + r.below(max)).map(|_| r.pick(pool)).collect())
}

fn any_uuid(r: &mut Rng) -> u128 {
    match r.below(3) {
        0 => r.pick(GROUPS),
        1 => r.pick(USERS),
        _ => r.pick(ENTRIES),
    }
}

pub fn value_of(r: &mut Rng, syn: Syn) -> k::PartialValue {
    match syn {
        Syn::Iutf8 => {
            if r.chance(70) {
                k::PartialValue::Iutf8(b(r.pick(CLASSES)))
            } else {
                k::PartialValue::Iutf8(b(r.pick(IUTF8)))
            }
        }
        Syn::Iname => k::PartialValue::Iname(b(r.pick(INAME))),
        Syn::Utf8 => k::PartialValue::Utf8(b(r.pick(UTF8))),
        Syn::Uuid => k::PartialValue::Uuid(any_uuid(r)),
        Syn::Refer | Syn::Scope => k::PartialValue::Refer(any_uuid(r)),
        Syn::Uint32 => k::PartialValue::Uint32(r.below(5) as u32 * 1000),
    }
}

/// A value of a random syntax, sometimes not the attribute's.
fn value_for(r: &mut Rng, syn: Syn) -> k::PartialValue {
    if r.chance(10) {
        let s = r.pick(&[Syn::Iutf8, Syn::Iname, Syn::Utf8, Syn::Uuid, Syn::Refer, Syn::Uint32]);
        value_of(r, s)
    } else {
        value_of(r, syn)
    }
}

pub fn valueset_of(r: &mut Rng, syn: Syn) -> k::ValueSet {
    let n = 1 + r.below(3);
    match syn {
        Syn::Iutf8 => k::ValueSet::Iutf8(dedup((0..n).map(|_| b(r.pick(IUTF8))).collect())),
        Syn::Iname => k::ValueSet::Iname(dedup((0..n).map(|_| b(r.pick(INAME))).collect())),
        Syn::Utf8 => k::ValueSet::Utf8(dedup((0..n).map(|_| b(r.pick(UTF8))).collect())),
        Syn::Uuid => k::ValueSet::Uuid(vec![any_uuid(r)]),
        Syn::Refer => k::ValueSet::Refer(dedup((0..n).map(|_| any_uuid(r)).collect())),
        Syn::Uint32 => k::ValueSet::Uint32(dedup((0..n).map(|_| r.below(5) as u32 * 1000).collect())),
        Syn::Scope => k::ValueSet::OauthScopeMap(some_uuids(r, GROUPS, 2)),
    }
}

pub fn class_set(r: &mut Rng) -> Vec<Vec<u8>> {
    if r.chance(60) {
        let mut v: Vec<Vec<u8>> = r.pick(CLASS_SETS).iter().map(|s| b(s)).collect();
        if r.chance(15) {
            v.push(b(r.pick(CLASSES)));
        }
        dedup(v)
    } else {
        dedup((0..1 + r.below(3)).map(|_| b(r.pick(CLASSES))).collect())
    }
}

fn set_attr(attrs: &mut Vec<k::Ava>, name: &str, vs: k::ValueSet) {
    attrs.retain(|a| a.attr != name.as_bytes());
    attrs.push(k::Ava { attr: b(name), vs });
}

/// A random entry.
pub fn entry(r: &mut Rng, uuid: u128, init: bool) -> k::Entry {
    if init && r.chance(20) {
        // The shape of an account sign-up request.
        let mut attrs = vec![k::Ava {
            attr: b("class"),
            vs: k::ValueSet::Iutf8(vec![b("object"), b("account_signup_request")]),
        }];
        for name in ["name", "mail", "displayname", "delete_after"] {
            if r.chance(50) {
                set_attr(&mut attrs, name, valueset_of(r, if name == "name" { Syn::Iname } else { Syn::Utf8 }));
            }
        }
        if r.chance(50) {
            set_attr(&mut attrs, "uuid", k::ValueSet::Uuid(vec![uuid]));
        }
        return k::Entry { uuid: 0, attrs };
    }
    let mut attrs: Vec<k::Ava> = Vec::new();
    for _ in 0..r.below(5) {
        let (name, syn) = r.pick(ATTRS);
        let vs = valueset_of(r, syn);
        set_attr(&mut attrs, name, vs);
    }
    if r.chance(92) {
        let cls = class_set(r);
        set_attr(&mut attrs, "class", k::ValueSet::Iutf8(cls));
    } else {
        attrs.retain(|a| a.attr != b"class");
    }
    if !init || r.chance(80) {
        set_attr(&mut attrs, "uuid", k::ValueSet::Uuid(vec![uuid]));
    }
    if r.chance(30) {
        set_attr(&mut attrs, "entry_managed_by", k::ValueSet::Refer(some_uuids(r, &[GROUPS, USERS].concat(), 2)));
    }
    if r.chance(25) {
        set_attr(&mut attrs, "sync_parent_uuid", k::ValueSet::Refer(some_uuids(r, SYNC_ACCOUNTS, 1)));
    }
    if r.chance(20) {
        set_attr(&mut attrs, "linked_group", k::ValueSet::Refer(some_uuids(r, GROUPS, 1)));
    }
    if r.chance(20) {
        set_attr(&mut attrs, "oauth2_rs_scope_map", k::ValueSet::OauthScopeMap(some_uuids(r, GROUPS, 2)));
    }
    k::Entry { uuid: if init { 0 } else { uuid }, attrs }
}

pub fn identity(r: &mut Rng) -> k::Identity {
    let origin = match r.below(100) {
        0..=69 => {
            let uuid = r.pick(USERS);
            let mut attrs = vec![k::Ava { attr: b("uuid"), vs: k::ValueSet::Uuid(vec![uuid]) }];
            if r.chance(75) {
                attrs.push(k::Ava { attr: b("memberof"), vs: k::ValueSet::Refer(some_uuids(r, GROUPS, 3)) });
            }
            let classes = if r.chance(25) {
                vec![b("object"), b("sync_object"), b("account")]
            } else if r.chance(10) {
                vec![b("object"), b("sync_object")]
            } else {
                vec![b("object"), b("account"), b("person")]
            };
            attrs.push(k::Ava { attr: b("class"), vs: k::ValueSet::Iutf8(classes) });
            if r.chance(50) {
                attrs.push(k::Ava { attr: b("sync_parent_uuid"), vs: k::ValueSet::Refer(some_uuids(r, SYNC_ACCOUNTS, 1)) });
            }
            k::IdentType::User(k::IdentUser { entry: k::Entry { uuid, attrs } })
        }
        70..=77 => k::IdentType::Synch(r.pick(SYNC_ACCOUNTS)),
        _ => k::IdentType::Internal(r.pick(&[
            k::InternalRole::System,
            k::InternalRole::Migration,
            k::InternalRole::AccountRequest,
            k::InternalRole::MessageQueue,
        ])),
    };
    let scope = match r.below(10) {
        0..=6 => k::AccessScope::ReadWrite,
        7..=8 => k::AccessScope::ReadOnly,
        _ => k::AccessScope::Synchronise,
    };
    k::Identity { origin, scope }
}

fn attr_name(r: &mut Rng) -> (&'static str, Syn) {
    if r.chance(40) {
        r.pick(&ATTRS[..6])
    } else {
        r.pick(ATTRS)
    }
}

pub fn filter(r: &mut Rng, depth: u32) -> k::FilterComp {
    let leaf = depth == 0 || r.chance(55);
    if leaf {
        let (a, syn) = attr_name(r);
        match r.below(20) {
            0..=7 => k::FilterComp::Eq(b(a), value_for(r, syn)),
            8..=10 => k::FilterComp::Pres(b(a)),
            11 => k::FilterComp::Cnt(b(a), value_for(r, syn)),
            12 => k::FilterComp::Stw(b(a), value_for(r, syn)),
            13 => k::FilterComp::Enw(b(a), value_for(r, syn)),
            14 => k::FilterComp::LessThan(b(a), value_for(r, syn)),
            15..=16 => k::FilterComp::SelfUuid,
            17 => k::FilterComp::Invalid(b(a)),
            _ => k::FilterComp::Eq(b("class"), k::PartialValue::Iutf8(b(r.pick(CLASSES)))),
        }
    } else {
        let n = r.below(4) as usize;
        let mut l = Vec::new();
        for _ in 0..n {
            l.push(filter(r, depth - 1));
        }
        match r.below(10) {
            0..=3 => k::FilterComp::Or(l),
            4..=6 => k::FilterComp::And(l),
            7..=8 => k::FilterComp::AndNot(Box::new(filter(r, depth - 1))),
            _ => k::FilterComp::Inclusion(l),
        }
    }
}

/// A random subset of the attributes; sometimes nearly all of them.
fn attr_subset(r: &mut Rng, pct: u64) -> Vec<Vec<u8>> {
    let pct = if r.chance(30) { 95 } else { pct };
    ATTRS.iter().filter(|_| r.chance(pct)).map(|(a, _)| b(a)).collect()
}

fn class_subset(r: &mut Rng, pct: u64) -> Vec<Vec<u8>> {
    let pct = if r.chance(30) { 95 } else { pct };
    CLASSES.iter().filter(|_| r.chance(pct)).map(|c| b(c)).collect()
}

fn profile(r: &mut Rng) -> kp::AccessControlProfile {
    let receiver = match r.below(20) {
        0..=11 => kp::AccessControlReceiver::Group(some_uuids(r, GROUPS, 2)),
        12..=17 => kp::AccessControlReceiver::EntryManager,
        _ => kp::AccessControlReceiver::None,
    };
    let target = match r.below(100) {
        0..=29 => kp::AccessControlTarget::Scope(k::FilterComp::Pres(b(r.pick(&["class", "uuid", "name"])))),
        30..=91 => kp::AccessControlTarget::Scope(filter(r, 2)),
        _ => kp::AccessControlTarget::None,
    };
    kp::AccessControlProfile { receiver, target }
}

pub fn acls(r: &mut Rng) -> k::AccessControlsInner {
    let acps_search = (0..r.below(4))
        .map(|_| kp::AccessControlSearch { acp: profile(r), attrs: attr_subset(r, 50) })
        .collect();
    let acps_create = (0..r.below(4))
        .map(|_| kp::AccessControlCreate { acp: profile(r), classes: class_subset(r, 50), attrs: attr_subset(r, 60) })
        .collect();
    let acps_modify = (0..r.below(4))
        .map(|_| kp::AccessControlModify {
            acp: profile(r),
            presattrs: attr_subset(r, 50),
            remattrs: attr_subset(r, 50),
            pres_classes: class_subset(r, 40),
            rem_classes: class_subset(r, 40),
        })
        .collect();
    let acps_delete = (0..r.below(4)).map(|_| kp::AccessControlDelete { acp: profile(r) }).collect();
    let mut sync_agreements: Vec<k::SyncAgreement> = Vec::new();
    for &u in SYNC_ACCOUNTS {
        if r.chance(50) {
            sync_agreements.push(k::SyncAgreement { uuid: u, attrs: attr_subset(r, 30) });
        }
    }
    k::AccessControlsInner { acps_search, acps_create, acps_modify, acps_delete, sync_agreements }
}

pub fn modlist(r: &mut Rng) -> Vec<k::Modify> {
    (0..r.below(4))
        .map(|_| {
            let (a, syn) = match r.below(10) {
                0..=3 => ("class", Syn::Iutf8),
                4..=5 => (r.pick(&["user_auth_token_session", "oauth2_session", "credential_update_intent_token"]), Syn::Utf8),
                _ => attr_name(r),
            };
            match r.below(10) {
                0..=3 => k::Modify::Present(b(a), value_for(r, syn)),
                4..=5 => k::Modify::Removed(b(a), value_for(r, syn)),
                6 => k::Modify::Purged(b(a)),
                7 => k::Modify::Assert(b(a), value_for(r, syn)),
                _ => {
                    if a == "class" && r.chance(70) {
                        k::Modify::Set(b(a), k::ValueSet::Iutf8(class_set(r)))
                    } else {
                        k::Modify::Set(b(a), valueset_of(r, syn))
                    }
                }
            }
        })
        .collect()
}

pub fn search_attrs(r: &mut Rng) -> Option<Vec<Vec<u8>>> {
    if r.chance(40) { None } else { Some(attr_subset(r, 30)) }
}

// ---- To kanidm's types ----

pub fn s(v: &[u8]) -> String {
    String::from_utf8(v.to_vec()).unwrap()
}

pub fn attr(v: &[u8]) -> Attribute {
    Attribute::from(s(v).as_str())
}

pub fn uid(u: u128) -> Uuid {
    Uuid::from_u128(u)
}

pub fn pv(v: &k::PartialValue) -> uv::PartialValue {
    match v {
        k::PartialValue::Utf8(x) => uv::PartialValue::Utf8(s(x)),
        k::PartialValue::Iutf8(x) => uv::PartialValue::Iutf8(s(x)),
        k::PartialValue::Iname(x) => uv::PartialValue::Iname(s(x)),
        k::PartialValue::Uuid(u) => uv::PartialValue::Uuid(uid(*u)),
        k::PartialValue::Refer(u) => uv::PartialValue::Refer(uid(*u)),
        k::PartialValue::Uint32(n) => uv::PartialValue::Uint32(*n),
    }
}

pub fn value(v: &k::PartialValue) -> uv::Value {
    match v {
        k::PartialValue::Utf8(x) => uv::Value::Utf8(s(x)),
        k::PartialValue::Iutf8(x) => uv::Value::Iutf8(s(x)),
        k::PartialValue::Iname(x) => uv::Value::Iname(s(x)),
        k::PartialValue::Uuid(u) => uv::Value::Uuid(uid(*u)),
        k::PartialValue::Refer(u) => uv::Value::Refer(uid(*u)),
        k::PartialValue::Uint32(n) => uv::Value::Uint32(*n),
    }
}

fn strs(v: &[Vec<u8>]) -> BTreeSet<String> {
    v.iter().map(|x| s(x)).collect()
}

pub fn valueset(v: &k::ValueSet) -> uvs::ValueSet {
    match v {
        k::ValueSet::Utf8(x) => Box::new(uvs::ValueSetUtf8 { set: strs(x) }),
        k::ValueSet::Iutf8(x) => Box::new(uvs::ValueSetIutf8 { set: strs(x) }),
        k::ValueSet::Iname(x) => Box::new(uvs::ValueSetIname { set: strs(x) }),
        k::ValueSet::Uuid(x) => Box::new(uvs::ValueSetUuid { set: x.iter().map(|u| uid(*u)).collect() }),
        k::ValueSet::Refer(x) => Box::new(uvs::ValueSetRefer { set: x.iter().map(|u| uid(*u)).collect() }),
        k::ValueSet::Uint32(x) => Box::new(uvs::ValueSetUint32 { set: x.iter().copied().collect() }),
        k::ValueSet::OauthScopeMap(x) => Box::new(uvs::ValueSetOauthScopeMap {
            map: x.iter().map(|u| (uid(*u), BTreeSet::from(["openid".to_string()]))).collect(),
        }),
    }
}

fn eattrs(e: &k::Entry) -> ue::Eattrs {
    e.attrs.iter().map(|a| (attr(&a.attr), valueset(&a.vs))).collect()
}

pub fn sealed(e: &k::Entry) -> Arc<ue::EntrySealedCommitted> {
    Arc::new(ue::EntrySealedCommitted::difftest_new(uid(e.uuid), eattrs(e)))
}

pub fn init(e: &k::Entry) -> ue::EntryInitNew {
    ue::EntryInitNew::difftest_new(eattrs(e))
}

pub fn ident(i: &k::Identity) -> ui::Identity {
    let origin = match &i.origin {
        k::IdentType::User(u) => ui::IdentType::User(ui::IdentUser { entry: sealed(&u.entry) }),
        k::IdentType::Synch(u) => ui::IdentType::Synch(uid(*u)),
        k::IdentType::Internal(r) => ui::IdentType::Internal(match r {
            k::InternalRole::System => ui::InternalRole::System,
            k::InternalRole::Migration => ui::InternalRole::Migration,
            k::InternalRole::AccountRequest => ui::InternalRole::AccountRequest,
            k::InternalRole::MessageQueue => ui::InternalRole::MessageQueue,
        }),
    };
    let scope = match i.scope {
        k::AccessScope::ReadOnly => ui::AccessScope::ReadOnly,
        k::AccessScope::ReadWrite => ui::AccessScope::ReadWrite,
        k::AccessScope::Synchronise => ui::AccessScope::Synchronise,
    };
    ui::Identity::difftest_new(origin, scope)
}

pub fn dfilter(f: &k::FilterComp) -> DFilter {
    match f {
        k::FilterComp::Eq(a, v) => DFilter::Eq(attr(a), pv(v)),
        k::FilterComp::Cnt(a, v) => DFilter::Cnt(attr(a), pv(v)),
        k::FilterComp::Stw(a, v) => DFilter::Stw(attr(a), pv(v)),
        k::FilterComp::Enw(a, v) => DFilter::Enw(attr(a), pv(v)),
        k::FilterComp::Pres(a) => DFilter::Pres(attr(a)),
        k::FilterComp::LessThan(a, v) => DFilter::LessThan(attr(a), pv(v)),
        k::FilterComp::Or(l) => DFilter::Or(l.iter().map(dfilter).collect()),
        k::FilterComp::And(l) => DFilter::And(l.iter().map(dfilter).collect()),
        k::FilterComp::Inclusion(l) => DFilter::Inclusion(l.iter().map(dfilter).collect()),
        k::FilterComp::AndNot(x) => DFilter::AndNot(Box::new(dfilter(x))),
        k::FilterComp::SelfUuid => DFilter::SelfUuid,
        k::FilterComp::Invalid(a) => DFilter::Invalid(attr(a)),
    }
}

pub fn filt(f: &k::FilterComp) -> Filter<kanidmd_lib::filter::FilterValid> {
    Filter::difftest_new(dfilter(f))
}

fn uprofile(p: &kp::AccessControlProfile) -> up::AccessControlProfile {
    let receiver = match &p.receiver {
        kp::AccessControlReceiver::None => up::AccessControlReceiver::None,
        kp::AccessControlReceiver::Group(g) => up::AccessControlReceiver::Group(g.iter().map(|u| uid(*u)).collect()),
        kp::AccessControlReceiver::EntryManager => up::AccessControlReceiver::EntryManager,
    };
    let target = match &p.target {
        kp::AccessControlTarget::None => up::AccessControlTarget::None,
        kp::AccessControlTarget::Scope(f) => up::AccessControlTarget::Scope(filt(f)),
    };
    up::AccessControlProfile::difftest_new(receiver, target)
}

fn attrset(v: &[Vec<u8>]) -> BTreeSet<Attribute> {
    v.iter().map(|a| attr(a)).collect()
}

fn attrvec(v: &[Vec<u8>]) -> Vec<Attribute> {
    v.iter().map(|a| attr(a)).collect()
}

fn attrstrings(v: &[Vec<u8>]) -> Vec<kanidm_proto::attribute::AttrString> {
    v.iter().map(|a| s(a).as_str().into()).collect()
}

pub fn controls(c: &k::AccessControlsInner) -> kanidmd_lib::server::access::DifftestAccessControls {
    kanidmd_lib::server::access::DifftestAccessControls::new(
        c.acps_search
            .iter()
            .map(|a| up::AccessControlSearch { acp: uprofile(&a.acp), attrs: attrset(&a.attrs) })
            .collect(),
        c.acps_create
            .iter()
            .map(|a| up::AccessControlCreate {
                acp: uprofile(&a.acp),
                classes: attrstrings(&a.classes),
                attrs: attrvec(&a.attrs),
            })
            .collect(),
        c.acps_modify
            .iter()
            .map(|a| up::AccessControlModify {
                acp: uprofile(&a.acp),
                presattrs: attrvec(&a.presattrs),
                remattrs: attrvec(&a.remattrs),
                pres_classes: attrstrings(&a.pres_classes),
                rem_classes: attrstrings(&a.rem_classes),
            })
            .collect(),
        c.acps_delete.iter().map(|a| up::AccessControlDelete { acp: uprofile(&a.acp) }).collect(),
        c.sync_agreements.iter().map(|a| (uid(a.uuid), attrset(&a.attrs))).collect(),
    )
}

pub fn umodify(m: &k::Modify) -> um::Modify {
    match m {
        k::Modify::Present(a, v) => um::Modify::Present(attr(a), value(v)),
        k::Modify::Removed(a, v) => um::Modify::Removed(attr(a), pv(v)),
        k::Modify::Purged(a) => um::Modify::Purged(attr(a)),
        k::Modify::Assert(a, v) => um::Modify::Assert(attr(a), pv(v)),
        k::Modify::Set(a, vs) => um::Modify::Set(attr(a), valueset(vs)),
    }
}

pub fn umodlist(ms: &[k::Modify]) -> um::ModifyList<um::ModifyValid> {
    um::ModifyList::difftest_new(ms.iter().map(umodify).collect())
}

pub fn modset(ms: &[k::ModSetEntry]) -> BTreeMap<Uuid, um::ModifyList<um::ModifyValid>> {
    ms.iter().map(|m| (uid(m.uuid), umodlist(&m.modlist))).collect()
}
