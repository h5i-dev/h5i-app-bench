import SpecKernel
open Aeneas Aeneas.Std Result oxicloud_kernel
open H5iAppLib hiding lit
namespace oxicloud_kernel.Verified.OxicloudBytes

theorem push_ok {α} {v w : alloc.vec.Vec α} {x : α} (h : alloc.vec.Vec.push v x = ok w) :
    w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  dsimp only at h
  split at h
  · simp only [Result.ok.injEq] at h; subst h; simp [alloc.vec.Vec.from_val]
  · simp at h

/-- Copying a wire spelling preserves every byte. -/
theorem copy_ok (a : Slice U8) (out : alloc.vec.Vec U8)
    (h : bytes.copy a = ok out) : out.val = a.val := by
  unfold bytes.copy bytes.copy_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec U8 × Usize => x.1.val = a.val.take x.2.val)
    (fun out => out.val = a.val) (fun x => a.val.length - x.2.val) ?_
    _ out (by simp) h
  rintro ⟨v, i⟩ r hv hr
  unfold bytes.copy_loop.body at hr
  h5i_invert hr
  · obtain ⟨hi, he⟩ := slice_index_ok hi2
    have hp := push_ok hout1
    have hj := add_ok_val hi3
    simp only at hv ⊢
    refine ⟨?_, by scalar_tac⟩
    rw [hp, hv, hj]
    simpa [he] using (List.take_succ_eq_append_getElem hi).symm
  · simpa [List.take_of_length_le (by scalar_tac : a.val.length ≤ i.val)] using hv

theorem equal_loop_ok (a b : Slice U8) (hl : a.val.length = b.val.length)
    (i : Usize) (r : Bool) (hp : ∀ j < i.val, a.val[j]? = b.val[j]?)
    (h : bytes.equal_loop a b i = ok r) : (r = true ↔ a.val = b.val) := by
  unfold bytes.equal_loop at h
  refine loop_ok _ (fun i : Usize => ∀ j < i.val, a.val[j]? = b.val[j]?)
    (fun r => r = true ↔ a.val = b.val) (fun i => a.val.length - i.val) ?_ i r hp h
  intro x r hx hr
  unfold bytes.equal_loop.body at hr
  h5i_invert hr
  · obtain ⟨ha, hea⟩ := slice_index_ok hi2
    obtain ⟨hb, heb⟩ := slice_index_ok hi3
    simp only [Bool.false_eq_true, false_iff]
    intro he
    have he' : i2 = i3 := by simpa [List.getElem?_eq_getElem ha, List.getElem?_eq_getElem hb, hea, heb] using congrArg (fun xs : List U8 => xs[x.val]?) he
    subst i3
    simp_all
  · obtain ⟨ha, hea⟩ := slice_index_ok hi2
    obtain ⟨hb, heb⟩ := slice_index_ok hi3
    have hj := add_ok_val hi4
    refine ⟨?_, by scalar_tac⟩
    intro j hji
    by_cases hjx : j < x.val
    · exact hx j hjx
    · have : j = x.val := by scalar_tac
      subst j
      have he : i2 = i3 := (u8_eq_iff _ _).2 (by simpa using hc_1)
      rw [List.getElem?_eq_getElem ha, List.getElem?_eq_getElem hb, hea, heb, he]
  · simp only [true_iff]
    apply List.ext_getElem hl
    intro j ha hb
    have := hx j (by scalar_tac)
    simpa [List.getElem?_eq_getElem ha, List.getElem?_eq_getElem hb] using this

/-- The byte comparator accepts precisely identical spellings. -/
theorem equal_ok (a b : Slice U8) (r : Bool) (h : bytes.equal a b = ok r) :
    (r = true ↔ a.val = b.val) := by
  unfold bytes.equal at h
  h5i_invert h
  · simp only [Bool.false_eq_true, false_iff]
    intro he
    have : a.length = b.length := by simp [Slice.length, he]
    simp_all
  · exact equal_loop_ok a b (by scalar_tac) 0#usize r (by simp) h

end oxicloud_kernel.Verified.OxicloudBytes
