import Verified.RustfsOperatorLookup
import Verified.RustfsScalarOperators
import Verified.RustfsParseI64
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsNumeric

theorem parse_ok (s : Slice U8) (out : Option I64) (h : bytes.parse_i64 s = ok out) :
    out.map (·.val) = parseI64Spec (nats s.val) := by
  obtain ⟨r,hr,hm⟩ := RustfsParseI64.parse_i64_spec s
  rw [h] at hr
  cases Result.ok.inj hr
  exact hm

/-- A missing first request value returns `if_exists` immediately. -/
theorem numeric_conditions_ok (op : condfuncs.NumOp) (ifExists : Bool)
    (funcs : Slice (condfuncs.Key × I64))
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (b : Bool) (h : condfuncs.num_func op ifExists funcs values = ok b) :
    b = true ↔ NumericConditions op ifExists (RequestValueLists values.val)
      (funcs.val.map (fun e => (e.1,e.2.val))) := by
  unfold condfuncs.num_func condfuncs.num_func_loop at h
  let P := fun fs : List (condfuncs.Key × I64) =>
    NumericConditions op ifExists (RequestValueLists values.val) (fs.map (fun e => (e.1,e.2.val)))
  change b = true ↔ P funcs.val
  refine loop_ok _ (fun i : Usize => i.val ≤ funcs.val.length ∧
      (P funcs.val ↔ P (funcs.val.drop i.val)))
    (fun b => b = true ↔ P funcs.val)
    (fun i => funcs.val.length - i.val) ?_ _ b ⟨by simp,by simp⟩ h
  rintro i r ⟨hi,hm⟩ hr
  unfold condfuncs.num_func_loop.body at hr
  h5i_invert hr
  · rcases x with ⟨key,bound⟩
    obtain ⟨hlt,he⟩ := slice_index_ok hx
    change (do
      let first ← condfuncs.first_value values key
      match first with
      | none => ok (ControlFlow.done ifExists)
      | some text => do
        let parsed ← bytes.parse_i64 text.deref
        match parsed with
        | none => ok (ControlFlow.done false)
        | some number => do
          let matched ← condfuncs.num_op op number bound
          if matched then
            let next ← i + 1#usize
            ok (ControlFlow.cont next)
          else ok (ControlFlow.done false)) = ok r at hr
    h5i_invert hr
    all_goals
      have hf := RustfsOperatorLookup.first_ok _ _ _ hfirst
      rw [List.drop_eq_getElem_cons hlt, he] at hm
      simp only [P,List.map_cons,NumericConditions, ← hf,Option.map_none,
        Option.map_some] at hm
    · exact hm.symm
    · have hp := parse_ok _ _ hparsed
      simp only [Option.map_none, RustfsForceDelete.deref_val] at hp
      simp only [← hp] at hm
      simpa using hm.symm
    · have hp := parse_ok _ _ hparsed
      simp only [Option.map_some, RustfsForceDelete.deref_val] at hp
      have hn := (RustfsScalarOperators.numeric_ok _ _ _ _ hmatched).1 hc_1
      simp only [← hp,Option.some.injEq, exists_eq_left',hn,true_and] at hm
      have ha := add_ok_val hnext
      refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
      convert hm using 2
      congr 3
    · have hp := parse_ok _ _ hparsed
      simp only [Option.map_some, RustfsForceDelete.deref_val] at hp
      have hn : ¬ NumericComparison op number.val bound.val := by
        intro hh; exact hc_1 ((RustfsScalarOperators.numeric_ok _ _ _ _ hmatched).2 hh)
      simp only [← hp,Option.some.injEq, exists_eq_left',hn,false_and] at hm
      simpa using hm.symm
  · rw [List.drop_of_length_le (by scalar_tac)] at hm
    simpa [P, NumericConditions] using hm.symm
end rustfs_kernel.Verified.RustfsNumeric
