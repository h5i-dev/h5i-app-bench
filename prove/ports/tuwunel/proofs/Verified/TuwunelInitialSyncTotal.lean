import Verified.TuwunelTotalityComposition
open Aeneas Aeneas.Std Result tuwunel_kernel tuwunel_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP
namespace tuwunel_kernel.Verified.TuwunelTransitionTotal
set_option maxHeartbeats 4000000
set_option maxRecDepth 4096
set_option linter.unusedSimpArgs false
set_option linter.unusedVariables false
set_option allowUnsafeReducibility true
attribute [local reducible] Aeneas.Std.WP.Post

@[step] theorem api_room.room_initial_sync_route_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (limit : Option Std.U64)  :
    api_room.room_initial_sync_route s user room limit ⦃ r => True ⦄ := by
  unfold api_room.room_initial_sync_route
  run_composed_routes


end tuwunel_kernel.Verified.TuwunelTransitionTotal
