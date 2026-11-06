import TdFreeKernel
import Spec
import H5iAppLib.Basic
/-!
# Properties of td-free's extracted VEML3328 config kernel

Security/safety (S) and correspondence (C) theorems. See STATUS.md for the
S/C/F table and the mutants each S kills.
-/
open Aeneas Aeneas.Std Result td_free_kernel

namespace td_free_kernel.Properties

/-! ## Totality foundations (C) -/

/-- The exact value `set_bits` computes. -/
theorem set_bits_val (c : Config) (mask value : Std.U16) :
    set_bits c mask value = ok { bits := (c.bits &&& ~~~mask) ||| (value &&& mask) } := by
  simp [set_bits, lift]

/-- `set_bits` is total (never panics). -/
theorem set_bits_total (c : Config) (mask value : Std.U16) :
    ∃ r, set_bits c mask value = ok r :=
  ⟨_, set_bits_val c mask value⟩

/-- `gain_bits` is total. -/
theorem gain_bits_ok (g : Gain) : ∃ v, gain_bits g = ok v := by
  cases g <;> exact ⟨_, rfl⟩

/-- `it_bits` is total. -/
theorem it_bits_ok (it : IntegrationTime) : ∃ v, it_bits it = ok v := by
  cases it <;> exact ⟨_, rfl⟩

/-! ## Field isolation (the core safety property) -/

/-- **Security (S): field isolation.** Writing the `mask` field leaves every
bit of a disjoint field `m` (`m &&& mask = 0`) unchanged. A plausible bug — not
re-masking `value`, or using the wrong mask — breaks this. Kills
`set_bits_value_unmasked`. -/
theorem set_bits_preserves_complement (c : Config) (mask value m : Std.U16)
    (hdisj : m &&& mask = 0#u16) :
    ∀ cfg, set_bits c mask value = ok cfg → cfg.bits &&& m = c.bits &&& m := by
  intro cfg h
  rw [set_bits_val] at h
  injection h with h; subst h
  bvify 16 at hdisj ⊢
  bv_decide

/-- The `mask` field is set to `value` (restricted to the field). (C) -/
theorem set_bits_sets_masked (c : Config) (mask value : Std.U16) :
    ∀ cfg, set_bits c mask value = ok cfg → cfg.bits &&& mask = value &&& mask := by
  intro cfg h
  rw [set_bits_val] at h
  injection h with h; subst h
  bvify 16
  bv_decide

/-! ## Register-write safety (S) -/

/-- `set_gain_config` reduces to a single `set_bits` on the gain field. -/
theorem set_gain_val (c : Config) (g : Gain) :
    ∃ v, set_gain_config c g = set_bits c GAIN_MASK v := by
  cases g <;> exact ⟨_, rfl⟩

/-- `set_it_config` reduces to a single `set_bits` on the IT field. -/
theorem set_it_val (c : Config) (it : IntegrationTime) :
    ∃ v, set_it_config c it = set_bits c IT_MASK v := by
  cases it <;> exact ⟨_, rfl⟩

/-- **Security (S): setting the gain never changes the shutdown bits.** So a
gain reconfiguration cannot power the sensor down. Kills `set_gain_wrong_mask`. -/
theorem set_gain_preserves_shutdown (c : Config) (g : Gain) :
    ∀ cfg, set_gain_config c g = ok cfg → cfg.bits &&& SHUTDOWN = c.bits &&& SHUTDOWN := by
  intro cfg h
  obtain ⟨v, hv⟩ := set_gain_val c g
  rw [hv] at h
  exact set_bits_preserves_complement c GAIN_MASK v SHUTDOWN
    TdFree.Spec.shutdown_gain_disjoint cfg h

/-- **Security (S): setting the integration time never changes shutdown.** -/
theorem set_it_preserves_shutdown (c : Config) (it : IntegrationTime) :
    ∀ cfg, set_it_config c it = ok cfg → cfg.bits &&& SHUTDOWN = c.bits &&& SHUTDOWN := by
  intro cfg h
  obtain ⟨v, hv⟩ := set_it_val c it
  rw [hv] at h
  exact set_bits_preserves_complement c IT_MASK v SHUTDOWN
    TdFree.Spec.shutdown_it_disjoint cfg h

/-- **Security (S): setting the integration time never changes the gain.** -/
theorem set_it_preserves_gain (c : Config) (it : IntegrationTime) :
    ∀ cfg, set_it_config c it = ok cfg → cfg.bits &&& GAIN_MASK = c.bits &&& GAIN_MASK := by
  intro cfg h
  obtain ⟨v, hv⟩ := set_it_val c it
  rw [hv] at h
  exact set_bits_preserves_complement c IT_MASK v GAIN_MASK
    TdFree.Spec.gain_it_disjoint cfg h

/-- **Security (S): setting the gain never changes the integration time.** -/
theorem set_gain_preserves_it (c : Config) (g : Gain) :
    ∀ cfg, set_gain_config c g = ok cfg → cfg.bits &&& IT_MASK = c.bits &&& IT_MASK := by
  intro cfg h
  obtain ⟨v, hv⟩ := set_gain_val c g
  rw [hv] at h
  have hdisj : IT_MASK &&& GAIN_MASK = 0#u16 := by unfold IT_MASK GAIN_MASK; decide
  exact set_bits_preserves_complement c GAIN_MASK v IT_MASK hdisj cfg h

/-- **Security (S): enable powers the sensor on** — both shutdown bits clear. -/
theorem enable_clears_shutdown :
    ∀ cfg, enable_config = ok cfg → cfg.bits &&& SHUTDOWN = 0#u16 := by
  intro cfg h
  simp only [enable_config, config_new, with_low, set_bits_val, lift, bind, Result.bind] at h
  injection h with h; subst h
  simp only [SHUTDOWN, IT_MASK, IT_100MS, GAIN_MASK, GAIN_ONE]
  bvify 16
  bv_decide

/-- `disable` sets the chip-shutdown bit. (C) -/
theorem disable_sets_shutdown :
    ∀ c cfg, disable_config c = ok cfg → cfg.bits &&& SD0 = SD0 := by
  intro c cfg h
  simp only [disable_config, with_high, lift] at h
  injection h with h; subst h
  simp only [SD0]
  bvify 16
  bv_decide

/-! ## Finding (F) -/

/-- **Finding (F): the integration-time encodings overflow `IT_MASK`.**
`IT_25MS = 0b1100<<4` and `IT_50MS = 0b1000<<4` set bits *outside* the 3-bit
`IT_MASK = 0b111<<4`, so `set_integration_time` silently drops them: after
masking, `_50ms` and `_100ms` are indistinguishable (both 0). Latent only —
`set_integration_time` is never called by the firmware (it uses the hard-coded
100 ms in `enable`), so this is informational, not exploitable. -/
theorem it_mask_collision :
    (IT_50MS &&& IT_MASK = IT_100MS &&& IT_MASK) ∧ (IT_25MS &&& ~~~IT_MASK ≠ 0#u16) := by
  refine ⟨?_, ?_⟩
  · unfold IT_50MS IT_100MS IT_MASK; decide
  · unfold IT_25MS IT_MASK; decide

end td_free_kernel.Properties
