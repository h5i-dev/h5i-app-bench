import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit

namespace rustfs_kernel.Counterexample

def bv (s : String) (h : (H5iAppLib.lit s).length < 2 ^ 32 - 1 := by decide) :
    alloc.vec.Vec U8 := vecOf (H5iAppLib.lit s) (Nat.le_of_lt (usize_lt_max h))

def ctx : awsvars.VarContext := {
  username := bv "$$"
  account := bv "{aws:username}{aws:AccountId}"
  claims := {
    sub := none
    parent := none
    parent_str := none
    has_parent := false
    has_role_arn := false
    has_sa_policy := false }
  now_rfc3339 := bv ""
  now_epoch := bv ""
}

def a : alloc.vec.Vec (alloc.vec.Vec U8) := vecOf [bv "$${aws:AccountId}"]
def b : alloc.vec.Vec (alloc.vec.Vec U8) := vecOf [bv "${aws:username}{aws:AccountId}"]

theorem lit_ref : lit "${" = [36, 123] := by
  simp [lit, ← String.utf8Encode_toList, List.utf8Encode, String.utf8EncodeChar,
    ByteArray.toList, ByteArray.toList.loop, ByteArray.get!]

theorem plain : PlainValues ctx := by
  simp [PlainValues, ctx, NoVarRef, bv, vecOf, H5iAppLib.lit, nats, lit_ref]
  all_goals decide

-- Each scan substitutes one value and requests another pass at the same index.
-- The second scan returns to exactly the original state.
/-- info: true -/
#guard_msgs in
#eval (awsvars.scan ctx a 0#usize 0#usize).reducesTo (b, true)

/-- info: true -/
#guard_msgs in
#eval (awsvars.scan ctx b 0#usize 0#usize).reducesTo (a, true)

open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Counterexample
set_option maxHeartbeats 1000000
set_option maxRecDepth 5000
set_option linter.unusedSimpArgs false

@[simp] theorem ground_add {ty} (x y : UScalar ty) : x + y = UScalar.add x y := rfl
@[simp] theorem ground_sub {ty} (x y : UScalar ty) : x - y = UScalar.sub x y := rfl
@[simp] theorem ground_val {ty : UScalarTy} (x : BitVec ty.numBits) : (UScalar.mk x).val = x.toNat := rfl

open Lean Meta in
simproc ↓ groundEval ((_ : Result _)) := fun e => do
  if !(← inferType e).isAppOf ``Aeneas.Std.Result then return .continue
  let .const decl _ := e.getAppFn | return .continue
  if !([``loop,
      ``awsvars.closing, ``awsvars.closing_loop, ``awsvars.closing_loop.body,
      ``awsvars.resolve_multiple, ``awsvars.resolve,
      ``awsvars.wrap_all, ``awsvars.wrap_all_loop, ``awsvars.wrap_all_loop.body,
      ``awsvars.splice, ``awsvars.splice_loop0, ``awsvars.splice_loop0.body,
      ``awsvars.splice_loop1, ``awsvars.splice_loop1.body,
      ``awsvars.splice_loop2, ``awsvars.splice_loop2.body,
      ``bytes.find_from, ``bytes.find_from_loop, ``bytes.find_from_loop.body,
      ``bytes.starts_with_at, ``bytes.starts_with_at_loop, ``bytes.starts_with_at_loop.body,
      ``bytes.slice, ``bytes.slice_loop, ``bytes.slice_loop.body,
      ``bytes.contains, ``bytes.eq, ``bytes.eq_loop, ``bytes.eq_loop.body,
      ``bytes.concat, ``bytes.concat_loop, ``bytes.concat_loop.body,
      ``alloc.vec.Vec.index, ``alloc.vec.Vec.push, ``Slice.index_usize,
      ``UScalar.add, ``UScalar.sub].contains decl)
    then return .continue
  if e.hasLooseBVars then return .continue
  for id in (Lean.collectFVars {} e).fvarIds do
    if !(← isProof (mkFVar id)) then return .continue
  return .visit (← Lean.Meta.unfold e decl)

open Lean Meta Simp in
simproc ↓ headBind (Bind.bind _ _) := fun e => do
  if !(← inferType e).isAppOf ``Aeneas.Std.Result then return .continue
  let args := e.getAppArgs
  let m := args[args.size - 2]!
  let k := args.back!
  let r ← simp m
  let f := e.getAppFn
  let bf := mkAppN f (args.extract 0 (args.size - 2))
  let ef := mkLambda `m .default (← inferType m) (mkApp2 bf (.bvar 0) k)
  let proof ← mkCongrArg ef (← r.getProof)
  if r.expr.isAppOf ``Result.ok then
    let x := r.expr.getAppArgs.back!
    let pf ← mkAppM ``bind_tc_ok #[x, k]
    return .visit { expr := (mkApp k x).headBeta, proof? := ← mkEqTrans proof pf }
  if r.expr == m then return .done { expr := e }
  return .visit { expr := mkApp2 bf r.expr k, proof? := proof }

macro "concrete_eval" : tactic => `(tactic| (
  rcases System.Platform.numBits_eq with hbits | hbits <;>
    simp [hbits, UScalarTy.numBits, lift, a, b, ctx, bv, vecOf, H5iAppLib.lit,
      groundEval, headBind,
      alloc.vec.Vec.val, alloc.vec.Vec.from, Usize.max_def, U32.max_def, U32.numBits, core.slice.index.SliceIndexUsizeSlice,
      alloc.vec.Vec.deref, u8vec_clone,
      UScalar.tryMk, UScalar.tryMkOpt, UScalar.eq_equiv]
))


def scanBody
  (ctx : awsvars.VarContext)
  (recScan : alloc.vec.Vec (alloc.vec.Vec Std.U8) → Std.Usize → Std.Usize → Result ((alloc.vec.Vec (alloc.vec.Vec Std.U8)) × Bool))
  (recResolve : Slice Std.U8 → Result (alloc.vec.Vec (alloc.vec.Vec Std.U8))) (results : alloc.vec.Vec (alloc.vec.Vec Std.U8))
  (i : Std.Usize) (start : Std.Usize) :
  Result ((alloc.vec.Vec (alloc.vec.Vec Std.U8)) × Bool)
  := do
  let v ←
    alloc.vec.Vec.index (core.slice.index.SliceIndexUsizeSlice (alloc.vec.Vec
      Std.U8)) results i
  let s ← alloc.vec.CloneVec.clone core.clone.CloneU8 v
  let s1 := alloc.vec.Vec.deref s
  let s2 ← lift (Array.to_slice (Array.make 2#usize [ 36#u8, 123#u8 ]))
  let o ← bytes.find_from s1 start s2
  match o with
  | none => ok (results, false)
  | some p =>
    let s3 := alloc.vec.Vec.deref s
    let i1 ← p + 2#usize
    let («end», brace) ← awsvars.closing s3 i1
    if brace != 0#usize
    then ok (results, false)
    else
      let s4 := alloc.vec.Vec.deref s
      let var ← bytes.slice s4 i1 «end»
      let s5 := alloc.vec.Vec.deref s
      let «prefix» ← bytes.slice s5 0#usize p
      let s6 := alloc.vec.Vec.deref s
      let i2 ← «end» + 1#usize
      let i3 := alloc.vec.Vec.len s
      let suffix ← bytes.slice s6 i2 i3
      let s7 := alloc.vec.Vec.deref var
      let s8 ← lift (Array.to_slice (Array.make 2#usize [ 36#u8, 123#u8 ]))
      let b ← bytes.contains s7 s8
      if b
      then
        let s9 := alloc.vec.Vec.deref var
        let inner ← recResolve s9
        let s10 := alloc.vec.Vec.deref «prefix»
        let s11 := alloc.vec.Vec.deref inner
        let s12 := alloc.vec.Vec.deref suffix
        let new ← awsvars.wrap_all s10 s11 s12
        let i4 := alloc.vec.Vec.len new
        if i4 > 0#usize
        then
          let s13 := alloc.vec.Vec.deref results
          let s14 := alloc.vec.Vec.deref new
          let v1 ← awsvars.splice s13 i s14
          ok (v1, true)
        else recScan results i i2
      else
        let s9 := alloc.vec.Vec.deref var
        let o1 ← awsvars.resolve_multiple ctx s9
        match o1 with
        | none => recScan results i i2
        | some values =>
          let i4 := alloc.vec.Vec.len values
          if i4 > 0#usize
          then
            let s10 := alloc.vec.Vec.deref «prefix»
            let s11 := alloc.vec.Vec.deref values
            let s12 := alloc.vec.Vec.deref suffix
            let new ← awsvars.wrap_all s10 s11 s12
            let s13 := alloc.vec.Vec.deref results
            let s14 := alloc.vec.Vec.deref new
            let v1 ← awsvars.splice s13 i s14
            ok (v1, true)
          else
            let s10 := alloc.vec.Vec.deref «prefix»
            let s11 := alloc.vec.Vec.deref suffix
            let v1 ← bytes.concat s10 s11
            let new ←
              alloc.vec.Vec.push (alloc.vec.Vec.new (alloc.vec.Vec Std.U8)) v1
            let s12 := alloc.vec.Vec.deref results
            let s13 := alloc.vec.Vec.deref new
            let v2 ← awsvars.splice s12 i s13
            ok (v2, true)

theorem body_a (recScan recResolve) :
    scanBody ctx recScan recResolve a 0#usize 0#usize = ok (b, true) := by
  unfold scanBody
  concrete_eval

theorem body_b (recScan recResolve) :
    scanBody ctx recScan recResolve b 0#usize 0#usize = ok (a, true) := by
  unfold scanBody
  concrete_eval

theorem scan_a : awsvars.scan ctx a 0#usize 0#usize = ok (b, true) := by
  rw [awsvars.scan]
  exact body_a _ _

theorem scan_b : awsvars.scan ctx b 0#usize 0#usize = ok (a, true) := by
  rw [awsvars.scan]
  exact body_b _ _
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Counterexample
open Aeneas.DspecInduction
open Lean.Order
attribute [-simp] groundEval headBind ground_add ground_sub ground_val
set_option linter.unusedSimpArgs false

abbrev VV := alloc.vec.Vec (alloc.vec.Vec U8)
abbrev p := (bv "$${aws:AccountId}").slice
abbrev emptyVV := alloc.vec.Vec.new (alloc.vec.Vec U8)

@[simp] theorem deref_slice {α : Type} (v : alloc.vec.Vec α) : v.deref = v.slice := by
  simp [alloc.vec.Vec.deref, alloc.vec.Vec.val]

theorem to_vec_p : alloc.slice.Slice.to_vec core.clone.CloneU8 p =
    ok (bv "$${aws:AccountId}") := u8vec_clone _

theorem init_p : emptyVV.push (bv "$${aws:AccountId}") = ok a := by
  simp [alloc.vec.Vec.push, a, vecOf, U32.max_def, U32.numBits]

def MScan (f : VV → Usize → Usize → Result (VV × Bool)) :=
  WP.dspec (f a 0#usize 0#usize) (· = (b, true)) ∧
  WP.dspec (f b 0#usize 0#usize) (· = (a, true))
def MFrom (f : VV → Usize → Result VV) :=
  WP.dspec (f a 0#usize) (fun _ => False) ∧
  WP.dspec (f b 0#usize) (fun _ => False)

macro "adm" : tactic => `(tactic| (
  repeat' first
    | apply admissible_and
    | apply curry_admissible
    | apply WP.dspec_func_admissible
))

theorem dspec_false_eq_div {α} {r : Result α} (h : WP.dspec r (fun _ => False)) :
    r = div := by
  cases h with
  | ret h => exact False.elim h
  | div => rfl

theorem from_div : MFrom (awsvars.pass_from ctx) := by
  apply awsvars.pass_from.fixpoint_induct ctx
    (motive_1 := MScan) (motive_2 := fun _ => True) (motive_3 := fun _ => True)
    (motive_4 := fun _ => True) (motive_5 := fun _ => True) (motive_6 := MFrom)
  · unfold MScan; adm
  · exact admissible_const_true
  · exact admissible_const_true
  · exact admissible_const_true
  · exact admissible_const_true
  · unfold MFrom; adm
  · intro scan resolve _ _
    change WP.dspec (scanBody ctx scan resolve a 0#usize 0#usize) (· = (b, true)) ∧
      WP.dspec (scanBody ctx scan resolve b 0#usize 0#usize) (· = (a, true))
    simp only [body_a, body_b, WP.dspec_ok, and_self]
  · intros; trivial
  · intros; trivial
  · intros; trivial
  · intros; trivial
  · intro scan pass ihs ihf
    unfold MFrom
    constructor
    · have ha : ¬ (0#usize ≥ a.len) := by simp [a, vecOf]
      simp only [if_neg ha]
      apply WP.dspec_bind ihs.1
      intro x hx
      subst x
      simpa using ihf.2
    · have hb : ¬ (0#usize ≥ b.len) := by simp [b, vecOf]
      simp only [if_neg hb]
      apply WP.dspec_bind ihs.2
      intro x hx
      subst x
      simpa using ihf.1

theorem resolver_div : awsvars.resolve_aws_variables ctx p = div := by
  have hf := dspec_false_eq_div from_div.1
  have hs : awsvars.resolve_single_pass ctx p = div := by
    rw [awsvars.resolve_single_pass]
    simp only [to_vec_p, bind_ok, bind_tc_ok, init_p, hf]
  have ha : awsvars.pass_all ctx a.slice 0#usize emptyVV false = div := by
    rw [awsvars.pass_all]
    simp [a, vecOf, alloc.vec.Vec.from, Slice.index_usize, hs]
  have hx : awsvars.fixpoint ctx a 0#usize = div := by
    rw [awsvars.fixpoint]
    simp [ha]
  rw [awsvars.resolve_aws_variables]
  simp only [to_vec_p, bind_ok, bind_tc_ok, init_p, hx]

theorem refutation :
    ¬ ((∃ r, awsvars.resolve_aws_variables ctx p = ok r) ∨
      ∃ err, awsvars.resolve_aws_variables ctx p = fail err) := by
  rw [resolver_div]
  rintro (⟨r, hr⟩ | ⟨e, he⟩)
  · exact div_not_ok hr
  · exact div_not_fail he

/-- The requested universally quantified termination statement is false. -/
theorem statement_false :
    ¬ (∀ (ctx : awsvars.VarContext) (pattern : Slice U8), PlainValues ctx →
      ((∃ r, awsvars.resolve_aws_variables ctx pattern = ok r) ∨
        ∃ err, awsvars.resolve_aws_variables ctx pattern = fail err)) := by
  intro h
  exact refutation (h ctx p plain)

end rustfs_kernel.Counterexample

#print axioms rustfs_kernel.Counterexample.statement_false
