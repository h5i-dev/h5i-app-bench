import SynctvKernel
import H5iAppLib
/-!
# What synctv's security decisions should do

The file to review. Everything here is stated over plain natural numbers, bit
indices and propositions; nothing calls a kernel function. The bit tables are
read off upstream `synctv-core/src/models/permission.rs` @ 38970e0.

* A permission set is a number; it grants `p` when bit `adminBit p` is set.
* Each role has its own override bitspace (`memberBit`, `guestBit`, admin bits).
  An override names `p` when the bit of `p` in that bitspace is set.
* Effective permissions follow the allow/deny pattern: (base ∪ added) \ removed,
  where only permissions that exist in the role's bitspace can be added or removed,
  and a guest's base is cut down to the guest-assignable permissions.
-/
open Aeneas Aeneas.Std synctv_kernel

namespace synctv_kernel.Spec

/-- Bit of each permission in the effective (admin) bitspace. -/
def adminBit : perms.RoomPermission → Nat
  | .SendChatMessages => 0
  | .ManageOwnMedia => 1
  | .BrowseLibrary => 2
  | .ViewMembers => 3
  | .ViewChatHistory => 4
  | .UseVoiceChat => 5
  | .DeleteMedia => 6
  | .ReorderMedia => 7
  | .ClearMedia => 8
  | .ManageLiveStreams => 9
  | .ControlPlaybackState => 10
  | .NavigatePlayback => 11
  | .ReviewJoinRequests => 12
  | .RemoveMembers => 13
  | .ManageMemberPermissions => 14
  | .AddMembers => 15
  | .ManageRoomSettings => 16
  | .DeleteChatMessages => 17
  | .DeleteRoom => 18
  | .ViewPlaybackHistory => 19
  | .UseP2pMedia => 20

/-- Admin overrides can name every permission, at its effective bit. -/
def adminSpace (p : perms.RoomPermission) : Option Nat := some (adminBit p)

/-- Bit of each member-assignable permission in the member override bitspace. -/
def memberBit : perms.RoomPermission → Option Nat
  | .SendChatMessages => some 0
  | .ManageOwnMedia => some 1
  | .BrowseLibrary => some 2
  | .ViewMembers => some 3
  | .ViewChatHistory => some 4
  | .UseVoiceChat => some 5
  | .UseP2pMedia => some 6
  | _ => none

/-- Bit of each guest-assignable permission in the guest override bitspace. -/
def guestBit : perms.RoomPermission → Option Nat
  | .ViewMembers => some 32
  | .ViewChatHistory => some 33
  | .UseVoiceChat => some 34
  | .UseP2pMedia => some 35
  | _ => none

/-- The permissions a guest may ever hold. -/
def guestAssignable (p : perms.RoomPermission) : Prop := (guestBit p).isSome

/-- The permissions a member override may add or remove. -/
def memberAssignable (p : perms.RoomPermission) : Prop := (memberBit p).isSome

/-- The permission set `set` grants `p`. -/
def grants (set : Nat) (p : perms.RoomPermission) : Prop := set.testBit (adminBit p) = true

/-- The override bits `bits` of bitspace `space` name `p`. -/
def names (space : perms.RoomPermission → Option Nat) (bits : Nat) (p : perms.RoomPermission) : Prop :=
  ∃ j, space p = some j ∧ bits.testBit j = true

/-- Allow/deny: granted by the base or added, and not removed. -/
def allowDeny (space : perms.RoomPermission → Option Nat) (base : Prop) (added removed : Nat)
    (p : perms.RoomPermission) : Prop :=
  (base ∨ names space added p) ∧ ¬ names space removed p

/-- A member's effective permissions (`RoomMember::effective_permissions`) over the
role default `base`: the creator holds everything; admins use the admin override
columns, members and guests the plain ones, each in its own bitspace. -/
def effective (m : perms.MemberPerms) (base : perms.RoomPermission → Prop) (p : perms.RoomPermission) : Prop :=
  match m.role with
  | .Creator => True
  | .Admin => allowDeny adminSpace (base p) m.admin_added_permissions.val m.admin_removed_permissions.val p
  | .Member => allowDeny memberBit (base p) m.added_permissions.val m.removed_permissions.val p
  | .Guest => allowDeny guestBit (base p ∧ guestAssignable p) m.added_permissions.val
      m.removed_permissions.val p

/-- The role default in a room (`EffectivePermissionCalculator::role_default`): the
server-wide default of the role, adjusted by the room's settings overrides. -/
def roleDefault (d : perms.Defaults) (s : perms.SettingsPerms) (r : perms.Role) (p : perms.RoomPermission) : Prop :=
  match r with
  | .Creator => True
  | .Admin => allowDeny adminSpace (grants d.admin.val p) s.admin_added_permissions.val
      s.admin_removed_permissions.val p
  | .Member => allowDeny memberBit (grants d.member.val p) s.member_added_permissions.val
      s.member_removed_permissions.val p
  | .Guest => allowDeny guestBit (grants d.guest.val p ∧ guestAssignable p)
      s.guest_added_permissions.val s.guest_removed_permissions.val p

/-- `EffectivePermissionCalculator::has_permission`: the member's own overrides must
allow `p` even over a full default, and the effective permissions must grant it. -/
def calcHas (d : perms.Defaults) (s : perms.SettingsPerms) (m : perms.MemberPerms)
    (p : perms.RoomPermission) : Prop :=
  effective m (fun _ => True) p ∧ effective m (roleDefault d s m.role) p

/-! ## Member role policy (`service/room/member_role_policy.rs`) -/

/-- A role update is allowed only from the room creator, never targets the creator,
and never confers the creator role. -/
def roleUpdateAllowed (createdBy actor target : Int) (newRole : perms.Role) : Prop :=
  newRole ≠ .Creator ∧ actor = createdBy ∧ target ≠ createdBy

/-- Bits all inside a bitspace of `width`-many bits starting at `lo`. -/
def withinSpace (lo width : Nat) (bits : Nat) : Prop :=
  ∀ i, bits.testBit i = true → lo ≤ i ∧ i < lo + width

/-- The override bitspace of each role, as `(lowest bit, width)`. -/
def roleSpace : perms.Role → Nat × Nat
  | .Creator => (0, 21)
  | .Admin => (0, 21)
  | .Member => (0, 7)
  | .Guest => (32, 4)

/-! ## Global roles (`models/user.rs`) -/

/-- Rank of a global role; a role manages exactly the roles strictly below it, and
root manages everyone. -/
def userRank : auth.UserRole → Nat
  | .Root => 2
  | .Admin => 1
  | .User => 0

def manages (a b : auth.UserRole) : Prop := a = .Root ∨ userRank b < userRank a

/-! ## Tokens -/

/-- A token with expiry `exp` is still valid at `now` with clock-skew leeway `leeway`
(seconds; a leeway above `i64::MAX` counts as `i64::MAX`, and the sum saturates at
`i64::MAX`). -/
def notExpired (now exp : Int) (leeway : Nat) : Prop :=
  now ≤ min (exp + min leeway (2 ^ 63 - 1)) (2 ^ 63 - 1)

/-- Visible ASCII whitespace as `str::trim` sees it. -/
def isWs (b : Nat) : Prop := b = 32 ∨ (9 ≤ b ∧ b ≤ 13)

/-! ## Path traversal (`synctv-common/src/validation.rs`) -/

/-- The value of an ASCII hex digit. -/
def hexDigit (b : Nat) : Option Nat :=
  if 48 ≤ b ∧ b ≤ 57 then some (b - 48)
  else if 97 ≤ b ∧ b ≤ 102 then some (b - 87)
  else if 65 ≤ b ∧ b ≤ 70 then some (b - 55)
  else none

/-- The byte `%ab` encodes. -/
def hexPair (a b : Nat) : Option Nat :=
  match hexDigit a, hexDigit b with
  | some h, some l => some (16 * h + l)
  | _, _ => none

/-- One round of percent-decoding: every `%` followed by two hex digits becomes the
byte they encode; everything else is kept. -/
def decodeOnce : List Nat → List Nat
  | 37 :: a :: b :: rest =>
    match hexPair a b with
    | some v => v :: decodeOnce rest
    | none => 37 :: decodeOnce (a :: b :: rest)
  | c :: rest => c :: decodeOnce rest
  | [] => []

/-- The byte `%xy` at positions `j, j+1` encodes, if both are hex digits. -/
def pairAt (l : List Nat) (j : Nat) : Option Nat :=
  match l[j]?, l[j + 1]? with
  | some x, some y => hexPair x y
  | _, _ => none

/-- Position `i` starts an encoded dot: `%2e`, `%25` + `2e`, or `%25` + `25` + `2e`
(hex in either case). -/
def encAt (l : List Nat) (i : Nat) : Prop :=
  l[i]? = some 37 ∧ (pairAt l (i + 1) = some 46 ∨ (pairAt l (i + 1) = some 37 ∧
    (pairAt l (i + 3) = some 46 ∨ (pairAt l (i + 3) = some 37 ∧ pairAt l (i + 5) = some 46))))

/-- A path that is an obvious traversal or injection: a literal `..`, a NUL byte, an
encoded NUL `%00`, or `./.`. -/
def literalTraversal (p : List Nat) : Prop :=
  [46, 46] <:+: p ∨ 0 ∈ p ∨ [37, 48, 48] <:+: p ∨ [46, 47, 46] <:+: p

end synctv_kernel.Spec
