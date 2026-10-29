import Verified.MigrationDefaults
import Verified.ValueObservers
import Verified.SyntaxTypes
import Verified.EntryValidation
import Verified.AccountPolicy
import Verified.CredentialCommit
import Verified.SchemaTags
import Verified.RecoveredProtectedDenyOverridesModify
import Verified.RecoveredProtectedDenyOverridesCreate
import Verified.RecoveredSearchAttrsGranted
import Verified.RecoveredAnonymousReadsByProfileOnly
import Verified.RecoveredDeleteNeedsProfile
import Verified.RecoveredCreateNeedsProfile
import Verified.RecoveredModifyNeedsProfile
import Verified.RecoveredCreateProtected
import Verified.RecoveredTombstoneLocked
import Verified.RecoveredProtectedClassNeverAdded
import Verified.RecoveredSyncObjectConstrained
import Verified.RecoveredAccountRequestCreatesSignups
import Verified.RecoveredMatchEqSpec
import Verified.RecoveredStrContainsSpec
import Verified.RecoveredEffectivePermissionCheckTotal
import Verified.SoftLock
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
  apply kanidm_kernel.Verified.RecoveredProtectedDenyOverridesModify.protected_deny_overrides_modify <;> assumption

/-- When the protection rules deny a create, no profile can allow it. -/
theorem protected_deny_overrides_create (ident : Identity)
    (related : Slice profiles.AccessControlCreateResolved) (e : Entry)
    (h : create_acc.protected_filter_entry ident e = ok .Deny) :
    create_acc.apply_create_access ident related e = ok .Deny := by
  apply kanidm_kernel.Verified.RecoveredProtectedDenyOverridesCreate.protected_deny_overrides_create <;> assumption

/-! ## Search -/

/-- Every attribute a search returns on an entry is granted on that entry by a
search profile that applies to the caller, or is one of the few attributes
the OAuth2, application and sync-account rules release. -/
theorem search_attrs_granted (ctl : AccessControlsInner) (se : SearchEvent) (es : Slice Entry)
    (rs : alloc.vec.Vec EntryReduced) (r : EntryReduced) (x : Ava)
    (h : access.search_filter_entry_attributes ctl se es = ok (.Ok rs))
    (hr : r ∈ rs.val) (hx : x ∈ r.attrs.val) :
    ∃ e ∈ es.val, e.uuid = r.uuid ∧ x ∈ e.attrs.val ∧ SearchGrants ctl se.ident e (nats x.attr.val) := by
  apply kanidm_kernel.Verified.RecoveredSearchAttrsGranted.search_attrs_granted <;> assumption

/-- The anonymous user gets nothing from the OAuth2 and application rules: what
it may read comes from the profiles alone. -/
theorem anonymous_reads_by_profile_only (ident : Identity) (u : IdentUser)
    (related : Slice profiles.AccessControlSearchResolved) (e : Entry)
    (attrs : alloc.vec.Vec (alloc.vec.Vec U8)) (x : alloc.vec.Vec U8)
    (hu : ident.origin = .User u) (ha : u.entry.uuid = UUID_ANONYMOUS)
    (hs : ¬ HasClass u.entry "sync_object")
    (h : search_acc.apply_search_access ident related e = ok (.Allow attrs)) (hx : x ∈ attrs.val) :
    ∃ acs ∈ related.val, x ∈ acs.attrs.val := by
  apply kanidm_kernel.Verified.RecoveredAnonymousReadsByProfileOnly.anonymous_reads_by_profile_only <;> assumption

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
  apply kanidm_kernel.Verified.RecoveredDeleteNeedsProfile.delete_needs_profile <;> assumption

/-- A user creates an entry only through a create profile with a group
receiver that covers the user, whose target matches the entry, and which
allows every attribute and class of the entry. -/
theorem create_needs_profile (ctl : AccessControlsInner) (ce : CreateEvent) (es : Slice Entry) (e : Entry)
    (hu : IsUser ce.ident) (h : access.create_allow_operation ctl ce es = ok (.Ok true)) (he : e ∈ es.val) :
    ∃ acc ∈ ctl.acps_create.val,
      (∃ gs, acc.acp.receiver = .Group gs) ∧ Applies ce.ident acc.acp e ∧
      (∀ a ∈ e.attrs.val, a.attr ∈ acc.attrs.val) ∧ (∀ c ∈ classes e, c ∈ names acc.classes.val) := by
  apply kanidm_kernel.Verified.RecoveredCreateNeedsProfile.create_needs_profile <;> assumption

/-- A user modification asks to set an attribute only where some modify
profile that applies to the entry allows it. -/
theorem modify_needs_profile (ctl : AccessControlsInner) (me : ModifyEvent) (es : Slice Entry) (e : Entry)
    (m : Modify) (a : List Nat)
    (hu : IsUser me.ident) (h : access.modify_allow_operation ctl me es = ok (.Ok true))
    (he : e ∈ es.val) (hm : m ∈ me.modlist.val) (ha : presAttr m = some a) :
    ∃ acm ∈ ctl.acps_modify.val, a ∈ names acm.presattrs.val ∧ Applies me.ident acm.acp e := by
  apply kanidm_kernel.Verified.RecoveredModifyNeedsProfile.modify_needs_profile <;> assumption

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
  apply kanidm_kernel.Verified.RecoveredCreateProtected.create_protected <;> assumption

/-- Only the internal system identity modifies a tombstone. -/
theorem tombstone_locked (ctl : AccessControlsInner) (me : ModifyEvent) (es : Slice Entry) (e : Entry) (b : Bool)
    (hn : me.ident.origin ≠ .Internal .System) (he : e ∈ es.val) (ht : HasClass e "tombstone")
    (h : access.modify_allow_operation ctl me es = ok (.Ok b)) :
    b = false := by
  apply kanidm_kernel.Verified.RecoveredTombstoneLocked.tombstone_locked <;> assumption

/-- Only the internal system identity adds a protected class to an entry. -/
theorem protected_class_never_added (ctl : AccessControlsInner) (me : ModifyEvent) (es : Slice Entry)
    (a : alloc.vec.Vec U8) (v : PartialValue) (c : List Nat)
    (hn : me.ident.origin ≠ .Internal .System) (hne : es.val ≠ [])
    (h : access.modify_allow_operation ctl me es = ok (.Ok true))
    (hm : .Present a v ∈ me.modlist.val) (hc : nats a.val = lit "class") (hv : strOf v = some c) :
    c ∉ protectedModPresClasses := by
  apply kanidm_kernel.Verified.RecoveredProtectedClassNeverAdded.protected_class_never_added <;> assumption

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
  apply kanidm_kernel.Verified.RecoveredSyncObjectConstrained.sync_object_constrained <;> assumption

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
  apply kanidm_kernel.Verified.RecoveredAccountRequestCreatesSignups.account_request_creates_signups <;> assumption

/-! ## The filter matcher -/

/-- An equality term matches exactly when the entry's value set for the
attribute holds the value. -/
theorem match_eq_spec (e : Entry) (a : alloc.vec.Vec U8) (v : PartialValue) :
    entry_impl.entry_match_no_index_inner e (.Eq a v) = ok true ↔
      ∃ vs, ava e (nats a.val) = some vs ∧ ValueContains vs v := by
  apply kanidm_kernel.Verified.RecoveredMatchEqSpec.match_eq_spec <;> assumption

/-- The substring test of `Cnt` terms is `List.IsInfix`. -/
theorem str_contains_spec (hay needle : Slice U8) :
    valueset.str_contains hay needle = ok (decide (needle.val <:+: hay.val)) := by
  apply kanidm_kernel.Verified.RecoveredStrContainsSpec.str_contains_spec <;> assumption

/-! ## Totality -/

/-- The effective-permission report (search, modify and delete decisions for
every entry) never panics, overflows or loops, when the access profiles and
sync agreements list fewer than `Usize.max - 73` attributes and classes in total
(the kernel's search, migration, create and modify modules insert 73 distinct
fixed attribute and class names of their own into the same grant sets). Without the bound, two
search profiles granting `Usize.max + 1` distinct attributes overflow the
union of their grants; Rust cannot hold that many distinct strings. -/
theorem effective_permission_check_total (ctl : AccessControlsInner) (ident : Identity)
    (attrs : Option (alloc.vec.Vec (alloc.vec.Vec U8))) (es : Slice Entry)
    (hcap : (ctl.acps_search.val.map (·.attrs.length)).sum +
      (ctl.acps_modify.val.map (fun m => m.presattrs.length + m.remattrs.length +
        m.pres_classes.length + m.rem_classes.length)).sum +
      (ctl.sync_agreements.val.map (·.attrs.length)).sum + 73 < Usize.max) :
    ∃ y, access.effective_permission_check ctl ident attrs es = ok y := by
  apply kanidm_kernel.Verified.RecoveredEffectivePermissionCheckTotal.effective_permission_check_total <;> assumption



open kanidm_kernel.Verified.SoftLock

theorem soft_lock_apply_time_step_spec (lock : softlock.SoftLock) (ct : softlock.Time) (expiry : Option softlock.Time) :
    softlock.apply_time_step lock ct expiry = ok (timeStep lock ct expiry) := by
  apply kanidm_kernel.Verified.SoftLock.apply_time_step_spec <;> assumption

theorem soft_lock_is_valid_spec (lock : softlock.SoftLock) :
    softlock.is_valid lock = ok (match lock.state with | .Locked .. => false | _ => true) := by
  apply kanidm_kernel.Verified.SoftLock.is_valid_spec <;> assumption

theorem soft_lock_new_spec (policy : softlock.Policy) :
    softlock.new policy = ok {state := .Init, policy := policy, last_expire_at := {secs := 0#u64, nanos := 0#u32}} := by
  apply kanidm_kernel.Verified.SoftLock.new_spec <;> assumption

theorem soft_lock_password_lockout (count : Usize) (ct : softlock.Time) (s : softlock.State)
    (hc : 100 ≤ count.val)
    (h : softlock.failure_next_state .Password count ct = ok s) :
    ∃ reset, s = .Locked count reset reset ∧ reset.nanos = 0#u32 := by
  apply kanidm_kernel.Verified.SoftLock.password_lockout <;> assumption

theorem soft_lock_totp_lockout (step : U64) (count : Usize) (ct : softlock.Time) (s : softlock.State)
    (hc : 3 ≤ count.val)
    (h : softlock.failure_next_state (.Totp step) count ct = ok s) :
    ∃ reset, s = .Locked count reset reset ∧ reset.nanos = 0#u32 := by
  apply kanidm_kernel.Verified.SoftLock.totp_lockout <;> assumption

theorem soft_lock_webauthn_failure (count : Usize) (ct : softlock.Time) (s : softlock.State)
    (h : softlock.failure_next_state .Webauthn count ct = ok s) :
    ∃ reset, s = .Locked count reset reset ∧ reset.nanos = ct.nanos ∧
      reset.secs.val = ct.secs.val + 1 := by
  apply kanidm_kernel.Verified.SoftLock.webauthn_failure <;> assumption

theorem soft_lock_unrestricted_failure (count : Usize) (ct : softlock.Time) :
    softlock.failure_next_state .Unrestricted count ct = ok .Init := by
  apply kanidm_kernel.Verified.SoftLock.unrestricted_failure <;> assumption

theorem soft_lock_failure_records_count (policy : softlock.Policy) (count : Usize) (ct : softlock.Time)
    (s : softlock.State) (h : softlock.failure_next_state policy count ct = ok s) :
    (policy = .Unrestricted ∧ s = .Init) ∨
      ∃ reset unlock, s = .Locked count reset unlock := by
  apply kanidm_kernel.Verified.SoftLock.failure_records_count <;> assumption

theorem soft_lock_record_failure_spec (lock : softlock.SoftLock) (ct : softlock.Time)
    (out : softlock.SoftLock) (h : softlock.record_failure lock ct = ok out) :
    out.policy = lock.policy ∧ out.last_expire_at = lock.last_expire_at ∧
    ((lock.policy = .Unrestricted ∧ out.state = .Init) ∨
      ∃ count reset unlock, out.state = .Locked count reset unlock ∧
        count.val = (match lock.state with | .Init => 0 | .Locked n .. => n.val | .Unlocked n _ => n.val) + 1) := by
  apply kanidm_kernel.Verified.SoftLock.record_failure_spec <;> assumption

open kanidm_kernel.Verified.SchemaTags

theorem schema_tags_partial_accepts_spec (syn : schema_tags.Syntax) (tag : U16) :
    schema_tags.partial_accepts syn tag =
      ok (decide (tag ∈ partial_acceptsAllowed syn)) := by
  apply kanidm_kernel.Verified.SchemaTags.partial_accepts_spec <;> assumption

theorem schema_tags_value_accepts_spec (syn : schema_tags.Syntax) (tag : U16) (valid : Bool) :
    schema_tags.value_accepts syn tag valid =
      ok (valid && decide (tag ∈ value_acceptsAllowed syn)) := by
  apply kanidm_kernel.Verified.SchemaTags.value_accepts_spec <;> assumption

theorem schema_tags_ava_accepts_spec (multi : Bool) (count : Usize) (expected actual : U16) (valid : Bool) :
    schema_tags.ava_accepts multi count expected actual valid =
      ok (decide (multi = true ∨ count.val ≤ 1) && decide (expected = actual) && valid) := by
  apply kanidm_kernel.Verified.SchemaTags.ava_accepts_spec <;> assumption

open kanidm_kernel.Verified.CredentialCommit

theorem credential_commit_can_commit_spec (policy : credential_commit.Policy) (primary : Option Bool)
    (passkeys attested : Bool) (caEmpty : Option Bool) :
    credential_commit.can_commit policy primary passkeys attested caEmpty =
      ok (decision policy primary passkeys attested caEmpty) := by
  apply kanidm_kernel.Verified.CredentialCommit.can_commit_spec <;> assumption

theorem credential_commit_invalid_denied (primary : Option Bool) (passkeys attested : Bool) (caEmpty : Option Bool) :
    ∃ d, credential_commit.can_commit .Invalid primary passkeys attested caEmpty = ok d ∧
      d.can_commit = false ∧ d.policy_warning = some .Unsatisfiable := by
  apply kanidm_kernel.Verified.CredentialCommit.invalid_denied <;> assumption


open kanidm_kernel.Verified.AccountPolicy

theorem account_policy_option_max_spec (a b : Option U64) :
    account_policy.option_max a b = ok (maxOption a b) := by
  apply kanidm_kernel.Verified.AccountPolicy.option_max_spec <;> assumption

theorem account_policy_combine_spec (a b : account_policy.Policy) :
    account_policy.combine a b = ok (combine a b) := by
  apply kanidm_kernel.Verified.AccountPolicy.combine_spec <;> assumption

theorem account_policy_finalize_spec (a : account_policy.Policy) :
    account_policy.finalize a = ok (finalize a) := by
  apply kanidm_kernel.Verified.AccountPolicy.finalize_spec <;> assumption

theorem account_policy_fold_from_spec (policies : Slice account_policy.Policy) :
    account_policy.fold_from policies
      ⦃ r => r = finalize (policies.val.foldl combine initial) ⦄ := by
  apply kanidm_kernel.Verified.AccountPolicy.fold_from_spec <;> assumption

/-- The complete entry schema decision, including the first error and ordered
    payloads, assuming only that collected schema lists fit in a vector. -/
theorem entry_validation_spec (entry : entry_validation.Entry)
    (classes : Slice entry_validation.ClassSchema) (attrs : Slice entry_validation.AttributeSchema)
    (hcap : kanidm_kernel.Verified.EntryValidation.capacity entry classes.val) :
    entry_validation.validate entry classes attrs ⦃ r =>
      kanidm_kernel.Verified.EntryValidation.outcome r =
        kanidm_kernel.Verified.EntryValidation.validateModel entry classes.val attrs.val ⦄ := by
  apply kanidm_kernel.Verified.EntryValidation.validate_spec <;> assumption


theorem value_observers_Value_is_utf8_spec (v : value_observers.Value) :
    value_observers.Value.is_utf8 v ⦃ r => r = Verified.ValueObservers.Value_is_utf8_model v ⦄ :=
  Verified.ValueObservers.Value_is_utf8_spec v

theorem value_observers_Value_is_iutf8_spec (v : value_observers.Value) :
    value_observers.Value.is_iutf8 v ⦃ r => r = Verified.ValueObservers.Value_is_iutf8_model v ⦄ :=
  Verified.ValueObservers.Value_is_iutf8_spec v

theorem value_observers_Value_is_insensitive_utf8_spec (v : value_observers.Value) :
    value_observers.Value.is_insensitive_utf8 v ⦃ r => r = Verified.ValueObservers.Value_is_insensitive_utf8_model v ⦄ :=
  Verified.ValueObservers.Value_is_insensitive_utf8_spec v

theorem value_observers_Value_is_iname_spec (v : value_observers.Value) :
    value_observers.Value.is_iname v ⦃ r => r = Verified.ValueObservers.Value_is_iname_model v ⦄ :=
  Verified.ValueObservers.Value_is_iname_spec v

theorem value_observers_Value_is_uuid_spec (v : value_observers.Value) :
    value_observers.Value.is_uuid v ⦃ r => r = Verified.ValueObservers.Value_is_uuid_model v ⦄ :=
  Verified.ValueObservers.Value_is_uuid_spec v

theorem value_observers_Value_is_bool_spec (v : value_observers.Value) :
    value_observers.Value.is_bool v ⦃ r => r = Verified.ValueObservers.Value_is_bool_model v ⦄ :=
  Verified.ValueObservers.Value_is_bool_spec v

theorem value_observers_Value_is_syntax_spec (v : value_observers.Value) :
    value_observers.Value.is_syntax v ⦃ r => r = Verified.ValueObservers.Value_is_syntax_model v ⦄ :=
  Verified.ValueObservers.Value_is_syntax_spec v

theorem value_observers_Value_is_index_spec (v : value_observers.Value) :
    value_observers.Value.is_index v ⦃ r => r = Verified.ValueObservers.Value_is_index_model v ⦄ :=
  Verified.ValueObservers.Value_is_index_spec v

theorem value_observers_Value_is_refer_spec (v : value_observers.Value) :
    value_observers.Value.is_refer v ⦃ r => r = Verified.ValueObservers.Value_is_refer_model v ⦄ :=
  Verified.ValueObservers.Value_is_refer_spec v

theorem value_observers_Value_is_json_filter_spec (v : value_observers.Value) :
    value_observers.Value.is_json_filter v ⦃ r => r = Verified.ValueObservers.Value_is_json_filter_model v ⦄ :=
  Verified.ValueObservers.Value_is_json_filter_spec v

theorem value_observers_Value_is_credential_spec (v : value_observers.Value) :
    value_observers.Value.is_credential v ⦃ r => r = Verified.ValueObservers.Value_is_credential_model v ⦄ :=
  Verified.ValueObservers.Value_is_credential_spec v

theorem value_observers_Value_is_secret_string_spec (v : value_observers.Value) :
    value_observers.Value.is_secret_string v ⦃ r => r = Verified.ValueObservers.Value_is_secret_string_model v ⦄ :=
  Verified.ValueObservers.Value_is_secret_string_spec v

theorem value_observers_Value_is_sshkey_spec (v : value_observers.Value) :
    value_observers.Value.is_sshkey v ⦃ r => r = Verified.ValueObservers.Value_is_sshkey_model v ⦄ :=
  Verified.ValueObservers.Value_is_sshkey_spec v

theorem value_observers_Value_is_spn_spec (v : value_observers.Value) :
    value_observers.Value.is_spn v ⦃ r => r = Verified.ValueObservers.Value_is_spn_model v ⦄ :=
  Verified.ValueObservers.Value_is_spn_spec v

theorem value_observers_Value_is_uint32_spec (v : value_observers.Value) :
    value_observers.Value.is_uint32 v ⦃ r => r = Verified.ValueObservers.Value_is_uint32_model v ⦄ :=
  Verified.ValueObservers.Value_is_uint32_spec v

theorem value_observers_Value_is_cid_spec (v : value_observers.Value) :
    value_observers.Value.is_cid v ⦃ r => r = Verified.ValueObservers.Value_is_cid_model v ⦄ :=
  Verified.ValueObservers.Value_is_cid_spec v

theorem value_observers_Value_is_nsuniqueid_spec (v : value_observers.Value) :
    value_observers.Value.is_nsuniqueid v ⦃ r => r = Verified.ValueObservers.Value_is_nsuniqueid_model v ⦄ :=
  Verified.ValueObservers.Value_is_nsuniqueid_spec v

theorem value_observers_Value_is_datetime_spec (v : value_observers.Value) :
    value_observers.Value.is_datetime v ⦃ r => r = Verified.ValueObservers.Value_is_datetime_model v ⦄ :=
  Verified.ValueObservers.Value_is_datetime_spec v

theorem value_observers_Value_is_email_address_spec (v : value_observers.Value) :
    value_observers.Value.is_email_address v ⦃ r => r = Verified.ValueObservers.Value_is_email_address_model v ⦄ :=
  Verified.ValueObservers.Value_is_email_address_spec v

theorem value_observers_Value_is_url_spec (v : value_observers.Value) :
    value_observers.Value.is_url v ⦃ r => r = Verified.ValueObservers.Value_is_url_model v ⦄ :=
  Verified.ValueObservers.Value_is_url_spec v

theorem value_observers_Value_is_oauthscope_spec (v : value_observers.Value) :
    value_observers.Value.is_oauthscope v ⦃ r => r = Verified.ValueObservers.Value_is_oauthscope_model v ⦄ :=
  Verified.ValueObservers.Value_is_oauthscope_spec v

theorem value_observers_Value_is_oauthscopemap_spec (v : value_observers.Value) :
    value_observers.Value.is_oauthscopemap v ⦃ r => r = Verified.ValueObservers.Value_is_oauthscopemap_model v ⦄ :=
  Verified.ValueObservers.Value_is_oauthscopemap_spec v

theorem value_observers_Value_is_privatebinary_spec (v : value_observers.Value) :
    value_observers.Value.is_privatebinary v ⦃ r => r = Verified.ValueObservers.Value_is_privatebinary_model v ⦄ :=
  Verified.ValueObservers.Value_is_privatebinary_spec v

theorem value_observers_Value_as_json_filter_spec (v : value_observers.Value) :
    value_observers.Value.as_json_filter v ⦃ r => r = Verified.ValueObservers.Value_as_json_filter_model v ⦄ :=
  Verified.ValueObservers.Value_as_json_filter_spec v

theorem value_observers_Value_to_credential_spec (v : value_observers.Value) :
    value_observers.Value.to_credential v ⦃ r => r = Verified.ValueObservers.Value_to_credential_model v ⦄ :=
  Verified.ValueObservers.Value_to_credential_spec v

theorem value_observers_Value_get_secret_str_spec (v : value_observers.Value) :
    value_observers.Value.get_secret_str v ⦃ r => r = Verified.ValueObservers.Value_get_secret_str_model v ⦄ :=
  Verified.ValueObservers.Value_get_secret_str_spec v

theorem value_observers_Value_to_privatebinary_spec (v : value_observers.Value) :
    value_observers.Value.to_privatebinary v ⦃ r => r = Verified.ValueObservers.Value_to_privatebinary_model v ⦄ :=
  Verified.ValueObservers.Value_to_privatebinary_spec v

theorem value_observers_Value_to_str_spec (v : value_observers.Value) :
    value_observers.Value.to_str v ⦃ r => r = Verified.ValueObservers.Value_to_str_model v ⦄ :=
  Verified.ValueObservers.Value_to_str_spec v

theorem value_observers_Value_to_url_spec (v : value_observers.Value) :
    value_observers.Value.to_url v ⦃ r => r = Verified.ValueObservers.Value_to_url_model v ⦄ :=
  Verified.ValueObservers.Value_to_url_spec v

theorem value_observers_Value_as_string_spec (v : value_observers.Value) :
    value_observers.Value.as_string v ⦃ r => r = Verified.ValueObservers.Value_as_string_model v ⦄ :=
  Verified.ValueObservers.Value_as_string_spec v

theorem value_observers_Value_to_ref_uuid_spec (v : value_observers.Value) :
    value_observers.Value.to_ref_uuid v ⦃ r => r = Verified.ValueObservers.Value_to_ref_uuid_model v ⦄ :=
  Verified.ValueObservers.Value_to_ref_uuid_spec v

theorem value_observers_Value_to_uuid_spec (v : value_observers.Value) :
    value_observers.Value.to_uuid v ⦃ r => r = Verified.ValueObservers.Value_to_uuid_model v ⦄ :=
  Verified.ValueObservers.Value_to_uuid_spec v

theorem value_observers_Value_to_indextype_spec (v : value_observers.Value) :
    value_observers.Value.to_indextype v ⦃ r => r = Verified.ValueObservers.Value_to_indextype_model v ⦄ :=
  Verified.ValueObservers.Value_to_indextype_spec v

theorem value_observers_Value_to_syntaxtype_spec (v : value_observers.Value) :
    value_observers.Value.to_syntaxtype v ⦃ r => r = Verified.ValueObservers.Value_to_syntaxtype_model v ⦄ :=
  Verified.ValueObservers.Value_to_syntaxtype_spec v

theorem value_observers_Value_to_bool_spec (v : value_observers.Value) :
    value_observers.Value.to_bool v ⦃ r => r = Verified.ValueObservers.Value_to_bool_model v ⦄ :=
  Verified.ValueObservers.Value_to_bool_spec v

theorem value_observers_Value_to_uint32_spec (v : value_observers.Value) :
    value_observers.Value.to_uint32 v ⦃ r => r = Verified.ValueObservers.Value_to_uint32_model v ⦄ :=
  Verified.ValueObservers.Value_to_uint32_spec v

theorem value_observers_Value_to_utf8_spec (v : value_observers.Value) :
    value_observers.Value.to_utf8 v ⦃ r => r = Verified.ValueObservers.Value_to_utf8_model v ⦄ :=
  Verified.ValueObservers.Value_to_utf8_spec v

theorem value_observers_Value_to_iutf8_spec (v : value_observers.Value) :
    value_observers.Value.to_iutf8 v ⦃ r => r = Verified.ValueObservers.Value_to_iutf8_model v ⦄ :=
  Verified.ValueObservers.Value_to_iutf8_spec v

theorem value_observers_Value_to_iname_spec (v : value_observers.Value) :
    value_observers.Value.to_iname v ⦃ r => r = Verified.ValueObservers.Value_to_iname_model v ⦄ :=
  Verified.ValueObservers.Value_to_iname_spec v

theorem value_observers_Value_to_jsonfilt_spec (v : value_observers.Value) :
    value_observers.Value.to_jsonfilt v ⦃ r => r = Verified.ValueObservers.Value_to_jsonfilt_model v ⦄ :=
  Verified.ValueObservers.Value_to_jsonfilt_spec v

theorem value_observers_Value_to_cred_spec (v : value_observers.Value) :
    value_observers.Value.to_cred v ⦃ r => r = Verified.ValueObservers.Value_to_cred_model v ⦄ :=
  Verified.ValueObservers.Value_to_cred_spec v

theorem value_observers_Value_to_spn_spec (v : value_observers.Value) :
    value_observers.Value.to_spn v ⦃ r => r = Verified.ValueObservers.Value_to_spn_model v ⦄ :=
  Verified.ValueObservers.Value_to_spn_spec v

theorem value_observers_Value_to_cid_spec (v : value_observers.Value) :
    value_observers.Value.to_cid v ⦃ r => r = Verified.ValueObservers.Value_to_cid_model v ⦄ :=
  Verified.ValueObservers.Value_to_cid_spec v

theorem value_observers_Value_to_nsuniqueid_spec (v : value_observers.Value) :
    value_observers.Value.to_nsuniqueid v ⦃ r => r = Verified.ValueObservers.Value_to_nsuniqueid_model v ⦄ :=
  Verified.ValueObservers.Value_to_nsuniqueid_spec v

theorem value_observers_Value_to_emailaddress_spec (v : value_observers.Value) :
    value_observers.Value.to_emailaddress v ⦃ r => r = Verified.ValueObservers.Value_to_emailaddress_model v ⦄ :=
  Verified.ValueObservers.Value_to_emailaddress_spec v

theorem value_observers_Value_to_oauthscope_spec (v : value_observers.Value) :
    value_observers.Value.to_oauthscope v ⦃ r => r = Verified.ValueObservers.Value_to_oauthscope_model v ⦄ :=
  Verified.ValueObservers.Value_to_oauthscope_spec v

theorem value_observers_Value_to_oauthscopemap_spec (v : value_observers.Value) :
    value_observers.Value.to_oauthscopemap v ⦃ r => r = Verified.ValueObservers.Value_to_oauthscopemap_model v ⦄ :=
  Verified.ValueObservers.Value_to_oauthscopemap_spec v

theorem value_observers_Value_to_restrictedstring_spec (v : value_observers.Value) :
    value_observers.Value.to_restrictedstring v ⦃ r => r = Verified.ValueObservers.Value_to_restrictedstring_model v ⦄ :=
  Verified.ValueObservers.Value_to_restrictedstring_spec v

theorem value_observers_Value_to_phonenumber_spec (v : value_observers.Value) :
    value_observers.Value.to_phonenumber v ⦃ r => r = Verified.ValueObservers.Value_to_phonenumber_model v ⦄ :=
  Verified.ValueObservers.Value_to_phonenumber_spec v

theorem value_observers_Value_to_publicbinary_spec (v : value_observers.Value) :
    value_observers.Value.to_publicbinary v ⦃ r => r = Verified.ValueObservers.Value_to_publicbinary_model v ⦄ :=
  Verified.ValueObservers.Value_to_publicbinary_spec v

theorem value_observers_Value_to_address_spec (v : value_observers.Value) :
    value_observers.Value.to_address v ⦃ r => r = Verified.ValueObservers.Value_to_address_model v ⦄ :=
  Verified.ValueObservers.Value_to_address_spec v

theorem value_observers_Value_to_intenttoken_spec (v : value_observers.Value) :
    value_observers.Value.to_intenttoken v ⦃ r => r = Verified.ValueObservers.Value_to_intenttoken_model v ⦄ :=
  Verified.ValueObservers.Value_to_intenttoken_spec v

theorem value_observers_Value_to_session_spec (v : value_observers.Value) :
    value_observers.Value.to_session v ⦃ r => r = Verified.ValueObservers.Value_to_session_model v ⦄ :=
  Verified.ValueObservers.Value_to_session_spec v

theorem value_observers_Value_migrate_iutf8_iname_spec (v : value_observers.Value) :
    value_observers.Value.migrate_iutf8_iname v ⦃ r => r = Verified.ValueObservers.Value_migrate_iutf8_iname_model v ⦄ :=
  Verified.ValueObservers.Value_migrate_iutf8_iname_spec v

theorem value_observers_PartialValue_is_utf8_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_utf8 v ⦃ r => r = Verified.ValueObservers.PartialValue_is_utf8_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_utf8_spec v

theorem value_observers_PartialValue_is_iutf8_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_iutf8 v ⦃ r => r = Verified.ValueObservers.PartialValue_is_iutf8_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_iutf8_spec v

theorem value_observers_PartialValue_is_iname_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_iname v ⦃ r => r = Verified.ValueObservers.PartialValue_is_iname_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_iname_spec v

theorem value_observers_PartialValue_is_bool_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_bool v ⦃ r => r = Verified.ValueObservers.PartialValue_is_bool_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_bool_spec v

theorem value_observers_PartialValue_is_uuid_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_uuid v ⦃ r => r = Verified.ValueObservers.PartialValue_is_uuid_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_uuid_spec v

theorem value_observers_PartialValue_is_refer_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_refer v ⦃ r => r = Verified.ValueObservers.PartialValue_is_refer_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_refer_spec v

theorem value_observers_PartialValue_is_index_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_index v ⦃ r => r = Verified.ValueObservers.PartialValue_is_index_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_index_spec v

theorem value_observers_PartialValue_is_syntax_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_syntax v ⦃ r => r = Verified.ValueObservers.PartialValue_is_syntax_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_syntax_spec v

theorem value_observers_PartialValue_is_json_filter_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_json_filter v ⦃ r => r = Verified.ValueObservers.PartialValue_is_json_filter_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_json_filter_spec v

theorem value_observers_PartialValue_is_credential_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_credential v ⦃ r => r = Verified.ValueObservers.PartialValue_is_credential_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_credential_spec v

theorem value_observers_PartialValue_is_secret_string_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_secret_string v ⦃ r => r = Verified.ValueObservers.PartialValue_is_secret_string_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_secret_string_spec v

theorem value_observers_PartialValue_is_sshkey_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_sshkey v ⦃ r => r = Verified.ValueObservers.PartialValue_is_sshkey_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_sshkey_spec v

theorem value_observers_PartialValue_is_spn_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_spn v ⦃ r => r = Verified.ValueObservers.PartialValue_is_spn_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_spn_spec v

theorem value_observers_PartialValue_is_uint32_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_uint32 v ⦃ r => r = Verified.ValueObservers.PartialValue_is_uint32_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_uint32_spec v

theorem value_observers_PartialValue_is_cid_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_cid v ⦃ r => r = Verified.ValueObservers.PartialValue_is_cid_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_cid_spec v

theorem value_observers_PartialValue_is_nsuniqueid_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_nsuniqueid v ⦃ r => r = Verified.ValueObservers.PartialValue_is_nsuniqueid_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_nsuniqueid_spec v

theorem value_observers_PartialValue_is_datetime_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_datetime v ⦃ r => r = Verified.ValueObservers.PartialValue_is_datetime_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_datetime_spec v

theorem value_observers_PartialValue_is_email_address_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_email_address v ⦃ r => r = Verified.ValueObservers.PartialValue_is_email_address_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_email_address_spec v

theorem value_observers_PartialValue_is_url_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_url v ⦃ r => r = Verified.ValueObservers.PartialValue_is_url_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_url_spec v

theorem value_observers_PartialValue_is_oauthscope_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_oauthscope v ⦃ r => r = Verified.ValueObservers.PartialValue_is_oauthscope_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_oauthscope_spec v

theorem value_observers_PartialValue_is_privatebinary_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.is_privatebinary v ⦃ r => r = Verified.ValueObservers.PartialValue_is_privatebinary_model v ⦄ :=
  Verified.ValueObservers.PartialValue_is_privatebinary_spec v

theorem value_observers_PartialValue_to_str_spec (v : value_observers.PartialValue) :
    value_observers.PartialValue.to_str v ⦃ r => r = Verified.ValueObservers.PartialValue_to_str_model v ⦄ :=
  Verified.ValueObservers.PartialValue_to_str_spec v

theorem syntax_types_parse_spec (inputBytes : Slice U8) :
    syntax_types.parse_normalized inputBytes ⦃ r => r = Verified.SyntaxTypes.parseModel inputBytes.val ⦄ :=
  Verified.SyntaxTypes.parse_spec inputBytes

theorem syntax_types_display_spec (syntaxValue : syntax_types.SyntaxType) :
    syntax_types.display syntaxValue ⦃ r => r.val = Verified.SyntaxTypes.displayModel syntaxValue ⦄ :=
  Verified.SyntaxTypes.display_spec syntaxValue

theorem syntax_types_indices_spec (syntaxValue : syntax_types.SyntaxType) :
    syntax_types.index_types syntaxValue ⦃ r => r.val = Verified.SyntaxTypes.indicesModel syntaxValue ⦄ :=
  Verified.SyntaxTypes.indices_spec syntaxValue

theorem migration_defaults_dl11_complete (r : migration_defaults.SystemConfig)
 (h : migration_defaults.dl11 = ok r) : Verified.MigrationDefaults.Complete Verified.MigrationDefaults.longSentinel r :=
 Verified.MigrationDefaults.dl11_complete r h

theorem migration_defaults_dl12_complete (r : migration_defaults.SystemConfig)
 (h : migration_defaults.dl12 = ok r) : Verified.MigrationDefaults.Complete Verified.MigrationDefaults.longSentinel r :=
 Verified.MigrationDefaults.dl12_complete r h

theorem migration_defaults_dl13_complete (r : migration_defaults.SystemConfig)
 (h : migration_defaults.dl13 = ok r) : Verified.MigrationDefaults.Complete Verified.MigrationDefaults.longSentinel r :=
 Verified.MigrationDefaults.dl13_complete r h

theorem migration_defaults_dl14_complete (r : migration_defaults.SystemConfig)
 (h : migration_defaults.dl14 = ok r) : Verified.MigrationDefaults.Complete Verified.MigrationDefaults.longSentinel r :=
 Verified.MigrationDefaults.dl14_complete r h

theorem migration_defaults_dl15_complete (r : migration_defaults.SystemConfig)
 (h : migration_defaults.dl15 = ok r) : Verified.MigrationDefaults.Complete Verified.MigrationDefaults.shortSentinel r :=
 Verified.MigrationDefaults.dl15_complete r h

theorem migration_defaults_dl_1_12_complete (r : migration_defaults.SystemConfig)
 (h : migration_defaults.dl_1_12 = ok r) : Verified.MigrationDefaults.Complete Verified.MigrationDefaults.shortSentinel r :=
 Verified.MigrationDefaults.dl_1_12_complete r h

end kanidm_kernel.Properties
