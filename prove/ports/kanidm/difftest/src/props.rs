//! Falsification tests for the statements in proofs/Properties.lean. Each
//! checks the property on random inputs and counts how often its premises
//! hold, so a statement that is false, or true only because its premises
//! never hold, fails here.
use crate::generate::*;
use crate::tests::{World, clone_filter, world};
use kanidm_kernel as k;
use kanidm_kernel::access as ka;
use kanidm_kernel::profiles as kp;

const N: usize = 150_000;
/// Each property's premises must hold in at least this many cases.
const MIN_HITS: usize = 300;

// ---- Spec.lean, in Rust ----

fn ava<'a>(e: &'a k::Entry, a: &[u8]) -> Option<&'a k::ValueSet> {
    e.attrs.iter().find(|x| x.attr == a).map(|x| &x.vs)
}
fn classes(e: &k::Entry) -> Vec<Vec<u8>> {
    match ava(e, b"class") {
        Some(k::ValueSet::Iutf8(s)) => s.clone(),
        _ => vec![],
    }
}
fn has_class(e: &k::Entry, c: &str) -> bool {
    classes(e).iter().any(|x| x == c.as_bytes())
}
fn refers(e: &k::Entry, a: &str) -> Option<Vec<u128>> {
    match ava(e, a.as_bytes()) {
        Some(k::ValueSet::Refer(s)) => Some(s.clone()),
        _ => None,
    }
}
fn uuid_of(e: &k::Entry) -> Option<u128> {
    match ava(e, b"uuid") {
        Some(k::ValueSet::Uuid(s)) if s.len() == 1 => Some(s[0]),
        _ => None,
    }
}
fn is_user(i: &k::Identity) -> bool {
    matches!(i.origin, k::IdentType::User(_))
}
fn memberof(i: &k::Identity) -> Vec<u128> {
    match &i.origin {
        k::IdentType::User(u) => refers(&u.entry, "memberof").unwrap_or_default(),
        _ => vec![],
    }
}
fn receiver_holds(i: &k::Identity, r: &kp::AccessControlReceiver, e: &k::Entry) -> bool {
    match r {
        kp::AccessControlReceiver::None => false,
        kp::AccessControlReceiver::Group(gs) => memberof(i).iter().any(|g| gs.contains(g)),
        kp::AccessControlReceiver::EntryManager => match refers(e, "entry_managed_by") {
            Some(ms) => {
                let user = matches!(&i.origin, k::IdentType::User(u) if ms.contains(&u.entry.uuid));
                user || memberof(i).iter().any(|g| ms.contains(g))
            }
            None => false,
        },
    }
}
fn target_holds(i: &k::Identity, t: &kp::AccessControlTarget, e: &k::Entry) -> bool {
    match t {
        kp::AccessControlTarget::None => false,
        kp::AccessControlTarget::Scope(f) => match k::filter_impl::resolve(f, i) {
            Some(fr) => k::entry_impl::entry_match_no_index(e, &fr),
            None => false,
        },
    }
}
fn applies(i: &k::Identity, p: &kp::AccessControlProfile, e: &k::Entry) -> bool {
    receiver_holds(i, &p.receiver, e) && target_holds(i, &p.target, e)
}
const FIXED_SEARCH: &[&str] = &[
    "class", "displayname", "uuid", "name", "oauth2_rs_origin_landing", "image", "linked_group",
    "sync_credential_portal",
];
fn search_grants(ctl: &k::AccessControlsInner, i: &k::Identity, e: &k::Entry, a: &[u8]) -> bool {
    ctl.acps_search.iter().any(|acs| acs.attrs.iter().any(|x| x == a) && applies(i, &acs.acp, e))
        || FIXED_SEARCH.iter().any(|x| x.as_bytes() == a)
}
const PROTECTED_ENTRY: &[&str] =
    &["system", "domain_info", "system_info", "system_config", "dyngroup", "sync_object", "tombstone", "recycled"];
const PROTECTED_MOD_ENTRY: &[&str] =
    &["system", "domain_info", "system_info", "system_config", "dyngroup", "tombstone", "recycled"];
fn in_list(c: &[u8], l: &[&str]) -> bool {
    l.iter().any(|x| x.as_bytes() == c)
}
fn pres_attr(m: &k::Modify) -> Option<Vec<u8>> {
    match m {
        k::Modify::Present(a, _) | k::Modify::Set(a, _) | k::Modify::Assert(a, _) => Some(a.clone()),
        _ => None,
    }
}
fn str_of(v: &k::PartialValue) -> Option<Vec<u8>> {
    match v {
        k::PartialValue::Utf8(s) | k::PartialValue::Iutf8(s) | k::PartialValue::Iname(s) => Some(s.clone()),
        _ => None,
    }
}
const SYNC_ATTRS: &[&str] =
    &["user_auth_token_session", "oauth2_session", "oauth2_consent_scope_map", "credential_update_intent_token"];
fn agreement_attrs(sa: &[k::SyncAgreement], u: u128) -> Vec<Vec<u8>> {
    sa.iter().find(|a| a.uuid == u).map(|a| a.attrs.clone()).unwrap_or_default()
}
fn value_contains(vs: &k::ValueSet, v: &k::PartialValue) -> bool {
    use k::PartialValue as P;
    use k::ValueSet as V;
    match (vs, v) {
        (V::Utf8(s), P::Utf8(x)) | (V::Iutf8(s), P::Iutf8(x)) | (V::Iname(s), P::Iname(x)) => s.contains(x),
        (V::Uuid(s), P::Uuid(u)) | (V::Refer(s), P::Refer(u)) | (V::OauthScopeMap(s), P::Refer(u)) => s.contains(u),
        (V::Uint32(s), P::Uint32(n)) => s.contains(n),
        _ => false,
    }
}

// ---- Harness ----

/// Runs `check` on N worlds; `check` returns how many times its premises held.
fn property(seed: u64, check: impl Fn(&mut Rng, &World) -> usize) {
    property_with(seed, |_, _| {}, check)
}

/// `property`, with each world first adjusted by `adjust`.
fn property_with(seed: u64, adjust: impl Fn(&mut Rng, &mut World), check: impl Fn(&mut Rng, &World) -> usize) {
    let mut r = Rng(seed);
    let mut hits = 0;
    for _ in 0..N {
        let mut w = world(&mut r);
        adjust(&mut r, &mut w);
        hits += check(&mut r, &w);
    }
    eprintln!("seed {seed}: {hits} hits");
    assert!(hits >= MIN_HITS, "premises held only {hits} times");
}

fn me(w: &World) -> k::ModifyEvent {
    k::ModifyEvent { ident: w.ident.clone(), modlist: crate::tests::clone_mods(&w.modlist) }
}

#[test]
fn protected_deny_overrides_modify() {
    property(1, |_, w| {
        let related = ka::modify_related_acp(&w.ctl, &w.ident);
        let mut hits = 0;
        for e in &w.entries {
            if !matches!(k::modify_acc::modify_protected_attrs(&w.ident, e), k::AccessModResult::Deny) {
                continue;
            }
            let out = k::modify_acc::apply_modify_access(&w.ident, &related, &w.ctl.sync_agreements, e);
            assert_eq!(out, k::modify_acc::ModifyResult::Deny);
            hits += 1;
        }
        hits
    });
}

#[test]
fn protected_deny_overrides_create() {
    property(2, |_, w| {
        let related = ka::create_related_acp(&w.ctl, &w.ident);
        let mut hits = 0;
        for e in &w.new_entries {
            if !matches!(k::create_acc::protected_filter_entry(&w.ident, e), k::create_acc::IResult::Deny) {
                continue;
            }
            assert_eq!(k::create_acc::apply_create_access(&w.ident, &related, e), k::create_acc::CreateResult::Deny);
            hits += 1;
        }
        hits
    });
}

#[test]
fn search_attrs_granted() {
    property(3, |_, w| {
        let se = k::SearchEvent {
            ident: w.ident.clone(),
            filter_orig: clone_filter(&w.filter),
            attrs: w.attrs.clone(),
            effective_access_check: false,
        };
        let Ok(rs) = ka::search_filter_entry_attributes(&w.ctl, &se, &w.entries) else { return 0 };
        let mut hits = 0;
        for r in &rs {
            for x in &r.attrs {
                let ok = w.entries.iter().any(|e| {
                    e.uuid == r.uuid && e.attrs.contains(x) && search_grants(&w.ctl, &w.ident, e, &x.attr)
                });
                assert!(ok);
                hits += 1;
            }
        }
        hits
    });
}

#[test]
fn anonymous_reads_by_profile_only() {
    property(4, |_, w| {
        let k::IdentType::User(u) = &w.ident.origin else { return 0 };
        if u.entry.uuid != k::UUID_ANONYMOUS || has_class(&u.entry, "sync_object") {
            return 0;
        }
        let related = ka::search_related_acp(&w.ctl, &w.ident, None);
        let mut hits = 0;
        for e in &w.entries {
            if let k::search_acc::SearchResult::Allow(attrs) = k::search_acc::apply_search_access(&w.ident, &related, e) {
                for x in &attrs {
                    assert!(related.iter().any(|acs| acs.attrs.contains(x)));
                    hits += 1;
                }
            }
        }
        hits
    });
}

#[test]
fn synchronise_sees_nothing() {
    property(5, |_, w| {
        let sync = (is_user(&w.ident) && w.ident.scope == k::AccessScope::Synchronise)
            || matches!(w.ident.origin, k::IdentType::Synch(_));
        if !sync {
            return 0;
        }
        let out = ka::filter_entries(&w.ctl, &w.ident, &w.filter, &w.entries).unwrap();
        assert!(out.is_empty());
        1
    });
}

#[test]
fn readonly_cannot_modify() {
    property(6, |_, w| {
        if !is_user(&w.ident) || w.ident.scope == k::AccessScope::ReadWrite || w.entries.is_empty() {
            return 0;
        }
        assert!(!ka::modify_allow_operation(&w.ctl, &me(w), &w.entries).unwrap());
        1
    });
}

#[test]
fn delete_needs_profile() {
    property(7, |_, w| {
        if !is_user(&w.ident) {
            return 0;
        }
        let de = k::DeleteEvent { ident: w.ident.clone() };
        if !ka::delete_allow_operation(&w.ctl, &de, &w.entries).unwrap() {
            return 0;
        }
        for e in &w.entries {
            assert!(w.ctl.acps_delete.iter().any(|acd| applies(&w.ident, &acd.acp, e)));
        }
        w.entries.len()
    });
}

#[test]
fn create_needs_profile() {
    property(8, |_, w| {
        if !is_user(&w.ident) {
            return 0;
        }
        let ce = k::CreateEvent { ident: w.ident.clone() };
        if !ka::create_allow_operation(&w.ctl, &ce, &w.new_entries).unwrap() {
            return 0;
        }
        for e in &w.new_entries {
            assert!(w.ctl.acps_create.iter().any(|acc| {
                matches!(acc.acp.receiver, kp::AccessControlReceiver::Group(_))
                    && applies(&w.ident, &acc.acp, e)
                    && e.attrs.iter().all(|a| acc.attrs.contains(&a.attr))
                    && classes(e).iter().all(|c| acc.classes.contains(c))
            }));
        }
        w.new_entries.len()
    });
}

#[test]
fn modify_needs_profile() {
    property(9, |_, w| {
        if !is_user(&w.ident) || !ka::modify_allow_operation(&w.ctl, &me(w), &w.entries).unwrap() {
            return 0;
        }
        let mut hits = 0;
        for e in &w.entries {
            for m in &w.modlist {
                let Some(a) = pres_attr(m) else { continue };
                assert!(w.ctl.acps_modify.iter().any(|acm| acm.presattrs.contains(&a) && applies(&w.ident, &acm.acp, e)));
                hits += 1;
            }
        }
        hits
    });
}

#[test]
fn delete_protected() {
    property(10, |_, w| {
        if !(is_user(&w.ident) || w.ident.origin == k::IdentType::Internal(k::InternalRole::Migration)) {
            return 0;
        }
        let de = k::DeleteEvent { ident: w.ident.clone() };
        if !ka::delete_allow_operation(&w.ctl, &de, &w.entries).unwrap() {
            return 0;
        }
        for e in &w.entries {
            assert!(k::UUID_ANONYMOUS < e.uuid);
            assert!(classes(e).iter().all(|c| !in_list(c, PROTECTED_ENTRY)));
        }
        w.entries.len()
    });
}

#[test]
fn create_protected() {
    property(11, |_, w| {
        if !(is_user(&w.ident) || w.ident.origin == k::IdentType::Internal(k::InternalRole::Migration)) {
            return 0;
        }
        let ce = k::CreateEvent { ident: w.ident.clone() };
        if !ka::create_allow_operation(&w.ctl, &ce, &w.new_entries).unwrap() {
            return 0;
        }
        for e in &w.new_entries {
            if let Some(u) = uuid_of(e) {
                assert!(k::UUID_ANONYMOUS < u);
            }
            assert!(classes(e).iter().all(|c| !in_list(c, PROTECTED_ENTRY)));
        }
        w.new_entries.len()
    });
}

#[test]
fn tombstone_locked() {
    property(12, |_, w| {
        if w.ident.origin == k::IdentType::Internal(k::InternalRole::System)
            || !w.entries.iter().any(|e| has_class(e, "tombstone"))
        {
            return 0;
        }
        assert!(!ka::modify_allow_operation(&w.ctl, &me(w), &w.entries).unwrap());
        1
    });
}

#[test]
fn protected_class_never_added() {
    // One entry and a request to add a class.
    let adjust = |r: &mut Rng, w: &mut World| {
        w.entries.truncate(1);
        let c = if r.chance(50) { r.pick(PROTECTED_ENTRY) } else { r.pick(CLASSES) };
        w.modlist = vec![k::Modify::Present(b("class"), k::PartialValue::Iutf8(b(c)))];
        if r.chance(50) {
            w.modlist.push(k::Modify::Present(b(r.pick(ATTRS).0), k::PartialValue::Utf8(b("x"))));
        }
    };
    property_with(13, adjust, |_, w| {
        if w.ident.origin == k::IdentType::Internal(k::InternalRole::System)
            || w.entries.is_empty()
            || !ka::modify_allow_operation(&w.ctl, &me(w), &w.entries).unwrap()
        {
            return 0;
        }
        let mut hits = 0;
        for m in &w.modlist {
            if let k::Modify::Present(a, v) = m {
                if a == b"class" {
                    if let Some(c) = str_of(v) {
                        assert!(!in_list(&c, PROTECTED_ENTRY));
                        hits += 1;
                    }
                }
            }
        }
        hits
    });
}

#[test]
fn sync_object_constrained() {
    // One synchronised entry with a sync parent, and changes to the session
    // attributes or others.
    let adjust = |r: &mut Rng, w: &mut World| {
        w.entries.truncate(1);
        if let Some(e) = w.entries.first_mut() {
            e.uuid = 0x2_0000_0000_0003;
            e.attrs.retain(|a| a.attr != b"class" && a.attr != b"sync_parent_uuid");
            e.attrs.push(k::Ava { attr: b("class"), vs: k::ValueSet::Iutf8(vec![b("object"), b("sync_object"), b("person")]) });
            if r.chance(90) {
                e.attrs.push(k::Ava { attr: b("sync_parent_uuid"), vs: k::ValueSet::Refer(vec![r.pick(SYNC_ACCOUNTS)]) });
            }
        }
        w.modlist = (0..1 + r.below(2))
            .map(|_| {
                let a = if r.chance(60) { r.pick(SYNC_ATTRS) } else { r.pick(ATTRS).0 };
                k::Modify::Present(b(a), k::PartialValue::Utf8(b("x")))
            })
            .collect();
    };
    property_with(14, adjust, |_, w| {
        if !is_user(&w.ident) || !ka::modify_allow_operation(&w.ctl, &me(w), &w.entries).unwrap() {
            return 0;
        }
        let mut hits = 0;
        for e in &w.entries {
            if !has_class(e, "sync_object")
                || e.uuid <= k::UUID_ANONYMOUS
                || classes(e).iter().any(|c| in_list(c, PROTECTED_MOD_ENTRY))
            {
                continue;
            }
            for m in &w.modlist {
                let Some(a) = pres_attr(m) else { continue };
                let p = refers(e, "sync_parent_uuid");
                assert!(matches!(&p, Some(v) if v.len() == 1));
                let p = p.unwrap()[0];
                assert!(in_list(&a, SYNC_ATTRS) || agreement_attrs(&w.ctl.sync_agreements, p).contains(&a));
                hits += 1;
            }
        }
        hits
    });
}

#[test]
fn account_request_creates_signups() {
    property(15, |_, w| {
        if w.ident.origin != k::IdentType::Internal(k::InternalRole::AccountRequest) {
            return 0;
        }
        let ce = k::CreateEvent { ident: w.ident.clone() };
        if !ka::create_allow_operation(&w.ctl, &ce, &w.new_entries).unwrap() {
            return 0;
        }
        for e in &w.new_entries {
            for x in &e.attrs {
                assert!(in_list(&x.attr, &["class", "delete_after", "displayname", "mail", "name", "uuid"]));
            }
            assert!(classes(e).iter().all(|c| in_list(c, &["object", "account_signup_request"])));
        }
        w.new_entries.len()
    });
}

#[test]
fn match_eq_spec() {
    property(16, |r, w| {
        let mut hits = 0;
        for e in w.entries.iter().chain(w.new_entries.iter()) {
            let (a, syn) = r.pick(ATTRS);
            let syn = if r.chance(85) { syn } else { Syn::Utf8 };
            let v = value_of(r, syn);
            let got = k::entry_impl::entry_match_no_index_inner(e, &k::FilterResolved::Eq(b(a), v.clone()));
            let want = match ava(e, a.as_bytes()) {
                Some(vs) => value_contains(vs, &v),
                None => false,
            };
            assert_eq!(got, want);
            hits += got as usize;
        }
        hits
    });
}

#[test]
fn str_contains_spec() {
    let mut r = Rng(17);
    let mut hits = 0;
    for _ in 0..N {
        let hay: Vec<u8> = (0..r.below(8)).map(|_| b"ab"[r.below(2) as usize]).collect();
        let needle: Vec<u8> = (0..r.below(4)).map(|_| b"ab"[r.below(2) as usize]).collect();
        let want = needle.is_empty() || hay.windows(needle.len()).any(|w| w == &needle[..]);
        assert_eq!(k::valueset::str_contains(&hay, &needle), want);
        hits += want as usize;
    }
    assert!(hits >= MIN_HITS);
}

#[test]
fn effective_permission_check_total() {
    property(18, |_, w| {
        // Panics and overflows abort the test; every case is a hit.
        ka::effective_permission_check(&w.ctl, &w.ident, w.attrs.as_ref(), &w.entries).unwrap();
        1
    });
}
