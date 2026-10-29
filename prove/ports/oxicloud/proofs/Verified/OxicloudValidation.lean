import Verified.OxicloudBytes
open Aeneas Aeneas.Std Result oxicloud_kernel oxicloud_kernel.SpecKernel
open H5iAppLib hiding lit
open oxicloud_kernel.Verified.OxicloudBytes
namespace oxicloud_kernel.Verified.OxicloudValidation

theorem email_ok (claim : Option Bool) (required : Bool) (d : validation.EmailDecision)
    (h : validation.classify_email_verification claim required = ok d) :
    VerifiedEmailDecision claim required d := by
  cases claim with
  | none =>
    cases required <;> simp_all [validation.classify_email_verification] <;>
      subst d <;> simp [VerifiedEmailDecision]
  | some claim =>
    cases claim <;> cases required <;>
      simp_all [validation.classify_email_verification] <;> subst d <;> simp [VerifiedEmailDecision]

theorem storage_byte_ok (b : U8) (r : Bool) (h : validation.storage_byte b = ok r) :
    (r = true ↔ StorageByte b) := by
  unfold validation.storage_byte at h
  h5i_invert h <;> simp_all [StorageByte] <;> scalar_tac

theorem base64url_byte_ok (b : U8) (r : Bool) (h : validation.base64url_byte b = ok r) :
    (r = true ↔ Base64UrlByte b) := by
  unfold validation.base64url_byte at h
  h5i_invert h
  all_goals have hp := storage_byte_ok _ _ hb1
  all_goals simp_all [Base64UrlByte] <;> scalar_tac




theorem all_storage_ok (raw : Slice U8) (r : Bool)
    (h : validation.all_storage raw = ok r) :
    (r = true ↔ ∀ b ∈ raw.val, StorageByte b) := by
  unfold validation.all_storage validation.all_storage_loop at h
  refine loop_ok _
    (fun i : Usize => ∀ j < i.val, ∀ b, raw.val[j]? = some b → StorageByte b)
    (fun r => r = true ↔ ∀ b ∈ raw.val, StorageByte b)
    (fun i => raw.val.length - i.val) ?_ 0#usize r (by simp) h
  intro i result hp hr
  unfold validation.all_storage_loop.body at hr
  h5i_invert hr
  · obtain ⟨hi, he⟩ := slice_index_ok hi2
    have hb' := storage_byte_ok _ _ hb
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
    have hb' := storage_byte_ok _ _ hb
    simp only [Bool.false_eq_true, false_iff]
    intro hall
    have hm : i2 ∈ raw.val := by rw [← he]; exact List.getElem_mem hi
    have : StorageByte i2 := hall i2 hm
    simp_all
  · simp only [true_iff]
    intro b hb
    obtain ⟨j, hj, he⟩ := List.mem_iff_getElem.1 hb
    apply hp j (by scalar_tac) b
    simp [List.getElem?_eq_getElem hj, he]

theorem all_base64url_ok (raw : Slice U8) (r : Bool)
    (h : validation.all_base64url raw = ok r) :
    (r = true ↔ ∀ b ∈ raw.val, Base64UrlByte b) := by
  unfold validation.all_base64url validation.all_base64url_loop at h
  refine loop_ok _
    (fun i : Usize => ∀ j < i.val, ∀ b, raw.val[j]? = some b → Base64UrlByte b)
    (fun r => r = true ↔ ∀ b ∈ raw.val, Base64UrlByte b)
    (fun i => raw.val.length - i.val) ?_ 0#usize r (by simp) h
  intro i result hp hr
  unfold validation.all_base64url_loop.body at hr
  h5i_invert hr
  · obtain ⟨hi, he⟩ := slice_index_ok hi2
    have hb' := base64url_byte_ok _ _ hb
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
    have hb' := base64url_byte_ok _ _ hb
    simp only [Bool.false_eq_true, false_iff]
    intro hall
    have hm : i2 ∈ raw.val := by rw [← he]; exact List.getElem_mem hi
    have : Base64UrlByte i2 := hall i2 hm
    simp_all
  · simp only [true_iff]
    intro b hb
    obtain ⟨j, hj, he⟩ := List.mem_iff_getElem.1 hb
    apply hp j (by scalar_tac) b
    simp [List.getElem?_eq_getElem hj, he]

/-- Accepted storage selectors have a bounded length and exclude every character outside
lowercase ASCII letters, decimal digits, hyphens, and underscores. -/
theorem storage_name_ok (raw : Slice U8) (r : Bool)
    (h : validation.is_valid_entry_name raw = ok r) : (r = true ↔ ValidStorageName raw.val) := by
  unfold validation.is_valid_entry_name at h
  h5i_invert h
  · simp only [Bool.false_eq_true, false_iff]
    simp only [ValidStorageName]
    intro hall
    scalar_tac
  · simp only [Bool.false_eq_true, false_iff]
    simp only [ValidStorageName]
    intro hall
    scalar_tac
  · have ha := all_storage_ok _ _ h
    simp only [ValidStorageName]
    have hlo : 1 ≤ raw.val.length := by scalar_tac
    have hhi : raw.val.length ≤ 32 := by scalar_tac
    simpa [hlo, hhi] using ha

/-- Thumbprint validation preserves the accepted input exactly and classifies invalid shapes. -/
theorem jkt_ok (raw : Slice U8)
    (r : core.result.Result (alloc.vec.Vec U8) validation.JktError)
    (h : validation.validate_dpop_jkt raw = ok r) : JktDecision raw.val r := by
  unfold validation.validate_dpop_jkt at h
  h5i_invert h
  · simp only [JktDecision]
    scalar_tac
  · have ha := all_base64url_ok _ _ hb
    have hc' := copy_ok _ _ hv
    simp only [JktDecision, ValidJkt]
    exact ⟨⟨by scalar_tac, ha.1 hc_1⟩, hc'⟩
  · have ha := all_base64url_ok _ _ hb
    simp only [JktDecision]
    exact ⟨by scalar_tac, by simp_all⟩

end oxicloud_kernel.Verified.OxicloudValidation
