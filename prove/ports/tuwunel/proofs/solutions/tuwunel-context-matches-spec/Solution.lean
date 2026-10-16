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


theorem contains_u64_ok (v : Slice U64) (x : U64) (b) (h : contains_u64 v x = ok b) :
    b = v.val.any (fun y => y = x) := by
  have := post_of_ok (contains_u64_spec v x) h; exact this

theorem len_bne_zero {α} (v : alloc.vec.Vec α) : (v.len != 0#usize) = decide (v.val ≠ []) := by
  have : v.len = 0#usize ↔ v.val = [] := by
    constructor
    · intro h; have := congrArg UScalar.val h; simpa using this
    · intro h; apply UScalar.eq_of_val_eq; simp [h]
  by_cases h : v.val = [] <;> simp_all [bne]

theorem forbidden_ok (c : Config) (srv : U64)
    (h : filters.is_forbidden_remote_server_name c srv = ok false) : ¬ Forbidden c srv.val := by
  unfold filters.is_forbidden_remote_server_name at h
  unfold Forbidden
  h5i_invert h
  all_goals (try have e1 := contains_u64_ok _ _ _ hb)
  all_goals (try have e2 := contains_u64_ok _ _ _ hb1)
  all_goals try simp only [len_bne_zero] at *
  all_goals simp_all [alloc.vec.Vec.deref, ← u64_val_eq]


theorem user_is_ignored_ok (s : Snapshot) (sender u : U64)
    (h : api_message.user_is_ignored s sender u = ok false) :
    ¬ ∃ i ∈ s.ignored.val, i.user.val = u.val ∧ i.ignored.val = sender.val := by
  have := post_of_ok (user_is_ignored_spec s sender u) h
  simp_all [u64_val_eq]

theorem is_ignored_message_type_ok (k : Kind) (b) (h : api_message.is_ignored_message_type k = ok b) :
    b = messageLike k := by
  cases k <;> simp [api_message.is_ignored_message_type, messageLike] at h ⊢ <;> cases b <;> simp_all

theorem server_name_ok (x i : U64) (h : server_name x = ok i) : i.val = x.val / 1000 := by
  unfold server_name at h
  have := div_ok_val h; simpa using this

theorem is_ignored_pdu_ok (s : Snapshot) (p : Pdu) (u : U64)
    (h : api_message.is_ignored_pdu s p u = ok false) : ¬ Ignored s u.val p := by
  unfold api_message.is_ignored_pdu at h
  unfold Ignored
  cases hpk : p.kind <;> simp [hpk, api_message.is_ignored_message_type, messageLike] at h ⊢
  all_goals
    h5i_invert h
    have h1 := server_name_ok _ _ hi
    simp only [Bool.not_eq_true] at hc; subst hc
    have h2 := forbidden_ok _ _ hignored_server
    have h3 := user_is_ignored_ok _ _ _ h
    rw [h1] at h2
    exact ⟨h2, fun x hx hu he => h3 ⟨x, hx, hu, he⟩⟩


theorem passes_ok (s : Snapshot) (u : U64) (f : Filter) (x : U64) (c : I64) (j : Usize)
    (h : api_message.passes s u f x c j false = ok true) :
    ∃ p, s.pdus.val[j.val]? = some p ∧ ¬ Ignored s u.val p ∧ Visible s u.val p.room.val p.event_id.val := by
  unfold api_message.passes api_message.event_filters api_message.ignored_filter api_message.visibility_filter at h
  h5i_invert h
  subst hc_2
  h5i_invert hb_1
  have e1 := vec_index_slice_ok_get? hp1
  have e2 := vec_index_slice_ok_get? hp1_1
  rw [e1] at e2; simp at e2; subst e2
  refine ⟨_, e1, is_ignored_pdu_ok _ _ _ ?_, user_can_see_event_ok _ _ _ _ h⟩
  revert hb_1 hb_1_1; cases b_1 <;> simp


theorem push_ok {α} (v : alloc.vec.Vec α) (x : α) (w) (h : alloc.vec.Vec.push v x = ok w) :
    w.val = v.val ++ [x] := by
  unfold alloc.vec.Vec.push at h
  simp only at h
  split at h
  · simp at h; subst h; simp
  · simp at h

def Good (s : Snapshot) (room : U64) (j : Usize) : Prop :=
  ∃ q, s.pdus.val[j.val]? = some q ∧ q.outlier = false ∧ q.room = room

theorem in_timeline_ok (p : Pdu) (room : U64) (h : svc_timeline.in_timeline p room = ok true) :
    p.outlier = false ∧ p.room = room := by
  unfold svc_timeline.in_timeline at h
  split at h <;> simp_all

theorem pdus_loop_ok (s : Snapshot) (room : U64) (fr : I64) (out : alloc.vec.Vec Usize) (i : Usize) (v)
    (h : svc_timeline.pdus_loop s room fr out i = ok v) (hout : ∀ j ∈ out.val, Good s room j) :
    ∀ j ∈ v.val, Good s room j := by
  unfold svc_timeline.pdus_loop at h
  refine loop_ok _ (fun x => ∀ j ∈ x.1.val, Good s room j) (fun v => ∀ j ∈ v.val, Good s room j)
    (fun x => s.pdus.val.length - x.2.val) ?_ _ _ hout h
  rintro ⟨out, i⟩ r hinv hr
  simp only at hr hinv
  unfold svc_timeline.pdus_loop.body at hr
  h5i_invert hr
  · simp only
    have hi2v := add_ok_val hi2
    have hidx := vec_index_slice_ok_get? hp
    refine ⟨?_, ?_⟩
    · intro j hj
      by_cases hb' : b = true
      · subst hb'
        have hg := in_timeline_ok _ _ hb
        simp only [if_true] at hout1
        split at hout1
        · rw [push_ok _ _ _ hout1] at hj
          simp at hj
          rcases hj with hj | rfl
          · exact hinv j hj
          · exact ⟨p, hidx, hg⟩
        · simp at hout1; subst hout1; exact hinv j hj
      · simp [hb'] at hout1; subst hout1; exact hinv j hj
    · have : i.val < s.pdus.val.length := by scalar_tac
      simp at hi2v; omega
  · exact hinv


theorem pdus_rev_loop_ok (s : Snapshot) (room : U64) (un : I64) (out : alloc.vec.Vec Usize) (i : Usize) (v)
    (h : svc_timeline.pdus_rev_loop s.pdus room un out i = ok v) (hout : ∀ j ∈ out.val, Good s room j) :
    ∀ j ∈ v.val, Good s room j := by
  unfold svc_timeline.pdus_rev_loop at h
  refine loop_ok _ (fun x => ∀ j ∈ x.1.val, Good s room j) (fun v => ∀ j ∈ v.val, Good s room j)
    (fun x => x.2.val) ?_ _ _ hout h
  rintro ⟨out, i⟩ r hinv hr
  simp only at hr hinv
  unfold svc_timeline.pdus_rev_loop.body at hr
  h5i_invert hr
  all_goals simp only
  all_goals try (have hi1v := sub_ok_val hi1)
  all_goals try (have hidx := vec_index_slice_ok_get? hp)
  · subst hc_1; have hg := in_timeline_ok _ _ hb
    refine ⟨?_, by simp at hi1v; omega⟩
    intro j hj; rw [push_ok _ _ _ hout1] at hj; simp at hj
    rcases hj with hj | rfl
    · exact hinv j hj
    · exact ⟨p, hidx, hg⟩
  · exact ⟨hinv, by simp at hi1v; omega⟩
  · exact ⟨hinv, by simp at hi1v; omega⟩
  · exact hinv

def ScanInv (s : Snapshot) (u : U64) (it : Slice Usize) (f : Filter) (x : U64) (evs : alloc.vec.Vec (I64 × Usize)) : Prop :=
  ∀ ce ∈ evs.val, ce.2 ∈ it.val ∧ api_message.passes s u f x ce.1 ce.2 false = ok true

theorem scan_loop_ok (s : Snapshot) (u : U64) (it : Slice Usize) (t : Option I64) (dir : Dir) (lim : U64)
    (f : Filter) (x : U64) (evs : alloc.vec.Vec (I64 × Usize)) (sc : Option I64) (dn : Bool) (i : Usize) (res)
    (h : api_message.scan_loop s u it t dir lim f x false evs sc dn i = ok res) (hinv : ScanInv s u it f x evs) :
    ScanInv s u it f x res.1 := by
  unfold api_message.scan_loop at h
  refine loop_ok _ (fun y => ScanInv s u it f x y.1) (fun y => ScanInv s u it f x y.1)
    (fun y => (if y.2.2.1 then 0 else 1) + 2 * (it.val.length - y.2.2.2.val)) ?_ _ _ hinv h
  rintro ⟨evs, sc, dn, i⟩ r hinv hr
  simp only at hr hinv
  unfold api_message.scan_loop.body at hr
  h5i_invert hr
  all_goals simp only
  · exact hinv
  · simp only [hc, if_true]; exact ⟨hinv, by simp⟩
  · simp only [hc, Bool.false_eq_true, if_false]
    have hi4v := add_ok_val hi4
    have hlt : i.val < it.val.length := by scalar_tac
    refine ⟨?_, by simp at hi4v; omega⟩
    have hmem := slice_index_ok_mem hp
    intro ce hce
    by_cases hb1' : b1 = true
    · subst hb1'; simp only [if_true] at hevents1
      rw [push_ok _ _ _ hevents1] at hce; simp at hce
      rcases hce with hce | rfl
      · exact hinv ce hce
      · exact ⟨hmem, hb1⟩
    · simp [hb1'] at hevents1; subst hevents1; exact hinv ce hce
  · exact hinv
  · exact hinv


def IdsInv (s : Snapshot) (evs : Slice (I64 × Usize)) (out : alloc.vec.Vec U64) : Prop :=
  ∀ e ∈ out.val, ∃ ce ∈ evs.val, ∃ q, s.pdus.val[ce.2.val]? = some q ∧ q.event_id = e

theorem event_ids_loop_ok (s : Snapshot) (evs : Slice (I64 × Usize)) (out : alloc.vec.Vec U64) (i : Usize) (v)
    (h : api_message.event_ids_loop s evs out i = ok v) (hinv : IdsInv s evs out) : IdsInv s evs v := by
  unfold api_message.event_ids_loop at h
  refine loop_ok _ (fun y => IdsInv s evs y.1) (fun y => IdsInv s evs y)
    (fun y => evs.val.length - y.2.val) ?_ _ _ hinv h
  rintro ⟨out, i⟩ r hinv hr
  simp only at hr hinv
  unfold api_message.event_ids_loop.body at hr
  h5i_invert hr
  · obtain ⟨c0, j⟩ := x
    change (do let p ← alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice Pdu) s.pdus j; let out1 ← out.push p.event_id; let i3 ← i + 1#usize; ok (ControlFlow.cont (out1, i3))) = ok r at hr
    h5i_invert hr
    simp only
    have hi3v := add_ok_val hi3
    have hlt : i.val < evs.val.length := by scalar_tac
    refine ⟨?_, by simp at hi3v; omega⟩
    have hmem := slice_index_ok_mem hx
    have hidx := vec_index_slice_ok_get? hp
    intro e he; rw [push_ok _ _ _ hout1] at he; simp at he
    rcases he with he | rfl
    · exact hinv e he
    · exact ⟨(c0, j), hmem, p, hidx, rfl⟩
  · exact hinv


def ChunkOk (s : Snapshot) (u room : U64) (chunk : alloc.vec.Vec U64) : Prop :=
  ∀ e ∈ chunk.val, ∃ q, q ∈ s.pdus.val ∧ q.outlier = false ∧ q.room = room ∧ q.event_id = e ∧
    ¬ Ignored s u.val q ∧ Visible s u.val q.room.val q.event_id.val

theorem chunk_of (s : Snapshot) (u room : U64) (it : Slice Usize) (f : Filter) (x : U64)
    (evs : alloc.vec.Vec (I64 × Usize)) (evs' : Slice (I64 × Usize)) (chunk : alloc.vec.Vec U64)
    (hids : IdsInv s evs' chunk) (hscan : ScanInv s u it f x evs) (hevs : evs'.val = evs.val)
    (hgood : ∀ j ∈ it.val, Good s room j) : ChunkOk s u room chunk := by
  intro e he
  obtain ⟨ce, hce, q, hq, hqe⟩ := hids e he
  rw [hevs] at hce
  obtain ⟨hmem, hpass⟩ := hscan ce hce
  obtain ⟨p, hp, hign, hvis⟩ := passes_ok _ _ _ _ _ _ hpass
  obtain ⟨q', hq', hout, hroom⟩ := hgood _ hmem
  rw [hq] at hp hq'
  simp at hp hq'
  subst hp hq'
  exact ⟨q, List.mem_of_getElem? hq, hout, hroom, hqe, hign, hvis⟩

theorem pdus_ok (s : Snapshot) (room : U64) (fr : I64) (v : alloc.vec.Vec Usize)
    (h : svc_timeline.pdus s room fr = ok (.Ok v)) : ∀ j ∈ v.val, Good s room j := by
  unfold svc_timeline.pdus at h
  h5i_invert h
  exact pdus_loop_ok s room fr _ _ v hout (by simp)

theorem pdus_rev_ok (s : Snapshot) (room : U64) (fr : I64) (v : alloc.vec.Vec Usize)
    (h : svc_timeline.pdus_rev s room fr = ok (.Ok v)) : ∀ j ∈ v.val, Good s room j := by
  unfold svc_timeline.pdus_rev at h
  h5i_invert h
  exact pdus_rev_loop_ok s room fr _ _ v hout (by simp)


theorem collect_half_ok (s : Snapshot) (u : U64) (f : Filter) (short : U64)
    (it : Slice Usize) (take : U64) (out : alloc.vec.Vec (I64 × Usize)) (i : Usize) (v)
    (h : api_context.collect_timeline_half_loop s u f short false it take out i = ok v)
    (hinv : ScanInv s u it f short out) : ScanInv s u it f short v := by
  unfold api_context.collect_timeline_half_loop at h
  refine loop_ok _ (fun st => ScanInv s u it f short st.1) (ScanInv s u it f short)
    (fun st => it.val.length - st.2.val) ?_ _ _ hinv h
  rintro ⟨out, i⟩ r hinv hr
  unfold api_context.collect_timeline_half_loop.body at hr
  h5i_invert hr
  all_goals simp only
  · have hstep := add_ok_val hi4
    have hlt : i.val < it.val.length := by scalar_tac
    refine ⟨?_, by simp at hstep; omega⟩
    have hmem := slice_index_ok_mem hp
    intro ce hce
    by_cases hb' : b = true
    · subst hb'; simp only [if_true] at hout1
      rw [push_ok _ _ _ hout1] at hce
      simp only [List.mem_append, List.mem_singleton] at hce
      rcases hce with hce | rfl
      · exact hinv ce hce
      · exact ⟨hmem, hb⟩
    · simp [hb'] at hout1; subst hout1; exact hinv ce hce
  · exact hinv
  · exact hinv

theorem eventOf_in_timeline (s : Snapshot) (ev : U64) (q : Pdu)
    (he : eventOf s ev.val = some q) (hc : ∃ c, countOf s ev.val = some c) : q ∈ timeline s := by
  obtain ⟨c, hc⟩ := hc
  unfold countOf at hc
  cases hh : (timeline s).find? (fun p => p.event_id.val = ev.val) with
  | none => simp [hh] at hc
  | some p =>
    unfold eventOf at he
    rw [hh] at he
    simp only [Option.some.injEq] at he
    subst q
    exact List.mem_of_find?_eq_some hh

theorem resolve_base_ok (s : Snapshot) (u room ev : U64) (x : I64 × Usize)
    (h : api_context.resolve_base_event s room ev u false = ok (.Ok x)) :
    ∃ q, s.pdus.val[x.2.val]? = some q ∧ q.event_id = ev ∧ q ∈ timeline s ∧
      q.room = room ∧ Visible s u.val room.val ev.val := by
  unfold api_context.resolve_base_event at h
  h5i_invert h
  obtain ⟨short, count⟩ := p
  change ok (core.result.Result.Ok (count, a)) = ok (core.result.Result.Ok x) at h
  simp only [ok.injEq, core.result.Result.Ok.injEq] at h
  subst x
  have hidx := vec_index_slice_ok_get? hp_1
  have hget := get_pdu_ok s ev _ hr1
  simp only [absIdx, hidx] at hget
  have he : eventOf s ev.val = some p_1 := by
    cases he : eventOf s ev.val <;> simp_all
  have hc : svc_timeline.get_pdu_count s ev = ok (.Ok count) := by
    simp [svc_timeline.get_pdu_count, hr]
  have htl := eventOf_in_timeline s ev p_1 he ⟨count.val, get_pdu_count_ok s ev count hc⟩
  exact ⟨p_1, hidx, by scalar_tac, htl, by scalar_tac, user_can_see_event_ok s u room ev (by simpa [hc_2] using hvisible)⟩

theorem context_visible (s : Snapshot) (u room ev lim : U64) (f : Filter)
    (base : U64) (st en : I64) (before after state : alloc.vec.Vec U64)
    (h : transition s ⟨u, .Context room ev lim f⟩ = ok (.Ok (.Context base st en before after state)))
    (hk : Keys s) :
    base = ev ∧ ∀ e ∈ base :: (before.val ++ after.val), InRoom s room.val e.val ∧ Visible s u.val room.val e.val := by
  unfold transition api_context.get_context_route api_context.event_context at h
  h5i_invert h
  obtain ⟨base_count, base_pdu⟩ := x
  change (do let r1 ← svc_timeline.get_shortroomid s room; _) = _ at h
  h5i_invert h
  all_goals
    obtain ⟨s3, state_at⟩ := x
    have hs3 : s3 = s := by
      h5i_invert hx
      all_goals try exact hx.1.symm
      all_goals
        obtain ⟨c, j⟩ := x
        simp only [Aeneas.Std.uncurry] at hx
        h5i_invert hx
        exact hx.1.symm
    subst s3
    simp only [Aeneas.Std.uncurry] at h
    h5i_invert h
  all_goals
    simp only [Reply.Context.injEq] at h
    obtain ⟨hbase, -, -, hbefore, hafter, -⟩ := h
    subst before
    subst after
    subst base
    obtain ⟨q, hq, hqe, hqt, hqr, hqv⟩ := resolve_base_ok s u room ev (base_count, base_pdu) hr
    have hpi := vec_index_slice_ok_get? hp
    rw [hpi] at hq
    simp only [Option.some.injEq] at hq
    subst q
    have hgood_before : ∀ j ∈ before_it.val, Good s room j := by
      revert hbefore_it
      cases r2 <;> simp
      · intro hh; subst before_it; exact pdus_rev_ok _ _ _ _ hr2
      · intro hh; subst before_it; simp
    have hgood_after : ∀ j ∈ after_it.val, Good s room j := by
      revert hafter_it
      cases r3 <;> simp
      · intro hh; subst after_it; exact pdus_ok _ _ _ _ hr3
      · intro hh; subst after_it; simp
    unfold api_context.collect_timeline_half at hevents_before hevents_after
    have hscan_before := collect_half_ok s u f a _ i _ _ _ hevents_before (by simp [ScanInv])
    have hscan_after := collect_half_ok s u f a _ i2 _ _ _ hevents_after (by simp [ScanInv])
    unfold api_message.event_ids at hv1 hv2
    have hids_before := event_ids_loop_ok s _ _ _ _ hv1 (by simp [IdsInv])
    have hids_after := event_ids_loop_ok s _ _ _ _ hv2 (by simp [IdsInv])
    have hchunk_before := chunk_of s u room _ f a events_before _ v1 hids_before hscan_before
      (by simp [alloc.vec.Vec.deref]) (by simpa [alloc.vec.Vec.deref] using hgood_before)
    have hchunk_after := chunk_of s u room _ f a events_after _ v2 hids_after hscan_after
      (by simp [alloc.vec.Vec.deref]) (by simpa [alloc.vec.Vec.deref] using hgood_after)
    refine ⟨hqe, ?_⟩
    intro e he
    simp only [List.mem_cons, List.mem_append] at he
    rcases he with rfl | he | he
    · exact ⟨⟨p, hqt, rfl, congrArg UScalar.val hqr⟩, by simpa [hqe] using hqv⟩
    all_goals
      obtain ⟨q, hq, hout, hroom, hid, hign, hvis⟩ := (by first | exact hchunk_before e he | exact hchunk_after e he)
      have hqt : q ∈ timeline s := by simp [timeline, hq, hout]
      exact ⟨⟨q, hqt, by rw [hid], by rw [hroom]⟩, by simpa [hroom, hid] using hvis⟩




theorem context_matches_spec (s : Snapshot) (u room ev lim : U64) (f : Filter)
    (base : U64) (st en : I64) (before after state : alloc.vec.Vec U64)
    (h : transition s ⟨u, .Context room ev lim f⟩ = ok (.Ok (.Context base st en before after state)))
    (hk : Keys s) :
    ∀ e ∈ base :: (before.val ++ after.val), ∀ p hp, eventOf s e.val = some p → p.state = .Hash hp →
      (visibilityAt s hp.val = .Joined ∨ visibilityAt s hp.val = .Invited) → MatrixVisible s u.val room.val e.val := by
  have hvis := (context_visible s u room ev lim f base st en before after state h hk).2
  intro e he p hp hep hstate hv
  have hvise := (hvis e he).2
  unfold Visible at hvise
  simp only [hep, hstate] at hvise
  refine ⟨p, hp, hep, hstate, ?_⟩
  rcases hv with hj | hi
  · rw [hj] at hvise
    exact Or.inr (Or.inl hvise)
  · rw [hi] at hvise
    rcases hvise with hjoin | hinvite
    · exact Or.inr (Or.inl hjoin)
    · exact Or.inr (Or.inr (Or.inr ⟨hi, hinvite⟩))

end tuwunel_kernel.Solution

