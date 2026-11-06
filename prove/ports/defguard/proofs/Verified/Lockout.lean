import Spec
/-!
# The failed-login tracker and the login gate
-/
open Aeneas Aeneas.Std Result defguard_kernel defguard_kernel.Spec
open H5iAppLib

namespace defguard_kernel.Verified

h5i_derive_all

theorem getElem!_of_lt {a : List U8} {k : Nat} (h : k < a.length) : a[k]! = a[k] := by
  rw [List.getElem!_eq_getElem?_getD, List.getElem?_eq_getElem h]; rfl

theorem list_eq_of_getElem! {a b : List U8} (hl : a.length = b.length)
    (hk : ∀ k < a.length, a[k]! = b[k]!) : a = b := by
  apply List.ext_getElem hl
  intro n h1 h2
  have := hk n h1
  rw [getElem!_of_lt h1, getElem!_of_lt h2] at this
  exact this

@[simp] theorem vec_deref_val {T : Type} (v : alloc.vec.Vec T) : (alloc.vec.Vec.deref v).val = v.val := by
  simp [alloc.vec.Vec.deref]

@[step] theorem bytes_eq_spec (a b : Slice U8) :
    util.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold util.bytes_eq; simp only []
  split
  · simp only [WP.spec_ok]
    have : a.val ≠ b.val := fun h => by simp_all
    simp [this]
  · unfold util.bytes_eq_loop
    apply loop.spec_decr_nat (measure := fun (j : Usize) => a.length - j.val)
      (inv := fun j => j.val ≤ a.length ∧ ∀ k < j.val, a.val[k]! = b.val[k]!)
    · rintro j ⟨hj, hk⟩
      unfold util.bytes_eq_loop.body; simp only []
      step*
      · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
        intro k hk'
        rcases Nat.lt_succ_iff_lt_or_eq.1 (show k < j.val + 1 by scalar_tac) with h1 | h1
        · exact hk k h1
        · subst h1
          rw [getElem!_of_lt (by scalar_tac), getElem!_of_lt (by scalar_tac)]
          apply UScalar.eq_of_val_eq
          simp_all
      · have : a.val = b.val := list_eq_of_getElem! (by scalar_tac) (fun k hk' => hk k (by scalar_tac))
        simp [this]
    · simp

@[step] theorem find_entry_spec (map : alloc.vec.Vec lockout.FailedLogin) (k : Slice U8) :
    lockout.find_entry map k ⦃ o => o.map (·.val) = map.val.findIdx? (fun f => decide (f.key.val = k.val)) ⦄ := by
  unfold lockout.find_entry lockout.find_entry_loop
  apply WP.spec_mono (H5iAppLib.loop_search map.val (fun f => decide (f.key.val = k.val)) (fun r => r.map (·.val))
    (fun i _ => some i) none _ ?step 0#usize (by simp))
  · intro r hr; rw [hr, H5iAppLib.searchFrom_findIdx]; simp
  case step =>
    intro j hj; unfold lockout.find_entry_loop.body; h5i_step

theorem isub_ok_val {ty} {x y z : IScalar ty} (h : x - y = ok z) : z.val = x.val - y.val := by
  have := IScalar.sub_equiv x y; rw [h] at this; simp at this; omega

theorem should_prevent_ok {f : lockout.FailedLogin} {now : I64} {b : Bool}
    (h : lockout.should_prevent_login f now = ok b) :
    b = decide (5 ≤ f.attempt_count.val ∧ now.val - f.last_attempt.val ≤ 300000000000) := by
  unfold lockout.should_prevent_login at h
  h5i_invert h
  all_goals (try have := isub_ok_val hi)
  all_goals (simp_all [lockout.COUNT, lockout.TIMEOUT_NS]; try omega)

theorem should_reset_ok {f : lockout.FailedLogin} {now : I64} {b : Bool}
    (h : lockout.should_reset_counter f now = ok b) :
    b = decide ((now.val - f.first_attempt.val > 60000000000 ∧ f.attempt_count.val < 5) ∨
      now.val - f.last_attempt.val > 300000000000) := by
  unfold lockout.should_reset_counter at h
  h5i_invert h
  all_goals (try have := isub_ok_val hi)
  all_goals (try have := isub_ok_val hi1)
  all_goals (simp_all [lockout.COUNT, lockout.TIMEOUT_NS, lockout.WINDOW_NS]; try omega)

/-! ## Lists -/

theorem find_set_first {α : Type} (p : α → Bool) (l : List α) (i : Nat) (f : α)
    (hi : l.findIdx? p = some i) (hf : p f = true) : (l.set i f).find? p = some f := by
  induction l generalizing i with
  | nil => simp at hi
  | cons x xs ih =>
    by_cases hx : p x
    · simp [List.findIdx?_cons, hx] at hi; subst hi; simp [hf]
    · simp [List.findIdx?_cons, hx] at hi
      obtain ⟨j, hj, rfl⟩ := hi
      simp [hx, ih j hj]

theorem find_set_other {α : Type} (p q : α → Bool) (l : List α) (i : Nat) (f : α)
    (hi : l.findIdx? p = some i) (hq : ∀ x, p x = true → q x = false) (hf : q f = false) :
    (l.set i f).find? q = l.find? q := by
  induction l generalizing i with
  | nil => simp at hi
  | cons x xs ih =>
    by_cases hx : p x
    · simp [List.findIdx?_cons, hx] at hi; subst hi; simp [hf, hq x hx]
    · simp [List.findIdx?_cons, hx] at hi
      obtain ⟨j, hj, rfl⟩ := hi
      by_cases hqx : q x <;> simp [hqx, ih j hj]

theorem find_of_findIdx {α : Type} (p : α → Bool) (l : List α) (i : Nat) (hi : l.findIdx? p = some i) :
    ∃ h : i < l.length, l.find? p = some l[i] := by
  obtain ⟨hl, hidx⟩ := List.findIdx?_eq_some_iff_findIdx_eq.1 hi
  refine ⟨hl, ?_⟩
  rw [List.find?_eq_getElem?_findIdx, hidx, List.getElem?_eq_getElem hl]

/-! ## Kernel helpers -/

theorem vclone_eq {T : Type} (inst : core.clone.Clone T) (hc : ∀ x, inst.clone x = ok x)
    {a b : alloc.vec.Vec T} (h : alloc.vec.CloneVec.clone inst a = ok b) : b = a := by
  rw [H5iAppLib.vec_clone_ok inst a hc] at h; exact (H5iAppLib.Result.ok.inj h).symm

theorem map_clone_eq {a b : alloc.vec.Vec lockout.FailedLogin}
    (h : alloc.vec.CloneVec.clone lockout.FailedLogin.Insts.CoreCloneClone a = ok b) : b = a :=
  vclone_eq _ lockout.FailedLogin.Insts.CoreCloneClone.clone.ok_eq h

theorem push_ok_val {α : Type} {v : alloc.vec.Vec α} {x : α} {w : alloc.vec.Vec α}
    (h : v.push x = ok w) : w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  simp only [] at h
  split at h
  · have := H5iAppLib.Result.ok.inj h
    subst this; simp
  · simp at h

theorem set_entry_ok {map m : alloc.vec.Vec lockout.FailedLogin} {i : Usize} {f : lockout.FailedLogin}
    (h : lockout.set_entry map i f = ok m) : m.val = map.val.set i.val f := by
  unfold lockout.set_entry at h
  h5i_invert h
  · obtain rfl := map_clone_eq hres
    obtain ⟨a, back⟩ := x
    try simp only [] at h
    rw [alloc.vec.Vec.index_mut_slice_index] at hx
    unfold alloc.vec.Vec.index_mut_usize at hx
    obtain ⟨y, hy, hx'⟩ := H5iAppLib.bind_tc_eq_ok.1 hx
    have e1 := H5iAppLib.Result.ok.inj hx'
    have e2 := H5iAppLib.Result.ok.inj h
    simp only [Prod.mk.injEq] at e1
    obtain ⟨_, rfl⟩ := e1
    subst e2
    simp
  · obtain rfl := map_clone_eq hres
    rw [List.set_eq_of_length_le]; scalar_tac

theorem fresh_spec (key : Slice U8) (now : I64) :
    lockout.fresh key now ⦃ f => f.key.val = key.val ∧ f.attempt_count = 1#u32 ∧
      f.first_attempt = now ∧ f.last_attempt = now ⦄ := by
  unfold lockout.fresh lockout.fresh_loop
  apply WP.spec_bind (H5iAppLib.loop_fold key.val (fun (o : alloc.vec.Vec U8) => o.val) (fun acc x => acc ++ [x])
    (fun o i => o.val.length ≤ i) _ ?step (alloc.vec.Vec.new U8) 0#usize (by simp) (by simp))
  · intro r hr; rw [H5iAppLib.foldl_snoc] at hr; simp_all
  case step =>
    intro o j hj hinv; unfold lockout.fresh_loop.body; h5i_step

theorem incremented_ok {f f' : lockout.FailedLogin} {now : I64} (h : lockout.incremented f now = ok f') :
    f'.key = f.key ∧ f'.attempt_count = core.num.U32.wrapping_add f.attempt_count 1#u32 ∧
      f'.first_attempt = f.first_attempt ∧ f'.last_attempt = now := by
  unfold lockout.incremented at h
  rw [H5iAppLib.u8vec_clone] at h
  simp only [lift, bind_ok] at h
  have := (H5iAppLib.Result.ok.inj h).symm
  subst this
  exact ⟨rfl, rfl, rfl, rfl⟩

theorem vec_index_eq {α : Type} (v : alloc.vec.Vec α) (i : Usize) (h : i.val < v.val.length) :
    alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice α) v i = ok v.val[i.val] := by
  rw [alloc.vec.Vec.index_slice_index]
  simp only [alloc.vec.Vec.index_usize]
  rw [show v[i.val]? = some v.val[i.val] by simp [h]]

theorem entry_of_idx {map : alloc.vec.Vec lockout.FailedLogin} {k : Slice U8} {o : Option Usize}
    (ho : o.map (·.val) = map.val.findIdx? (fun f => decide (f.key.val = k.val))) :
    match o with
    | none => entryFor map.val k.val = none
    | some i => ∃ h : i.val < map.val.length, entryFor map.val k.val = some map.val[i.val] ∧
        map.val.findIdx? (fun f => decide (f.key.val = k.val)) = some i.val := by
  cases o with
  | none =>
    simp only [Option.map_none] at ho
    simp only [entryFor]; rw [List.find?_eq_none]; intro x hx
    have := List.findIdx?_eq_none_iff.1 ho.symm x hx; simpa using this
  | some i =>
    simp only [Option.map_some] at ho
    obtain ⟨hl, hf⟩ := find_of_findIdx _ _ _ ho.symm
    exact ⟨hl, hf, ho.symm⟩

/-- `verify_username`: a name with no entry, or one not locked out, passes
and leaves the tracker as it was; a locked-out name is refused. -/
theorem verify_username_ok {map m : alloc.vec.Vec lockout.FailedLogin} {k : Slice U8} {now : I64} {b : Bool}
    (h : lockout.verify_username map k now = ok (m, b)) :
    (b = true ↔ Locked map.val k.val now.val) ∧ (b = false → m = map) := by
  unfold lockout.verify_username at h
  h5i_invert h
  · -- no entry
    have h' := post_of_ok (find_entry_spec map k) ho
    have he := entry_of_idx h'
    simp only [] at he
    obtain ⟨rfl, rfl⟩ := h
    refine ⟨?_, fun _ => map_clone_eq hv⟩
    simp only [Bool.false_eq_true, false_iff]
    rintro ⟨f, hf, _⟩; rw [he] at hf; cases hf
  all_goals
    obtain ⟨rfl, rfl⟩ := h
    have h' := post_of_ok (find_entry_spec map k) ho
    obtain ⟨hl, he, _⟩ := entry_of_idx h'
    have hfl' : fl = map.val[i.val] := by
      rw [vec_index_eq _ _ hl] at hfl; exact (H5iAppLib.Result.ok.inj hfl).symm
    subst hfl'
    have hb := should_prevent_ok hb_1
  · refine ⟨?_, fun h => by cases h⟩
    simp only [true_iff]
    exact ⟨_, he, by simp_all⟩
  · refine ⟨?_, fun _ => map_clone_eq hv⟩
    simp only [Bool.false_eq_true, false_iff]
    rintro ⟨f, hf, h5, ht⟩
    rw [he] at hf; cases hf
    simp_all

/-- The reset condition of `should_reset_counter`, on integers. -/
def ResetCond (f : lockout.FailedLogin) (now : Int) : Prop :=
  (now - f.first_attempt.val > 60000000000 ∧ f.attempt_count.val < 5) ∨ now - f.last_attempt.val > 300000000000

/-- `log_failed_attempt`: the entries of other names are untouched; the
name's entry is new or reset (one attempt, now), or one attempt more. -/
theorem log_failed_attempt_ok {map m : alloc.vec.Vec lockout.FailedLogin} {k : Slice U8} {now : I64}
    (h : lockout.log_failed_attempt map k now = ok m) :
    (∀ k', k' ≠ k.val → entryFor m.val k' = entryFor map.val k') ∧
    ∃ f', entryFor m.val k.val = some f' ∧ f'.last_attempt = now ∧
      (match entryFor map.val k.val with
       | none => f'.attempt_count = 1#u32 ∧ f'.first_attempt = now
       | some f => (ResetCond f now.val → f'.attempt_count = 1#u32 ∧ f'.first_attempt = now) ∧
           (¬ ResetCond f now.val → f'.attempt_count = core.num.U32.wrapping_add f.attempt_count 1#u32 ∧
             f'.first_attempt = f.first_attempt)) := by
  unfold lockout.log_failed_attempt at h
  h5i_invert h
  · -- a new entry
    have h' := post_of_ok (find_entry_spec map k) ho
    have he := entry_of_idx h'
    simp only [] at he
    obtain rfl := map_clone_eq hres
    have hf := post_of_ok (fresh_spec k now) hfl
    have hm := push_ok_val h
    refine ⟨?_, fl, ?_, hf.2.2.2, ?_⟩
    · intro k' hk'
      simp only [entryFor, hm, List.find?_append]
      have : [fl].find? (fun f => decide (f.key.val = k')) = none := by
        simp [hf.1]; exact fun e => hk' e.symm
      rw [this]; simp
    · simp only [entryFor] at he ⊢
      simp only [hm, List.find?_append, he]; simp; exact hf.1
    · rw [he]; exact ⟨hf.2.1, hf.2.2.1⟩
  all_goals
    have h' := post_of_ok (find_entry_spec map k) ho
    obtain ⟨hl, he, hidx⟩ := entry_of_idx h'
    have hfl' : fl = map.val[i.val] := by
      rw [vec_index_eq _ _ hl] at hfl; exact (H5iAppLib.Result.ok.inj hfl).symm
    subst hfl'
    have hr := should_reset_ok hb
    have hm := set_entry_ok h
    have hkey : map.val[i.val].key.val = k.val := by
      have := List.find?_some he; simpa using this
  · -- reset
    have hf := post_of_ok (fresh_spec k now) hfl1
    refine ⟨?_, fl1, ?_, hf.2.2.2, ?_⟩
    · intro k' hk'
      simp only [entryFor, hm]
      exact find_set_other _ _ _ _ _ hidx (fun x hx => by simp at hx ⊢; rw [hx]; exact fun e => hk' e.symm)
        (by simp [hf.1]; exact fun e => hk' e.symm)
    · simp only [entryFor, hm]
      exact find_set_first _ _ _ _ hidx (by simp [hf.1])
    · rw [he]
      refine ⟨fun _ => ⟨hf.2.1, hf.2.2.1⟩, fun hn => ?_⟩
      exfalso; apply hn; unfold ResetCond; simp_all
  · -- one more attempt
    have hf := incremented_ok hfl1
    refine ⟨?_, fl1, ?_, hf.2.2.2, ?_⟩
    · intro k' hk'
      simp only [entryFor, hm]
      exact find_set_other _ _ _ _ _ hidx (fun x hx => by simp at hx ⊢; rw [hx]; exact fun e => hk' e.symm)
        (by simp [hf.1, hkey]; exact fun e => hk' e.symm)
    · simp only [entryFor, hm]
      exact find_set_first _ _ _ _ hidx (by simp [hf.1, hkey])
    · rw [he]
      refine ⟨fun hy => ?_, fun _ => ⟨hf.2.1, hf.2.2.1⟩⟩
      exfalso; unfold ResetCond at hy; simp_all

/-! ## Account lookup -/

@[step] theorem lower_spec (b : U8) : lockout.lower b ⦃ r => r.val = lowerN b.val ⦄ := by
  unfold lockout.lower lowerN
  step*
  all_goals (simp_all; try scalar_tac)

instance (a b : List U8) : Decidable (LowerEq a b) := by unfold LowerEq; infer_instance

theorem lowerEq_iff (a b : List U8) :
    LowerEq a b ↔ a.length = b.length ∧ ∀ k < a.length, lowerN a[k]!.val = lowerN b[k]!.val := by
  unfold LowerEq
  constructor
  · intro h
    have hl : a.length = b.length := by simpa using congrArg List.length h
    refine ⟨hl, fun k hk => ?_⟩
    have := congrArg (fun l => l[k]?) h
    simp only [List.getElem?_map, List.getElem?_eq_getElem hk, List.getElem?_eq_getElem (show k < b.length by omega),
      Option.map_some, Option.some.injEq] at this
    rw [getElem!_of_lt hk, getElem!_of_lt (by omega)]
    exact this
  · rintro ⟨hl, hk⟩
    apply List.ext_getElem (by simpa using hl)
    intro n h1 h2
    have := hk n (by simpa using h1)
    simp only [List.getElem_map]
    rw [getElem!_of_lt (by simpa using h1), getElem!_of_lt (by simpa using h2)] at this
    exact this

@[step] theorem eq_lower_spec (a b : Slice U8) :
    lockout.eq_lower a b ⦃ r => r = decide (LowerEq a.val b.val) ⦄ := by
  unfold lockout.eq_lower; simp only []
  split
  · simp only [WP.spec_ok]
    have : ¬ LowerEq a.val b.val := fun h => by
      have := ((lowerEq_iff _ _).1 h).1; simp_all
    simp [this]
  · unfold lockout.eq_lower_loop
    apply loop.spec_decr_nat (measure := fun (j : Usize) => a.length - j.val)
      (inv := fun j => j.val ≤ a.length ∧ ∀ k < j.val, lowerN a.val[k]!.val = lowerN b.val[k]!.val)
    · rintro j ⟨hj, hk⟩
      unfold lockout.eq_lower_loop.body; simp only []
      step*
      · have : ¬ LowerEq a.val b.val := by
          intro h
          have h2 := ((lowerEq_iff _ _).1 h).2 j.val (by scalar_tac)
          rw [getElem!_of_lt (by scalar_tac), getElem!_of_lt (by scalar_tac)] at h2
          have : i3 = i5 := UScalar.eq_of_val_eq (by simp_all)
          simp_all
        simp [this]
      · refine ⟨by scalar_tac, ?_, by scalar_tac⟩
        intro k hk'
        rcases Nat.lt_succ_iff_lt_or_eq.1 (show k < j.val + 1 by scalar_tac) with h1 | h1
        · exact hk k h1
        · subst h1
          rw [getElem!_of_lt (by scalar_tac), getElem!_of_lt (by scalar_tac)]
          simp_all
      · have : LowerEq a.val b.val := (lowerEq_iff _ _).2 ⟨by scalar_tac, fun k hk' => hk k (by scalar_tac)⟩
        simp [this]
    · simp

@[step] theorem find_by_username_spec (us : alloc.vec.Vec lockout.Account) (n : Slice U8) :
    lockout.find_by_username us n ⦃ o => o.map (·.val) = us.val.findIdx? (fun a => decide (a.username.val = n.val)) ⦄ := by
  unfold lockout.find_by_username lockout.find_by_username_loop
  apply WP.spec_mono (H5iAppLib.loop_search us.val (fun a => decide (a.username.val = n.val)) (fun r => r.map (·.val))
    (fun i _ => some i) none _ ?step 0#usize (by simp))
  · intro r hr; rw [hr, H5iAppLib.searchFrom_findIdx]; simp
  case step =>
    intro j hj; unfold lockout.find_by_username_loop.body; h5i_step

@[step] theorem find_by_email_spec (us : alloc.vec.Vec lockout.Account) (e : Slice U8) :
    lockout.find_by_email us e ⦃ o => o.map (·.val) = us.val.findIdx? (fun a => decide (LowerEq a.email.val e.val)) ⦄ := by
  unfold lockout.find_by_email lockout.find_by_email_loop
  apply WP.spec_mono (H5iAppLib.loop_search us.val (fun a => decide (LowerEq a.email.val e.val)) (fun r => r.map (·.val))
    (fun i _ => some i) none _ ?step 0#usize (by simp))
  · intro r hr; rw [hr, H5iAppLib.searchFrom_findIdx]; simp
  case step =>
    intro j hj; unfold lockout.find_by_email_loop.body; h5i_step

/-- `find_by_username_or_email`: an exact username match, else (only if no
username matches) a case-insensitive email match. -/
theorem find_account_ok {us : alloc.vec.Vec lockout.Account} {input : Slice U8} {o : Option Usize}
    (h : lockout.find_by_username_or_email us input = ok o) :
    match o with
    | some i => ∃ hi : i.val < us.val.length,
        us.val[i.val].username.val = input.val ∨ (¬ IsUsername us.val input.val ∧ LowerEq us.val[i.val].email.val input.val)
    | none => ¬ IsUsername us.val input.val ∧ ∀ a ∈ us.val, ¬ LowerEq a.email.val input.val := by
  unfold lockout.find_by_username_or_email at h
  obtain ⟨o1, h1, h2⟩ := H5iAppLib.bind_tc_eq_ok.1 h
  have hs1 := post_of_ok (find_by_username_spec us input) h1
  have nou : o1 = none → ¬ IsUsername us.val input.val := by
    rintro rfl ⟨a, ha, hn⟩
    simp only [Option.map_none] at hs1
    have := List.findIdx?_eq_none_iff.1 hs1.symm a ha
    simp [hn] at this
  cases o1 with
  | some j =>
    simp only [] at h2
    have e := (H5iAppLib.Result.ok.inj h2).symm; subst e
    simp only [Option.map_some] at hs1
    obtain ⟨hl, hf⟩ := find_of_findIdx _ _ _ hs1.symm
    refine ⟨hl, Or.inl ?_⟩
    have := List.find?_some hf; simpa using this
  | none =>
    simp only [] at h2
    have hs2 := post_of_ok (find_by_email_spec us input) h2
    have hnu := nou rfl
    cases o with
    | none =>
      refine ⟨hnu, fun a ha he => ?_⟩
      simp only [Option.map_none] at hs2
      have := List.findIdx?_eq_none_iff.1 hs2.symm a ha
      simp [he] at this
    | some i =>
      simp only [Option.map_some] at hs2
      obtain ⟨hl, hf⟩ := find_of_findIdx _ _ _ hs2.symm
      refine ⟨hl, Or.inr ⟨hnu, ?_⟩⟩
      have := List.find?_some hf; simpa using this

end defguard_kernel.Verified
