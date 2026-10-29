import ArtifactkeeperKernel
import H5iAppLib

open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.MigrationSafety
open migration_safety
set_option maxHeartbeats 2000000
set_option maxRecDepth 4096

lemma push_length {α} (v w : alloc.vec.Vec α) (x : α)
    (h : alloc.vec.Vec.push v x = ok w) : w.val.length = v.val.length + 1 := by
  unfold alloc.vec.Vec.push at h
  h5i_invert h
  simp

/-- Mask output length always tracks its consumed byte offset. -/
def aligned (n start : Usize) (v : alloc.vec.Vec U8) (i : Usize) : Prop :=
  v.val.length = i.val ∧ start.val ≤ i.val ∧ i.val ≤ n.val

lemma segment0 (b : Slice U8) (n start : Usize) (v : alloc.vec.Vec U8)
    (i : Usize)  (out : alloc.vec.Vec U8 × Usize)
    (hv : aligned n start v i)
    (h : mask_sql_loop0_loop0 b n v i  = ok out) :
    aligned n start out.1 out.2 := by
  unfold mask_sql_loop0_loop0 at h
  apply loop_ok _ (fun x => aligned n start x.1 x.2)
    (fun x => aligned n start x.1 x.2)
    (fun x => n.val - x.2.val) ?_ (v,i) out hv h
  rintro ⟨v,i⟩ r hv hr
  unfold mask_sql_loop0_loop0.body at hr
  h5i_invert hr
  all_goals simp only [aligned] at *
  all_goals
    repeat' (match_goal with
      | h : alloc.vec.Vec.push ?v ?x = ok ?w ⊢ _ =>
        have hp := push_length v w x h
        clear h
      )
    h5i_ok_facts
    simp_all only [UScalar.ofNatCore_val_eq]
    try scalar_tac
    omega

lemma segment1 (b : Slice U8) (n start : Usize) (v : alloc.vec.Vec U8)
    (i : Usize) (depth : U32) (out : alloc.vec.Vec U8 × Usize)
    (hv : aligned n start v i)
    (h : mask_sql_loop0_loop1 b n v i depth = ok out) :
    aligned n start out.1 out.2 := by
  unfold mask_sql_loop0_loop1 at h
  apply loop_ok _ (fun x => aligned n start x.1 x.2.1)
    (fun x => aligned n start x.1 x.2)
    (fun x => n.val - x.2.1.val) ?_ (v,i,depth) out hv h
  rintro ⟨v,i,d⟩ r hv hr
  unfold mask_sql_loop0_loop1.body at hr
  h5i_invert hr
  all_goals simp only [aligned] at *
  all_goals
    repeat' (match_goal with
      | h : alloc.vec.Vec.push ?v ?x = ok ?w ⊢ _ =>
        have hp := push_length v w x h
        clear h
      )
    h5i_ok_facts
    simp_all only [UScalar.ofNatCore_val_eq]
    try scalar_tac
    omega

lemma segment2 (b : Slice U8) (n start : Usize) (v : alloc.vec.Vec U8)
    (i : Usize)  (out : alloc.vec.Vec U8 × Usize)
    (hv : aligned n start v i)
    (h : mask_sql_loop0_loop2 b n v i  = ok out) :
    aligned n start out.1 out.2 := by
  unfold mask_sql_loop0_loop2 at h
  apply loop_ok _ (fun x => aligned n start x.1 x.2)
    (fun x => aligned n start x.1 x.2)
    (fun x => n.val - x.2.val) ?_ (v,i) out hv h
  rintro ⟨v,i⟩ r hv hr
  unfold mask_sql_loop0_loop2.body at hr
  h5i_invert hr
  all_goals simp only [aligned] at *
  all_goals
    repeat' (match_goal with
      | h : alloc.vec.Vec.push ?v ?x = ok ?w ⊢ _ =>
        have hp := push_length v w x h
        clear h
      )
    h5i_ok_facts
    simp_all only [UScalar.ofNatCore_val_eq]
    try scalar_tac
    omega

lemma segment3 (b : Slice U8) (n start : Usize) (v : alloc.vec.Vec U8)
    (i : Usize)  (out : alloc.vec.Vec U8 × Usize)
    (hv : aligned n start v i)
    (h : mask_sql_loop0_loop3 b n v i  = ok out) :
    aligned n start out.1 out.2 := by
  unfold mask_sql_loop0_loop3 at h
  apply loop_ok _ (fun x => aligned n start x.1 x.2)
    (fun x => aligned n start x.1 x.2)
    (fun x => n.val - x.2.val) ?_ (v,i) out hv h
  rintro ⟨v,i⟩ r hv hr
  unfold mask_sql_loop0_loop3.body at hr
  h5i_invert hr
  all_goals simp only [aligned] at *
  all_goals
    repeat' (match_goal with
      | h : alloc.vec.Vec.push ?v ?x = ok ?w ⊢ _ =>
        have hp := push_length v w x h
        clear h
      )
    h5i_ok_facts
    simp_all only [UScalar.ofNatCore_val_eq]
    try scalar_tac
    omega

lemma segment4 (b : Slice U8) (n start : Usize) (v : alloc.vec.Vec U8)
    (i : Usize) (depth : U32) (out : alloc.vec.Vec U8 × Usize)
    (hv : aligned n start v i)
    (h : mask_sql_loop0_loop4 b n v i depth = ok out) :
    aligned n start out.1 out.2 := by
  unfold mask_sql_loop0_loop4 at h
  apply loop_ok _ (fun x => aligned n start x.1 x.2.1)
    (fun x => aligned n start x.1 x.2)
    (fun x => n.val - x.2.1.val) ?_ (v,i,depth) out hv h
  rintro ⟨v,i,d⟩ r hv hr
  unfold mask_sql_loop0_loop4.body at hr
  h5i_invert hr
  all_goals simp only [aligned] at *
  all_goals
    repeat' (match_goal with
      | h : alloc.vec.Vec.push ?v ?x = ok ?w ⊢ _ =>
        have hp := push_length v w x h
        clear h
      )
    h5i_ok_facts
    simp_all only [UScalar.ofNatCore_val_eq]
    try scalar_tac
    omega

lemma segment5 (b : Slice U8) (n start : Usize) (v : alloc.vec.Vec U8)
    (i : Usize)  (out : alloc.vec.Vec U8 × Usize)
    (hv : aligned n start v i)
    (h : mask_sql_loop0_loop5 b n v i  = ok out) :
    aligned n start out.1 out.2 := by
  unfold mask_sql_loop0_loop5 at h
  apply loop_ok _ (fun x => aligned n start x.1 x.2)
    (fun x => aligned n start x.1 x.2)
    (fun x => n.val - x.2.val) ?_ (v,i) out hv h
  rintro ⟨v,i⟩ r hv hr
  unfold mask_sql_loop0_loop5.body at hr
  h5i_invert hr
  all_goals simp only [aligned] at *
  all_goals
    repeat' (match_goal with
      | h : alloc.vec.Vec.push ?v ?x = ok ?w ⊢ _ =>
        have hp := push_length v w x h
        clear h
      )
    h5i_ok_facts
    simp_all only [UScalar.ofNatCore_val_eq]
    try scalar_tac
    omega

lemma segment6 (b : Slice U8) (n start : Usize) (v : alloc.vec.Vec U8)
    (i : Usize)  (out : alloc.vec.Vec U8 × Usize)
    (hv : aligned n start v i)
    (h : mask_sql_loop0_loop6 b n v i  = ok out) :
    aligned n start out.1 out.2 := by
  unfold mask_sql_loop0_loop6 at h
  apply loop_ok _ (fun x => aligned n start x.1 x.2)
    (fun x => aligned n start x.1 x.2)
    (fun x => n.val - x.2.val) ?_ (v,i) out hv h
  rintro ⟨v,i⟩ r hv hr
  unfold mask_sql_loop0_loop6.body at hr
  h5i_invert hr
  all_goals simp only [aligned] at *
  all_goals
    repeat' (match_goal with
      | h : alloc.vec.Vec.push ?v ?x = ok ?w ⊢ _ =>
        have hp := push_length v w x h
        clear h
      )
    h5i_ok_facts
    simp_all only [UScalar.ofNatCore_val_eq]
    try scalar_tac
    omega

