import Verified.Effects
/-!
# Invariants of every reachable database
-/
open Aeneas Aeneas.Std Result atuin_kernel atuin_kernel.Spec
open H5iAppLib hiding lit

namespace atuin_kernel.Verified

/-- What one write does to the AUTOINCREMENT counters. -/
def Counters (s : Snapshot) : Write → Snapshot → Prop
  | .AddUser u, s' => (u.id ≥ s.next_user_id → u.id < core.num.U64.MAX → s'.next_user_id.val = u.id.val + 1) ∧
      s'.next_session_id = s.next_session_id
  | .AddSession x, s' => s'.next_user_id = s.next_user_id ∧
      (x.id ≥ s.next_session_id → x.id < core.num.U64.MAX → s'.next_session_id.val = x.id.val + 1)
  | _, s' => s'.next_user_id = s.next_user_id ∧ s'.next_session_id = s.next_session_id

theorem apply_write_counters {s s' : Snapshot} {w : Write} (h : apply_write s w = ok s') : Counters s w s' := by
  unfold apply_write at h
  cases w <;> simp only [] at h <;> h5i_invert h
  all_goals (simp only [Counters]; try (h5i_ok_facts; scalar_tac))
  all_goals (try (refine ⟨fun _ _ => ?_, rfl⟩; h5i_ok_facts; scalar_tac))
  all_goals (try (refine ⟨rfl, fun _ _ => ?_⟩; h5i_ok_facts; scalar_tac))
  all_goals (try (refine ⟨fun h1 h2 => ?_, rfl⟩; scalar_tac))
  all_goals (try (refine ⟨rfl, fun h1 h2 => ?_⟩; scalar_tac))
  all_goals (try exact ⟨rfl, rfl⟩)
  all_goals (constructor <;> (try trivial) <;> intro _ _ <;> contradiction)


theorem register_guard {cfg : Config} {s : Snapshot} {n e h t : alloc.vec.Vec U8} {ws rep}
    (hr : register cfg s n e h t = ok (.Ok (ws, rep))) :
    s.next_user_id < core.num.U64.MAX ∧ s.next_session_id < core.num.U64.MAX := by
  unfold register at hr
  h5i_invert hr
  have := H5iAppLib.u64_max_val
  constructor <;> scalar_tac

/-- What a write needs from the state it is applied to, to keep `Inv`. -/
def Cond (a : Snapshot) : Write → Prop
  | .AddUser u => u.id = a.next_user_id ∧ u.id < core.num.U64.MAX
  | .AddSession x => x.id = a.next_session_id ∧ x.id < core.num.U64.MAX ∧ (∃ y ∈ a.users.val, y.id = x.user_id) ∧
      ∀ y ∈ a.sessions.val, y.token.val ≠ x.token.val
  | .InsertRecord r => ∃ y ∈ a.users.val, y.id = r.user_id
  | _ => True

theorem setPw_id (id : U64) (h : alloc.vec.Vec U8) (u : User) : (setPw id h u).id = u.id := by
  unfold setPw; split <;> rfl

theorem owned_filter {α : Type} {l : List α} {us : List User} {f : α → U64} {id : U64}
    (h : ∀ x ∈ l, ∃ y ∈ us, y.id = f x) :
    ∀ x ∈ l.filter (fun x => decide (f x ≠ id)), ∃ y ∈ us.filter (fun y => decide (y.id ≠ id)), y.id = f x := by
  intro x hx
  rw [List.mem_filter] at hx
  obtain ⟨y, hy, hyx⟩ := h x hx.1
  refine ⟨y, List.mem_filter.2 ⟨hy, ?_⟩, hyx⟩
  simpa [hyx] using hx.2

theorem owned_map {α : Type} {l : List α} {us : List User} {f : α → U64} (g : User → User) (hg : ∀ u, (g u).id = u.id)
    (h : ∀ x ∈ l, ∃ y ∈ us, y.id = f x) : ∀ x ∈ l, ∃ y ∈ us.map g, y.id = f x := by
  intro x hx
  obtain ⟨y, hy, hyx⟩ := h x hx
  exact ⟨g y, List.mem_map_of_mem hy, by rw [hg]; exact hyx⟩

theorem owned_mono {α : Type} {l : List α} {us us' : List User} {f : α → U64} (hsub : ∀ y ∈ us, y ∈ us')
    (h : ∀ x ∈ l, ∃ y ∈ us, y.id = f x) : ∀ x ∈ l, ∃ y ∈ us', y.id = f x := by
  intro x hx
  obtain ⟨y, hy, hyx⟩ := h x hx
  exact ⟨y, hsub y hy, hyx⟩

theorem nodup_map_filter {α β : Type} (l : List α) (f : α → β) (P : α → Bool) (h : (l.map f).Nodup) :
    ((l.filter P).map f).Nodup :=
  h.sublist (List.Sublist.map f (List.filter_sublist))

theorem inv_write {a b : Snapshot} {w : Write} (hi : Inv a) (he : Effect a w b) (hc : Counters a w b)
    (hcond : Cond a w) : Inv b := by
  cases w with
  | AddUser u =>
    obtain ⟨h1, h2, h3, h4⟩ := he
    obtain ⟨hn, hs⟩ := hc
    obtain ⟨hid, hmax⟩ := hcond
    have hn' := hn (by rw [hid]) hmax
    have hlt : u.id.val = a.next_user_id.val := by rw [hid]
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
    · intro y hy; rw [h1, List.mem_append] at hy
      rcases hy with hy | hy
      · have := hi.user_ids_below y hy; omega
      · simp at hy; subst hy; omega
    · rw [h2, hs]; exact hi.session_ids_below
    · rw [h2, h1]; exact owned_mono (fun y hy => List.mem_append_left _ hy) hi.sessions_owned
    · rw [h4, h1]; exact owned_mono (fun y hy => List.mem_append_left _ hy) hi.store_owned
    · rw [h3, h1]; exact owned_mono (fun y hy => List.mem_append_left _ hy) hi.history_owned
    · rw [h2]; exact hi.tokens_unique
    · rw [h1, List.map_append, List.nodup_append]
      refine ⟨hi.user_ids_unique, by simp, ?_⟩
      intro x hx y hy
      simp at hy; subst hy
      obtain ⟨z, hz, rfl⟩ := List.mem_map.1 hx
      have := hi.user_ids_below z hz
      intro e; rw [e] at this; omega
  | AddSession x =>
    obtain ⟨h1, h2, h3, h4⟩ := he
    obtain ⟨hn, hs⟩ := hc
    obtain ⟨hid, hmax, ⟨y, hy, hyx⟩, htok⟩ := hcond
    have hs' := hs (by rw [hid]) hmax
    have hlt : x.id.val = a.next_session_id.val := by rw [hid]
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
    · rw [h1, hn]; exact hi.user_ids_below
    · intro z hz; rw [h2, List.mem_append] at hz
      rcases hz with hz | hz
      · have := hi.session_ids_below z hz; omega
      · simp at hz; subst hz; omega
    · rw [h2, h1]; intro z hz; rw [List.mem_append] at hz
      rcases hz with hz | hz
      · exact hi.sessions_owned z hz
      · simp at hz; subst hz; exact ⟨y, hy, hyx⟩
    · rw [h4, h1]; exact hi.store_owned
    · rw [h3, h1]; exact hi.history_owned
    · rw [h2, List.map_append, List.nodup_append]
      refine ⟨hi.tokens_unique, by simp, ?_⟩
      intro t ht t' ht'
      simp at ht'; subst ht'
      obtain ⟨z, hz, rfl⟩ := List.mem_map.1 ht
      exact htok z hz
    · rw [h1]; exact hi.user_ids_unique
  | SetPassword id hh =>
    obtain ⟨h1, h2, h3, h4⟩ := he
    obtain ⟨hn, hs⟩ := hc
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
    · rw [h1, hn]; intro y hy; obtain ⟨z, hz, rfl⟩ := List.mem_map.1 hy; rw [setPw_id]; exact hi.user_ids_below z hz
    · rw [h2, hs]; exact hi.session_ids_below
    · rw [h2, h1]; exact owned_map _ (setPw_id id hh) hi.sessions_owned
    · rw [h4, h1]; exact owned_map _ (setPw_id id hh) hi.store_owned
    · rw [h3, h1]; exact owned_map _ (setPw_id id hh) hi.history_owned
    · rw [h2]; exact hi.tokens_unique
    · rw [h1, List.map_map]
      have : (fun u => u.id) ∘ setPw id hh = (fun u => u.id) := by funext u; simp [setPw_id]
      rw [this]; exact hi.user_ids_unique
  | DeleteUser id =>
    obtain ⟨h1, h2, h3, h4⟩ := he
    obtain ⟨hn, hs⟩ := hc
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
    · rw [h1, hn]; intro y hy; exact hi.user_ids_below y (List.mem_filter.1 hy).1
    · rw [h2, hs]; intro y hy; exact hi.session_ids_below y (List.mem_filter.1 hy).1
    · rw [h2, h1]; exact owned_filter hi.sessions_owned
    · rw [h4, h1]; exact owned_filter hi.store_owned
    · rw [h3, h1]; exact owned_filter hi.history_owned
    · rw [h2]; exact nodup_map_filter _ _ _ hi.tokens_unique
    · rw [h1]; exact nodup_map_filter _ _ _ hi.user_ids_unique
  | InsertRecord r =>
    obtain ⟨h1, h2, h3, h4⟩ := he
    obtain ⟨hn, hs⟩ := hc
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
    · rw [h1, hn]; exact hi.user_ids_below
    · rw [h2, hs]; exact hi.session_ids_below
    · rw [h2, h1]; exact hi.sessions_owned
    · rw [h4, h1]; split
      · exact hi.store_owned
      · intro z hz; rw [List.mem_append] at hz
        rcases hz with hz | hz
        · exact hi.store_owned z hz
        · simp at hz; subst hz; exact hcond
    · rw [h3, h1]; exact hi.history_owned
    · rw [h2]; exact hi.tokens_unique
    · rw [h1]; exact hi.user_ids_unique
  | DeleteStore id =>
    obtain ⟨h1, h2, h3, h4⟩ := he
    obtain ⟨hn, hs⟩ := hc
    refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩
    · rw [h1, hn]; exact hi.user_ids_below
    · rw [h2, hs]; exact hi.session_ids_below
    · rw [h2, h1]; exact hi.sessions_owned
    · rw [h4, h1]; intro z hz; exact hi.store_owned z (List.mem_filter.1 hz).1
    · rw [h3, h1]; exact hi.history_owned
    · rw [h2]; exact hi.tokens_unique
    · rw [h1]; exact hi.user_ids_unique

theorem apply_one {s s' : Snapshot} {ws : alloc.vec.Vec Write} {w : Write} (hw : ws.val = [w])
    (h : apply s ws = ok s') : apply_write s w = ok s' := by
  rw [apply_eq, hw] at h
  simp only [List.foldlM_cons, List.foldlM_nil] at h
  obtain ⟨b, hb, hb'⟩ := H5iAppLib.bind_tc_eq_ok.1 h
  rw [hb, ← H5iAppLib.Result.ok.inj hb']

theorem apply_two {s s' : Snapshot} {ws : alloc.vec.Vec Write} {w1 w2 : Write} (hw : ws.val = [w1, w2])
    (h : apply s ws = ok s') : ∃ a, apply_write s w1 = ok a ∧ apply_write a w2 = ok s' := by
  rw [apply_eq, hw] at h
  simp only [List.foldlM_cons, List.foldlM_nil] at h
  obtain ⟨a, ha, h'⟩ := H5iAppLib.bind_tc_eq_ok.1 h
  obtain ⟨b, hb, hb'⟩ := H5iAppLib.bind_tc_eq_ok.1 h'
  exact ⟨a, ha, by rw [hb, ← H5iAppLib.Result.ok.inj hb']⟩

theorem apply_nil {s s' : Snapshot} {ws : alloc.vec.Vec Write} (hw : ws.val = []) (h : apply s ws = ok s') :
    s' = s := by
  rw [apply_eq, hw] at h
  simp only [List.foldlM_nil] at h
  exact (H5iAppLib.Result.ok.inj h).symm

theorem inv_one {a b : Snapshot} {w : Write} (hi : Inv a) (h : apply_write a w = ok b) (hc : Cond a w) : Inv b :=
  inv_write hi (apply_write_ok h) (apply_write_counters h) hc

/-- Every successful request keeps the invariant. -/
theorem inv_step {cfg : Config} {c : Crypto} {s s' : Snapshot} {req : Request} {ws : alloc.vec.Vec Write}
    {rep : Reply} (hi : Inv s) (h : transition cfg c s req = ok (.Ok (ws, rep))) (ha : apply s ws = ok s') :
    Inv s' := by
  rcases transition_writes h with ⟨n, e, hh, t, hc, _, _, hf, hws, _⟩ | ⟨u, hu, hw⟩ | h0
  · -- registration: the user, then their session
    have hreg : register cfg s n e hh t = ok (.Ok (ws, rep)) := by
      unfold transition at h; rw [hc] at h; exact h
    obtain ⟨hmu, hms⟩ := register_guard hreg
    obtain ⟨a, h1, h2⟩ := apply_two hws ha
    have ia := inv_one hi h1 ⟨rfl, hmu⟩
    obtain ⟨e1, e2, _, _⟩ := apply_write_ok h1
    obtain ⟨_, c2⟩ := apply_write_counters h1
    refine inv_one ia h2 ⟨c2.symm, hms, ⟨_, by rw [e1]; exact List.mem_append_right _ (List.mem_singleton_self _), rfl⟩, ?_⟩
    rw [e2]; intro y hy; exact hf.2 y hy
  · have hus : u ∈ s.users.val := hu.choose_spec.2.1
    cases hcmd : req.command with
    | DeleteAccount pw =>
      rw [hcmd] at hw; obtain ⟨_, hws⟩ := hw; exact inv_one hi (apply_one hws ha) trivial
    | ChangePassword cur h' =>
      rw [hcmd] at hw; obtain ⟨_, _, hws⟩ := hw; exact inv_one hi (apply_one hws ha) trivial
    | DeleteStore =>
      rw [hcmd] at hw; exact inv_one hi (apply_one hw ha) trivial
    | PostRecords rs =>
      rw [hcmd] at hw; obtain ⟨_, hws⟩ := hw
      rw [apply_eq] at ha
      refine (foldlM_preserve apply_write (fun x => Inv x ∧ x.users = s.users) ws.val s s' ?_ ha ⟨hi, rfl⟩).1
      intro w hwm x y ⟨hx, hxu⟩ hy
      rw [hws, List.mem_map] at hwm
      obtain ⟨r, _, rfl⟩ := hwm
      refine ⟨inv_one hx hy (by simp only [Cond, rowOf]; rw [hxu]; exact ⟨u, hus, rfl⟩), ?_⟩
      rw [(apply_write_ok hy).1, hxu]
    | GetUser _ | Register _ _ _ _ | Login _ _ | Me | Status | Next _ _ _ _ =>
      rw [hcmd] at hw; simp only [AuthedWrites] at hw; rw [apply_nil hw ha]; exact hi
  · rw [apply_nil h0 ha]; exact hi

theorem inv_empty : Inv empty := by
  refine ⟨?_, ?_, ?_, ?_, ?_, ?_, ?_⟩ <;> simp [empty, H5iAppLib.vec_new_val]

theorem reachable_inv {s : Snapshot} (h : Reachable s) : Inv s := by
  induction h with
  | init => exact inv_empty
  | step _ ht ha ih => exact inv_step ih ht ha

/-- In every reachable database every session, history row and record
belongs to an existing user: no orphans (upstream once left records of
deleted users behind, fixed by migration 20260828000000_purge-orphaned-store). -/
theorem no_orphans {s : Snapshot} (h : Reachable s) :
    (∀ x ∈ s.sessions.val, ∃ u ∈ s.users.val, u.id = x.user_id) ∧
    (∀ r ∈ s.store.val, ∃ u ∈ s.users.val, u.id = r.user_id) ∧
    (∀ x ∈ s.history.val, ∃ u ∈ s.users.val, u.id = x.user_id) :=
  let hi := reachable_inv h
  ⟨hi.sessions_owned, hi.store_owned, hi.history_owned⟩

/-- A new account starts empty: it inherits no record, history row or
session of any earlier (e.g. deleted) account; its only session is the new one. -/
theorem new_account_starts_empty {cfg : Config} {c : Crypto} {s s' : Snapshot} {req : Request}
    {ws : alloc.vec.Vec Write} {rep : Reply} {n e hh t : alloc.vec.Vec U8}
    (hr : Reachable s) (hcmd : req.command = .Register n e hh t)
    (h : transition cfg c s req = ok (.Ok (ws, rep))) (ha : apply s ws = ok s') :
    ownRows s' s.next_user_id = [] ∧ ownHistory s' s.next_user_id = [] ∧
    ownSessions s' s.next_user_id = [{ id := s.next_session_id, user_id := s.next_user_id, token := t }] := by
  have hi := reachable_inv hr
  have hreg : register cfg s n e hh t = ok (.Ok (ws, rep)) := by
    unfold transition at h; rw [hcmd] at h; exact h
  obtain ⟨_, _, _, hws, _⟩ := register_ok hreg
  obtain ⟨a, h1, h2⟩ := apply_two hws ha
  obtain ⟨e1, e2, e3, e4⟩ := apply_write_ok h1
  obtain ⟨f1, f2, f3, f4⟩ := apply_write_ok h2
  have none_owned : ∀ {α : Type} (l : List α) (g : α → U64), (∀ x ∈ l, ∃ u ∈ s.users.val, u.id = g x) →
      l.filter (fun x => decide (g x = s.next_user_id)) = [] := by
    intro α l g hl
    rw [List.filter_eq_nil_iff]; intro x hx
    obtain ⟨u, hu, hux⟩ := hl x hx
    simp only [decide_eq_true_eq]; intro heq
    have h2 := hi.user_ids_below u hu
    rw [hux, heq] at h2; exact Nat.lt_irrefl _ h2
  refine ⟨?_, ?_, ?_⟩
  · simp only [ownRows, f4, e4]; exact none_owned s.store.val (fun (r : StoreRow) => r.user_id) hi.store_owned
  · simp only [ownHistory, f3, e3]; exact none_owned s.history.val (fun (x : HistoryRow) => x.user_id) hi.history_owned
  · simp only [ownSessions, f2, e2, List.filter_append]
    rw [none_owned s.sessions.val (fun (x : Session) => x.user_id) hi.sessions_owned]; simp

/-- A session token identifies at most one account in every reachable database. -/
theorem token_identifies_one_account {s : Snapshot} {h : Option (alloc.vec.Vec U8)} {u u' : User}
    (hr : Reachable s) (hu : Authenticated s h u) (hu' : Authenticated s h u') : u = u' := by
  have hi := reachable_inv hr
  obtain ⟨t, ht, hm, x, hx, hxt, hxu⟩ := hu
  obtain ⟨t', ht', hm', x', hx', hxt', hxu'⟩ := hu'
  rw [ht] at ht'; cases ht'
  have hxx : x = x' := List.inj_on_of_nodup_map hi.tokens_unique hx hx' (by rw [hxt, hxt'])
  subst hxx
  exact List.inj_on_of_nodup_map hi.user_ids_unique hm hm' (by rw [← hxu, hxu'])

end atuin_kernel.Verified
