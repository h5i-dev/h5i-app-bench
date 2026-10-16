import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit

namespace rustfs_kernel.Solution

set_option maxHeartbeats 2000000
open ControlFlow

/-- A finite execution, with a postcondition on successful results. -/
def Finishes {α : Type} (m : Result α) (P : α → Prop) : Prop :=
  (∃ x, m = ok x ∧ P x) ∨ ∃ e, m = fail e

namespace Finishes

theorem ret {α : Type} {x : α} {P : α → Prop} (h : P x) : Finishes (ok x) P :=
  .inl ⟨x, rfl, h⟩

theorem error {α : Type} (e : Error) (P : α → Prop) : Finishes (fail e) P :=
  .inr ⟨e, rfl⟩

theorem of_spec {α : Type} {m : Result α} {P : α → Prop} (h : m ⦃ P ⦄) :
    Finishes m P := .inl ((WP.spec_equiv_exists _ _).mp h)

theorem mono {α : Type} {m : Result α} {P Q : α → Prop}
    (h : Finishes m P) (hq : ∀ x, P x → Q x) : Finishes m Q := by
  rcases h with ⟨x, hx, hp⟩ | h
  · exact .inl ⟨x, hx, hq x hp⟩
  · exact .inr h

theorem bind {α β : Type} {m : Result α} {k : α → Result β} {P : α → Prop}
    {Q : β → Prop} (h : Finishes m P)
    (hk : ∀ x, m = ok x → P x → Finishes (k x) Q) :
    Finishes (Std.bind m k) Q := by
  rcases h with ⟨x, hx, hp⟩ | ⟨e, he⟩
  · simpa [hx] using hk x hx hp
  · simp only [he, bind_fail]; exact error e Q

theorem loop_nat {α β : Type} (body : α → Result (ControlFlow α β))
    (μ : α → Nat) (P : α → Prop) (Q : β → Prop)
    (hs : ∀ x, P x → Finishes (body x) (fun r => match r with
      | .done y => Q y
      | .cont y => P y ∧ μ y < μ x)) :
    ∀ x, P x → Finishes (loop body x) Q := by
  intro x
  induction h : μ x using Nat.strong_induction_on generalizing x with
  | _ n ih =>
    intro hx
    rw [loop]
    apply bind (hs x hx)
    intro r _ hr
    cases r with
    | done y => exact ret hr
    | cont y => exact ih (μ y) (h ▸ hr.2) y rfl hr.1

theorem add (x y : Usize) : Finishes (x + y) (fun z => z.val = x.val + y.val) := by
  by_cases h : x.val + y.val ≤ Usize.max
  · exact of_spec (Usize.add_spec h)
  · change Finishes (UScalar.tryMk .Usize (x.val + y.val)) _
    unfold UScalar.tryMk UScalar.tryMkOpt
    split
    · rename_i hb
      exfalso; apply h
      simp only [UScalar.check_bounds_eq_inBounds, UScalar.inBounds] at hb
      scalar_tac
    · exact error _ _

theorem sub (x y : Usize) : Finishes (x - y) (fun z => z.val = x.val - y.val) := by
  by_cases h : y.val ≤ x.val
  · exact (of_spec (Usize.sub_spec h)).mono (fun _ h => h.1)
  · change Finishes (UScalar.sub x y) _
    unfold UScalar.sub
    simp only [show x.val < y.val from by omega, ↓reduceIte]
    exact error _ _

theorem index {α : Type} (s : Slice α) (i : Usize) :
    Finishes (s.index_usize i) (fun x => s.val[i.val]? = some x) := by
  unfold Slice.index_usize
  cases h : s.val[i.val]? with
  | none => exact error _ _
  | some x => exact ret rfl

theorem vindex {α : Type} (s : alloc.vec.Vec α) (i : Usize) :
    Finishes (alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice α) s i)
      (fun x => s.val[i.val]? = some x) := by
  simpa [alloc.vec.Vec.index, alloc.vec.Vec.val] using index s.slice i

theorem push {α : Type} (v : alloc.vec.Vec α) (x : α) :
    Finishes (alloc.vec.Vec.push v x) (fun w => w.val = v.val ++ [x]) := by
  unfold alloc.vec.Vec.push
  dsimp only
  split
  · exact ret (by simp)
  · exact error _ _

theorem clone (v : alloc.vec.Vec U8) :
    Finishes (alloc.vec.CloneVec.clone core.clone.CloneU8 v) (fun w => w = v) := by
  rw [u8vec_clone]; exact ret rfl

theorem to_vec (s : Slice U8) :
    Finishes (alloc.slice.Slice.to_vec core.clone.CloneU8 s) (fun w => w.val = s.val) := by
  apply of_spec
  step*; simp_all [alloc.vec.Vec.val]

end Finishes

@[simp] theorem deref_eq {α : Type} (v : alloc.vec.Vec α) :
    alloc.vec.Vec.deref v = v.slice := by
  apply (Slice.eq_iff _ _).mpr
  simp only [alloc.vec.Vec.deref, Slice.from_val, alloc.vec.Vec.val]

theorem loop_fin {α β : Type} (body : α → Result (ControlFlow α β))
    (μ : α → Nat) (Q : α → β → Prop)
    (hs : ∀ x, Finishes (body x) (fun r => match r with
      | .done y => Q x y
      | .cont y => μ y < μ x ∧ ∀ z, Q y z → Q x z)) :
    ∀ x, Finishes (loop body x) (Q x) := by
  intro x
  induction h : μ x using Nat.strong_induction_on generalizing x with
  | _ n ih =>
    rw [loop]
    apply Finishes.bind (hs x)
    intro r _ hr
    cases r with
    | done y => exact Finishes.ret hr
    | cont y => exact (ih (μ y) (h ▸ hr.1) y rfl).mono hr.2

macro "fstep" t:term " with " x:ident h:ident : tactic => `(tactic| (
  try simp only [deref_eq]
  apply Finishes.bind $t
  intro $x _ $h
  try dsimp only at $h ⊢
))

macro "fprimitive" : tactic => `(tactic| (
  first
  | exact Finishes.add _ _
  | exact Finishes.sub _ _
  | exact Finishes.index _ _
  | exact Finishes.vindex _ _
  | exact Finishes.push _ _
  | exact Finishes.clone _
  | exact Finishes.to_vec _
))

theorem slice_fin (s : Slice U8) (a b : Usize) :
    Finishes (bytes.slice s a b) (fun v => v.val.length = b.val - a.val) := by
  unfold bytes.slice bytes.slice_loop
  refine (loop_fin (fun x => bytes.slice_loop.body s b x.1 x.2)
    (fun x => b.val - x.2.val)
    (fun x (v : alloc.vec.Vec U8) => v.val.length = x.1.val.length + (b.val - x.2.val))
    ?_ (alloc.vec.Vec.new U8, a)).mono ?_
  · rintro ⟨out, i⟩
    unfold bytes.slice_loop.body
    dsimp only
    split
    · rename_i hi
      fstep (Finishes.index s i) with c hc
      fstep (Finishes.push out c) with out' ho
      fstep (Finishes.add i 1#usize) with j hj
      apply Finishes.ret
      simp only [ho, List.length_append, List.length_singleton]
      simp only [UScalar.ofNatCore_val_eq] at hj
      constructor
      · scalar_tac
      · intro v hv; scalar_tac
    · apply Finishes.ret; scalar_tac
  · intro v hv
    simpa only [alloc.vec.Vec.new, alloc.vec.Vec.from_val, List.length_nil, Nat.zero_add] using hv

theorem concat_fin (a b : Slice U8) :
    Finishes (bytes.concat a b) (fun v => v.val.length = a.val.length + b.val.length) := by
  unfold bytes.concat
  fstep (slice_fin a 0#usize (Slice.len a)) with out ho
  unfold bytes.concat_loop
  refine (loop_fin (fun x => bytes.concat_loop.body b x.1 x.2)
    (fun x => b.val.length - x.2.val)
    (fun x (v : alloc.vec.Vec U8) => v.val.length = x.1.val.length + (b.val.length - x.2.val)) ?_
    (out, 0#usize)).mono ?_
  · rintro ⟨out, i⟩
    unfold bytes.concat_loop.body
    dsimp only
    split
    · rename_i hi
      fstep (Finishes.index b i) with c hc
      fstep (Finishes.push out c) with out' ho
      fstep (Finishes.add i 1#usize) with j hj
      apply Finishes.ret
      simp only [ho, List.length_append, List.length_singleton]
      simp only [UScalar.ofNatCore_val_eq] at hj
      constructor
      · scalar_tac
      · intro v hv; scalar_tac
    · apply Finishes.ret; scalar_tac
  · intro v hv
    simp only [Slice.len_val, Slice.length, Nat.sub_zero, UScalar.ofNatCore_val_eq] at ho hv
    omega

theorem eq_fin (a b : Slice U8) : Finishes (bytes.eq a b) (fun _ => True) := by
  unfold bytes.eq
  dsimp only
  split
  · exact Finishes.ret trivial
  · unfold bytes.eq_loop
    apply Finishes.loop_nat _ (fun i => a.val.length + 1 - i.val)
      (fun _ => True) (fun _ => True) ?_ _ trivial
    intro i _
    unfold bytes.eq_loop.body
    dsimp only
    split
    · rename_i hi
      fstep (Finishes.index a i) with c hc
      fstep (Finishes.index b i) with d hd
      split
      · exact Finishes.ret trivial
      · fstep (Finishes.add i 1#usize) with j hj
        apply Finishes.ret; constructor
        · trivial
        · scalar_tac
    · exact Finishes.ret trivial

theorem starts_fin (s p : Slice U8) (a : Usize) :
    Finishes (bytes.starts_with_at s a p) (fun _ => True) := by
  unfold bytes.starts_with_at
  dsimp only
  split
  · exact Finishes.ret trivial
  · fstep (Finishes.sub (Slice.len s) a) with n hn
    split
    · exact Finishes.ret trivial
    · unfold bytes.starts_with_at_loop
      apply Finishes.loop_nat _ (fun i => p.val.length + 1 - i.val)
        (fun _ => True) (fun _ => True) ?_ _ trivial
      intro i _
      unfold bytes.starts_with_at_loop.body
      dsimp only
      split
      · rename_i hi
        fstep (Finishes.add a i) with j hj
        fstep (Finishes.index s j) with c hc
        fstep (Finishes.index p i) with d hd
        split
        · exact Finishes.ret trivial
        · fstep (Finishes.add i 1#usize) with k hk
          apply Finishes.ret; constructor
          · trivial
          · scalar_tac
      · exact Finishes.ret trivial

theorem find_fin (s p : Slice U8) (a : Usize) :
    Finishes (bytes.find_from s a p) (fun o => ∀ j, o = some j →
      a.val ≤ j.val ∧ j.val + p.val.length ≤ s.val.length) := by
  unfold bytes.find_from bytes.find_from_loop
  apply loop_fin (fun i => bytes.find_from_loop.body s p i)
    (fun i => s.val.length + 1 - i.val)
    (fun i o => ∀ j, o = some j → i.val ≤ j.val ∧ j.val + p.val.length ≤ s.val.length)
  intro i
  unfold bytes.find_from_loop.body
  dsimp only
  split
  · rename_i hi
    fstep (Finishes.sub (Slice.len s) i) with n hn
    split
    · rename_i hp
      fstep (starts_fin s p i) with b hb
      split
      · apply Finishes.ret
        intro j hj
        cases Option.some.inj hj
        scalar_tac
      · fstep (Finishes.add i 1#usize) with k hk
        apply Finishes.ret
        constructor
        · scalar_tac
        · intro o ho j hj
          obtain ⟨h1, h2⟩ := ho j hj
          constructor
          · scalar_tac
          · exact h2
    · apply Finishes.ret; simp
  · apply Finishes.ret; simp

theorem contains_fin (s p : Slice U8) : Finishes (bytes.contains s p) (fun _ => True) := by
  unfold bytes.contains
  fstep (find_fin s p 0#usize) with o ho
  cases o <;> exact Finishes.ret trivial

theorem pending_fin (p : awsvars.Pending) :
    Finishes (awsvars.pending_clone p) (fun q => q = p) := by
  unfold awsvars.pending_clone
  fstep (Finishes.clone p.text) with v hv
  subst v
  exact Finishes.ret rfl

macro "fbase" : tactic => `(tactic| (
  first
  | exact eq_fin _ _
  | exact starts_fin _ _ _
  | exact contains_fin _ _
  | exact pending_fin _
  | exact slice_fin _ _ _
  | exact concat_fin _ _
  | fprimitive
  | exact (Finishes.add _ _).mono (fun _ _ => True.intro)
  | exact (Finishes.sub _ _).mono (fun _ _ => True.intro)
))

macro "fplain_using " "[" solver:tacticSeq "]" : tactic => `(tactic| (
  try dsimp only
  repeat' first
  | (simp only [bind_ok, lift])
  | $solver
  | (apply Finishes.ret; first
      | trivial
      | (constructor; trivial; scalar_tac)
      | scalar_tac)
  | (apply Finishes.bind (by $solver)
     intro x hx hp
     try dsimp only at hp ⊢)
  | split
))

macro "fplain" : tactic => `(tactic| fplain_using [fbase])

theorem clone_list_fin (s : Slice (alloc.vec.Vec U8)) :
    Finishes (awsvars.clone_list s) (fun _ => True) := by
  unfold awsvars.clone_list awsvars.clone_list_loop
  apply Finishes.loop_nat _ (fun x => s.val.length + 1 - x.2.val)
    (fun _ => True) (fun _ => True) ?_ _ trivial
  rintro ⟨out, i⟩ _
  unfold awsvars.clone_list_loop.body
  fplain

macro "fclone" : tactic => `(tactic| first | fbase | exact clone_list_fin _)

theorem userid_fin (c : awsvars.ClaimStrings) :
    Finishes (awsvars.userid_strings c) (fun _ => True) := by
  unfold awsvars.userid_strings
  fplain_using [fclone]

macro "fuserid" : tactic => `(tactic| first | fclone | exact userid_fin _)

theorem resolve_fin (ctx : awsvars.VarContext) (s : Slice U8) :
    Finishes (awsvars.resolve ctx s) (fun _ => True) := by
  unfold awsvars.resolve
  simp only [lift, bind_ok]
  fplain_using [fuserid]

macro "fresolve" : tactic => `(tactic| first | fuserid | exact resolve_fin _ _)

theorem multiple_fin (ctx : awsvars.VarContext) (s : Slice U8) :
    Finishes (awsvars.resolve_multiple ctx s) (fun _ => True) := by
  unfold awsvars.resolve_multiple
  simp only [lift, bind_ok]
  fplain_using [fresolve]

theorem member_fin (s : Slice (alloc.vec.Vec U8)) (p : Slice U8) :
    Finishes (bytes.member s p) (fun _ => True) := by
  unfold bytes.member bytes.member_loop
  apply Finishes.loop_nat _ (fun i => s.val.length + 1 - i.val)
    (fun _ => True) (fun _ => True) ?_ _ trivial
  intro i _
  unfold bytes.member_loop.body
  fplain

macro "fmember" : tactic => `(tactic| first | fresolve | exact member_fin _ _)

theorem dedup_fin (s : Slice (alloc.vec.Vec U8)) :
    Finishes (awsvars.dedup s) (fun _ => True) := by
  unfold awsvars.dedup awsvars.dedup_loop
  apply Finishes.loop_nat _ (fun x => s.val.length + 1 - x.2.val)
    (fun _ => True) (fun _ => True) ?_ _ trivial
  rintro ⟨out, i⟩ _
  unfold awsvars.dedup_loop.body
  fplain_using [fmember]

theorem extend_fin (out : alloc.vec.Vec (alloc.vec.Vec U8)) (s : Slice (alloc.vec.Vec U8)) :
    Finishes (awsvars.extend out s) (fun _ => True) := by
  unfold awsvars.extend awsvars.extend_loop
  apply Finishes.loop_nat _ (fun x => s.val.length + 1 - x.2.val)
    (fun _ => True) (fun _ => True) ?_ _ trivial
  rintro ⟨out, i⟩ _
  unfold awsvars.extend_loop.body
  fplain

theorem texts_fin (s : Slice awsvars.Pending) :
    Finishes (awsvars.texts s) (fun _ => True) := by
  unfold awsvars.texts awsvars.texts_loop
  apply Finishes.loop_nat _ (fun x => s.val.length + 1 - x.2.val)
    (fun _ => True) (fun _ => True) ?_ _ trivial
  rintro ⟨out, i⟩ _
  unfold awsvars.texts_loop.body
  fplain

theorem closing_fin (s : Slice U8) (a : Usize) :
    Finishes (awsvars.closing s a) (fun r => a.val ≤ r.1.val ∧
      (r.2 = 0#usize → r.1.val < s.val.length)) := by
  unfold awsvars.closing awsvars.closing_loop
  apply Finishes.loop_nat (fun x : Usize × Usize => awsvars.closing_loop.body s x.1 x.2)
    (fun x => 2 * (s.val.length + 1 - x.2.val) + if x.1 = 0#usize then 0 else 1)
    (fun x => a.val ≤ x.2.val ∧ (x.1 = 0#usize → x.2.val < s.val.length))
    (fun r : Usize × Usize => a.val ≤ r.1.val ∧ (r.2 = 0#usize → r.1.val < s.val.length))
  · rintro ⟨brace, e⟩ ⟨ha, hz⟩
    unfold awsvars.closing_loop.body
    dsimp only
    split
    · rename_i he
      split
      · rename_i hb
        have hb0 : brace ≠ 0#usize := by scalar_tac
        fstep (Finishes.index s e) with c hc
        have hf : Finishes
            (if c = 123#u8 then brace + 1#usize else
              if c = 125#u8 then brace - 1#usize else ok brace)
            (fun _ => True) := by fplain
        fstep hf with b hbb
        split
        · rename_i hbn
          fstep (Finishes.add e 1#usize) with e' he'
          have hb' : b ≠ 0#usize := by scalar_tac
          apply Finishes.ret
          simp only [hb', ↓reduceIte]
          constructor
          · constructor
            · scalar_tac
            · intro h; contradiction
          · scalar_tac
        · rename_i hbn
          have hb' : b = 0#usize := by scalar_tac
          apply Finishes.ret
          simp only [hb', ↓reduceIte]
          constructor
          · exact ⟨ha, fun _ => by scalar_tac⟩
          · omega
      · exact Finishes.ret ⟨ha, hz⟩
    · exact Finishes.ret ⟨ha, hz⟩
  · exact ⟨Nat.le_refl _, by simp⟩

def copyBody (s : Slice awsvars.Pending) (n : Nat)
    (x : alloc.vec.Vec awsvars.Pending × Usize) :
    Result (ControlFlow (alloc.vec.Vec awsvars.Pending × Usize) (alloc.vec.Vec awsvars.Pending)) := do
  if x.2.val < n then
    let p ← s.index_usize x.2
    let q ← awsvars.pending_clone p
    let out ← alloc.vec.Vec.push x.1 q
    let j ← x.2 + 1#usize
    ok (.cont (out, j))
  else ok (.done x.1)

theorem copy_fin (s : Slice awsvars.Pending) (n : Nat) (hn : n ≤ s.val.length)
    (out : alloc.vec.Vec awsvars.Pending) (i : Usize) :
    Finishes (loop (copyBody s n) (out, i))
      (fun v => v.val = out.val ++ (s.val.take n).drop i.val) := by
  apply loop_fin (copyBody s n) (fun x => n + 1 - x.2.val)
    (fun x v => v.val = x.1.val ++ (s.val.take n).drop x.2.val)
  rintro ⟨out, i⟩
  unfold copyBody
  dsimp only
  split
  · rename_i hi
    fstep (Finishes.index s i) with p hp
    fstep (pending_fin p) with q hq
    subst q
    fstep (Finishes.push out p) with out' ho
    fstep (Finishes.add i 1#usize) with j hj
    apply Finishes.ret
    constructor
    · simp only [UScalar.ofNatCore_val_eq] at hj
      dsimp only
      omega
    · intro v hv
      rw [hv, ho, List.append_assoc]
      have hil : i.val < (s.val.take n).length := by simp; omega
      rw [List.drop_eq_getElem_cons hil]
      have hpi : s.val[i.val] = p := by
        have hi' : i.val < s.val.length := by omega
        simpa only [List.getElem?_eq_getElem hi', Option.some.injEq] using hp
      simp only [List.getElem_take, hpi, hj, UScalar.ofNatCore_val_eq, List.singleton_append]
  · apply Finishes.ret
    have he : (s.val.take n).drop i.val = [] :=
      List.drop_eq_nil_of_le (by simp; omega)
    simp [he]

theorem splice_fin (s : Slice awsvars.Pending) (i : Usize) (new : Slice awsvars.Pending)
    (hi : i.val < s.val.length) :
    Finishes (awsvars.splice s i new)
      (fun v => v.val = s.val.take i.val ++ new.val ++ s.val.drop (i.val + 1)) := by
  unfold awsvars.splice
  have h0 : Finishes (awsvars.splice_loop0 s i (alloc.vec.Vec.new awsvars.Pending) 0#usize)
      (fun v => v.val = s.val.take i.val) := by
    unfold awsvars.splice_loop0
    change Finishes (loop (copyBody s i.val) (alloc.vec.Vec.new _, 0#usize)) _
    exact (copy_fin s i.val (by omega) _ _).mono (by intro v hv; simpa using hv)
  fstep h0 with out ho
  have h1 : Finishes (awsvars.splice_loop1 new out 0#usize)
      (fun v => v.val = out.val ++ new.val) := by
    unfold awsvars.splice_loop1
    change Finishes (loop (copyBody new new.val.length) (out, 0#usize)) _
    exact (copy_fin new new.val.length (by omega) _ _).mono (by intro v hv; simpa using hv)
  fstep h1 with out' ho'
  fstep (Finishes.add i 1#usize) with j hj
  unfold awsvars.splice_loop2
  change Finishes (loop (copyBody s s.val.length) (out', j)) _
  apply (copy_fin s s.val.length (by omega) _ _).mono
  intro v hv
  simpa [ho', ho, hj] using hv

theorem wrap_fin («prefix» : Slice U8) (values : Slice (alloc.vec.Vec U8))
    (suffix : Slice U8) (a : Usize) (ha : «prefix».val.length = a.val) :
    Finishes (awsvars.wrap_all «prefix» values suffix a)
      (fun out => ∀ p ∈ out.val, p.text.val.length - p.resume.val = suffix.val.length) := by
  unfold awsvars.wrap_all awsvars.wrap_all_loop
  apply Finishes.loop_nat
    (fun x : alloc.vec.Vec awsvars.Pending × Usize =>
      awsvars.wrap_all_loop.body «prefix» values suffix a x.1 x.2)
    (fun x => values.val.length + 1 - x.2.val)
    (fun x => ∀ p ∈ x.1.val, p.text.val.length - p.resume.val = suffix.val.length)
    (fun out => ∀ p ∈ out.val, p.text.val.length - p.resume.val = suffix.val.length)
  · rintro ⟨out, i⟩ hout
    unfold awsvars.wrap_all_loop.body
    dsimp only
    split
    · rename_i hi
      fstep (Finishes.index values i) with v hv
      fstep (concat_fin «prefix» v.slice) with v1 h1
      fstep (concat_fin v1.slice suffix) with v2 h2
      fstep (Finishes.add a (alloc.vec.Vec.len v)) with j hj
      fstep (Finishes.push out {text := v2, resume := j}) with out' ho
      fstep (Finishes.add i 1#usize) with k hk
      apply Finishes.ret
      constructor
      · intro p hp
        rw [ho, List.mem_append, List.mem_singleton] at hp
        rcases hp with hp | rfl
        · exact hout p hp
        · dsimp only
          change v1.val.length = «prefix».val.length + v.val.length at h1
          change v2.val.length = v1.val.length + suffix.val.length at h2
          scalar_tac
      · scalar_tac
    · exact Finishes.ret hout
  · simp

def base : Nat := Usize.max + 1

theorem base_gt_one : 1 < base := by
  have := usize_max_ge
  unfold base
  omega

/-- The base exceeds the number of results any successful substitution can produce.
Replacing a pending result with shorter unprocessed suffixes decreases their total weight. -/
def weight (p : awsvars.Pending) : Nat := base ^ (p.text.val.length - p.resume.val + 1)

def score (ps : List awsvars.Pending) : Nat := (ps.map weight).sum

theorem score_append (xs ys : List awsvars.Pending) :
    score (xs ++ ys) = score xs + score ys := by simp [score]

theorem score_cons (p : awsvars.Pending) (ps : List awsvars.Pending) :
    score (p :: ps) = weight p + score ps := by simp [score]

theorem weight_pos (p : awsvars.Pending) : 0 < weight p :=
  Nat.pow_pos (by have := base_gt_one; omega)

theorem score_bound (ps : List awsvars.Pending) (n : Nat)
    (h : ∀ p ∈ ps, p.text.val.length - p.resume.val ≤ n) :
    score ps ≤ ps.length * base ^ (n + 1) := by
  induction ps with
  | nil => simp [score]
  | cons p ps ih =>
    rw [score_cons, List.length_cons]
    have hp : weight p ≤ base ^ (n + 1) := by
      apply Nat.pow_le_pow_right (by have := base_gt_one; omega)
      have := h p (by simp)
      omega
    have ht := ih (fun q hq => h q (by simp [hq]))
    rw [Nat.add_mul, Nat.one_mul]
    omega

theorem score_replace (results : alloc.vec.Vec awsvars.Pending) (i : Usize)
    (p : awsvars.Pending) (hp : results.val[i.val]? = some p)
    (new : alloc.vec.Vec awsvars.Pending) (n : Nat)
    (hn : n < p.text.val.length - p.resume.val)
    (hnew : ∀ q ∈ new.val, q.text.val.length - q.resume.val ≤ n) :
    score ((results.val.take i.val ++ new.val ++ results.val.drop (i.val + 1)).drop i.val) <
      score (results.val.drop i.val) := by
  have hi : i.val < results.val.length := List.getElem?_eq_some_iff.mp hp |>.1
  have hpi : results.val[i.val] = p := by simpa [List.getElem?_eq_getElem hi] using hp
  rw [List.drop_eq_getElem_cons hi, hpi, score_cons]
  have hlen : (results.val.take i.val).length = i.val := by simp; omega
  rw [List.append_assoc, List.drop_append_of_le_length (by omega)]
  have hem : (results.val.take i.val).drop i.val = [] :=
    List.drop_eq_nil_of_le (by omega)
  rw [hem, List.nil_append, score_append]
  have hbound := score_bound new.val n hnew
  have hm := alloc.vec.Vec.property new
  have hpow : base ^ (n + 1) * base ≤ weight p := by
    rw [← Nat.pow_succ]
    apply Nat.pow_le_pow_right (by have := base_gt_one; omega)
    omega
  have hpos : 0 < base ^ (n + 1) := Nat.pow_pos (by have := base_gt_one; omega)
  have hlt : new.val.length * base ^ (n + 1) < base ^ (n + 1) * base := by
    rw [Nat.mul_comm (base ^ (n + 1)) base]
    apply Nat.mul_lt_mul_of_pos_right
    · unfold base; omega
    · exact hpos
  omega

def ScanPost (results : alloc.vec.Vec awsvars.Pending) (i : Usize)
    (r : alloc.vec.Vec awsvars.Pending × Bool) : Prop :=
  if r.2 then score (r.1.val.drop i.val) < score (results.val.drop i.val)
  else r.1 = results

theorem splice_modified_fin (results : alloc.vec.Vec awsvars.Pending) (i : Usize)
    (p : awsvars.Pending) (hp : results.val[i.val]? = some p)
    (new : alloc.vec.Vec awsvars.Pending) (n : Nat)
    (hn : n < p.text.val.length - p.resume.val)
    (hnew : ∀ q ∈ new.val, q.text.val.length - q.resume.val ≤ n) :
    Finishes (do let v ← awsvars.splice results.slice i new.slice; ok (v, true))
      (ScanPost results i) := by
  have hi : i.val < results.val.length := List.getElem?_eq_some_iff.mp hp |>.1
  fstep (splice_fin results.slice i new.slice hi) with v hv
  apply Finishes.ret
  simp only [ScanPost, ↓reduceIte]
  change v.val = results.val.take i.val ++ new.val ++ results.val.drop (i.val + 1) at hv
  rw [hv]
  exact score_replace results i p hp new n hn hnew

theorem scan_fin (ctx : awsvars.VarContext) (depth : Usize)
    (hinner : ∀ (s : Slice U8) (d : Usize), depth.val < d.val →
      Finishes (awsvars.resolve_aws_variables_with_depth ctx s d) (fun _ => True))
    (results : alloc.vec.Vec awsvars.Pending) (i : Usize) (p : awsvars.Pending)
    (hp : results.val[i.val]? = some p) (start : Usize) (hs : p.resume.val ≤ start.val) :
    Finishes (awsvars.scan ctx results i start depth) (ScanPost results i) := by
  induction hm : p.text.val.length + 1 - start.val using Nat.strong_induction_on
      generalizing start with
  | _ n ih =>
    rw [awsvars.scan]
    simp only [deref_eq]
    fstep (Finishes.vindex results i) with q hq
    have heq : q = p := by rw [hp] at hq; exact (Option.some.inj hq).symm
    subst q
    fstep (Finishes.clone p.text) with s hs'
    subst s
    simp only [lift, bind_ok]
    fstep (find_fin _ _ _) with pos hpos
    cases pos with
    | none => exact Finishes.ret (by simp [ScanPost])
    | some posIdx =>
      dsimp only
      have hfind := hpos posIdx rfl
      change start.val ≤ posIdx.val ∧ posIdx.val + 2 ≤ p.text.val.length at hfind
      fstep (Finishes.add posIdx 2#usize) with a ha
      fstep (closing_fin p.text.slice a) with closing hc
      rcases closing with ⟨e, brace⟩
      simp only [uncurry_apply_pair]
      dsimp only at hc
      split
      · exact Finishes.ret (by simp [ScanPost])
      · rename_i hb
        have hb0 : brace = 0#usize := by scalar_tac
        have he : e.val < p.text.val.length := hc.2 hb0
        have hea : a.val ≤ e.val := hc.1
        fstep (slice_fin p.text.slice a e) with var hv
        fstep (slice_fin p.text.slice 0#usize posIdx) with pref hpr
        fstep (Finishes.add e 1#usize) with next hnext
        fstep (slice_fin p.text.slice next (alloc.vec.Vec.len p.text)) with suffix hsu
        have hplen : pref.val.length = posIdx.val := by simpa using hpr
        have hshort : suffix.val.length < p.text.val.length - p.resume.val := by
          change suffix.val.length = p.text.val.length - next.val at hsu
          simp only [UScalar.ofNatCore_val_eq] at ha hnext
          omega
        have hrec : Finishes (awsvars.scan ctx results i next depth) (ScanPost results i) := by
          apply ih (p.text.val.length + 1 - next.val) ?_ next ?_ rfl
          · simp only [UScalar.ofNatCore_val_eq] at ha hnext
            omega
          · simp only [UScalar.ofNatCore_val_eq] at ha hnext
            omega
        have hwrap (values : Slice (alloc.vec.Vec U8)) :=
          wrap_fin pref.slice values suffix.slice posIdx hplen
        try simp only [lift, bind_ok]
        fstep (contains_fin _ _) with nested hnested
        split
        · fstep (Finishes.add depth 1#usize) with d hd
          have hdgt : depth.val < d.val := by scalar_tac
          fstep (hinner var.slice d hdgt) with inner hinner'
          split
          · fstep (Finishes.vindex inner 0#usize) with v hv'
            fstep (eq_fin v.slice var.slice) with same hsame
            split
            · exact hrec
            · fstep (hwrap inner.slice) with new hnew
              split
              · exact splice_modified_fin results i p hp new suffix.val.length hshort
                  (fun q hq => Nat.le_of_eq (hnew q hq))
              · exact hrec
          · fstep (hwrap inner.slice) with new hnew
            split
            · exact splice_modified_fin results i p hp new suffix.val.length hshort
                (fun q hq => Nat.le_of_eq (hnew q hq))
            · exact hrec
        · fstep (multiple_fin ctx var.slice) with values hvalues
          cases values with
          | none => exact hrec
          | some values =>
            dsimp only
            split
            · fstep (hwrap values.slice) with new hnew
              exact splice_modified_fin results i p hp new suffix.val.length hshort
                (fun q hq => Nat.le_of_eq (hnew q hq))
            · fstep (concat_fin pref.slice suffix.slice) with text ht
              fstep (Finishes.push (alloc.vec.Vec.new awsvars.Pending) {text := text, resume := posIdx})
                with new hnew
              apply splice_modified_fin results i p hp new suffix.val.length hshort
              intro q hq
              rw [hnew] at hq
              simp only [alloc.vec.Vec.new, alloc.vec.Vec.from_val, List.nil_append,
                List.mem_singleton] at hq
              subst q
              change text.val.length = pref.val.length + suffix.val.length at ht
              dsimp only
              omega

theorem score_skip (results : alloc.vec.Vec awsvars.Pending) (i : Usize)
    (p : awsvars.Pending) (hp : results.val[i.val]? = some p) :
    score (results.val.drop (i.val + 1)) < score (results.val.drop i.val) := by
  have hi : i.val < results.val.length := List.getElem?_eq_some_iff.mp hp |>.1
  have hpi : results.val[i.val] = p := by simpa [List.getElem?_eq_getElem hi] using hp
  rw [List.drop_eq_getElem_cons hi, hpi, score_cons]
  have := weight_pos p
  omega

theorem pass_from_fin (ctx : awsvars.VarContext) (depth : Usize)
    (hinner : ∀ (s : Slice U8) (d : Usize), depth.val < d.val →
      Finishes (awsvars.resolve_aws_variables_with_depth ctx s d) (fun _ => True))
    (results : alloc.vec.Vec awsvars.Pending) (i : Usize) :
    Finishes (awsvars.pass_from ctx results i depth) (fun _ => True) := by
  induction hm : score (results.val.drop i.val) using Nat.strong_induction_on
      generalizing results i with
  | _ n ih =>
    rw [awsvars.pass_from]
    try dsimp only
    split
    · exact Finishes.ret trivial
    · fstep (Finishes.vindex results i) with p hp
      fstep (scan_fin ctx depth hinner results i p hp p.resume (by omega)) with r hr
      rcases r with ⟨results', modified⟩
      simp only [uncurry_apply_pair]
      try dsimp only at hr
      cases modified with
      | false =>
        simp only [ScanPost, Bool.false_eq_true, ↓reduceIte] at hr
        subst results'
        simp only [Bool.false_eq_true, ↓reduceIte]
        fstep (Finishes.add i 1#usize) with j hj
        apply ih (score (results.val.drop j.val)) ?_ results j rfl
        have hh := score_skip results i p hp
        simpa [hj, hm] using hh
      | true =>
        simp only [ScanPost, ↓reduceIte] at hr
        simp only [↓reduceIte]
        exact ih (score (results'.val.drop i.val)) (hm ▸ hr) results' i rfl

theorem single_fin (ctx : awsvars.VarContext) (depth : Usize)
    (hinner : ∀ (s : Slice U8) (d : Usize), depth.val < d.val →
      Finishes (awsvars.resolve_aws_variables_with_depth ctx s d) (fun _ => True))
    (pattern : Slice U8) :
    Finishes (awsvars.resolve_single_pass ctx pattern depth) (fun _ => True) := by
  rw [awsvars.resolve_single_pass]
  simp only [deref_eq]
  fstep (Finishes.to_vec pattern) with text ht
  fstep (Finishes.push (alloc.vec.Vec.new awsvars.Pending)
    ({text := text, resume := 0#usize} : awsvars.Pending)) with results hr
  fstep (pass_from_fin ctx depth hinner results 0#usize) with out ho
  exact texts_fin out.slice

theorem pass_all_fin (ctx : awsvars.VarContext) (depth : Usize)
    (hinner : ∀ (s : Slice U8) (d : Usize), depth.val < d.val →
      Finishes (awsvars.resolve_aws_variables_with_depth ctx s d) (fun _ => True))
    (results : Slice (alloc.vec.Vec U8)) (k : Usize)
    (acc : alloc.vec.Vec (alloc.vec.Vec U8)) (changed : Bool) :
    Finishes (awsvars.pass_all ctx results k acc changed depth) (fun _ => True) := by
  induction hm : results.val.length + 1 - k.val using Nat.strong_induction_on
      generalizing k acc changed with
  | _ n ih =>
    rw [awsvars.pass_all]
    simp only [deref_eq]
    try dsimp only
    split
    · exact Finishes.ret trivial
    · rename_i hk
      fstep (Finishes.index results k) with v hv
      fstep (single_fin ctx depth hinner v.slice) with resolved hr
      have hdiff : Finishes
          (if alloc.vec.Vec.len resolved > 1#usize then ok true else
            if alloc.vec.Vec.len resolved = 1#usize then do
              let w ← alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice (alloc.vec.Vec U8))
                resolved 0#usize
              let b ← bytes.eq w.slice v.slice
              ok (¬b)
            else ok false) (fun _ => True) := by fplain
      fstep hdiff with differs hd
      fstep (extend_fin acc resolved.slice) with acc' ha
      fstep (Finishes.add k 1#usize) with j hj
      have hc : Finishes (if changed then ok true else ok differs) (fun _ => True) := by
        split <;> exact Finishes.ret trivial
      fstep hc with changed' hc'
      apply ih (results.val.length + 1 - j.val) ?_ j acc' changed' rfl
      scalar_tac

theorem fixpoint_fin (ctx : awsvars.VarContext) (depth : Usize)
    (hinner : ∀ (s : Slice U8) (d : Usize), depth.val < d.val →
      Finishes (awsvars.resolve_aws_variables_with_depth ctx s d) (fun _ => True))
    (results : alloc.vec.Vec (alloc.vec.Vec U8)) (iteration : Usize) :
    Finishes (awsvars.fixpoint ctx results iteration depth) (fun _ => True) := by
  induction hm : 10 - iteration.val using Nat.strong_induction_on generalizing iteration results with
  | _ n ih =>
    rw [awsvars.fixpoint]
    simp only [deref_eq]
    split
    · exact Finishes.ret trivial
    · rename_i hit
      fstep (pass_all_fin ctx depth hinner results.slice 0#usize (alloc.vec.Vec.new _) false)
        with r hr
      rcases r with ⟨new, changed⟩
      simp only [uncurry_apply_pair]
      fstep (dedup_fin new.slice) with results' hd
      split
      · fstep (Finishes.add iteration 1#usize) with j hj
        apply ih (10 - j.val) ?_ results' j rfl
        scalar_tac
      · exact Finishes.ret trivial

/-- The kernel's resume offsets and depth bound ensure termination for every context. -/
theorem depth_fin (ctx : awsvars.VarContext) (pattern : Slice U8) (depth : Usize) :
    Finishes (awsvars.resolve_aws_variables_with_depth ctx pattern depth) (fun _ => True) := by
  induction hm : 10 - depth.val using Nat.strong_induction_on generalizing depth pattern with
  | _ n ih =>
    rw [awsvars.resolve_aws_variables_with_depth]
    split
    · fstep (Finishes.to_vec pattern) with text ht
      exact (Finishes.push (alloc.vec.Vec.new _) text).mono (fun _ _ => trivial)
    · rename_i hd
      fstep (Finishes.to_vec pattern) with text ht
      fstep (Finishes.push (alloc.vec.Vec.new _) text) with results hr
      apply fixpoint_fin ctx depth ?_ results 0#usize
      intro s d hgt
      apply ih (10 - d.val) ?_ s d rfl
      scalar_tac

theorem resolution_terminates (ctx : awsvars.VarContext) (p : Slice U8) (hv : PlainValues ctx) :
    (∃ r, awsvars.resolve_aws_variables ctx p = ok r) ∨
      ∃ err, awsvars.resolve_aws_variables ctx p = fail err := by
  clear hv
  unfold awsvars.resolve_aws_variables
  rcases depth_fin ctx p 0#usize with ⟨r, hr, _⟩ | ⟨e, he⟩
  · exact .inl ⟨r, hr⟩
  · exact .inr ⟨e, he⟩

end rustfs_kernel.Solution
