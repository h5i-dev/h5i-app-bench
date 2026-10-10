import Verified.KanidmSynchroniseSeesNothing
import Verified.KanidmReadonlyCannotModify
import Verified.KanidmDeleteProtected
import Spec
open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec

namespace kanidm_kernel.Properties

/-! ## Deny overrides allow -/

/-- When the protection rules deny a modification, no profile can allow it. -/
theorem protected_deny_overrides_modify (ident : Identity)
    (related : Slice profiles.AccessControlModifyResolved) (sa : Slice SyncAgreement) (e : Entry)
    (h : modify_acc.modify_protected_attrs ident e = ok .Deny) :
    modify_acc.apply_modify_access ident related sa e = ok .Deny := by
  sorry

/-- When the protection rules deny a create, no profile can allow it. -/
theorem protected_deny_overrides_create (ident : Identity)
    (related : Slice profiles.AccessControlCreateResolved) (e : Entry)
    (h : create_acc.protected_filter_entry ident e = ok .Deny) :
    create_acc.apply_create_access ident related e = ok .Deny := by
  sorry

/-! ## Search -/

/-- Every attribute a search returns on an entry is granted on that entry by a
search profile that applies to the caller, or is one of the few attributes
the OAuth2, application and sync-account rules release. -/
theorem search_attrs_granted (ctl : AccessControlsInner) (se : SearchEvent) (es : Slice Entry)
    (rs : alloc.vec.Vec EntryReduced) (r : EntryReduced) (x : Ava)
    (h : access.search_filter_entry_attributes ctl se es = ok (.Ok rs))
    (hr : r ∈ rs.val) (hx : x ∈ r.attrs.val) :
    ∃ e ∈ es.val, e.uuid = r.uuid ∧ x ∈ e.attrs.val ∧ SearchGrants ctl se.ident e (nats x.attr.val) := by
  sorry

/-- The anonymous user gets nothing from the OAuth2 and application rules: what
it may read comes from the profiles alone. -/
theorem anonymous_reads_by_profile_only (ident : Identity) (u : IdentUser)
    (related : Slice profiles.AccessControlSearchResolved) (e : Entry)
    (attrs : alloc.vec.Vec (alloc.vec.Vec U8)) (x : alloc.vec.Vec U8)
    (hu : ident.origin = .User u) (ha : u.entry.uuid = UUID_ANONYMOUS)
    (hs : ¬ HasClass u.entry "sync_object")
    (h : search_acc.apply_search_access ident related e = ok (.Allow attrs)) (hx : x ∈ attrs.val) :
    ∃ acs ∈ related.val, x ∈ acs.attrs.val := by
  sorry

/-- A sync agreement, or a user session scoped to synchronisation, sees no
entries. -/
theorem synchronise_sees_nothing (ctl : AccessControlsInner) (ident : Identity) (f : FilterComp)
    (es : Slice Entry) (out : alloc.vec.Vec Entry)
    (hs : (IsUser ident ∧ ident.scope = .Synchronise) ∨ ∃ s, ident.origin = .Synch s)
    (h : access.filter_entries ctl ident f es = ok (.Ok out)) :
    out.val = [] := by
  apply kanidm_kernel.Verified.KanidmSynchroniseSeesNothing.synchronise_sees_nothing <;> assumption

/-! ## Write operations need a profile -/

/-- A user session that is not read-write modifies nothing. -/
theorem readonly_cannot_modify (ctl : AccessControlsInner) (me : ModifyEvent) (es : Slice Entry) (b : Bool)
    (hu : IsUser me.ident) (hs : me.ident.scope ≠ .ReadWrite) (hne : es.val ≠ [])
    (h : access.modify_allow_operation ctl me es = ok (.Ok b)) :
    b = false := by
  apply kanidm_kernel.Verified.KanidmReadonlyCannotModify.readonly_cannot_modify <;> assumption

/-- A user deletes an entry only through a delete profile that applies to it. -/
theorem delete_needs_profile (ctl : AccessControlsInner) (de : DeleteEvent) (es : Slice Entry) (e : Entry)
    (hu : IsUser de.ident) (h : access.delete_allow_operation ctl de es = ok (.Ok true)) (he : e ∈ es.val) :
    ∃ acd ∈ ctl.acps_delete.val, Applies de.ident acd.acp e := by
  sorry

/-- A user creates an entry only through a create profile with a group
receiver that covers the user, whose target matches the entry, and which
allows every attribute and class of the entry. -/
theorem create_needs_profile (ctl : AccessControlsInner) (ce : CreateEvent) (es : Slice Entry) (e : Entry)
    (hu : IsUser ce.ident) (h : access.create_allow_operation ctl ce es = ok (.Ok true)) (he : e ∈ es.val) :
    ∃ acc ∈ ctl.acps_create.val,
      (∃ gs, acc.acp.receiver = .Group gs) ∧ Applies ce.ident acc.acp e ∧
      (∀ a ∈ e.attrs.val, a.attr ∈ acc.attrs.val) ∧ (∀ c ∈ classes e, c ∈ names acc.classes.val) := by
  sorry

/-- A user modification asks to set an attribute only where some modify
profile that applies to the entry allows it. -/
theorem modify_needs_profile (ctl : AccessControlsInner) (me : ModifyEvent) (es : Slice Entry) (e : Entry)
    (m : Modify) (a : List Nat)
    (hu : IsUser me.ident) (h : access.modify_allow_operation ctl me es = ok (.Ok true))
    (he : e ∈ es.val) (hm : m ∈ me.modlist.val) (ha : presAttr m = some a) :
    ∃ acm ∈ ctl.acps_modify.val, a ∈ names acm.presattrs.val ∧ Applies me.ident acm.acp e := by
  sorry

/-! ## Protected entries -/

/-- Users and migrations never delete builtin entries (uuid at or below
anonymous's) or entries of a protected class. -/
theorem delete_protected (ctl : AccessControlsInner) (de : DeleteEvent) (es : Slice Entry) (e : Entry)
    (hk : IsUser de.ident ∨ de.ident.origin = .Internal .Migration)
    (h : access.delete_allow_operation ctl de es = ok (.Ok true)) (he : e ∈ es.val) :
    UUID_ANONYMOUS < e.uuid ∧ ∀ c ∈ classes e, c ∉ protectedEntryClasses := by
  apply kanidm_kernel.Verified.KanidmDeleteProtected.delete_protected <;> assumption

/-- Users and migrations never create builtin entries or entries of a
protected class. -/
theorem create_protected (ctl : AccessControlsInner) (ce : CreateEvent) (es : Slice Entry) (e : Entry)
    (hk : IsUser ce.ident ∨ ce.ident.origin = .Internal .Migration)
    (h : access.create_allow_operation ctl ce es = ok (.Ok true)) (he : e ∈ es.val) :
    (∀ u, uuidOf e = some u → UUID_ANONYMOUS < u) ∧ ∀ c ∈ classes e, c ∉ protectedEntryClasses := by
  sorry

/-- Only the internal system identity modifies a tombstone. -/
theorem tombstone_locked (ctl : AccessControlsInner) (me : ModifyEvent) (es : Slice Entry) (e : Entry) (b : Bool)
    (hn : me.ident.origin ≠ .Internal .System) (he : e ∈ es.val) (ht : HasClass e "tombstone")
    (h : access.modify_allow_operation ctl me es = ok (.Ok b)) :
    b = false := by
  sorry

/-- Only the internal system identity adds a protected class to an entry. -/
theorem protected_class_never_added (ctl : AccessControlsInner) (me : ModifyEvent) (es : Slice Entry)
    (a : alloc.vec.Vec U8) (v : PartialValue) (c : List Nat)
    (hn : me.ident.origin ≠ .Internal .System) (hne : es.val ≠ [])
    (h : access.modify_allow_operation ctl me es = ok (.Ok true))
    (hm : .Present a v ∈ me.modlist.val) (hc : nats a.val = lit "class") (hv : strOf v = some c) :
    c ∉ protectedModPresClasses := by
  sorry

/-! ## Synchronised entries -/

/-- On an unprotected entry owned by a sync agreement, a user may only set the
session and credential-reset attributes and those the agreement yields; an
entry with no single sync parent cannot be modified at all. -/
theorem sync_object_constrained (ctl : AccessControlsInner) (me : ModifyEvent) (es : Slice Entry) (e : Entry)
    (m : Modify) (a : List Nat)
    (hu : IsUser me.ident) (h : access.modify_allow_operation ctl me es = ok (.Ok true))
    (he : e ∈ es.val) (hs : HasClass e "sync_object")
    (hb : UUID_ANONYMOUS < e.uuid) (hp : ∀ c ∈ classes e, c ∉ protectedModEntryClasses)
    (hm : m ∈ me.modlist.val) (ha : presAttr m = some a) :
    ∃ p, refers e "sync_parent_uuid" = some [p] ∧ (a ∈ syncAttrs ∨ a ∈ agreementAttrs ctl.sync_agreements.val p) := by
  sorry

/-! ## Internal identities -/

/-- The account-request identity creates only sign-up requests, with only
their six attributes. -/
theorem account_request_creates_signups (ctl : AccessControlsInner) (ce : CreateEvent) (es : Slice Entry)
    (e : Entry)
    (hr : ce.ident.origin = .Internal .AccountRequest)
    (h : access.create_allow_operation ctl ce es = ok (.Ok true)) (he : e ∈ es.val) :
    (∀ x ∈ e.attrs.val,
      nats x.attr.val ∈ ["class", "delete_after", "displayname", "mail", "name", "uuid"].map lit) ∧
    ∀ c ∈ classes e, c ∈ ["object", "account_signup_request"].map lit := by
  sorry

/-! ## The filter matcher -/

/-- An equality term matches exactly when the entry's value set for the
attribute holds the value. -/
theorem match_eq_spec (e : Entry) (a : alloc.vec.Vec U8) (v : PartialValue) :
    entry_impl.entry_match_no_index_inner e (.Eq a v) = ok true ↔
      ∃ vs, ava e (nats a.val) = some vs ∧ ValueContains vs v := by
  sorry

/-- The substring test of `Cnt` terms is `List.IsInfix`. -/
theorem str_contains_spec (hay needle : Slice U8) :
    valueset.str_contains hay needle = ok (decide (needle.val <:+: hay.val)) := by
  sorry

/-! ## Totality -/

/-- The effective-permission report (search, modify and delete decisions for
every entry) never panics, overflows or loops, when the access profiles and
sync agreements list fewer than `Usize.max` attributes and classes in total. Without the bound, two
search profiles granting `Usize.max + 1` distinct attributes overflow the
union of their grants; Rust cannot hold that many distinct strings. -/
theorem effective_permission_check_total (ctl : AccessControlsInner) (ident : Identity)
    (attrs : Option (alloc.vec.Vec (alloc.vec.Vec U8))) (es : Slice Entry)
    (hcap : (ctl.acps_search.val.map (·.attrs.length)).sum +
      (ctl.acps_modify.val.map (fun m => m.presattrs.length + m.remattrs.length +
        m.pres_classes.length + m.rem_classes.length)).sum +
      (ctl.sync_agreements.val.map (·.attrs.length)).sum < Usize.max) :
    ∃ y, access.effective_permission_check ctl ident attrs es = ok y := by
  sorry

end kanidm_kernel.Properties
