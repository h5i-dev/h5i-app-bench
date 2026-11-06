import CratesioKernel
import H5iAppLib
/-!
# crates.io's publishing authorization policy: the spec

From crates.io's code, RFC 2947 (scoped API tokens) and the Trusted
Publishing documentation at e0fc83a. Everything here is over plain lists and
values; nothing calls the kernel's functions.
-/
open Aeneas Aeneas.Std cratesio_kernel

namespace cratesio_kernel.Spec

instance : DecidableEq scopes.EndpointScope := fun a b => by
  cases a <;> cases b <;> first | exact isTrue rfl | exact isFalse (by intro h; cases h)

/-- An account lock is in force: a lock reason is set and the lock has no end
or ends after `now`. -/
def Locked (u : auth.User) (now : Int) : Prop :=
  u.lock_reason = true ∧ (u.lock_until = none ∨ ∃ t, u.lock_until = some t ∧ now < t.val)

/-- A token row accepts a presented secret at `now`: not revoked, not
expired, and the same secret. -/
def Live (t : auth.ApiToken) (secret : List U8) (now : Int) : Prop :=
  t.revoked = false ∧ (t.expired_at = none ∨ ∃ e, t.expired_at = some e ∧ now < e.val) ∧
    t.secret.val = secret

/-- A crate scope pattern covers a crate name (RFC 2947): `prefix*` covers the
names starting with `prefix` (so `*` covers all), any other pattern exactly
itself. -/
def Covers (p n : List U8) : Prop :=
  (∃ pre, p = pre ++ [42#u8] ∧ pre <+: n) ∨ p = n

/-- The token is a legacy token (no endpoint scopes): it may use every
endpoint that accepts tokens. -/
def Legacy (t : auth.ApiToken) : Prop := t.endpoint_scopes = none

/-- The session epoch the cookie carries, if it parses (absent is 0). -/
def epochOf : auth.Epoch → Option Int
  | .Absent => some 0
  | .Invalid => none
  | .Value v => some v.val

end cratesio_kernel.Spec
