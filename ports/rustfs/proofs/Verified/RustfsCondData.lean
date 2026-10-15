import Verified.RustfsValids
import SpecCondData
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsValids
open rustfs_kernel.Verified.RustfsForceDelete (bytes_eq_ok deref_val)

namespace rustfs_kernel.Verified.RustfsCondData

/-- Key membership compares the full key name independently of its suffix. -/
theorem key_is_ok (k : condfuncs.Key) (needle : Slice U8) (b : Bool)
    (h : conddata.key_is k needle = ok b) : (b = true ↔ k.key_name.val = needle.val) := by
  unfold conddata.key_is at h
  have hh := bytes_eq_ok _ _ _ h
  simpa only [deref_val] using hh

theorem contains_key_name_ok {T : Type} (f : conddata.InnerFunc T) (needle : Slice U8) (b : Bool)
    (h : conddata.contains_key_name f needle = ok b) :
    (b = true ↔ ∃ e ∈ f.entries.val, e.key.key_name.val = needle.val) := by
  unfold conddata.contains_key_name conddata.contains_key_name_loop at h
  refine any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold conddata.contains_key_name_loop.body at hr
  h5i_invert hr
  · have h0 := vec_index_slice_ok_get? hfkv
    have hlt : i.val < f.entries.val.length := by scalar_tac
    have hk := key_is_ok fkv.key needle _ (by assumption)
    rw [List.getElem?_eq_getElem hlt] at h0
    simp only [Option.some.injEq] at h0
    exact .inl ⟨hlt, by rw [h0]; exact hk.1 hc_1, rfl⟩
  · have h0 := vec_index_slice_ok_get? hfkv
    have hlt : i.val < f.entries.val.length := by scalar_tac
    have hk := key_is_ok fkv.key needle _ (by assumption)
    rw [List.getElem?_eq_getElem hlt] at h0
    simp only [Option.some.injEq] at h0
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [h0]; intro he; exact hc_1 (hk.2 he)
  · exact .inr ⟨by scalar_tac, rfl⟩

/-- No condition remains in any of the three quantifier groups. -/
theorem empty_ok (f : conddata.Functions) (b : Bool) (h : conddata.is_empty f = ok b) :
    (b = true ↔ f.for_any_value.val = [] ∧ f.for_all_values.val = [] ∧ f.for_normal.val = []) := by
  unfold conddata.is_empty at h
  simp only [len_zero] at h
  by_cases ha : f.for_any_value.val = [] <;> by_cases hb : f.for_all_values.val = [] <;>
    simp_all <;> subst h <;> simp_all


theorem op_notip_eq (op : conddata.Op) :
    conddata.Op.Insts.CoreCmpPartialEqOp.eq op .NotIpAddress = ok (decide (op = .NotIpAddress)) := by
  cases op <;> simp [conddata.Op.Insts.CoreCmpPartialEqOp.eq, conddata.Op.read_discriminant]

/-- Negation here is confined to the unwrapped negative IP operator. -/
theorem negate_ok (c : conddata.Condition) (b : Bool) (h : conddata.is_negate c = ok b) :
    (b = true ↔ c.wrappers.val = 0 ∧ c.op = .NotIpAddress) := by
  unfold conddata.is_negate at h
  have hz : c.wrappers = 0#usize ↔ c.wrappers.val = 0 := by
    constructor
    · intro hh; rw [hh]; rfl
    · intro hh; apply UScalar.eq_of_val_eq; simpa using hh
  by_cases hw : c.wrappers.val = 0
  · simp only [hz, hw, ↓reduceIte, op_notip_eq, Result.ok.injEq] at h
    subst b; simp [hw]
  · simp only [hz, hw, ↓reduceIte, Result.ok.injEq] at h
    subst b; simp [hw]

/-- One step of a traversal rejecting the first element that fails `P`. -/
def AllStep {α} (l : List α) (P : α → Prop) (i : Usize) : ControlFlow Usize Bool → Prop
  | .done b => (∃ h : i.val < l.length, ¬ P l[i.val] ∧ b = false) ∨ (l.length ≤ i.val ∧ b = true)
  | .cont j => ∃ h : i.val < l.length, P l[i.val] ∧ j.val = i.val + 1

theorem all_loop {α} (l : List α) (P : α → Prop) (body : Usize → Result (ControlFlow Usize Bool))
    (hb : ∀ i r, i.val ≤ l.length → body i = ok r → AllStep l P i r) (r : Bool)
    (h : loop body 0#usize = ok r) : (r = true ↔ ∀ x ∈ l, P x) := by
  refine loop_ok _ (fun i : Usize => i.val ≤ l.length ∧ ∀ x ∈ l.take i.val, P x)
    (fun r => r = true ↔ ∀ x ∈ l, P x) (fun i : Usize => l.length - i.val) ?_ _ r
    ⟨by simp, by simp⟩ h
  rintro i r ⟨hi, hx⟩ hr
  have hh := hb i r hi hr
  cases r with
  | done b =>
    rcases hh with ⟨hlt, hp, rfl⟩ | ⟨hle, rfl⟩
    · simp only [Bool.false_eq_true, false_iff]
      intro hall; exact hp (hall _ (List.getElem_mem hlt))
    · simp only [true_iff]
      rw [List.take_of_length_le hle] at hx; exact hx
  | cont j =>
    obtain ⟨hlt, hp, hj⟩ := hh
    refine ⟨⟨by omega, fun x hx' => ?_⟩, by omega⟩
    rw [hj, List.take_add_one, List.getElem?_eq_getElem hlt] at hx'
    simp only [Option.toList_some, List.mem_append, List.mem_singleton] at hx'
    rcases hx' with hh | rfl
    · exact hx x hh
    · exact hp

theorem member_ok (xs : Slice (alloc.vec.Vec U8)) (x : Slice U8) (b : Bool)
    (h : bytes.member xs x = ok b) : (b = true ↔ ∃ y ∈ xs.val, y.val = x.val) := by
  unfold bytes.member bytes.member_loop at h
  refine any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold bytes.member_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt, he⟩ := slice_index_ok hv
    have hk := bytes_eq_ok _ _ _ (by assumption : bytes.eq _ _ = ok _)
    simp only [deref_val] at hk
    exact .inl ⟨hlt, by rw [he]; exact hk.1 hc_1, rfl⟩
  · obtain ⟨hlt, he⟩ := slice_index_ok hv
    have hk := bytes_eq_ok _ _ _ (by assumption : bytes.eq _ _ = ok _)
    simp only [deref_val] at hk
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]; intro hh; exact hc_1 (hk.2 hh)
  · exact .inr ⟨by scalar_tac, rfl⟩

/-- Coverage of byte-string sets is independent of order and duplicates. -/
theorem string_covers_ok (l r : Slice (alloc.vec.Vec U8)) (b : Bool)
    (h : conddata.string_covers l r = ok b) :
    (b = true ↔ ∀ x ∈ l.val, ∃ y ∈ r.val, y.val = x.val) := by
  unfold conddata.string_covers conddata.string_covers_loop at h
  refine all_loop _ _ _ (fun i res _ hr => ?_) b h
  unfold conddata.string_covers_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt, he⟩ := slice_index_ok hv
    have hk := member_ok _ _ _ (by assumption)
    simp only [deref_val] at hk
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]; exact hk.1 hc_1
  · obtain ⟨hlt, he⟩ := slice_index_ok hv
    have hk := member_ok _ _ _ (by assumption)
    simp only [deref_val] at hk
    refine .inl ⟨hlt, ?_, rfl⟩
    rw [he]; intro hh; exact hc_1 (hk.2 hh)
  · exact .inr ⟨by scalar_tac, rfl⟩

theorem string_set_eq_ok (l r : Slice (alloc.vec.Vec U8)) (b : Bool)
    (h : conddata.string_set_eq l r = ok b) :
    (b = true ↔ (∀ x ∈ l.val, ∃ y ∈ r.val, y.val = x.val) ∧
      (∀ y ∈ r.val, ∃ x ∈ l.val, x.val = y.val)) := by
  unfold conddata.string_set_eq at h
  h5i_invert h
  · have h1 := string_covers_ok l r _ (by assumption)
    have h2 := string_covers_ok _ _ _ h
    simp_all
  · have h1 := string_covers_ok l r _ (by assumption)
    simp_all

/-- Key equality preserves both names and the optional variable suffix. -/
theorem key_eq_ok (a c : condfuncs.Key) (b : Bool) (h : conddata.key_eq a c = ok b) :
    (b = true ↔ a.key_name.val = c.key_name.val ∧ a.name.val = c.name.val ∧
      a.variable.map (·.val) = c.variable.map (·.val)) := by
  unfold conddata.key_eq at h
  bcase b1 with hb1 at h
  have h1 := bytes_eq_ok _ _ _ hb1
  simp only [deref_val] at h1
  cases b1 <;> vif h []
  all_goals try vclose h
  bcase b2 with hb2 at h
  have h2 := bytes_eq_ok _ _ _ hb2
  simp only [deref_val] at h2
  cases b2 <;> vif h []
  all_goals try vclose h
  cases ha : a.variable <;> cases hc : c.variable <;>
    simp only [ha, hc, Result.ok.injEq] at h
  all_goals try vclose h
  have h3 := bytes_eq_ok _ _ _ h
  simp only [deref_val] at h3
  simp_all

/-- Every returned digit is precisely the six-bit index of its alphabet symbol. -/
theorem base64_digit_ok (c : U8) (o : Option U8) (h : conddata.base64_digit c = ok o) :
    ∀ i : U8, o = some i ↔ Base64Symbol c.val i.val := by
  unfold conddata.base64_digit at h
  h5i_invert h
  all_goals
    h5i_ok_facts
    intro digit
    simp only [Option.some.injEq, reduceCtorEq, u8_eq_iff, Base64Symbol]
    scalar_tac

/-- The alphabet excludes padding and nonalphabet bytes, and digits fit six bits. -/
theorem base64_digit_boundary (c : U8) (o : Option U8) (h : conddata.base64_digit c = ok o) :
    (∀ i, o = some i → i.val < 64) ∧
    (o = none ↔ ¬ ∃ i : U8, Base64Symbol c.val i.val) := by
  have hh := base64_digit_ok c o h
  constructor
  · intro i hi
    have hi' := (hh i).1 hi
    unfold Base64Symbol at hi'; omega
  · constructor
    · intro hn ⟨i, hi⟩; have := (hh i).2 hi; simp [hn] at this
    · intro hn; cases ho : o with
      | none => rfl
      | some i => exact False.elim (hn ⟨i, (hh i).1 ho⟩)

end rustfs_kernel.Verified.RustfsCondData
