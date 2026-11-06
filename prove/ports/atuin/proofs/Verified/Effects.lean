import Verified.Apply
import Verified.Authorization
/-!
# What a successful request does to the tables
-/
open Aeneas Aeneas.Std Result atuin_kernel atuin_kernel.Spec
open H5iAppLib hiding lit

namespace atuin_kernel.Verified

theorem apply_eq (s : Snapshot) (ws : alloc.vec.Vec Write) : apply s ws = ws.val.foldlM apply_write s := by
  unfold apply apply_loop
  rw [Snapshot.Insts.CoreCloneClone.clone.ok_eq]
  simp only [bind_ok, bind_tc_ok]
  rw [loop_eq_foldlM ws.val apply_write _ ?hb ?he (by scalar_tac) s 0#usize (by simp)]
  · simp
  case hb =>
    intro acc i hi
    unfold apply_loop.body
    have hc : i < alloc.vec.Vec.len ws := by scalar_tac
    simp only [hc, ↓reduceIte, vec_index_eq _ _ hi, bind_ok]
  case he =>
    intro acc i hi
    unfold apply_loop.body
    have hc : ¬ i < alloc.vec.Vec.len ws := by scalar_tac
    simp only [hc, ↓reduceIte]

/-- A property every write keeps holds after the whole write set. -/
theorem foldlM_preserve {α σ : Type} (f : σ → α → Result σ) (P : σ → Prop) (l : List α) (s s' : σ)
    (hstep : ∀ x ∈ l, ∀ a b, P a → f a x = ok b → P b) (h : l.foldlM f s = ok s') (hs : P s) : P s' := by
  induction l generalizing s with
  | nil => simp only [List.foldlM_nil] at h; exact (H5iAppLib.Result.ok.inj h) ▸ hs
  | cons x xs ih =>
    rw [List.foldlM_cons] at h
    obtain ⟨a, ha, h'⟩ := H5iAppLib.bind_tc_eq_ok.1 h
    exact ih a (fun y hy => hstep y (List.mem_cons_of_mem _ hy)) h' (hstep x (List.mem_cons_self) s a hs ha)

theorem apply_preserve {s s' : Snapshot} {ws : alloc.vec.Vec Write} (P : Snapshot → Prop)
    (hstep : ∀ w ∈ ws.val, ∀ a b, P a → Effect a w b → P b) (h : apply s ws = ok s') (hs : P s) : P s' := by
  rw [apply_eq] at h
  exact foldlM_preserve apply_write P ws.val s s' (fun w hw a b ha hb => hstep w hw a b ha (apply_write_ok hb)) h hs

/-- Everything a database holds about account `uid`. -/
def Account (s : Snapshot) (uid : U64) : List User × List Session × List HistoryRow × List StoreRow :=
  (s.users.val.filter (fun u => u.id = uid), ownSessions s uid, ownHistory s uid, ownRows s uid)

theorem filter_append_ne {α : Type} (l : List α) (x : α) (P : α → Bool) (h : P x = false) :
    (l ++ [x]).filter P = l.filter P := by simp [List.filter_append, h]

theorem filter_filter_ne {α : Type} (l : List α) (f : α → U64) (id uid : U64) (h : id ≠ uid) :
    (l.filter (fun x => decide (f x ≠ id))).filter (fun x => decide (f x = uid)) = l.filter (fun x => decide (f x = uid)) := by
  rw [List.filter_filter]; congr 1; funext x
  by_cases hx : f x = uid <;> by_cases hy : f x = id <;> simp_all

theorem filter_setPw (l : List User) (id uid : U64) (hh : alloc.vec.Vec U8) (h : id ≠ uid) :
    (l.map (setPw id hh)).filter (fun u => decide (u.id = uid)) = l.filter (fun u => decide (u.id = uid)) := by
  induction l with
  | nil => rfl
  | cons x xs ih =>
    simp only [List.map_cons, List.filter_cons]
    by_cases hx : x.id = id
    · have : x.id ≠ uid := hx ▸ h
      simp [setPw, hx, this, ih, h]
    · simp [setPw, hx, ih]

/-- A write that does not belong to `uid` leaves `uid`'s account as it was. -/
theorem effect_account {a b : Snapshot} {w : Write} {uid : U64} (he : Effect a w b) (hw : ownerOf w ≠ uid) :
    Account b uid = Account a uid := by
  cases w with
  | AddUser u =>
    simp only [ownerOf] at hw
    obtain ⟨h1, h2, h3, h4⟩ := he
    simp only [Account, ownSessions, ownHistory, ownRows, h1, h2, h3, h4]
    rw [filter_append_ne]; simp [hw]
  | AddSession x =>
    simp only [ownerOf] at hw
    obtain ⟨h1, h2, h3, h4⟩ := he
    simp only [Account, ownSessions, ownHistory, ownRows, h1, h2, h3, h4]
    rw [filter_append_ne]; simp [hw]
  | SetPassword id hh =>
    simp only [ownerOf] at hw
    obtain ⟨h1, h2, h3, h4⟩ := he
    simp only [Account, ownSessions, ownHistory, ownRows, h1, h2, h3, h4]
    rw [filter_setPw _ _ _ _ hw]
  | DeleteUser id =>
    simp only [ownerOf] at hw
    obtain ⟨h1, h2, h3, h4⟩ := he
    simp only [Account, ownSessions, ownHistory, ownRows, h1, h2, h3, h4]
    rw [filter_filter_ne a.users.val (fun (u : User) => u.id) _ _ hw,
      filter_filter_ne a.sessions.val (fun (x : Session) => x.user_id) _ _ hw,
      filter_filter_ne a.history.val (fun (x : HistoryRow) => x.user_id) _ _ hw,
      filter_filter_ne a.store.val (fun (x : StoreRow) => x.user_id) _ _ hw]
  | InsertRecord r =>
    simp only [ownerOf] at hw
    obtain ⟨h1, h2, h3, h4⟩ := he
    simp only [Account, ownSessions, ownHistory, ownRows, h1, h2, h3, h4]
    split
    · rfl
    · rw [filter_append_ne]; simp [hw]
  | DeleteStore id =>
    simp only [ownerOf] at hw
    obtain ⟨h1, h2, h3, h4⟩ := he
    simp only [Account, ownSessions, ownHistory, ownRows, h1, h2, h3, h4]
    rw [filter_filter_ne a.store.val (fun (x : StoreRow) => x.user_id) _ _ hw]

/-- A successful request leaves every account other than the requester's
(and the id the next registration takes) exactly as it was. -/
theorem other_accounts_untouched {cfg : Config} {c : Crypto} {s s' : Snapshot} {req : Request}
    {ws : alloc.vec.Vec Write} {rep : Reply} {uid : U64}
    (h : transition cfg c s req = ok (.Ok (ws, rep))) (ha : apply s ws = ok s')
    (hnew : uid ≠ s.next_user_id) (hnot : ∀ u, Authenticated s req.authorization u → u.id ≠ uid) :
    Account s' uid = Account s uid := by
  apply apply_preserve (fun x => Account x uid = Account s uid) _ ha rfl
  intro w hw a b hab he
  rw [← hab]
  apply effect_account he
  have hal := authorized cfg c s req ws rep h w hw
  cases w with
  | AddUser u => obtain ⟨_, _, _, _, _, _, _, _, rfl⟩ := hal; exact fun e => hnew e.symm
  | AddSession x => obtain ⟨_, _, _, _, _, _, _, _, rfl⟩ := hal; exact fun e => hnew e.symm
  | SetPassword id hh => obtain ⟨u, hu, rfl, _⟩ := hal; exact hnot u hu
  | DeleteUser id => obtain ⟨u, hu, rfl, _⟩ := hal; exact hnot u hu
  | InsertRecord r => obtain ⟨u, hu, _, _, _, x, _, rfl⟩ := hal; exact hnot u hu
  | DeleteStore id => obtain ⟨u, hu, rfl, _⟩ := hal; exact hnot u hu

theorem authenticated_route {cfg : Config} {c : Crypto} {s : Snapshot} {req : Request} {ws rep}
    (h : transition cfg c s req = ok (.Ok (ws, rep)))
    (hgu : ∀ n, req.command ≠ .GetUser n) (hreg : ∀ n e hh t, req.command ≠ .Register n e hh t)
    (hlog : ∀ n pw, req.command ≠ .Login n pw) :
    ∃ u, Authenticated s req.authorization u ∧ AuthedWrites cfg c s u req.command ws.val := by
  unfold transition at h
  split at h
  · rename_i n heq; exact absurd heq (hgu n)
  · rename_i n e hh t heq; exact absurd heq (hreg n e hh t)
  · rename_i n pw heq; exact absurd heq (hlog n pw)
  all_goals
    h5i_invert h
    exact ⟨_, authenticate_ok hr, authed_ok h⟩

/-- Deleting an account removes the user and every session, history row
and record of theirs. -/
theorem account_deletion_purges {cfg : Config} {c : Crypto} {s s' : Snapshot} {req : Request}
    {ws : alloc.vec.Vec Write} {rep : Reply} {pw : alloc.vec.Vec U8}
    (hcmd : req.command = .DeleteAccount pw)
    (h : transition cfg c s req = ok (.Ok (ws, rep))) (ha : apply s ws = ok s') :
    ∃ u, Authenticated s req.authorization u ∧ Account s' u.id = ([], [], [], []) := by
  obtain ⟨u, hu, hw⟩ := authenticated_route h (by simp [hcmd]) (by simp [hcmd]) (by simp [hcmd])
  rw [hcmd] at hw
  simp only [AuthedWrites] at hw
  obtain ⟨_, hws⟩ := hw
  refine ⟨u, hu, ?_⟩
  rw [apply_eq, hws] at ha
  simp only [List.foldlM_cons, List.foldlM_nil] at ha
  obtain ⟨b, hb, hb'⟩ := H5iAppLib.bind_tc_eq_ok.1 ha
  have : s' = b := (H5iAppLib.Result.ok.inj hb').symm
  subst this
  obtain ⟨h1, h2, h3, h4⟩ := apply_write_ok hb
  simp only [Account, ownSessions, ownHistory, ownRows, h1, h2, h3, h4, List.filter_filter, Prod.mk.injEq]
  refine ⟨?_, ?_, ?_, ?_⟩ <;> (rw [List.filter_eq_nil_iff]; intro x _; simp only [Bool.and_eq_true, decide_eq_true_eq, not_and]; intro e1 e2; exact e2 e1)

/-- Records are append-only: no request but an account or store deletion
removes or changes a stored record (`ON CONFLICT DO NOTHING` never overwrites). -/
theorem records_append_only {cfg : Config} {c : Crypto} {s s' : Snapshot} {req : Request}
    {ws : alloc.vec.Vec Write} {rep : Reply}
    (hd : ∀ pw, req.command ≠ .DeleteAccount pw) (hs : req.command ≠ .DeleteStore)
    (h : transition cfg c s req = ok (.Ok (ws, rep))) (ha : apply s ws = ok s') :
    s.store.val <+: s'.store.val := by
  apply apply_preserve (fun x => s.store.val <+: x.store.val) _ ha (List.prefix_refl _)
  intro w hw a b hab he
  have hal := authorized cfg c s req ws rep h w hw
  cases w with
  | AddUser u => rw [he.2.2.2]; exact hab
  | AddSession x => rw [he.2.2.2]; exact hab
  | SetPassword id hh => rw [he.2.2.2]; exact hab
  | DeleteUser id => obtain ⟨u, _, _, pw, hc, _⟩ := hal; exact absurd hc (hd pw)
  | InsertRecord r =>
    rw [he.2.2.2]
    split
    · exact hab
    · exact hab.trans (List.prefix_append _ _)
  | DeleteStore id => obtain ⟨u, _, _, hc⟩ := hal; exact absurd hc hs

/-- Finding: changing the password keeps every session, so a session token
taken before the change stays valid after it. -/
theorem password_change_keeps_sessions {cfg : Config} {c : Crypto} {s s' : Snapshot} {req : Request}
    {ws : alloc.vec.Vec Write} {rep : Reply} {cur h' : alloc.vec.Vec U8}
    (hcmd : req.command = .ChangePassword cur h')
    (h : transition cfg c s req = ok (.Ok (ws, rep))) (ha : apply s ws = ok s') :
    s'.sessions = s.sessions := by
  apply apply_preserve (fun x => x.sessions = s.sessions) _ ha rfl
  intro w hw a b hab he
  have hal := authorized cfg c s req ws rep h w hw
  cases w with
  | SetPassword id hh => rw [he.2.1]; exact hab
  | AddUser u => obtain ⟨_, _, _, _, hc, _⟩ := hal; simp [hcmd] at hc
  | AddSession x => obtain ⟨_, _, _, _, hc, _⟩ := hal; simp [hcmd] at hc
  | DeleteUser id => obtain ⟨u, _, _, pw, hc, _⟩ := hal; simp [hcmd] at hc
  | InsertRecord r => obtain ⟨u, _, rs, hc, _⟩ := hal; simp [hcmd] at hc
  | DeleteStore id => obtain ⟨u, _, _, hc⟩ := hal; simp [hcmd] at hc

end atuin_kernel.Verified
