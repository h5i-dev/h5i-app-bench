import Verified.RustfsAwsScan
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsAwsMeaning
set_option maxHeartbeats 1000000
def pendingMeaning (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (p : awsvars.Pending) : List (List Nat) :=
  ResumeAlternatives inner c (nats p.text.val) p.resume.val
 theorem wrap_meaning_ok (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (pre post : Slice U8) (values : Slice (alloc.vec.Vec U8)) (offset : Usize)
    (hout : offset.val=pre.val.length) (out : alloc.vec.Vec awsvars.Pending)
    (h : awsvars.wrap_all pre values post offset=ok out) :
    out.val.flatMap (pendingMeaning inner c) =
      values.val.flatMap (fun value => (ExpansionPass inner c (nats post.val)).map
        (fun suffix => nats pre.val ++ nats value.val ++ suffix)) := by
  have hw := RustfsAwsCollections.wrap_ok pre post values offset out h
  have hm : out.val.flatMap (pendingMeaning inner c) =
      (out.val.map RustfsAwsCollections.pending).flatMap (fun p =>
        ResumeAlternatives inner c (nats p.1) p.2) := by
    simp only [List.flatMap_map,RustfsAwsCollections.pending]
    rfl
  rw [hm,hw]
  simp only [WrappedValues,List.flatMap_map,List.map_map,Function.comp_def]
  apply congrArg (fun f : alloc.vec.Vec U8 → List (List Nat) => values.val.flatMap f)
  funext value
  simp only [nats,List.map_append,hout]
  simpa only [nats,List.length_map] using
    resume_wrapped inner c (nats pre.val) (nats value.val) (nats post.val)
theorem splice_meaning_ok (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (xs new : Slice awsvars.Pending) (idx : Usize) (out : alloc.vec.Vec awsvars.Pending)
    (hi : idx.val ≤ xs.val.length) (h : awsvars.splice xs idx new=ok out) :
    out.val.take idx.val=xs.val.take idx.val ∧
      (out.val.drop idx.val).flatMap (pendingMeaning inner c) =
        new.val.flatMap (pendingMeaning inner c) ++
          (xs.val.drop (idx.val+1)).flatMap (pendingMeaning inner c) := by
  have ho := RustfsAwsCollections.splice_ok xs new idx out h
  have hp : (xs.val.take idx.val).length=idx.val := by simp [List.length_take,hi]
  rw [ho]
  simp [hp,List.append_assoc,List.flatMap_append]
end rustfs_kernel.Verified.RustfsAwsMeaning
