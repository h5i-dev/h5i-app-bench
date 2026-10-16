import Verified.RustfsClaimTokens
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsBytes (push_ok)
open rustfs_kernel.Verified.RustfsForceDelete (deref_val)
namespace rustfs_kernel.Verified.RustfsExtras

theorem member_iff (xs : Slice (alloc.vec.Vec U8)) (x : alloc.vec.Vec U8) (b : Bool)
    (h : bytes.member xs x.deref = ok b) : (b = true ↔ x ∈ xs.val) := by
  rw [rustfs_kernel.Verified.RustfsCondData.member_ok _ _ _ h, deref_val]
  constructor
  · rintro ⟨y,hy,he⟩
    have hh : y = x := alloc.vec.Vec.ext _ _ he
    simpa only [hh] using hy
  · intro hx; exact ⟨x,hx,rfl⟩

theorem unique_ok (values : Slice (alloc.vec.Vec U8)) (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : extras.unique_values values = ok out) :
    out.val.Nodup ∧ ∀ x, x ∈ out.val ↔ x ∈ values.val := by
  unfold extras.unique_values extras.unique_values_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec (alloc.vec.Vec U8) × Usize =>
      x.2.val ≤ values.val.length ∧ x.1.val.Nodup ∧
      ∀ v, v ∈ x.1.val ↔ v ∈ values.val.take x.2.val)
    (fun out => out.val.Nodup ∧ ∀ x, x ∈ out.val ↔ x ∈ values.val)
    (fun x => values.val.length - x.2.val) ?_ _ out
    ⟨by simp,by simp,by simp [alloc.vec.Vec.new,alloc.vec.Vec.from_val]⟩ h
  rintro ⟨out,i⟩ r ⟨hi,hnd,hm⟩ hr
  unfold extras.unique_values_loop.body at hr
  simp only [u8vec_clone] at hr
  h5i_invert hr
  · obtain ⟨hlt,he⟩ := slice_index_ok hv
    have hbmem := member_iff out.deref v b hb
    rw [deref_val] at hbmem
    have hadd := add_ok_val hi2
    have hij : i2.val = i.val+1 := by scalar_tac
    have htake : values.val.take i2.val = values.val.take i.val ++ [v] := by
      rw [hij,List.take_add_one,List.getElem?_eq_getElem hlt,he]
      rfl
    h5i_invert hout1
    · have hvout := hbmem.1 hc_1
      have hvtake := (hm v).1 hvout
      refine ⟨⟨by scalar_tac,hnd,?_⟩,by scalar_tac⟩
      intro x
      rw [htake,List.mem_append,List.mem_singleton]
      constructor
      · intro hx; exact Or.inl ((hm x).1 hx)
      · rintro (hx | rfl)
        · exact (hm x).2 hx
        · exact hvout
    · have hp := push_ok hout1
      have hn : v ∉ out.val := fun hh => hc_1 (hbmem.2 hh)
      refine ⟨⟨by scalar_tac,?_,?_⟩,by scalar_tac⟩
      · rw [hp]
        simp only [List.nodup_append,hnd,List.nodup_singleton,true_and,List.mem_singleton]
        intro a ha b hb heq
        have hbv : b = v := by simpa using hb
        exact hn ((heq.trans hbv) ▸ ha)
      · intro x
        simp only [hp,htake,List.mem_append,List.mem_singleton,hm]
  · have hle : values.val.length ≤ i.val := by scalar_tac
    exact ⟨hnd,by simpa only [List.take_of_length_le hle] using hm⟩
theorem principal_set_ok (v : extras.PrincipalValues) (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : extras.principal_values_into_set v = ok out) :
    out.val.Nodup ∧ ∀ x, x ∈ out.val ↔ x ∈ (match v with
      | .Single s => [s]
      | .Multiple vs => vs.val) := by
  cases v with
  | Single s =>
    unfold extras.principal_values_into_set at h
    rw [push_ok h]
    simp [alloc.vec.Vec.new,alloc.vec.Vec.from_val]
  | Multiple vs =>
    simpa [deref_val] using unique_ok vs.deref out h

theorem lazybuf_initial (source : Slice U8) :
    ∃ out, extras.lazybuf_new source = ok out ∧ out.source = source ∧
      out.buffer = none ∧ out.written.val = 0 := by
  exact ⟨_,rfl,rfl,rfl,rfl⟩

end rustfs_kernel.Verified.RustfsExtras
