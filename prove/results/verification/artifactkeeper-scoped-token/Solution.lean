import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result artifactkeeper_kernel artifactkeeper_kernel.Spec
open H5iAppLib hiding lit

namespace artifactkeeper_kernel.Solution

set_option maxHeartbeats 3000000

h5i_derive_eq Method Method.Insts.CoreCmpPartialEqMethod.eq
h5i_derive_clone AccessScope AccessScope.Insts.CoreCloneClone.clone

@[step, h5i_spec] theorem contains_id_spec (s : Slice U64) (x : U64) :
    strs.contains_id s x ⦃ b => b = decide (x ∈ s.val) ⦄ := by
  unfold strs.contains_id strs.contains_id_loop
  h5i_search_any s.val (fun y => decide (y = x))
  rename_i hr
  rw [← hr]
  apply Bool.eq_iff_iff.mpr
  simp only [List.any_eq_true, decide_eq_true_eq]
  aesop

@[step, h5i_spec] theorem bytes_eq_spec (a b : Slice U8) :
    strs.bytes_eq a b ⦃ r => r = decide (a.val = b.val) ⦄ := by
  unfold strs.bytes_eq
  dsimp only
  split
  · rename_i h
    simp only [WP.spec_ok]
    have hn : a.val ≠ b.val := by
      intro he
      simp [Slice.len, he] at h
    simp [hn]
  · rename_i h
    have hlen : a.val.length = b.val.length := by
      scalar_tac
    unfold strs.bytes_eq_loop
    h5i_search_all (a.val.zip b.val) (fun p => decide (p.1 ≠ p.2))
    · rename_i hr
      rw [← hr]
      simpa only [u8_eq_iff] using zip_all_eq a.val b.val hlen

@[step, h5i_spec] theorem lookup_repo_loop_spec (db : tables.Db) (key : Slice U8) :
    middleware.lookup_repo_loop db key 0#usize ⦃ o =>
      o = (db.repositories.val.find? (fun r => decide (r.key.val = key.val))).map
        (fun r => (r.id, r.visibility.getD .Private)) ⦄ := by
  unfold middleware.lookup_repo_loop
  apply WP.spec_mono (loop_search db.repositories.val
    (fun r => decide (r.key.val = key.val)) id
    (fun _ r => some (r.id, r.visibility.getD .Private)) none _ ?_ 0#usize (by simp))
  · intro o ho
    simpa only [id_eq, searchFrom_find, UScalar.ofNatCore_val_eq, List.drop_zero] using ho
  · intro i hi
    unfold middleware.lookup_repo_loop.body
    h5i_step [alloc.vec.Vec.deref, Option.getD]

theorem lookup_repo_success (db : tables.Db) (key : Slice U8) (r : tables.Repository)
    (repo : U64) (vis : Visibility)
    (hf : db.repositories.val.find? (fun r => decide (r.key.val = key.val)) = some r)
    (h : middleware.lookup_repo db key = ok (some (repo, vis))) :
    repo = r.id ∧ vis = r.visibility.getD .Private := by
  unfold middleware.lookup_repo at h
  h5i_invert h
  have hh := lookup_repo_loop_spec.inv _ _ _ h
  simpa [hf] using hh

theorem can_access_repo_false (e : AuthExtension) (ids : alloc.vec.Vec U64) (repo : U64)
    (hs : e.allowed_repo_ids = .Restricted ids) (hi : repo ∉ ids.val) :
    token_scope.AuthExtension.can_access_repo e repo = ok false := by
  simp [token_scope.AuthExtension.can_access_repo, token_scope.AuthExtension.access_scope,
    hs, AccessScope.grants, contains_id_spec.eq, alloc.vec.Vec.deref, hi]

theorem public_read_success (vis : Visibility) (a : Slice U8)
    (h : paths.public_read_satisfies_acl vis a = ok true) :
    vis = .Public ∧ a.val.length = 4 := by
  cases vis <;>
    simp only [paths.public_read_satisfies_acl, Visibility.allows_anonymous_read] at h
  all_goals h5i_invert h
  have he : a.val = s.val := of_decide_eq_true (bytes_eq_spec.inv _ _ _ h).symm
  simp only [lift, ok.injEq] at hs
  subst s
  simp_all [Array.to_slice, Array.make]

theorem action_for_method_nonmutation (m : Method) (a : alloc.vec.Vec U8)
    (h : paths.action_for_method m = ok a) (hlen : a.val.length = 4) :
    ¬ isMutation m := by
  have spec : paths.action_for_method m ⦃ a => a.val.length = 4 → ¬ isMutation m ⦄ := by
    cases m <;> unfold paths.action_for_method <;> step* <;>
      simp_all [isMutation, alloc.vec.Vec.val, Array.to_slice, Array.make]
  exact post_of_ok spec h hlen

theorem next_after_if_respond {c : Prop} [Decidable c]
    {w ws : alloc.vec.Vec resolve.Write} {resp : middleware.Response}
    {m : Result ((alloc.vec.Vec resolve.Write) × middleware.Outcome)}
    {e : AuthExtension} {t : Bool}
    (h : (if c then middleware.respond w resp else m) = ok (ws, .Next (some e) t)) :
    m = ok (ws, .Next (some e) t) := by
  split at h
  · simp [middleware.respond] at h
  · exact h

theorem gated_action_nonmutation (m : Method) (b anon : Bool) (a : alloc.vec.Vec U8)
    (hb : Method.Insts.CoreCmpPartialEqMethod.eq m .Post = ok b)
    (hp : b ≠ true → anon = false)
    (ha : anon = false → paths.action_for_method m = ok a)
    (hlen : a.val.length = 4) : ¬ isMutation m := by
  by_cases hpost : b = true
  · have he := post_of_ok (Method.Insts.CoreCmpPartialEqMethod.eq.spec m .Post) hb
    have hm : m = .Post := of_decide_eq_true (hpost ▸ he.symm)
    simp [hm, isMutation]
  · exact action_for_method_nonmutation m a (ha (hp hpost)) hlen

theorem ite_success {α} {c : Prop} [Decidable c] {a b : Result α} {v : α}
    (h : (if c then a else b) = ok v) :
    (c ∧ a = ok v) ∨ (¬c ∧ b = ok v) := by
  split at h
  · exact .inl ⟨by assumption, h⟩
  · exact .inr ⟨by assumption, h⟩

-- Invert the outer bind or conditional before simplifying its branches.
-- This avoids traversing the large inlined middleware body at every step.
open Lean Elab Tactic Meta in
elab "invert_one " h:ident : tactic => withMainContext do
  let some d := (← getLCtx).findFromUserName? h.getId | throwError "missing equation"
  let some (_, lhs, _) := (← instantiateMVars d.type).consumeMData.eq?
    | throwError "not an equation"
  let lhs := lhs.consumeMData
  if lhs.isAppOfArity ``Bind.bind 6 || lhs.isAppOfArity ``Aeneas.Std.bind 4 then
    let n := match lhs.appArg!.consumeMData with
      | .lam n _ _ _ => n
      | _ => `x
    let lctx ← getLCtx
    let x := lctx.getUnusedName (if n.isAnonymous || n.hasMacroScopes then `x else n)
    let hx := lctx.getUnusedName (.mkSimple ("h" ++ x.toString))
    let thm := mkIdent (if lhs.isAppOfArity ``Aeneas.Std.bind 4
      then ``H5iAppLib.bind_eq_ok else ``H5iAppLib.bind_tc_eq_ok)
    evalTactic (← `(tactic| obtain ⟨$(mkIdent x), $(mkIdent hx), $h⟩ := ($thm).mp $h))
    replaceMainGoal [← (← getMainGoal).clear d.fvarId]
  else if lhs.isAppOfArity ``ite 5 then
    evalTactic (← `(tactic| obtain ⟨hc, $h⟩ | ⟨hc, $h⟩ := ite_success $h))
    setGoals (← (← getGoals).mapM (fun g => g.clear d.fvarId))
  else
    evalTactic (← `(tactic| first
      | (simp only [ok.injEq, Prod.mk.injEq, middleware.Outcome.Next.injEq,
          Option.some.injEq, reduceCtorEq, and_false, false_and, and_true, bind_ok,
          Bool.false_eq_true, Bool.true_eq_false, reduceIte] at $h:ident)
      | (split at $h:ident)))

macro "invert_fast " h:ident : tactic => `(tactic| repeat' (invert_one $h))

theorem scoped_token_confined (db : tables.Db) (o : trusted.Oracle) (ip : Option net.IpAddr)
    (req : http.Request) (ws : alloc.vec.Vec resolve.Write) (e : AuthExtension) (t : Bool)
    (r : tables.Repository) (ids : alloc.vec.Vec U64)
    (h : middleware.repo_visibility_middleware db o ip req = ok (ws, .Next (some e) t))
    (hs : e.allowed_repo_ids = .Restricted ids) (hr : RepoOf db req r) (hi : r.id ∉ ids.val) :
    r.visibility = some .Public ∧ ¬ isMutation req.method := by
  obtain ⟨key, hkey, hfind⟩ := hr
  unfold middleware.repo_visibility_middleware at h
  dsimp only at h
  rw [hkey] at h
  rw [bind_ok] at h
  replace h := next_after_if_respond h
  obtain ⟨found, hfound, hbody⟩ := bind_tc_eq_ok.mp h
  clear h
  have h := hbody
  clear hbody
  cases found with
  | none =>
    simp only [middleware.respond] at h
    h5i_invert h
    simp at h
  | some found =>
    obtain ⟨repo, vis⟩ := found
    have hlookup := lookup_repo_success db (alloc.vec.Vec.deref key) r repo vis
      (by simpa only [vec_deref_val] using hfind) hfound
    obtain ⟨rfl, rfl⟩ := hlookup
    dsimp only at h
    change (do
      let non_mutating_post ← paths.is_non_mutating_format_post (alloc.vec.Vec.deref req.path)
      _) = ok (ws, middleware.Outcome.Next (some e) t) at h
    simp -failIfUnchanged only [middleware.respond] at h
    h5i_invert h
    replace h := next_after_if_respond h
    h5i_invert h
    obtain ⟨writes, auth_ext1, ticket⟩ := x
    change (if credential_invalid = true then _ else _) =
      ok (ws, middleware.Outcome.Next (some e) t) at h
    obtain ⟨hc, hbody⟩ | ⟨hc, hbody⟩ := ite_success h
    all_goals clear h
    all_goals have h := hbody
    all_goals clear hbody
    all_goals try (replace h := next_after_if_respond h)
    all_goals invert_fast h
    all_goals obtain ⟨hw, he, ht⟩ := h
    all_goals subst e
    all_goals have hno := can_access_repo_false _ ids r.id hs hi
    all_goals (try simp_all only [ok.injEq, Bool.false_eq_true])
    all_goals
      have hp : r.visibility.getD .Private = .Public ∧ scope_gate_action.val.length = 4 := by
        simpa only [vec_deref_val] using
          (public_read_success (r.visibility.getD .Private)
            (alloc.vec.Vec.deref scope_gate_action) (by assumption))
      refine ⟨?_, gated_action_nonmutation req.method b anonymous_readable_post
        scope_gate_action hb ?_ ?_ hp.2⟩
      · cases hv : r.visibility <;> simp_all [Option.getD]
      · intro hbfalse
        simpa only [if_neg hbfalse, ok.injEq] using hanonymous_readable_post.symm
      · intro hanonfalse
        simpa only [hanonfalse, Bool.false_eq_true, if_false] using hscope_gate_action

end artifactkeeper_kernel.Solution
