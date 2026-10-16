import Verified.RustfsBase64
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsBinaryMatch

theorem match_sound (f : conddata.BinaryFuncValue) (requests : Slice (alloc.vec.Vec U8))
    (b : Bool) (h : conddata.binary_key_matches f requests = ok b) :
    b = true → (∀ e ∈ requests.val, ValidBinaryRequest e) ∧
      ∃ e ∈ requests.val, MatchingBinaryRequest f e := by
  unfold conddata.binary_key_matches conddata.binary_key_matches_loop at h
  refine loop_ok _ (fun x : Bool × Usize => x.2.val ≤ requests.val.length ∧
      (∀ e ∈ requests.val.take x.2.val, ValidBinaryRequest e) ∧
      (x.1 = true → ∃ e ∈ requests.val.take x.2.val, MatchingBinaryRequest f e))
    (fun r => r = true → (∀ e ∈ requests.val, ValidBinaryRequest e) ∧
      ∃ e ∈ requests.val, MatchingBinaryRequest f e)
    (fun x => requests.val.length - x.2.val) ?_ _ b
    ⟨by simp, by simp, by simp⟩ h
  rintro ⟨matched,i⟩ r ⟨hi,hvalid,hmatched⟩ hr
  unfold conddata.binary_key_matches_loop.body at hr
  h5i_invert hr
  · obtain ⟨hlt, he⟩ := slice_index_ok hv
    have hd := rustfs_kernel.Verified.RustfsBase64.decode_sound _ _ hr_1
    simp only [rustfs_kernel.Verified.RustfsForceDelete.deref_val] at hd
    have hm := rustfs_kernel.Verified.RustfsCondData.member_ok _ _ _ hb_1
    simp only [rustfs_kernel.Verified.RustfsForceDelete.deref_val] at hm
    have hadd := add_ok_val hi2
    have ht : requests.val.take i2.val = requests.val.take i.val ++ [v] := by
      rw [show i2.val = i.val + 1 by scalar_tac, List.take_add_one,
        List.getElem?_eq_getElem hlt, he]
      rfl
    refine ⟨⟨by scalar_tac, ?_, ?_⟩, by scalar_tac⟩
    · rw [ht]
      intro e hem
      simp only [List.mem_append, List.mem_singleton] at hem
      rcases hem with hem | rfl
      · exact hvalid e hem
      · exact ⟨_, hd⟩
    · intro hyes
      rw [ht]
      by_cases hb : b_1 = true
      · obtain ⟨y, hym, hye⟩ := hm.1 hb
        refine ⟨v, by simp, y, hym, ?_⟩
        rw [hye]
        exact hd
      · have heq : matched = matched1 := by simpa [hb] using hmatched1
        have hmtrue : matched = true := heq.trans hyes
        obtain ⟨e, hem, heyes⟩ := hmatched hmtrue
        exact ⟨e, List.mem_append_left _ hem, heyes⟩
  · intro hfalse; cases hfalse
  · intro hyes
    have he : requests.val.take i.val = requests.val := List.take_of_length_le (by scalar_tac)
    rw [he] at hvalid hmatched
    exact ⟨hvalid, hmatched hyes⟩
end rustfs_kernel.Verified.RustfsBinaryMatch
