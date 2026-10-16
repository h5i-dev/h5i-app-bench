import Spec
import H5iAppLib
/-!
This snapshot is permitted by the requested theorem: one room, one PDU,
one joined user, and `Usize.max` copies of a self-relation. The request
does not recurse and filters for Dummy events; its sole PDU is Create.

The relation walker therefore keeps its output empty, ignoring the reply
limit, and appends one queue entry per relation. Its initial queue entry
means the final push exceeds the vector's maximum length. The proof below
shows that the whole transition cannot return any `ok` value.
-/
open Aeneas Aeneas.Std Result tuwunel_kernel
open H5iAppLib hiding lit
open Aeneas.Std.WP

namespace tuwunel_kernel.Counterexample

def pdu : Pdu := {
  event_id := 0#u64, room := 0#u64, sender := 0#u64,
  kind := .Create, has_state_key := false, state_key := 0#u64,
  membership := .Absent, history_visibility := .Absent,
  relates_to := .None, has_url := false, outlier := false,
  count := 1#i64, state := .None }

def snapshot : Snapshot := {
  rooms := vecOf [{ id := 0#u64, short := 0#u64, state := .None }],
  pdus := vecOf [pdu], states := alloc.vec.Vec.new _,
  joined := vecOf [{ user := 0#u64, room := 0#u64 }],
  invited := alloc.vec.Vec.new _, knocked := alloc.vec.Vec.new _,
  left := alloc.vec.Vec.new _, once_joined := alloc.vec.Vec.new _,
  relations := vecOf (List.replicate Usize.max { «to» := 1#u64, «from» := 1#u64 })
    (by simp),
  thread_activity := alloc.vec.Vec.new _, thread_latest := alloc.vec.Vec.new _,
  thread_participants := alloc.vec.Vec.new _, ignored := alloc.vec.Vec.new _,
  config := {
    server_name := 0#u64
    forbidden_remote_server_names := alloc.vec.Vec.new _
    allowed_remote_server_names := alloc.vec.Vec.new _ },
  current_count := 1#i64 }

@[step] theorem in_timeline (p : Pdu) (room : U64) :
    svc_timeline.in_timeline p room ⦃ b => b = (!p.outlier && decide (p.room = room)) ⦄ := by
  unfold svc_timeline.in_timeline
  split <;> simp_all

@[step] theorem short : svc_timeline.get_shortroomid snapshot 0#u64
    ⦃ r => r = .Ok 0#u64 ⦄ := by
  unfold svc_timeline.get_shortroomid svc_timeline.get_shortroomid_loop
  rw [loop]
  unfold svc_timeline.get_shortroomid_loop.body
  simp only [snapshot, alloc.vec.Vec.len]
  step* <;> simp_all
  all_goals step* <;> simp_all

@[step] theorem row : svc_timeline.find_row snapshot 0#u64 1#i64
    ⦃ r => r = .Ok 0#usize ⦄ := by
  unfold svc_timeline.find_row svc_timeline.find_row_loop
  rw [loop]
  unfold svc_timeline.find_row_loop.body
  simp only [snapshot, alloc.vec.Vec.len]
  step* <;> simp_all [pdu]
  all_goals step* <;> simp_all [pdu]

@[step] theorem room : svc_timeline.room_of_short snapshot 0#u64
    ⦃ r => r = some 0#u64 ⦄ := by
  unfold svc_timeline.room_of_short svc_timeline.room_of_short_loop
  rw [loop]
  unfold svc_timeline.room_of_short_loop.body
  simp only [snapshot, alloc.vec.Vec.len]
  step* <;> simp_all
  all_goals step* <;> simp_all

@[step] theorem from_id : svc_timeline.get_pdu_from_id snapshot 0#u64 1#i64
    ⦃ r => r = .Ok 0#usize ⦄ := by
  unfold svc_timeline.get_pdu_from_id
  step* <;> simp_all
  all_goals step* <;> simp_all

@[step] theorem push_relation (out : alloc.vec.Vec (I64 × Usize))
    (h : out.val.length < Usize.max) :
    svc_relations.push_relation snapshot 0#u64 1#u64 out
      ⦃ r => r.val = out.val ++ [(1#i64, 0#usize)] ⦄ := by
  unfold svc_relations.push_relation
  have hc : UScalar.hcast .I64 1#u64 = 1#i64 := by
    apply IScalar.eq_of_val_eq
    simp [UScalar.hcast_val_eq]
  simp only [hc, lift, bind_tc_ok]
  step* <;> simp_all
  all_goals step* <;> simp_all

theorem fold_constant {α β : Type} (l : List α) (a : List β) (b : β) :
    l.foldl (fun acc _ => acc ++ [b]) a = a ++ List.replicate l.length b := by
  induction l generalizing a with
  | nil => simp
  | cons x xs ih =>
    simp [ih, List.replicate_succ, List.append_assoc]

@[step] theorem relations : svc_relations.get_relations snapshot 0#u64 1#i64 none .Forward
    ⦃ r => r.val = List.replicate Usize.max (1#i64, 0#usize) ⦄ := by
  unfold svc_relations.get_relations
  have hc : IScalar.hcast .U64 1#i64 = 1#u64 := by
    apply UScalar.eq_of_val_eq
    simp [IScalar.hcast_val_eq]
  simp only [lift, hc, bind_tc_ok, bind_ok]
  unfold svc_relations.get_relations_loop0
  apply spec_mono (loop_fold snapshot.relations.val alloc.vec.Vec.val
    (fun acc _ => acc ++ [(1#i64, 0#usize)])
    (fun out i => out.val.length ≤ i) _ ?_ (alloc.vec.Vec.new _) 0#usize
    (by simp) (by simp))
  · intro r hr
    simpa [snapshot, fold_constant] using hr
  · intro out i hi hlen
    unfold svc_relations.get_relations_loop0.body
    h5i_steps
    all_goals simp_all [snapshot, FoldStep]
    all_goals try scalar_tac
    all_goals change (do
      let out1 ← svc_relations.push_relation snapshot 0#u64 1#u64 out
      let i2 ← i + 1#usize
      ok (ControlFlow.cont (out1, i2))) ⦃ _ ⦄
    all_goals step with push_relation out (by scalar_tac)
    all_goals h5i_steps
    all_goals simp_all [snapshot, FoldStep]
    all_goals scalar_tac

@[step] theorem fetch : api_relations.fetch snapshot 0#u64 1#i64 none .Forward
    ⦃ r => r.val = List.replicate Usize.max (1#i64, 0#usize) ⦄ := by
  unfold api_relations.fetch
  step
  have hrels : rels.val = List.replicate Usize.max (1#i64, 0#usize) := by assumption
  unfold api_relations.fetch_loop
  apply spec_mono (loop_fold rels.val alloc.vec.Vec.val
    (fun acc _ => acc ++ [(1#i64, 0#usize)])
    (fun out i => out.val.length ≤ i) _ ?_ (alloc.vec.Vec.new _) 0#usize
    (by simp) (by simp))
  · intro r hr
    simpa [hrels, fold_constant] using hr
  · intro out i hi hlen
    unfold api_relations.fetch_loop.body
    h5i_steps
    all_goals simp_all [FoldStep]
    all_goals try scalar_tac
    all_goals h5i_steps
    all_goals simp_all [FoldStep]
    all_goals scalar_tac

theorem push_value {α : Type} (v w : alloc.vec.Vec α) (a : α)
    (h : alloc.vec.Vec.push v a = ok w) : w.val = v.val ++ [a] := by
  unfold alloc.vec.Vec.push at h
  dsimp only at h
  split at h
  · have he := result_ok_inj h
    subst w
    simp
  · simp at h

theorem index_value {α : Type} (v : alloc.vec.Vec α) (i : Usize) (a : α)
    (h : v.val[i.val]? = some a) :
    alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice α) v i = ok a := by
  rw [alloc.vec.Vec.index_slice_index]
  simp [alloc.vec.Vec.index_usize, h]

def QueueInv (q : alloc.vec.Vec api_relations.Fetch) (i : Usize) : Prop :=
  q.val.length = i.val + 1 ∧ ∃ f, q.val[i.val]? = some f ∧
    f.depth = 0#u64 ∧ f.list = 0#usize ∧ f.pos = i

abbrev WalkState := (alloc.vec.Vec (alloc.vec.Vec (I64 × Usize))) ×
  (alloc.vec.Vec api_relations.Fetch) × (alloc.vec.Vec (U64 × I64 × Usize)) × Bool × Usize

theorem walk_loop_not_ok (v : alloc.vec.Vec (I64 × Usize))
    (hv : v.val = List.replicate Usize.max (1#i64, 0#usize))
    (lists : alloc.vec.Vec (alloc.vec.Vec (I64 × Usize))) (hl : lists.val = [v])
    (queue : alloc.vec.Vec api_relations.Fetch) (qi : Usize) (hq : QueueInv queue qi)
    (r : alloc.vec.Vec (U64 × I64 × Usize)) :
    api_relations.walk_loop snapshot 0#u64 0#u64 none .Forward 0#u64 none
      (some .Dummy) none 1#u64 lists queue (alloc.vec.Vec.new _) false qi ≠ ok r := by
  intro h
  unfold api_relations.walk_loop at h
  let Inv : WalkState → Prop := fun x => x.1 = lists ∧ x.2.2.1 = alloc.vec.Vec.new _ ∧
    x.2.2.2.1 = false ∧ QueueInv x.2.1 x.2.2.2.2
  refine loop_ok _ Inv (fun _ => False) (fun x => Usize.max - x.2.2.2.2.val)
    ?_ _ _ ⟨rfl, rfl, rfl, hq⟩ h
  rintro ⟨ls, q, out, done1, i⟩ res ⟨hls, hout, hdone, hgood⟩ hs
  dsimp only at hls hout hdone hgood
  subst ls out done1
  obtain ⟨hlen, f, hget, hdepth, hlist, hpos⟩ := hgood
  have hi : i < alloc.vec.Vec.len q := by scalar_tac
  have hfv : f.pos < alloc.vec.Vec.len v := by
    have := q.property
    have hvlen : v.val.length = Usize.max := by simp [hv]
    scalar_tac
  have hfl : alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice
      (alloc.vec.Vec (I64 × Usize))) lists f.list = ok v :=
    index_value lists f.list v (by simp [hl, hlist])
  have hfp : alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice (I64 × Usize))
      v f.pos = ok (1#i64, 0#usize) :=
    index_value v f.pos _ (by
      have hx : f.pos.val < v.val.length := by scalar_tac
      simp only [hv, List.length_replicate] at hx
      simp [hv, hx])
  have hp : alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice Pdu)
      snapshot.pdus 0#usize = ok pdu := index_value _ _ _ (by simp [snapshot])
  have hk : api_relations.keep snapshot 0#u64 pdu (some .Dummy) none = ok false := by
    simp [api_relations.keep, kind_eq, pdu]
  have hc0 : UScalar.cast .U64 (alloc.vec.Vec.len (alloc.vec.Vec.new (U64 × I64 × Usize))) < 1#u64 := by
    change (UScalar.cast .U64 _).val < (1#u64).val
    simp [usize_cast_u64]
  have hd : ¬ (0#u64 < 0#u64) := by scalar_tac
  unfold api_relations.walk_loop.body at hs
  dsimp only at hs
  simp only [hi, hfv, index_value q i f hget, hfl, hfp, hp, hk, hdepth, hc0, hd,
    lift, bind_ok, bind_tc_ok, Bool.false_eq_true, ite_false, ite_true] at hs
  try dsimp only at hs
  try simp only [hp, hk, bind_ok, bind_tc_ok, Bool.false_eq_true, ite_false] at hs
  h5i_invert hs
  change (do
    let i4 ← f.pos + 1#usize
    let queue1 ← alloc.vec.Vec.push q { depth := 0#u64, list := f.list, pos := i4 }
    let p1 ← alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice Pdu) snapshot.pdus 0#usize
    let b ← api_relations.keep snapshot 0#u64 p1 (some .Dummy) none
    if b then
      do
      let out1 ← alloc.vec.Vec.push (alloc.vec.Vec.new _) (0#u64, 1#i64, 0#usize)
      ok (ControlFlow.cont (lists, queue1, out1, false, qi1))
    else ok (ControlFlow.cont (lists, queue1, alloc.vec.Vec.new _, false, qi1))) = ok res at hs
  simp only [hpos, hp, hk, bind_ok, bind_tc_ok, Bool.false_eq_true, ite_false] at hs
  h5i_invert hs
  have he : qi1 = i4 := result_ok_inj (hqi1.symm.trans hi4)
  subst i4
  have hval := add_ok_val hqi1
  simp at hval
  have hqval := push_value q queue1 _ hqueue1
  have hnew : queue1.val.length = qi1.val + 1 := by
    simp only [hqval, List.length_append, List.length_cons, List.length_nil]
    omega
  dsimp only [Inv]
  refine ⟨⟨rfl, rfl, rfl, hnew, ?_⟩, ?_⟩
  · refine ⟨{ depth := 0#u64, list := f.list, pos := qi1 }, ?_, rfl, hlist, rfl⟩
    have heidx : qi1.val = q.val.length := by omega
    rw [hqval, heidx]
    simp
  · have := queue1.property
    omega

theorem walk_not_ok (r : alloc.vec.Vec (U64 × I64 × Usize)) :
    api_relations.walk snapshot 0#u64 0#u64 1#i64 none .Forward 0#u64 none
      (some .Dummy) none 1#u64 ≠ ok r := by
  intro h
  unfold api_relations.walk at h
  h5i_invert h
  have hv := post_of_ok fetch hv
  have hl := push_value (alloc.vec.Vec.new _) lists v hlists
  have hqv := push_value (alloc.vec.Vec.new _) queue _ hqueue
  apply walk_loop_not_ok v hv lists (by simpa using hl) queue 0#usize ?_ r h
  simp only [QueueInv, hqv, alloc.vec.Vec.from_val, List.nil_append]
  refine ⟨by simp, ⟨{ depth := 0#u64, list := 0#usize, pos := 0#usize }, by simp, rfl, rfl, rfl⟩⟩

@[step] theorem non_outlier : svc_timeline.get_non_outlier snapshot 0#u64
    ⦃ r => r = .Ok 0#usize ⦄ := by
  unfold svc_timeline.get_non_outlier svc_timeline.get_non_outlier_loop
  rw [loop]
  unfold svc_timeline.get_non_outlier_loop.body
  simp only [snapshot, alloc.vec.Vec.len]
  step* <;> simp_all [pdu]
  all_goals step* <;> simp_all [pdu]

@[step] theorem get_pdu : svc_timeline.get_pdu snapshot 0#u64
    ⦃ r => r = .Ok 0#usize ⦄ := by
  unfold svc_timeline.get_pdu
  step* <;> simp_all

@[step] theorem get_pdu_id : svc_timeline.get_pdu_id snapshot 0#u64
    ⦃ r => r = .Ok (0#u64, 1#i64) ⦄ := by
  unfold svc_timeline.get_pdu_id
  have hp : alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice Pdu)
      snapshot.pdus 0#usize = ok pdu := index_value _ _ _ (by simp [snapshot])
  simp only [eq_ok_of_spec non_outlier, bind_ok, hp, pdu,
    eq_ok_of_spec short, WP.spec_ok]

@[step] theorem joined : svc_cache.is_joined snapshot 0#u64 0#u64
    ⦃ r => r = true ⦄ := by
  unfold svc_cache.is_joined svc_cache.has_row svc_cache.has_row_loop
  rw [loop]
  unfold svc_cache.has_row_loop.body
  simp [snapshot, Slice.index_usize, alloc.vec.Vec.deref]

@[step] theorem can_see_state : svc_accessor.user_can_see_state_events snapshot 0#u64 0#u64
    ⦃ r => r = true ⦄ := by
  unfold svc_accessor.user_can_see_state_events
  step* <;> simp_all

theorem ignored : api_message.is_ignored_pdu snapshot pdu 0#u64 = ok false := by
  simp [api_message.is_ignored_pdu, api_message.is_ignored_message_type, pdu]

def request : Request := {
  user := 0#u64
  op := .Relations 0#u64 0#u64 none (some .Dummy) .Absent .Absent (some 1#u64) false .Forward }

theorem transition_not_ok (r : core.result.Result Reply tuwunel_kernel.Error) :
    transition snapshot request ≠ ok r := by
  intro h
  simp only [transition, request] at h
  unfold api_relations.paginate_relations_with_filter at h
  have hb : api_message.bounded (some 1#u64) 30#u64 100#u64 = ok 1#u64 := by
    simp [api_message.bounded]
  have hp : alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice Pdu)
      snapshot.pdus 0#usize = ok pdu := index_value _ _ _ (by simp [snapshot])
  simp only [hb, eq_ok_of_spec short, eq_ok_of_spec get_pdu_id,
    eq_ok_of_spec can_see_state, eq_ok_of_spec get_pdu, ignored, hp,
    bind_ok, bind_tc_ok, Bool.false_eq_true, Bool.true_eq_false, ite_false, ite_true] at h
  have hn : ¬ (0#u64 > 0#u64) := by scalar_tac
  simp only [hn, ite_false] at h
  change (do
    let events ← api_relations.walk snapshot 0#u64 0#u64 1#i64 none .Forward 0#u64 none
      (some .Dummy) none 1#u64
    _) = ok r at h
  obtain ⟨events, hevents, _⟩ := bind_eq_ok.mp h
  exact walk_not_ok events hevents

/-- The universally quantified theorem requested in TASK.md is false. -/
theorem not_transition_total :
    ¬ (∀ (s : Snapshot) (req : Request), ∃ r, transition s req = ok r) := by
  intro h
  obtain ⟨r, hr⟩ := h snapshot request
  exact transition_not_ok r hr

end tuwunel_kernel.Counterexample
