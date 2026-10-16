import Verified.RustfsManagementEquality
import Verified.RustfsManagementQueries
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsDuplicateMarks
open rustfs_kernel.Verified.RustfsManagementEquality (statement_eq_ok)
open rustfs_kernel.Verified.RustfsManagementQueries (index_member_ok)
open rustfs_kernel.Verified.RustfsForceDelete (deref_val)
theorem mark_loop_ok (ss : Slice manage.Statement) (i : Usize) (hi : i.val < ss.val.length)
    (initial : alloc.vec.Vec Usize) (start : Usize) (hstart : start.val ≤ ss.val.length)
    (out : alloc.vec.Vec Usize) (h : manage.mark_duplicates_loop ss i initial start = ok out) :
    ∀ k, k ∈ out.val ↔ k ∈ initial.val ∨ start.val ≤ k.val ∧
      ∃ hk : k.val < ss.val.length, MetadataStatementEquivalent ss.val[i.val] ss.val[k.val] := by
  unfold manage.mark_duplicates_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec Usize × Usize =>
      start.val ≤ x.2.val ∧ x.2.val ≤ ss.val.length ∧
      ∀ k, k ∈ x.1.val ↔ k ∈ initial.val ∨ start.val ≤ k.val ∧ k.val < x.2.val ∧
        ∃ hk : k.val < ss.val.length, MetadataStatementEquivalent ss.val[i.val] ss.val[k.val])
    (fun out => ∀ k, k ∈ out.val ↔ k ∈ initial.val ∨ start.val ≤ k.val ∧
      ∃ hk : k.val < ss.val.length, MetadataStatementEquivalent ss.val[i.val] ss.val[k.val])
    (fun x => ss.val.length - x.2.val) ?_ _ out
    ⟨Nat.le_refl _,hstart,by
      intro k
      dsimp only
      have hn : ¬ (start.val ≤ k.val ∧ k.val < start.val) := by omega
      constructor
      · exact fun hh => .inl hh
      · rintro (hh | ⟨h1,h2,_⟩)
        · exact hh
        · exact False.elim (hn ⟨h1,h2⟩)⟩ h
  rintro ⟨ds,j⟩ r ⟨hj,hjl,hd⟩ hr
  dsimp only at hj hjl hd ⊢
  unfold manage.mark_duplicates_loop.body at hr
  h5i_invert hr
  · obtain ⟨_,he⟩ := slice_index_ok hs
    obtain ⟨hlt,he1⟩ := slice_index_ok hs1
    have heq := statement_eq_ok s s1 b hb
    have hnew : ∀ k, k ∈ dups1.val ↔ k ∈ ds.val ∨ k = j ∧ MetadataStatementEquivalent s s1 := by
      h5i_invert hdups1
      all_goals
        try have hm := index_member_ok _ _ _ hb1
        try have hp := rustfs_kernel.Verified.RustfsBytes.push_ok hdups1
        intro k
        simp_all [deref_val]
    have hadd := add_ok_val hj1
    dsimp only
    refine ⟨⟨by scalar_tac,by scalar_tac,?_⟩,by scalar_tac⟩
    intro k
    rw [hnew,hd]
    have hidx : k = j ↔ k.val = j.val := ⟨congrArg UScalar.val, UScalar.eq_of_val_eq⟩
    rw [hidx,←he,←he1]
    constructor
    · rintro (hold | ⟨hejk,hmatch⟩)
      · rcases hold with hold | ⟨hs,hk,hk',hm⟩
        · exact .inl hold
        · exact .inr ⟨hs,by scalar_tac,hk',hm⟩
      · have hkj : k = j := UScalar.eq_of_val_eq hejk
        subst k
        exact .inr ⟨hj,by scalar_tac,hlt,hmatch⟩
    · rintro (hold | ⟨hs,hk,hk',hm⟩)
      · exact .inl (.inl hold)
      · by_cases hkj : k.val < j.val
        · exact .inl (.inr ⟨hs,hkj,hk',hm⟩)
        · have hkj : k.val = j.val := by scalar_tac
          have hkjs : k = j := UScalar.eq_of_val_eq hkj
          subst k
          exact .inr ⟨rfl,hm⟩
  · dsimp only
    have hje : j.val = ss.val.length := by scalar_tac
    intro k
    rw [hd,hje]
    constructor
    · rintro (hh | ⟨hs,hk,hk',hm⟩)
      · exact .inl hh
      · exact .inr ⟨hs,hk',hm⟩
    · rintro (hh | ⟨hs,hk,hm⟩)
      · exact .inl hh
      · exact .inr ⟨hs,hk,hk,hm⟩
theorem mark_ok (ss : Slice manage.Statement) (i : Usize) (hi : i.val < ss.val.length)
    (initial out : alloc.vec.Vec Usize) (h : manage.mark_duplicates ss i initial = ok out) :
    ∀ k, k ∈ out.val ↔ k ∈ initial.val ∨ i.val < k.val ∧
      ∃ hk : k.val < ss.val.length, MetadataStatementEquivalent ss.val[i.val] ss.val[k.val] := by
  unfold manage.mark_duplicates at h
  obtain ⟨j,hj,h⟩ := bind_tc_eq_ok.1 h
  have hadd := add_ok_val hj
  have hj' : j.val = i.val + 1 := by scalar_tac
  have hm := mark_loop_ok ss i hi initial j (by scalar_tac) out h
  simpa only [hj',Nat.add_one_le_iff] using hm
end rustfs_kernel.Verified.RustfsDuplicateMarks
