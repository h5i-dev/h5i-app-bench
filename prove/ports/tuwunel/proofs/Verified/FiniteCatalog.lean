import TuwunelKernel
import H5iAppLib
open Aeneas Aeneas.Std Result H5iAppLib tuwunel_kernel
namespace tuwunel_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def field_bea9b175_label_model (v : finite_catalog.field_bea9b175.Field) : List U8 :=
  match v with
  | .Name => [110#u8, 97#u8, 109#u8, 101#u8]
  | .Version => [118#u8, 101#u8, 114#u8, 115#u8, 105#u8, 111#u8, 110#u8]
  | .Compiler => [99#u8, 111#u8, 109#u8, 112#u8, 105#u8, 108#u8, 101#u8, 114#u8]
theorem field_bea9b175_label_complete (v : finite_catalog.field_bea9b175.Field) :
    finite_catalog.field_bea9b175.Field.label v ⦃r => r.val = field_bea9b175_label_model v⦄ := by
  cases v <;> simp only [field_bea9b175_label_model]
  all_goals simp only [finite_catalog.field_bea9b175.Field.label]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end tuwunel_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib tuwunel_kernel
namespace tuwunel_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def state_after_c4e3af58_requested_model (v : finite_catalog.state_after_c4e3af58.StateAfter) : Bool :=
  match v with
  | .Off => false
  | .Stable => true
  | .Unstable => true
theorem state_after_c4e3af58_requested_complete (v : finite_catalog.state_after_c4e3af58.StateAfter) :
    finite_catalog.state_after_c4e3af58.StateAfter.requested v ⦃r => r = state_after_c4e3af58_requested_model v⦄ := by
  cases v <;> simp only [state_after_c4e3af58_requested_model]
  all_goals simp only [finite_catalog.state_after_c4e3af58.StateAfter.requested]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end tuwunel_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib tuwunel_kernel
namespace tuwunel_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def fallback_08cb57a8_name_model (v : finite_catalog.fallback_08cb57a8.Fallback) : List U8 :=
  match v with
  | .Absent => [97#u8, 98#u8, 115#u8, 101#u8, 110#u8, 116#u8]
  | .Ceiling => [99#u8, 101#u8, 105#u8, 108#u8, 105#u8, 110#u8, 103#u8]
  | .AuthMissing => [97#u8, 117#u8, 116#u8, 104#u8, 95#u8, 109#u8, 105#u8, 115#u8, 115#u8, 105#u8, 110#u8, 103#u8]
  | .AllCommitted => [97#u8, 108#u8, 108#u8, 95#u8, 99#u8, 111#u8, 109#u8, 109#u8, 105#u8, 116#u8, 116#u8, 101#u8, 100#u8]
  | .Entries => [101#u8, 110#u8, 116#u8, 114#u8, 105#u8, 101#u8, 115#u8]
  | .Canary => [99#u8, 97#u8, 110#u8, 97#u8, 114#u8, 121#u8]
  | .CreateMismatch => [99#u8, 114#u8, 101#u8, 97#u8, 116#u8, 101#u8, 95#u8, 109#u8, 105#u8, 115#u8, 109#u8, 97#u8, 116#u8, 99#u8, 104#u8]
  | .Unevaluable => [117#u8, 110#u8, 101#u8, 118#u8, 97#u8, 108#u8, 117#u8, 97#u8, 98#u8, 108#u8, 101#u8]
  | .Error => [101#u8, 114#u8, 114#u8, 111#u8, 114#u8]
theorem fallback_08cb57a8_name_complete (v : finite_catalog.fallback_08cb57a8.Fallback) :
    finite_catalog.fallback_08cb57a8.Fallback.name v ⦃r => r.val = fallback_08cb57a8_name_model v⦄ := by
  cases v <;> simp only [fallback_08cb57a8_name_model]
  all_goals simp only [finite_catalog.fallback_08cb57a8.Fallback.name]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end tuwunel_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib tuwunel_kernel
namespace tuwunel_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def room_power_levels_int_field_b809be58_as_str_model (v : finite_catalog.room_power_levels_int_field_b809be58.RoomPowerLevelsIntField) : List U8 :=
  match v with
  | .UsersDefault => [117#u8, 115#u8, 101#u8, 114#u8, 115#u8, 95#u8, 100#u8, 101#u8, 102#u8, 97#u8, 117#u8, 108#u8, 116#u8]
  | .EventsDefault => [101#u8, 118#u8, 101#u8, 110#u8, 116#u8, 115#u8, 95#u8, 100#u8, 101#u8, 102#u8, 97#u8, 117#u8, 108#u8, 116#u8]
  | .StateDefault => [115#u8, 116#u8, 97#u8, 116#u8, 101#u8, 95#u8, 100#u8, 101#u8, 102#u8, 97#u8, 117#u8, 108#u8, 116#u8]
  | .Ban => [98#u8, 97#u8, 110#u8]
  | .Redact => [114#u8, 101#u8, 100#u8, 97#u8, 99#u8, 116#u8]
  | .Kick => [107#u8, 105#u8, 99#u8, 107#u8]
  | .Invite => [105#u8, 110#u8, 118#u8, 105#u8, 116#u8, 101#u8]
theorem room_power_levels_int_field_b809be58_as_str_complete (v : finite_catalog.room_power_levels_int_field_b809be58.RoomPowerLevelsIntField) :
    finite_catalog.room_power_levels_int_field_b809be58.RoomPowerLevelsIntField.as_str v ⦃r => r.val = room_power_levels_int_field_b809be58_as_str_model v⦄ := by
  cases v <;> simp only [room_power_levels_int_field_b809be58_as_str_model]
  all_goals simp only [finite_catalog.room_power_levels_int_field_b809be58.RoomPowerLevelsIntField.as_str, finite_catalog.room_power_levels_int_field_b809be58.RoomPowerLevelsIntField.as_ref]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end tuwunel_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib tuwunel_kernel
namespace tuwunel_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def room_power_levels_int_field_b809be58_as_ref_model (v : finite_catalog.room_power_levels_int_field_b809be58.RoomPowerLevelsIntField) : List U8 :=
  match v with
  | .UsersDefault => [117#u8, 115#u8, 101#u8, 114#u8, 115#u8, 95#u8, 100#u8, 101#u8, 102#u8, 97#u8, 117#u8, 108#u8, 116#u8]
  | .EventsDefault => [101#u8, 118#u8, 101#u8, 110#u8, 116#u8, 115#u8, 95#u8, 100#u8, 101#u8, 102#u8, 97#u8, 117#u8, 108#u8, 116#u8]
  | .StateDefault => [115#u8, 116#u8, 97#u8, 116#u8, 101#u8, 95#u8, 100#u8, 101#u8, 102#u8, 97#u8, 117#u8, 108#u8, 116#u8]
  | .Ban => [98#u8, 97#u8, 110#u8]
  | .Redact => [114#u8, 101#u8, 100#u8, 97#u8, 99#u8, 116#u8]
  | .Kick => [107#u8, 105#u8, 99#u8, 107#u8]
  | .Invite => [105#u8, 110#u8, 118#u8, 105#u8, 116#u8, 101#u8]
theorem room_power_levels_int_field_b809be58_as_ref_complete (v : finite_catalog.room_power_levels_int_field_b809be58.RoomPowerLevelsIntField) :
    finite_catalog.room_power_levels_int_field_b809be58.RoomPowerLevelsIntField.as_ref v ⦃r => r.val = room_power_levels_int_field_b809be58_as_ref_model v⦄ := by
  cases v <;> simp only [room_power_levels_int_field_b809be58_as_ref_model]
  all_goals simp only [finite_catalog.room_power_levels_int_field_b809be58.RoomPowerLevelsIntField.as_str, finite_catalog.room_power_levels_int_field_b809be58.RoomPowerLevelsIntField.as_ref]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end tuwunel_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib tuwunel_kernel
namespace tuwunel_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def status_4004009f_is_terminal_model (v : finite_catalog.status_4004009f.Status) : Bool :=
  match v with
  | .Scheduled => false
  | .Active => false
  | .Complete => true
  | .Failed => true
theorem status_4004009f_is_terminal_complete (v : finite_catalog.status_4004009f.Status) :
    finite_catalog.status_4004009f.Status.is_terminal v ⦃r => r = status_4004009f_is_terminal_model v⦄ := by
  cases v <;> simp only [status_4004009f_is_terminal_model]
  all_goals simp only [finite_catalog.status_4004009f.Status.is_terminal, finite_catalog.status_4004009f.Status.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end tuwunel_kernel.Verified.FiniteCatalog
open Aeneas Aeneas.Std Result H5iAppLib tuwunel_kernel
namespace tuwunel_kernel.Verified.FiniteCatalog
set_option maxRecDepth 16384
set_option maxHeartbeats 12000000
def status_4004009f_as_str_model (v : finite_catalog.status_4004009f.Status) : List U8 :=
  match v with
  | .Scheduled => [115#u8, 99#u8, 104#u8, 101#u8, 100#u8, 117#u8, 108#u8, 101#u8, 100#u8]
  | .Active => [97#u8, 99#u8, 116#u8, 105#u8, 118#u8, 101#u8]
  | .Complete => [99#u8, 111#u8, 109#u8, 112#u8, 108#u8, 101#u8, 116#u8, 101#u8]
  | .Failed => [102#u8, 97#u8, 105#u8, 108#u8, 101#u8, 100#u8]
theorem status_4004009f_as_str_complete (v : finite_catalog.status_4004009f.Status) :
    finite_catalog.status_4004009f.Status.as_str v ⦃r => r.val = status_4004009f_as_str_model v⦄ := by
  cases v <;> simp only [status_4004009f_as_str_model]
  all_goals simp only [finite_catalog.status_4004009f.Status.is_terminal, finite_catalog.status_4004009f.Status.as_str]
  all_goals h5i_steps
  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]
  all_goals scalar_tac
end tuwunel_kernel.Verified.FiniteCatalog
