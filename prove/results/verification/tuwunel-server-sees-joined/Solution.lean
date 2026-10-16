import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result tuwunel_kernel tuwunel_kernel.Spec
open H5iAppLib hiding lit

set_option maxHeartbeats 0
namespace tuwunel_kernel.Solution

def absIdx (s : Snapshot) : core.result.Result Usize Error → Option (Option Pdu)
  | .Ok i => some s.pdus.val[i.val]?
  | .Err _ => none

def nonOut (e : U64) (p : Pdu) : Bool := !p.outlier && p.event_id = e
def isOut (e : U64) (p : Pdu) : Bool := p.outlier && p.event_id = e

def hashP (h : U64) (x : StateSet) : Bool := x.hash = h
def entryP (k : Kind) (key : U64) (en : StateEntry) : Bool := en.kind = k ∧ en.state_key = key

def leftP (u room : U64) (x : LeftRow) : Bool := x.user = u ∧ x.room = room

def absOpt {α} : core.result.Result α Error → Option α
  | .Ok x => some x
  | .Err _ => none

theorem kind_eq_ok (a b : Kind) : kind_eq a b = ok (decide (a = b)) := by
  cases a <;> cases b <;> simp [kind_eq]

theorem get_non_outlier_spec (s : Snapshot) (e : U64) :
    svc_timeline.get_non_outlier_loop s e 0#usize ⦃ r => absIdx s r = (s.pdus.val.find? (nonOut e)).map some ⦄ := by
  unfold svc_timeline.get_non_outlier_loop
  apply WP.spec_mono (H5iAppLib.loop_search s.pdus.val (nonOut e) (absIdx s) (fun _ x => some (some x)) none _ ?step 0#usize (by simp))
  · intro r hr; rw [hr, searchFrom_find]; simp
  case step => intro j hj; h5i_unfold_body; h5i_step [absIdx, nonOut, isOut]

theorem get_outlier_spec (s : Snapshot) (e : U64) :
    svc_timeline.get_outlier_loop s e 0#usize ⦃ r => absIdx s r = (s.pdus.val.find? (isOut e)).map some ⦄ := by
  unfold svc_timeline.get_outlier_loop
  apply WP.spec_mono (H5iAppLib.loop_search s.pdus.val (isOut e) (absIdx s) (fun _ x => some (some x)) none _ ?step 0#usize (by simp))
  · intro r hr; rw [hr, searchFrom_find]; simp
  case step => intro j hj; h5i_unfold_body; h5i_step [absIdx, nonOut, isOut]

def absState (s : Snapshot) : core.result.Result Usize Error → Option StateSet
  | .Ok i => s.states.val[i.val]?
  | .Err _ => none

theorem load_full_state_spec (s : Snapshot) (h : U64) :
    svc_accessor.load_full_state_loop s h 0#usize ⦃ r => absState s r = s.states.val.find? (hashP h) ⦄ := by
  unfold svc_accessor.load_full_state_loop
  apply WP.spec_mono (H5iAppLib.loop_search s.states.val (hashP h) (absState s) (fun _ x => some x) none _ ?step 0#usize (by simp))
  · intro r hr; exact H5iAppLib.search_find _ _ _ hr
  case step => intro j hj; h5i_unfold_body; h5i_step [absState, hashP]

theorem find_entry_spec (es : Slice StateEntry) (k : Kind) (key : U64) :
    svc_accessor.find_entry_loop es k key 0#usize ⦃ r => absOpt r = (es.val.find? (entryP k key)).map (·.event_id) ⦄ := by
  unfold svc_accessor.find_entry_loop
  apply WP.spec_mono (H5iAppLib.loop_search es.val (entryP k key) absOpt (fun _ x => some x.event_id) none _ ?step 0#usize (by simp))
  · intro r hr; rw [hr, searchFrom_find]; simp
  case step =>
    intro j hj; h5i_unfold_body; simp only [kind_eq_ok]
    h5i_step [absOpt, entryP]

theorem get_left_count_spec (s : Snapshot) (room u : U64) :
    svc_cache.get_left_count_loop s room u 0#usize ⦃ r => absOpt r = (s.left.val.find? (leftP u room)).map (·.count) ⦄ := by
  unfold svc_cache.get_left_count_loop
  apply WP.spec_mono (H5iAppLib.loop_search s.left.val (leftP u room) absOpt (fun _ x => some x.count) none _ ?step 0#usize (by simp))
  · intro r hr; rw [hr, searchFrom_find]; simp
  case step => intro j hj; h5i_unfold_body; h5i_step [absOpt, leftP]

theorem has_row_spec (rows : Slice UserRoom) (u room : U64) :
    svc_cache.has_row_loop rows u room 0#usize ⦃ b => b = rows.val.any (fun x => x.user = u ∧ x.room = room) ⦄ := by
  unfold svc_cache.has_row_loop
  h5i_search_any rows.val (fun (x : UserRoom) => decide (x.user = u ∧ x.room = room))

theorem user_is_ignored_spec (s : Snapshot) (sender u : U64) :
    api_message.user_is_ignored_loop s sender u 0#usize ⦃ b => b = s.ignored.val.any (fun x => x.user = u ∧ x.ignored = sender) ⦄ := by
  unfold api_message.user_is_ignored_loop
  h5i_search_any s.ignored.val (fun (x : Ignore) => decide (x.user = u ∧ x.ignored = sender))

theorem contains_u64_spec (v : Slice U64) (x : U64) :
    contains_u64_loop v x 0#usize ⦃ b => b = v.val.any (fun y => y = x) ⦄ := by
  unfold contains_u64_loop
  h5i_search_any v.val (fun (y : U64) => decide (y = x))


theorem timeline_find (s : Snapshot) (e : U64) :
    (timeline s).find? (fun p => p.event_id.val = e.val) = s.pdus.val.find? (nonOut e) := by
  unfold timeline; rw [List.find?_filter]; congr 1; funext p; simp [u64_val_eq, nonOut]

theorem outlier_find (s : Snapshot) (e : U64) :
    (s.pdus.val.filter (fun p => p.outlier)).find? (fun p => p.event_id.val = e.val) = s.pdus.val.find? (isOut e) := by
  rw [List.find?_filter]; congr 1; funext p; simp [u64_val_eq, isOut]

theorem eventOf_eq (s : Snapshot) (e : U64) :
    eventOf s e.val = (s.pdus.val.find? (nonOut e)).or
      (s.pdus.val.find? (isOut e)) := by
  unfold eventOf; rw [timeline_find, outlier_find]; rcases s.pdus.val.find? (nonOut e) with _ | p <;> rfl

theorem get_pdu_ok (s : Snapshot) (e : U64) (res) (h : svc_timeline.get_pdu s e = ok res) :
    absIdx s res = (eventOf s e.val).map some := by
  unfold svc_timeline.get_pdu at h
  rw [eventOf_eq]
  h5i_invert h
  · have := post_of_ok (get_non_outlier_spec s e) hr
    revert this
    rcases s.pdus.val.find? (nonOut e) with _ | p <;> simp [absIdx]
  · have h1 := post_of_ok (get_non_outlier_spec s e) hr
    have h2 := post_of_ok (get_outlier_spec s e) h
    rw [h2]; revert h1
    rcases s.pdus.val.find? (nonOut e) with _ | p <;> simp [absIdx]


def PssRes (s : Snapshot) (e : U64) : core.result.Result U64 Error → Prop
  | .Ok hs => ∃ p, eventOf s e.val = some p ∧ p.state = .Hash hs
  | .Err _ => ∀ p, eventOf s e.val = some p → p.state = .None

theorem pdu_shortstatehash_ok (s : Snapshot) (e : U64) (res) (h : svc_timeline.pdu_shortstatehash s e = ok res) :
    PssRes s e res := by
  unfold svc_timeline.pdu_shortstatehash at h
  h5i_invert h
  · have h1 := get_pdu_ok s e _ hr
    have h2 := vec_index_slice_ok_get? hp
    simp only [absIdx, h2] at h1
    unfold svc_timeline.state_of at h
    split at h <;> simp at h <;> subst h <;> simp only [PssRes]
    · intro q hq; rw [hq] at h1; simp at h1; subst h1; assumption
    · exact ⟨p, by cases h3 : eventOf s e.val <;> simp_all, by assumption⟩
  · have h1 := get_pdu_ok s e _ hr
    simp only [PssRes]; intro q hq; simp [absIdx, hq] at h1

theorem stateEntries_eq (s : Snapshot) (h : U64) :
    stateEntries s h.val = (s.states.val.find? (hashP h)).map (·.entries.val) := by
  unfold stateEntries; congr 2; funext x; simp [hashP, u64_val_eq]

theorem state_get_id_ok (s : Snapshot) (hs : U64) (k : Kind) (key : U64) (res)
    (h : svc_accessor.state_get_id s hs k key = ok res) :
    absOpt res = (stateEntries s hs.val).bind (fun es => (es.find? (entryP k key)).map (·.event_id)) := by
  unfold svc_accessor.state_get_id at h
  rw [stateEntries_eq]
  h5i_invert h
  · have h1 := post_of_ok (load_full_state_spec s hs) hr
    have h2 := vec_index_slice_ok_get? hss
    have h3 := post_of_ok (find_entry_spec _ k key) h
    simp only [absState, h2] at h1
    rw [h3, ← h1]; simp [alloc.vec.Vec.deref]
  · have h1 := post_of_ok (load_full_state_spec s hs) hr
    simp only [absState] at h1
    rw [← h1]; rfl


theorem stateLookup_eq (s : Snapshot) (hs : U64) (k : Kind) (key : U64) :
    stateLookup s hs.val k key.val =
      ((stateEntries s hs.val).bind (fun es => es.find? (entryP k key))).bind (fun en => eventOf s en.event_id.val) := by
  have hp : (fun en : StateEntry => decide (en.kind = k ∧ en.state_key.val = key.val)) = entryP k key := by
    funext en; simp [entryP, u64_val_eq]
  unfold stateLookup
  rcases stateEntries s hs.val with _ | es
  · rfl
  · simp only [Option.bind_some, hp]
    rcases es.find? (entryP k key) with _ | en <;> rfl

theorem state_get_ok (s : Snapshot) (hs : U64) (k : Kind) (key : U64) (res)
    (h : svc_accessor.state_get s hs k key = ok res) :
    absIdx s res = (stateLookup s hs.val k key.val).map some := by
  unfold svc_accessor.state_get at h
  rw [stateLookup_eq]
  h5i_invert h
  · have h1 := state_get_id_ok s hs k key _ hr
    rw [get_pdu_ok s _ _ h]
    revert h1
    rcases stateEntries s hs.val with _ | es
    · simp [absOpt]
    · simp only [Option.bind_some]
      rcases es.find? (entryP k key) with _ | en
      · simp [absOpt]
      · simp [absOpt]; intro h; rw [h]
  · have h1 := state_get_id_ok s hs k key _ hr
    revert h1
    rcases stateEntries s hs.val with _ | es
    · simp [absOpt, absIdx]
    · simp only [Option.bind_some]
      rcases es.find? (entryP k key) with _ | en
      · simp [absOpt, absIdx]
      · simp [absOpt]

theorem user_membership_ok (s : Snapshot) (hs u : U64) (m)
    (h : svc_accessor.user_membership s hs u = ok m) : m = membershipAt s hs.val u.val := by
  unfold svc_accessor.user_membership at h
  unfold membershipAt
  h5i_invert h
  all_goals have h1 := state_get_ok s hs .Member u _ hr
  · have h2 := vec_index_slice_ok_get? hp
    have h3 : stateLookup s hs.val .Member u.val = some p := by
      cases h3 : stateLookup s hs.val .Member u.val <;> simp_all [absIdx]
    rw [h3]; simp [hc]
  · have h2 := vec_index_slice_ok_get? hp
    have h3 : stateLookup s hs.val .Member u.val = some p := by
      cases h3 : stateLookup s hs.val .Member u.val <;> simp_all [absIdx]
    rw [h3]; simp [hc]
  · have h3 : stateLookup s hs.val .Member u.val = none := by
      cases h3 : stateLookup s hs.val .Member u.val <;> simp_all [absIdx]
    rw [h3]

theorem history_visibility_at_ok (s : Snapshot) (hs : U64) (v)
    (h : svc_accessor.history_visibility_at s hs = ok v) : v = visibilityAt s hs.val := by
  unfold svc_accessor.history_visibility_at at h
  unfold visibilityAt
  h5i_invert h
  all_goals have h1 := state_get_ok s hs .HistoryVisibility 0#u64 _ hr
  · have h2 := vec_index_slice_ok_get? hp
    have h3 : stateLookup s hs.val .HistoryVisibility 0 = some p := by
      cases h3 : stateLookup s hs.val .HistoryVisibility 0 <;> simp_all [absIdx]
    rw [h3]; simp [hc]
  · have h2 := vec_index_slice_ok_get? hp
    have h3 : stateLookup s hs.val .HistoryVisibility 0 = some p := by
      cases h3 : stateLookup s hs.val .HistoryVisibility 0 <;> simp_all [absIdx]
    rw [h3]; simp [hc]
  · have h3 : stateLookup s hs.val .HistoryVisibility 0 = none := by
      cases h3 : stateLookup s hs.val .HistoryVisibility 0 <;> simp_all [absIdx]
    rw [h3]

theorem user_was_joined_ok (s : Snapshot) (hs u : U64)
    (h : svc_accessor.user_was_joined s hs u = ok true) : membershipAt s hs.val u.val = .Join := by
  unfold svc_accessor.user_was_joined at h
  h5i_invert h
  all_goals (have := user_membership_ok s hs u _ hm; simp_all)

theorem user_was_invited_ok (s : Snapshot) (hs u : U64)
    (h : svc_accessor.user_was_invited s hs u = ok true) :
    membershipAt s hs.val u.val = .Join ∨ membershipAt s hs.val u.val = .Invite := by
  unfold svc_accessor.user_was_invited at h
  h5i_invert h
  all_goals (have := user_membership_ok s hs u _ hm; first | (subst this; revert hb; cases membershipAt s hs.val u.val <;> simp_all) | (rw [← this]; simp))


theorem toSigned_eq (l : U64) : Int.bmod (l.val : Int) (2 ^ 64) = toSigned l.val := by
  have hl : l.val < 2 ^ 64 := by scalar_tac
  unfold toSigned Int.bmod
  have : ((l.val : Int) % (2 ^ 64 : Nat)) = l.val := Int.emod_eq_of_lt (by omega) (by omega)
  simp only [this]
  split <;> split <;> omega

theorem countOf_eq (s : Snapshot) (e : U64) :
    countOf s e.val = (s.pdus.val.find? (nonOut e)).map (fun p => p.count.val) := by
  unfold countOf; rw [timeline_find]

theorem get_pdu_count_ok (s : Snapshot) (e : U64) (c : I64)
    (h : svc_timeline.get_pdu_count s e = ok (.Ok c)) : countOf s e.val = some c.val := by
  unfold svc_timeline.get_pdu_count svc_timeline.get_pdu_id at h
  rw [countOf_eq]
  h5i_invert h
  obtain ⟨sh, c'⟩ := p
  simp at h; subst h
  h5i_invert hr
  have h1 := post_of_ok (get_non_outlier_spec s e) hr_1
  have h2 := vec_index_slice_ok_get? hp
  simp only [absIdx, h2] at h1
  rw [← hr.2]; revert h1
  rcases s.pdus.val.find? (nonOut e) with _ | q <;> simp
  intro h; rw [h]

theorem get_left_count_ok (s : Snapshot) (room u : U64) (l : U64)
    (h : svc_cache.get_left_count s room u = ok (.Ok l)) : leftCount s u.val room.val = some l.val := by
  have h1 := post_of_ok (get_left_count_spec s room u) h
  unfold leftCount
  have hp : (fun x : LeftRow => decide (x.user.val = u.val ∧ x.room.val = room.val)) = leftP u room := by
    funext x; simp [leftP, u64_val_eq]
  rw [hp]
  revert h1
  rcases s.left.val.find? (leftP u room) with _ | x <;> simp [absOpt]
  intro h; rw [h]

theorem has_row_ok (rows : Slice UserRoom) (u room : U64)
    (h : svc_cache.has_row rows u room = ok true) : ∃ x ∈ rows.val, x.user.val = u.val ∧ x.room.val = room.val := by
  have h1 := post_of_ok (has_row_spec rows u room) h
  simp at h1
  obtain ⟨x, hx, h2, h3⟩ := h1
  exact ⟨x, hx, by rw [h2], by rw [h3]⟩


theorem user_shared_history_ok (s : Snapshot) (hs room e u : U64)
    (h : svc_accessor.user_shared_history s hs room e u = ok true) :
    Joined s u.val room.val ∨ membershipAt s hs.val u.val = .Join ∨
      (OnceJoined s u.val room.val ∧ ∃ l c, leftCount s u.val room.val = some l ∧ countOf s e.val = some c ∧ c ≤ toSigned l) := by
  unfold svc_accessor.user_shared_history at h
  h5i_invert h
  · subst hc; left; unfold svc_cache.is_joined at hb; dsimp only at hb
    simpa [Joined, alloc.vec.Vec.deref] using has_row_ok _ _ _ hb
  · subst hc_1; right; left; exact user_was_joined_ok s hs u hb1
  · subst hc_2; right; right
    unfold svc_cache.once_joined at hb2; dsimp only at hb2
    have hj := has_row_ok _ _ _ hb2; simp only [alloc.vec.Vec.deref] at hj
    refine ⟨by simpa [OnceJoined] using hj, a.val, event_count.val, get_left_count_ok s room u a hr, get_pdu_count_ok s e _ hr1, ?_⟩
    simp [lift] at hi; subst hi
    simp at h
    have := toSigned_eq a
    have h3 : event_count.val ≤ (UScalar.hcast IScalarTy.I64 a).val := by scalar_tac
    rw [UScalar.hcast_val_eq] at h3
    have h5 : (2:Nat) ^ IScalarTy.I64.numBits = 2 ^ 64 := rfl
    rw [h5, this] at h3; exact h3


theorem user_can_see_event_ok (s : Snapshot) (u room e : U64)
    (h : svc_accessor.user_can_see_event s u room e = ok true) : Visible s u.val room.val e.val := by
  unfold svc_accessor.user_can_see_event at h
  h5i_invert h
  all_goals have h1 := pdu_shortstatehash_ok s e _ hr
  all_goals simp only [PssRes] at h1
  all_goals try (obtain ⟨p, hp, hst⟩ := h1; have h2 := history_visibility_at_ok s _ _ hhv; unfold Visible; rw [hp]; simp only [hst]; rw [← h2])
  · trivial
  · exact user_shared_history_ok s _ room e u h
  · exact user_was_invited_ok s _ u h
  · exact user_was_joined_ok s _ u h
  · exact user_shared_history_ok s _ room e u h
  · unfold Visible
    rcases hp : eventOf s e.val with _ | p
    · trivial
    · simp only [h1 p hp]


theorem eventOf_id {s : Snapshot} {ev : U64} {p : Pdu}
    (h : eventOf s ev.val = some p) : p.event_id = ev := by
  unfold eventOf at h
  split at h
  · rename_i q hq
    simp only [Option.some.injEq] at h
    subst p
    have hi := List.find?_some hq
    scalar_tac
  · have hi := List.find?_some h
    scalar_tac


theorem room_members_ok (s : Snapshot) (room : U64) (ms : alloc.vec.Vec U64)
    (h : svc_cache.room_members s room = ok ms) :
    ∀ m ∈ ms.val, Joined s m.val room.val := by
  unfold svc_cache.room_members svc_cache.room_members_loop at h
  let inv := fun st : alloc.vec.Vec U64 × Usize => ∀ m ∈ st.1.val, Joined s m.val room.val
  refine loop_idx_ok (fun st => svc_cache.room_members_loop.body s room st.1 st.2)
    Prod.snd s.joined.val.length inv
    (fun out => ∀ m ∈ out.val, Joined s m.val room.val) ?_
    (alloc.vec.Vec.new U64, 0#usize) ms (by simp [inv, vec_new_val]) (by simp) h
  rintro ⟨out, i⟩ r hI hbound hr
  unfold svc_cache.room_members_loop.body at hr
  h5i_invert hr
  all_goals simp only [Prod.fst, Prod.snd] at *
  all_goals try (simp only [alloc.vec.Vec.push, bind_tc_ok, bind_ok] at hout1)
  all_goals try h5i_invert hout1
  all_goals try have hurmem := vec_index_ok_mem hur
  all_goals h5i_ok_facts
  all_goals try h5i_arith
  all_goals simp_all [inv, Joined]
  all_goals first
    | omega
    | (intro m hm; rcases hm with hm | hm
       · exact hI m hm
       · subst m; exact ⟨ur, vec_index_ok_mem hur, rfl, by scalar_tac⟩)

theorem any_joined_ok (s : Snapshot) (hash origin : U64) (ms : Slice U64)
    (h : svc_accessor.any_member_was s hash origin ms true = ok true) :
    ∃ m ∈ ms.val, m.val / 1000 = origin.val ∧ membershipAt s hash.val m.val = .Join := by
  unfold svc_accessor.any_member_was svc_accessor.any_member_was_loop at h
  refine loop_true_witness _ (fun _ => True) (fun i : Usize => ms.val.length - i.val)
    (∃ m ∈ ms.val, m.val / 1000 = origin.val ∧ membershipAt s hash.val m.val = .Join)
    ?_ 0#usize trivial h
  intro i r _ hr
  unfold svc_accessor.any_member_was_loop.body at hr
  h5i_invert hr
  all_goals try (intro hb; simp at hb)
  all_goals try h5i_arith
  all_goals
    have hm := slice_index_ok_mem hm
    rw [hc_2] at hok1
    have hmem := user_was_joined_ok s hash m hok1
    have hserver := div_ok_val hi2
    simp only [server_name] at hi2
    exact ⟨m, hm, by scalar_tac, hmem⟩

theorem server_sees_joined_only (s : Snapshot) (origin room ev : U64) (p : Pdu) (hp : U64)
    (h : transition s ⟨0#u64, .ServerCanSee origin room ev⟩ = ok (.Ok (.CanSee true)))
    (he : eventOf s ev.val = some p) (hs : p.state = .Hash hp) (hj : visibilityAt s hp.val = .Joined) :
    ∃ m, Joined s m room.val ∧ m / 1000 = origin.val ∧ membershipAt s hp.val m = .Join := by
  unfold transition svc_accessor.server_can_see_event at h
  h5i_invert h
  simp only [Reply.CanSee.injEq] at h
  subst b
  h5i_invert hb
  all_goals have hstate := pdu_shortstatehash_ok s ev _ hr
  all_goals simp only [PssRes] at hstate
  all_goals try (obtain ⟨q, hq, hhash⟩ := hstate; rw [he] at hq; cases hq; rw [hs] at hhash; cases hhash)
  all_goals try (have hvis := history_visibility_at_ok s hp _ hhv; rw [hj] at hvis; subst_vars)
  all_goals try contradiction
  all_goals try (have hn := hstate p he; rw [hs] at hn; contradiction)
  have hall := room_members_ok s room members hmembers
  obtain ⟨m, hm, hserver, hmem⟩ := any_joined_ok s hp origin (alloc.vec.Vec.deref members) hb
  exact ⟨m.val, hall m (by simpa [alloc.vec.Vec.deref] using hm), hserver, hmem⟩

end tuwunel_kernel.Solution
