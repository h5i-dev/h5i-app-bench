import Verified.Lockout
/-!
# The login handler's lockout: what it guarantees, and how it is bypassed
-/
open Aeneas Aeneas.Std Result defguard_kernel defguard_kernel.Spec
open H5iAppLib

namespace defguard_kernel.Verified

/-- The shape of a successful `authenticate` run. -/
theorem authenticate_cases {map m : alloc.vec.Vec lockout.FailedLogin} {us : alloc.vec.Vec lockout.Account}
    {input : Slice U8} {pw : alloc.vec.Vec Bool} {now : I64} {out : lockout.LoginOutcome}
    (h : lockout.authenticate map us input pw now = ok (m, out)) :
    ∃ m1 b, lockout.verify_username map input now = ok (m1, b) ∧
      ((b = true ∧ m = m1 ∧ out = .Blocked) ∨
       (b = false ∧ lockout.find_by_username_or_email us input = ok none ∧
          lockout.log_failed_attempt m1 input now = ok m ∧ out = .UnknownUser) ∨
       (b = false ∧ ∃ i, lockout.find_by_username_or_email us input = ok (some i) ∧
          ((m = m1 ∧ out = .Verified i ∧ ∃ hi : i.val < pw.val.length, pw.val[i.val] = true) ∨
           (∃ hi : i.val < us.val.length,
              lockout.log_failed_attempt m1 (alloc.vec.Vec.deref us.val[i.val].username) now = ok m ∧
              out = .WrongPassword)))) := by
  unfold lockout.authenticate at h
  obtain ⟨⟨m1, b⟩, h1, h2⟩ := H5iAppLib.bind_tc_eq_ok.1 h
  refine ⟨m1, b, h1, ?_⟩
  have h2' : (if b = true then ok (m1, lockout.LoginOutcome.Blocked) else do
      let o ← lockout.find_by_username_or_email us input
      match o with
        | none => do
          let v ← lockout.log_failed_attempt m1 input now
          ok (v, lockout.LoginOutcome.UnknownUser)
        | some i =>
          if i < pw.len then do
            let b ← alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice Bool) pw i
            if b = true then ok (m1, lockout.LoginOutcome.Verified i)
              else do
                let a ← alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice lockout.Account) us i
                let v ← lockout.log_failed_attempt m1 (alloc.vec.Vec.deref a.username) now
                ok (v, lockout.LoginOutcome.WrongPassword)
          else do
            let a ← alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice lockout.Account) us i
            let v ← lockout.log_failed_attempt m1 (alloc.vec.Vec.deref a.username) now
            ok (v, lockout.LoginOutcome.WrongPassword)) = ok (m, out) := h2
  clear h2
  have h2 := h2'
  clear h2'
  split at h2
  · rename_i hb
    have := H5iAppLib.Result.ok.inj h2; simp only [Prod.mk.injEq] at this
    exact Or.inl ⟨hb, this.1.symm, this.2.symm⟩
  · rename_i hb
    simp only [Bool.not_eq_true] at hb
    obtain ⟨o, ho, h3⟩ := H5iAppLib.bind_tc_eq_ok.1 h2
    cases o with
    | none =>
      simp only [] at h3
      obtain ⟨v, hv, h4⟩ := H5iAppLib.bind_tc_eq_ok.1 h3
      have := H5iAppLib.Result.ok.inj h4; simp only [Prod.mk.injEq] at this
      obtain ⟨rfl, rfl⟩ := this
      exact Or.inr (Or.inl ⟨hb, ho, hv, rfl⟩)
    | some i =>
      refine Or.inr (Or.inr ⟨hb, i, ho, ?_⟩)
      simp only [] at h3
      have hfind := find_account_ok ho
      simp only [] at hfind
      obtain ⟨hil, _⟩ := hfind
      split at h3
      · rename_i hlt
        obtain ⟨bb, hbb, h4⟩ := H5iAppLib.bind_tc_eq_ok.1 h3
        have hl : i.val < pw.val.length := by scalar_tac
        rw [vec_index_eq _ _ hl] at hbb
        have := (H5iAppLib.Result.ok.inj hbb); subst this
        split at h4
        · rename_i ht
          have := H5iAppLib.Result.ok.inj h4; simp only [Prod.mk.injEq] at this
          exact Or.inl ⟨this.1.symm, this.2.symm, hl, ht⟩
        · obtain ⟨a, ha, h5⟩ := H5iAppLib.bind_tc_eq_ok.1 h4
          rw [vec_index_eq _ _ hil] at ha
          have := (H5iAppLib.Result.ok.inj ha); subst this
          obtain ⟨v, hv, h6⟩ := H5iAppLib.bind_tc_eq_ok.1 h5
          have := H5iAppLib.Result.ok.inj h6; simp only [Prod.mk.injEq] at this
          obtain ⟨rfl, rfl⟩ := this
          exact Or.inr ⟨hil, hv, rfl⟩
      · obtain ⟨a, ha, h5⟩ := H5iAppLib.bind_tc_eq_ok.1 h3
        rw [vec_index_eq _ _ hil] at ha
        have := (H5iAppLib.Result.ok.inj ha); subst this
        obtain ⟨v, hv, h6⟩ := H5iAppLib.bind_tc_eq_ok.1 h5
        have := H5iAppLib.Result.ok.inj h6; simp only [Prod.mk.injEq] at this
        obtain ⟨rfl, rfl⟩ := this
        exact Or.inr ⟨hil, hv, rfl⟩

/-- A locked-out name is refused before the password is looked at. -/
theorem locked_name_blocked {map m : alloc.vec.Vec lockout.FailedLogin} {us : alloc.vec.Vec lockout.Account}
    {input : Slice U8} {pw : alloc.vec.Vec Bool} {now : I64} {out : lockout.LoginOutcome}
    (hl : Locked map.val input.val now.val) (h : lockout.authenticate map us input pw now = ok (m, out)) :
    out = .Blocked := by
  obtain ⟨m1, b, h1, hc⟩ := authenticate_cases h
  have hb := ((verify_username_ok h1).1).2 hl
  rcases hc with ⟨_, _, rfl⟩ | ⟨hb', _⟩ | ⟨hb', _⟩ <;> simp_all

/-- The password verifies only for the account the name resolves to. -/
theorem verified_needs_password {map m : alloc.vec.Vec lockout.FailedLogin} {us : alloc.vec.Vec lockout.Account}
    {input : Slice U8} {pw : alloc.vec.Vec Bool} {now : I64} {i : Usize}
    (h : lockout.authenticate map us input pw now = ok (m, .Verified i)) :
    ¬ Locked map.val input.val now.val ∧ ∃ hi : i.val < pw.val.length, pw.val[i.val] = true := by
  obtain ⟨m1, b, h1, hc⟩ := authenticate_cases h
  have hv := verify_username_ok h1
  rcases hc with ⟨_, _, hout⟩ | ⟨_, _, _, hout⟩ | ⟨hb, j, _, ⟨_, hout, hj⟩ | ⟨_, _, hout⟩⟩
  · cases hout
  · cases hout
  · cases hout
    exact ⟨fun hl => by have := hv.1.2 hl; simp_all, hj⟩
  · cases hout

/-- A wrong password typed with a username is recorded under that name, now. -/
theorem failure_recorded {map m : alloc.vec.Vec lockout.FailedLogin} {us : alloc.vec.Vec lockout.Account}
    {input : Slice U8} {pw : alloc.vec.Vec Bool} {now : I64}
    (hu : IsUsername us.val input.val) (h : lockout.authenticate map us input pw now = ok (m, .WrongPassword)) :
    ∃ f, entryFor m.val input.val = some f ∧ f.last_attempt = now := by
  obtain ⟨m1, b, h1, hc⟩ := authenticate_cases h
  rcases hc with ⟨_, _, hout⟩ | ⟨_, _, _, hout⟩ | ⟨hb, i, hi, ⟨_, hout, _⟩ | ⟨hil, hlog, _⟩⟩
  · cases hout
  · cases hout
  · cases hout
  · have hf := find_account_ok hi
    simp only [] at hf
    obtain ⟨_, hname | ⟨hnu, _⟩⟩ := hf
    · obtain ⟨_, f, hf, hl, _⟩ := log_failed_attempt_ok hlog
      simp only [vec_deref_val, hname] at hf
      exact ⟨f, hf, hl⟩
    · exact absurd hu hnu

/-- The fifth wrong password inside the window locks the name out for the
next five minutes. -/
theorem fifth_failure_locks {map m : alloc.vec.Vec lockout.FailedLogin} {us : alloc.vec.Vec lockout.Account}
    {input : Slice U8} {pw : alloc.vec.Vec Bool} {now : I64} {f : lockout.FailedLogin}
    (hu : IsUsername us.val input.val) (he : entryFor map.val input.val = some f) (h4 : f.attempt_count.val = 4)
    (hr : ¬ ResetCond f now.val)
    (h : lockout.authenticate map us input pw now = ok (m, .WrongPassword)) (later : Int)
    (hlater : later - now.val ≤ 300000000000) :
    Locked m.val input.val later := by
  obtain ⟨m1, b, h1, hc⟩ := authenticate_cases h
  have hv := verify_username_ok h1
  have hnl : ¬ Locked map.val input.val now.val := by
    rintro ⟨g, hg, h5, _⟩; rw [he] at hg; cases hg; omega
  have hb : b = false := by cases b <;> simp_all
  have hm1 : m1 = map := hv.2 hb
  subst hm1
  rcases hc with ⟨_, _, hout⟩ | ⟨_, _, _, hout⟩ | ⟨_, i, hi, ⟨_, hout, _⟩ | ⟨hil, hlog, _⟩⟩
  · cases hout
  · cases hout
  · cases hout
  · have hf := find_account_ok hi
    simp only [] at hf
    obtain ⟨_, hname | ⟨hnu, _⟩⟩ := hf
    · obtain ⟨_, f', hf', hl, hcnt⟩ := log_failed_attempt_ok hlog
      simp only [vec_deref_val, hname] at hf' hcnt
      rw [he] at hcnt
      obtain ⟨hc4, _⟩ := hcnt.2 hr
      have hf4 : f.attempt_count = 4#u32 := UScalar.eq_of_val_eq (by simp [h4])
      rw [hf4] at hc4
      refine ⟨f', hf', ?_, ?_⟩
      · rw [hc4]; decide
      · rw [hl]; exact hlater
    · exact absurd hu hnu

/-- Finding: the tracker is consulted under the name the client typed, but
failures of a known account are recorded under its username. Typing the
account's email instead (any letter case) is therefore never locked out:
the attempt always reaches the password check, and the tracker never gains
an entry for what was typed. -/
theorem email_login_never_locked {map m : alloc.vec.Vec lockout.FailedLogin} {us : alloc.vec.Vec lockout.Account}
    {input : Slice U8} {pw : alloc.vec.Vec Bool} {now : I64} {out : lockout.LoginOutcome}
    (hnone : entryFor map.val input.val = none) (hnu : ¬ IsUsername us.val input.val)
    (hem : ∃ a ∈ us.val, LowerEq a.email.val input.val)
    (h : lockout.authenticate map us input pw now = ok (m, out)) :
    out ≠ .Blocked ∧ entryFor m.val input.val = none := by
  obtain ⟨m1, b, h1, hc⟩ := authenticate_cases h
  have hv := verify_username_ok h1
  have hnl : ¬ Locked map.val input.val now.val := by
    rintro ⟨g, hg, _⟩; rw [hnone] at hg; cases hg
  have hb : b = false := by cases b <;> simp_all
  have hm1 : m1 = map := hv.2 hb
  subst hm1
  rcases hc with ⟨hb', _, _⟩ | ⟨_, hn, _, _⟩ | ⟨_, i, hi, ⟨rfl, hout, _⟩ | ⟨hil, hlog, hout⟩⟩
  · simp_all
  · have := find_account_ok hn
    simp only [] at this
    obtain ⟨a, ha, he⟩ := hem
    exact absurd he (this.2 a ha)
  · exact ⟨by rw [hout]; simp, hnone⟩
  · refine ⟨by rw [hout]; simp, ?_⟩
    have hf := find_account_ok hi
    simp only [] at hf
    obtain ⟨_, hname | ⟨_, _⟩⟩ := hf
    · exact absurd ⟨_, List.getElem_mem hil, hname⟩ hnu
    · have hne : us.val[i.val].username.val ≠ input.val := fun e => hnu ⟨_, List.getElem_mem hil, e⟩
      obtain ⟨hframe, _⟩ := log_failed_attempt_ok hlog
      simp only [vec_deref_val] at hframe
      rw [hframe input.val (fun e => hne e.symm)]
      exact hnone

end defguard_kernel.Verified
