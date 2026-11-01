import NoraKernel
import H5iAppLib
open Aeneas Aeneas.Std Result H5iAppLib nora_kernel
namespace nora_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def breaker_state_f11f5e92_as_gauge_model (v : finite_catalog.breaker_state_f11f5e92.BreakerState) : I64 :=
  match v with
  | .Closed => 0#i64
  | .Open => 1#i64
  | .HalfOpen => 2#i64
theorem breaker_state_f11f5e92_as_gauge_complete (v : finite_catalog.breaker_state_f11f5e92.BreakerState) :
    finite_catalog.breaker_state_f11f5e92.BreakerState.as_gauge v ⦃r => r = breaker_state_f11f5e92_as_gauge_model v⦄ := by
  cases v <;> simp only [breaker_state_f11f5e92_as_gauge_model]
  all_goals simp only [finite_catalog.breaker_state_f11f5e92.BreakerState.as_gauge, finite_catalog.breaker_state_f11f5e92.BreakerState.as_health_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end nora_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib nora_kernel
namespace nora_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def breaker_state_f11f5e92_as_health_str_model (v : finite_catalog.breaker_state_f11f5e92.BreakerState) : List U8 :=
  match v with
  | .Closed => [99#u8, 108#u8, 111#u8, 115#u8, 101#u8, 100#u8]
  | .Open => [111#u8, 112#u8, 101#u8, 110#u8]
  | .HalfOpen => [104#u8, 97#u8, 108#u8, 102#u8, 95#u8, 111#u8, 112#u8, 101#u8, 110#u8]
theorem breaker_state_f11f5e92_as_health_str_complete (v : finite_catalog.breaker_state_f11f5e92.BreakerState) :
    finite_catalog.breaker_state_f11f5e92.BreakerState.as_health_str v ⦃r => r.val = breaker_state_f11f5e92_as_health_str_model v⦄ := by
  cases v <;> simp only [breaker_state_f11f5e92_as_health_str_model]
  all_goals simp only [finite_catalog.breaker_state_f11f5e92.BreakerState.as_gauge, finite_catalog.breaker_state_f11f5e92.BreakerState.as_health_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end nora_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib nora_kernel
namespace nora_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def role_a890c86c_can_write_model (v : finite_catalog.role_a890c86c.Role) : Bool :=
  match v with
  | .Read => false
  | .Write => true
  | .Admin => true
theorem role_a890c86c_can_write_complete (v : finite_catalog.role_a890c86c.Role) :
    finite_catalog.role_a890c86c.Role.can_write v ⦃r => r = role_a890c86c_can_write_model v⦄ := by
  cases v <;> simp only [role_a890c86c_can_write_model]
  all_goals simp only [finite_catalog.role_a890c86c.Role.can_write, finite_catalog.role_a890c86c.Role.can_admin]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end nora_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib nora_kernel
namespace nora_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def role_a890c86c_can_admin_model (v : finite_catalog.role_a890c86c.Role) : Bool :=
  match v with
  | .Read => false
  | .Write => false
  | .Admin => true
theorem role_a890c86c_can_admin_complete (v : finite_catalog.role_a890c86c.Role) :
    finite_catalog.role_a890c86c.Role.can_admin v ⦃r => r = role_a890c86c_can_admin_model v⦄ := by
  cases v <;> simp only [role_a890c86c_can_admin_model]
  all_goals simp only [finite_catalog.role_a890c86c.Role.can_write, finite_catalog.role_a890c86c.Role.can_admin]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end nora_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib nora_kernel
namespace nora_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def lang_986f59b4_code_model (v : finite_catalog.lang_986f59b4.Lang) : List U8 :=
  match v with
  | .En => [101#u8, 110#u8]
  | .Ru => [114#u8, 117#u8]
  | .Zh => [122#u8, 104#u8]
theorem lang_986f59b4_code_complete (v : finite_catalog.lang_986f59b4.Lang) :
    finite_catalog.lang_986f59b4.Lang.code v ⦃r => r.val = lang_986f59b4_code_model v⦄ := by
  cases v <;> simp only [lang_986f59b4_code_model]
  all_goals simp only [finite_catalog.lang_986f59b4.Lang.code]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end nora_kernel.Verified.FiniteCatalog
