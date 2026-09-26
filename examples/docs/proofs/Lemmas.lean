import Spec
/-! Each extracted helper computes its list counterpart in `Spec`. -/
open Aeneas Aeneas.Std Result docs_kernel docs_kernel.Spec

namespace docs_kernel.Lemmas

theorem usize_max_le : Usize.max ≤ U64.max := by
  rw [Usize.max_def, U64.max_def]
  cases System.Platform.numBits_eq <;> simp_all [Usize.numBits, U64.numBits]

theorem roleOf_cons (m : Member) (l : List Member) (p u : Nat) :
    roleOf (m :: l) p u = if m.project.val = p ∧ m.user.val = u then some m.role else roleOf l p u := by
  simp only [roleOf, List.find?_cons]
  split <;> simp_all

@[step]
theorem role_of_loop_spec (ms : alloc.vec.Vec Member) (p u : U64) (i : Usize)
    (hi : i.val ≤ ms.length) :
    role_of_loop ms p u i ⦃ r => r = roleOf (ms.val.drop i.val) p.val u.val ⦄ := by
  unfold role_of_loop
  apply loop.spec_decr_nat (measure := fun (j : Usize) => ms.length - j.val)
    (inv := fun j => j.val ≤ ms.length ∧
      roleOf (ms.val.drop i.val) p.val u.val = roleOf (ms.val.drop j.val) p.val u.val)
  · rintro j ⟨hj, heq⟩
    unfold role_of_loop.body
    step*
    · rw [heq, List.drop_eq_getElem_cons (by scalar_tac), roleOf_cons]; simp_all
    · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
      rw [heq, List.drop_eq_getElem_cons (by scalar_tac), roleOf_cons, i2_post]; simp_all
    · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
      rw [heq, List.drop_eq_getElem_cons (by scalar_tac), roleOf_cons, i2_post]; simp_all
    · rw [heq, List.drop_eq_nil_of_le (by scalar_tac)]; rfl
  · simp [hi]

@[step]
theorem role_of_spec (ms : alloc.vec.Vec Member) (p u : U64) :
    role_of ms p u ⦃ r => r = roleOf ms.val p.val u.val ⦄ := by
  unfold role_of
  step*
  simp_all

@[step]
theorem can_spec (s : Snapshot) (u p : U64) (a : Action) :
    can s u p a ⦃ b => b = allowed (Snapshot.toSt s) u.val p.val a ⦄ := by
  unfold can
  step*
  · subst o_post; rename_i h; simp [allowed, Snapshot.toSt, h]
  · subst o_post; rename_i h
    cases role <;> cases a <;> simp [allows, allowed, policy, Snapshot.toSt, h]

theorem clone_bytes (v : alloc.vec.Vec U8) :
    alloc.vec.CloneVec.clone core.clone.CloneU8 v = ok v := by
  have h := Slice.clone_spec (clone := liftFun1 core.clone.impls.CloneU8.clone) (s := v.slice)
    (fun _ _ => rfl)
  rw [WP.spec_equiv_exists] at h
  obtain ⟨s', hs, rfl⟩ := h
  simp [alloc.vec.CloneVec.clone, hs]

@[step]
theorem document_clone_spec (d : Document) :
    Document.Insts.CoreCloneClone.clone d ⦃ d' => d' = d ⦄ := by
  unfold Document.Insts.CoreCloneClone.clone
  simp only [clone_bytes]
  simp [WP.spec_ok]

theorem findDoc_cons (d : Document) (l : List Document) (id : Nat) :
    findDoc (d :: l) id = if d.id.val = id then some d else findDoc l id := by
  simp only [findDoc, List.find?_cons]
  split <;> simp_all

@[step]
theorem find_document_loop_spec (ds : alloc.vec.Vec Document) (id : U64) (i : Usize)
    (hi : i.val ≤ ds.length) :
    find_document_loop ds id i ⦃ r => r = findDoc (ds.val.drop i.val) id.val ⦄ := by
  unfold find_document_loop
  apply loop.spec_decr_nat (measure := fun (j : Usize) => ds.length - j.val)
    (inv := fun j => j.val ≤ ds.length ∧
      findDoc (ds.val.drop i.val) id.val = findDoc (ds.val.drop j.val) id.val)
  · rintro j ⟨hj, heq⟩
    unfold find_document_loop.body
    step*
    · rw [heq, List.drop_eq_getElem_cons (by scalar_tac), findDoc_cons]; simp_all
    · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
      rw [heq, List.drop_eq_getElem_cons (by scalar_tac), findDoc_cons, i2_post]; simp_all
    · rw [heq, List.drop_eq_nil_of_le (by scalar_tac)]; rfl
  · simp [hi]

@[step]
theorem find_document_spec (ds : alloc.vec.Vec Document) (id : U64) :
    find_document ds id ⦃ r => r = findDoc ds.val id.val ⦄ := by
  unfold find_document
  step*
  simp_all

@[step]
theorem role_eq_spec (a b : Role) :
    Role.Insts.CoreCmpPartialEqRole.eq a b ⦃ r => r = decide (a = b) ⦄ := by
  cases a <;> cases b <;> simp [Role.Insts.CoreCmpPartialEqRole.eq, Role.read_discriminant, WP.spec_ok]

theorem owners_cons (m : Member) (l : List Member) (p : Nat) :
    owners (m :: l) p = (if m.project.val = p ∧ m.role = .Owner then 1 else 0) + owners l p := by
  simp only [owners, List.filter_cons]
  split <;> simp_all; omega

@[step]
theorem count_owners_loop_spec (ms : alloc.vec.Vec Member) (p n : U64) (i : Usize)
    (hi : i.val ≤ ms.length) (hn : n.val ≤ i.val) :
    count_owners_loop ms p n i ⦃ r => r.val = n.val + owners (ms.val.drop i.val) p.val ⦄ := by
  unfold count_owners_loop
  apply loop.spec_decr_nat (measure := fun (x : U64 × Usize) => ms.length - x.2.val)
    (inv := fun x => x.2.val ≤ ms.length ∧ x.1.val ≤ x.2.val ∧
      n.val + owners (ms.val.drop i.val) p.val = x.1.val + owners (ms.val.drop x.2.val) p.val)
  · rintro ⟨k, j⟩ ⟨hj, hk, heq⟩
    simp only at hj hk heq ⊢
    unfold count_owners_loop.body
    step*
    · have hc : ms.val.drop j.val = m :: ms.val.drop (j.val + 1) := by
        rw [m_post]; exact List.drop_eq_getElem_cons (by scalar_tac)
      have hlen := ms.len_ineq
      have hb := usize_max_le
      split
      · step*
        split
        · step*
          all_goals first
            | scalar_tac
            | refine ⟨by scalar_tac, by scalar_tac, ?_, by scalar_tac⟩
              rw [heq, hc, owners_cons, i2_post]; grind
        · step*
          refine ⟨by scalar_tac, by scalar_tac, ?_, by scalar_tac⟩
          rw [heq, hc, owners_cons, i2_post]; grind
      · step*
        refine ⟨by scalar_tac, by scalar_tac, ?_, by scalar_tac⟩
        rw [heq, hc, owners_cons, i2_post]; grind
    · rw [heq, List.drop_eq_nil_of_le (by scalar_tac)]; simp [owners]
  · simp [hi, hn]

@[step]
theorem count_owners_spec (ms : alloc.vec.Vec Member) (p : U64) :
    count_owners ms p ⦃ n => n.val = owners ms.val p.val ⦄ := by
  unfold count_owners
  step*
  simp_all

@[step]
theorem documents_in_loop_spec (ds : alloc.vec.Vec Document) (p : U64)
    (out : alloc.vec.Vec Document) (i : Usize) (hi : i.val ≤ ds.length) (ho : out.length ≤ i.val) :
    documents_in_loop ds p out i ⦃ v =>
      v.val = out.val ++ (ds.val.drop i.val).filter (fun d => d.project.val = p.val) ⦄ := by
  unfold documents_in_loop
  apply loop.spec_decr_nat
    (measure := fun (x : alloc.vec.Vec Document × Usize) => ds.length - x.2.val)
    (inv := fun x => x.2.val ≤ ds.length ∧ x.1.length ≤ x.2.val ∧
      out.val ++ (ds.val.drop i.val).filter (fun d => d.project.val = p.val) =
        x.1.val ++ (ds.val.drop x.2.val).filter (fun d => d.project.val = p.val))
  · rintro ⟨o, j⟩ ⟨hj, hk, heq⟩
    simp only at hj hk heq ⊢
    unfold documents_in_loop.body
    step*
    · have hc : ds.val.drop j.val = d :: ds.val.drop (j.val + 1) := by
        rw [d_post]; exact List.drop_eq_getElem_cons (by scalar_tac)
      have hlen := ds.len_ineq
      split
      · step*
        refine ⟨by scalar_tac, by scalar_tac, ?_, by scalar_tac⟩
        rw [heq, hc, List.filter_cons, i2_post]; grind
      · step*
        refine ⟨by scalar_tac, by scalar_tac, ?_, by scalar_tac⟩
        rw [heq, hc, List.filter_cons, i2_post]; grind
    · rw [heq, List.drop_eq_nil_of_le (by scalar_tac)]; simp
  · simp [hi, ho]

@[step]
theorem documents_in_spec (ds : alloc.vec.Vec Document) (p : U64) :
    documents_in ds p ⦃ v => v.val = ds.val.filter (fun d => d.project.val = p.val) ⦄ := by
  unfold documents_in
  step*
  simp_all

end docs_kernel.Lemmas
