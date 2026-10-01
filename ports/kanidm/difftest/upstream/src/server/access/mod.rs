// Stub head of `server/access/mod.rs`: the uses and module declarations of
// upstream's, without the cache and SCIM types. The items below are copied.
use hashbrown::HashMap;
use std::{collections::BTreeSet, sync::Arc};

use uuid::Uuid;

use crate::{
    entry::{Entry, EntryInit, EntryNew},
    event::{CreateEvent, DeleteEvent, ModifyEvent, SearchEvent},
    filter::{Filter, FilterValid, ResolveFilterCacheReadTxn},
    modify::Modify,
    prelude::*,
};

use self::profiles::{
    AccessControlCreate, AccessControlCreateResolved, AccessControlDelete,
    AccessControlDeleteResolved, AccessControlModify, AccessControlModifyResolved,
    AccessControlReceiver, AccessControlReceiverCondition, AccessControlSearch,
    AccessControlSearchResolved, AccessControlTarget, AccessControlTargetCondition,
};

use self::{
    create::{apply_create_access, CreateResult},
    delete::{apply_delete_access, DeleteResult},
    modify::{apply_modify_access, ModifyResult},
    search::{apply_search_access, SearchResult},
};

mod create;
mod delete;
mod migration;
mod modify;
pub mod profiles;
mod protected;
mod search;

// Copied from kanidm/kanidm @ f608c4f by extract_upstream.py. Do not edit.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Access {
    Grant,
    Deny,
    Allow(BTreeSet<Attribute>),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum AccessClass {
    Grant,
    Deny,
    Allow(BTreeSet<AttrString>),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AccessEffectivePermission {
    /// Who the access applies to
    pub ident: Uuid,
    /// The target the access affects
    pub target: Uuid,
    pub delete: bool,
    pub search: Access,
    pub modify_pres: Access,
    pub modify_rem: Access,
    pub modify_pres_class: AccessClass,
    pub modify_rem_class: AccessClass,
}

pub enum AccessBasicResult {
    // Deny this operation unconditionally.
    Deny,
    // Unbounded allow, provided no deny state exists.
    Grant,
    // This module makes no decisions about this entry.
    Ignore,
}

pub enum AccessSrchResult {
    // Deny this operation unconditionally.
    Deny,
    // Unbounded allow, provided no deny state exists.
    Grant,
    // This module makes no decisions about this entry.
    Ignore,
    // Limit the allowed attr set to this - this doesn't
    // allow anything, it constrains what might be allowed
    // by a later module.
    /*
    Constrain {
        attr: BTreeSet<Attribute>,
    },
    */
    Allow { attr: BTreeSet<Attribute> },
}

pub enum AccessModResult<'a> {
    // Deny this operation unconditionally.
    Deny,
    // Unbounded allow, provided no deny state exists.
    // Grant,
    // This module makes no decisions about this entry.
    Ignore,
    // Limit the allowed attr set to this - this doesn't
    // allow anything, it constrains what might be allowed
    // by a later module.
    Constrain {
        pres_attr: BTreeSet<Attribute>,
        rem_attr: BTreeSet<Attribute>,
        pres_cls: Option<BTreeSet<&'a str>>,
        rem_cls: Option<BTreeSet<&'a str>>,
    },
    // Allow these modifications within constraints.
    Allow {
        pres_attr: BTreeSet<Attribute>,
        rem_attr: BTreeSet<Attribute>,
        pres_class: BTreeSet<&'a str>,
        rem_class: BTreeSet<&'a str>,
    },
}

#[derive(Clone)]
struct AccessControlsInner {
    acps_search: Vec<AccessControlSearch>,
    acps_create: Vec<AccessControlCreate>,
    acps_modify: Vec<AccessControlModify>,
    acps_delete: Vec<AccessControlDelete>,
    sync_agreements: HashMap<Uuid, BTreeSet<Attribute>>,
    // Oauth2
    // Sync prov
}

fn resolve_access_conditions(
    ident: &Identity,
    ident_memberof: Option<&BTreeSet<Uuid>>,
    receiver: &AccessControlReceiver,
    target: &AccessControlTarget,
    acp_resolve_filter_cache: &mut ResolveFilterCacheReadTxn<'_>,
) -> Option<(AccessControlReceiverCondition, AccessControlTargetCondition)> {
    let receiver_condition = match receiver {
        AccessControlReceiver::Group(groups) => {
            let group_check = ident_memberof
                // Have at least one group allowed.
                .map(|imo| {
                    trace!(?imo, ?groups);
                    imo.intersection(groups).next().is_some()
                })
                .unwrap_or_default();

            if group_check {
                AccessControlReceiverCondition::GroupChecked
            } else {
                // AccessControlReceiverCondition::None
                return None;
            }
        }
        AccessControlReceiver::EntryManager => AccessControlReceiverCondition::EntryManager,
        AccessControlReceiver::None => return None,
        // AccessControlReceiverCondition::None,
    };

    let target_condition = match &target {
        AccessControlTarget::Scope(filter) => filter
            .resolve(ident, None, Some(acp_resolve_filter_cache))
            .map_err(|e| {
                admin_error!(?e, "A internal filter/event was passed for resolution!?!?");
                e
            })
            .ok()
            .map(AccessControlTargetCondition::Scope)?,
        AccessControlTarget::None => return None,
    };

    Some((receiver_condition, target_condition))
}

pub trait AccessControlsTransaction<'a> {
    fn get_search(&self) -> &Vec<AccessControlSearch>;
    fn get_create(&self) -> &Vec<AccessControlCreate>;
    fn get_modify(&self) -> &Vec<AccessControlModify>;
    fn get_delete(&self) -> &Vec<AccessControlDelete>;
    fn get_sync_agreements(&self) -> &HashMap<Uuid, BTreeSet<Attribute>>;

    #[allow(clippy::mut_from_ref)]
    fn get_acp_resolve_filter_cache(&self) -> &mut ResolveFilterCacheReadTxn<'a>;

    #[instrument(level = "trace", name = "access::search_related_acp", skip_all)]
    fn search_related_acp<'b>(
        &'b self,
        ident: &Identity,
        attrs: Option<&BTreeSet<Attribute>>,
    ) -> Vec<AccessControlSearchResolved<'b>> {
        let search_state = self.get_search();
        let acp_resolve_filter_cache = self.get_acp_resolve_filter_cache();

        // ⚠️  WARNING ⚠️  -- Why is this cache commented out?
        //
        // The reason for this is that to determine what acps relate, we need to be
        // aware of session claims - since these can change session to session, we
        // would need the cache to be structured to handle this. It's much better
        // in a search to just lean on the filter resolve cache because of this
        // dynamic behaviour.
        //
        // It may be possible to do per-operation caching when we know that we will
        // perform the reduce step, but it may not be worth it. It's probably better
        // to make entry_match_no_index faster.

        /*
        if let Some(acs_uuids) = acp_related_search_cache.get(rec_entry.get_uuid()) {
            lperf_trace_segment!( "access::search_related_acp<cached>", || {
                // If we have a cache, we should look here first for all the uuids that match

                // could this be a better algo?
                search_state
                    .iter()
                    .filter(|acs| acs_uuids.binary_search(&acs.acp.uuid).is_ok())
                    .collect()
            })
        } else {
        */
        // else, we calculate this, and then stash/cache the uuids.

        let ident_memberof = ident.get_memberof();

        // let related_acp: Vec<(&AccessControlSearch, Filter<FilterValidResolved>)> =
        let related_acp: Vec<AccessControlSearchResolved<'b>> = search_state
            .iter()
            .filter_map(|acs| {
                // Now resolve the receiver filter
                // Okay, so in filter resolution, the primary error case
                // is that we have a non-user in the event. We have already
                // checked for this above BUT we should still check here
                // properly just in case.
                //
                // In this case, we assume that if the event is internal
                // that the receiver can NOT match because it has no selfuuid
                // and can as a result, never return true. This leads to this
                // acp not being considered in that case ... which should never
                // happen because we already bypassed internal ops above!
                //
                // A possible solution is to change the filter resolve function
                // such that it takes an entry, rather than an event, but that
                // would create issues in search.
                let (receiver_condition, target_condition) = resolve_access_conditions(
                    ident,
                    ident_memberof,
                    &acs.acp.receiver,
                    &acs.acp.target,
                    acp_resolve_filter_cache,
                )?;

                Some(AccessControlSearchResolved {
                    acp: acs,
                    receiver_condition,
                    target_condition,
                })
            })
            .collect();

        // Trim any search rule that doesn't provide attributes related to the request.
        let related_acp = if let Some(r_attrs) = attrs.as_ref() {
            related_acp
                .into_iter()
                .filter(|acs| !acs.acp.attrs.is_disjoint(r_attrs))
                .collect()
        } else {
            // None here means all attrs requested.
            related_acp
        };

        related_acp
    }

    #[instrument(level = "debug", name = "access::filter_entries", skip_all)]
    fn filter_entries(
        &self,
        ident: &Identity,
        filter_orig: &Filter<FilterValid>,
        entries: Vec<Arc<EntrySealedCommitted>>,
    ) -> Result<Vec<Arc<EntrySealedCommitted>>, OperationError> {
        // Prepare some shared resources.

        // Get the set of attributes requested by this se filter. This is what we are
        // going to access check.
        let requested_attrs: BTreeSet<Attribute> = filter_orig.get_attr_set();

        // NOTE: This is a safety barrier, but queries can't proceed if they have no attributes.
        if requested_attrs.is_empty() {
            security_access!("denied ❌ - no attributes were requested in search, denying all entries from release");
            return Ok(Vec::with_capacity(0));
        }

        // First get the set of acps that apply to this receiver
        let related_acp = self.search_related_acp(ident, None);

        // For each entry.
        let entries_is_empty = entries.is_empty();
        let allowed_entries: Vec<_> = entries
            .into_iter()
            .filter(|e| {
                match apply_search_access(ident, related_acp.as_slice(), e) {
                    SearchResult::Deny => false,
                    SearchResult::Grant => true,
                    SearchResult::Allow(allowed_attrs) => {
                        // The allow set constrained.
                        let decision = requested_attrs.is_subset(&allowed_attrs);
                        security_debug!(
                            ?decision,
                            allowed = ?allowed_attrs,
                            requested = ?requested_attrs,
                            "search attribute decision",
                        );
                        decision
                    }
                }
            })
            .collect();

        if allowed_entries.is_empty() {
            if !entries_is_empty {
                security_access!("denied ❌ - no entries were released");
            }
        } else {
            debug!("allowed search of {} entries ✅", allowed_entries.len());
        }

        Ok(allowed_entries)
    }

    // Contains all the way to eval acps to entries
    #[inline(always)]
    fn search_filter_entries(
        &self,
        se: &SearchEvent,
        entries: Vec<Arc<EntrySealedCommitted>>,
    ) -> Result<Vec<Arc<EntrySealedCommitted>>, OperationError> {
        self.filter_entries(&se.ident, &se.filter_orig, entries)
    }

    #[instrument(
        level = "debug",
        name = "access::search_filter_entry_attributes",
        skip_all
    )]
    fn search_filter_entry_attributes(
        &self,
        se: &SearchEvent,
        entries: Vec<Arc<EntrySealedCommitted>>,
    ) -> Result<Vec<EntryReducedCommitted>, OperationError> {
        struct DoEffectiveCheck<'b> {
            modify_related_acp: Vec<AccessControlModifyResolved<'b>>,
            delete_related_acp: Vec<AccessControlDeleteResolved<'b>>,
            sync_agmts: &'b HashMap<Uuid, BTreeSet<Attribute>>,
        }

        match &se.ident.origin {
            IdentType::Internal(_) => {
                // In production we can't risk leaking data here, so we return
                // empty sets.
                security_critical!("IMPOSSIBLE STATE: Internal search in external interface?! Returning empty for safety.");
                // No need to check ACS
                return Err(OperationError::InvalidState);
            }
            IdentType::Synch(_) => {
                security_critical!("Blocking sync check");
                return Err(OperationError::InvalidState);
            }
            IdentType::User(u) => u.entry.get_uuid(),
        };

        // Build a reference set from the req_attrs. This is what we test against
        // to see if the attribute is something we currently want.

        let do_effective_check = se.effective_access_check.then(|| {
            debug!("effective permission check requested during reduction phase");

            // == modify ==
            let modify_related_acp = self.modify_related_acp(&se.ident);
            // == delete ==
            let delete_related_acp = self.delete_related_acp(&se.ident);

            let sync_agmts = self.get_sync_agreements();

            DoEffectiveCheck {
                modify_related_acp,
                delete_related_acp,
                sync_agmts,
            }
        });

        // Get the relevant acps for this receiver.
        let search_related_acp = self.search_related_acp(&se.ident, se.attrs.as_ref());

        // For each entry.
        let entries_is_empty = entries.is_empty();
        let allowed_entries: Vec<_> = entries
            .into_iter()
            .filter_map(|entry| {
                match apply_search_access(&se.ident, &search_related_acp, &entry) {
                    SearchResult::Deny => {
                        None
                    }
                    SearchResult::Grant => {
                        // No properly written access module should allow
                        // unbounded attribute read!
                        error!("An access module allowed full read, this is a BUG! Denying read to prevent data leaks.");
                        None
                    }
                    SearchResult::Allow(allowed_attrs) => {
                        // The allow set constrained.
                        debug!(
                            requested = ?se.attrs,
                            allowed = ?allowed_attrs,
                            "reduction",
                        );

                        // Reduce requested by allowed.
                        let reduced_attrs = if let Some(requested) = se.attrs.as_ref() {
                            requested & &allowed_attrs
                        } else {
                            allowed_attrs
                        };

                        let effective_permissions = do_effective_check.as_ref().map(|do_check| {
                            self.entry_effective_permission_check(
                                &se.ident,
                                &entry,
                                &search_related_acp,
                                &do_check.modify_related_acp,
                                &do_check.delete_related_acp,
                                do_check.sync_agmts,
                            )
                        })
                        .map(Box::new);

                        Some(entry.reduce_attributes(&reduced_attrs, effective_permissions))
                    }
                }

                // End filter
            })
            .collect();

        if allowed_entries.is_empty() {
            if !entries_is_empty {
                security_access!("reduced to empty set on all entries ❌");
            }
        } else {
            debug!(
                "attribute set reduced on {} entries ✅",
                allowed_entries.len()
            );
        }

        Ok(allowed_entries)
    }

    #[instrument(level = "trace", name = "access::modify_related_acp", skip_all)]
    fn modify_related_acp<'b>(&'b self, ident: &Identity) -> Vec<AccessControlModifyResolved<'b>> {
        // Some useful references we'll use for the remainder of the operation
        let modify_state = self.get_modify();
        let acp_resolve_filter_cache = self.get_acp_resolve_filter_cache();

        let ident_memberof = ident.get_memberof();

        // Find the acps that relate to the caller, and compile their related
        // target filters.
        let related_acp: Vec<_> = modify_state
            .iter()
            .filter_map(|acs| {
                trace!(acs_name = ?acs.acp.name);
                let (receiver_condition, target_condition) = resolve_access_conditions(
                    ident,
                    ident_memberof,
                    &acs.acp.receiver,
                    &acs.acp.target,
                    acp_resolve_filter_cache,
                )?;

                Some(AccessControlModifyResolved {
                    acp: acs,
                    receiver_condition,
                    target_condition,
                })
            })
            .collect();

        related_acp
    }

    #[instrument(level = "debug", name = "access::modify_allow_operation", skip_all)]
    fn modify_allow_operation(
        &self,
        me: &ModifyEvent,
        entries: &[Arc<EntrySealedCommitted>],
    ) -> Result<bool, OperationError> {
        // Find the acps that relate to the caller, and compile their related
        // target filters.
        let related_acp: Vec<_> = self.modify_related_acp(&me.ident);

        let r = entries.iter().all(|e| {
            self.modify_allow_operation_per_entry(&me.ident, &related_acp, e, &me.modlist)
        });

        if r {
            debug!("allowed modify of {} entries ✅", entries.len());
        } else {
            security_access!("denied ❌ - modify may not proceed");
        }
        Ok(r)
    }

    #[instrument(
        level = "debug",
        name = "access::batch_modify_allow_operation",
        skip_all
    )]
    fn batch_modify_allow_operation(
        &self,
        me: &BatchModifyEvent,
        entries: &[Arc<EntrySealedCommitted>],
    ) -> Result<bool, OperationError> {
        // Find the acps that relate to the caller, and compile their related
        // target filters.
        let related_acp = self.modify_related_acp(&me.ident);

        let r = entries.iter().all(|e| {
            // Due to how batch mod works, we have to check the modlist *per entry* rather
            // than as a whole.

            let Some(modlist) = me.modset.get(&e.get_uuid()) else {
                security_access!(
                    "modlist not present for {}, failing operation.",
                    e.get_uuid()
                );
                return false;
            };

            self.modify_allow_operation_per_entry(&me.ident, &related_acp, e, modlist)
        });

        if r {
            debug!("allowed modify of {} entries ✅", entries.len());
        } else {
            security_access!("denied ❌ - modifications may not proceed");
        }
        Ok(r)
    }

    fn modify_allow_operation_per_entry(
        &self,
        ident: &Identity,
        related_acp: &[AccessControlModifyResolved<'_>],
        entry: &Arc<EntrySealedCommitted>,
        modlist: &ModifyList<ModifyValid>,
    ) -> bool {
        let disallow = modlist
            .iter()
            .any(|m| matches!(m, Modify::Purged(a) if a == Attribute::Class.as_ref()));

        if disallow {
            security_access!("Disallowing purge in modification");
            return false;
        }

        // build two sets of "requested pres" and "requested rem"
        let requested_pres: BTreeSet<Attribute> = modlist
            .iter()
            .filter_map(|m| match m {
                Modify::Present(a, _) | Modify::Set(a, _) | Modify::Assert(a, _) => Some(a.clone()),
                Modify::Removed(_, _) | Modify::Purged(_) => None,
            })
            .collect();

        let requested_rem: BTreeSet<Attribute> = modlist
            .iter()
            .filter_map(|m| match m {
                Modify::Removed(a, _) | Modify::Purged(a) | Modify::Set(a, _) => Some(a.clone()),
                Modify::Present(_, _) | Modify::Assert(_, _) => None,
            })
            .collect();

        let mut requested_pres_classes: BTreeSet<&str> = Default::default();
        let mut requested_rem_classes: BTreeSet<&str> = Default::default();

        // This loop extracts what classes have been requested for modification so that we can
        // apply our modify class rules.
        for modify in modlist.iter() {
            match modify {
                Modify::Present(a, v) if a == Attribute::Class.as_ref() => {
                    requested_pres_classes.extend(v.to_str())
                }
                Modify::Removed(a, v) if a == Attribute::Class.as_ref() => {
                    requested_rem_classes.extend(v.to_str())
                }
                Modify::Set(a, v) if a == Attribute::Class.as_ref() => {
                    // When we apply the set of classes, we base the access control decision
                    // only on what CHANGED, rather than the full set that is present.
                    if let Some(current_classes) = entry.get_ava_as_iutf8(Attribute::Class) {
                        if let Some(requested_classes) = v.as_iutf8_set() {
                            // Diff the classes to determine what changed. We only perform access
                            // checks on what is different, rather than everything in the set. This
                            // is what allow's SCIM PUT to operate since you have to "set" every
                            // value in the set, even if it's not one you have access too.
                            requested_pres_classes.extend(
                                requested_classes
                                    .difference(current_classes)
                                    .map(|s| s.as_str()),
                            );
                            requested_rem_classes.extend(
                                current_classes
                                    .difference(requested_classes)
                                    .map(|s| s.as_str()),
                            );
                        } else {
                            // This should be an impossible case - to have made it to this
                            // point, then the modify should have passed schema validation
                            // an must be a valid iutf8 set, and return a Some(). However
                            // in the interest of completeness, we defend from this and
                            // and deny the operation.
                            error!("invalid valueset state - requested class set is not valid");
                            return false;
                        }
                    } else {
                        error!("invalid entry state - entry does not have attribute class and is not valid");
                        return false;
                    }
                }
                // No attribute::class present.
                Modify::Set(_, _) | Modify::Removed(_, _) | Modify::Present(_, _) => {}
                // Actions don't relate to gathering of classes for modification checks
                Modify::Purged(_) | Modify::Assert(_, _) => {}
            }
        }

        debug!(?requested_pres, "Requested present set");
        debug!(?requested_rem, "Requested remove set");
        debug!(?requested_pres_classes, "Requested present class set");
        debug!(?requested_rem_classes, "Requested remove class set");
        debug!(entry_id = %entry.get_display_id());

        // You must request *at least* one change. Note that in the case a class
        // is being changed, it must also have at least one pres/rem state also.
        if requested_pres.is_empty() && requested_rem.is_empty() {
            security_error!("No modifications were requested");
            return false;
        };

        let sync_agmts = self.get_sync_agreements();

        match apply_modify_access(ident, related_acp, sync_agmts, entry) {
            ModifyResult::Deny => {
                security_error!("modify access denied.");
                false
            }
            ModifyResult::Grant => true,
            ModifyResult::Allow {
                pres,
                rem,
                pres_cls,
                rem_cls,
            } => {
                let mut decision = true;

                if !requested_pres.is_subset(&pres) {
                    security_error!("requested_pres is not a subset of allowed");
                    security_error!(
                        "requested_pres: {:?} !⊆ allowed: {:?}",
                        requested_pres,
                        pres
                    );
                    decision = false
                };

                if !requested_rem.is_subset(&rem) {
                    security_error!("requested_rem is not a subset of allowed");
                    security_error!("requested_rem: {:?} !⊆ allowed: {:?}", requested_rem, rem);
                    decision = false;
                };

                if !requested_pres_classes.is_subset(&pres_cls) {
                    security_error!("requested_pres_classes is not a subset of allowed");
                    security_error!(
                        "requested_classes: {:?} !⊆ allowed: {:?}",
                        requested_pres_classes,
                        pres_cls
                    );
                    decision = false;
                };

                if !requested_rem_classes.is_subset(&rem_cls) {
                    security_error!("requested_rem_classes is not a subset of allowed");
                    security_error!(
                        "requested_classes: {:?} !⊆ allowed: {:?}",
                        requested_rem_classes,
                        rem_cls
                    );
                    decision = false;
                }

                if decision {
                    debug!("passed pres, rem, classes check.");
                }

                // Yield the result
                decision
            }
        }
    }

    #[instrument(level = "debug", name = "access::create_allow_operation", skip_all)]
    fn create_allow_operation(
        &self,
        ce: &CreateEvent,
        entries: &[Entry<EntryInit, EntryNew>],
    ) -> Result<bool, OperationError> {
        // Some useful references we'll use for the remainder of the operation
        let create_state = self.get_create();
        let acp_resolve_filter_cache = self.get_acp_resolve_filter_cache();

        let ident_memberof = ce.ident.get_memberof();

        // Find the acps that relate to the caller.
        let related_acp: Vec<_> = create_state
            .iter()
            .filter_map(|acs| {
                let (receiver_condition, target_condition) = resolve_access_conditions(
                    &ce.ident,
                    ident_memberof,
                    &acs.acp.receiver,
                    &acs.acp.target,
                    acp_resolve_filter_cache,
                )?;

                Some(AccessControlCreateResolved {
                    acp: acs,
                    receiver_condition,
                    target_condition,
                })
            })
            .collect();

        // For each entry
        let decision = entries.iter().all(|e| {
            let requested_pres: BTreeSet<_> = e.attr_keys().cloned().collect();
            let Some(requested_pres_classes) = e
                .get_ava_as_iutf8(Attribute::Class)
                .map(|set| set.iter().map(|s| s.as_str()).collect::<BTreeSet<_>>())
            else {
                error!("unable to perform access control checks on entry with no classes, denied.");
                return false;
            };

            debug!(?requested_pres, "Requested present set");
            debug!(?requested_pres_classes, "Requested present class set");
            debug!(entry_id = %e.get_display_id());

            match apply_create_access(&ce.ident, related_acp.as_slice(), e) {
                CreateResult::Deny => false,
                CreateResult::Grant => true,
                CreateResult::Allow { pres, pres_cls } => {
                    let mut decision = true;

                    if !requested_pres.is_subset(&pres) {
                        security_error!("requested_pres is not a subset of allowed");
                        security_error!(
                            "requested_pres: {:?} !⊆ allowed: {:?}",
                            requested_pres,
                            pres
                        );
                        decision = false
                    };

                    if !requested_pres_classes.is_subset(&pres_cls) {
                        security_error!("requested_pres_classes is not a subset of allowed");
                        security_error!(
                            "requested_classes: {:?} !⊆ allowed: {:?}",
                            requested_pres_classes,
                            pres_cls
                        );
                        decision = false;
                    };

                    if decision {
                        debug!("passed pres, classes check.");
                    }

                    decision
                }
            }
        });

        if decision {
            debug!("allowed create of {} entries ✅", entries.len());
        } else {
            security_access!("denied ❌ - create may not proceed");
        }

        Ok(decision)
    }

    #[instrument(level = "trace", name = "access::delete_related_acp", skip_all)]
    fn delete_related_acp<'b>(&'b self, ident: &Identity) -> Vec<AccessControlDeleteResolved<'b>> {
        // Some useful references we'll use for the remainder of the operation
        let delete_state = self.get_delete();
        let acp_resolve_filter_cache = self.get_acp_resolve_filter_cache();

        let ident_memberof = ident.get_memberof();

        let related_acp: Vec<_> = delete_state
            .iter()
            .filter_map(|acs| {
                let (receiver_condition, target_condition) = resolve_access_conditions(
                    ident,
                    ident_memberof,
                    &acs.acp.receiver,
                    &acs.acp.target,
                    acp_resolve_filter_cache,
                )?;

                Some(AccessControlDeleteResolved {
                    acp: acs,
                    receiver_condition,
                    target_condition,
                })
            })
            .collect();

        related_acp
    }

    #[instrument(level = "debug", name = "access::delete_allow_operation", skip_all)]
    fn delete_allow_operation(
        &self,
        de: &DeleteEvent,
        entries: &[Arc<EntrySealedCommitted>],
    ) -> Result<bool, OperationError> {
        // Find the acps that relate to the caller.
        let related_acp = self.delete_related_acp(&de.ident);

        // For each entry
        let r = entries.iter().all(|e| {
            match apply_delete_access(&de.ident, related_acp.as_slice(), e) {
                DeleteResult::Deny => false,
                DeleteResult::Grant => true,
            }
        });
        if r {
            debug!("allowed delete of {} entries ✅", entries.len());
        } else {
            security_access!("denied ❌ - delete may not proceed");
        }
        Ok(r)
    }

    #[instrument(level = "debug", name = "access::effective_permission_check", skip_all)]
    fn effective_permission_check(
        &self,
        ident: &Identity,
        attrs: Option<BTreeSet<Attribute>>,
        entries: &[Arc<EntrySealedCommitted>],
    ) -> Result<Vec<AccessEffectivePermission>, OperationError> {
        // I think we need a structure like CheckResult, which is in the order of the
        // entries, but also stashes the uuid. Then it has search, mod, create, delete,
        // as separate attrs to describe what is capable.

        // Does create make sense here? I don't think it does. Create requires you to
        // have an entry template. I think james was right about the create being
        // a template copy op ...

        trace!(ident = %ident, "Effective permission check");
        // I think we separate this to multiple checks ...?

        // == search ==
        // Get the relevant acps for this receiver.
        let search_related_acp = self.search_related_acp(ident, attrs.as_ref());
        // == modify ==
        let modify_related_acp = self.modify_related_acp(ident);
        // == delete ==
        let delete_related_acp = self.delete_related_acp(ident);

        let sync_agmts = self.get_sync_agreements();

        let effective_permissions: Vec<_> = entries
            .iter()
            .map(|entry| {
                self.entry_effective_permission_check(
                    ident,
                    entry,
                    &search_related_acp,
                    &modify_related_acp,
                    &delete_related_acp,
                    sync_agmts,
                )
            })
            .collect();

        effective_permissions.iter().for_each(|ep| {
            trace!(?ep);
        });

        Ok(effective_permissions)
    }

    fn entry_effective_permission_check<'b>(
        &'b self,
        ident: &Identity,
        entry: &Arc<EntrySealedCommitted>,
        search_related_acp: &[AccessControlSearchResolved<'b>],
        modify_related_acp: &[AccessControlModifyResolved<'b>],
        delete_related_acp: &[AccessControlDeleteResolved<'b>],
        sync_agmts: &HashMap<Uuid, BTreeSet<Attribute>>,
    ) -> AccessEffectivePermission {
        // == search ==
        let search_effective = match apply_search_access(ident, search_related_acp, entry) {
            SearchResult::Deny => Access::Deny,
            SearchResult::Grant => Access::Grant,
            SearchResult::Allow(allowed_attrs) => {
                // Bound by requested attrs?
                Access::Allow(allowed_attrs.into_iter().collect())
            }
        };

        // == modify ==
        let (modify_pres, modify_rem, modify_pres_class, modify_rem_class) =
            match apply_modify_access(ident, modify_related_acp, sync_agmts, entry) {
                ModifyResult::Deny => (
                    Access::Deny,
                    Access::Deny,
                    AccessClass::Deny,
                    AccessClass::Deny,
                ),
                ModifyResult::Grant => (
                    Access::Grant,
                    Access::Grant,
                    AccessClass::Grant,
                    AccessClass::Grant,
                ),
                ModifyResult::Allow {
                    pres,
                    rem,
                    pres_cls,
                    rem_cls,
                } => (
                    Access::Allow(pres.into_iter().collect()),
                    Access::Allow(rem.into_iter().collect()),
                    AccessClass::Allow(pres_cls.into_iter().map(|s| s.into()).collect()),
                    AccessClass::Allow(rem_cls.into_iter().map(|s| s.into()).collect()),
                ),
            };

        // == delete ==
        let delete_status = apply_delete_access(ident, delete_related_acp, entry);

        let delete = match delete_status {
            DeleteResult::Deny => false,
            DeleteResult::Grant => true,
        };

        AccessEffectivePermission {
            ident: ident.get_uuid(),
            target: entry.get_uuid(),
            delete,
            search: search_effective,
            modify_pres,
            modify_rem,
            modify_pres_class,
            modify_rem_class,
        }
    }
}

// ---- Test seam (not upstream): a transaction over given profiles. ----

pub struct DifftestAccessControls {
    inner: AccessControlsInner,
}

impl DifftestAccessControls {
    pub fn new(
        acps_search: Vec<AccessControlSearch>,
        acps_create: Vec<AccessControlCreate>,
        acps_modify: Vec<AccessControlModify>,
        acps_delete: Vec<AccessControlDelete>,
        sync_agreements: Vec<(Uuid, BTreeSet<Attribute>)>,
    ) -> Self {
        let sync_agreements: HashMap<Uuid, BTreeSet<Attribute>> = sync_agreements.into_iter().collect();
        DifftestAccessControls {
            inner: AccessControlsInner {
                acps_search,
                acps_create,
                acps_modify,
                acps_delete,
                sync_agreements,
            },
        }
    }
}

impl<'a> AccessControlsTransaction<'a> for DifftestAccessControls {
    fn get_search(&self) -> &Vec<AccessControlSearch> {
        &self.inner.acps_search
    }

    fn get_create(&self) -> &Vec<AccessControlCreate> {
        &self.inner.acps_create
    }

    fn get_modify(&self) -> &Vec<AccessControlModify> {
        &self.inner.acps_modify
    }

    fn get_delete(&self) -> &Vec<AccessControlDelete> {
        &self.inner.acps_delete
    }

    fn get_sync_agreements(&self) -> &HashMap<Uuid, BTreeSet<Attribute>> {
        &self.inner.sync_agreements
    }

    fn get_acp_resolve_filter_cache(&self) -> &mut ResolveFilterCacheReadTxn<'a> {
        Box::leak(Box::default())
    }
}
