import SpooleaseKernel
import H5iAppLib.Basic
import H5iAppLib.Loops
/-!
# List-level model of the SpoolEase inventory store

`Spec` describes the store as a plain `Model` (a `List Slot` plus the append
point and last id) and states the integrity invariant `Inv` over it, without
mentioning the extracted kernel's `Vec`/loops. `Properties.lean` proves the
kernel's `transition` keeps `Inv` and that its write plan never leaves a
record's own slot.
-/
open Aeneas Aeneas.Std Result spoolease_kernel

namespace spoolease_kernel.Spec

/-! ## Constant values -/

theorem max_file_val : MAX_FILE.val = 16777216 := by unfold MAX_FILE; rfl
theorem max_rec_val : MAX_REC.val = 4096 := by unfold MAX_REC; rfl
theorem max_id_val : MAX_ID.val = 4294967294 := by unfold MAX_ID; rfl

/-! ## The model -/

/-- The abstract store: just the fields the integrity invariant talks about. -/
structure Model where
  file_len : U32
  last_id : U32
  slots : List Slot

/-- Read a kernel `Store` as a `Model`. -/
def toM (s : Store) : Model :=
  { file_len := s.file_len, last_id := s.last_id, slots := s.slots.val }

/-! ## Slot geometry -/

/-- Last byte+1 of a slot's region in the `.db` file. -/
def slotEnd (s : Slot) : Nat := s.offset.val + s.length.val

/-- Two slots own non-overlapping byte ranges. -/
def Disj (a b : Slot) : Prop := slotEnd a ≤ b.offset.val ∨ slotEnd b ≤ a.offset.val

/-- Position `p` lies inside slot `s`'s region. -/
def inSlot (s : Slot) (p : Nat) : Prop := s.offset.val ≤ p ∧ p < slotEnd s

/-! ## The integrity invariant

Everything a plausible allocator bug would break:

* `file_len` and `last_id` stay inside their hard caps (so the arithmetic in
  `place` / `AddSpool` never overflows);
* every slot is non-empty, no wider than `MAX_REC`, and wholly inside the file;
* every slot id is in `1 ..= last_id` (ids are handed out monotonically);
* no two slots share an id (the record index is a map);
* no two slots' byte ranges overlap (two spools never alias storage);
* every non-zero NFC tag is held by at most one slot.
-/
def BoundsOk (m : Model) : Prop :=
  m.file_len.val ≤ 16777216 ∧ m.last_id.val ≤ 4294967294 ∧
  ∀ s ∈ m.slots, 1 ≤ s.length.val ∧ s.length.val ≤ 4096 ∧ slotEnd s ≤ m.file_len.val

def IdsOk (m : Model) : Prop :=
  ∀ s ∈ m.slots, 1 ≤ s.id.val ∧ s.id.val ≤ m.last_id.val

/-- No two distinct positions in the list carry the same id. -/
def IdUnique (m : Model) : Prop := List.Pairwise (fun a b => a.id ≠ b.id) m.slots

def DisjAll (m : Model) : Prop := List.Pairwise Disj m.slots

/-- A non-zero tag is functional: it determines the id. -/
def TagUnique (m : Model) : Prop :=
  ∀ a ∈ m.slots, ∀ b ∈ m.slots, a.tag.val ≠ 0 → a.tag = b.tag → a.id = b.id

def Inv (m : Model) : Prop :=
  BoundsOk m ∧ IdsOk m ∧ IdUnique m ∧ DisjAll m ∧ TagUnique m

/-! ## The list transforms the kernel's loops compute -/

/-- `claim_tag`'s per-element rewrite: give `tag` to `keeper`, strike it from
every other holder. -/
def claimOne (keeper tag : U32) (s : Slot) : Slot :=
  if s.id = keeper then { s with tag := tag }
  else if tag != 0#u32 then (if s.tag = tag then { s with tag := 0#u32 } else s)
  else s

/-- `replace_slot`'s per-element rewrite. -/
def replaceOne (id : U32) (ns s : Slot) : Slot := if s.id = id then ns else s

/-! ## The write set applied to the model -/

/-- How a committed write set changes the model (mirrors `apply`: a `Some`
snapshot replaces the state, a `None` leaves it; `clone` preserves fields). -/
def applyM (m : Model) : Option Store → Model
  | none => m
  | some n => toM n

end spoolease_kernel.Spec
