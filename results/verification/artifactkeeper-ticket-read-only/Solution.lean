import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit

namespace artifactkeeper_kernel.Solution

set_option maxHeartbeats 4000000
set_option maxRecDepth 4096

def TicketSafe (req : http.Request) (auth : Option AuthExtension) (ticket : Bool) : Prop :=
  ticket = true → (req.method = .Get ∨ req.method = .Head) ∧
    ∃ e, auth = some e ∧ e.is_admin = false ∧ e.scopes.map (·.val) = some []

theorem resolved_ticket_read_only (db : tables.Db) (writes ws : alloc.vec.Vec resolve.Write)
    (ticket : Slice U8) (method : Method) (path : Slice U8) (e : AuthExtension)
    (h : resolve.try_resolve_ticket_auth db writes ticket method path = ok (some e, ws)) :
    (method = .Get ∨ method = .Head) ∧
    e.is_admin = false ∧ e.scopes.map (·.val) = some [] := by
  unfold resolve.try_resolve_ticket_auth at h
  h5i_invert h
  · rcases x with ⟨_ | ⟨user, bound_path⟩, ws'⟩
    · change ok (none, ws') = ok (some e, ws) at h
      simp at h
    · change Std.bind (paths.ticket_path_allowed bound_path path) _ = ok (some e, ws) at h
      h5i_invert h
      all_goals try simp at h
      have hm : method = .Get ∨ method = .Head := by
        cases method <;> simp_all [paths.ticket_method_allowed]
      have he := h.1
      subst e
      exact ⟨hm, rfl, rfl⟩
  · simp at h

theorem try_ticket_read_only (db : tables.Db) (writes ws : alloc.vec.Vec resolve.Write)
    (req : http.Request) (e : AuthExtension)
    (h : resolve.try_ticket db writes req = ok (some e, ws)) :
    (req.method = .Get ∨ req.method = .Head) ∧
    e.is_admin = false ∧ e.scopes.map (·.val) = some [] := by
  unfold resolve.try_ticket at h
  h5i_invert h
  · simp at h
  · exact resolved_ticket_read_only db writes ws _ req.method _ e h

def select_ticket (db : tables.Db) (req : http.Request) (auth : Option AuthExtension) :
    Result (alloc.vec.Vec resolve.Write × Option AuthExtension × Bool) := do
  if core.option.Option.is_none auth then
    let (a, ws) ← resolve.try_ticket db (alloc.vec.Vec.new resolve.Write) req
    let (a', ticket) ← match a with
      | none => ok (auth, false)
      | some _ => ok (a, true)
    ok (ws, a', ticket)
  else ok (alloc.vec.Vec.new resolve.Write, auth, false)

theorem select_ticket_safe (db : tables.Db) (req : http.Request) (auth : Option AuthExtension)
    (x : alloc.vec.Vec resolve.Write × Option AuthExtension × Bool)
    (h : select_ticket db req auth = ok x) : TicketSafe req x.2.1 x.2.2 := by
  cases auth with
  | some e =>
    change ok (alloc.vec.Vec.new resolve.Write, some e, false) = ok x at h
    have he := Result.ok.inj h
    subst x
    simp [TicketSafe]
  | none =>
    unfold select_ticket at h
    rw [if_pos (show core.option.Option.is_none (none : Option AuthExtension) = true from rfl)] at h
    obtain ⟨⟨a, writes⟩, ha, h⟩ := bind_eq_ok.1 h
    cases a with
    | none =>
      change Std.bind (ok (none, false)) _ = ok x at h
      rw [bind_ok] at h
      change ok (writes, none, false) = ok x at h
      have he := Result.ok.inj h
      subst x
      simp [TicketSafe]
    | some e =>
      change Std.bind (ok (some e, true)) _ = ok x at h
      rw [bind_ok] at h
      change ok (writes, some e, true) = ok x at h
      have he := Result.ok.inj h
      subst x
      intro _
      obtain ⟨hm, hadmin, hscopes⟩ := try_ticket_read_only db _ writes req e ha
      exact ⟨hm, e, rfl, hadmin, hscopes⟩

theorem ticket_read_only (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (auth : Option AuthExtension)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, .Next auth true)) :
    (req.method = .Get ∨ req.method = .Head) ∧
    ∃ e, auth = some e ∧ e.is_admin = false ∧ e.scopes.map (·.val) = some [] := by
  unfold middleware.repo_visibility_middleware at h
  apply bind_eq_ok.1 at h
  rcases h with ⟨repo_key, hrepo_key, h⟩
  change (if repo_key.len = 0#usize then _ else _) = _ at h
  by_cases hk : repo_key.len = 0#usize
  · rw [if_pos hk] at h
    simp [middleware.respond] at h
  · rw [if_neg hk] at h
    h5i_invert h
    · simp [middleware.respond] at h
    · rcases r with ⟨repo_id, visibility⟩
      change Std.bind (paths.is_non_mutating_format_post req.path.deref) _ = _ at h
      h5i_invert h
      cases outcome <;> simp only [Result.ok.injEq] at hb2 <;> subst b2
      all_goals h5i_invert h
      all_goals try simp [middleware.respond] at h
      all_goals have hs := select_ticket_safe db req _ x hx
      all_goals rcases x with ⟨writes, auth1, ticket⟩
      all_goals cases auth1
      all_goals simp only [uncurry_apply_pair] at h
      all_goals h5i_invert h
      all_goals simp only [middleware.Outcome.Next.injEq, and_false] at h
      all_goals exact h.2.1 ▸ hs h.2.2

end artifactkeeper_kernel.Solution
