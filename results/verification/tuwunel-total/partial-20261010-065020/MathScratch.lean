import HelpersScratch
open Aeneas Aeneas.Std Result tuwunel_kernel
open H5iAppLib
namespace tuwunel_kernel.Solution
set_option maxHeartbeats 500000
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

end tuwunel_kernel.Solution
