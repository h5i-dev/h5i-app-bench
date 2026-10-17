import Storage
/-!
# Read-only commands write nothing

The server declares `read_only` commands read-only (`Kernel::read_only`), so
`h5i-app-pg` runs them in a `SERIALIZABLE READ ONLY DEFERRABLE` transaction
without locks. `read_only_sound` is the obligation that makes this sound: for
every actor and state, an accepted read-only command returns no writes.

Each read-only command builds its reply after the lookups it needs and
returns it with `Vec::new()`; the proofs follow the binds of the extracted
code to that return, whatever the lookups computed.
-/
open Aeneas Aeneas.Std Result linkding_kernel H5iAppLib

namespace linkding_kernel.ReadOnly

set_option hygiene false in
/-- Follow `h : prog = ok (.Ok (ws, r))` through binds and branches to the
returns, each of which writes nothing. -/
macro "ws_nil" : tactic => `(tactic| (
  repeat (first
    | (simp only [bind_tc_eq_ok] at h; obtain ⟨_, _, h⟩ := h)
    | (split at h));
  all_goals (simp at h)
  all_goals (try casesm* Exists _, _ ∧ _)
  all_goals (subst_vars; rfl)))

theorem profile_ws (s : Snapshot) t ws r (h : profile s t = ok (.Ok (ws, r))) : ws.val = [] := by
  unfold profile at h; ws_nil

set_option maxHeartbeats 4000000 in
theorem list_ws (s : Snapshot) t f l o ws r (h : list s t f l o = ok (.Ok (ws, r))) : ws.val = [] := by
  unfold list at h; ws_nil

theorem check_ws (s : Snapshot) t u n ws r (h : check s t u n = ok (.Ok (ws, r))) : ws.val = [] := by
  unfold check at h; ws_nil

theorem get_bookmark_ws (s : Snapshot) t i ws r (h : get_bookmark s t i = ok (.Ok (ws, r))) : ws.val = [] := by
  unfold get_bookmark at h; ws_nil

theorem list_tags_ws (s : Snapshot) t l o ws r (h : list_tags s t l o = ok (.Ok (ws, r))) : ws.val = [] := by
  unfold list_tags at h; ws_nil

theorem get_tag_ws (s : Snapshot) t i ws r (h : get_tag s t i = ok (.Ok (ws, r))) : ws.val = [] := by
  unfold get_tag at h; ws_nil

theorem list_bundles_ws (s : Snapshot) t l o ws r (h : list_bundles s t l o = ok (.Ok (ws, r))) : ws.val = [] := by
  unfold list_bundles at h; ws_nil

theorem get_bundle_ws (s : Snapshot) t i ws r (h : get_bundle s t i = ok (.Ok (ws, r))) : ws.val = [] := by
  unfold get_bundle at h; ws_nil

/-- The obligation of `Kernel::read_only`, for the kernel the server runs. -/
theorem read_only_sound : H5iAppLib.ReadOnly.Sound read_only transition (fun ws => ws.val) := by
  intro a s c ws r hro h
  cases c <;> simp only [read_only, ok.injEq, Bool.false_eq_true] at hro <;> simp only [transition] at h
  · exact profile_ws _ _ _ _ h
  · exact list_ws _ _ _ _ _ _ _ h
  · exact check_ws _ _ _ _ _ _ h
  · exact get_bookmark_ws _ _ _ _ _ h
  · exact list_tags_ws _ _ _ _ _ _ h
  · exact get_tag_ws _ _ _ _ _ h
  · exact list_bundles_ws _ _ _ _ _ _ h
  · exact get_bundle_ws _ _ _ _ _ h

end linkding_kernel.ReadOnly
