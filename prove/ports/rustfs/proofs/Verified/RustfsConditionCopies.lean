import Verified.RustfsConditionEval
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsBytes (push_ok)
namespace rustfs_kernel.Verified.RustfsConditionCopies
 theorem key_clone (k : condfuncs.Key) : condfuncs.Key.Insts.CoreCloneClone.clone k = ok k := by
  cases k with | mk full nm suffix =>
    cases suffix <;> simp [condfuncs.Key.Insts.CoreCloneClone.clone, u8vec_clone]

theorem entry_clone {T : Type} (inst : core.clone.Clone T) [CloneLaw inst]
    (e : conddata.FuncKeyValue T) : conddata.clone_key_value inst e = ok e := by
  simp [conddata.clone_key_value, key_clone, CloneLaw.clone_ok]

theorem inner_clone {T : Type} (inst : core.clone.Clone T) [CloneLaw inst]
    (a b : conddata.InnerFunc T) (h : conddata.clone_inner inst a = ok b) : b = a := by
  unfold conddata.clone_inner at h
  h5i_invert h
  have hv : entries.val = a.entries.val := by
    unfold conddata.clone_inner_loop at hentries
    refine loop_ok _ (fun x : alloc.vec.Vec (conddata.FuncKeyValue T) × Usize =>
        x.2.val ≤ a.entries.val.length ∧ x.1.val = a.entries.val.take x.2.val)
      (fun v => v.val = a.entries.val) (fun x => a.entries.val.length - x.2.val)
      ?_ _ entries ⟨by simp, by simp [alloc.vec.Vec.new]⟩ hentries
    rintro ⟨out, i⟩ r ⟨hi, ho⟩ hr
    unfold conddata.clone_inner_loop.body at hr
    simp only [entry_clone, bind_tc_ok] at hr
    h5i_invert hr
    · have he := vec_index_slice_ok_get? (by assumption : alloc.vec.Vec.index _ _ _ = ok _)
      have hlt : i.val < a.entries.val.length := by scalar_tac
      rw [List.getElem?_eq_getElem hlt] at he
      simp only [Option.some.injEq] at he
      have hp := push_ok hentries1
      have hadd := add_ok_val hi2
      refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
      rw [hp, ho, show i2.val = i.val + 1 by scalar_tac,
        List.take_add_one, List.getElem?_eq_getElem hlt, he]
      rfl
    · rw [List.take_of_length_le (by scalar_tac)] at ho
      exact ho
  have he : entries = a.entries := by apply alloc.vec.Vec.ext; exact hv
  cases a; simp_all
theorem legacy_pairs_ok {T : Type} (inst : core.clone.Clone T) [CloneLaw inst]
    (a : conddata.InnerFunc T) (b : alloc.vec.Vec (condfuncs.Key × T))
    (h : conddata.legacy_pairs inst a = ok b) :
    b.val = a.entries.val.map (fun e => (e.key, e.values)) := by
  unfold conddata.legacy_pairs conddata.legacy_pairs_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec (condfuncs.Key × T) × Usize =>
      x.2.val ≤ a.entries.val.length ∧
      x.1.val = (a.entries.val.take x.2.val).map (fun e => (e.key, e.values)))
    (fun v => v.val = a.entries.val.map (fun e => (e.key, e.values)))
    (fun x => a.entries.val.length - x.2.val) ?_ _ b ⟨by simp, by simp⟩ h
  rintro ⟨out, i⟩ r ⟨hi, ho⟩ hr
  unfold conddata.legacy_pairs_loop.body at hr
  simp only [key_clone, CloneLaw.clone_ok, bind_tc_ok] at hr
  h5i_invert hr
  · have he := vec_index_slice_ok_get? (by assumption : alloc.vec.Vec.index _ _ _ = ok _)
    have hlt : i.val < a.entries.val.length := by scalar_tac
    rw [List.getElem?_eq_getElem hlt] at he
    simp only [Option.some.injEq] at he
    have hp := push_ok hout1
    have hadd := add_ok_val hi2
    refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
    rw [hp, ho, show i2.val = i.val + 1 by scalar_tac,
      List.take_add_one, List.getElem?_eq_getElem hlt, List.map_append, he]
    rfl
  · rw [List.take_of_length_le (by scalar_tac)] at ho
    exact ho
theorem key_presence_ok {T : Type}
    (a : conddata.InnerFunc T) (b : alloc.vec.Vec (condfuncs.Key × Bool))
    (h : conddata.key_presence a = ok b) :
    b.val = a.entries.val.map (fun e => (e.key, false)) := by
  unfold conddata.key_presence conddata.key_presence_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec (condfuncs.Key × Bool) × Usize =>
      x.2.val ≤ a.entries.val.length ∧
      x.1.val = (a.entries.val.take x.2.val).map (fun e => (e.key, false)))
    (fun v => v.val = a.entries.val.map (fun e => (e.key, false)))
    (fun x => a.entries.val.length - x.2.val) ?_ _ b ⟨by simp, by simp⟩ h
  rintro ⟨out, i⟩ r ⟨hi, ho⟩ hr
  unfold conddata.key_presence_loop.body at hr
  simp only [key_clone, bind_tc_ok] at hr
  h5i_invert hr
  · have he := vec_index_slice_ok_get? (by assumption : alloc.vec.Vec.index _ _ _ = ok _)
    have hlt : i.val < a.entries.val.length := by scalar_tac
    rw [List.getElem?_eq_getElem hlt] at he
    simp only [Option.some.injEq] at he
    have hp := push_ok hout1
    have hadd := add_ok_val hi2
    refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
    rw [hp, ho, show i2.val = i.val + 1 by scalar_tac,
      List.take_add_one, List.getElem?_eq_getElem hlt, List.map_append, he]
    rfl
  · rw [List.take_of_length_le (by scalar_tac)] at ho
    exact ho
end rustfs_kernel.Verified.RustfsConditionCopies
