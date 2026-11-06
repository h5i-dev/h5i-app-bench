import Verified.Fold
/-!
# Tenant isolation: what a request does depends only on the requester's own rows
-/
open Aeneas Aeneas.Std Result atuin_kernel atuin_kernel.Spec
open H5iAppLib hiding lit

namespace atuin_kernel.Verified

theorem status_isolated (s s' : Snapshot) (uid : U64) (h : ownRows s uid = ownRows s' uid) :
    status s uid = status s' uid := by
  rw [status_eq, status_eq, foldlM_filter (fun x => decide (x.user_id = uid)) bump,
    foldlM_filter (fun x => decide (x.user_id = uid)) bump]
  unfold ownRows at h
  rw [h]

theorem filter_of_imp {α : Type} (l : List α) (P U : α → Bool) (h : ∀ x, P x = true → U x = true) :
    l.filter P = (l.filter U).filter P := by
  rw [List.filter_filter]
  congr 1; funext x
  by_cases hp : P x <;> simp [hp, h x]

theorem next_isolated (s s' : Snapshot) (uid : U64) (host : U128) (tag : alloc.vec.Vec U8)
    (start : Option U64) (count : U64) (h : ownRows s uid = ownRows s' uid) :
    next_records s uid host tag start count = next_records s' uid host tag start count := by
  rw [next_records_eq, next_records_eq,
    foldlM_filter (InSeries uid host tag.val (start.getD 0#u64)) insert_sorted,
    foldlM_filter (InSeries uid host tag.val (start.getD 0#u64)) insert_sorted,
    filter_of_imp s.store.val _ (fun x => decide (x.user_id = uid)) (fun x hx => by simp [in_series_user hx]),
    filter_of_imp s'.store.val _ (fun x => decide (x.user_id = uid)) (fun x hx => by simp [in_series_user hx])]
  unfold ownRows at h
  rw [h]

theorem authenticate_congr (s s' : Snapshot) (h : Option (alloc.vec.Vec U8))
    (hu : s.users = s'.users) (hs : s.sessions = s'.sessions) :
    authenticate s h = authenticate s' h := by
  unfold authenticate session_user
  rw [hu, hs]

theorem authed_isolated (cfg : Config) (c : Crypto) (s s' : Snapshot) (u : User) (cmd : Command)
    (hu : s.users = s'.users) (hown : ownRows s u.id = ownRows s' u.id) :
    authed cfg c s u cmd = authed cfg c s' u cmd := by
  unfold authed
  cases cmd with
  | ChangePassword cur h => simp only []; unfold change_password; rw [hu]
  | Status => simp only []; rw [status_isolated s s' u.id hown]
  | Next host tag start count => simp only []; rw [next_isolated s s' u.id host tag start count hown]
  | _ => rfl

/-- Nothing a request does depends on another user's records: if two
databases agree on the accounts, the sessions, the counters and the rows of
whichever user the request authenticates as, the request has the same
outcome (reply, writes, or error) on both. -/
theorem transition_isolated (cfg : Config) (c : Crypto) (s s' : Snapshot) (req : Request)
    (hu : s.users = s'.users) (hs : s.sessions = s'.sessions)
    (hn : s.next_user_id = s'.next_user_id) (hn' : s.next_session_id = s'.next_session_id)
    (hown : ∀ u, Authenticated s req.authorization u → ownRows s u.id = ownRows s' u.id) :
    transition cfg c s req = transition cfg c s' req := by
  have ha := authenticate_congr s s' req.authorization hu hs
  obtain ⟨r, hr⟩ := ok_of (authenticate_spec s req.authorization)
  have hpost := post_of_ok (authenticate_spec s req.authorization) hr
  have hr' : authenticate s' req.authorization = ok r := ha ▸ hr
  have hauth : ∀ u, r = .Ok u → authed cfg c s u req.command = authed cfg c s' u req.command :=
    fun u hu' => authed_isolated cfg c s s' u req.command hu (hown u (hpost u hu'))
  unfold transition
  cases hc : req.command with
  | GetUser n => simp only []; unfold get_user; rw [hu]
  | Register n e h t => simp only []; unfold register; rw [hu, hs, hn, hn']
  | Login n pw => simp only []; unfold login; rw [hu, hs]
  | _ =>
    simp only []
    rw [hr, hr', bind_tc_ok, bind_tc_ok]
    cases r with
    | Ok u => simp only []; rw [← hc]; exact hauth u rfl
    | Err e => rfl

end atuin_kernel.Verified
