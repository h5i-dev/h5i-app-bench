import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result tuwunel_kernel tuwunel_kernel.Spec
open H5iAppLib hiding lit

namespace tuwunel_kernel.Solution

lemma resolve_base_event_implies_room_event
    (s : Snapshot) (u room ev : U64) (x : I64 × Usize)
    (h : api_context.resolve_base_event s room ev u false = ok (.Ok x)) :
    api_room.get_room_event_route s u room ev = ok (.Ok (Reply.RoomEvent ev)) := by
  unfold api_context.resolve_base_event at h
  h5i_invert h
  unfold api_room.get_room_event_route
  simp_all
  scalar_tac

theorem context_base_served_by_event (s : Snapshot) (u room ev lim : U64) (f : Filter)
    (base : U64) (st en : I64) (before after state : alloc.vec.Vec U64)
    (h : transition s ⟨u, .Context room ev lim f⟩ = ok (.Ok (.Context base st en before after state)))
    (hk : Keys s) :
    transition s ⟨u, .RoomEvent room ev⟩ = ok (.Ok (.RoomEvent ev)) := by
  have _ := hk
  unfold transition at h
  dsimp only at h
  unfold api_context.get_context_route api_context.event_context at h
  obtain ⟨b, hb, h⟩ := bind_tc_eq_ok.1 h
  split at h
  · obtain ⟨limit1, hlimit1, h⟩ := bind_tc_eq_ok.1 h
    obtain ⟨r, hr, h⟩ := bind_tc_eq_ok.1 h
    cases r with
    | Err e => simp only [ok.injEq, reduceCtorEq] at h
    | Ok x =>
      unfold transition
      dsimp only
      exact resolve_base_event_implies_room_event s u room ev x hr
  · simp only [ok.injEq, reduceCtorEq] at h

end tuwunel_kernel.Solution
