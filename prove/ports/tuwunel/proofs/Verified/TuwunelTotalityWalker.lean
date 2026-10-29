import Verified.TuwunelTotalityMessages
open Aeneas Aeneas.Std Result tuwunel_kernel tuwunel_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP
namespace tuwunel_kernel.Verified.TuwunelTransitionTotal
set_option maxHeartbeats 2000000
set_option maxRecDepth 4096
set_option linter.unusedSimpArgs false
set_option linter.unusedVariables false
set_option allowUnsafeReducibility true
attribute [local reducible] Aeneas.Std.WP.Post

def cost (R d : Nat) : Nat :=
  match d with
  | 0 => R^3 + 2*R^2 + 2*R + 2
  | 1 => R^2 + 2*R + 2
  | 2 => R + 2
  | _ => 1

theorem cost_pos (R d : Nat) : 0 < cost R d := by
  unfold cost
  split <;> omega

theorem cost_next (R d : Nat) (hd : d < 3) :
    cost R d = 2 + R * cost R (d+1) := by
  have h : d = 0 ∨ d = 1 ∨ d = 2 := by omega
  rcases h with rfl | rfl | rfl <;> simp [cost] <;> ring

def weight (R : Nat) (f : api_relations.Fetch) : Nat :=
  1 + (R - f.pos.val) * cost R f.depth.val

theorem weight_pos (R : Nat) (f : api_relations.Fetch) : 0 < weight R f := by
  unfold weight; omega

theorem weight_succ (R : Nat) (f : api_relations.Fetch) (p : Usize)
    (hp : p.val = f.pos.val + 1) (hpos : f.pos.val < R) :
    weight R { f with pos := p } + cost R f.depth.val = weight R f := by
  simp only [weight]
  rw [hp]
  have he : R - f.pos.val = (R - (f.pos.val + 1)) + 1 := by omega
  rw [he]; ring

theorem weight_child (R : Nat) (d : U64) (l : Usize) :
    weight R { depth := d, list := l, pos := 0#usize } =
      1 + R * cost R d.val := by
  simp [weight]

theorem initial_weight (R : Nat) :
    1 + R * cost R 0 ≤ (R+1)^4 := by
  simp only [cost]
  nlinarith [Nat.zero_le (R^3), Nat.zero_le (R^2)]

def debt (R : Nat) (q : List api_relations.Fetch) : Nat :=
  (q.map (weight R)).sum

@[simp] theorem debt_nil (R : Nat) : debt R [] = 0 := rfl
@[simp] theorem debt_cons (R : Nat) (f : api_relations.Fetch) (q : List api_relations.Fetch) :
    debt R (f::q) = weight R f + debt R q := rfl
@[simp] theorem debt_append (R : Nat) (q q' : List api_relations.Fetch) :
    debt R (q++q') = debt R q + debt R q' := by
  simp [debt]

theorem debt_length (R : Nat) (q : List api_relations.Fetch) :
    q.length ≤ debt R q := by
  induction q with
  | nil => simp
  | cons f q ih => simp only [List.length_cons, debt_cons]; have := weight_pos R f; omega

theorem debt_drop (R : Nat) (q : List api_relations.Fetch) (i : Nat)
    (hi : i < q.length) :
    debt R (q.drop i) = weight R q[i] + debt R (q.drop (i+1)) := by
  rw [List.drop_eq_getElem_cons hi, debt_cons]

theorem queue_capacity (R : Nat) (q : List api_relations.Fetch) (i B : Nat)
    (hi : i ≤ q.length) (hb : i + debt R (q.drop i) ≤ B) : q.length ≤ B := by
  have := debt_length R (q.drop i)
  simp only [List.length_drop] at this
  omega


abbrev RelList := alloc.vec.Vec (I64 × Usize)
abbrev RelLists := alloc.vec.Vec RelList
abbrev FetchQueue := alloc.vec.Vec api_relations.Fetch

structure WalkCore (R N D : Nat) (lists : RelLists) (queue : FetchQueue) (qi : Usize) : Prop where
  listsGood : ∀ l ∈ lists.val, Good N l ∧ l.length ≤ R
  tasksGood : ∀ f ∈ queue.val, f.list.val < lists.length ∧ f.depth.val ≤ D ∧ f.pos.val ≤ R
  listsSize : lists.length ≤ queue.length
  cursor : qi.val ≤ queue.length
  fuel : qi.val + debt R (queue.val.drop qi.val) ≤ (R+1)^4

theorem WalkCore.capacity (h : WalkCore R N D lists queue qi) :
    queue.length ≤ (R+1)^4 :=
  queue_capacity R queue.val qi.val ((R+1)^4) h.cursor h.fuel

theorem WalkCore.advance (h : WalkCore R N D lists queue qi)
    (hi : qi.val < queue.length) (qi' : Usize) (hqi : qi'.val = qi.val+1) :
    WalkCore R N D lists queue qi' := by
  refine ⟨h.listsGood, h.tasksGood, h.listsSize, by omega, ?_⟩
  have hw := weight_pos R queue.val[qi.val]
  have he := debt_drop R queue.val qi.val hi
  have hf := h.fuel
  rw [he] at hf
  rw [hqi]
  omega

theorem WalkCore.next (h : WalkCore R N D lists queue qi)
    (hi : qi.val < queue.length) (f : api_relations.Fetch)
    (hf : f = queue.val[qi.val]) (p qi' : Usize)
    (hp : p.val = f.pos.val+1) (hpos : f.pos.val < R)
    (hqi : qi'.val = qi.val+1)
    (queue' : FetchQueue) (hq : queue'.val = queue.val ++ [{f with pos := p}]) :
    WalkCore R N D lists queue' qi' := by
  have hfm : f ∈ queue.val := hf ▸ List.getElem_mem hi
  obtain ⟨hl, hd, hb⟩ := h.tasksGood f hfm
  have hw := weight_succ R f p hp hpos
  have hc := cost_pos R f.depth.val
  have he := debt_drop R queue.val qi.val hi
  rw [← hf] at he
  have hfuel := h.fuel
  rw [he] at hfuel
  have hcursor : qi.val+1 ≤ queue.length := by omega
  refine ⟨h.listsGood, ?_, ?_, ?_, ?_⟩
  · intro a ha
    rw [hq] at ha
    simp only [List.mem_append, List.mem_singleton] at ha
    rcases ha with ha | rfl
    · exact h.tasksGood a ha
    · dsimp
      exact ⟨hl, hd, by omega⟩
  · have := h.listsSize
    simp only [alloc.vec.Vec.length, hq, List.length_append, List.length_singleton]
    simp only [alloc.vec.Vec.length] at *
    omega
  · simp only [alloc.vec.Vec.length, hq, List.length_append, List.length_singleton]
    simp only [alloc.vec.Vec.length] at *
    omega
  · simp only [hq, hqi, List.drop_append, Nat.sub_eq_zero_of_le hcursor,
      List.drop_zero, debt_append, debt_cons, debt_nil]
    omega

theorem WalkCore.child (h : WalkCore R N D lists queue qi)
    (hi : qi.val < queue.length) (f : api_relations.Fetch)
    (hf : f = queue.val[qi.val]) (p qi' : Usize)
    (hp : p.val = f.pos.val+1) (hpos : f.pos.val < R)
    (hqi : qi'.val = qi.val+1) (hD : D ≤ 3) (hd : f.depth.val < D)
    (child : RelList) (hc : Good N child ∧ child.length ≤ R)
    (lists' : RelLists) (hlists : lists'.val = lists.val ++ [child])
    (d' : U64) (hdepth : d'.val = f.depth.val+1)
    (li : Usize) (hli : li.val = lists.length)
    (queue' : FetchQueue)
    (hq : queue'.val = queue.val ++ [{f with pos := p},
      {depth := d', list := li, pos := 0#usize}]) :
    WalkCore R N D lists' queue' qi' := by
  have hfm : f ∈ queue.val := hf ▸ List.getElem_mem hi
  obtain ⟨hl, hdf, hb⟩ := h.tasksGood f hfm
  have hw := weight_succ R f p hp hpos
  have hnext := cost_next R f.depth.val (by omega)
  have hchild := weight_child R d' li
  rw [hdepth] at hchild
  have he := debt_drop R queue.val qi.val hi
  rw [← hf] at he
  have hfuel := h.fuel
  rw [he] at hfuel
  have hcursor : qi.val+1 ≤ queue.length := by omega
  have hlen : lists'.length = lists.length+1 := by
    simp [alloc.vec.Vec.length, hlists]
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · intro l hm
    rw [hlists] at hm
    simp only [List.mem_append, List.mem_singleton] at hm
    rcases hm with hm | rfl
    · exact h.listsGood l hm
    · exact hc
  · intro a ha
    rw [hq] at ha
    simp only [List.mem_append, List.mem_cons, List.not_mem_nil, or_false] at ha
    rcases ha with ha | rfl | rfl
    · obtain ⟨hal, had, hap⟩ := h.tasksGood a ha
      exact ⟨by scalar_tac, had, hap⟩
    · dsimp; exact ⟨by scalar_tac, hdf, by omega⟩
    · dsimp; exact ⟨by scalar_tac, by omega, by simp⟩
  · have := h.listsSize
    simp only [alloc.vec.Vec.length, hq, List.length_append, List.length_cons, List.length_nil]
    simp only [alloc.vec.Vec.length] at *
    omega
  · simp only [alloc.vec.Vec.length, hq, List.length_append, List.length_cons, List.length_nil]
    simp only [alloc.vec.Vec.length] at *
    omega
  · simp only [hq, hqi, List.drop_append, Nat.sub_eq_zero_of_le hcursor,
      List.drop_zero, debt_append, debt_cons, debt_nil]
    omega

abbrev WalkState := RelLists × FetchQueue × alloc.vec.Vec (U64 × I64 × Usize) × Bool × Usize

def WalkInv (R N D : Nat) (x : WalkState) : Prop :=
  WalkCore R N D x.1 x.2.1 x.2.2.2.2 ∧ Good N x.2.2.1 ∧ x.2.2.1.length ≤ x.2.2.2.2.val

theorem good_vec_append (n : Nat) (v v' : alloc.vec.Vec α) (x : α) [Indexed α]
    (hv : Good n v) (he : v'.val = v.val ++ [x]) (hx : Good n x) : Good n v' := by
  dsimp only [Good, Indexed.valid] at *
  rw [he]
  intro a ha
  simp only [List.mem_append, List.mem_singleton] at ha
  rcases ha with ha | rfl
  · exact hv a ha
  · exact hx

macro "finish_walk" : tactic => `(tactic| (
  repeat' (first
    | assumption
    | (simp only [bind_tc_ok, bind_ok, WP.spec_ok, Bool.false_eq_true, Bool.true_eq_false, ↓reduceIte, ↓reduceDIte])
    | step
    | (dsimp only)
    | split)
  all_goals try (dsimp only [WalkInv]; refine ⟨⟨by assumption, ?_, ?_⟩, ?_, by assumption⟩)
  all_goals try assumption
  all_goals try (apply good_vec_append <;> first
    | assumption
    | (simp only [Good, Indexed.valid, true_and]; assumption))
  all_goals try scalar_tac
  all_goals try grind))

@[step] theorem api_relations.walk_loop_total
  (s : Snapshot) (user shortroomid : U64) («from» : Option I64) (dir : Dir)
  (max_depth : U64) («to» : Option I64) (filter_event_type : Option Kind)
  (filter_rel_type : Option RelType) (limit : U64)
  (lists : RelLists) (queue : FetchQueue) (out : alloc.vec.Vec (U64 × I64 × Usize))
  (done1 : Bool) (qi : Usize)
  (hr : (s.relations.length+1)^4 < Usize.max) (hd : max_depth.val ≤ 3)
  (hInv : WalkInv s.relations.length s.pdus.length max_depth.val (lists,queue,out,done1,qi)) :
  api_relations.walk_loop s user shortroomid «from» dir max_depth «to» filter_event_type
    filter_rel_type limit lists queue out done1 qi ⦃ r => Good s.pdus.length r ⦄ := by
  unfold api_relations.walk_loop
  apply loop_idx_spec _ (fun x => x.2.2.2.2) ((s.relations.length+1)^4)
    (WalkInv s.relations.length s.pdus.length max_depth.val) _ ?_ _ hInv ?_
  · intro x hin hx
    rcases x with ⟨lists,queue,out,done1,qi⟩
    dsimp only
    obtain ⟨hcore, hout, hsize⟩ := hin
    have hcap : queue.length < Usize.max := lt_of_le_of_lt hcore.capacity hr
    have hlcap : lists.length < Usize.max := lt_of_le_of_lt hcore.listsSize hcap
    have houtcap : out.length < Usize.max := lt_of_le_of_lt (le_trans hsize hcore.cursor) hcap
    unfold api_relations.walk_loop.body
    by_cases hdone : done1 = true
    · simp only [hdone, Bool.false_eq_true, Bool.true_eq_false, reduceIte, WP.spec_ok]
      exact hout
    · simp only [hdone, Bool.false_eq_true, Bool.true_eq_false, reduceIte]
      by_cases hi : qi < alloc.vec.Vec.len queue
      · simp only [hi, Bool.false_eq_true, Bool.true_eq_false, reduceIte, lift, bind_tc_ok, bind_ok]
        by_cases htake : UScalar.cast .U64 (alloc.vec.Vec.len out) < limit
        · simp only [htake, Bool.false_eq_true, Bool.true_eq_false, reduceIte]
          step as ⟨f, hf⟩
          have hfm : f ∈ queue.val := hf ▸ List.getElem_mem (by scalar_tac)
          obtain ⟨hfl, hfd, hfp⟩ := hcore.tasksGood f hfm
          step as ⟨qi1, hqi1⟩
          step as ⟨v, hv⟩
          have hvm : v ∈ lists.val := hv ▸ List.getElem_mem hfl
          obtain ⟨hvGood, hvSize⟩ := hcore.listsGood v hvm
          by_cases hp : f.pos < alloc.vec.Vec.len v
          · simp only [hp, Bool.false_eq_true, Bool.true_eq_false, reduceIte]
            step as ⟨count, p, hcp⟩
            have hpm : (count,p) ∈ v.val := hcp ▸ List.getElem_mem (by scalar_tac)
            have hpGood : p.val < s.pdus.length := by
              have := hvGood (count,p) hpm
              simpa [Good, Indexed.valid] using this
            have hpos : f.pos.val < s.relations.length := by scalar_tac
            step as ⟨pos1, hpos1⟩
            step as ⟨queue1, hqueue1⟩
            have hc1 := hcore.next (by scalar_tac) f hf pos1 qi1 hpos1 hpos hqi1 queue1 hqueue1
            have hqcap : queue1.length < Usize.max := lt_of_le_of_lt hc1.capacity hr
            simp only [bind_tc_ite, bind_ite]
            by_cases hdepth : f.depth < max_depth
            · simp only [hdepth, Bool.false_eq_true, Bool.true_eq_false, reduceIte]
              step as ⟨child, hchild, hchildsize⟩
              step as ⟨lists1, hlists1⟩
              have hlen1 : lists1.length = lists.length+1 := by simp [alloc.vec.Vec.length, hlists1]
              step as ⟨depth1, hdepth1⟩
              step as ⟨li, hli⟩
              have hli' : li.val = lists.length := by scalar_tac
              step as ⟨queue2, hqueue2⟩
              have hq2 : queue2.val = queue.val ++
                  [{f with pos := pos1}, {depth := depth1, list := li, pos := 0#usize}] := by
                simp [hqueue2, hqueue1, List.append_assoc]
              have hc2 := hcore.child (by scalar_tac) f hf pos1 qi1 hpos1 hpos hqi1 hd
                (by scalar_tac) child ⟨hchild,hchildsize⟩ lists1 hlists1 depth1 hdepth1 li hli' queue2 hq2
              have hqiBound : qi1.val ≤ (s.relations.length+1)^4 := by have := hc2.fuel; omega
              finish_walk
            · simp only [hdepth, Bool.false_eq_true, Bool.true_eq_false, reduceIte]
              have hqiBound : qi1.val ≤ (s.relations.length+1)^4 := by have := hc1.fuel; omega
              finish_walk
          · simp only [hp, Bool.false_eq_true, Bool.true_eq_false, reduceIte]
            have hc1 := hcore.advance (by scalar_tac) qi1 hqi1
            have hqiBound : qi1.val ≤ (s.relations.length+1)^4 := by have := hc1.fuel; omega
            finish_walk
        · simp only [htake, Bool.false_eq_true, Bool.true_eq_false, reduceIte]
          finish_walk
      · simp only [hi, Bool.false_eq_true, Bool.true_eq_false, reduceIte]
        finish_walk
  · have := hInv.1.fuel
    omega


@[step] theorem api_relations.walk_total
  (s : Snapshot) (user shortroomid : U64) (target_count : I64) («from» : Option I64)
  (dir : Dir) (max_depth : U64) («to» : Option I64) (filter_event_type : Option Kind)
  (filter_rel_type : Option RelType) (limit : U64)
  (hr : (s.relations.length+1)^4 < Usize.max) (hd : max_depth.val ≤ 3) :
    api_relations.walk s user shortroomid target_count «from» dir max_depth «to»
      filter_event_type filter_rel_type limit ⦃ r => Good s.pdus.length r ⦄ := by
  unfold api_relations.walk
  step as ⟨v,hv,hvsize⟩
  step as ⟨lists,hlists⟩
  step as ⟨queue,hqueue⟩
  apply api_relations.walk_loop_total _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ hr hd
  refine ⟨?_, by clean, by clean⟩
  refine ⟨?_, ?_, ?_, ?_, ?_⟩
  · simpa [hlists] using (And.intro hv hvsize)
  · simp [hqueue, hlists, alloc.vec.Vec.length]
  · simp [alloc.vec.Vec.length, hlists, hqueue]
  · simp [alloc.vec.Vec.length, hqueue]
  · simpa [hqueue, weight] using initial_weight s.relations.length



end tuwunel_kernel.Verified.TuwunelTransitionTotal
