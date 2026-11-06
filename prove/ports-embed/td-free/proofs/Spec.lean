import Aeneas
import TdFreeKernel
/-!
# Spec: the VEML3328 CONFIG-register field model

The CONFIG register packs independent fields into one `u16`:

* shutdown  = bit 0 (`SD0`) and bit 15 (`SD1`)
* gain      = bits [12:11] (`GAIN_MASK`)
* integration time = bits [6:4] (`IT_MASK`)

The safety model is simply that these fields are **pairwise disjoint**: a write
to one field must not touch another. `Properties.lean` proves the kernel's
per-field register writes respect this, so reconfiguring gain or integration
time can never flip a shutdown bit and silently power the sensor off (which
would turn every later reading into a nonsensical physical value).
-/
open Aeneas Aeneas.Std td_free_kernel

namespace TdFree.Spec

theorem shutdown_gain_disjoint : SHUTDOWN &&& GAIN_MASK = 0#u16 := by
  unfold SHUTDOWN GAIN_MASK; decide

theorem shutdown_it_disjoint : SHUTDOWN &&& IT_MASK = 0#u16 := by
  unfold SHUTDOWN IT_MASK; decide

theorem gain_it_disjoint : GAIN_MASK &&& IT_MASK = 0#u16 := by
  unfold GAIN_MASK IT_MASK; decide

theorem sd0_gain_disjoint : SD0 &&& GAIN_MASK = 0#u16 := by
  unfold SD0 GAIN_MASK; decide

end TdFree.Spec
