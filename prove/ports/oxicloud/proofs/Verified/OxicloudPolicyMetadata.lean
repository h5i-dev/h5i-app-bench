import Verified.OxicloudDrivePolicy
import Verified.OxicloudBytes
open oxicloud_kernel.Verified.OxicloudBytes
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.SpecKernel
open H5iAppLib hiding lit
namespace oxicloud_kernel.Verified.OxicloudPolicyMetadata
attribute [local instance] Classical.propDecidable

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

theorem parsed_ok (raw : Slice U8) (knob : policycompare.Knob)
    (h : policycompare.knob_from_bytes raw = ok knob) : PolicyKnobParsed raw.val knob := by
  unfold policycompare.knob_from_bytes at h
  h5i_invert h
  all_goals simp only [lift, Result.ok.injEq] at *
  all_goals subst_vars
  all_goals have he := oxicloud_kernel.Verified.OxicloudBytes.equal_ok _ _ _ hb
  all_goals try have he1 := oxicloud_kernel.Verified.OxicloudBytes.equal_ok _ _ _ hb1
  all_goals try have he2 := oxicloud_kernel.Verified.OxicloudBytes.equal_ok _ _ _ hb2
  all_goals try have he3 := oxicloud_kernel.Verified.OxicloudBytes.equal_ok _ _ _ hb3
  all_goals try have he4 := oxicloud_kernel.Verified.OxicloudBytes.equal_ok _ _ _ hb4
  all_goals try have he5 := oxicloud_kernel.Verified.OxicloudBytes.equal_ok _ _ _ hb5
  all_goals try have he6 := oxicloud_kernel.Verified.OxicloudBytes.equal_ok _ _ _ hb6
  all_goals try have he7 := oxicloud_kernel.Verified.OxicloudBytes.equal_ok _ _ _ hb7
  all_goals try have he8 := oxicloud_kernel.Verified.OxicloudBytes.equal_ok _ _ _ hb8
  all_goals try have he9 := oxicloud_kernel.Verified.OxicloudBytes.equal_ok _ _ _ hb9
  all_goals simp_all [PolicyKnobParsed, PolicyKnobWire, PolicyKnobNames, Array.to_slice, Array.make]

theorem applies_bytes_ok (raw : Slice U8) (kind : model.DriveKind) (r : Bool)
    (h : policycompare.knob_applies_to_kind_bytes raw kind = ok r) :
    ∃ k, PolicyKnobParsed raw.val k ∧ (r = true ↔ PolicyApplies k kind) := by
  unfold policycompare.knob_applies_to_kind_bytes at h
  h5i_invert h
  exact ⟨k, parsed_ok raw k hk, applies_ok k kind r h⟩

theorem strictness_bytes_ok (raw : Slice U8)  (r : policycompare.Strictness)
    (h : policycompare.knob_strictness_bytes raw = ok r) :
    ∃ k, PolicyKnobParsed raw.val k ∧ PolicyStrictness k r := by
  unfold policycompare.knob_strictness_bytes at h
  h5i_invert h
  exact ⟨k, parsed_ok raw k hk, strictness_ok k r h⟩

theorem value_bytes_ok (raw : Slice U8) (p : drivepolicy.Policies) (r : policycompare.KnobValue)
    (h : policycompare.knob_value_bytes p raw = ok r) :
    ∃ k, PolicyKnobParsed raw.val k ∧ PolicyValue p k r := by
  unfold policycompare.knob_value_bytes at h
  h5i_invert h
  exact ⟨k, parsed_ok raw k hk, value_ok p k r h⟩

theorem bool_bytes_ok (raw : Slice U8) (p : drivepolicy.Policies) (r : Bool)
    (h : policycompare.knob_bool_bytes p raw = ok r) :
    ∃ k, PolicyKnobParsed raw.val k ∧ r = PolicyBit p k := by
  unfold policycompare.knob_bool_bytes at h
  h5i_invert h
  exact ⟨k, parsed_ok raw k hk, bool_ok p k r h⟩

theorem refinement_bytes_ok (raw : Slice U8) (p q : drivepolicy.Policies) (r : Bool)
    (h : policycompare.at_least_as_strict_on_bytes p q raw = ok r) :
    ∃ k, PolicyKnobParsed raw.val k ∧ (r = true ↔ PolicyRefines p q k) := by
  unfold policycompare.at_least_as_strict_on_bytes at h
  h5i_invert h
  exact ⟨k, parsed_ok raw k hk, refinement_ok p q k r h⟩

end oxicloud_kernel.Verified.OxicloudPolicyMetadata
