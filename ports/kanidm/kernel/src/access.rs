//! `AccessControlsTransaction` and `resolve_access_conditions`
//! (access/mod.rs). The transaction is `AccessControlsInner`; the resolve
//! filter cache only memoises `Filter::resolve` and is left out.
use crate::bset::{extend, intersection, is_disjoint, is_subset};
use crate::create_acc::{apply_create_access, CreateResult};
use crate::delete_acc::{apply_delete_access, DeleteResult};
use crate::entry_impl::{get_ava_as_iutf8, get_ava_names, reduce_attributes};
use crate::filter_impl::{get_attr_set, resolve};
use crate::identity_impl::{get_memberof, get_uuid};
use crate::modify_acc::{apply_modify_access, ModifyResult};
use crate::profiles::{
    AccessControlCreateResolved, AccessControlDeleteResolved, AccessControlModifyResolved, AccessControlReceiver,
    AccessControlReceiverCondition, AccessControlSearchResolved, AccessControlTarget, AccessControlTargetCondition,
    ModifyGrants,
};
use crate::search_acc::{apply_search_access, SearchResult};
use crate::valueset::{as_iutf8_set, to_str};
use crate::{
    Access, AccessClass, AccessControlsInner, AccessEffectivePermission, Attribute, BatchModifyEvent, CreateEvent,
    DeleteEvent, Entry, EntryReduced, FilterComp, IdentType, Identity, Modify, ModifyEvent, OperationError,
    SearchEvent, SyncAgreement, Uuid,
};

/// `resolve_access_conditions`.
pub fn resolve_access_conditions(
    ident: &Identity,
    ident_memberof: Option<&Vec<Uuid>>,
    receiver: &AccessControlReceiver,
    target: &AccessControlTarget,
) -> Option<(AccessControlReceiverCondition, AccessControlTargetCondition)> {
    let receiver_condition = match receiver {
        AccessControlReceiver::Group(groups) => {
            let group_check = match ident_memberof {
                // Have at least one group allowed.
                Some(imo) => crate::bset::intersects_uuid(imo, groups),
                None => false,
            };

            if group_check {
                AccessControlReceiverCondition::GroupChecked
            } else {
                return None;
            }
        }
        AccessControlReceiver::EntryManager => AccessControlReceiverCondition::EntryManager,
        AccessControlReceiver::None => return None,
    };

    let target_condition = match target {
        AccessControlTarget::Scope(filter) => match resolve(filter, ident) {
            Some(f) => AccessControlTargetCondition::Scope(f),
            None => return None,
        },
        AccessControlTarget::None => return None,
    };

    Some((receiver_condition, target_condition))
}

/// `search_related_acp`. The trim by requested attributes is applied as
/// each profile is resolved rather than in a second pass.
pub fn search_related_acp(
    ctl: &AccessControlsInner,
    ident: &Identity,
    attrs: Option<&Vec<Attribute>>,
) -> Vec<AccessControlSearchResolved> {
    let search_state = &ctl.acps_search;
    let ident_memberof = get_memberof(ident);

    let mut related_acp: Vec<AccessControlSearchResolved> = Vec::new();
    let mut i = 0;
    while i < search_state.len() {
        let acs = &search_state[i];
        match resolve_access_conditions(ident, ident_memberof, &acs.acp.receiver, &acs.acp.target) {
            Some((receiver_condition, target_condition)) => {
                // Trim any search rule that doesn't provide attributes related to the request.
                let keep = match attrs {
                    Some(r_attrs) => !is_disjoint(&acs.attrs, r_attrs),
                    // None here means all attrs requested.
                    None => true,
                };
                if keep {
                    related_acp.push(AccessControlSearchResolved {
                        attrs: acs.attrs.clone(),
                        receiver_condition,
                        target_condition,
                    });
                }
            }
            None => {}
        }
        i += 1;
    }
    related_acp
}

/// `filter_entries`: the entries the identity may see with this filter.
pub fn filter_entries(
    ctl: &AccessControlsInner,
    ident: &Identity,
    filter_orig: &FilterComp,
    entries: &[Entry],
) -> Result<Vec<Entry>, OperationError> {
    // Get the set of attributes requested by this se filter. This is what we are
    // going to access check.
    let requested_attrs = get_attr_set(filter_orig);

    // NOTE: This is a safety barrier, but queries can't proceed if they have no attributes.
    if requested_attrs.len() == 0 {
        return Ok(Vec::new());
    }

    // First get the set of acps that apply to this receiver
    let related_acp = search_related_acp(ctl, ident, None);

    Ok(filter_entries_loop(ident, &related_acp, &requested_attrs, entries))
}

/// The `entries.into_iter().filter(..).collect()` of `filter_entries`.
pub fn filter_entries_loop(
    ident: &Identity,
    related_acp: &[AccessControlSearchResolved],
    requested_attrs: &[Attribute],
    entries: &[Entry],
) -> Vec<Entry> {
    let mut allowed_entries: Vec<Entry> = Vec::new();
    let mut i = 0;
    while i < entries.len() {
        let e = entries[i].clone();
        let keep = match apply_search_access(ident, related_acp, &e) {
            SearchResult::Deny => false,
            SearchResult::Grant => true,
            // The allow set constrained.
            SearchResult::Allow(allowed_attrs) => is_subset(requested_attrs, &allowed_attrs),
        };
        if keep {
            allowed_entries.push(e);
        }
        i += 1;
    }
    allowed_entries
}

/// `search_filter_entries`.
pub fn search_filter_entries(
    ctl: &AccessControlsInner,
    se: &SearchEvent,
    entries: &[Entry],
) -> Result<Vec<Entry>, OperationError> {
    filter_entries(ctl, &se.ident, &se.filter_orig, entries)
}

/// `search_filter_entry_attributes`: reduce each entry to the attributes
/// the identity may read.
pub fn search_filter_entry_attributes(
    ctl: &AccessControlsInner,
    se: &SearchEvent,
    entries: &[Entry],
) -> Result<Vec<EntryReduced>, OperationError> {
    match &se.ident.origin {
        IdentType::Internal(_) => {
            return Err(OperationError::InvalidState);
        }
        IdentType::Synch(_) => {
            return Err(OperationError::InvalidState);
        }
        IdentType::User(_) => {}
    };

    // `do_effective_check`: the modify and delete profiles, when asked for.
    let modify_related_acp = if se.effective_access_check {
        modify_related_acp(ctl, &se.ident)
    } else {
        Vec::new()
    };
    let delete_related_acp = if se.effective_access_check {
        delete_related_acp(ctl, &se.ident)
    } else {
        Vec::new()
    };

    let attrs = match &se.attrs {
        Some(a) => Some(a),
        None => None,
    };

    // Get the relevant acps for this receiver.
    let search_related_acp = search_related_acp(ctl, &se.ident, attrs);

    Ok(reduce_entries_loop(
        ctl,
        se,
        &search_related_acp,
        &modify_related_acp,
        &delete_related_acp,
        entries,
    ))
}

/// The `entries.into_iter().filter_map(..).collect()` of
/// `search_filter_entry_attributes`.
pub fn reduce_entries_loop(
    ctl: &AccessControlsInner,
    se: &SearchEvent,
    search_related_acp: &[AccessControlSearchResolved],
    modify_related_acp: &[AccessControlModifyResolved],
    delete_related_acp: &[AccessControlDeleteResolved],
    entries: &[Entry],
) -> Vec<EntryReduced> {
    let mut allowed_entries: Vec<EntryReduced> = Vec::new();
    let mut i = 0;
    while i < entries.len() {
        let entry = &entries[i];
        match apply_search_access(&se.ident, search_related_acp, entry) {
            SearchResult::Deny => {}
            SearchResult::Grant => {
                // No properly written access module should allow
                // unbounded attribute read!
            }
            SearchResult::Allow(allowed_attrs) => {
                // Reduce requested by allowed.
                let reduced_attrs = match &se.attrs {
                    Some(requested) => intersection(requested, &allowed_attrs),
                    None => allowed_attrs,
                };

                let effective_permissions = if se.effective_access_check {
                    Some(entry_effective_permission_check(
                        &se.ident,
                        entry,
                        search_related_acp,
                        modify_related_acp,
                        delete_related_acp,
                        &ctl.sync_agreements,
                    ))
                } else {
                    None
                };

                allowed_entries.push(reduce_attributes(entry, &reduced_attrs, effective_permissions));
            }
        }
        i += 1;
    }
    allowed_entries
}

/// `modify_related_acp`.
pub fn modify_related_acp(ctl: &AccessControlsInner, ident: &Identity) -> Vec<AccessControlModifyResolved> {
    let modify_state = &ctl.acps_modify;
    let ident_memberof = get_memberof(ident);

    let mut related_acp: Vec<AccessControlModifyResolved> = Vec::new();
    let mut i = 0;
    while i < modify_state.len() {
        let acs = &modify_state[i];
        match resolve_access_conditions(ident, ident_memberof, &acs.acp.receiver, &acs.acp.target) {
            Some((receiver_condition, target_condition)) => {
                related_acp.push(AccessControlModifyResolved {
                    acp: ModifyGrants {
                        presattrs: acs.presattrs.clone(),
                        remattrs: acs.remattrs.clone(),
                        pres_classes: acs.pres_classes.clone(),
                        rem_classes: acs.rem_classes.clone(),
                    },
                    receiver_condition,
                    target_condition,
                });
            }
            None => {}
        }
        i += 1;
    }
    related_acp
}

/// `modify_allow_operation`.
pub fn modify_allow_operation(
    ctl: &AccessControlsInner,
    me: &ModifyEvent,
    entries: &[Entry],
) -> Result<bool, OperationError> {
    // Find the acps that relate to the caller, and compile their related
    // target filters.
    let related_acp = modify_related_acp(ctl, &me.ident);

    Ok(modify_all_entries(ctl, &me.ident, &related_acp, entries, &me.modlist))
}

/// `entries.iter().all(|e| self.modify_allow_operation_per_entry(..))`.
pub fn modify_all_entries(
    ctl: &AccessControlsInner,
    ident: &Identity,
    related_acp: &[AccessControlModifyResolved],
    entries: &[Entry],
    modlist: &[Modify],
) -> bool {
    let mut i = 0;
    while i < entries.len() {
        if !modify_allow_operation_per_entry(ctl, ident, related_acp, &entries[i], modlist) {
            return false;
        }
        i += 1;
    }
    true
}

/// `me.modset.get(&e.get_uuid())`.
pub fn modset_get(me: &BatchModifyEvent, uuid: Uuid) -> Option<&Vec<Modify>> {
    let mut i = 0;
    while i < me.modset.len() {
        if me.modset[i].uuid == uuid {
            return Some(&me.modset[i].modlist);
        }
        i += 1;
    }
    None
}

/// `batch_modify_allow_operation`.
pub fn batch_modify_allow_operation(
    ctl: &AccessControlsInner,
    me: &BatchModifyEvent,
    entries: &[Entry],
) -> Result<bool, OperationError> {
    let related_acp = modify_related_acp(ctl, &me.ident);

    Ok(batch_modify_all_entries(ctl, me, &related_acp, entries))
}

/// The `entries.iter().all(..)` of `batch_modify_allow_operation`.
pub fn batch_modify_all_entries(
    ctl: &AccessControlsInner,
    me: &BatchModifyEvent,
    related_acp: &[AccessControlModifyResolved],
    entries: &[Entry],
) -> bool {
    let mut i = 0;
    while i < entries.len() {
        let e = &entries[i];
        // Due to how batch mod works, we have to check the modlist *per entry* rather
        // than as a whole.
        let ok = match modset_get(me, e.uuid) {
            Some(modlist) => modify_allow_operation_per_entry(ctl, &me.ident, related_acp, e, modlist),
            None => false,
        };
        if !ok {
            return false;
        }
        i += 1;
    }
    true
}

/// `matches!(m, Modify::Purged(a) if a == Attribute::Class.as_ref())`.
pub fn is_purge_class(m: &Modify) -> bool {
    match m {
        Modify::Purged(a) => crate::bset::bytes_eq(a, b"class"),
        _ => false,
    }
}

/// `modlist.iter().any(|m| matches!(m, Modify::Purged(a) if a == Attribute::Class))`.
pub fn modlist_purges_class(modlist: &[Modify]) -> bool {
    let mut i = 0;
    while i < modlist.len() {
        if is_purge_class(&modlist[i]) {
            return true;
        }
        i += 1;
    }
    false
}

/// `requested_pres`: the attributes `Present`, `Set` and `Assert` touch.
pub fn requested_pres(modlist: &[Modify]) -> Vec<Attribute> {
    let mut out: Vec<Attribute> = Vec::new();
    let mut i = 0;
    while i < modlist.len() {
        match &modlist[i] {
            Modify::Present(a, _) | Modify::Set(a, _) | Modify::Assert(a, _) => crate::bset::insert(&mut out, a),
            Modify::Removed(_, _) | Modify::Purged(_) => {}
        }
        i += 1;
    }
    out
}

/// `requested_rem`: the attributes `Removed`, `Purged` and `Set` touch.
pub fn requested_rem(modlist: &[Modify]) -> Vec<Attribute> {
    let mut out: Vec<Attribute> = Vec::new();
    let mut i = 0;
    while i < modlist.len() {
        match &modlist[i] {
            Modify::Removed(a, _) | Modify::Purged(a) | Modify::Set(a, _) => crate::bset::insert(&mut out, a),
            Modify::Present(_, _) | Modify::Assert(_, _) => {}
        }
        i += 1;
    }
    out
}

/// One step of the loop of `modify_allow_operation_per_entry` that collects
/// the requested classes: the classes `m` adds and removes. `None` is the
/// loop's `return false`.
pub fn modify_class_change(entry: &Entry, m: &Modify) -> Option<(Vec<Vec<u8>>, Vec<Vec<u8>>)> {
    match m {
        Modify::Present(a, v) => {
            let mut pres: Vec<Vec<u8>> = Vec::new();
            if crate::bset::bytes_eq(a, b"class") {
                match to_str(v) {
                    Some(s) => pres.push(s.clone()),
                    None => {}
                }
            }
            Some((pres, Vec::new()))
        }
        Modify::Removed(a, v) => {
            let mut rem: Vec<Vec<u8>> = Vec::new();
            if crate::bset::bytes_eq(a, b"class") {
                match to_str(v) {
                    Some(s) => rem.push(s.clone()),
                    None => {}
                }
            }
            Some((Vec::new(), rem))
        }
        Modify::Set(a, v) => {
            if crate::bset::bytes_eq(a, b"class") {
                // When we apply the set of classes, we base the access control decision
                // only on what CHANGED, rather than the full set that is present.
                match get_ava_as_iutf8(entry, b"class") {
                    Some(current_classes) => match as_iutf8_set(v) {
                        Some(requested) => Some((
                            crate::bset::difference(requested, current_classes),
                            crate::bset::difference(current_classes, requested),
                        )),
                        None => None,
                    },
                    None => None,
                }
            } else {
                Some((Vec::new(), Vec::new()))
            }
        }
        Modify::Purged(_) | Modify::Assert(_, _) => Some((Vec::new(), Vec::new())),
    }
}

/// The loop of `modify_allow_operation_per_entry` that collects the
/// requested present and removed classes. `None` is its `return false`.
pub fn requested_classes(entry: &Entry, modlist: &[Modify]) -> Option<(Vec<Vec<u8>>, Vec<Vec<u8>>)> {
    let mut requested_pres_classes: Vec<Vec<u8>> = Vec::new();
    let mut requested_rem_classes: Vec<Vec<u8>> = Vec::new();
    let mut i = 0;
    while i < modlist.len() {
        match modify_class_change(entry, &modlist[i]) {
            Some((pres, rem)) => {
                extend(&mut requested_pres_classes, &pres);
                extend(&mut requested_rem_classes, &rem);
            }
            None => return None,
        }
        i += 1;
    }
    Some((requested_pres_classes, requested_rem_classes))
}

/// `modify_allow_operation_per_entry`.
pub fn modify_allow_operation_per_entry(
    ctl: &AccessControlsInner,
    ident: &Identity,
    related_acp: &[AccessControlModifyResolved],
    entry: &Entry,
    modlist: &[Modify],
) -> bool {
    let disallow = modlist_purges_class(modlist);

    if disallow {
        return false;
    }

    // build two sets of "requested pres" and "requested rem"
    let requested_pres = requested_pres(modlist);
    let requested_rem = requested_rem(modlist);

    let (requested_pres_classes, requested_rem_classes) = match requested_classes(entry, modlist) {
        Some(c) => c,
        None => return false,
    };

    // You must request *at least* one change. Note that in the case a class
    // is being changed, it must also have at least one pres/rem state also.
    if requested_pres.len() == 0 && requested_rem.len() == 0 {
        return false;
    };

    let sync_agmts = &ctl.sync_agreements;

    match apply_modify_access(ident, related_acp, sync_agmts, entry) {
        ModifyResult::Deny => false,
        ModifyResult::Grant => true,
        ModifyResult::Allow { pres, rem, pres_cls, rem_cls } => {
            let mut decision = true;

            if !is_subset(&requested_pres, &pres) {
                decision = false
            };

            if !is_subset(&requested_rem, &rem) {
                decision = false;
            };

            if !is_subset(&requested_pres_classes, &pres_cls) {
                decision = false;
            };

            if !is_subset(&requested_rem_classes, &rem_cls) {
                decision = false;
            }

            // Yield the result
            decision
        }
    }
}

/// The `create_state.iter().filter_map(..).collect()` of
/// `create_allow_operation`.
pub fn create_related_acp(ctl: &AccessControlsInner, ident: &Identity) -> Vec<AccessControlCreateResolved> {
    let create_state = &ctl.acps_create;
    let ident_memberof = get_memberof(ident);

    let mut related_acp: Vec<AccessControlCreateResolved> = Vec::new();
    let mut i = 0;
    while i < create_state.len() {
        let acs = &create_state[i];
        match resolve_access_conditions(ident, ident_memberof, &acs.acp.receiver, &acs.acp.target) {
            Some((receiver_condition, target_condition)) => {
                related_acp.push(AccessControlCreateResolved {
                    classes: acs.classes.clone(),
                    attrs: acs.attrs.clone(),
                    receiver_condition,
                    target_condition,
                });
            }
            None => {}
        }
        i += 1;
    }
    related_acp
}

/// `create_allow_operation`.
pub fn create_allow_operation(
    ctl: &AccessControlsInner,
    ce: &CreateEvent,
    entries: &[Entry],
) -> Result<bool, OperationError> {
    // Find the acps that relate to the caller.
    let related_acp = create_related_acp(ctl, &ce.ident);

    Ok(create_all_entries(&ce.ident, &related_acp, entries))
}

/// The `entries.iter().all(..)` of `create_allow_operation`.
pub fn create_all_entries(ident: &Identity, related_acp: &[AccessControlCreateResolved], entries: &[Entry]) -> bool {
    let mut i = 0;
    while i < entries.len() {
        if !create_allow_entry(ident, related_acp, &entries[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// The closure of `create_allow_operation`'s `all`.
pub fn create_allow_entry(ident: &Identity, related_acp: &[AccessControlCreateResolved], e: &Entry) -> bool {
    let requested_pres = get_ava_names(e);
    let requested_pres_classes = match get_ava_as_iutf8(e, b"class") {
        Some(set) => set,
        None => {
            return false;
        }
    };

    match apply_create_access(ident, related_acp, e) {
        CreateResult::Deny => false,
        CreateResult::Grant => true,
        CreateResult::Allow { pres, pres_cls } => {
            let mut decision = true;

            if !is_subset(&requested_pres, &pres) {
                decision = false
            };

            if !is_subset(requested_pres_classes, &pres_cls) {
                decision = false;
            };

            decision
        }
    }
}

/// `delete_related_acp`.
pub fn delete_related_acp(ctl: &AccessControlsInner, ident: &Identity) -> Vec<AccessControlDeleteResolved> {
    let delete_state = &ctl.acps_delete;
    let ident_memberof = get_memberof(ident);

    let mut related_acp: Vec<AccessControlDeleteResolved> = Vec::new();
    let mut i = 0;
    while i < delete_state.len() {
        let acs = &delete_state[i];
        match resolve_access_conditions(ident, ident_memberof, &acs.acp.receiver, &acs.acp.target) {
            Some((receiver_condition, target_condition)) => {
                related_acp.push(AccessControlDeleteResolved { receiver_condition, target_condition });
            }
            None => {}
        }
        i += 1;
    }
    related_acp
}

/// `delete_allow_operation`.
pub fn delete_allow_operation(
    ctl: &AccessControlsInner,
    de: &DeleteEvent,
    entries: &[Entry],
) -> Result<bool, OperationError> {
    // Find the acps that relate to the caller.
    let related_acp = delete_related_acp(ctl, &de.ident);

    Ok(delete_all_entries(&de.ident, &related_acp, entries))
}

/// The `entries.iter().all(..)` of `delete_allow_operation`.
pub fn delete_all_entries(ident: &Identity, related_acp: &[AccessControlDeleteResolved], entries: &[Entry]) -> bool {
    let mut i = 0;
    while i < entries.len() {
        match apply_delete_access(ident, related_acp, &entries[i]) {
            DeleteResult::Deny => return false,
            DeleteResult::Grant => {}
        }
        i += 1;
    }
    true
}

/// `effective_permission_check`.
pub fn effective_permission_check(
    ctl: &AccessControlsInner,
    ident: &Identity,
    attrs: Option<&Vec<Attribute>>,
    entries: &[Entry],
) -> Result<Vec<AccessEffectivePermission>, OperationError> {
    // == search ==
    let search_related_acp = search_related_acp(ctl, ident, attrs);
    // == modify ==
    let modify_related_acp = modify_related_acp(ctl, ident);
    // == delete ==
    let delete_related_acp = delete_related_acp(ctl, ident);

    let sync_agmts = &ctl.sync_agreements;

    let mut effective_permissions: Vec<AccessEffectivePermission> = Vec::new();
    let mut i = 0;
    while i < entries.len() {
        effective_permissions.push(entry_effective_permission_check(
            ident,
            &entries[i],
            &search_related_acp,
            &modify_related_acp,
            &delete_related_acp,
            sync_agmts,
        ));
        i += 1;
    }

    Ok(effective_permissions)
}

/// `entry_effective_permission_check`.
pub fn entry_effective_permission_check(
    ident: &Identity,
    entry: &Entry,
    search_related_acp: &[AccessControlSearchResolved],
    modify_related_acp: &[AccessControlModifyResolved],
    delete_related_acp: &[AccessControlDeleteResolved],
    sync_agmts: &[SyncAgreement],
) -> AccessEffectivePermission {
    // == search ==
    let search_effective = match apply_search_access(ident, search_related_acp, entry) {
        SearchResult::Deny => Access::Deny,
        SearchResult::Grant => Access::Grant,
        SearchResult::Allow(allowed_attrs) => Access::Allow(allowed_attrs),
    };

    // == modify ==
    let (modify_pres, modify_rem, modify_pres_class, modify_rem_class) =
        match apply_modify_access(ident, modify_related_acp, sync_agmts, entry) {
            ModifyResult::Deny => (Access::Deny, Access::Deny, AccessClass::Deny, AccessClass::Deny),
            ModifyResult::Grant => (Access::Grant, Access::Grant, AccessClass::Grant, AccessClass::Grant),
            ModifyResult::Allow { pres, rem, pres_cls, rem_cls } => (
                Access::Allow(pres),
                Access::Allow(rem),
                AccessClass::Allow(pres_cls),
                AccessClass::Allow(rem_cls),
            ),
        };

    // == delete ==
    let delete_status = apply_delete_access(ident, delete_related_acp, entry);

    let delete = match delete_status {
        DeleteResult::Deny => false,
        DeleteResult::Grant => true,
    };

    AccessEffectivePermission {
        ident: get_uuid(ident),
        target: entry.uuid,
        delete,
        search: search_effective,
        modify_pres,
        modify_rem,
        modify_pres_class,
        modify_rem_class,
    }
}
