import Verified.OxicloudBytes
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.SpecKernel
open H5iAppLib hiding lit
namespace oxicloud_kernel.Verified.OxicloudSubjectGroup

theorem alphanumeric_ok (b : U8) (r : Bool) (h : subjectgroup.alphanumeric b = ok r) :
    (r = true ↔ GroupAlphanumeric b) := by
  unfold subjectgroup.alphanumeric at h
  h5i_invert h <;> simp_all [GroupAlphanumeric] <;> scalar_tac

theorem name_byte_ok (b : U8) (r : Bool) (h : subjectgroup.name_byte b = ok r) :
    (r = true ↔ GroupNameByte b) := by
  unfold subjectgroup.name_byte at h
  h5i_invert h
  all_goals have ha := alphanumeric_ok _ _ hb1
  all_goals simp_all [GroupNameByte] <;> scalar_tac

theorem all_name_ok (raw : Slice U8) (r : Bool)
    (h : subjectgroup.all_name raw = ok r) :
    (r = true ↔ ∀ b ∈ raw.val, GroupNameByte b) := by
  unfold subjectgroup.all_name subjectgroup.all_name_loop at h
  refine loop_ok _
    (fun i : Usize => ∀ j < i.val, ∀ b, raw.val[j]? = some b → GroupNameByte b)
    (fun r => r = true ↔ ∀ b ∈ raw.val, GroupNameByte b)
    (fun i => raw.val.length - i.val) ?_ 0#usize r (by simp) h
  intro i result hp hr
  unfold subjectgroup.all_name_loop.body at hr
  h5i_invert hr
  · obtain ⟨hi, he⟩ := slice_index_ok hi2
    have hb' := name_byte_ok _ _ hb
    have hj := add_ok_val hi3
    refine ⟨?_, by scalar_tac⟩
    intro j hji b heq
    by_cases hji' : j < i.val
    · exact hp j hji' b heq
    · have hj' : j = i.val := by scalar_tac
      subst j
      have heq' : raw.val[i.val]? = some i2 := by simp [List.getElem?_eq_getElem hi, he]
      have : b = i2 := by simp_all
      subst b
      exact hb'.1 hc_1
  · obtain ⟨hi, he⟩ := slice_index_ok hi2
    have hb' := name_byte_ok _ _ hb
    simp only [Bool.false_eq_true, false_iff]
    intro hall
    have hm : i2 ∈ raw.val := by rw [← he]; exact List.getElem_mem hi
    have : GroupNameByte i2 := hall i2 hm
    simp_all
  · simp only [true_iff]
    intro b hb
    obtain ⟨j, hj, he⟩ := List.mem_iff_getElem.1 hb
    apply hp j (by scalar_tac) b
    simp [List.getElem?_eq_getElem hj, he]


theorem validation_ok (raw : Slice U8) (r : core.result.Result Unit subjectgroup.NameError)
    (h : subjectgroup.validate_name raw = ok r) : GroupNameDecision raw.val r := by
  unfold subjectgroup.validate_name at h
  h5i_invert h
  · simp only [GroupNameDecision]
    scalar_tac
  · simp only [GroupNameDecision]
    simp only [subjectgroup.MAX_NAME_LEN] at hc_1
    constructor <;> scalar_tac
  · obtain ⟨hi, he⟩ := slice_index_ok hi2
    have hs : GroupNameStart raw.val := by
      refine ⟨i2, ?_, (alphanumeric_ok _ _ hb).1 hc_2⟩
      exact List.getElem?_eq_some_iff.mpr ⟨hi, he⟩
    have ha := (all_name_ok _ _ hb1).1 hc_3
    simp only [GroupNameDecision, ValidGroupName]
    simp only [subjectgroup.MAX_NAME_LEN] at hc_1
    exact ⟨by scalar_tac, by scalar_tac, hs, ha⟩
  · obtain ⟨hi, he⟩ := slice_index_ok hi2
    have hs : GroupNameStart raw.val := by
      refine ⟨i2, ?_, (alphanumeric_ok _ _ hb).1 hc_2⟩
      exact List.getElem?_eq_some_iff.mpr ⟨hi, he⟩
    have ha : ¬ (∀ b ∈ raw.val, GroupNameByte b) := by
      intro hall
      exact hc_3 ((all_name_ok _ _ hb1).2 hall)
    simp only [GroupNameDecision]
    simp only [subjectgroup.MAX_NAME_LEN] at hc_1
    exact ⟨by scalar_tac, by scalar_tac, hs, ha⟩
  · obtain ⟨hi, he⟩ := slice_index_ok hi2
    have hn : ¬ GroupNameStart raw.val := by
      rintro ⟨c, hhead, ha⟩
      have heq : raw.val[0]? = some i2 := List.getElem?_eq_some_iff.mpr ⟨hi, he⟩
      have : c = i2 := by simp_all
      subst c
      exact hc_2 ((alphanumeric_ok _ _ hb).2 ha)
    simp only [GroupNameDecision]
    simp only [subjectgroup.MAX_NAME_LEN] at hc_1
    exact ⟨by scalar_tac, by scalar_tac, hn⟩

theorem validation_exact (raw : Slice U8) (r : core.result.Result Unit subjectgroup.NameError)
    (h : subjectgroup.validate_name raw = ok r) :
    (r = .Ok () ↔ ValidGroupName raw.val) := by
  have hd := validation_ok raw r h
  cases r with
  | Ok unit => cases unit; simpa [GroupNameDecision] using hd
  | Err error =>
    cases error <;> simp_all [GroupNameDecision, ValidGroupName] <;> omega

theorem immutability_ok (group : subjectgroup.SubjectGroup) (r : Bool)
    (h : subjectgroup.is_immutable group = ok r) :
    (r = true ↔ group.is_virtual = true) := by
  simp only [subjectgroup.is_immutable, Result.ok.injEq] at h
  subst r
  rfl

end oxicloud_kernel.Verified.OxicloudSubjectGroup
