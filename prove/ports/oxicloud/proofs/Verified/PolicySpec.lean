import Verified.Derived
open Aeneas Aeneas.Std Result oxicloud_kernel
open H5iAppLib hiding lit
namespace oxicloud_kernel.PolicySpec
/-- A drive's explicit choices override its kind's defaults, including explicit
false choices. An absent expiry cap override inherits the default cap. -/
def PolicyResolved (d : drivepolicy.Policies) (o : drivepolicy.Overrides)
    (r : drivepolicy.Policies) : Prop :=
  r.forbid_sharing = o.forbid_sharing.getD d.forbid_sharing ∧
  r.forbid_external_sharing = o.forbid_external_sharing.getD d.forbid_external_sharing ∧
  r.forbid_public_links = o.forbid_public_links.getD d.forbid_public_links ∧
  r.forbid_cross_drive_move = o.forbid_cross_drive_move.getD d.forbid_cross_drive_move ∧
  r.forbid_owner_role_change = o.forbid_owner_role_change.getD d.forbid_owner_role_change ∧
  r.include_in_photo_index = o.include_in_photo_index.getD d.include_in_photo_index ∧
  r.include_in_music_index = o.include_in_music_index.getD d.include_in_music_index ∧
  r.read_only = o.read_only.getD d.read_only ∧
  r.require_public_link_password = o.require_public_link_password.getD d.require_public_link_password ∧
  r.max_public_link_days = o.max_public_link_days.or d.max_public_link_days

/-- Both the broad sharing policy and the link-specific policy permit minting. -/
def PublicLinksAllowed (p : drivepolicy.Policies) : Prop :=
  p.forbid_sharing = false ∧ p.forbid_public_links = false

def SharingAllowed (p : drivepolicy.Policies) : Prop := p.forbid_sharing = false

/-- Administrators may manage a locked owner roster. -/
def OwnerChangesAllowed (p : drivepolicy.Policies) (admin : Bool) : Prop :=
  p.forbid_owner_role_change = false ∨ admin = true

def CrossDriveMoveAllowed (p : drivepolicy.Policies) : Prop :=
  p.forbid_cross_drive_move = false

/-- Only external user principals are constrained by the external-sharing knob. -/
def ExternalSharingAllowed (p : drivepolicy.Policies) (s : model.Subject) (external : Bool) : Prop :=
  p.forbid_external_sharing = false ∨ (∀ id, s ≠ .User id) ∨ external = false

/-- A policy guard succeeds exactly when allowed and otherwise returns the
canonical unsupported-operation refusal. -/
def GuardDecision (allowed : Prop) (r : core.result.Result Unit model.ErrorKind) : Prop :=
  (r = .Ok () ↔ allowed) ∧ (r = .Err .OperationNotSupported ↔ ¬allowed)




/-- Canonical order of independently configurable drive policies. -/
def PolicyKnobOrder : List policycompare.Knob :=
  [.ForbidSharing, .ForbidExternalSharing, .ForbidPublicLinks, .ForbidCrossDriveMove,
   .ForbidOwnerRoleChange, .IncludeInPhotoIndex, .IncludeInMusicIndex, .ReadOnly,
   .MaxPublicLinkDays, .RequirePublicLinkPassword]

def PolicyBit (p : drivepolicy.Policies) : policycompare.Knob → Bool
  | .ForbidSharing => p.forbid_sharing
  | .ForbidExternalSharing => p.forbid_external_sharing
  | .ForbidPublicLinks => p.forbid_public_links
  | .ForbidCrossDriveMove => p.forbid_cross_drive_move
  | .ForbidOwnerRoleChange => p.forbid_owner_role_change
  | .IncludeInPhotoIndex => p.include_in_photo_index
  | .IncludeInMusicIndex => p.include_in_music_index
  | .ReadOnly => p.read_only
  | .RequirePublicLinkPassword => p.require_public_link_password
  | _ => false

/-- Every configured upper bound is respected, with no bound weaker than any finite bound. -/
def PolicyCapRefines (own required : Option U32) : Prop :=
  ∀ bound, required = some bound → ∃ cap, own = some cap ∧ cap.val ≤ bound.val

/-- Refinement preserves prohibitions, reduces index exposure, and tightens link lifetimes. -/
def PolicyRefines (p q : drivepolicy.Policies) (knob : policycompare.Knob) : Prop :=
  match knob with
  | .MaxPublicLinkDays => PolicyCapRefines p.max_public_link_days q.max_public_link_days
  | .IncludeInPhotoIndex | .IncludeInMusicIndex => PolicyBit p knob = true → PolicyBit q knob = true
  | _ => PolicyBit q knob = true → PolicyBit p knob = true

def PolicyApplies (knob : policycompare.Knob) (kind : model.DriveKind) : Prop :=
  knob ≠ .ForbidOwnerRoleChange ∨ kind ≠ .Personal

def PolicyDefaultable (knob : policycompare.Knob) : Prop := knob ≠ .ReadOnly

/-- Drift consists only of applicable standing defaults that the current drive fails to refine. -/
def PolicyWeak (p d : drivepolicy.Policies) (kind : model.DriveKind) (knob : policycompare.Knob) : Prop :=
  PolicyApplies knob kind ∧ PolicyDefaultable knob ∧ ¬PolicyRefines p d knob

noncomputable def PolicyWeakerList (p d : drivepolicy.Policies) (kind : model.DriveKind) : List policycompare.Knob := by
  classical
  exact PolicyKnobOrder.filter (fun knob => decide (PolicyWeak p d kind knob))

/-- Policy values have exactly the boolean, bounded-integer, or null shape declared by their knob. -/
def PolicyValue (p : drivepolicy.Policies) (knob : policycompare.Knob) (out : policycompare.KnobValue) : Prop :=
  match knob with
  | .Other => out = .Null
  | .MaxPublicLinkDays =>
    match p.max_public_link_days with
    | none => out = .Null
    | some n => out = .Number n
  | _ => out = .Bool (PolicyBit p knob)

/-- Opt-in indices are false-stricter, link lifetime is smaller-stricter, and other flags are true-stricter. -/
def PolicyStrictness (knob : policycompare.Knob) (out : policycompare.Strictness) : Prop :=
  match knob with
  | .IncludeInPhotoIndex | .IncludeInMusicIndex => out = .FalseIsStricter
  | .MaxPublicLinkDays => out = .SmallerIsStricter
  | _ => out = .TrueIsStricter



end oxicloud_kernel.PolicySpec
