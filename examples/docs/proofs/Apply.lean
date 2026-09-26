import Spec
/-! `apply` computes `Spec.applyAll`. -/
open Aeneas Aeneas.Std Result docs_kernel docs_kernel.Spec

namespace docs_kernel.ApplyLemmas

/-- No vector can overflow: each write adds at most one row. -/
def Room (s : Snapshot) (n : Nat) : Prop :=
  s.projects.length + s.members.length + s.documents.length + n < Usize.max

theorem vec_clone_eq {T : Type} (inst : core.clone.Clone T) (v : alloc.vec.Vec T)
    (h : ∀ x, inst.clone x = ok x) : alloc.vec.CloneVec.clone inst v = ok v := by
  have := Slice.clone_spec (clone := inst.clone) (s := v.slice) (fun x _ => h x)
  rw [WP.spec_equiv_exists] at this
  obtain ⟨s', hs, heq⟩ := this
  simp [alloc.vec.CloneVec.clone, hs, ← heq]

theorem u8vec_clone (v : alloc.vec.Vec U8) : alloc.vec.CloneVec.clone core.clone.CloneU8 v = ok v :=
  vec_clone_eq _ v (fun _ => rfl)

theorem project_clone (p : Project) : Project.Insts.CoreCloneClone.clone p = ok p := by
  simp [Project.Insts.CoreCloneClone.clone, u8vec_clone, lift]

theorem member_clone (m : Member) : Member.Insts.CoreCloneClone.clone m = ok m := by
  cases m; rename_i r; cases r <;> simp [Member.Insts.CoreCloneClone.clone, Role.Insts.CoreCloneClone.clone, lift]

theorem document_clone (d : Document) : Document.Insts.CoreCloneClone.clone d = ok d := by
  simp [Document.Insts.CoreCloneClone.clone, u8vec_clone]

theorem counter_clone (c : Counter) : Counter.Insts.CoreCloneClone.clone c = ok c := by
  simp [Counter.Insts.CoreCloneClone.clone, lift]

theorem write_clone (w : Write) : Write.Insts.CoreCloneClone.clone w = ok w := by
  cases w <;> simp [Write.Insts.CoreCloneClone.clone, project_clone, member_clone,
    document_clone, counter_clone, lift]

theorem snapshot_clone (s : Snapshot) : Snapshot.Insts.CoreCloneClone.clone s = ok s := by
  simp [Snapshot.Insts.CoreCloneClone.clone, counter_clone,
    vec_clone_eq Project.Insts.CoreCloneClone s.projects project_clone,
    vec_clone_eq Member.Insts.CoreCloneClone s.members member_clone,
    vec_clone_eq Document.Insts.CoreCloneClone s.documents document_clone]

@[step]
theorem member_clone_spec (m : Member) : Member.Insts.CoreCloneClone.clone m ⦃ m' => m' = m ⦄ := by
  rw [member_clone]; simp

@[step]
theorem document_clone_spec (d : Document) : Document.Insts.CoreCloneClone.clone d ⦃ d' => d' = d ⦄ := by
  rw [document_clone]; simp

theorem filter_take_succ {α} (P : α → Bool) (l : List α) (j : Nat) (hj : j < l.length) :
    (l.take (j + 1)).filter P = (l.take j).filter P ++ (if P l[j] then [l[j]] else []) := by
  rw [List.take_add_one, List.getElem?_eq_getElem hj]
  simp only [Option.toList_some, List.filter_append, List.filter_cons, List.filter_nil]

theorem upsert_step {α} (key : α → Nat × Nat) (x : α) (l : List α) (j : Nat) (hj : j < l.length) :
    l.take j ++ upsert key x (l.drop j) =
      if key l[j] = key x then l.take j ++ x :: l.drop (j + 1)
      else l.take (j + 1) ++ upsert key x (l.drop (j + 1)) := by
  rw [List.drop_eq_getElem_cons hj, upsert]
  split
  · rfl
  · rw [List.take_add_one, List.getElem?_eq_getElem hj, Option.toList_some, List.append_assoc]
    rfl

theorem upsert_end {α} (key : α → Nat × Nat) (x : α) (l : List α) (j : Nat) (hj : l.length ≤ j) :
    l.take j ++ upsert key x (l.drop j) = l ++ [x] := by
  simp [List.take_of_length_le hj, List.drop_eq_nil_of_le hj, upsert]

@[step]
theorem put_project_loop_spec (v : alloc.vec.Vec Project) (p : Project) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (fun q => (q.id.val, 0)) p v.val =
      v.val.take i.val ++ upsert (fun q => (q.id.val, 0)) p (v.val.drop i.val)) :
    put_project_loop v p i ⦃ v' => v'.val = upsert (fun q => (q.id.val, 0)) p v.val ⦄ := by
  unfold put_project_loop
  apply loop.spec_decr_nat (measure := fun (j : Usize) => v.length - j.val)
    (inv := fun j => j.val ≤ v.length ∧ upsert (fun q => (q.id.val, 0)) p v.val =
      v.val.take j.val ++ upsert (fun q => (q.id.val, 0)) p (v.val.drop j.val))
  · rintro j ⟨hj, heq⟩
    unfold put_project_loop.body
    step*
    · rw [index_mut_back_post, alloc.vec.Vec.set_val_eq, heq, upsert_step _ _ _ _ (by scalar_tac),
        if_pos (by simp_all), List.set_eq_take_append_cons_drop, if_pos (by scalar_tac)]
    · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
      rw [heq, upsert_step _ _ _ _ (by scalar_tac), if_neg (by simp_all), i2_post]
    · rw [v1_post, heq, upsert_end _ _ _ _ (by scalar_tac)]
  · exact ⟨hi, hpre⟩

@[step]
theorem put_member_loop_spec (v : alloc.vec.Vec Member) (m : Member) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (fun n => (n.project.val, n.user.val)) m v.val =
      v.val.take i.val ++ upsert (fun n => (n.project.val, n.user.val)) m (v.val.drop i.val)) :
    put_member_loop v m i ⦃ v' => v'.val = upsert (fun n => (n.project.val, n.user.val)) m v.val ⦄ := by
  unfold put_member_loop
  apply loop.spec_decr_nat (measure := fun (j : Usize) => v.length - j.val)
    (inv := fun j => j.val ≤ v.length ∧ upsert (fun n => (n.project.val, n.user.val)) m v.val =
      v.val.take j.val ++ upsert (fun n => (n.project.val, n.user.val)) m (v.val.drop j.val))
  · rintro j ⟨hj, heq⟩
    unfold put_member_loop.body
    step*
    · rw [index_mut_back_post, alloc.vec.Vec.set_val_eq, heq, upsert_step _ _ _ _ (by scalar_tac),
        if_pos (by simp_all), List.set_eq_take_append_cons_drop, if_pos (by scalar_tac)]
    · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
      rw [heq, upsert_step _ _ _ _ (by scalar_tac), if_neg (by simp_all), i2_post]
    · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
      rw [heq, upsert_step _ _ _ _ (by scalar_tac), if_neg (by simp_all), i2_post]
    · rw [v1_post, heq, upsert_end _ _ _ _ (by scalar_tac)]
  · exact ⟨hi, hpre⟩

@[step]
theorem put_document_loop_spec (v : alloc.vec.Vec Document) (d : Document) (i : Usize)
    (hi : i.val ≤ v.length) (hroom : v.length < Usize.max)
    (hpre : upsert (fun e => (e.id.val, 0)) d v.val =
      v.val.take i.val ++ upsert (fun e => (e.id.val, 0)) d (v.val.drop i.val)) :
    put_document_loop v d i ⦃ v' => v'.val = upsert (fun e => (e.id.val, 0)) d v.val ⦄ := by
  unfold put_document_loop
  apply loop.spec_decr_nat (measure := fun (j : Usize) => v.length - j.val)
    (inv := fun j => j.val ≤ v.length ∧ upsert (fun e => (e.id.val, 0)) d v.val =
      v.val.take j.val ++ upsert (fun e => (e.id.val, 0)) d (v.val.drop j.val))
  · rintro j ⟨hj, heq⟩
    unfold put_document_loop.body
    step*
    · rw [index_mut_back_post, alloc.vec.Vec.set_val_eq, heq, upsert_step _ _ _ _ (by scalar_tac),
        if_pos (by simp_all), List.set_eq_take_append_cons_drop, if_pos (by scalar_tac)]
    · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
      rw [heq, upsert_step _ _ _ _ (by scalar_tac), if_neg (by simp_all), i2_post]
    · rw [v1_post, heq, upsert_end _ _ _ _ (by scalar_tac)]
  · exact ⟨hi, hpre⟩

@[step]
theorem del_member_loop_spec (v : alloc.vec.Vec Member) (p u : U64) (out : alloc.vec.Vec Member)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun n => ¬(n.project = p ∧ n.user = u))) :
    del_member_loop v p u out i ⦃ v' => v'.val = v.val.filter (fun n => ¬(n.project = p ∧ n.user = u)) ⦄ := by
  unfold del_member_loop
  apply loop.spec_decr_nat (measure := fun (x : alloc.vec.Vec Member × Usize) => v.length - x.2.val)
    (inv := fun x => x.2.val ≤ v.length ∧
      x.1.val = (v.val.take x.2.val).filter (fun n => ¬(n.project = p ∧ n.user = u)))
  · rintro ⟨o, j⟩ ⟨hj, heq⟩
    simp only at hj heq ⊢
    have hlo : o.val.length ≤ j.val := by
      rw [heq]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)
    unfold del_member_loop.body
    step*
    · have : o.length < Usize.max := by scalar_tac
      split
      · split
        · step*
          refine ⟨by scalar_tac, ?_, by scalar_tac⟩
          rw [i2_post, filter_take_succ _ _ _ (by scalar_tac), heq]; simp_all
        · step*
          refine ⟨by scalar_tac, ?_, by scalar_tac⟩
          rw [i2_post, filter_take_succ _ _ _ (by scalar_tac), out1_post, heq]; simp_all
      · step*
        refine ⟨by scalar_tac, ?_, by scalar_tac⟩
        rw [i2_post, filter_take_succ _ _ _ (by scalar_tac), out1_post, heq]; simp_all
    · rw [heq, List.take_of_length_le (by scalar_tac)]
  · exact ⟨hi, hout⟩

@[step]
theorem del_document_loop_spec (v : alloc.vec.Vec Document) (id : U64) (out : alloc.vec.Vec Document)
    (i : Usize) (hi : i.val ≤ v.length)
    (hout : out.val = (v.val.take i.val).filter (fun e => e.id ≠ id)) :
    del_document_loop v id out i ⦃ v' => v'.val = v.val.filter (fun e => e.id ≠ id) ⦄ := by
  unfold del_document_loop
  apply loop.spec_decr_nat (measure := fun (x : alloc.vec.Vec Document × Usize) => v.length - x.2.val)
    (inv := fun x => x.2.val ≤ v.length ∧ x.1.val = (v.val.take x.2.val).filter (fun e => e.id ≠ id))
  · rintro ⟨o, j⟩ ⟨hj, heq⟩
    simp only at hj heq ⊢
    have hlo : o.val.length ≤ j.val := by
      rw [heq]; exact (List.length_filter_le _ _).trans (List.length_take_le _ _)
    unfold del_document_loop.body
    step*
    · have : o.length < Usize.max := by scalar_tac
      split
      · step*
        refine ⟨by scalar_tac, ?_, by scalar_tac⟩
        rw [i2_post, filter_take_succ _ _ _ (by scalar_tac), out1_post, heq]; simp_all
      · step*
        refine ⟨by scalar_tac, ?_, by scalar_tac⟩
        rw [i2_post, filter_take_succ _ _ _ (by scalar_tac), heq]; simp_all
    · rw [heq, List.take_of_length_le (by scalar_tac)]
  · exact ⟨hi, hout⟩

theorem upsert_length {α} (key : α → Nat × Nat) (x : α) (l : List α) :
    (upsert key x l).length ≤ l.length + 1 := by
  induction l with
  | nil => simp [upsert]
  | cons y ys ih => rw [upsert]; split <;> simp; omega

/-- Total rows in a snapshot. -/
def total (s : Snapshot) : Nat := s.projects.length + s.members.length + s.documents.length

@[step]
theorem apply_write_spec (s : Snapshot) (w : Write) (h : total s < Usize.max) :
    apply_write s w ⦃ s' => Snapshot.toSt s' = applyWrite (Snapshot.toSt s) w ∧ total s' ≤ total s + 1 ⦄ := by
  unfold total at h
  unfold apply_write
  cases w <;> step*
  all_goals first
    | refine ⟨by simp [Snapshot.toSt, applyWrite, *], ?_⟩
      simp only [total, alloc.vec.Vec.length, *]
      first
        | omega
        | (have := upsert_length (fun q : Project => (q.id.val, 0)) ‹_› s.projects.val; omega)
        | (have := upsert_length (fun n : Member => (n.project.val, n.user.val)) ‹_› s.members.val; omega)
        | (have := upsert_length (fun e : Document => (e.id.val, 0)) ‹_› s.documents.val; omega)
        | grind [List.length_filter_le]
    | simp

@[step]
theorem write_clone_spec (w : Write) : Write.Insts.CoreCloneClone.clone w ⦃ w' => w' = w ⦄ := by
  rw [write_clone]; simp

@[step]
theorem snapshot_clone_spec (s : Snapshot) : Snapshot.Insts.CoreCloneClone.clone s ⦃ s' => s' = s ⦄ := by
  rw [snapshot_clone]; simp

theorem applyAll_take_succ (s : St) (l : List Write) (j : Nat) (hj : j < l.length) :
    applyAll s (l.take (j + 1)) = applyWrite (applyAll s (l.take j)) l[j] := by
  rw [List.take_add_one, List.getElem?_eq_getElem hj]
  simp only [applyAll, List.foldl_append, Option.toList_some, List.foldl_cons, List.foldl_nil]

@[step]
theorem apply_loop_spec (ws : alloc.vec.Vec Write) (s₀ s : Snapshot) (i : Usize)
    (hi : i.val ≤ ws.length)
    (hs : Snapshot.toSt s = applyAll (Snapshot.toSt s₀) (ws.val.take i.val))
    (hroom : total s + (ws.length - i.val) < Usize.max) :
    apply_loop ws s i ⦃ s' => Snapshot.toSt s' = applyAll (Snapshot.toSt s₀) ws.val ⦄ := by
  unfold apply_loop
  apply loop.spec_decr_nat (measure := fun (x : Snapshot × Usize) => ws.length - x.2.val)
    (inv := fun x => x.2.val ≤ ws.length ∧
      Snapshot.toSt x.1 = applyAll (Snapshot.toSt s₀) (ws.val.take x.2.val) ∧
      total x.1 + (ws.length - x.2.val) < Usize.max)
  · rintro ⟨t, j⟩ ⟨hj, heq, hr⟩
    simp only at hj heq hr ⊢
    unfold apply_loop.body
    step*
    · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
      rw [i2_post, applyAll_take_succ _ _ _ (by scalar_tac), ← heq, ‹Snapshot.toSt s1 = _›, w1_post, w_post]
    · rw [heq, List.take_of_length_le (by scalar_tac)]
  · exact ⟨hi, hs, hroom⟩

@[step]
theorem apply_spec (s : Snapshot) (ws : alloc.vec.Vec Write) (h : Room s ws.length) :
    apply s ws ⦃ s' => Snapshot.toSt s' = applyAll (Snapshot.toSt s) ws.val ⦄ := by
  unfold apply
  rw [snapshot_clone]
  simp only [bind_ok]
  exact apply_loop_spec ws s s 0#usize (by simp) (by simp [applyAll])
    (by simp only [Room] at h; simp only [total]; scalar_tac)

end docs_kernel.ApplyLemmas
