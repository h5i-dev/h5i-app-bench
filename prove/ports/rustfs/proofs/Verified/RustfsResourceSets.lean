import Verified.RustfsActionSets
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsCondData (all_loop)
open rustfs_kernel.Verified.RustfsValids (any_loop)
open rustfs_kernel.Verified.RustfsConditionEquality (vec_eq_law)
deriving instance DecidableEq for rsrc.Resource
namespace rustfs_kernel.Verified.RustfsResourceSets

theorem resource_eq_law (a b : rsrc.Resource) :
    rsrc.Resource.Insts.CoreCmpPartialEqResource.eq a b = ok (decide (a = b)) := by
  cases a <;> cases b <;>
    simp [rsrc.Resource.Insts.CoreCmpPartialEqResource.eq, rsrc.Resource.read_discriminant, vec_eq_law,
      alloc.vec.Vec.ext_iff]

theorem member_ok (xs : Slice rsrc.Resource) (x : rsrc.Resource) (b : Bool)
    (h : resets.member xs x = ok b) : (b = true ↔ x ∈ xs.val) := by
  unfold resets.member resets.member_loop at h
  have hm : (b = true ↔ ∃ y ∈ xs.val, y = x) := by
    refine any_loop xs.val (fun y => y = x) _ (fun i r _ hr => ?_) b h
    unfold resets.member_loop.body at hr
    simp only [resource_eq_law, bind_ok] at hr
    h5i_invert hr
    · obtain ⟨hlt, he⟩ := slice_index_ok hr_1
      exact .inl ⟨hlt, by rw [he]; simpa using hc_1, rfl⟩
    · obtain ⟨hlt, he⟩ := slice_index_ok hr_1
      refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
      rw [he]; simpa using hc_1
    · exact .inr ⟨by scalar_tac, rfl⟩
  simpa using hm

theorem covers_ok (xs ys : Slice rsrc.Resource) (b : Bool)
    (h : resets.covers xs ys = ok b) :
    (b = true ↔ ∀ x ∈ xs.val, x ∈ ys.val) := by
  unfold resets.covers resets.covers_loop at h
  refine all_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold resets.covers_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt, he⟩ := slice_index_ok hr_1
    have hm := member_ok _ _ _ (by assumption)
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]; exact hm.1 hc_1
  · obtain ⟨hlt, he⟩ := slice_index_ok hr_1
    have hm := member_ok _ _ _ (by assumption)
    exact .inl ⟨hlt, by rw [he]; exact fun hh => hc_1 (hm.2 hh), rfl⟩
  · exact .inr ⟨by scalar_tac, rfl⟩

theorem eq_ok (xs ys : Slice rsrc.Resource) (b : Bool)
    (h : resets.eq xs ys = ok b) :
    (b = true ↔ ∀ x, x ∈ xs.val ↔ x ∈ ys.val) := by
  unfold resets.eq at h
  h5i_invert h
  · have hl := covers_ok xs ys _ (by assumption)
    have hr := covers_ok ys xs _ h
    have hleft := hl.1 hc
    rw [hr]
    constructor
    · intro hh x; exact ⟨hleft x, hh x⟩
    · intro hh x hx; exact (hh x).2 hx
  · have hl := covers_ok xs ys _ (by assumption)
    simp only [Bool.false_eq_true, false_iff]
    intro hh; apply hc; exact hl.2 (fun x hx => (hh x).1 hx)

theorem push_unique_ok (xs : alloc.vec.Vec rsrc.Resource) (x : rsrc.Resource)
    (ys : alloc.vec.Vec rsrc.Resource) (h : resets.push_unique xs x = ok ys) :
    ys.val = if x ∈ xs.val then xs.val else xs.val ++ [x] := by
  unfold resets.push_unique at h
  h5i_invert h
  · have hm := (member_ok _ _ _ hb).1 hc
    simpa [rustfs_kernel.Verified.RustfsForceDelete.deref_val] using hm
  · have hm : x ∉ xs.val := fun hx => hc ((member_ok _ _ _ hb).2 (by simpa [rustfs_kernel.Verified.RustfsForceDelete.deref_val] using hx))
    rw [rustfs_kernel.Verified.RustfsBytes.push_ok h]
    simp [hm]

theorem empty_ok (xs : Slice rsrc.Resource) :
    resets.is_empty xs = ok (decide (xs.val = [])) := by
  unfold resets.is_empty
  dsimp only
  apply congrArg Result.ok
  apply Bool.eq_iff_iff.mpr
  simp only [decide_eq_true_eq, ← List.length_eq_zero_iff]
  constructor
  · intro h; have := congrArg UScalar.val h; simpa using this
  · intro h; apply UScalar.eq_of_val_eq; simpa using h

theorem slice_ok (xs : Slice rsrc.Resource) : resets.as_slice xs = ok xs := rfl

/-- A successful resource-set match has a witness in the supplied set. -/
theorem set_match_ok (xs : Slice rsrc.Resource) (needle : Slice U8) (b : Bool)
    (h : resets.set_match_resource xs needle = ok b) :
    (b = true ↔ ∃ x ∈ xs.val, resets.match_resource x needle = ok true) := by
  unfold resets.set_match_resource resets.set_match_resource_loop at h
  refine any_loop xs.val (fun x => resets.match_resource x needle = ok true) _
    (fun i r _ hr => ?_) b h
  unfold resets.set_match_resource_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok hr_1
    exact .inl ⟨hlt, by rw [he]; simpa [hc_1] using hb_1, rfl⟩
  · obtain ⟨hlt,he⟩ := slice_index_ok hr_1
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]
    intro hh
    rw [hh] at hb_1
    simp only [Result.ok.injEq] at hb_1
    exact hc_1 hb_1.symm
  · exact .inr ⟨by scalar_tac,rfl⟩

/-- Empty resource sets cannot authorize any needle, regardless of condition values. -/
theorem empty_matches (xs : Slice rsrc.Resource) (needle : Slice U8)
    (values : alloc.vec.Vec ((alloc.vec.Vec U8) × (alloc.vec.Vec (alloc.vec.Vec U8)))) (hx : xs.val = []) :
    resets.set_matches xs needle values = ok false := by
  unfold resets.set_matches rsrc.set_is_match rsrc.set_is_match_loop
  rw [loop]
  simp [rsrc.set_is_match_loop.body, Slice.len, hx]

end rustfs_kernel.Verified.RustfsResourceSets
