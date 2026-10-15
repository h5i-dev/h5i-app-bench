import Verified.OxicloudPolicyCompare
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.SpecKernel
open H5iAppLib hiding lit
namespace oxicloud_kernel.Verified.OxicloudPolicyDefaults

theorem knob_ok (knob : policycompare.Knob) (kind : model.DriveKind)
    (r : Option policydefaults.KeyRejection) (h : policydefaults.reject_knob knob kind = ok r) :
    (r = none ↔ DefaultKnobAllowed knob kind) ∧
    (∀ reason, r = some reason → DefaultKnobRejection knob kind reason) := by
  cases knob <;> cases kind <;>
    simp_all [policydefaults.reject_knob, policycompare.knob_applies_to_kind,
      DefaultKnobAllowed, PolicyApplies, DefaultKnobRejection]
  all_goals subst_vars
  all_goals simp_all

theorem parsed_unique {raw : List U8} {a b : policycompare.Knob}
    (ha : PolicyKnobParsed raw a) (hb : PolicyKnobParsed raw b) : a = b := by
  cases a <;> cases b <;> simp_all [PolicyKnobParsed, PolicyKnobWire, PolicyKnobNames]
  all_goals subst raw
  all_goals simp_all

theorem key_ok (raw : Slice U8) (kind : model.DriveKind)
    (r : Option policydefaults.KeyRejection) (h : policydefaults.reject_key raw kind = ok r) :
    (r = none ↔ DefaultKeyAllowed raw.val kind) ∧
    (∀ reason, r = some reason → DefaultKeyRejection raw.val kind reason) := by
  unfold policydefaults.reject_key at h
  h5i_invert h
  have hp := OxicloudPolicyCompare.parsed_ok raw k hk
  have hd := knob_ok k kind r h
  refine ⟨⟨fun hn => ⟨k, hp, hd.1.mp hn⟩, ?_⟩, fun reason hr => ⟨k, hp, hd.2 reason hr⟩⟩
  rintro ⟨other, hp', ha⟩
  have he := parsed_unique hp hp'
  subst other
  exact hd.1.mpr ha

theorem validation_ok (kind : model.DriveKind) (isObject : Bool)
    (keys : Slice (alloc.vec.Vec U8)) (r : policydefaults.Validation)
    (h : policydefaults.validate kind isObject keys = ok r) :
    DefaultsValidation kind isObject keys.val r := by
  unfold policydefaults.validate at h
  split at h
  · rename_i ho
    unfold policydefaults.validate_loop at h
    refine loop_ok _
      (fun i : Usize => ∀ j < i.val, ∀ raw, keys.val[j]? = some raw → DefaultKeyAllowed raw.val kind)
      (DefaultsValidation kind isObject keys.val)
      (fun i => keys.val.length - i.val) ?_ 0#usize r (by simp) h
    intro i result hp hr
    unfold policydefaults.validate_loop.body at hr
    h5i_invert hr
    · obtain ⟨hi, he⟩ := slice_index_ok hv
      have ha := (key_ok _ _ _ ho_1).1.mp rfl
      have hj := add_ok_val hi2
      refine ⟨?_, by scalar_tac⟩
      intro j hji raw heq
      by_cases hji' : j < i.val
      · exact hp j hji' raw heq
      · have hj' : j = i.val := by scalar_tac
        subst j
        have heq' : keys.val[i.val]? = some v := List.getElem?_eq_some_iff.mpr ⟨hi, he⟩
        have : raw = v := by simp_all
        subst raw
        simpa [alloc.vec.Vec.deref] using ha
    · obtain ⟨hi, he⟩ := slice_index_ok hv
      have hb := (key_ok _ _ _ ho_1).2 reason rfl
      refine ⟨ho, ⟨v, List.getElem?_eq_some_iff.mpr ⟨hi, he⟩, ?_⟩, hp⟩
      simpa [alloc.vec.Vec.deref] using hb
    · refine ⟨ho, ?_⟩
      intro raw hm
      obtain ⟨j, hj, he⟩ := List.mem_iff_getElem.1 hm
      apply hp j (by scalar_tac) raw
      simp [List.getElem?_eq_getElem hj, he]
  · cases r <;> simp_all [DefaultsValidation]

theorem rejection_excludes_allowed {raw : List U8} {kind : model.DriveKind}
    {reason : policydefaults.KeyRejection} (hb : DefaultKeyRejection raw kind reason) :
    ¬ DefaultKeyAllowed raw kind := by
  rintro ⟨other, ho, ha⟩
  obtain ⟨knob, hk, hr⟩ := hb
  have he := parsed_unique hk ho
  subst other
  cases reason <;> simp_all [DefaultKnobRejection, DefaultKnobAllowed, PolicyApplies]

theorem validation_exact (kind : model.DriveKind) (isObject : Bool)
    (keys : Slice (alloc.vec.Vec U8)) (r : policydefaults.Validation)
    (h : policydefaults.validate kind isObject keys = ok r) :
    (r = .Valid ↔ isObject = true ∧ ∀ raw ∈ keys.val, DefaultKeyAllowed raw.val kind) := by
  have hd := validation_ok kind isObject keys r h
  cases r with
  | Valid => simpa [DefaultsValidation] using hd
  | NotObject => simp_all [DefaultsValidation]
  | Rejected index reason =>
    simp only [DefaultsValidation] at hd
    obtain ⟨_, ⟨raw, hm, hb⟩, _⟩ := hd
    constructor
    · intro hv
      cases hv
    · rintro ⟨_, hall⟩
      exact False.elim (rejection_excludes_allowed hb (hall raw (List.mem_of_getElem? hm)))

end oxicloud_kernel.Verified.OxicloudPolicyDefaults
