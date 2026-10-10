import Spec
import H5iAppLib
/-!
This file disproves the requested totality statement without importing Solution.
For n = Usize.max - 1, the snapshot has n duplicate self-relations. The request
enables recursion and filters out every event, so the output limit never stops
the traversal. Pending records a root stream that still has work. Its invariant
is preserved by every successful step and rules out every done branch.
-/
open Aeneas Aeneas.Std Result tuwunel_kernel H5iAppLib
open Aeneas.Std.WP

namespace Counterexample

-- Diagnostic facts about the recursive traversal's append-only queue.
theorem platform_max_lt : Usize.max < 65536 ^ 4 := by
  rw [Usize.max_def]
  cases System.Platform.numBits_eq <;> simp_all [Usize.numBits]

theorem input_size_allowed : 65536 < Usize.max := by
  have := usize_max_ge
  omega

theorem push_full_fails {α : Type} (v : alloc.vec.Vec α) (x : α)
    (h : v.val.length = Usize.max) :
    alloc.vec.Vec.push v x = fail .maximumSizeExceeded := by
  have h32 : U32.max ≤ Usize.max := by
    rw [U32.max_def]
    simpa [U32.numBits] using usize_max_ge
  unfold alloc.vec.Vec.push
  simp only [h]
  split
  · rename_i hb
    simp only [Bool.or_eq_true, decide_eq_true_eq] at hb
    omega
  · rfl

def queued (n : Nat) : Nat :=
  1 + 2 * (n + n ^ 2 + n ^ 3) + n ^ 4

theorem queue_exceeds_capacity : Usize.max < queued 65536 := by
  have := platform_max_lt
  unfold queued
  omega

abbrev Rows := alloc.vec.Vec (I64 × Usize)
abbrev Arena := alloc.vec.Vec Rows
abbrev Queue := alloc.vec.Vec api_relations.Fetch
abbrev Output := alloc.vec.Vec (U64 × I64 × Usize)
abbrev WalkState := Arena × Queue × Output × Bool × Usize

def Pending (seed : Rows) (x : WalkState) : Prop :=
  x.1.val[0]? = some seed ∧ x.2.2.1.val = [] ∧ x.2.2.2.1 = false ∧
    ∃ j f, x.2.2.2.2.val ≤ j ∧ x.2.1.val[j]? = some f ∧
      f.depth = 0#u64 ∧ f.list = 0#usize ∧
      Usize.max < x.2.1.val.length + 2 * (seed.val.length - f.pos.val)

theorem keep_rejects (s : Snapshot) (user : U64) (p : Pdu)
    (hp : p.kind = .Name) :
    api_relations.keep s user p (some .Member) none = ok false := by
  simp [api_relations.keep, hp, kind_eq]

def WalkPost (seed : Rows) (qi : Usize) (r : ControlFlow WalkState Output) : Prop :=
  match r with
  | .done _ => False
  | .cont x' => Pending seed x' ∧ qi.val < x'.2.2.2.2.val

theorem push_val {α : Type} {v w : alloc.vec.Vec α} {a : α}
    (h : alloc.vec.Vec.push v a = ok w) : w.val = v.val ++ [a] := by
  unfold alloc.vec.Vec.push at h
  dsimp at h
  split at h
  · have hw := result_ok_inj h
    rw [← hw]
    simp
  · simp at h

theorem preserve_pending (s : Snapshot) (user short : U64) (seed : Rows)
    (hs : ∀ p ∈ s.pdus.val, p.kind = .Name)
    (x : WalkState) (hx : Pending seed x) (r : ControlFlow WalkState Output)
    (hr : api_relations.walk_loop.body s user short none .Forward 3#u64 none
      (some .Member) none 1#u64 x.1 x.2.1 x.2.2.1 x.2.2.2.1 x.2.2.2.2 = ok r) :
    WalkPost seed x.2.2.2.2 r := by
  rcases x with ⟨ls, q, out, stop, qi⟩
  rcases hx with ⟨hl, ho, hstop, j, root, hj, hroot, hd, hli, hweight⟩
  dsimp only at hl ho hstop hj hroot hweight ⊢
  subst hstop
  have hjlt : j < q.val.length := (List.getElem?_eq_some_iff.mp hroot).1
  have hrootval := (List.getElem?_eq_some_iff.mp hroot).2
  have hlval := (List.getElem?_eq_some_iff.mp hl).2
  have hqi : qi < alloc.vec.Vec.len q := by scalar_tac
  change WalkPost seed qi r
  unfold api_relations.walk_loop.body at hr
  dsimp only at hr
  simp only [Bool.false_eq_true, ↓reduceIte, hqi] at hr
  h5i_invert hr
  all_goals expose_names
  case isTrue.isTrue.isTrue =>
    rcases x with ⟨count, p⟩
    obtain ⟨i4, hi4, hr⟩ := bind_tc_eq_ok.mp hr
    h5i_invert hr
    expose_names
    rcases x with ⟨lists1, queue2⟩
    h5i_invert hx_1
    obtain ⟨p1, hp1, hr⟩ := bind_tc_eq_ok.mp hr
    rw [keep_rejects s user p1 (hs p1 (vec_index_slice_ok_mem hp1))] at hr
    h5i_invert hr
    expose_names
    rcases hx_1 with ⟨rfl, rfl⟩
    have hls := push_val hlists2
    have hq := push_val hqueue1
    have hq3 := push_val hqueue3
    have hls0 : 0 < ls.val.length := (List.getElem?_eq_some_iff.mp hl).1
    have hl' : lists2.val[0]? = some seed := by
      rw [hls, List.getElem?_append]
      simp [hls0, hlval]
    have hq' : queue3.val = q.val ++
        [{depth := f.depth, list := f.list, pos := i4},
          {depth := i5, list := i7, pos := 0#usize}] := by
      rw [hq3, hq, List.append_assoc]
      rfl
    have hqi' : qi1.val = qi.val + 1 := by simpa using add_ok_val hqi1
    change Pending seed (lists2, queue3, out, false, qi1) ∧ qi.val < qi1.val
    dsimp only [Pending]
    refine ⟨⟨hl', ho, rfl, ?_⟩, by omega⟩
    by_cases he : j = qi.val
    · have hfr : f = root := by
        have hf' := vec_index_slice_ok_get? hf
        rw [← he, hroot] at hf'
        exact Option.some.inj hf'.symm
      subst f
      have hpos : root.pos.val < seed.val.length := by
        have := q.property
        omega
      have hip : i4.val = root.pos.val + 1 := by simpa using add_ok_val hi4
      refine ⟨q.val.length, {depth := root.depth, list := root.list, pos := i4},
        by omega, ?_, hd, hli, ?_⟩
      · rw [hq']
        simp
      · simp only [hq', List.length_append, List.length_cons, List.length_nil]
        omega
    · refine ⟨j, root, by omega, ?_, hd, hli, ?_⟩
      · rw [hq', List.getElem?_append]
        simp [hjlt, hrootval]
      · simp only [hq', List.length_append, List.length_cons, List.length_nil]
        omega
  case isTrue.isTrue.isFalse =>
    rcases x with ⟨count, p⟩
    obtain ⟨i4, hi4, hr⟩ := bind_tc_eq_ok.mp hr
    h5i_invert hr
    obtain ⟨p1, hp1, hr⟩ := bind_tc_eq_ok.mp hr
    rw [keep_rejects s user p1 (hs p1 (vec_index_slice_ok_mem hp1))] at hr
    h5i_invert hr
    expose_names
    have hq := push_val hqueue1
    have hqi' : qi1.val = qi.val + 1 := by simpa using add_ok_val hqi1
    change Pending seed (ls, queue1, out, false, qi1) ∧ qi.val < qi1.val
    dsimp only [Pending]
    refine ⟨⟨hl, ho, rfl, ?_⟩, by omega⟩
    have he : j ≠ qi.val := by
      intro he
      have hf' := vec_index_slice_ok_get? hf
      rw [← he, hroot] at hf'
      have hfr := Option.some.inj hf'.symm
      subst f
      rw [hd] at hc_2
      scalar_tac
    refine ⟨j, root, by omega, ?_, hd, hli, ?_⟩
    · rw [hq, List.getElem?_append]
      simp [hjlt, hrootval]
    · simp only [hq, List.length_append, List.length_cons, List.length_nil]
      omega
  case isFalse =>
    have he := result_ok_inj hi2
    have hz : i2.val = 0 := by
      rw [← he, usize_cast_u64, alloc.vec.Vec.len_val]
      simp only [alloc.vec.Vec.length, ho, List.length_nil]
    scalar_tac
  case isTrue.isFalse =>
    have hqi' : qi1.val = qi.val + 1 := by simpa using add_ok_val hqi1
    have he : j ≠ qi.val := by
      intro he
      have hf' := vec_index_slice_ok_get? hf
      rw [← he, hroot] at hf'
      have hfr := Option.some.inj hf'.symm
      subst f
      have hv' := vec_index_slice_ok_get? hv
      simp only [hli, UScalar.ofNatCore_val_eq] at hv'
      rw [hl] at hv'
      have hvseed := Option.some.inj hv'
      subst v
      have hpos : root.pos.val < seed.val.length := by
        have := q.property
        omega
      scalar_tac
    change Pending seed (ls, q, out, false, qi1) ∧ qi.val < qi1.val
    dsimp only [Pending]
    exact ⟨⟨hl, ho, rfl, j, root, by omega, hroot, hd, hli, hweight⟩, by omega⟩

theorem pending_ne_ok (s : Snapshot) (user short : U64) (seed : Rows)
    (hs : ∀ p ∈ s.pdus.val, p.kind = .Name)
    (x : WalkState) (hx : Pending seed x) (y : Output) :
    api_relations.walk_loop s user short none .Forward 3#u64 none
      (some .Member) none 1#u64 x.1 x.2.1 x.2.2.1 x.2.2.2.1 x.2.2.2.2 ≠ ok y := by
  intro hy
  unfold api_relations.walk_loop at hy
  apply loop_ok _ (Pending seed) (fun _ => False)
    (fun x : WalkState => Usize.max - x.2.2.2.2.val) ?_ x y hx hy
  intro x r hx hr
  have hpost := preserve_pending s user short seed hs x hx r hr
  cases r with
  | done y => exact hpost
  | cont x' =>
    have hinc := hpost.2
    have hb : x'.2.2.2.2.val ≤ Usize.max := by scalar_tac
    exact ⟨hpost.1, by omega⟩

def pdu : Pdu := {
  event_id := 1#u64, room := 1#u64, sender := 0#u64, kind := .Name,
  has_state_key := false, state_key := 0#u64, membership := .Absent,
  history_visibility := .Absent, relates_to := .None, has_url := false,
  outlier := false, count := 1#i64, state := .None }

def snapshot (n : Nat) (hn : n < Usize.max) : Snapshot := {
  rooms := vecOf [{ id := 1#u64, short := 1#u64, state := .None }],
  pdus := vecOf [pdu], states := alloc.vec.Vec.new _,
  joined := vecOf [{ user := 0#u64, room := 1#u64 }],
  invited := alloc.vec.Vec.new _, knocked := alloc.vec.Vec.new _,
  left := alloc.vec.Vec.new _, once_joined := alloc.vec.Vec.new _,
  relations := vecOf (List.replicate n {«to» := 1#u64, «from» := 1#u64})
    (by simpa using Nat.le_of_lt hn),
  thread_activity := alloc.vec.Vec.new _, thread_latest := alloc.vec.Vec.new _,
  thread_participants := alloc.vec.Vec.new _, ignored := alloc.vec.Vec.new _,
  config := {
    server_name := 0#u64,
    forbidden_remote_server_names := alloc.vec.Vec.new _,
    allowed_remote_server_names := alloc.vec.Vec.new _ },
  current_count := 1#i64 }

@[step] theorem short_id_spec (n : Nat) (hn : n < Usize.max) :
    svc_timeline.get_shortroomid (snapshot n hn) 1#u64 ⦃ r => r = .Ok 1#u64 ⦄ := by
  unfold svc_timeline.get_shortroomid svc_timeline.get_shortroomid_loop
  rw [loop]
  unfold svc_timeline.get_shortroomid_loop.body
  step*
  all_goals simp_all [snapshot, vecOf, alloc.vec.Vec.index_usize, bind_ok, bind_tc_ok, spec_ok]
  all_goals scalar_tac

@[step] theorem room_short_spec (n : Nat) (hn : n < Usize.max) :
    svc_timeline.room_of_short (snapshot n hn) 1#u64 ⦃ r => r = some 1#u64 ⦄ := by
  unfold svc_timeline.room_of_short svc_timeline.room_of_short_loop
  rw [loop]
  unfold svc_timeline.room_of_short_loop.body
  step*
  all_goals simp_all [snapshot, vecOf, alloc.vec.Vec.index_usize, bind_ok, bind_tc_ok, spec_ok]
  all_goals scalar_tac

@[step] theorem find_row_spec (n : Nat) (hn : n < Usize.max) :
    svc_timeline.find_row (snapshot n hn) 1#u64 1#i64 ⦃ r => r = .Ok 0#usize ⦄ := by
  unfold svc_timeline.find_row svc_timeline.find_row_loop
  rw [loop]
  unfold svc_timeline.find_row_loop.body svc_timeline.in_timeline
  step*
  all_goals simp_all [snapshot, vecOf, pdu, alloc.vec.Vec.index_usize, bind_ok, bind_tc_ok, spec_ok]
  all_goals scalar_tac

@[step] theorem pdu_from_id_spec (n : Nat) (hn : n < Usize.max) :
    svc_timeline.get_pdu_from_id (snapshot n hn) 1#u64 1#i64 ⦃ r => r = .Ok 0#usize ⦄ := by
  unfold svc_timeline.get_pdu_from_id
  step* <;> simp_all
  all_goals step*

@[step] theorem push_relation_spec (n : Nat) (hn : n < Usize.max) (out : Rows)
    (hout : out.val.length < Usize.max) :
    svc_relations.push_relation (snapshot n hn) 1#u64 1#u64 out
      ⦃ out' => out'.val = out.val ++ [(1#i64, 0#usize)] ⦄ := by
  have hc : UScalar.hcast .I64 (1#u64) = 1#i64 := by rfl
  unfold svc_relations.push_relation
  simp only [hc, lift, bind_tc_ok]
  step*
  all_goals simp_all -failIfUnchanged
  all_goals step*
  all_goals simp_all -failIfUnchanged

@[simp] theorem relations_val (n : Nat) (hn : n < Usize.max) :
    (snapshot n hn).relations.val =
      List.replicate n {«to» := 1#u64, «from» := 1#u64} := by simp [snapshot]

def GoodRows (n : Nat) (v : Rows) : Prop :=
  v.val.length = n ∧ ∀ x ∈ v.val, x.1 = 1#i64

@[step] theorem get_relations_loop_spec (n : Nat) (hn : n < Usize.max)
    (out : Rows) (i : Usize) (ho : GoodRows i.val out) (hi : i.val ≤ n) :
    svc_relations.get_relations_loop0 (snapshot n hn) 1#u64 1#u64 0#u64 out i
      ⦃ out' => GoodRows n out' ⦄ := by
  unfold svc_relations.get_relations_loop0
  apply loop.spec_decr_nat (measure := fun x : Rows × Usize => n - x.2.val)
    (inv := fun x : Rows × Usize => GoodRows x.2.val x.1 ∧ x.2.val ≤ n)
  · rintro ⟨out, i⟩ ⟨ho, hi⟩
    dsimp only at ho hi ⊢
    unfold svc_relations.get_relations_loop0.body
    h5i_step [relations_val, GoodRows]
    all_goals h5i_step [relations_val, GoodRows]
    constructor
    · intro a b hab
      rcases hab with hab | ⟨rfl, _⟩
      · exact ho.2 a b hab
      · rfl
    · omega
  · exact ⟨ho, hi⟩

@[step] theorem get_relations_spec (n : Nat) (hn : n < Usize.max) :
    svc_relations.get_relations (snapshot n hn) 1#u64 1#i64 none .Forward
      ⦃ out => GoodRows n out ⦄ := by
  have hc : IScalar.hcast .U64 (1#i64) = 1#u64 := by rfl
  unfold svc_relations.get_relations
  simp only [hc, lift, bind_tc_ok]
  step*
  all_goals simp_all [GoodRows]
  all_goals step*

@[step] theorem fetch_loop_spec (rels : Rows) (out : Rows) (i : Usize)
    (hall : ∀ x ∈ rels.val, x.1 = 1#i64)
    (ho : out.val.length = i.val) (hi : i.val ≤ rels.val.length) :
    api_relations.fetch_loop rels out i ⦃ out' => out'.val.length = rels.val.length ⦄ := by
  unfold api_relations.fetch_loop
  apply loop.spec_decr_nat (measure := fun x : Rows × Usize => rels.val.length - x.2.val)
    (inv := fun x : Rows × Usize => x.1.val.length = x.2.val ∧ x.2.val ≤ rels.val.length)
  · rintro ⟨out, i⟩ ⟨ho, hi⟩
    dsimp only at ho hi ⊢
    unfold api_relations.fetch_loop.body
    h5i_step
    all_goals
      have hm : (i2, i3) ∈ rels.val := by rw [i2_post]; exact List.getElem_mem _
      have hc := hall i2 i3 hm
      subst i2
      scalar_tac
  · exact ⟨ho, hi⟩

@[step] theorem fetch_spec (n : Nat) (hn : n < Usize.max) :
    api_relations.fetch (snapshot n hn) 1#u64 1#i64 none .Forward
      ⦃ out => out.val.length = n ⦄ := by
  unfold api_relations.fetch
  step*
  all_goals simp_all [GoodRows]
  all_goals step*

theorem walk_ne_ok (n : Nat) (hn : n < Usize.max)
    (hl : Usize.max < 1 + 2 * n) (r : Output) :
    api_relations.walk (snapshot n hn) 0#u64 1#u64 1#i64 none .Forward
      3#u64 none (some .Member) none 1#u64 ≠ ok r := by
  intro h
  unfold api_relations.walk at h
  h5i_invert h
  expose_names
  have hvlen := post_of_ok (fetch_spec n hn) hv
  have hlsval := push_val hlists
  have hqval := push_val hqueue
  have hp : Pending v (lists, queue, alloc.vec.Vec.new _, false, 0#usize) := by
    refine ⟨?_, rfl, rfl, 0, {depth := 0#u64, list := 0#usize, pos := 0#usize},
      by simp, ?_, rfl, rfl, ?_⟩
    · simp [hlsval]
    · simp [hqval]
    · simpa [hqval, hvlen] using hl
  exact pending_ne_ok (snapshot n hn) 0#u64 1#u64 v
    (by simp [snapshot, pdu]) _ hp r h

@[step] theorem non_outlier_spec (n : Nat) (hn : n < Usize.max) :
    svc_timeline.get_non_outlier (snapshot n hn) 1#u64 ⦃ r => r = .Ok 0#usize ⦄ := by
  unfold svc_timeline.get_non_outlier svc_timeline.get_non_outlier_loop
  rw [loop]
  unfold svc_timeline.get_non_outlier_loop.body
  step*
  all_goals simp_all [snapshot, vecOf, pdu, alloc.vec.Vec.index_usize, bind_ok, spec_ok]

@[step] theorem pdu_zero_spec (n : Nat) (hn : n < Usize.max) :
    alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice Pdu)
      (snapshot n hn).pdus 0#usize ⦃ p => p = pdu ⦄ := by
  simp [snapshot, vecOf, alloc.vec.Vec.index_usize]

theorem pdu_zero_eq (n : Nat) (hn : n < Usize.max) :
    (snapshot n hn).pdus.index_usize 0#usize = ok pdu := by
  simpa only [alloc.vec.Vec.index_slice_index] using eq_ok_of_spec (pdu_zero_spec n hn)

@[step] theorem pdu_id_spec (n : Nat) (hn : n < Usize.max) :
    svc_timeline.get_pdu_id (snapshot n hn) 1#u64
      ⦃ r => r = .Ok (1#u64, 1#i64) ⦄ := by
  simp [svc_timeline.get_pdu_id, eq_ok_of_spec (non_outlier_spec n hn),
    pdu_zero_eq n hn, pdu, eq_ok_of_spec (short_id_spec n hn)]

@[step] theorem get_pdu_spec (n : Nat) (hn : n < Usize.max) :
    svc_timeline.get_pdu (snapshot n hn) 1#u64 ⦃ r => r = .Ok 0#usize ⦄ := by
  unfold svc_timeline.get_pdu
  step*
  all_goals simp_all

@[step] theorem joined_spec (n : Nat) (hn : n < Usize.max) :
    svc_cache.is_joined (snapshot n hn) 0#u64 1#u64 ⦃ b => b = true ⦄ := by
  unfold svc_cache.is_joined svc_cache.has_row svc_cache.has_row_loop
  rw [loop]
  unfold svc_cache.has_row_loop.body
  step*
  all_goals simp_all [snapshot, vecOf, alloc.vec.Vec.deref, Slice.index_usize, bind_ok, spec_ok]

@[step] theorem visible_spec (n : Nat) (hn : n < Usize.max) :
    svc_accessor.user_can_see_state_events (snapshot n hn) 0#u64 1#u64
      ⦃ b => b = true ⦄ := by
  unfold svc_accessor.user_can_see_state_events
  step* <;> simp_all

@[step] theorem ignored_spec (n : Nat) (hn : n < Usize.max) :
    api_message.is_ignored_pdu (snapshot n hn) pdu 0#u64 ⦃ b => b = false ⦄ := by
  simp [api_message.is_ignored_pdu, api_message.is_ignored_message_type, pdu]

def request : Request := {
  user := 0#u64,
  op := .Relations 1#u64 1#u64 none (some .Member) .Absent .Absent (some 1#u64) true .Forward }

theorem transition_ne_ok (n : Nat) (hn : n < Usize.max)
    (hl : Usize.max < 1 + 2 * n) (r : core.result.Result Reply tuwunel_kernel.Error) :
    transition (snapshot n hn) request ≠ ok r := by
  intro h
  simp [transition, request, api_relations.paginate_relations_with_filter,
    eq_ok_of_spec (short_id_spec n hn), eq_ok_of_spec (pdu_id_spec n hn),
    eq_ok_of_spec (visible_spec n hn), eq_ok_of_spec (get_pdu_spec n hn),
    pdu_zero_eq n hn, eq_ok_of_spec (ignored_spec n hn),
    api_message.bounded] at h
  obtain ⟨events, he, _⟩ := bind_tc_eq_ok.mp h
  exact walk_ne_ok n hn hl events he

theorem counterexample :
    ∃ s req, s.relations.length < Usize.max ∧ ¬ ∃ r, transition s req = ok r := by
  have hmax : 1 < Usize.max := by have := usize_max_ge; omega
  have hn : Usize.max - 1 < Usize.max := by omega
  refine ⟨snapshot (Usize.max - 1) hn, request, ?_, ?_⟩
  · simpa only [alloc.vec.Vec.length, relations_val, List.length_replicate] using hn
  · rintro ⟨r, hr⟩
    exact transition_ne_ok (Usize.max - 1) hn (by omega) r hr

theorem not_transition_total :
    ¬ (∀ (s : Snapshot) (req : Request), s.relations.length < Usize.max →
      ∃ r, transition s req = ok r) := by
  intro ht
  obtain ⟨s, req, hs, hfail⟩ := counterexample
  exact hfail (ht s req hs)

#print axioms not_transition_total

end Counterexample
