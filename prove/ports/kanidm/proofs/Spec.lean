import KanidmKernel
import H5iAppLib
/-!
# kanidm's access control engine: the spec

From kanidm's access module at f608c4f (`server/lib/src/server/access/`)
and its design notes (`book/src/developers/designs/access_profiles_original.md`).
An access control profile applies to an identity and an entry when its
receiver covers the identity and its target filter, resolved for the
identity, matches the entry. The theorems use the extracted filter resolver
and matcher for the target (`TargetHolds`); `match_eq_spec` and
`str_contains_spec` describe the matcher's pieces on their own.
-/
open Aeneas Aeneas.Std kanidm_kernel

namespace kanidm_kernel.Spec

/-- A byte string as numbers. -/
def nats (v : List U8) : List Nat := v.map (·.val)

/-- The UTF-8 bytes of a literal. -/
def lit (s : String) : List Nat := s.toUTF8.toList.map (·.toNat)

/-- Attribute or class names. -/
def names (v : List (alloc.vec.Vec U8)) : List (List Nat) := v.map (fun x => nats x.val)

/-- The value set of the entry's attribute `a` (the first pair with that name). -/
def ava (e : Entry) (a : List Nat) : Option ValueSet :=
  (e.attrs.val.find? (fun x => nats x.attr.val == a)).map (·.vs)

/-- The entry's classes: its `class` attribute when it is a case-insensitive
string set, else none. -/
def classes (e : Entry) : List (List Nat) :=
  match ava e (lit "class") with
  | some (.Iutf8 s) => names s.val
  | _ => []

def HasClass (e : Entry) (c : String) : Prop := lit c ∈ classes e

/-- The uuids of a reference attribute. -/
def refers (e : Entry) (a : String) : Option (List U128) :=
  match ava e (lit a) with
  | some (.Refer s) => some s.val
  | _ => none

/-- The uuid of an entry being created: its `uuid` attribute, when single. -/
def uuidOf (e : Entry) : Option U128 :=
  match ava e (lit "uuid") with
  | some (.Uuid s) => if s.val.length = 1 then s.val.head? else none
  | _ => none

def IsUser (i : Identity) : Prop := ∃ u, i.origin = .User u

/-- The groups a user identity is a member of. -/
def memberof (i : Identity) : List U128 :=
  match i.origin with
  | .User u => (refers u.entry "memberof").getD []
  | _ => []

/-- The receiver of a profile covers the identity for this entry: a member of
one of its groups, or, for an entry-manager profile, the entry's manager or a
member of a managing group. -/
def ReceiverHolds (i : Identity) (r : profiles.AccessControlReceiver) (e : Entry) : Prop :=
  match r with
  | .None => False
  | .Group gs => ∃ g ∈ memberof i, g ∈ gs.val
  | .EntryManager =>
    ∃ ms, refers e "entry_managed_by" = some ms ∧
      ((∃ u, i.origin = .User u ∧ u.entry.uuid ∈ ms) ∨ ∃ g ∈ memberof i, g ∈ ms)

/-- The target filter, resolved for the identity, matches the entry. -/
def TargetHolds (i : Identity) (t : profiles.AccessControlTarget) (e : Entry) : Prop :=
  match t with
  | .None => False
  | .Scope f => ∃ fr, filter_impl.resolve f i = .ok (some fr) ∧ entry_impl.entry_match_no_index e fr = .ok true

/-- The profile applies to the identity and the entry. -/
def Applies (i : Identity) (p : profiles.AccessControlProfile) (e : Entry) : Prop :=
  ReceiverHolds i p.receiver e ∧ TargetHolds i p.target e

/-- What the OAuth2, application and sync-account modules may release, without
a profile. -/
def fixedSearchAttrs : List (List Nat) :=
  ["class", "displayname", "uuid", "name", "oauth2_rs_origin_landing", "image", "linked_group",
   "sync_credential_portal"].map lit

/-- Some search profile that applies grants attribute `a` on `e`, or `a` is one
of the fixed attributes. -/
def SearchGrants (ctl : AccessControlsInner) (i : Identity) (e : Entry) (a : List Nat) : Prop :=
  (∃ acs ∈ ctl.acps_search.val, a ∈ names acs.attrs.val ∧ Applies i acs.acp e) ∨ a ∈ fixedSearchAttrs

/-- `PROTECTED_ENTRY_CLASSES`: may not be created or deleted. -/
def protectedEntryClasses : List (List Nat) :=
  ["system", "domain_info", "system_info", "system_config", "dyngroup", "sync_object", "tombstone",
   "recycled"].map lit

/-- `PROTECTED_MOD_ENTRY_CLASSES`. -/
def protectedModEntryClasses : List (List Nat) :=
  ["system", "domain_info", "system_info", "system_config", "dyngroup", "tombstone", "recycled"].map lit

/-- `PROTECTED_MOD_PRES_ENTRY_CLASSES`: may not be added to any entry. -/
def protectedModPresClasses : List (List Nat) := protectedEntryClasses

/-- The attribute a modification asks to make present (`requested_pres`). -/
def presAttr : Modify → Option (List Nat)
  | .Present a _ | .Set a _ | .Assert a _ => some (nats a.val)
  | .Removed _ _ | .Purged _ => none

/-- `Value::to_str`. -/
def strOf : PartialValue → Option (List Nat)
  | .Utf8 s | .Iutf8 s | .Iname s => some (nats s.val)
  | _ => none

/-- What a user may always change on a synchronised entry. -/
def syncAttrs : List (List Nat) :=
  ["user_auth_token_session", "oauth2_session", "oauth2_consent_scope_map",
   "credential_update_intent_token"].map lit

/-- The attributes the sync agreement `u` yields to kanidm. -/
def agreementAttrs (sa : List SyncAgreement) (u : U128) : List (List Nat) :=
  match sa.find? (fun a => a.uuid == u) with
  | some a => names a.attrs.val
  | none => []

/-- The value set holds the value (`ValueSetT::contains`). -/
def ValueContains : ValueSet → PartialValue → Prop
  | .Utf8 s, .Utf8 x => x ∈ s.val
  | .Iutf8 s, .Iutf8 x => x ∈ s.val
  | .Iname s, .Iname x => x ∈ s.val
  | .Uuid s, .Uuid u => u ∈ s.val
  | .Refer s, .Refer u => u ∈ s.val
  | .Uint32 s, .Uint32 n => n ∈ s.val
  | .OauthScopeMap s, .Refer u => u ∈ s.val
  | _, _ => False

end kanidm_kernel.Spec
