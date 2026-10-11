import Verified.RustfsBytes
import Verified.RustfsForceDelete
import SpecKernel
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsBytes
open rustfs_kernel.Verified.RustfsForceDelete (lift_slice nats_inj family_eq_ok deref_val bytes_eq_ok)

/-! `BPStatement::is_valid` and `Resource::is_valid` (`valids.rs`) accept
exactly what `SpecKernel` describes; `Statement::action_family` agrees with
`UniformFamily`. -/

namespace rustfs_kernel.Verified.RustfsValids

theorem prefAt_iff (s p : List U8) (k : Nat) : PrefAt s p k ↔ k ≤ s.length ∧ p <+: s.drop k := by
  rw [List.prefix_iff_eq_take]
  constructor
  · rintro ⟨h1, h2⟩
    refine ⟨by omega, ?_⟩
    apply List.ext_getElem?; intro j
    by_cases hj : j < p.length
    · rw [List.getElem?_take_of_lt hj, List.getElem?_drop, h2 j hj]
    · rw [List.getElem?_eq_none (by omega), List.getElem?_eq_none (by simp; omega)]
  · rintro ⟨hk, h⟩
    have hl := congrArg List.length h
    simp only [List.length_take, List.length_drop] at hl
    refine ⟨by omega, fun j hj => ?_⟩
    rw [h, List.getElem?_take_of_lt hj, List.getElem?_drop]

theorem nats_prefix {p s : List U8} : nats p <+: nats s ↔ p <+: s :=
  List.prefix_map_iff_of_injective (fun x y h => (u8_eq_iff x y).2 h)

theorem starts_lit {s p : Slice U8} {l : List Nat} (hp : nats p.val = l) {b : Bool}
    (h : bytes.starts_with s p = ok b) : (b = true ↔ l <+: nats s.val) := by
  rw [starts_with_ok s p b h, prefAt_iff, ← hp, nats_prefix]
  simp

theorem contains_byte {s p : Slice U8} {c : Nat} (hp : nats p.val = [c]) {b : Bool}
    (h : bytes.contains s p = ok b) : (b = true ↔ c ∈ nats s.val) := by
  rw [contains_ok s p b h]
  obtain ⟨x, hx, hxc⟩ : ∃ x, p.val = [x] ∧ x.val = c := by
    cases hpv : p.val with
    | nil => simp [nats, hpv] at hp
    | cons x t =>
      rw [hpv] at hp
      simp only [nats, List.map_cons, List.cons.injEq, List.map_eq_nil_iff] at hp
      exact ⟨x, by rw [hp.2], hp.1⟩
  unfold PrefAt
  rw [hx]
  constructor
  · rintro ⟨k, hk1, hk2⟩
    have := hk2 0 (by simp)
    simp only [Nat.add_zero, List.getElem?_cons_zero] at this
    simp only [nats, List.mem_map]
    exact ⟨x, List.mem_of_getElem? this, hxc⟩
  · intro hc
    simp only [nats, List.mem_map] at hc
    obtain ⟨y, hy, hyc⟩ := hc
    obtain ⟨k, hk, hky⟩ := List.getElem_of_mem hy
    have : y = x := (u8_eq_iff _ _).2 (by omega)
    subst this
    refine ⟨k, by simp; omega, fun j hj => ?_⟩
    simp only [List.length_singleton, Nat.lt_one_iff] at hj
    subst hj
    simp [List.getElem?_eq_getElem hk, hky]

theorem lit_key : lit "key/" = [107, 101, 121, 47] := by decide +kernel
theorem lit_alias : lit "alias/" = [97, 108, 105, 97, 115, 47] := by decide +kernel
theorem lit_star : lit "*" = [42] := by decide +kernel

theorem nats_drop (l : List U8) (n : Nat) : nats (l.drop n) = (nats l).drop n := by
  simp [nats, List.map_drop]

theorem nats_length (l : List U8) : (nats l).length = l.length := by simp [nats]

theorem kms_key_ok (p : Slice U8) (r : Bool) (h : valids.kms_key_valid p = ok r) :
    (r = true ↔ lit "key/" <+: nats p.val ∧ 4 < (nats p.val).length ∧
      47 ∉ (nats p.val).drop 4 ∧ 92 ∉ nats p.val) := by
  unfold valids.kms_key_valid at h
  rw [lit_key, nats_length]
  h5i_invert h
  · have h1 := starts_lit (by simpa using lift_slice hs) hb
    have hv := slice_ok _ _ _ _ hv
    have h2 := contains_byte (c := 47) (by simpa using lift_slice hs2) hb1
    rw [deref_val, hv, nats_drop] at h2
    simp_all
  · have h1 := starts_lit (by simpa using lift_slice hs) hb
    have hv := slice_ok _ _ _ _ hv
    have h2 := contains_byte (c := 47) (by simpa using lift_slice hs2) hb1
    have h3 := contains_byte (c := 92) (by simpa using lift_slice hs3) hb2
    rw [deref_val, hv, nats_drop] at h2
    cases b2 <;> simp_all
  · have h1 := starts_lit (by simpa using lift_slice hs) hb
    simp only [Bool.false_eq_true, false_iff, not_and]
    intro _ h; scalar_tac
  · have h1 := starts_lit (by simpa using lift_slice hs) hb
    simp_all

theorem kms_alias_ok (p : Slice U8) (r : Bool) (h : valids.kms_alias_valid p = ok r) :
    (r = true ↔ lit "alias/" <+: nats p.val ∧ 6 < (nats p.val).length ∧ 92 ∉ nats p.val) := by
  unfold valids.kms_alias_valid at h
  rw [lit_alias, nats_length]
  h5i_invert h
  · have h1 := starts_lit (by simpa using lift_slice hs) hb
    have h3 := contains_byte (c := 92) (by simpa using lift_slice hs1) hb1
    simp only [decide_eq_true_eq, Bool.not_eq_true] at *
    constructor
    · intro hb2'
      refine ⟨h1.1 hc, by scalar_tac, fun h => ?_⟩
      simp_all
    · rintro ⟨-, -, h4⟩
      cases b1 <;> simp_all
  · simp only [Bool.false_eq_true, false_iff, not_and]
    intro _ h; scalar_tac
  · have h1 := starts_lit (by simpa using lift_slice hs) hb
    simp only [Bool.false_eq_true, false_iff, not_and]
    intro h; simp_all

theorem resource_pattern_ok (x : rsrc.Resource) (r : Bool) (h : valids.resource_pattern_valid x = ok r) :
    (r = true ↔ resourceOK x) := by
  unfold valids.resource_pattern_valid at h
  cases x with
  | S3 p =>
    simp only [resourceOK]
    h5i_invert h
    · have h0 := vec_index_slice_ok_get? hi1
      have hne : p.val ≠ [] := by intro h; simp [h] at h0
      obtain ⟨y, t, hyt⟩ := List.exists_cons_of_ne_nil hne
      rw [hyt] at h0
      simp only [List.getElem?_cons_zero, UScalar.ofNatCore_val_eq, Option.some.injEq] at h0
      subst h0
      simp only [hyt, nats, List.map_cons, List.head?_cons, ne_eq, Option.some.injEq, reduceCtorEq,
        not_false_eq_true, true_and, bne_iff_ne]
      rw [u8_eq_iff]; rfl
    · have : p.val = [] := by
        have : p.len.val = 0 := by scalar_tac
        simpa using this
      simp [this]
  | Kms p =>
    simp only [resourceOK, kmsResourceOK]
    h5i_invert h
    · have h0 := (bytes_eq_ok _ _ _ hb).1 hc
      rw [deref_val] at h0
      simp [h0, lift_slice hs1, lit_star]
    · have h0 := (bytes_eq_ok _ _ _ hb)
      have h1 := (kms_key_ok _ _ hb1)
      rw [deref_val] at h1
      simp_all
    · have h0 := (bytes_eq_ok _ _ _ hb)
      have h1 := (kms_key_ok _ _ hb1)
      have h2 := (kms_alias_ok _ _ h)
      rw [deref_val] at h0 h1 h2
      have h3 : ¬ nats p.val = lit "*" := by
        intro he
        apply hc; rw [h0]
        apply nats_inj
        rw [he, lift_slice hs1, lit_star]; rfl
      simp only [h3, false_or]
      rw [h2, ← h1]
      simp [hc_1]

theorem resource_ok (x : rsrc.Resource) (res) (h : valids.resource_is_valid x = ok res) :
    (res = .Ok () ↔ resourceOK x) := by
  unfold valids.resource_is_valid at h
  h5i_invert h
  · simp [← resource_pattern_ok _ _ hb, hc]
  all_goals (have := resource_pattern_ok _ _ hb; simp_all)

/-- One step of a loop that returns `true` at the first element satisfying `P`. -/
def AnyStep {β} (l : List β) (P : β → Prop) (i : Usize) : ControlFlow Usize Bool → Prop
  | .done b => (∃ h : i.val < l.length, P l[i.val] ∧ b = true) ∨ (l.length ≤ i.val ∧ b = false)
  | .cont j => ∃ h : i.val < l.length, ¬ P l[i.val] ∧ j.val = i.val + 1

theorem any_loop {β} (l : List β) (P : β → Prop) (body : Usize → Result (ControlFlow Usize Bool))
    (hb : ∀ i r, i.val ≤ l.length → body i = ok r → AnyStep l P i r) (r : Bool)
    (h : loop body 0#usize = ok r) : (r = true ↔ ∃ x ∈ l, P x) := by
  refine loop_ok _ (fun i : Usize => i.val ≤ l.length ∧ ∀ x ∈ l.take i.val, ¬ P x)
    (fun r => r = true ↔ ∃ x ∈ l, P x) (fun i : Usize => l.length - i.val) ?_ _ r
    ⟨by simp, by simp⟩ h
  rintro i r ⟨hi, hx⟩ hr
  have := hb i r hi hr
  cases r with
  | done b =>
    rcases this with ⟨hlt, hp, rfl⟩ | ⟨hle, rfl⟩
    · simp only [true_iff]; exact ⟨_, List.getElem_mem hlt, hp⟩
    · simp only [Bool.false_eq_true, false_iff, not_exists, not_and]
      rw [List.take_of_length_le hle] at hx
      exact hx
  | cont j =>
    obtain ⟨hlt, hp, hj⟩ := this
    refine ⟨⟨by omega, fun x hx' => ?_⟩, by omega⟩
    rw [hj, List.take_add_one, List.getElem?_eq_getElem hlt] at hx'
    simp only [Option.toList_some, List.mem_append, List.mem_singleton] at hx'
    rcases hx' with h | rfl
    · exact hx x h
    · exact hp

theorem has_kms_action_ok (l : Slice acts.Action) (r : Bool) (h : valids.has_kms_action l = ok r) :
    (r = true ↔ ∃ a ∈ l.val, a.family = .Kms) := by
  unfold valids.has_kms_action valids.has_kms_action_loop at h
  refine any_loop _ _ _ (fun i r _ hr => ?_) r h
  unfold valids.has_kms_action_loop.body at hr
  h5i_invert hr
  · obtain ⟨h1, h2⟩ := slice_index_ok ha
    rw [family_eq_ok] at hb
    simp only [Result.ok.injEq, decide_eq_true_eq] at hb
    exact .inl ⟨h1, by rw [h2]; simp_all, rfl⟩
  · obtain ⟨h1, h2⟩ := slice_index_ok ha
    rw [family_eq_ok] at hb
    simp only [Result.ok.injEq] at hb
    refine ⟨h1, ?_, by have := add_ok_val hi2; scalar_tac⟩
    rw [h2]; intro he; simp_all
  · exact .inr ⟨by scalar_tac, rfl⟩

theorem is_kms_ok (x : rsrc.Resource) (b : Bool) (h : rsrc.is_kms x = ok b) :
    (b = true ↔ isKmsResource x) := by
  unfold rsrc.is_kms at h; cases x <;> simp_all [isKmsResource]

theorem has_kms_resource_ok (l : Slice rsrc.Resource) (o : Bool) (h : valids.has_kms_resource l = ok o) :
    (o = true ↔ ∃ x ∈ l.val, isKmsResource x) := by
  unfold valids.has_kms_resource valids.has_kms_resource_loop at h
  refine any_loop _ _ _ (fun i o _ hbody => ?_) o h
  unfold valids.has_kms_resource_loop.body at hbody
  h5i_invert hbody
  · obtain ⟨h1, h2⟩ := slice_index_ok hr
    have := is_kms_ok _ _ hb
    exact .inl ⟨h1, by rw [h2]; simp_all, rfl⟩
  · obtain ⟨h1, h2⟩ := slice_index_ok hr
    have := is_kms_ok _ _ hb
    exact ⟨h1, by rw [h2]; simp_all, by have := add_ok_val hi2; scalar_tac⟩
  · exact .inr ⟨by scalar_tac, rfl⟩

theorem resources_ok (l : Slice rsrc.Resource) (o) (h : valids.resources_is_valid l = ok o) :
    (o = .Ok () ↔ ∀ x ∈ l.val, resourceOK x) := by
  unfold valids.resources_is_valid valids.resources_is_valid_loop at h
  refine loop_ok _ (fun i : Usize => i.val ≤ l.val.length ∧ ∀ x ∈ l.val.take i.val, resourceOK x)
    (fun o => o = .Ok () ↔ ∀ x ∈ l.val, resourceOK x) (fun i : Usize => l.val.length - i.val) ?_ _ o
    ⟨by simp, by simp⟩ h
  rintro i o ⟨hi, hx⟩ hbody
  unfold valids.resources_is_valid_loop.body at hbody
  h5i_invert hbody
  · obtain ⟨h1, h2⟩ := slice_index_ok hr
    have h3 := resource_ok _ _ hr1
    have := add_ok_val hi2
    refine ⟨⟨by scalar_tac, fun x hx' => ?_⟩, by scalar_tac⟩
    rw [show i2.val = i.val + 1 by scalar_tac, List.take_add_one, List.getElem?_eq_getElem h1] at hx'
    simp only [Option.toList_some, List.mem_append, List.mem_singleton] at hx'
    rcases hx' with h | rfl
    · exact hx x h
    · rw [h2]; exact h3.1 rfl
  · obtain ⟨h1, h2⟩ := slice_index_ok hr
    have h3 := resource_ok _ _ hr1
    simp only [reduceCtorEq, false_iff, not_forall] at h3 ⊢
    exact ⟨r, by rw [← h2]; exact List.getElem_mem h1, h3⟩
  · simp only [true_iff]
    rw [List.take_of_length_le (by scalar_tac)] at hx
    exact hx

theorem principal_ok (p : stmts.Principal) (o) (h : valids.principal_is_valid p = ok o) :
    (o = .Ok () ↔ (p.aws.val ≠ [] ∨ p.service.val ≠ [])) := by
  unfold valids.principal_is_valid valids.error at h
  h5i_invert h <;> simp_all [usize_ofNatCore_eq_zero]

theorem len_zero {α} (v : alloc.vec.Vec α) : v.len = 0#usize ↔ v.val = [] := by
  constructor
  · intro h; have : v.len.val = 0 := by rw [h]; rfl
    simpa using this
  · intro h; apply UScalar.eq_of_val_eq; simp [h]

theorem len_bne {α} (v : alloc.vec.Vec α) : (v.len != 0#usize) = !decide (v.val = []) := by
  have := len_zero v
  by_cases hv : v.len = 0#usize <;> simp_all

/-- `h : (do let x ← e; k x) = ok o`: name the value of `e` and continue with `k`. -/
macro "bcase " x:ident " with " hx:ident " at " h:ident : tactic => `(tactic| (
  have hh := bind_tc_eq_ok.1 $h:ident
  clear $h:ident
  obtain ⟨$x, $hx, $h⟩ := hh))

macro "vsimp " h:ident : tactic => `(tactic| (
  simp only [len_zero, len_bne, deref_val, ↓reduceIte, Bool.not_true, Bool.not_false, decide_true, decide_false,
    Bool.false_eq_true, bind_tc_ok, bind_ok, valids.error, core.result.Result.Insts.CoreOpsTry.branch,
    Result.ok.injEq] at $h:ident))

macro "vif " h:ident " [" ls:Lean.Parser.Tactic.simpLemma,* "]" : tactic => `(tactic| (
  simp only [↓reduceIte, decide_true, decide_false, Bool.not_true, Bool.not_false, Bool.false_eq_true,
    Bool.true_eq_false, Result.ok.injEq, $ls,*] at $h:ident))

macro "vclose " h:ident : tactic => `(tactic| (subst $h:ident; first
  | (simp_all; done)
  | (simp only [reduceCtorEq, false_iff]; grind)))

theorem bp_statement_ok (st : stmts.BPStatement) (sid : Slice U8) (o)
    (h : valids.bp_statement_is_valid st sid = ok o) : (o = .Ok () ↔ BPStatementOK st) := by
  unfold valids.bp_statement_is_valid at h
  unfold BPStatementOK
  bcase e1 with he1 at h
  bcase e2 with he2 at h
  bcase p with hp at h
  have hpo := principal_ok _ _ hp
  cases p with
  | Err e =>
    vsimp h
    simp only [from_residual_err, bind_tc_ok, bind_ok, Result.ok.injEq] at h
    subst h; simp_all
  | Ok v =>
    vsimp h
    have hP : st.principal.aws.val ≠ [] ∨ st.principal.service.val ≠ [] := hpo.1 rfl
    clear hpo hp he1 he2
    by_cases ha : st.actions.val = [] <;> by_cases hn : st.not_actions.val = [] <;> vif h [ha, hn]
    all_goals try vclose h
    all_goals
      bcase b with hb at h
      have hb' := has_kms_action_ok _ _ hb
      rw [deref_val] at hb'
      cases b <;> vif h []
    all_goals try vclose h
    all_goals
      bcase b1 with hb1 at h
      have hb1' := has_kms_action_ok _ _ hb1
      rw [deref_val] at hb1'
      cases b1 <;> vif h []
    all_goals try vclose h
    all_goals
      bcase b2 with hb2 at h
      have hb2' := has_kms_resource_ok _ _ hb2
      rw [deref_val] at hb2'
      cases b2 <;> vif h []
    all_goals try vclose h
    all_goals
      bcase b3 with hb3 at h
      have hb3' := has_kms_resource_ok _ _ hb3
      rw [deref_val] at hb3'
      cases b3 <;> vif h []
    all_goals try vclose h
    all_goals (by_cases hr : st.resources.val = [] <;> by_cases hnr : st.not_resources.val = [] <;> vif h [hr, hnr])
    all_goals try vclose h
    all_goals
      bcase x1 with hx1 at h
      bcase x2 with hx2 at h
      bcase r1 with hr1 at h
      have hr1' := resources_ok _ _ hr1
      rw [deref_val] at hr1'
      cases r1 <;> vsimp h <;> try simp only [from_residual_err, bind_tc_ok, bind_ok, Result.ok.injEq] at h
    all_goals try vclose h
    all_goals
      bcase r2 with hr2 at h
      have hr2' := resources_ok _ _ hr2
      rw [deref_val] at hr2'
      cases r2 <;> vsimp h <;> try simp only [from_residual_err, bind_tc_ok, bind_ok, Result.ok.injEq] at h
    all_goals try vclose h

/-- Some action of `l` has family `f`. -/
def Saw (l : List acts.Action) (f : acts.Family) : Bool := decide (∃ a ∈ l, a.family = f)

theorem saw_snoc (l : List acts.Action) (y : acts.Action) (f : acts.Family) :
    Saw (l ++ [y]) f = (Saw l f || decide (y.family = f)) := by
  simp only [Saw, List.mem_append, List.mem_singleton]
  by_cases h1 : ∃ a ∈ l, a.family = f <;> by_cases h2 : y.family = f <;> simp_all

def Saws (l : List acts.Action) : Bool × Bool × Bool × Bool :=
  (Saw l .S3, Saw l .Admin, Saw l .Sts, Saw l .Kms)

theorem action_family_loop_ok (v : alloc.vec.Vec acts.Action) (x : Bool × Bool × Bool × Bool)
    (h : valids.action_family_loop v false false false false 0#usize = ok x) : x = Saws v.val := by
  unfold valids.action_family_loop at h
  refine loop_ok _ (fun y : Bool × Bool × Bool × Bool × Usize => y.2.2.2.2.val ≤ v.val.length ∧
      (y.1, y.2.1, y.2.2.1, y.2.2.2.1) = Saws (v.val.take y.2.2.2.2.val))
    (fun x => x = Saws v.val) (fun y => v.val.length - y.2.2.2.2.val) ?_ _ x
    ⟨by simp, by simp [Saws, Saw]⟩ h
  rintro ⟨s0, a0, t0, k0, i⟩ r ⟨hi, hx⟩ hr
  simp only at hi hx
  unfold valids.action_family_loop.body at hr
  h5i_invert hr
  · obtain ⟨s1, a1, t1, k1⟩ := x_1
    change (do let i2 ← i + 1#usize; ok (ControlFlow.cont (s1, a1, t1, k1, i2))) = ok r at hr
    obtain ⟨i2, hi2, hr⟩ := bind_tc_eq_ok.1 hr
    simp only [Result.ok.injEq] at hr
    subst hr
    have h0 := vec_index_slice_ok_get? ha
    have h1 := add_ok_val hi2
    have hlt : i.val < v.val.length := by scalar_tac
    refine ⟨⟨by scalar_tac, ?_⟩, by scalar_tac⟩
    rw [show i2.val = i.val + 1 by scalar_tac, List.take_add_one, h0]
    simp only [Option.toList_some, Saws, saw_snoc]
    simp only [Saws, Prod.mk.injEq] at hx
    obtain ⟨rfl, rfl, rfl, rfl⟩ := hx
    cases hf : a.family <;> simp only [hf, Result.ok.injEq, Prod.mk.injEq] at hx_1 <;>
      obtain ⟨rfl, rfl, rfl, rfl⟩ := hx_1 <;> simp
  · simp only
    rw [List.take_of_length_le (by scalar_tac)] at hx
    exact hx

def famModel : Bool × Bool × Bool × Bool → Option valids.ActionFamily
  | (s, a, t, k) =>
    if s.toNat + a.toNat + t.toNat + k.toNat ≠ 1 then some .Mixed
    else if s then some .S3 else if a then some .Admin else if t then some .Sts
    else if k then some .Kms else some .Mixed

theorem action_family_ok (st : stmts.Statement) (o) (h : valids.action_family st = ok o) :
    o = if st.actions.val = [] then none else famModel (Saws st.actions.val) := by
  unfold valids.action_family at h
  simp only [len_zero] at h
  by_cases hc : st.actions.val = []
  · simp only [hc, ↓reduceIte, Result.ok.injEq] at h ⊢
    exact h.symm
  · simp only [hc, ↓reduceIte] at h ⊢
    obtain ⟨x, hx, h⟩ := bind_tc_eq_ok.1 h
    have := action_family_loop_ok _ _ hx
    subst this
    rcases hS : Saws st.actions.val with ⟨s0, a0, t0, k0⟩
    rw [hS] at h
    change (do
      let i1 ← lift (UScalar.cast_fromBool .U8 s0)
      let i2 ← lift (UScalar.cast_fromBool .U8 a0)
      let i3 ← i1 + i2
      let i4 ← lift (UScalar.cast_fromBool .U8 t0)
      let i5 ← i3 + i4
      let i6 ← lift (UScalar.cast_fromBool .U8 k0)
      let count ← i5 + i6
      if count != 1#u8 then ok (some valids.ActionFamily.Mixed)
      else if s0 then ok (some .S3) else if a0 then ok (some .Admin) else if t0 then ok (some .Sts)
      else if k0 then ok (some .Kms) else ok (some .Mixed)) = ok o at h
    simp only [lift, bind_tc_ok, bind_ok] at h
    clear hS hx hc
    h5i_invert h
    all_goals
      h5i_ok_facts
      simp only [UScalar.cast_fromBool_val_eq, bne_iff_ne, ne_eq] at *
      have hu : ∀ x : U8, x = 1#u8 ↔ x.val = 1 := fun x => by
        rw [u8_eq_iff]; rfl
      simp only [hu] at *
      try clear h
      clear hi3 hi5 hcount hu
      cases s0 <;> cases a0 <;> cases t0 <;> cases k0 <;>
        simp only [Bool.toNat_true, Bool.toNat_false, Bool.false_eq_true, Bool.true_eq_false] at * <;>
        first | rfl | omega | (exfalso; omega) | simp_all

theorem family_forall {P : acts.Family → Prop} :
    (∀ g, P g) ↔ P .S3 ∧ P .Admin ∧ P .Sts ∧ P .Kms ∧ P .None :=
  ⟨fun h => ⟨h _, h _, h _, h _, h _⟩, fun ⟨a, b, c, d, e⟩ g => by cases g <;> assumption⟩

theorem family_exists {P : acts.Family → Prop} :
    (∃ g, P g) ↔ P .S3 ∨ P .Admin ∨ P .Sts ∨ P .Kms ∨ P .None :=
  ⟨fun ⟨g, h⟩ => by cases g <;> simp_all, fun h => by
    rcases h with h | h | h | h | h <;> exact ⟨_, h⟩⟩

theorem uf_iff (l : List acts.Action) (f : acts.Family) :
    UniformFamily l f ↔ f ≠ .None ∧ Saw l f ∧ ∀ g, g ≠ f → g ≠ .None → Saw l g = false := by
  unfold UniformFamily Saw
  constructor
  · rintro ⟨h1, h2, h3⟩
    refine ⟨h1, by simpa using h2, fun g hg hn => ?_⟩
    simp only [decide_eq_false_iff_not, not_exists, not_and]
    intro a ha he
    rcases h3 a ha with h | h <;> simp_all
  · rintro ⟨h1, h2, h3⟩
    refine ⟨h1, by simpa using h2, fun a ha => ?_⟩
    by_contra hc
    simp only [not_or] at hc
    have := h3 a.family hc.1 hc.2
    simp only [decide_eq_false_iff_not, not_exists, not_and] at this
    exact this a ha rfl

macro "fam_cases" l:term : tactic => `(tactic| (
  simp only [uf_iff, family_forall, family_exists, Saws, ne_eq, reduceCtorEq, not_false_eq_true,
    not_true_eq_false, true_and, false_and, imp_self, forall_const, and_true, true_implies,
    false_implies, IsEmpty.forall_iff, or_false, false_or]
  generalize Saw $l .S3 = s0
  generalize Saw $l .Admin = a0
  generalize Saw $l .Sts = t0
  generalize Saw $l .Kms = k0
  cases s0 <;> cases a0 <;> cases t0 <;> cases k0 <;> simp [famModel]))

theorem fam_mixed (l : List acts.Action) :
    famModel (Saws l) = some .Mixed ↔ ¬ ∃ f, UniformFamily l f := by
  fam_cases l

theorem fam_kms (l : List acts.Action) :
    famModel (Saws l) = some .Kms ↔ UniformFamily l .Kms := by
  fam_cases l

theorem fam_empty_ok (l : List acts.Action) :
    (famModel (Saws l) = some .Admin ∨ famModel (Saws l) = some .Sts ∨ famModel (Saws l) = some .Kms) ↔
      ∃ f, (f = .Admin ∨ f = .Sts ∨ f = .Kms) ∧ UniformFamily l f := by
  rw [family_exists]
  fam_cases l

theorem action_family_mixed (st : stmts.Statement) (o) (h : valids.action_family st = ok o)
    (hne : st.actions.val ≠ []) : (o = some .Mixed ↔ ¬ ∃ f, UniformFamily st.actions.val f) := by
  rw [action_family_ok st o h, if_neg hne]; exact fam_mixed _

end rustfs_kernel.Verified.RustfsValids
