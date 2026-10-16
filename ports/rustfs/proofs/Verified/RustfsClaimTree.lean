import SpecClaims
import Verified.RustfsForceDelete
import Verified.RustfsBytes
import Verified.RustfsClaimTags
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsBytes
open rustfs_kernel.Verified.RustfsForceDelete (deref_val)
namespace rustfs_kernel.Verified.RustfsClaimTree
theorem listN_size {α : Type} [SizeOf α] {n : Nat} (l : Aeneas.Data.ListN.ListN α n) :
    sizeOf l.toList ≤ sizeOf l := by
  induction l with
  | nil => simp only [Aeneas.Data.ListN.ListN.toList, List.nil.sizeOf_spec,
      Aeneas.Data.ListN.ListN.nil.sizeOf_spec]; omega
  | cons x l ih =>
    simp only [Aeneas.Data.ListN.ListN.toList, List.cons.sizeOf_spec,
      Aeneas.Data.ListN.ListN.cons.sizeOf_spec]
    omega

theorem slice_size {α : Type} [SizeOf α] (s : Slice α) : sizeOf s.val < sizeOf s := by
  cases s with | mk n l h =>
    have hl := listN_size l
    simp only [Slice.val, Slice.mk.sizeOf_spec]
    omega

theorem array_size (es : alloc.vec.Vec claims.Value) : sizeOf es.val < sizeOf (claims.Value.Array es) := by
  cases es with | mk sl =>
    have hs := slice_size sl
    simp only [claims.Value.Array.sizeOf_spec, alloc.vec.Vec.mk.sizeOf_spec, alloc.vec.Vec.val]
    omega

theorem object_size (es : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value)) :
    sizeOf es.val < sizeOf (claims.Value.Object es) := by
  cases es with | mk sl =>
    have hs := slice_size sl
    simp only [claims.Value.Object.sizeOf_spec, alloc.vec.Vec.mk.sizeOf_spec, alloc.vec.Vec.val]
    omega

theorem child_array_size (es : Slice claims.Value) (i : Nat) (hlt : i < es.val.length) :
    sizeOf es.val[i] < sizeOf (es.val.drop i) := by
  rw [List.drop_eq_getElem_cons hlt]
  simp only [List.cons.sizeOf_spec]
  omega

theorem child_object_size (es : Slice (alloc.vec.Vec U8 × claims.Value)) (i : Nat) (hlt : i < es.val.length) :
    sizeOf es.val[i].2 < sizeOf (es.val.drop i) := by
  have hp : sizeOf es.val[i].2 < sizeOf es.val[i] := by
    generalize es.val[i] = p
    rcases p with ⟨key,v⟩
    simp only [Prod.mk.sizeOf_spec]
    omega
  rw [List.drop_eq_getElem_cons hlt]
  simp only [List.cons.sizeOf_spec]
  omega

theorem tail_size {α : Type} [SizeOf α] (es : Slice α) (i : Nat) (hlt : i < es.val.length) :
    sizeOf (es.val.drop (i+1)) < sizeOf (es.val.drop i) := by
  rw [List.drop_eq_getElem_cons hlt]
  simp only [List.cons.sizeOf_spec]
  omega


theorem array_use_iff (es : alloc.vec.Vec claims.Value) :
    ExistingTagUse (.Array es) ↔ ∃ v ∈ es.val, ExistingTagUse v := by
  constructor
  · intro h; cases h with | array_value _ v hv ht => exact ⟨v,hv,ht⟩
  · rintro ⟨v,hv,ht⟩; exact .array_value es v hv ht

theorem object_use_iff (es : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value)) :
    ExistingTagUse (.Object es) ↔
      ∃ e ∈ es.val, ExistingTagKey (nats e.1.val) ∨ ExistingTagUse e.2 := by
  constructor
  · intro h
    cases h with
    | object_key _ e he ht => exact ⟨e,he,.inl ht⟩
    | object_value _ e he ht => exact ⟨e,he,.inr ht⟩
  · rintro ⟨e,he,ht | ht⟩
    · exact .object_key es e he ht
    · exact .object_value es e he ht

def ObjectTagUse (es : List (alloc.vec.Vec U8 × claims.Value)) : Prop :=
  ∃ e ∈ es, ExistingTagKey (nats e.1.val) ∨ ExistingTagUse e.2

def ArrayTagUse (es : List claims.Value) : Prop := ∃ v ∈ es, ExistingTagUse v

theorem all_ok (n : Nat) :
    (∀ v : claims.Value, sizeOf v ≤ n → ∀ b,
      claims.value_uses_existing_object_tag v = ok b → (b = true ↔ ExistingTagUse v)) ∧
    (∀ (es : Slice (alloc.vec.Vec U8 × claims.Value)) (i : Usize),
      sizeOf (es.val.drop i.val) ≤ n → ∀ b, claims.object_uses_tag es i = ok b →
        (b = true ↔ ObjectTagUse (es.val.drop i.val))) ∧
    (∀ (es : Slice claims.Value) (i : Usize),
      sizeOf (es.val.drop i.val) ≤ n → ∀ b, claims.array_uses_tag es i = ok b →
        (b = true ↔ ArrayTagUse (es.val.drop i.val))) := by
  induction n using Nat.strong_induction_on with
  | h n ih =>
    have hz : (0#usize).val = 0 := by decide +kernel
    refine ⟨?_,?_,?_⟩
    · intro v hv b h
      cases v with
      | Array es =>
        unfold claims.value_uses_existing_object_tag at h
        have hs := array_size es
        have hh := (ih (sizeOf es.val) (by omega)).2.2 es.deref 0#usize
          (by simp only [deref_val, hz, List.drop_zero]; omega) b h
        simpa only [deref_val,hz,List.drop_zero,ArrayTagUse,← array_use_iff] using hh
      | Object es =>
        unfold claims.value_uses_existing_object_tag at h
        have hs := object_size es
        have hh := (ih (sizeOf es.val) (by omega)).2.1 es.deref 0#usize
          (by simp only [deref_val, hz, List.drop_zero]; omega) b h
        simpa only [deref_val,hz,List.drop_zero,ObjectTagUse,← object_use_iff] using hh
      | Null | Bool _ | Number _ | String _ =>
        unfold claims.value_uses_existing_object_tag at h
        h5i_invert h
        constructor <;> intro hx <;> cases hx
    · intro es i hsize b h
      unfold claims.object_uses_tag at h
      h5i_invert h
      · have hle : es.val.length ≤ i.val := by scalar_tac
        simp [ObjectTagUse,List.drop_eq_nil_of_le hle]
      · rcases x with ⟨key,value⟩
        change (do
          let kb ← claims.is_existing_object_tag_condition_key key.deref
          if kb then ok true else
            let vb ← claims.value_uses_existing_object_tag value
            if vb then ok true else
              let j ← i + 1#usize
              claims.object_uses_tag es j) = ok b at h
        obtain ⟨hlt,he⟩ := slice_index_ok hx
        have hex : ObjectTagUse (es.val.drop i.val) ↔
            (ExistingTagKey (nats key.val) ∨ ExistingTagUse value) ∨
              ObjectTagUse (es.val.drop (i.val+1)) := by
          rw [List.drop_eq_getElem_cons hlt,he]
          simp [ObjectTagUse]
        h5i_invert h
        all_goals
          have hk := rustfs_kernel.Verified.RustfsClaimTags.tag_key_ok _ _ hkb
          rw [deref_val] at hk
        · rw [hex]
          simp [hk.1 hc_1]
        all_goals
          have hvs := child_object_size es i.val hlt
          rw [he] at hvs
          change sizeOf value < sizeOf (es.val.drop i.val) at hvs
          have hvsmall : sizeOf value < n := by omega
          have hvspec := (ih (sizeOf value) hvsmall).1 value (by omega) _ hvb
        · rw [hex]
          simp [hvspec.1 hc_2]
        · have hj := add_ok_val hj
          have hjval : j.val = i.val+1 := by scalar_tac
          have hts := tail_size es i.val hlt
          have htsmall : sizeOf (es.val.drop (i.val+1)) < n := by omega
          have htspec := (ih _ htsmall).2.1 es j (by rw [hjval]) b h
          rw [hjval] at htspec
          rw [hex,← hk,← hvspec]
          simpa only [hc_1,hc_2,Bool.false_eq_true,false_or] using htspec
    · intro es i hsize b h
      unfold claims.array_uses_tag at h
      h5i_invert h
      · have hle : es.val.length ≤ i.val := by scalar_tac
        simp [ArrayTagUse,List.drop_eq_nil_of_le hle]
      all_goals
        obtain ⟨hlt,he⟩ := slice_index_ok hv
        have hex : ArrayTagUse (es.val.drop i.val) ↔
            ExistingTagUse v ∨ ArrayTagUse (es.val.drop (i.val+1)) := by
          rw [List.drop_eq_getElem_cons hlt,he]
          simp [ArrayTagUse]
        have hvs := child_array_size es i.val hlt
        rw [he] at hvs
        have hvsmall : sizeOf v < n := by omega
        have hvspec := (ih (sizeOf v) hvsmall).1 v (by omega) b_1 hb_1
      · rw [hex]
        simp [hvspec.1 hc_1]
      · have hj := add_ok_val hi2
        have hjval : i2.val = i.val+1 := by scalar_tac
        have hts := tail_size es i.val hlt
        have htsmall : sizeOf (es.val.drop (i.val+1)) < n := by omega
        have htspec := (ih _ htsmall).2.2 es i2 (by rw [hjval]) b h
        rw [hjval] at htspec
        rw [hex,← hvspec]
        simpa only [hc_1,Bool.false_eq_true,false_or] using htspec
theorem value_ok (v : claims.Value) (b : Bool)
    (h : claims.value_uses_existing_object_tag v = ok b) :
    (b = true ↔ ExistingTagUse v) := (all_ok (sizeOf v)).1 v (Nat.le_refl _) b h
end rustfs_kernel.Verified.RustfsClaimTree
