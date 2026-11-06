import DefguardKernel
import H5iAppLib
/-!
# defguard: the policy

Stated from defguard's code and comments at 12508b4 (`auth/failed_login.rs`,
`handlers/auth.rs`, `auth/mod.rs`, `handlers/mod.rs`, `db/models/enrollment.rs`,
`servers/enrollment.rs`, `enterprise/utils.rs`) over plain lists and
integers. Nothing here calls the kernel's functions.
-/
open Aeneas Aeneas.Std defguard_kernel

namespace defguard_kernel.Spec

/-! ## Failed-login lockout -/

/-- The tracker's entry for name `k` (`HashMap::get`). -/
def entryFor (map : List lockout.FailedLogin) (k : List U8) : Option lockout.FailedLogin :=
  map.find? (fun f => decide (f.key.val = k))

/-- Name `k` is locked out at `now`: at least five failures, the last one at
most five minutes ago. -/
def Locked (map : List lockout.FailedLogin) (k : List U8) (now : Int) : Prop :=
  ∃ f, entryFor map k = some f ∧ 5 ≤ f.attempt_count.val ∧ now - f.last_attempt.val ≤ 300000000000

/-- PostgreSQL `LOWER` on an ASCII byte. -/
def lowerN (n : Nat) : Nat := if 65 ≤ n ∧ n ≤ 90 then n + 32 else n

/-- `LOWER(a) = LOWER(b)`. -/
def LowerEq (a b : List U8) : Prop := a.map (fun c => lowerN c.val) = b.map (fun c => lowerN c.val)

/-- Some account's username is exactly `k`. -/
def IsUsername (us : List lockout.Account) (k : List U8) : Prop := ∃ a ∈ us, a.username.val = k

/-! ## API guards -/

/-- The user is in a group with the `is_admin` flag. -/
def IsAdmin (u : auth.User) (adminGroups : List (alloc.vec.Vec U8)) : Prop :=
  ∃ g ∈ u.groups.val, ∃ a ∈ adminGroups, a.val = g.val

/-- The session a credential authenticates at `now`: a stored, unexpired
session row, or (with a business licence) an API token of an active user. -/
def Presents (license : Bool) (cred : auth.Credential) (now : Int) (s : auth.Session) : Prop :=
  match cred with
  | .Cookie (some row) => row = s ∧ now ≤ row.expires.val
  | .Bearer (some uid) => license = true ∧ s.user_id = uid ∧ s.state = .ApiTokenVerified
  | _ => False

/-! ## Enrollment tokens -/

/-- An enrollment session is open at `now`: the token was first used at
`u` and `now < u + timeout`. -/
def SessionOpen (t : token.Token) (now timeout : Int) : Prop :=
  ∃ u, t.used_at = some u ∧ now < u.val + timeout

end defguard_kernel.Spec

namespace defguard_kernel.Spec

/-! ## Device addresses (`ipnetwork`, `assign_next_network_ip`) -/

/-- Host bits of a subnet. -/
def hostBits (n : ipalloc.Net) : Nat := if n.v4 then 32 - min 32 n.prefix.val else 128 - min 128 n.prefix.val

/-- `network()`. -/
def netLo (n : ipalloc.Net) : Nat := n.ip.val / 2 ^ hostBits n * 2 ^ hostBits n

/-- `broadcast()`. -/
def netHi (n : ipalloc.Net) : Nat := netLo n + 2 ^ hostBits n - 1

/-- The address is in the subnet. -/
def InNet (n : ipalloc.Net) (ip : ipalloc.Ip) : Prop :=
  ip.v4 = n.v4 ∧ netLo n ≤ ip.bits.val ∧ ip.bits.val ≤ netHi n

/-- An address a device may be given in subnet `n`: inside it, not its
network, broadcast or gateway address, and neither in use nor reserved. -/
def Assignable (n : ipalloc.Net) (used reserved : List ipalloc.Ip) (ip : ipalloc.Ip) : Prop :=
  InNet n ip ∧ ip.bits.val ≠ netLo n ∧ ip.bits.val ≠ netHi n ∧ ip.bits.val ≠ n.ip.val ∧
    ip ∉ used ∧ ip ∉ reserved

end defguard_kernel.Spec

namespace defguard_kernel.Spec

/-! ## Firewall port and address ranges (`merge_ranges`) -/

/-- Value `x` lies in one of the inclusive ranges. -/
def InRanges (l : List ranges.Range) (x : Nat) : Prop := ∃ r ∈ l, r.start.val ≤ x ∧ x ≤ r.end.val

/-- No two ranges of the list share a value. -/
def PairwiseDisjoint (l : List ranges.Range) : Prop :=
  l.Pairwise (fun a b => a.end.val < b.start.val ∨ b.end.val < a.start.val)

end defguard_kernel.Spec

namespace defguard_kernel.Spec

/-- Each range ends at least two values before the next one starts: the
ranges are sorted, disjoint and not adjacent (adjacent ones would merge). -/
def Separated (l : List ranges.Range) : Prop :=
  l.Pairwise (fun a b => a.end.val + 1 < b.start.val)

end defguard_kernel.Spec
