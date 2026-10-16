import Verified.RustfsDateParser
import Verified.RustfsDateFields
import Verified.RustfsOperatorLookup
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsDateEvaluate
set_option maxHeartbeats 4000000
set_option maxRecDepth 5000
theorem evaluate_using
    (parse_ok : ∀ (s : Slice U8) (r : Option I128), dates.parse_rfc3339 s=ok r → r.map (·.val)=ParseInstant (nats s.val))
    (inner : conddata.InnerFunc conddata.DateFuncValue) (op : conddata.Op)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (b : Bool) (h : dates.evaluate inner op values=ok b) :
    b=true ↔ DateConditionsHold (inner.entries.val.map (fun e=>(e.key,e.values.unix_nanos.val))) op (RequestValueLists values.val) := by
  unfold dates.evaluate dates.evaluate_loop at h
  let P := fun es : List (conddata.FuncKeyValue conddata.DateFuncValue) =>
    DateConditionsHold (es.map (fun e=>(e.key,e.values.unix_nanos.val))) op (RequestValueLists values.val)
  change b=true ↔ P inner.entries.val
  refine loop_ok _ (fun i : Usize => i.val ≤ inner.entries.val.length ∧ (P inner.entries.val ↔ P (inner.entries.val.drop i.val)))
    (fun b=>b=true ↔ P inner.entries.val) (fun i=>inner.entries.val.length-i.val) ?_ _ b ⟨by simp,by simp⟩ h
  intro i out hinv hr
  rcases hinv with ⟨hi,hm⟩
  unfold dates.evaluate_loop.body at hr
  h5i_invert hr
  all_goals first
    | (obtain ⟨hlt,he⟩ := vec_index_ok hentry
       have hk := RustfsConditionEval.lookup_name_ok _ _ hv
       have hl := RustfsOperatorLookup.lookup_ok _ _ _ ho
       simp only [RustfsForceDelete.deref_val,hk] at hl
       rw [List.drop_eq_getElem_cons hlt,he] at hm
       simp only [P,List.map_cons,DateConditionsHold,List.forall_mem_cons] at hm)
    | (rw [List.drop_of_length_le (by scalar_tac)] at hm
       simpa [P,DateConditionsHold] using hm.symm)
  all_goals have hf : FirstConditionValue (RequestValueLists values.val) entry.key =
      (ConditionValues (RequestValueLists values.val) (LookupName entry.key)).bind List.head? := rfl
  all_goals rw [←hl] at hf
  · simp only [Option.map_none,Option.bind_none] at hf
    simp only [hf,reduceCtorEq,false_and,exists_false,and_false,false_iff] at hm
    simpa [P,DateConditionsHold] using hm.symm
  · have he : l.val=[] := List.eq_nil_iff_length_eq_zero.2 (by scalar_tac)
    simp only [Option.map_some,Option.bind_some,he,List.map_nil,List.head?_nil] at hf
    simp only [hf,reduceCtorEq,false_and,exists_false,and_false,false_iff] at hm
    simpa [P,DateConditionsHold] using hm.symm
  all_goals
    obtain ⟨hvlt,hve⟩ := vec_index_ok hv2
    have hhead : l.val.head?=some v2 := by
      have hh : l.val.head?=l.val[0]? := by cases l.val <;> rfl
      rw [hh,List.getElem?_eq_getElem (show 0<l.val.length by scalar_tac)]
      simpa using congrArg some hve
    simp only [Option.map_some,Option.bind_some,List.head?_map,hhead,Option.map_some] at hf
    have hp := parse_ok _ _ ho1
    simp only [Option.map_none,Option.map_some,RustfsForceDelete.deref_val] at hp
    simp only [hf,Option.some.injEq,exists_and_left,exists_eq_left,exists_eq_left'] at hm
    simp only [←hp] at hm
  · simpa [P,DateConditionsHold] using hm.symm
  · have hn := (RustfsScalarOperators.date_comparison_ok _ _ _ _ hb_1).1 hc_2
    simp only [Option.some.injEq,exists_eq_left,exists_eq_left',hn,true_and] at hm
    have ha := add_ok_val hi3
    refine ⟨⟨by scalar_tac,?_⟩,by scalar_tac⟩
    have hm' : P inner.entries.val ↔ P (inner.entries.val.drop (i.val+1)) := by simpa only [P,DateConditionsHold,exists_and_left] using hm
    simpa only [ha,UScalar.ofNatCore_val_eq] using hm'
  · have hn : ¬DateComparison op t.val entry.values.unix_nanos.val := by
      intro hh
      exact hc_2 ((RustfsScalarOperators.date_comparison_ok _ _ _ _ hb_1).2 hh)
    simp only [Option.some.injEq,exists_eq_left,exists_eq_left',hn,false_and,and_false] at hm
    simpa [P,DateConditionsHold] using hm.symm
/-- Date conditions conjoin comparisons of parsed first values with expected instants. -/
theorem evaluate_ok
    (inner : conddata.InnerFunc conddata.DateFuncValue) (op : conddata.Op)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (b : Bool) (h : dates.evaluate inner op values=ok b) :
    b=true ↔ DateConditionsHold (inner.entries.val.map (fun e=>(e.key,e.values.unix_nanos.val)))
      op (RequestValueLists values.val) :=
  evaluate_using RustfsDateParser.parse_ok inner op values b h
end rustfs_kernel.Verified.RustfsDateEvaluate
