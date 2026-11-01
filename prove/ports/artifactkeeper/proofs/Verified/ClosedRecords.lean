import ArtifactkeeperKernel
import H5iAppLib
open Aeneas Aeneas.Std Result H5iAppLib artifactkeeper_kernel
namespace artifactkeeper_kernel.Verified.ClosedRecords
set_option maxHeartbeats 1000000
@[step] theorem bytes_to_vec (s : Slice U8) :
    alloc.slice.Slice.to_vec core.clone.CloneU8 s ⦃r => r.val = s.val⦄ := by
  apply WP.spec_mono (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 s (by intros; rfl))
  intro r hr
  exact (congrArg Slice.val hr).symm

@[step] theorem plugin_resource_limits_default_a005c35c_complete :
    closed_records.plugin_resource_limits_default_a005c35c.make ⦃r => r.memory_mb.val = 64 ∧
      r.timeout_secs.val = 5 ∧
      r.fuel.val = 500000000⦄ := by
  unfold closed_records.plugin_resource_limits_default_a005c35c.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem plugin_capabilities_default_a005c35c_complete :
    closed_records.plugin_capabilities_default_a005c35c.make ⦃r => r.parse_metadata = true ∧
      r.generate_index = false ∧
      r.validate_artifact = true ∧
      r.handle_request = false⦄ := by
  unfold closed_records.plugin_capabilities_default_a005c35c.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem capabilities_config_default_75c080e9_complete :
    closed_records.capabilities_config_default_75c080e9.make ⦃r => r.parse_metadata = true ∧
      r.generate_index = false ∧
      r.validate_artifact = true ∧
      r.handle_request = false⦄ := by
  unfold closed_records.capabilities_config_default_75c080e9.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem telemetry_settings_default_453927f4_complete :
    closed_records.telemetry_settings_default_453927f4.make ⦃r => r.enabled = false ∧
      r.review_before_send = true ∧
      r.scrub_level.val = [115#u8, 116#u8, 97#u8, 110#u8, 100#u8, 97#u8, 114#u8, 100#u8] ∧
      r.include_logs = false⦄ := by
  unfold closed_records.telemetry_settings_default_453927f4.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

@[step] theorem password_policy_config_default_97110402_complete :
    closed_records.password_policy_config_default_97110402.make ⦃r => r.min_length.val = 8 ∧
      r.max_length.val = 128 ∧
      r.require_uppercase = false ∧
      r.require_lowercase = false ∧
      r.require_digit = false ∧
      r.require_special = false ∧
      r.min_strength.val = 0⦄ := by
  unfold closed_records.password_policy_config_default_97110402.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac

end artifactkeeper_kernel.Verified.ClosedRecords
