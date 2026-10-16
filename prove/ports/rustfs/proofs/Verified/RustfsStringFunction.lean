import Verified.RustfsStringEval
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsStringFunction
set_option maxHeartbeats 2000000
set_option linter.unusedSimpArgs false
open RustfsPolicyValues
theorem entry_ok (key : condfuncs.Key) (v : alloc.vec.Vec (alloc.vec.Vec U8))
    (q : condfuncs.Quantifier) (ignore_case like negate : Bool)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (pair : Bool × Bool)
    (h : (
      match q with
      | condfuncs.Quantifier.None =>
        do
        let matched ←
          if like
          then
            let s := alloc.vec.Vec.deref v
            condfuncs.str_eval_like key s condfuncs.Quantifier.None false
              values ctx
          else
            let s := alloc.vec.Vec.deref v
            condfuncs.str_eval key s condfuncs.Quantifier.None ignore_case
              false values ctx
        ok (like, matched ^^ negate)
      | condfuncs.Quantifier.ForAnyValue =>
        do
        let b ←
          if like
          then
            let s := alloc.vec.Vec.deref v
            condfuncs.str_eval_like key s condfuncs.Quantifier.ForAnyValue
              negate values ctx
          else
            let s := alloc.vec.Vec.deref v
            condfuncs.str_eval key s condfuncs.Quantifier.ForAnyValue
              ignore_case negate values ctx
        ok (like, b)
      | condfuncs.Quantifier.ForAllValues =>
        do
        let b ←
          if like
          then
            let s := alloc.vec.Vec.deref v
            condfuncs.str_eval_like key s condfuncs.Quantifier.ForAllValues
              negate values ctx
          else
            let s := alloc.vec.Vec.deref v
            condfuncs.str_eval key s condfuncs.Quantifier.ForAllValues
              ignore_case negate values ctx
        ok (like, b)
)=ok pair) :
    pair.1=like ∧ (pair.2=true ↔ StringEntryHolds (ctx.map RustfsAwsValues.context)
      (RequestValueLists values.val) key (texts v.val) q ignore_case like negate) := by
  cases q <;> cases like <;> simp only [Bool.false_eq_true, ↓reduceIte] at h
  all_goals h5i_invert h
  all_goals first
    | have hh := RustfsStringEval.equality_ok _ _ _ _ _ _ _ _ (by assumption)
    | have hh := RustfsStringEval.like_ok _ _ _ _ _ _ _ (by assumption)
  all_goals dsimp only [StringEntryHolds]
  all_goals cases negate <;> simp_all [RustfsForceDelete.deref_val]
  all_goals rw [←hh]; cases matched <;> simp
theorem function_ok (funcs : Slice (condfuncs.Key × alloc.vec.Vec (alloc.vec.Vec U8)))
    (q : condfuncs.Quantifier) (ignoreCase like negate : Bool)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (b : Bool)
    (h : condfuncs.str_func funcs q ignoreCase like negate values ctx=ok b) :
    b=true ↔ ∀ entry ∈ funcs.val, StringEntryHolds (ctx.map RustfsAwsValues.context)
      (RequestValueLists values.val) entry.1 (texts entry.2.val) q ignoreCase like negate := by
  let P := fun entry : condfuncs.Key × alloc.vec.Vec (alloc.vec.Vec U8) =>
    StringEntryHolds (ctx.map RustfsAwsValues.context) (RequestValueLists values.val)
      entry.1 (texts entry.2.val) q ignoreCase like negate
  unfold condfuncs.str_func condfuncs.str_func_loop at h
  refine loop_ok _ (fun s : Bool × Usize => s.1=like ∧ s.2.val ≤ funcs.val.length ∧
    ∀ x ∈ funcs.val.take s.2.val, P x)
    (fun r => r=true ↔ ∀ x ∈ funcs.val, P x)
    (fun s => funcs.val.length-s.2.val) ?_ _ b ⟨rfl,by simp,by simp⟩ h
  rintro ⟨flag,i⟩ r ⟨hflag,hi,hall⟩ hr
  dsimp only at hflag hi hall hr ⊢
  subst flag
  unfold condfuncs.str_func_loop.body at hr
  by_cases hlt : i<funcs.len
  · simp only [hlt,↓reduceIte] at hr
    obtain ⟨entry,hentry,hr⟩ := bind_tc_eq_ok.mp hr
    rcases entry with ⟨key,v⟩
    obtain ⟨pair,hpair,hr⟩ := bind_tc_eq_ok.mp hr
    have hh := entry_ok key v q ignoreCase like negate values ctx pair hpair
    rcases pair with ⟨flag,result⟩
    dsimp only at hh
    obtain ⟨hflag,hh⟩ := hh
    subst flag
    obtain ⟨hidx,he⟩ := slice_index_ok hentry
    have hp : P funcs.val[i.val] ↔ result=true := by rw [he]; exact hh.symm
    change (if result then do let next ← i+1#usize; ok (ControlFlow.cont (like,next))
      else ok (ControlFlow.done false))=ok r at hr
    by_cases hb : result=true
    · simp only [hb,↓reduceIte] at hr
      h5i_invert hr
      have hn : next.val=i.val+1 := by have := add_ok_val hnext; scalar_tac
      dsimp only
      refine ⟨⟨rfl,by omega,?_⟩,by omega⟩
      intro x hx
      rw [hn,List.take_succ_eq_append_getElem hidx] at hx
      rcases List.mem_append.mp hx with hx | hx
      · exact hall x hx
      · have heq : x=funcs.val[i.val] := by simpa using hx
        rw [heq]; exact hp.mpr hb
    · simp only [hb,Bool.false_eq_true,↓reduceIte,Result.ok.injEq] at hr
      subst r
      simp only [Bool.false_eq_true,false_iff]
      intro h; exact hb (hp.mp (h _ (List.getElem_mem hidx)))
  · simp only [hlt,↓reduceIte,Result.ok.injEq] at hr
    subst r
    have hn : funcs.val.length ≤ i.val := by scalar_tac
    rw [List.take_of_length_le hn] at hall
    simpa using hall
end rustfs_kernel.Verified.RustfsStringFunction
