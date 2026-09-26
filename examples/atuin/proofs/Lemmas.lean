import Spec
/-! Each extracted helper computes its list counterpart. Loops use `I5hLib`. -/
open Aeneas Aeneas.Std Result atuin_kernel atuin_kernel.Spec I5hLib

namespace atuin_kernel.Lemmas

/-- Alphanumeric or hyphen. -/
def byteOK (n : Nat) : Bool :=
  decide ((97 ≤ n ∧ n ≤ 122) ∨ (65 ≤ n ∧ n ≤ 90) ∨ (48 ≤ n ∧ n ≤ 57) ∨ n = 45)

theorem u8_eq_iff (x y : U8) : x = y ↔ x.val = y.val :=
  ⟨fun h => h ▸ rfl, fun h => by scalar_tac⟩

@[step]
theorem byte_ok_spec (c : U8) : byte_ok c ⦃ b => b = byteOK c.val ⦄ := by
  unfold byte_ok byteOK
  step*
  all_goals (simp only [u8_eq_iff, UScalar.ofNatCore_val_eq] at *; simp_all; try omega)

theorem search_bool {α} (l : List α) (P : α → Bool) (b c : Bool) (r : Bool)
    (hr : r = searchFrom l P (fun _ _ => b) c (↑(0#usize : Usize))) : r = if l.any P then b else c := by
  rw [hr, searchFrom_const, UScalar.ofNatCore_val_eq, List.drop_zero]

@[step]
theorem username_ok_spec (nm : alloc.vec.Vec U8) :
    username_ok nm ⦃ b => b = !(nm.val.any (fun c => !byteOK c.val)) ⦄ := by
  unfold username_ok username_ok_loop
  apply WP.spec_mono (loop_search nm.val (fun c => !byteOK c.val) id (fun _ _ => false) true _ ?_
    0#usize (by simp))
  · intro r hr; simp only [id] at hr; rw [search_bool _ _ _ _ _ hr]; split <;> simp_all
  · intro j hj; unfold username_ok_loop.body; i5h_step

theorem allM_u8 (l : List (U8 × U8)) :
    List.allM (fun (p : U8 × U8) => core.cmp.PartialEqU8.eq p.1 p.2) l =
      ok (l.all (fun p => decide (p.1 = p.2))) := by
  induction l with
  | nil => rfl
  | cons p ps ih =>
    by_cases h : p.1 = p.2 <;> simp [List.allM, liftFun2, h, ih] <;> rfl

theorem zip_all_eq (a b : List U8) (h : a.length = b.length) :
    (List.zip a b).all (fun p => decide (p.1 = p.2)) = decide (a = b) := by
  induction a generalizing b with
  | nil => cases b <;> simp_all
  | cons x xs ih =>
    cases b with
    | nil => simp at h
    | cons y ys =>
      simp only [List.length_cons, Nat.add_right_cancel_iff] at h
      simp [List.zip_cons_cons, ih ys h]

@[step]
theorem vec_u8_eq_spec (v w : alloc.vec.Vec U8) :
    alloc.vec.partial_eq.PartialEqVec.eq core.cmp.PartialEqU8 v w ⦃ b => b = decide (v.val = w.val) ⦄ := by
  unfold alloc.vec.partial_eq.PartialEqVec.eq
  split
  · rename_i hlen
    rw [show (fun (x : U8 × U8) => match x with | (x0, x1) => core.cmp.PartialEqU8.eq x0 x1) =
        (fun p => core.cmp.PartialEqU8.eq p.1 p.2) from rfl, allM_u8]
    simp only [WP.spec_ok]
    exact zip_all_eq _ _ hlen
  · rename_i hlen
    simp only [WP.spec_ok]
    have : v.val ≠ w.val := fun h => hlen (by simp [alloc.vec.Vec.length, h])
    simp [this]

@[step]
theorem username_taken_spec (us : alloc.vec.Vec User) (nm : alloc.vec.Vec U8) :
    username_taken us nm ⦃ b => b = us.val.any (fun u => decide (u.username.val = nm.val)) ⦄ := by
  unfold username_taken username_taken_loop
  apply WP.spec_mono (loop_search us.val (fun u => decide (u.username.val = nm.val)) id (fun _ _ => true) false _ ?_
    0#usize (by simp))
  · intro r hr; simp only [id] at hr; rw [search_bool _ _ _ _ _ hr]; split <;> simp_all
  · intro j hj; unfold username_taken_loop.body; i5h_step

@[step]
theorem user_exists_spec (us : alloc.vec.Vec User) (k : U64) :
    user_exists us k ⦃ b => b = us.val.any (fun u => decide (u.id = k)) ⦄ := by
  unfold user_exists user_exists_loop
  apply WP.spec_mono (loop_search us.val (fun u => decide (u.id = k)) id (fun _ _ => true) false _ ?_
    0#usize (by simp))
  · intro r hr; simp only [id] at hr; rw [search_bool _ _ _ _ _ hr]; split <;> simp_all
  · intro j hj; unfold user_exists_loop.body; i5h_step

theorem u8vec_clone (v : alloc.vec.Vec U8) : alloc.vec.CloneVec.clone core.clone.CloneU8 v = ok v :=
  vec_clone_eq _ v (fun _ => rfl)

@[step]
theorem u8vec_clone_spec (v : alloc.vec.Vec U8) :
    alloc.vec.CloneVec.clone core.clone.CloneU8 v ⦃ v' => v' = v ⦄ := by
  rw [u8vec_clone]; simp

theorem user_clone (u : User) : User.Insts.CoreCloneClone.clone u = ok u := by
  simp [User.Insts.CoreCloneClone.clone, u8vec_clone, lift]

theorem record_clone (r : Record) : Record.Insts.CoreCloneClone.clone r = ok r := by
  simp [Record.Insts.CoreCloneClone.clone, u8vec_clone, lift]

@[step]
theorem user_clone_spec (u : User) : User.Insts.CoreCloneClone.clone u ⦃ u' => u' = u ⦄ := by
  rw [user_clone]; simp

@[step]
theorem record_clone_spec (r : Record) : Record.Insts.CoreCloneClone.clone r ⦃ r' => r' = r ⦄ := by
  rw [record_clone]; simp

@[step]
theorem find_user_spec (us : alloc.vec.Vec User) (k : U64) :
    find_user us k ⦃ r => r = us.val.find? (fun u => decide (u.id = k)) ⦄ := by
  unfold find_user find_user_loop
  apply WP.spec_mono (loop_search us.val (fun u => decide (u.id = k)) id (fun _ u => some u) none _ ?_
    0#usize (by simp))
  · intro r hr; simp only [id] at hr
    rw [hr, show (fun (_ : Nat) (u : User) => some u) = (fun _ x => some (id x)) from rfl, searchFrom_find]
    simp
  · intro j hj; unfold find_user_loop.body; i5h_step

/-- The size cap check; 0 means no cap. -/
def fitsB (max : Nat) (r : NewRecord) : Bool := decide (max = 0 ∨ r.data.length ≤ max)

@[step]
theorem fits_spec (max : U64) (r : NewRecord) : fits max r ⦃ b => b = fitsB max.val r ⦄ := by
  unfold fits fitsB
  have := r.data.len_ineq; have := usize_max_le
  step*
  all_goals (simp_all; try scalar_tac)

@[step]
theorem all_fit_spec (max : U64) (rs : alloc.vec.Vec NewRecord) :
    all_fit max rs ⦃ b => b = !(rs.val.any (fun r => !fitsB max.val r)) ⦄ := by
  unfold all_fit all_fit_loop
  apply WP.spec_mono (loop_search rs.val (fun r => !fitsB max.val r) id (fun _ _ => false) true _ ?_
    0#usize (by simp))
  · intro r hr; simp only [id] at hr; rw [search_bool _ _ _ _ _ hr]; split <;> simp_all
  · intro j hj; unfold all_fit_loop.body; i5h_step

theorem foldl_filter_map {α β} (P : α → Bool) (f : α → β) (l : List α) (acc : List β) :
    l.foldl (fun acc x => if P x then acc ++ [f x] else acc) acc = acc ++ (l.filter P).map f := by
  induction l generalizing acc with
  | nil => simp
  | cons x xs ih => by_cases h : P x <;> simp [h, ih]

theorem foldl_map {α β} (f : α → β) (l : List α) (acc : List β) :
    l.foldl (fun acc x => acc ++ [f x]) acc = acc ++ l.map f := by
  induction l generalizing acc with
  | nil => simp
  | cons x xs ih => simp [ih]

/-- `Status`: (host, tag, idx) of each of the user's records. -/
def statusL (rs : List Record) (u : U64) : List (U64 × U64 × U64) :=
  (rs.filter (fun r => decide (r.user = u))).map (fun r => (r.host, r.tag, r.idx))

@[step]
theorem status_of_spec (rs : alloc.vec.Vec Record) (u : U64) :
    status_of rs u ⦃ v => v.val = statusL rs.val u ⦄ := by
  unfold status_of status_of_loop
  apply WP.spec_mono (loop_fold rs.val (fun v : alloc.vec.Vec (U64 × U64 × U64) => v.val)
    (fun acc r => if decide (r.user = u) then acc ++ [(r.host, r.tag, r.idx)] else acc)
    (fun v k => v.length ≤ k) (fun x => status_of_loop.body rs u x.1 x.2) ?_ _ 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, foldl_filter_map]; simp [statusL]
  · intro o j hj ho; have := rs.len_ineq; unfold status_of_loop.body; i5h_step

/-- `AddRecords`: one put per new record, owned by the caller. -/
def toWritesL (u : U64) (rs : List NewRecord) : List Write :=
  rs.map (fun r => .PutRecord { user := u, host := r.host, tag := r.tag, idx := r.idx, data := r.data })

@[step]
theorem to_writes_spec (u : U64) (rs : alloc.vec.Vec NewRecord) :
    to_writes u rs ⦃ v => v.val = toWritesL u rs.val ⦄ := by
  unfold to_writes to_writes_loop
  apply WP.spec_mono (loop_fold rs.val (fun v : alloc.vec.Vec Write => v.val)
    (fun acc r => acc ++ [.PutRecord { user := u, host := r.host, tag := r.tag, idx := r.idx, data := r.data }])
    (fun v k => v.length ≤ k) (fun x => to_writes_loop.body u rs x.1 x.2) ?_ _ 0#usize (by simp) (by simp))
  · intro r hr; rw [hr, foldl_map]; simp [toWritesL]
  · intro o j hj ho; have := rs.len_ineq; unfold to_writes_loop.body; i5h_step

/-- `NextRecords`: the caller's records of one series from `start`, at most `count`. -/
def nextL (rs : List Record) (u h t start count : U64) : List Record :=
  rs.foldl (fun acc r =>
    if decide (r.user = u ∧ r.host = h ∧ r.tag = t ∧ start.val ≤ r.idx.val) && decide (acc.length < count.val)
    then acc ++ [r] else acc) []

@[step]
theorem next_records_spec (rs : alloc.vec.Vec Record) (u h t start count : U64) :
    next_records rs u h t start count ⦃ v => v.val = nextL rs.val u h t start count ⦄ := by
  unfold next_records next_records_loop
  apply WP.spec_mono (loop_fold rs.val (fun v : alloc.vec.Vec Record => v.val)
    (fun acc r =>
      if decide (r.user = u ∧ r.host = h ∧ r.tag = t ∧ start.val ≤ r.idx.val) && decide (acc.length < count.val)
      then acc ++ [r] else acc)
    (fun v k => v.length ≤ k) (fun x => next_records_loop.body rs u h t start count x.1 x.2) ?_ _ 0#usize
    (by simp) (by simp))
  · intro r hr; rw [hr]; rfl
  · intro o j hj ho; have := rs.len_ineq; have := usize_max_le
    unfold next_records_loop.body; i5h_step

@[step]
theorem signed_in_spec (s : Snapshot) (a : Principal) :
    signed_in s a ⦃ r => r.map (·.val) = signedIn (Snapshot.toSt s) a ⦄ := by
  unfold signed_in
  cases a <;> step* <;> simp_all [signedIn, Snapshot.toSt]

end atuin_kernel.Lemmas
