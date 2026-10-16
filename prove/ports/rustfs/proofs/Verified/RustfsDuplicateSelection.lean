import Verified.RustfsStatementRetention
import Verified.RustfsDuplicateMarks
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsDuplicateSelection
open rustfs_kernel.Verified.RustfsManagementQueries (index_member_ok)
open rustfs_kernel.Verified.RustfsDuplicateMarks (mark_ok)
open rustfs_kernel.Verified.RustfsForceDelete (deref_val)
theorem advance_marked (ss : List manage.Statement) (i : Usize) (old new : List Usize)
    (hold : MarkedThrough ss i.val old)
    (hnew : ∀ k, k ∈ new ↔ k ∈ old ∨ i ∉ old ∧ DuplicatePair ss i k) :
    MarkedThrough ss (i.val + 1) new := by
  have hstable (j : Usize) (hj : j.val ≤ i.val) : j ∈ new ↔ j ∈ old := by
    rw [hnew]
    constructor
    · rintro (hh | ⟨_,hp⟩)
      · exact hh
      · exact False.elim (by have := hp.1; omega)
    · exact fun hh => .inl hh
  intro k
  rw [hnew]
  constructor
  · rintro (hk | ⟨hi,hp⟩)
    · obtain ⟨j,hj,hjm,hp⟩ := (hold k).1 hk
      exact ⟨j,by omega,fun hh => hjm ((hstable j (by omega)).1 hh),hp⟩
    · exact ⟨i,by omega,fun hh => hi ((hstable i (Nat.le_refl _)).1 hh),hp⟩
  · rintro ⟨j,hj,hjm,hp⟩
    have hjo : j ∉ old := fun hh => hjm ((hstable j (by omega)).2 hh)
    by_cases hj' : j.val < i.val
    · exact .inl ((hold k).2 ⟨j,hj',hjo,hp⟩)
    · have hje : j = i := UScalar.eq_of_val_eq (by omega)
      subst j
      exact .inr ⟨hjo,hp⟩

theorem selection_loop_ok (p : manage.Policy)
    (r : alloc.vec.Vec U8 × alloc.vec.Vec U8 × alloc.vec.Vec manage.Statement × alloc.vec.Vec Usize)
    (h : manage.drop_duplicate_statements_loop p (alloc.vec.Vec.new _) 0#usize = ok r) :
    ∃ ds, r = (p.id,p.version,p.statements,ds) ∧ MarkedThrough p.statements.val p.statements.val.length ds.val := by
  unfold manage.drop_duplicate_statements_loop at h
  refine loop_ok _ (fun x : alloc.vec.Vec Usize × Usize =>
      x.2.val ≤ p.statements.val.length ∧ MarkedThrough p.statements.val x.2.val x.1.val)
    (fun r => ∃ ds, r = (p.id,p.version,p.statements,ds) ∧ MarkedThrough p.statements.val p.statements.val.length ds.val)
    (fun x => p.statements.val.length - x.2.val) ?_ _ r
    ⟨by simp,by intro k; simp [MarkedThrough,alloc.vec.Vec.new]⟩ h
  rintro ⟨ds,i⟩ r ⟨hi,hd⟩ hr
  dsimp only at hi hd ⊢
  unfold manage.drop_duplicate_statements_loop.body at hr
  h5i_invert hr
  · have hlt : i.val < p.statements.val.length := by scalar_tac
    have hm := index_member_ok _ _ _ hb
    simp only [deref_val] at hm
    have hadd := add_ok_val hi2
    have hnew : ∀ k, k ∈ dups1.val ↔ k ∈ ds.val ∨ i ∉ ds.val ∧ DuplicatePair p.statements.val i k := by
      h5i_invert hdups1
      · have hin := hm.1 hc_1
        intro k
        simp [hin]
      · have hn : i ∉ ds.val := fun hh => hc_1 (hm.2 hh)
        have hmarks := mark_ok _ i (by simpa [deref_val] using hlt) ds dups1 hdups1
        simp only [deref_val] at hmarks
        intro k
        rw [hmarks k]
        simp only [hn,not_false_eq_true,true_and,DuplicatePair]
        constructor
        · rintro (hh | ⟨hk,hk',he⟩)
          · exact .inl hh
          · exact .inr ⟨hk,hlt,hk',he⟩
        · rintro (hh | ⟨hk,_,hk',he⟩)
          · exact .inl hh
          · exact .inr ⟨hk,hk',he⟩
    dsimp only
    refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
    have he : i2.val = i.val + 1 := by scalar_tac
    rw [he]
    exact advance_marked _ _ _ _ hd hnew
  · dsimp only
    refine ⟨ds,rfl,?_⟩
    have he : i.val = p.statements.val.length := by scalar_tac
    simpa only [he] using hd
theorem drop_ok (p out : manage.Policy) (h : manage.drop_duplicate_statements p = ok out) :
    out.id = p.id ∧ out.version = p.version ∧ DeduplicatedStatements p.statements.val out.statements.val := by
  unfold manage.drop_duplicate_statements at h
  obtain ⟨r,hr,h⟩ := bind_tc_eq_ok.1 h
  obtain ⟨ds,he,hd⟩ := selection_loop_ok p r hr
  subst r
  change (do
    let v3 ← manage.retained_statements p.statements.deref ds.deref
    ok { id := p.id, version := p.version, statements := v3 }) = ok out at h
  obtain ⟨v3,hv3,h⟩ := bind_tc_eq_ok.1 h
  simp only [Result.ok.injEq] at h
  subst out
  have ht := rustfs_kernel.Verified.RustfsStatementRetention.retain_ok _ _ _ hv3
  simp only [deref_val] at ht
  exact ⟨rfl,rfl,ds.val,hd,ht⟩
end rustfs_kernel.Verified.RustfsDuplicateSelection
