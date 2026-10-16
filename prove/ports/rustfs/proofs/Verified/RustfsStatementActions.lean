import SpecStatements
import Verified.RustfsActionSets
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsValids (any_loop)

namespace rustfs_kernel.Verified.RustfsStatementActions

theorem action_match_ok (pattern requested : acts.Action) (deny b : Bool)
    (h : acts.action_is_match_for_effect pattern requested deny = ok b) :
    b = true ↔ EffectActionMatches deny pattern requested := by
  cases deny with
  | false => exact RustfsActionSets.action_match_ok pattern requested b h
  | true =>
    unfold acts.action_is_match_for_effect at h
    simp only [Bool.true_eq_false,Bool.false_eq_true,↓reduceIte] at h
    rw [RustfsWildcard.wildcard_is_glob] at h
    simp only [RustfsForceDelete.deref_val,Result.ok.injEq] at h
    simp only [EffectActionMatches,↓reduceIte,← h]

theorem set_match_ok (xs : Slice acts.Action) (requested : acts.Action) (deny b : Bool)
    (h : acts.set_is_match_for_effect xs requested deny = ok b) :
    (b = true ↔ EffectActionSetMatches deny xs.val requested) := by
  unfold acts.set_is_match_for_effect acts.set_is_match_for_effect_loop at h
  unfold EffectActionSetMatches
  refine any_loop _ _ _ (fun i r _ hr => ?_) b h
  unfold acts.set_is_match_for_effect_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok ha1
    have hm := action_match_ok a1 requested deny b_1 hb_1
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
    have hm := action_match_ok a1 requested deny b_1 hb_1
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
    have hm := action_match_ok a1 requested deny b_1 hb_1
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

theorem coverage_ok (actions excluded : Slice acts.Action) (requested : acts.Action)
    (deny b : Bool) (h : acts.statement_covers actions excluded requested deny = ok b) :
    b = true ↔ StatementActionCoverage deny actions.val excluded.val requested := by
  unfold acts.statement_covers at h
  h5i_invert h
  all_goals have hm := set_match_ok excluded requested true b_1 hb_1
  · have hh := hm.mp hc
    simp [StatementActionCoverage,hh]
  · have hh : ¬EffectActionSetMatches true excluded.val requested := fun hh => hc (hm.mpr hh)
    have he : actions.val=[] := List.eq_nil_iff_length_eq_zero.mpr (by scalar_tac)
    simp [StatementActionCoverage,hh,he,hc_2]
  · have hh : ¬EffectActionSetMatches true excluded.val requested := fun hh => hc (hm.mpr hh)
    have he : actions.val=[] := List.eq_nil_iff_length_eq_zero.mpr (by scalar_tac)
    have hf := RustfsForceDelete.requires_ok requested b1 hb1
    simp [StatementActionCoverage,hh,he,hc_2,Bool.eq_false_iff,hf]
  · have hh : ¬EffectActionSetMatches true excluded.val requested := fun hh => hc (hm.mpr hh)
    have he : actions.val≠[] := by intro he; have hl:=congrArg List.length he; scalar_tac
    simpa only [StatementActionCoverage,hh,he,ite_false,not_false_eq_true,true_and] using
      set_match_ok actions requested deny b h

end rustfs_kernel.Verified.RustfsStatementActions
