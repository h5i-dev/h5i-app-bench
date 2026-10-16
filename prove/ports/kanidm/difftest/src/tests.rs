//! The kernel against kanidm's access module: every public operation of
//! `AccessControlsTransaction` on the same random profiles, identities,
//! entries and requests.
use crate::generate::*;
use kanidm_kernel as k;
use kanidm_kernel::access as ka;
use kanidmd_lib::event as uev;
use kanidmd_lib::server::access::{
    Access, AccessClass, AccessControlsTransaction, AccessEffectivePermission,
};
use kanidmd_lib::server::batch_modify::BatchModifyEvent;
use std::collections::BTreeSet;

const N: u64 = 100_000;

/// One random case.
pub struct World {
    pub ctl: k::AccessControlsInner,
    pub ident: k::Identity,
    pub entries: Vec<k::Entry>,
    pub new_entries: Vec<k::Entry>,
    pub filter: k::FilterComp,
    pub attrs: Option<Vec<Vec<u8>>>,
    pub effective: bool,
    pub modlist: Vec<k::Modify>,
    pub modset: Vec<k::ModSetEntry>,
}

pub fn world(r: &mut Rng) -> World {
    let ctl = acls(r);
    let ident = identity(r);
    let n = 1 + r.below(4);
    let mut uuids: Vec<u128> = Vec::new();
    for _ in 0..n {
        let u = r.pick(ENTRIES);
        if !uuids.contains(&u) {
            uuids.push(u);
        }
    }
    let entries: Vec<k::Entry> = uuids.iter().map(|&u| entry(r, u, false)).collect();
    let new_entries = (0..1 + r.below(2)).map(|_| {
        let u = r.pick(ENTRIES);
        entry(r, u, true)
    }).collect();
    let filter = filter(r, 3);
    let attrs = search_attrs(r);
    let effective = r.chance(50);
    let modlist = modlist(r);
    let mut modset = Vec::new();
    for &u in &uuids {
        if r.chance(85) {
            modset.push(k::ModSetEntry { uuid: u, modlist: crate::generate::modlist(r) });
        }
    }
    World { ctl, ident, entries, new_entries, filter, attrs, effective, modlist, modset }
}

fn names(v: &[Vec<u8>]) -> BTreeSet<String> {
    v.iter().map(|x| s(x)).collect()
}

fn k_access(a: &k::Access) -> String {
    match a {
        k::Access::Grant => "grant".into(),
        k::Access::Deny => "deny".into(),
        k::Access::Allow(x) => format!("allow {:?}", names(x)),
    }
}

fn u_access(a: &Access) -> String {
    match a {
        Access::Grant => "grant".into(),
        Access::Deny => "deny".into(),
        Access::Allow(x) => format!("allow {:?}", x.iter().map(|a| a.as_str().to_string()).collect::<BTreeSet<_>>()),
    }
}

fn k_class(a: &k::AccessClass) -> String {
    match a {
        k::AccessClass::Grant => "grant".into(),
        k::AccessClass::Deny => "deny".into(),
        k::AccessClass::Allow(x) => format!("allow {:?}", names(x)),
    }
}

fn u_class(a: &AccessClass) -> String {
    match a {
        AccessClass::Grant => "grant".into(),
        AccessClass::Deny => "deny".into(),
        AccessClass::Allow(x) => format!("allow {:?}", x.iter().map(|a| a.to_string()).collect::<BTreeSet<_>>()),
    }
}

fn k_eff(p: &k::AccessEffectivePermission) -> String {
    format!(
        "{:x} {:x} del={} s={} mp={} mr={} mpc={} mrc={}",
        p.ident,
        p.target,
        p.delete,
        k_access(&p.search),
        k_access(&p.modify_pres),
        k_access(&p.modify_rem),
        k_class(&p.modify_pres_class),
        k_class(&p.modify_rem_class)
    )
}

fn u_eff(p: &AccessEffectivePermission) -> String {
    format!(
        "{:x} {:x} del={} s={} mp={} mr={} mpc={} mrc={}",
        p.ident.as_u128(),
        p.target.as_u128(),
        p.delete,
        u_access(&p.search),
        u_access(&p.modify_pres),
        u_access(&p.modify_rem),
        u_class(&p.modify_pres_class),
        u_class(&p.modify_rem_class)
    )
}

/// Runs every operation on both sides; returns how many results were
/// non-trivial (an entry released, an operation allowed).
fn compare(w: &World, hits: &mut [usize; 7]) {
    let uctl = controls(&w.ctl);
    let uident = ident(&w.ident);
    let uentries: Vec<_> = w.entries.iter().map(sealed).collect();
    let ufilter = filt(&w.filter);
    let ctx = format!("{:?}\nentries {:?}\nfilter {:?}", w.ident, w.entries, w.filter);

    // filter_entries
    let kf = ka::filter_entries(&w.ctl, &w.ident, &w.filter, &w.entries).unwrap();
    let uf = uctl.filter_entries(&uident, &ufilter, uentries.clone()).unwrap();
    let kf: Vec<u128> = kf.iter().map(|e| e.uuid).collect();
    let uf: Vec<u128> = uf.iter().map(|e| e.get_uuid().as_u128()).collect();
    assert_eq!(kf, uf, "filter_entries\n{ctx}");
    hits[0] += (!kf.is_empty()) as usize;

    // search_filter_entry_attributes
    let kse = k::SearchEvent {
        ident: w.ident.clone(),
        filter_orig: clone_filter(&w.filter),
        attrs: w.attrs.clone(),
        effective_access_check: w.effective,
    };
    let use_ = uev::SearchEvent {
        ident: uident.clone(),
        filter: filt(&w.filter),
        filter_orig: filt(&w.filter),
        attrs: w.attrs.as_ref().map(|a| a.iter().map(|x| attr(x)).collect()),
        effective_access_check: w.effective,
    };
    let kr = ka::search_filter_entry_attributes(&w.ctl, &kse, &w.entries);
    let ur = uctl.search_filter_entry_attributes(&use_, uentries.clone());
    match (kr, ur) {
        (Err(_), Err(_)) => {}
        (Ok(kr), Ok(ur)) => {
            let kr: Vec<String> = kr
                .iter()
                .map(|e| {
                    format!(
                        "{:x} {:?} {:?}",
                        e.uuid,
                        e.attrs.iter().map(|a| s(&a.attr)).collect::<BTreeSet<_>>(),
                        e.effective_access.as_ref().map(k_eff)
                    )
                })
                .collect();
            let ur: Vec<String> = ur
                .iter()
                .map(|e| {
                    let (u, attrs, eff) = e.difftest_parts();
                    format!(
                        "{:x} {:?} {:?}",
                        u.as_u128(),
                        attrs.keys().map(|a| a.as_str().to_string()).collect::<BTreeSet<_>>(),
                        eff.map(u_eff)
                    )
                })
                .collect();
            assert_eq!(kr, ur, "search_filter_entry_attributes\n{ctx}\nattrs {:?}", w.attrs);
            hits[1] += kr.iter().any(|x| !x.contains("{}")) as usize;
        }
        (a, b) => panic!("search_filter_entry_attributes: {:?} vs {:?}\n{ctx}", a.is_ok(), b.is_ok()),
    }

    // modify_allow_operation
    let kme = k::ModifyEvent { ident: w.ident.clone(), modlist: clone_mods(&w.modlist) };
    let ume = uev::ModifyEvent {
        ident: uident.clone(),
        filter: filt(&w.filter),
        filter_orig: filt(&w.filter),
        modlist: umodlist(&w.modlist),
    };
    let km = ka::modify_allow_operation(&w.ctl, &kme, &w.entries).unwrap();
    let um = uctl.modify_allow_operation(&ume, &uentries).unwrap();
    assert_eq!(km, um, "modify_allow_operation\n{ctx}\nmods {:?}\nacps {}", w.modlist, w.ctl.acps_modify.len());
    hits[2] += km as usize;

    // batch_modify_allow_operation
    let kbe = k::BatchModifyEvent {
        ident: w.ident.clone(),
        modset: w.modset.iter().map(|m| k::ModSetEntry { uuid: m.uuid, modlist: clone_mods(&m.modlist) }).collect(),
    };
    let ube = BatchModifyEvent { ident: uident.clone(), modset: modset(&w.modset) };
    let kb = ka::batch_modify_allow_operation(&w.ctl, &kbe, &w.entries).unwrap();
    let ub = uctl.batch_modify_allow_operation(&ube, &uentries).unwrap();
    assert_eq!(kb, ub, "batch_modify_allow_operation\n{ctx}");
    hits[3] += kb as usize;

    // create_allow_operation
    let uinit: Vec<_> = w.new_entries.iter().map(init).collect();
    let kce = k::CreateEvent { ident: w.ident.clone() };
    let uce = uev::CreateEvent { ident: uident.clone(), entries: Vec::new(), return_created_uuids: false };
    let kc = ka::create_allow_operation(&w.ctl, &kce, &w.new_entries).unwrap();
    let uc = uctl.create_allow_operation(&uce, &uinit).unwrap();
    assert_eq!(kc, uc, "create_allow_operation\n{ctx}\nnew {:?}", w.new_entries);
    hits[4] += kc as usize;

    // delete_allow_operation
    let kde = k::DeleteEvent { ident: w.ident.clone() };
    let ude = uev::DeleteEvent { ident: uident.clone(), filter: filt(&w.filter), filter_orig: filt(&w.filter) };
    let kd = ka::delete_allow_operation(&w.ctl, &kde, &w.entries).unwrap();
    let ud = uctl.delete_allow_operation(&ude, &uentries).unwrap();
    assert_eq!(kd, ud, "delete_allow_operation\n{ctx}");
    hits[5] += kd as usize;

    // effective_permission_check
    let kp = ka::effective_permission_check(&w.ctl, &w.ident, w.attrs.as_ref(), &w.entries).unwrap();
    let up = uctl
        .effective_permission_check(&uident, w.attrs.as_ref().map(|a| a.iter().map(|x| attr(x)).collect()), &uentries)
        .unwrap();
    let kp: Vec<String> = kp.iter().map(k_eff).collect();
    let up: Vec<String> = up.iter().map(u_eff).collect();
    assert_eq!(kp, up, "effective_permission_check\n{ctx}");
    hits[6] += kp.iter().any(|p| p.contains("allow {\"")) as usize;
}

pub fn clone_filter(f: &k::FilterComp) -> k::FilterComp {
    match f {
        k::FilterComp::Eq(a, v) => k::FilterComp::Eq(a.clone(), v.clone()),
        k::FilterComp::Cnt(a, v) => k::FilterComp::Cnt(a.clone(), v.clone()),
        k::FilterComp::Stw(a, v) => k::FilterComp::Stw(a.clone(), v.clone()),
        k::FilterComp::Enw(a, v) => k::FilterComp::Enw(a.clone(), v.clone()),
        k::FilterComp::Pres(a) => k::FilterComp::Pres(a.clone()),
        k::FilterComp::LessThan(a, v) => k::FilterComp::LessThan(a.clone(), v.clone()),
        k::FilterComp::Or(l) => k::FilterComp::Or(l.iter().map(clone_filter).collect()),
        k::FilterComp::And(l) => k::FilterComp::And(l.iter().map(clone_filter).collect()),
        k::FilterComp::Inclusion(l) => k::FilterComp::Inclusion(l.iter().map(clone_filter).collect()),
        k::FilterComp::AndNot(x) => k::FilterComp::AndNot(Box::new(clone_filter(x))),
        k::FilterComp::SelfUuid => k::FilterComp::SelfUuid,
        k::FilterComp::Invalid(a) => k::FilterComp::Invalid(a.clone()),
    }
}

pub fn clone_mods(ms: &[k::Modify]) -> Vec<k::Modify> {
    ms.iter()
        .map(|m| match m {
            k::Modify::Present(a, v) => k::Modify::Present(a.clone(), v.clone()),
            k::Modify::Removed(a, v) => k::Modify::Removed(a.clone(), v.clone()),
            k::Modify::Purged(a) => k::Modify::Purged(a.clone()),
            k::Modify::Assert(a, v) => k::Modify::Assert(a.clone(), v.clone()),
            k::Modify::Set(a, v) => k::Modify::Set(a.clone(), v.clone()),
        })
        .collect()
}

#[test]
fn kernel_agrees_with_upstream() {
    let mut r = Rng(7);
    let mut hits = [0usize; 7];
    for _ in 0..N {
        let w = world(&mut r);
        compare(&w, &mut hits);
    }
    eprintln!("non-trivial outcomes: {hits:?}");
    for (i, h) in hits.iter().enumerate() {
        assert!(*h >= 200, "operation {i} was non-trivial only {h} times");
    }
}
