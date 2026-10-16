import Verified.RustfsCleanCanonical
import Verified.RustfsBase64
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsBinaryConstruction

theorem forall₂_snoc {A B : Type} {R : A → B → Prop} {xs : List A} {ys : List B}
    (h : List.Forall₂ R xs ys) {x : A} {y : B} (hr : R x y) :
    List.Forall₂ R (xs ++ [x]) (ys ++ [y]) := by
  induction h with
  | nil => exact .cons hr .nil
  | cons h ht ih => exact .cons h ih

theorem from_values_ok (es : alloc.vec.Vec (alloc.vec.Vec U8)) (v : conddata.BinaryFuncValue)
    (h : conddata.binary_from_encoded_values es = ok (.Ok v)) :
    v.encoded = es ∧ List.Forall₂ BinaryValueEncoding es.val v.decoded.val := by
  unfold conddata.binary_from_encoded_values conddata.binary_from_encoded_values_loop at h
  have hh : ∀ w : conddata.BinaryFuncValue,
      (core.result.Result.Ok v : core.result.Result conddata.BinaryFuncValue conddata.BinaryFuncValueError) = .Ok w →
      w.encoded = es ∧ List.Forall₂ BinaryValueEncoding es.val w.decoded.val := by
    refine loop_ok _ (fun x : alloc.vec.Vec (alloc.vec.Vec U8) × Usize =>
        x.2.val ≤ es.val.length ∧ List.Forall₂ BinaryValueEncoding (es.val.take x.2.val) x.1.val)
      (fun r => ∀ w, r = core.result.Result.Ok w →
        w.encoded = es ∧ List.Forall₂ BinaryValueEncoding es.val w.decoded.val)
      (fun x => es.val.length - x.2.val) ?_ _ (.Ok v)
      ⟨by simp, by constructor⟩ h
    rintro ⟨ds,i⟩ r ⟨hi,hrel⟩ hr
    unfold conddata.binary_from_encoded_values_loop.body at hr
    h5i_invert hr
    · have hd := rustfs_kernel.Verified.RustfsBase64.decode_sound _ _ hr_1
      simp only [rustfs_kernel.Verified.RustfsForceDelete.deref_val] at hd
      have he := vec_index_slice_ok_get? hv_1
      have hlt : i.val < es.val.length := by scalar_tac
      rw [List.getElem?_eq_getElem hlt] at he
      simp only [Option.some.injEq] at he
      have hp := rustfs_kernel.Verified.RustfsBytes.push_ok hdecoded1
      have hadd := add_ok_val hi2
      refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
      rw [hp, show i2.val = i.val + 1 by scalar_tac, List.take_add_one,
        List.getElem?_eq_getElem hlt, he]
      exact forall₂_snoc hrel hd
    · intro w hw; cases hw
    · intro w hw; cases hw
      refine ⟨rfl, ?_⟩
      rw [List.take_of_length_le (by scalar_tac)] at hrel
      exact hrel
  exact hh v rfl
theorem new_ok (es : Slice U8) (v : conddata.BinaryFuncValue)
    (h : conddata.binary_new es = ok (.Ok v)) :
    v.encoded.val.map (fun e => e.val) = [es.val] ∧
      List.Forall₂ BinaryValueEncoding v.encoded.val v.decoded.val := by
  unfold conddata.binary_new at h
  h5i_invert h
  have hv := rustfs_kernel.Verified.RustfsCleanCanonical.to_vec_ok es v_1 hv_1
  rcases from_values_ok __v v h with ⟨he, hr⟩
  refine ⟨?_, by simpa only [he] using hr⟩
  rw [he, rustfs_kernel.Verified.RustfsBytes.push_ok h__v]
  simp [alloc.vec.Vec.new, alloc.vec.Vec.from_val, hv]
end rustfs_kernel.Verified.RustfsBinaryConstruction
