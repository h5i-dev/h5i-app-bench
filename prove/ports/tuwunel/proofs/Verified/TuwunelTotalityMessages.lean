import Verified.TuwunelTotalityVisibility
open Aeneas Aeneas.Std Result tuwunel_kernel tuwunel_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP
namespace tuwunel_kernel.Verified.TuwunelTransitionTotal
set_option maxHeartbeats 2000000
set_option maxRecDepth 4096
set_option linter.unusedSimpArgs false
set_option linter.unusedVariables false
set_option allowUnsafeReducibility true
attribute [local reducible] Aeneas.Std.WP.Post

@[step] theorem api_message.get_messages_total (s : Snapshot) (user : Std.U64) (room : Std.U64) («from» : Token) («to» : Token) (dir : Dir) (limit : Option Std.U64) (filter : Filter) (bypass_visibility : Bool)  :
    api_message.get_messages s user room «from» «to» dir limit filter bypass_visibility ⦃ r => True ⦄ := by
  unfold api_message.get_messages
  run
  all_goals norm_num [api_message.LIMIT_DEFAULT, api_message.LIMIT_MAX]

@[step] theorem api_message.get_message_events_route_total (s : Snapshot) (user : Std.U64) (room : Std.U64) («from» : Token) («to» : Token) (dir : Dir) (limit : Std.U64) (filter : Filter)  :
    api_message.get_message_events_route s user room «from» «to» dir limit filter ⦃ r => True ⦄ := by
  unfold api_message.get_message_events_route
  run

@[step] theorem api_relations.keep_total (s : Snapshot) (user : Std.U64) (p : Pdu) (filter_event_type : Option Kind) (filter_rel_type : Option RelType)  :
    api_relations.keep s user p filter_event_type filter_rel_type ⦃ r => True ⦄ := by
  unfold api_relations.keep
  run

@[step] theorem api_relations.fetch_loop_total (bound : Nat) (rels : alloc.vec.Vec (Std.I64 × Std.Usize)) (out : alloc.vec.Vec (Std.I64 × Std.Usize)) (i : Std.Usize) (h_rels : Good (bound) rels) (h_out : Good (bound) out) (hsize : out.length ≤ i.val) (hi : i.val ≤ rels.length) :
    api_relations.fetch_loop rels out i ⦃ r => Good (bound) r ∧ r.length ≤ rels.length ⦄ := by
  unfold api_relations.fetch_loop
  apply loop_idx_spec _ (fun x => x.2) (rels.length) (fun x => x.1.length ≤ (x.2).val ∧ Good (bound) x.1) _ ?_ _ ?_ hi
  · intro x hin hx
    rcases x with ⟨out, i⟩
    try dsimp only at hin hx
    try simp only [Good, Indexed.valid] at hin
    unfold api_relations.fetch_loop.body
    run
  all_goals clean

@[step] theorem api_relations.fetch_total (s : Snapshot) (shortroomid : Std.U64) (count : Std.I64) («from» : Option Std.I64) (dir : Dir)  :
    api_relations.fetch s shortroomid count «from» dir ⦃ r => Good (s.pdus.length) r ∧ r.length ≤ s.relations.length ⦄ := by
  unfold api_relations.fetch
  run

end tuwunel_kernel.Verified.TuwunelTransitionTotal
