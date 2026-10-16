import SpecKmsStatement
import Verified.RustfsResourceMeaning
import Verified.RustfsKmsFilter
import Verified.RustfsStatementSkips
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsKmsMeaning
set_option maxHeartbeats 4000000
open RustfsForceDelete
lemma scalar_eq {ty} (a b : UScalar ty) : a=b ↔ a.val=b.val := ⟨congrArg UScalar.val, UScalar.eq_of_val_eq⟩
lemma zero_not_pos (n : Nat) : n=0 ↔ ¬0<n := by omega
lemma backup_lit : lit "kms:Backup" = [107,109,115,58,66,97,99,107,117,112] := by decide +kernel
lemma restore_lit : lit "kms:Restore" = [107,109,115,58,82,101,115,116,111,114,101] := by decide +kernel
lemma key_lit : lit "key/" = [107,101,121,47] := by decide +kernel
def backupCheck (args : stmts.Args) : Result Bool :=
  if decide (args.action.family=.Kms)
    then
      do
      let s := alloc.vec.Vec.deref args.action.name
      let s1 ←
        lift (Array.to_slice
          (Array.make 10#usize [
            107#u8, 109#u8, 115#u8, 58#u8, 66#u8, 97#u8, 99#u8, 107#u8, 117#u8,
            112#u8
            ]))
      let b1 ← bytes.eq s s1
      if b1
      then ok true
      else
        let s2 := alloc.vec.Vec.deref args.action.name
        let s3 ←
          lift (Array.to_slice
            (Array.make 11#usize [
              107#u8, 109#u8, 115#u8, 58#u8, 82#u8, 101#u8, 115#u8, 116#u8,
              111#u8, 114#u8, 101#u8
              ]))
        bytes.eq s2 s3
    else ok false
theorem backup_ok (args : stmts.Args) (b : Bool) (h : backupCheck args=ok b) :
    b=true ↔ args.action.family=.Kms ∧ nats args.action.name.val ∈ [lit "kms:Backup",lit "kms:Restore"] := by
  unfold backupCheck at h
  simp only [family_eq_ok] at h
  h5i_invert h
  all_goals try have hl1 := lift_slice hs1
  all_goals try have hl2 := lift_slice hs3
  all_goals try have he1 := RustfsResourceMeaning.eq_nats _ _ _ hb1
  all_goals try have he2 := RustfsResourceMeaning.eq_nats _ _ _ h
  all_goals try simp only [deref_val] at *
  all_goals simp_all [backup_lit,restore_lit,List.mem_cons,List.not_mem_nil]
theorem scope_ok (st : stmts.Statement) (args : stmts.Args) (ctx : Option awsvars.VarContext)
    (b : Bool) (h : stmts.kms_key_scope_matches st args ctx=ok b) :
    b=true ↔ KmsScopeHolds (ctx.map RustfsAwsValues.context) st args := by
  unfold stmts.kms_key_scope_matches at h
  simp only [family_eq_ok,bind_ok] at h
  bcase br with hbr at h
  change backupCheck args=ok br at hbr
  have hbackup := backup_ok args br hbr
  simp only [effect_eq_ok] at h
  h5i_invert h
  all_goals try have hf := RustfsKmsFilter.filter_ok _ _ (by assumption : stmts.kms_only st.resources.deref=ok _)
  all_goals try have hn := RustfsKmsFilter.filter_ok _ _ (by assumption : stmts.kms_only st.not_resources.deref=ok _)
  all_goals try have hl := lift_slice (by assumption : lift (Array.to_slice _) = ok _)
  all_goals
    try
      have hr : nats requested.val=lit "key/" ++ nats args.object.val := by
        rw [RustfsConditionEval.concat_ok _ _ _ (by assumption : bytes.concat _ _=ok requested)]
        simpa only [nats,List.map_append,deref_val,key_lit,List.map_cons,List.map_nil,UScalar.ofNatCore_val_eq] using congrArg (fun x=>x ++ nats args.object.val) hl
  all_goals try have hp := RustfsResourceMeaning.set_ok _ _ _ _ _ (by assumption : rsrc.set_is_match kms_resources.deref _ args.conditions ctx=ok _)
  all_goals try have hm := RustfsResourceMeaning.set_ok _ _ _ _ _ (by assumption : rsrc.set_is_match kms_not_resources.deref _ args.conditions ctx=ok _)
  all_goals simp only [scalar_eq,deref_val,gt_iff_lt,UScalar.lt_equiv,alloc.vec.Vec.len_val,alloc.vec.Vec.length,UScalar.ofNatCore_val_eq] at *
  all_goals unfold KmsScopeHolds
  all_goals simp only [KmsResources]
  all_goals try rw [←hf,←hn]
  all_goals try rw [←hr]
  all_goals simp_all only [ne_eq,decide_eq_true_eq,Bool.false_eq_true,Bool.true_eq_false,true_iff,false_iff,not_true_eq_false,not_false_eq_true,List.eq_nil_iff_length_eq_zero,zero_not_pos]
  all_goals split
  all_goals try cases b1
  all_goals try cases b2
  all_goals try simp only [Bool.true_eq_false,Bool.false_eq_true,true_iff,false_iff,not_true_eq_false,not_false_eq_true] at *
  all_goals try rw [hf,hn] at *
  all_goals tauto
end rustfs_kernel.Verified.RustfsKmsMeaning
