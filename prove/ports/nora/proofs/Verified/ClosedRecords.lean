import NoraKernel
import H5iAppLib
open Aeneas Aeneas.Std Result H5iAppLib nora_kernel
namespace nora_kernel.Verified.ClosedRecords
set_option maxHeartbeats 1000000
@[step] theorem bytes_to_vec (s : Slice U8) :
    alloc.slice.Slice.to_vec core.clone.CloneU8 s ⦃r => r.val = s.val⦄ := by
  apply WP.spec_mono (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 s (by intros; rfl))
  intro r hr
  exact (congrArg Slice.val hr).symm

@[step] theorem signing_config_default_942b3541_complete :
    closed_records.signing_config_default_942b3541.make ⦃r => r.enabled = true ∧
      r.key_path.val = []⦄ := by
  unfold closed_records.signing_config_default_942b3541.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem env_provider_new_23e18cff_complete :
    closed_records.env_provider_new_23e18cff.make ⦃r => r.clear_after_read = false⦄ := by
  unfold closed_records.env_provider_new_23e18cff.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

end nora_kernel.Verified.ClosedRecords
