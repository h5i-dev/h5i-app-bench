import MathScratch
open Aeneas Aeneas.Std Result tuwunel_kernel tuwunel_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP
namespace tuwunel_kernel.Solution
set_option maxHeartbeats 500000
set_option maxRecDepth 4096
set_option Elab.async false






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

end tuwunel_kernel.Solution
