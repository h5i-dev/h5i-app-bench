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
 theorem wrapped_scan_ok (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (text : List U8) (start pos closing : Nat)
    (hf : FirstOccurrence text [36#u8,123#u8] start (some pos))
    (hc : ClosingTail (nats (text.drop (pos+2))) 1=(closing,0))
    (pre post : Slice U8) (values : Slice (alloc.vec.Vec U8)) (offset : Usize)
    (hp : pre.val=text.take pos) (hs : post.val=text.drop (pos+closing+3))
    (ho : offset.val=pos)
    (hr : PlaceholderAlternatives inner c ((nats (text.drop (pos+2))).take closing)
      ((36::123::nats (text.drop (pos+2))).take (closing+3))=
        values.val.map (fun value => nats value.val))
    (results : Slice awsvars.Pending) (idx : Usize) (new out : alloc.vec.Vec awsvars.Pending)
    (hi : idx.val ≤ results.val.length)
    (hw : awsvars.wrap_all pre values post offset=ok new)
    (hsplice : awsvars.splice results idx new.slice=ok out) :
    out.val.take idx.val=results.val.take idx.val ∧
      (out.val.drop idx.val).flatMap (pendingMeaning inner c)=
        ResumeAlternatives inner c (nats text) start ++
          (results.val.drop (idx.val+1)).flatMap (pendingMeaning inner c) := by
  have hlen : offset.val=pre.val.length := by
    have hbound := hf.2.1.1
    simp only [List.length_cons,List.length_nil] at hbound
    rw [ho,hp,List.length_take]
    omega
  obtain ⟨ht,hmeaning⟩ := splice_meaning_ok inner c results new.slice idx out hi hsplice
  refine ⟨ht,?_⟩
  rw [hmeaning]
  have hwrapped := wrap_meaning_ok inner c pre post values offset hlen new hw
  change new.val.flatMap (pendingMeaning inner c) ++ _ = _
  rw [hwrapped]
  congr 1
  rw [RustfsAwsScan.resume_balanced inner c text start pos closing hf hc,hr]
  simp only [List.flatMap_map,hp,hs]
 theorem empty_scan_ok (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (text : List U8) (start pos closing : Nat)
    (hf : FirstOccurrence text [36#u8,123#u8] start (some pos))
    (hc : ClosingTail (nats (text.drop (pos+2))) 1=(closing,0))
    (pre post : Slice U8) (offset : Usize)
    (hp : pre.val=text.take pos) (hs : post.val=text.drop (pos+closing+3))
    (ho : offset.val=pos)
    (hr : PlaceholderAlternatives inner c ((nats (text.drop (pos+2))).take closing)
      ((36::123::nats (text.drop (pos+2))).take (closing+3))=[[]])
    (results : Slice awsvars.Pending) (idx : Usize) (v : alloc.vec.Vec U8)
    (new out : alloc.vec.Vec awsvars.Pending) (hi : idx.val ≤ results.val.length)
    (hconcat : bytes.concat pre post=ok v)
    (hpush : (alloc.vec.Vec.new awsvars.Pending).push {text:=v,resume:=offset}=ok new)
    (hsplice : awsvars.splice results idx new.slice=ok out) :
    out.val.take idx.val=results.val.take idx.val ∧
      (out.val.drop idx.val).flatMap (pendingMeaning inner c)=
        ResumeAlternatives inner c (nats text) start ++
          (results.val.drop (idx.val+1)).flatMap (pendingMeaning inner c) := by
  have hlen : offset.val=(nats pre.val).length := by
    have hbound := hf.2.1.1
    simp only [List.length_cons,List.length_nil] at hbound
    rw [ho,hp]
    simp only [nats,List.length_map,List.length_take]
    omega
  obtain ⟨ht,hmeaning⟩ := splice_meaning_ok inner c results new.slice idx out hi hsplice
  refine ⟨ht,?_⟩
  rw [hmeaning]
  have hnew := RustfsBytes.push_ok hpush
  have hv := RustfsConditionEval.concat_ok pre post v hconcat
  change new.val=[{text:=v,resume:=offset}] at hnew
  change new.val.flatMap (pendingMeaning inner c) ++ _ = _
  rw [hnew]
  congr 1
  simp only [List.flatMap_cons,List.flatMap_nil,List.append_nil,pendingMeaning]
  rw [hv]
  simp only [nats,List.map_append]
  rw [hlen]
  change ResumeAlternatives inner c (nats pre.val ++ nats post.val) (nats pre.val).length =
    ResumeAlternatives inner c (nats text) start
  rw [resume_append]
  rw [RustfsAwsScan.resume_balanced inner c text start pos closing hf hc,hr]
  simp only [List.flatMap_cons,List.flatMap_nil,List.append_nil,hp,hs]
end rustfs_kernel.Verified.RustfsAwsMeaning
