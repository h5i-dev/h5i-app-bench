import WastebinKernel
import H5iAppLib
/-!
# wastebin's paste access policy: the spec

From wastebin's code, README and comments at c0ec968 (`wastebin_core/src/db.rs`,
`wastebin_server/src/handlers/**`, `cache.rs`). Everything here is over plain
lists and values; nothing calls the kernel's functions.

The table is a list of rows; `id` is the primary key, so the first row with
an id is the row. A paste is *expired* when its `expires` time lies before
`now`; it *burns* when its `burn_after_reading` column is `true`; it is
*encrypted* with password `k` when its `secret` is `some k`.
-/
open Aeneas Aeneas.Std wastebin_kernel

namespace wastebin_kernel.Spec

abbrev Row := store.Row

/-- The row the statements `WHERE id=?1` read. -/
def rowOf (rows : List Row) (id : I64) : Option Row := rows.find? (fun r => r.id = id)

/-- `DELETE FROM entries WHERE id=?1`. -/
def without (rows : List Row) (id : I64) : List Row := rows.filter (fun r => r.id ≠ id)

/-- `expires < datetime('now')`; a paste without an expiry never expires. -/
def Expired (r : Row) (now : Int) : Prop := ∃ e, r.expires = some e ∧ e.val < now

/-- `burn_after_reading` is set. -/
def Burns (r : Row) : Prop := r.burn = some true

instance (r : Row) : Decidable (Burns r) := inferInstanceAs (Decidable (r.burn = some true))

/-- `expires < now`, `NULL` read as false. -/
def expiredB (r : Row) (now : Int) : Bool :=
  match r.expires with
  | none => false
  | some e => decide (e.val < now)

instance (r : Row) (now : Int) : Decidable (Expired r now) :=
  decidable_of_iff (expiredB r now = true) (by
    unfold Expired expiredB; rcases r.expires with _ | e <;> simp)

/-- The password a reader presents opens the paste: it is plaintext, or the
password is the one it was encrypted with. -/
def Opens (r : Row) (pw : Option U64) : Prop := r.secret = none ∨ (∃ k, r.secret = some k ∧ pw = some k)

/-- The verified `uid` cookie lists the owner of a paste; a paste without an
owner is owned by nobody. -/
def Owns (uids : List I64) (owner : Option I64) : Prop := ∃ u, owner = some u ∧ u ∈ uids

/-- The rows a deletion by the holder of `uids` removes. -/
def deletedBy (rows : List Row) (id : I64) (uids : List I64) : List Row :=
  rows.filter (fun r => !(decide (r.id = id) && decide (∃ u, r.uid = some u ∧ u ∈ uids)))

/-- Bytes that may appear in a paste URL path segment the server emits:
ASCII alphanumerics and `-`, `+`, `.`, `_`. In particular none of
`/ " ' < > & % ? #`, whitespace or control bytes. -/
def UrlSafe (b : Nat) : Prop :=
  (48 ≤ b ∧ b ≤ 57) ∨ (65 ≤ b ∧ b ≤ 90) ∨ (97 ≤ b ∧ b ≤ 122) ∨ b = 45 ∨ b = 43 ∨ b = 46 ∨ b = 95

/-- `valid_extension`'s byte class: ASCII alphanumerics, `.`, `_`, `-`. -/
def ExtByte (b : Nat) : Prop :=
  (48 ≤ b ∧ b ≤ 57) ∨ (65 ≤ b ∧ b ≤ 90) ∨ (97 ≤ b ∧ b ≤ 122) ∨ b = 46 ∨ b = 95 ∨ b = 45

/-- The id alphabet `CHAR_TABLE`: `a-z`, `A-Z`, `0-9`, `-`, `+`, in that
order; a character's position is its six-bit value. -/
def alphabet : List Nat :=
  (List.range 26).map (· + 97) ++ (List.range 26).map (· + 65) ++ (List.range 10).map (· + 48) ++ [45, 43]

/-- Header-safe bytes: visible ASCII without the separators `"`, `;`, `,`,
`\`, and without CR, LF and other controls. -/
def HeaderToken (b : Nat) : Prop :=
  (48 ≤ b ∧ b ≤ 57) ∨ (65 ≤ b ∧ b ≤ 90) ∨ (97 ≤ b ∧ b ≤ 122) ∨
    b = 46 ∨ b = 45 ∨ b = 95 ∨ b = 126 ∨ b = 43 ∨ b = 37

/-- The content and metadata an entry carries. -/
def entryData : store.Entry → store.Data
  | .Regular d => d
  | .Burned d => d
  | .Encrypted d => d

/-- `Entry::Encrypted`: the callers mark the response `no-store` and keep it
out of the cache. -/
def isEncrypted : store.Entry → Bool
  | .Encrypted _ => true
  | _ => false

/-- Concurrent burn-after-reading readers. Each reader has already read and
decrypted the paste (`fetch` answered `Ready`), possibly all from the same
table state; their burning `DELETE`s (`finish`) then run one after another,
in any order. The result lists which readers got the content. -/
def burnReaders (id : I64) : List (store.Data × Bool) → alloc.vec.Vec Row → Result (List Bool)
  | [], _ => .ok []
  | (d, enc) :: rs, v => do
    let (v', res) ← store.finish v id d enc true
    let bs ← burnReaders id rs v'
    .ok ((match res with | .Ok _ => true | .Err _ => false) :: bs)

end wastebin_kernel.Spec
