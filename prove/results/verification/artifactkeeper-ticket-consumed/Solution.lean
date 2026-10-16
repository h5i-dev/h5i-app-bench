import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit

namespace artifactkeeper_kernel.Solution

set_option maxHeartbeats 2000000
set_option maxRecDepth 4096

open Lean Elab Tactic Meta in
elab "split_product" : tactic => withMainContext do
  for d in ← getLCtx do
    if d.isImplementationDetail then continue
    if (← whnf d.type).isAppOfArity ``Prod 2 then
      evalTactic (← `(tactic| cases $(mkIdent d.userName):ident))
      return
  throwError "No product to split"

open Lean Elab Tactic Meta in
elab "split_head_if " h:ident : tactic => withMainContext do
  let some d := (← getLCtx).findFromUserName? h.getId | throwError "Missing equation"
  let some (_, lhs, _) := d.type.eq? | throwError "Not an equation"
  unless lhs.isAppOfArity ``ite 5 do throwError "Not a conditional"
  let c ← Term.exprToSyntax lhs.getAppArgs[1]!
  let hc := mkIdent ((← getLCtx).getUnusedName `hcond)
  evalTactic (← `(tactic| by_cases $hc:ident : $c))
  evalTactic (← `(tactic| all_goals first
    | rw [if_pos $hc:ident] at $h:ident
    | rw [if_neg $hc:ident] at $h:ident))

theorem bytes_eq_true (a b : Slice U8) (h : strs.bytes_eq a b = ok true) :
    a.val = b.val := by
  unfold strs.bytes_eq at h
  h5i_invert h
  have hlen : a.val.length = b.val.length := by scalar_tac
  unfold strs.bytes_eq_loop at h
  apply loop_idx_ok (fun i => strs.bytes_eq_loop.body a b i) id a.val.length
    (fun i => ∀ j, j < i.val → a.val[j]? = b.val[j]?)
    (fun r => r = true → a.val = b.val) ?_ 0#usize true
    (by simp) (by simp) h rfl
  intro i r hi hn hr
  unfold strs.bytes_eq_loop.body at hr
  h5i_invert hr
  all_goals try simp
  · have heq : i2 = i3 := by scalar_tac
    have hv := add_ok_val hi4
    refine ⟨?_, by scalar_tac, by scalar_tac⟩
    intro j hj
    by_cases hjold : j < i.val
    · exact hi j hjold
    · have hji : j = i.val := by scalar_tac
      subst j
      obtain ⟨ha, hea⟩ := slice_index_ok hi2
      obtain ⟨hb, heb⟩ := slice_index_ok hi3
      rw [List.getElem?_eq_getElem ha, List.getElem?_eq_getElem hb, hea, heb, heq]
  · apply List.ext_getElem hlen
    intro j hja hjb
    have hj : j < i.val := by scalar_tac
    have hp := hi j hj
    rw [List.getElem?_eq_getElem hja, List.getElem?_eq_getElem hjb] at hp
    exact Option.some.inj hp

def LiveTicket (db : tables.Db) (tk : alloc.vec.Vec U8) : Prop :=
  ∃ x ∈ db.tickets.val, x.ticket = tk ∧ x.live = true

theorem validate_ticket_writes (db : tables.Db) (writes ws : alloc.vec.Vec resolve.Write)
    (ticket : Slice U8) (res : Option (U64 × Option (alloc.vec.Vec U8)))
    (h : resolve.validate_download_ticket db writes ticket = ok (res, ws)) :
    ∀ tk, resolve.Write.DeleteTicket tk ∈ ws.val →
      resolve.Write.DeleteTicket tk ∈ writes.val ∨ LiveTicket db tk := by
  unfold resolve.validate_download_ticket at h
  h5i_invert h
  · rcases h with ⟨rfl, rfl⟩
    intro tk hw
    exact Or.inl hw
  · unfold resolve.validate_download_ticket_loop at h
    apply loop_idx_ok (fun i => resolve.validate_download_ticket_loop.body db writes ticket i)
      id db.tickets.val.length (fun _ => True)
      (fun r => ∀ tk, resolve.Write.DeleteTicket tk ∈ r.2.val →
        resolve.Write.DeleteTicket tk ∈ writes.val ∨ LiveTicket db tk)
      ?_ 0#usize (res, ws) trivial (by simp) h
    intro i r _ hn hr
    unfold resolve.validate_download_ticket_loop.body at hr
    h5i_invert hr
    · simp only
      have htmem := vec_index_slice_ok_mem ht
      have heq := bytes_eq_true _ _ (hc_2 ▸ hb_1)
      have hcopy := post_of_ok (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 ticket
        (fun _ _ => rfl)) hv
      have hpush : writes1.val = writes.val ++ [resolve.Write.DeleteTicket v] := by
        unfold alloc.vec.Vec.push at hwrites1
        dsimp only at hwrites1
        split at hwrites1
        · have he := result_ok_inj hwrites1
          rw [← he]
          simp
        · simp at hwrites1
      intro tk hw
      rw [hpush] at hw
      simp only [List.mem_append, List.mem_singleton] at hw
      rcases hw with hw | hw
      · exact Or.inl hw
      · have htk : tk = v := by cases hw; rfl
        subst tk
        right
        refine ⟨t, htmem, ?_, hc_3⟩
        apply (alloc.vec.Vec.eq_iff _ _).2
        have hcval := congrArg Slice.val hcopy
        change ticket.val = v.val at hcval
        simpa only [alloc.vec.Vec.deref, Slice.from_val] using heq.trans hcval
    · simp only [id_eq]
      have hv := add_ok_val hi2
      exact ⟨trivial, by scalar_tac, by scalar_tac⟩
    · simp only [id_eq]
      have hv := add_ok_val hi2
      exact ⟨trivial, by scalar_tac, by scalar_tac⟩
    · simp only
      intro tk hw
      exact Or.inl hw

def ReadTicket (db : tables.Db) (m : Method) (tk : alloc.vec.Vec U8) : Prop :=
  (m = .Get ∨ m = .Head) ∧ LiveTicket db tk

theorem resolve_ticket_writes (db : tables.Db) (writes ws : alloc.vec.Vec resolve.Write)
    (ticket path : Slice U8) (m : Method) (ext : Option AuthExtension)
    (h : resolve.try_resolve_ticket_auth db writes ticket m path = ok (ext, ws)) :
    ∀ tk, resolve.Write.DeleteTicket tk ∈ ws.val →
      resolve.Write.DeleteTicket tk ∈ writes.val ∨ ReadTicket db m tk := by
  unfold resolve.try_resolve_ticket_auth at h
  h5i_invert h
  · have hm : m = .Get ∨ m = .Head := by
      rw [hc] at hb
      cases m <;> simp [paths.ticket_method_allowed] at hb ⊢
    obtain ⟨res, writes1⟩ := x
    have hv := validate_ticket_writes db writes writes1 ticket res hx
    cases res
    all_goals try (rename_i r; rcases r with ⟨user_id, resource_path⟩)
    all_goals simp -failIfUnchanged only [Aeneas.Std.uncurry, Result.ok.injEq, Prod.mk.injEq] at h
    all_goals h5i_invert h
    all_goals rcases h with ⟨_, rfl⟩
    all_goals
      intro tk hw
      rcases hv tk hw with hw | hw
      · exact Or.inl hw
      · exact Or.inr ⟨hm, hw⟩
  · rcases h with ⟨_, rfl⟩
    intro tk hw
    exact Or.inl hw

theorem try_ticket_writes (db : tables.Db) (writes ws : alloc.vec.Vec resolve.Write)
    (req : http.Request) (ext : Option AuthExtension)
    (h : resolve.try_ticket db writes req = ok (ext, ws)) :
    ∀ tk, resolve.Write.DeleteTicket tk ∈ ws.val →
      resolve.Write.DeleteTicket tk ∈ writes.val ∨ ReadTicket db req.method tk := by
  unfold resolve.try_ticket at h
  h5i_invert h
  · rcases h with ⟨_, rfl⟩
    intro tk hw
    exact Or.inl hw
  · exact resolve_ticket_writes db writes ws _ _ req.method ext h

def ticketChoice (db : tables.Db) (req : http.Request) (auth : Option AuthExtension) :
    Result (alloc.vec.Vec resolve.Write × Option AuthExtension × Bool) :=
  if core.option.Option.is_none auth then do
    let (o1, writes1) ← resolve.try_ticket db (alloc.vec.Vec.new resolve.Write) req
    let (o2, b4) ← match o1 with
      | none => ok (auth, false)
      | some _ => ok (o1, true)
    ok (writes1, o2, b4)
  else ok (alloc.vec.Vec.new resolve.Write, auth, false)

theorem ticketChoice_writes (db : tables.Db) (req : http.Request) (auth ext : Option AuthExtension)
    (ws : alloc.vec.Vec resolve.Write) (via : Bool)
    (h : ticketChoice db req auth = ok (ws, ext, via)) :
    ∀ tk, resolve.Write.DeleteTicket tk ∈ ws.val → ReadTicket db req.method tk := by
  unfold ticketChoice at h
  h5i_invert h
  · obtain ⟨ext1, ws1⟩ := x
    simp only [Aeneas.Std.uncurry] at h
    h5i_invert h
    obtain ⟨ext2, via2⟩ := x
    simp only [Aeneas.Std.uncurry, Result.ok.injEq, Prod.mk.injEq] at h
    rcases h with ⟨rfl, _, _⟩
    intro tk hw
    have ht := try_ticket_writes db (alloc.vec.Vec.new resolve.Write) ws1 req ext1 hx tk hw
    simpa only [vec_new_val, List.not_mem_nil, false_or] using ht
  · rcases h with ⟨rfl, _, _⟩
    intro tk hw
    simp only [vec_new_val, List.not_mem_nil] at hw

theorem ticket_consumed_on_read (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (out : middleware.Outcome)
    (tk : alloc.vec.Vec U8)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, out))
    (hw : resolve.Write.DeleteTicket tk ∈ ws.val) :
    (req.method = .Get ∨ req.method = .Head) ∧ ∃ x ∈ db.tickets.val, x.ticket = tk ∧ x.live = true := by
  unfold middleware.repo_visibility_middleware middleware.respond at h
  all_goals repeat' (first
    | (fail_if_no_progress h5i_invert h)
    | split_head_if h
    | (split_product; simp -failIfUnchanged (config := { maxSteps := 1000000 }) only
        [Aeneas.Std.uncurry] at h))
  all_goals try (rcases h with ⟨rfl, rfl⟩)
  all_goals try (simp only [vec_new_val, List.not_mem_nil] at hw)
  all_goals exact ticketChoice_writes db req _ _ _ _ hx tk hw

end artifactkeeper_kernel.Solution
