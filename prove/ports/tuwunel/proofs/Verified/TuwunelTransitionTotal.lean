import Verified.TuwunelInitialSyncTotal
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

@[step] theorem api_relations.paginate_relations_with_filter_total (s : Snapshot) (user : Std.U64) (room : Std.U64) (target : Std.U64) (filter_event_type : Option Kind) (filter_rel_type : Option RelType) («from» : Token) («to» : Token) (limit : Option Std.U64) (recurse : Bool) (dir : Dir) (hr : (s.relations.length + 1)^4 < Usize.max) :
    api_relations.paginate_relations_with_filter s user room target filter_event_type filter_rel_type «from» «to» limit recurse dir ⦃ r => True ⦄ := by
  unfold api_relations.paginate_relations_with_filter
  run_composed_routes
  all_goals simp_all [Nat.succ_le_iff, List.length_pos_iff]

theorem transition_total (s : Snapshot) (req : Request) (hr : (s.relations.length + 1) ^ 4 < Usize.max) :
    ∃ r, transition s req = ok r := by
  apply ok_of (P := fun _ => True)
  unfold transition
  run_composed_routes


end tuwunel_kernel.Verified.TuwunelTransitionTotal
