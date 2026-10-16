import Verified.RustfsAwsMeaning
import Verified.RustfsResolutionTerminates
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
namespace rustfs_kernel.Verified.RustfsAwsPassMeaning
open RustfsAwsMeaning
 def pendingTexts (xs : List awsvars.Pending) : List (List Nat) :=
  xs.map (fun p => nats p.text.val)
 def passMeaning (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (xs : List awsvars.Pending) (i : Nat) : List (List Nat) :=
  pendingTexts (xs.take i) ++ (xs.drop i).flatMap (pendingMeaning inner c)
 theorem pass_meaning_advance (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (xs : List awsvars.Pending) (i : Nat) (p : awsvars.Pending)
    (hp : xs[i]?=some p) (hm : pendingMeaning inner c p=[nats p.text.val]) :
    passMeaning inner c xs (i+1)=passMeaning inner c xs i := by
  have hi := List.getElem?_eq_some_iff.mp hp |>.1
  have hpi : xs[i]=p := by simpa [List.getElem?_eq_getElem hi] using hp
  unfold passMeaning pendingTexts
  rw [List.take_succ_eq_append_getElem hi,List.drop_eq_getElem_cons hi,hpi]
  simp [List.map_append,hm,List.append_assoc]
 theorem pass_meaning_replace (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (xs ys : List awsvars.Pending) (i : Nat)
    (hp : ys.take i=xs.take i)
    (hm : (ys.drop i).flatMap (pendingMeaning inner c)=
      (xs.drop i).flatMap (pendingMeaning inner c)) :
    passMeaning inner c ys i=passMeaning inner c xs i := by
  simp only [passMeaning,hp,hm]
open H5iAppLib hiding lit
open RustfsResolutionTerminates
 theorem scan_post_ok (ctx : awsvars.VarContext) (depth : Usize)
    (results : alloc.vec.Vec awsvars.Pending) (i : Usize) (p : awsvars.Pending)
    (hp : results.val[i.val]?=some p) (start : Usize) (hs : p.resume.val≤start.val)
    (out : alloc.vec.Vec awsvars.Pending × Bool)
    (h : awsvars.scan ctx results i start depth=ok out) : ScanPost results i out := by
  have hf := scan_fin ctx depth (fun text d _ => depth_fin ctx text d) results i p hp start hs
  rcases hf with ⟨r,hr,hpost⟩ | ⟨e,he⟩
  · have hsame : r=out := Result.ok.inj (hr.symm.trans h)
    subst r
    exact hpost
  · have hh := he.symm.trans h
    exact False.elim (fail_ne_ok hh)
end rustfs_kernel.Verified.RustfsAwsPassMeaning
