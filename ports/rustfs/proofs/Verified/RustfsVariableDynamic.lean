import Verified.RustfsVariableScalars
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
namespace rustfs_kernel.Verified.RustfsVariableDynamic
 theorem equal_nats (s p : Slice U8) (b : Bool) (h : bytes.eq s p = ok b) :
    (b = true ↔ nats s.val = nats p.val) := by
  rw [rustfs_kernel.Verified.RustfsForceDelete.bytes_eq_ok _ _ _ h]
  exact ⟨congrArg nats,rustfs_kernel.Verified.RustfsForceDelete.nats_inj⟩
 theorem dynamic_ok (needle : Slice U8) (b : Bool) (h : varctx.is_dynamic needle = ok b) :
    (b = true ↔ nats needle.val = lit "aws:CurrentTime" ∨ nats needle.val = lit "aws:EpochTime") := by
  unfold varctx.is_dynamic at h
  h5i_invert h
  all_goals
    have hl : nats s.val = lit "aws:CurrentTime" := by
      rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs]
      decide +kernel
    have he := equal_nats _ _ _ hb_1
    rw [hl] at he
  case isTrue => simp [he.mp hc]
  case isFalse =>
    have hl1 : nats s1.val = lit "aws:EpochTime" := by
      rw [rustfs_kernel.Verified.RustfsForceDelete.lift_slice hs1]
      decide +kernel
    have he1 := equal_nats _ _ _ h
    rw [hl1] at he1
    have hn : nats needle.val ≠ lit "aws:CurrentTime" := fun hh => hc (he.mpr hh)
    simpa only [hn,false_or] using he1
end rustfs_kernel.Verified.RustfsVariableDynamic
