import Verified.RustfsDateMeaning
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsDateNanos
set_option maxHeartbeats 1000000
lemma cast_ok (a : I64) (r : I128) (h : lift (IScalar.cast .I128 a)=ok r) : r.val=a.val :=
  H5iAppLib.post_of_ok (x:=r) (P:=fun z : I128 => z.val=a.val)
    (IScalar.cast_inBounds_spec .I128 a (by scalar_tac)) h
theorem nanos_ok (utc nano : I64) (r : I128) (h : dates.nanos utc nano=ok r) :
    r.val=InstantNanos utc.val nano.val := by
  unfold dates.nanos at h
  h5i_invert h
  have hc := cast_ok _ _ hi
  have hc' := cast_ok _ _ hi2
  have hm := IScalar.mul_equiv i 1000000000#i128
  change IScalar.mul i 1000000000#i128=ok i1 at hi1
  rw [hi1] at hm
  have ha := IScalar.add_equiv i1 i2
  rw [h] at ha
  simp only [InstantNanos,ha.2.1,hm.2.2.1,hc,hc',IScalar.ofInt_val_eq]
end rustfs_kernel.Verified.RustfsDateNanos
