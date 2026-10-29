import Verified.OxicloudDrivePolicy
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.PolicySpec
open H5iAppLib hiding lit
namespace oxicloud_kernel.Verified.OxicloudPolicyCompare
attribute [local instance] Classical.propDecidable

theorem push_ok {α} {v w : alloc.vec.Vec α} {x : α} (h : v.push x = ok w) : w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h; simp only at h
  split at h
  · simp at h; subst h; simp
  · simp at h


theorem knobs_ok (r : alloc.vec.Vec policycompare.Knob)
    (h : policycompare.policy_knobs = ok r) : r.val = PolicyKnobOrder := by
  unfold policycompare.policy_knobs at h
  h5i_invert h
  have hp0 := push_ok hout
  have hp1 := push_ok hout1
  have hp2 := push_ok hout2
  have hp3 := push_ok hout3
  have hp4 := push_ok hout4
  have hp5 := push_ok hout5
  have hp6 := push_ok hout6
  have hp7 := push_ok hout7
  have hp8 := push_ok hout8
  have hp9 := push_ok h
  simp_all [alloc.vec.Vec.new, PolicyKnobOrder]

theorem non_defaultable_ok (r : alloc.vec.Vec policycompare.Knob)
    (h : policycompare.non_defaultable_knobs = ok r) : r.val = [.ReadOnly] := by
  unfold policycompare.non_defaultable_knobs at h
  have hp := push_ok h
  simpa [alloc.vec.Vec.new] using hp

theorem applies_ok (knob : policycompare.Knob) (kind : model.DriveKind) (b : Bool)
    (h : policycompare.knob_applies_to_kind knob kind = ok b) :
    (b = true ↔ PolicyApplies knob kind) := by
  cases knob <;> cases kind <;> simp_all [policycompare.knob_applies_to_kind, PolicyApplies]

theorem strictness_ok (knob : policycompare.Knob) (r : policycompare.Strictness)
    (h : policycompare.knob_strictness knob = ok r) : PolicyStrictness knob r := by
  cases knob <;> simp_all [policycompare.knob_strictness, PolicyStrictness]

theorem value_ok (p : drivepolicy.Policies) (knob : policycompare.Knob) (r : policycompare.KnobValue)
    (h : policycompare.knob_value p knob = ok r) : PolicyValue p knob r := by
  cases knob <;> simp_all [policycompare.knob_value, PolicyValue, PolicyBit]
  cases hc : p.max_public_link_days <;> simp_all

theorem bool_ok (p : drivepolicy.Policies) (knob : policycompare.Knob) (b : Bool)
    (h : policycompare.knob_bool p knob = ok b) : b = PolicyBit p knob := by
  cases knob <;> simp_all [policycompare.knob_bool, policycompare.knob_value, PolicyBit]
  cases hc : p.max_public_link_days <;> simp_all

theorem refinement_ok (p q : drivepolicy.Policies) (knob : policycompare.Knob) (b : Bool)
    (h : policycompare.at_least_as_strict_on p q knob = ok b) :
    (b = true ↔ PolicyRefines p q knob) := by
  cases knob <;> simp_all [policycompare.at_least_as_strict_on, policycompare.knob_strictness,
    policycompare.knob_bool, policycompare.knob_value, PolicyRefines, PolicyBit, PolicyCapRefines]
  all_goals repeat' (split at h <;> simp_all)
  all_goals subst_vars
  all_goals simp_all

theorem cap_refines_refl (cap : Option U32) : PolicyCapRefines cap cap := by
  intro bound hb
  exact ⟨bound, hb, Nat.le_refl _⟩

theorem cap_refines_trans {a b c : Option U32}
    (hab : PolicyCapRefines a b) (hbc : PolicyCapRefines b c) : PolicyCapRefines a c := by
  intro bound hc
  obtain ⟨middle, hm, hmb⟩ := hbc bound hc
  obtain ⟨own, ho, hom⟩ := hab middle hm
  exact ⟨own, ho, hom.trans hmb⟩

theorem refinement_refl (p : drivepolicy.Policies) (knob : policycompare.Knob) : PolicyRefines p p knob := by
  cases knob <;> first | exact cap_refines_refl _ | exact fun h => h

theorem refinement_trans {p q r : drivepolicy.Policies} (knob : policycompare.Knob)
    (hpq : PolicyRefines p q knob) (hqr : PolicyRefines q r knob) : PolicyRefines p r knob := by
  cases knob <;> first
    | exact cap_refines_trans hpq hqr
    | exact fun h => hpq (hqr h)
    | exact fun h => hqr (hpq h)

theorem checked_refinement_transitive (p q r : drivepolicy.Policies) (knob : policycompare.Knob)
    (hpq : policycompare.at_least_as_strict_on p q knob = ok true)
    (hqr : policycompare.at_least_as_strict_on q r knob = ok true)
    (b : Bool) (hpr : policycompare.at_least_as_strict_on p r knob = ok b) : b = true := by
  exact (refinement_ok p r knob b hpr).2
    (refinement_trans knob ((refinement_ok p q knob true hpq).1 rfl)
      ((refinement_ok q r knob true hqr).1 rfl))

theorem append_weaker_ok (out : alloc.vec.Vec policycompare.Knob) (p d : drivepolicy.Policies)
    (kind : model.DriveKind) (knob : policycompare.Knob) (r : alloc.vec.Vec policycompare.Knob)
    (h : policycompare.append_weaker out p d kind knob = ok r) :
    r.val = out.val ++ (if PolicyWeak p d kind knob then [knob] else []) := by
  classical
  cases knob <;> unfold policycompare.append_weaker at h <;> h5i_invert h
  all_goals try have ha := applies_ok _ _ _ hdefaultable
  all_goals try have hr := refinement_ok _ _ _ _ hb1
  all_goals try have hp := push_ok h
  all_goals simp_all [PolicyWeak, PolicyDefaultable, PolicyApplies]


theorem filter_cons_selected {α : Type} (P : α → Prop) [DecidablePred P] (x : α) (xs : List α) :
    (x :: xs).filter (fun a => decide (P a)) = (if P x then [x] else []) ++ xs.filter (fun a => decide (P a)) := by
  by_cases h : P x <;> simp [h]

theorem weaker_ok (p d : drivepolicy.Policies) (kind : model.DriveKind)
    (r : alloc.vec.Vec policycompare.Knob) (h : policycompare.weaker_than p d kind = ok r) :
    r.val = PolicyWeakerList p d kind := by
  classical
  unfold policycompare.weaker_than at h
  h5i_invert h
  have hp0 := append_weaker_ok _ _ _ _ _ _ hout
  have hp1 := append_weaker_ok _ _ _ _ _ _ hout1
  have hp2 := append_weaker_ok _ _ _ _ _ _ hout2
  have hp3 := append_weaker_ok _ _ _ _ _ _ hout3
  have hp4 := append_weaker_ok _ _ _ _ _ _ hout4
  have hp5 := append_weaker_ok _ _ _ _ _ _ hout5
  have hp6 := append_weaker_ok _ _ _ _ _ _ hout6
  have hp7 := append_weaker_ok _ _ _ _ _ _ hout7
  have hp8 := append_weaker_ok _ _ _ _ _ _ hout8
  have hp9 := append_weaker_ok _ _ _ _ _ _ h
  simp only [PolicyWeakerList, PolicyKnobOrder, filter_cons_selected, List.filter_nil]
  simp_all [alloc.vec.Vec.new, List.append_assoc]


end oxicloud_kernel.Verified.OxicloudPolicyCompare
