import Verified.RustfsConditionEquality
import Verified.RustfsWildcard
import SpecKernel
import Verified.RustfsDefaults
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsForceDelete (family_eq_ok)
open rustfs_kernel.Verified.RustfsCondData (all_loop)
open rustfs_kernel.Verified.RustfsValids (any_loop)
open rustfs_kernel.Verified.RustfsConditionEquality (vec_eq_law)
deriving instance DecidableEq for acts.Action
namespace rustfs_kernel.Verified.RustfsActionSets

theorem action_eq_law (a b : acts.Action) :
    acts.Action.Insts.CoreCmpPartialEqAction.eq a b = ok (decide (a = b)) := by
  unfold acts.Action.Insts.CoreCmpPartialEqAction.eq
  rw [family_eq_ok]
  by_cases hf : a.family = b.family
  · have he : (a.name.val = b.name.val) ↔ a = b := by
      constructor
      · intro hn
        cases a; cases b
        simp_all only [acts.Action.mk.injEq]
        exact ⟨trivial, alloc.vec.Vec.ext _ _ hn⟩
      · intro h; cases h; rfl
    simp [hf, vec_eq_law, he]
  · have hn : a ≠ b := fun hh => hf (congrArg acts.Action.family hh)
    simp [hf, hn]

theorem member_ok (xs : Slice acts.Action) (x : acts.Action) (b : Bool)
    (h : actsets.member xs x = ok b) : (b = true ↔ x ∈ xs.val) := by
  unfold actsets.member actsets.member_loop at h
  have hm : (b = true ↔ ∃ y ∈ xs.val, y = x) := by
    refine any_loop xs.val (fun y => y = x) _ (fun i r _ hr => ?_) b h
    unfold actsets.member_loop.body at hr
    simp only [action_eq_law, bind_ok] at hr
    h5i_invert hr
    · obtain ⟨hlt, he⟩ := slice_index_ok ha1
      exact .inl ⟨hlt, by rw [he]; simpa using hc_1, rfl⟩
    · obtain ⟨hlt, he⟩ := slice_index_ok ha1
      refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
      rw [he]; simpa using hc_1
    · exact .inr ⟨by scalar_tac, rfl⟩
  simpa using hm

theorem covers_ok (xs ys : Slice acts.Action) (b : Bool)
    (h : actsets.covers xs ys = ok b) :
    (b = true ↔ ∀ x ∈ xs.val, x ∈ ys.val) := by
  unfold actsets.covers actsets.covers_loop at h
  refine all_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold actsets.covers_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt, he⟩ := slice_index_ok ha
    have hm := member_ok _ _ _ (by assumption)
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]; exact hm.1 hc_1
  · obtain ⟨hlt, he⟩ := slice_index_ok ha
    have hm := member_ok _ _ _ (by assumption)
    exact .inl ⟨hlt, by rw [he]; exact fun hh => hc_1 (hm.2 hh), rfl⟩
  · exact .inr ⟨by scalar_tac, rfl⟩

theorem eq_ok (xs ys : Slice acts.Action) (b : Bool)
    (h : actsets.eq xs ys = ok b) :
    (b = true ↔ ∀ x, x ∈ xs.val ↔ x ∈ ys.val) := by
  unfold actsets.eq at h
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

theorem push_unique_ok (xs : alloc.vec.Vec acts.Action) (x : acts.Action)
    (ys : alloc.vec.Vec acts.Action) (h : actsets.push_unique xs x = ok ys) :
    ys.val = if x ∈ xs.val then xs.val else xs.val ++ [x] := by
  unfold actsets.push_unique actsets.push_unique_loop at h
  refine loop_ok _ (fun i : Usize => i.val ≤ xs.val.length ∧
      x ∉ xs.val.take i.val)
    (fun ys : alloc.vec.Vec acts.Action =>
      ys.val = if x ∈ xs.val then xs.val else xs.val ++ [x])
    (fun i => xs.val.length - i.val) ?_ _ ys ⟨by simp, by simp⟩ h
  rintro i r ⟨hi,hn⟩ hr
  unfold actsets.push_unique_loop.body at hr
  simp only [action_eq_law, bind_ok] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := vec_index_ok ha1
    have hx : xs.val[i.val] = x := by rw [he]; simpa using hc_1
    have hm : x ∈ xs.val := hx ▸ List.getElem_mem hlt
    simp [hm]
  · obtain ⟨hlt,he⟩ := vec_index_ok ha1
    have hx : xs.val[i.val] ≠ x := by rw [he]; simpa using hc_1
    have hj := add_ok_val hi2
    refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
    have hji : i2.val = i.val + 1 := by scalar_tac
    rw [hji, List.take_add_one, List.getElem?_eq_getElem hlt]
    simpa only [Option.toList_some, List.mem_append, List.mem_singleton, not_or] using And.intro hn (Ne.symm hx)
  · have hle : xs.val.length ≤ i.val := by scalar_tac
    rw [List.take_of_length_le hle] at hn
    change set1.val = _
    rw [rustfs_kernel.Verified.RustfsBytes.push_ok hset1]
    simp [hn]

theorem empty_ok (xs : Slice acts.Action) :
    actsets.is_empty xs = ok (decide (xs.val = [])) := by
  unfold actsets.is_empty
  dsimp only
  apply congrArg Result.ok
  apply Bool.eq_iff_iff.mpr
  simp only [decide_eq_true_eq, ← List.length_eq_zero_iff]
  constructor
  · intro h; have := congrArg UScalar.val h; simpa using this
  · intro h; apply UScalar.eq_of_val_eq; simpa using h

theorem slice_ok (xs : Slice acts.Action) : actsets.as_slice xs = ok xs := rfl

theorem validation_total (xs : Slice acts.Action) : actsets.is_valid xs = ok true := rfl

theorem action_match_ok (pattern requested : acts.Action) (b : Bool)
    (h : actsets.action_is_match pattern requested = ok b) :
    (b = true ↔ ActionGrantMatches pattern requested) := by
  unfold actsets.action_is_match acts.action_is_match_for_effect at h
  simp only [Bool.false_eq_true, ↓reduceIte] at h
  h5i_invert h
  · have hs3 := rustfs_kernel.Verified.RustfsForceDelete.is_s3_ok pattern _ _ (by assumption)
    have hf := rustfs_kernel.Verified.RustfsForceDelete.requires_ok requested _ (by assumption)
    have hl := rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs
    simp only [hl] at hs3
    have hstar : lit "s3:*" = [115,51,58,42] := by decide +kernel
    simp only [ActionGrantMatches, hstar]
    simp_all
  · have hs3 := rustfs_kernel.Verified.RustfsForceDelete.is_s3_ok pattern _ _ (by assumption)
    have hf := rustfs_kernel.Verified.RustfsForceDelete.requires_ok requested _ (by assumption)
    have hl := rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs
    rw [rustfs_kernel.Verified.RustfsWildcard.wildcard_is_glob] at h
    have hstar : lit "s3:*" = [115,51,58,42] := by decide +kernel
    simp_all [ActionGrantMatches, hstar, rustfs_kernel.Verified.RustfsForceDelete.deref_val]
  · have hs3 := rustfs_kernel.Verified.RustfsForceDelete.is_s3_ok pattern _ _ (by assumption)
    have hl := rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs
    rw [rustfs_kernel.Verified.RustfsWildcard.wildcard_is_glob] at h
    have hstar : lit "s3:*" = [115,51,58,42] := by decide +kernel
    simp_all [ActionGrantMatches, hstar, rustfs_kernel.Verified.RustfsForceDelete.deref_val]

theorem set_match_ok (xs : Slice acts.Action) (requested : acts.Action) (b : Bool)
    (h : actsets.set_is_match xs requested = ok b) :
    (b = true ↔ ActionSetGrantMatches xs.val requested) := by
  unfold actsets.set_is_match acts.set_is_match_for_effect acts.set_is_match_for_effect_loop at h
  unfold ActionSetGrantMatches
  refine any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold acts.set_is_match_for_effect_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok ha1
    have hm := action_match_ok a1 requested b_1 hb_1
    exact .inl ⟨hlt, by rw [he]; exact .inl (hm.1 hc_1), rfl⟩
  · obtain ⟨hlt,he⟩ := slice_index_ok ha1
    have h1 := rustfs_kernel.Verified.RustfsForceDelete.is_s3_ok _ _ _ hb1
    have h2 := rustfs_kernel.Verified.RustfsForceDelete.is_s3_ok _ _ _ hb2
    have hl : nats s.val = lit "s3:GetObjectVersion" := by
      simpa [rustfs_kernel.Verified.RustfsDefaults.lit_GOV, rustfs_kernel.Verified.RustfsDefaults.lit_GO] using rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs
    have hr : nats s1.val = lit "s3:GetObject" := by
      simpa [rustfs_kernel.Verified.RustfsDefaults.lit_GOV, rustfs_kernel.Verified.RustfsDefaults.lit_GO] using rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs1
    rw [hl] at h1; rw [hr] at h2
    exact .inl ⟨hlt, by rw [he]; exact .inr ⟨(h1.1 hc_2).1, (h1.1 hc_2).2,
      (h2.1 hc_3).1, (h2.1 hc_3).2⟩, rfl⟩
  · obtain ⟨hlt,he⟩ := slice_index_ok ha1
    have hm := action_match_ok a1 requested b_1 hb_1
    have h2 := rustfs_kernel.Verified.RustfsForceDelete.is_s3_ok _ _ _ hb2
    have hl : nats s1.val = lit "s3:GetObject" := by
      simpa [rustfs_kernel.Verified.RustfsDefaults.lit_GOV, rustfs_kernel.Verified.RustfsDefaults.lit_GO] using rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs1
    rw [hl] at h2
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]
    rintro (hh | hh)
    · exact hc_1 (hm.2 hh)
    · exact hc_3 (h2.2 ⟨hh.2.2.1, hh.2.2.2⟩)
  · obtain ⟨hlt,he⟩ := slice_index_ok ha1
    have hm := action_match_ok a1 requested b_1 hb_1
    have h1 := rustfs_kernel.Verified.RustfsForceDelete.is_s3_ok _ _ _ hb1
    have hl : nats s.val = lit "s3:GetObjectVersion" := by
      simpa [rustfs_kernel.Verified.RustfsDefaults.lit_GOV, rustfs_kernel.Verified.RustfsDefaults.lit_GO] using rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs
    rw [hl] at h1
    refine ⟨hlt, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [he]
    rintro (hh | hh)
    · exact hc_1 (hm.2 hh)
    · exact hc_2 (h1.2 ⟨hh.1, hh.2.1⟩)
  · exact .inr ⟨by scalar_tac, rfl⟩

end rustfs_kernel.Verified.RustfsActionSets
