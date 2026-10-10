import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result tuwunel_kernel tuwunel_kernel.Spec
open H5iAppLib hiding lit

namespace tuwunel_kernel.Verified.TuwunelStateReadsNeedMembership

theorem u64_eq_iff (a b : U64) : a = b ↔ a.val = b.val := by
  constructor
  · rintro rfl; rfl
  · intro h; scalar_tac

@[step] theorem kind_eq_spec (a b : Kind) : kind_eq a b ⦃ r => r = decide (a = b) ⦄ := by
  cases a <;> cases b <;> simp [kind_eq]

theorem has_row_spec (rows : Slice UserRoom) (u room : U64) :
    svc_cache.has_row rows u room ⦃ b => b = rows.val.any (fun x => x.user = u ∧ x.room = room) ⦄ := by
  unfold svc_cache.has_row svc_cache.has_row_loop
  h5i_search_any rows.val (fun x : UserRoom => decide (x.user = u ∧ x.room = room))

def roomHash (x : Room) : core.result.Result U64 Error :=
  match x.state with
  | .None => .Err .NotFound
  | .Hash h => .Ok h

theorem get_room_shortstatehash_spec (s : Snapshot) (room : U64) :
    svc_timeline.get_room_shortstatehash s room ⦃ r => r =
      ((s.rooms.val.find? (fun x => x.id = room)).map roomHash).getD (.Err .NotFound) ⦄ := by
  unfold svc_timeline.get_room_shortstatehash svc_timeline.get_room_shortstatehash_loop
  apply WP.spec_mono (loop_search s.rooms.val (fun x => decide (x.id = room)) id
    (fun _ x => roomHash x) (.Err .NotFound) _ ?step 0#usize (by simp))
  · intro r hr; simp only [id] at hr; rw [hr, searchFrom_findD]; simp
  case step => intro j hj; h5i_unfold_body; h5i_step [roomHash]

def idxAbs {α} (l : List α) (r : core.result.Result Usize Error) : Option (Option α) :=
  match r with
  | .Ok i => some l[i.val]?
  | .Err _ => none

theorem load_full_state_spec (s : Snapshot) (h : U64) :
    svc_accessor.load_full_state s h ⦃ r => idxAbs s.states.val r = (s.states.val.find? (fun x => x.hash = h)).map some ⦄ := by
  unfold svc_accessor.load_full_state svc_accessor.load_full_state_loop
  apply WP.spec_mono (loop_search s.states.val (fun x => decide (x.hash = h)) (idxAbs s.states.val)
    (fun _ x => some (some x)) none _ ?step 0#usize (by simp))
  · intro r hr; rw [hr, searchFrom_find]; simp
  case step => intro j hj; h5i_unfold_body; h5i_step [idxAbs]

theorem get_non_outlier_spec (s : Snapshot) (e : U64) :
    svc_timeline.get_non_outlier s e ⦃ r => idxAbs s.pdus.val r =
      (s.pdus.val.find? (fun x => !x.outlier && decide (x.event_id = e))).map some ⦄ := by
  unfold svc_timeline.get_non_outlier svc_timeline.get_non_outlier_loop
  apply WP.spec_mono (loop_search s.pdus.val (fun x => !x.outlier && decide (x.event_id = e)) (idxAbs s.pdus.val)
    (fun _ x => some (some x)) none _ ?step 0#usize (by simp))
  · intro r hr; rw [hr, searchFrom_find]; simp
  case step => intro j hj; h5i_unfold_body; h5i_step [idxAbs]

theorem get_outlier_spec (s : Snapshot) (e : U64) :
    svc_timeline.get_outlier s e ⦃ r => idxAbs s.pdus.val r =
      (s.pdus.val.find? (fun x => x.outlier && decide (x.event_id = e))).map some ⦄ := by
  unfold svc_timeline.get_outlier svc_timeline.get_outlier_loop
  apply WP.spec_mono (loop_search s.pdus.val (fun x => x.outlier && decide (x.event_id = e)) (idxAbs s.pdus.val)
    (fun _ x => some (some x)) none _ ?step 0#usize (by simp))
  · intro r hr; rw [hr, searchFrom_find]; simp
  case step => intro j hj; h5i_unfold_body; h5i_step [idxAbs]

theorem find_entry_spec (es : Slice StateEntry) (k : Kind) (key : U64) :
    svc_accessor.find_entry es k key ⦃ r => r =
      ((es.val.find? (fun x => decide (x.kind = k ∧ x.state_key = key))).map
        (fun x => core.result.Result.Ok x.event_id)).getD (.Err .NotFound) ⦄ := by
  unfold svc_accessor.find_entry svc_accessor.find_entry_loop
  apply WP.spec_mono (loop_search es.val (fun x => decide (x.kind = k ∧ x.state_key = key)) id
    (fun _ x => core.result.Result.Ok x.event_id) (.Err .NotFound) _ ?step 0#usize (by simp))
  · intro r hr; simp only [id] at hr; rw [hr, searchFrom_findD]; simp
  case step => intro j hj; h5i_unfold_body; h5i_step

theorem find?_u64 {α} (l : List α) (f : α → U64) (e : U64) (q : α → Bool) :
    l.find? (fun x => q x && decide (f x = e)) = l.find? (fun x => decide (q x = true ∧ decide ((f x).val = e.val) = true)) := by
  congr 1; funext x; simp [u64_eq_iff]

theorem idxAbs_ok {α} {l : List α} {i : Usize} {o : Option α} (h : idxAbs l (.Ok i) = o.map some) :
    ∃ p, o = some p ∧ l[i.val]? = some p := by
  cases o with
  | none => simp [idxAbs] at h
  | some p => simp [idxAbs] at h; exact ⟨p, rfl, h⟩

theorem idxAbs_err {α} {l : List α} {a : Error} {o : Option α} (h : idxAbs l (.Err a) = o.map some) :
    o = none := by
  cases o with
  | none => rfl
  | some p => simp [idxAbs] at h

theorem get_pdu_ok {s : Snapshot} {e : U64} {i : Usize}
    (h : svc_timeline.get_pdu s e = ok (.Ok i)) :
    ∃ p, s.pdus.val[i.val]? = some p ∧ eventOf s e.val = some p := by
  unfold svc_timeline.get_pdu at h
  h5i_invert h
  · have h1 := post_of_ok (get_non_outlier_spec s e) hr
    obtain ⟨p, hf, hp⟩ := idxAbs_ok h1
    refine ⟨p, hp, ?_⟩
    rw [find?_u64] at hf
    unfold eventOf timeline
    rw [List.find?_filter, hf]
  · have h1 := post_of_ok (get_non_outlier_spec s e) hr
    have hn := idxAbs_err h1
    have h2 := post_of_ok (get_outlier_spec s e) h
    obtain ⟨p, hf, hp⟩ := idxAbs_ok h2
    refine ⟨p, hp, ?_⟩
    rw [find?_u64] at hf hn
    unfold eventOf timeline
    rw [List.find?_filter, List.find?_filter, hn]
    simpa using hf

theorem state_get_id_ok {s : Snapshot} {hs : U64} {k : Kind} {key : U64} {id : U64}
    (h : svc_accessor.state_get_id s hs k key = ok (.Ok id)) :
    ∃ es, stateEntries s hs.val = some es ∧ ∃ en,
      es.find? (fun en => decide (en.kind = k ∧ en.state_key.val = key.val)) = some en ∧ en.event_id = id := by
  unfold svc_accessor.state_get_id at h
  h5i_invert h
  have h1 := post_of_ok (load_full_state_spec s hs) hr
  obtain ⟨st, hf, hst⟩ := idxAbs_ok h1
  have hss' := vec_index_slice_ok_get? hss
  rw [hst] at hss'; cases hss'
  have h2 := post_of_ok (find_entry_spec _ k key) h
  refine ⟨ss.entries.val, ?_, ?_⟩
  · unfold stateEntries
    have : (fun x : StateSet => decide (x.hash.val = hs.val)) = (fun x => decide (x.hash = hs)) := by
      funext x; simp [u64_eq_iff]
    rw [this, hf]; rfl
  · have : (fun x : StateEntry => decide (x.kind = k ∧ x.state_key.val = key.val)) =
        (fun x => decide (x.kind = k ∧ x.state_key = key)) := by
      funext x; simp [u64_eq_iff]
    rw [this]
    have e : (alloc.vec.Vec.deref ss.entries).val = ss.entries.val := by simp [alloc.vec.Vec.deref]
    rw [e] at h2
    cases hfe : List.find? (fun x => decide (x.kind = k ∧ x.state_key = key)) ss.entries.val with
    | none => rw [hfe] at h2; simp at h2
    | some en => rw [hfe] at h2; simp at h2; exact ⟨en, rfl, h2.symm⟩

theorem state_get_ok {s : Snapshot} {hs : U64} {k : Kind} {key : U64} {i : Usize}
    (h : svc_accessor.state_get s hs k key = ok (.Ok i)) :
    ∃ p, s.pdus.val[i.val]? = some p ∧ stateLookup s hs.val k key.val = some p := by
  unfold svc_accessor.state_get at h
  h5i_invert h
  obtain ⟨es, hes, en, hen, rfl⟩ := state_get_id_ok hr
  obtain ⟨p, hp, hev⟩ := get_pdu_ok h
  refine ⟨p, hp, ?_⟩
  unfold stateLookup
  rw [hes]; simp only [hen, hev]

theorem room_state_get_ok {s : Snapshot} {room : U64} {k : Kind} {key : U64} {i : Usize}
    (h : svc_accessor.room_state_get s room k key = ok (.Ok i)) :
    ∃ hs : U64, roomState s room.val = some hs.val ∧ svc_accessor.state_get s hs k key = ok (.Ok i) := by
  unfold svc_accessor.room_state_get at h
  h5i_invert h
  refine ⟨_, ?_, h⟩
  have h1 := post_of_ok (get_room_shortstatehash_spec s room) hr
  have : (fun x : Room => decide (x.id.val = room.val)) = (fun x => decide (x.id = room)) := by
    funext x; simp [u64_eq_iff]
  unfold roomState
  rw [this]
  cases hf : List.find? (fun x => decide (x.id = room)) s.rooms.val with
  | none => rw [hf] at h1; simp at h1
  | some x =>
    rw [hf] at h1
    obtain ⟨xi, xs, xst⟩ := x
    cases xst <;> simp [roomHash] at h1
    subst h1; rfl

theorem room_history_visibility_wr {s : Snapshot} {room : U64}
    (h : svc_accessor.room_history_visibility s room = ok (some .WorldReadable)) :
    WorldReadableNow s room.val := by
  unfold svc_accessor.room_history_visibility at h
  h5i_invert h
  simp only [Option.some.injEq] at h; subst h
  obtain ⟨hs, hrs, hsg⟩ := room_state_get_ok hr
  obtain ⟨q, hq, hl⟩ := state_get_ok hsg
  have hp' := vec_index_slice_ok_get? hp
  rw [hq] at hp'; cases hp'
  exact ⟨hs.val, hrs, p, by simpa using hl, hc⟩

theorem has_row_ok {rows : Slice UserRoom} {u room : U64} (h : svc_cache.has_row rows u room = ok true) :
    ∃ x ∈ rows.val, x.user.val = u.val ∧ x.room.val = room.val := by
  have h1 := post_of_ok (has_row_spec rows u room) h
  simp at h1
  obtain ⟨x, hx, h2, h3⟩ := h1
  exact ⟨x, hx, by rw [h2], by rw [h3]⟩

theorem has_row_deref_ok {v : alloc.vec.Vec UserRoom} {u room : U64}
    (h : svc_cache.has_row v.deref u room = ok true) :
    ∃ x ∈ v.val, x.user.val = u.val ∧ x.room.val = room.val := by
  have e : (alloc.vec.Vec.deref v).val = v.val := by simp [alloc.vec.Vec.deref]
  rw [← e]; exact has_row_ok h

theorem user_can_see_state_events_ok {s : Snapshot} {u room : U64}
    (h : svc_accessor.user_can_see_state_events s u room = ok true) :
    Joined s u.val room.val ∨ Invited s u.val room.val ∨ OnceJoined s u.val room.val ∨
      WorldReadableNow s room.val := by
  unfold svc_accessor.user_can_see_state_events svc_cache.is_joined svc_cache.once_joined
    svc_cache.is_invited at h
  h5i_invert h
  · subst hc; exact Or.inl (has_row_deref_ok hb)
  · cases o with
    | none => simp at hhv
    | some v =>
      simp at hhv; subst hhv
      exact Or.inr (Or.inr (Or.inr (room_history_visibility_wr ho)))
  · exact Or.inr (Or.inr (Or.inl (has_row_deref_ok h)))
  · exact Or.inr (Or.inl (has_row_deref_ok h))

theorem state_route_ok {s : Snapshot} {u room : U64} {r : Reply}
    (h : api_state.get_state_events_route s u room = ok (.Ok r)) :
    svc_accessor.user_can_see_state_events s u room = ok true := by
  unfold api_state.get_state_events_route at h
  h5i_invert h
  all_goals (subst hc; exact hb)

theorem state_key_route_ok {s : Snapshot} {u room : U64} {k : Kind} {key : U64} {r : Reply}
    (h : api_state.get_state_events_for_key_route s u room k key = ok (.Ok r)) :
    svc_accessor.user_can_see_state_events s u room = ok true := by
  unfold api_state.get_state_events_for_key_route at h
  h5i_invert h
  all_goals (subst hc; exact hb)

theorem members_route_ok {s : Snapshot} {u room : U64} {at_ : Token} {m n : Option Membership} {r : Reply}
    (h : api_members.get_member_events_route s u room at_ m n = ok (.Ok r)) :
    svc_accessor.user_can_see_state_events s u room = ok true := by
  unfold api_members.get_member_events_route at h
  h5i_invert h
  all_goals (subst hc; exact hb)

theorem state_reads_need_membership (s : Snapshot) (u room : U64) (op : Op) (r : Reply)
    (hop : op = .State room ∨ (∃ k key, op = .StateEvent room k key) ∨ ∃ at_ m n, op = .Members room at_ m n)
    (h : transition s ⟨u, op⟩ = ok (.Ok r)) :
    Joined s u.val room.val ∨ Invited s u.val room.val ∨ OnceJoined s u.val room.val ∨ WorldReadableNow s room.val := by
  apply user_can_see_state_events_ok
  rcases hop with rfl | ⟨k, key, rfl⟩ | ⟨at_, m, n, rfl⟩
  · exact state_route_ok (by simpa [transition] using h)
  · exact state_key_route_ok (by simpa [transition] using h)
  · exact members_route_ok (by simpa [transition] using h)

end tuwunel_kernel.Verified.TuwunelStateReadsNeedMembership
