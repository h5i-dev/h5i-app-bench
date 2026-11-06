import Verified.Authn
/-!
# The Trusted Publishing token exchange (`handle_github_token_inner`)
-/
open Aeneas Aeneas.Std Result cratesio_kernel cratesio_kernel.Spec
open H5iAppLib hiding Covers
open Aeneas.Std.WP
open cratesio_kernel.Verified.Bytes cratesio_kernel.Verified.Scopes cratesio_kernel.Verified.Authn

namespace cratesio_kernel.Verified.Exchange
set_option maxHeartbeats 2000000

@[step] theorem lower_spec (b : U8) : bytes.lower b ⦃ r => r.val = lowerN b.val ⦄ := by
  unfold bytes.lower
  split_ifs <;> step* <;> simp_all [lowerN]

theorem eq_lower_loop_spec (a b : Slice U8) (i : Usize)
    (hlen : a.length = b.length) (hi : i.val ≤ a.length) :
    trustpub.eq_lower_loop a b i ⦃ r => r = decide ((a.val.drop i.val).map (lowerN ·.val) =
      (b.val.drop i.val).map (lowerN ·.val)) ⦄ := by
  induction h : a.length - i.val using Nat.strong_induction_on generalizing i with
  | h n ih =>
    rw [trustpub.eq_lower_loop, loop]
    unfold trustpub.eq_lower_loop.body
    dsimp only
    simp only [bind_ite]
    split
    · have ha : i.val < a.val.length := by scalar_tac
      have hb : i.val < b.val.length := by scalar_tac
      step*
      split
      · step*
        rw [List.drop_eq_getElem_cons ha, List.drop_eq_getElem_cons hb]
        simp only [List.map_cons, List.cons.injEq, Bool.false_eq, decide_eq_false_iff_not]
        intro he; have := he.1; simp_all
      · step*
        apply WP.spec_mono (ih (a.length - x.val) (by scalar_tac) x (by scalar_tac) rfl)
        intro r hr
        rw [List.drop_eq_getElem_cons ha, List.drop_eq_getElem_cons hb]
        have he : lowerN a.val[i.val].val = lowerN b.val[i.val].val := by simp_all
        simpa only [List.map_cons, List.cons.injEq, he, true_and, x_post] using hr
    · step*
      have ha : a.val.length ≤ i.val := by scalar_tac
      have hb : b.val.length ≤ i.val := by scalar_tac
      simp [List.drop_eq_nil_of_le ha, List.drop_eq_nil_of_le hb]

@[step] theorem eq_lower_spec (a b : Slice U8) :
    trustpub.eq_lower a b ⦃ r => decide (EqLower a.val b.val) = r ⦄ := by
  unfold trustpub.eq_lower
  dsimp only
  split
  · have hn : ¬ EqLower a.val b.val := by
      intro he; have := congrArg List.length he; simp at this; scalar_tac
    simp [hn]
  · apply WP.spec_mono (eq_lower_loop_spec a b 0#usize (by scalar_tac) (by simp))
    intro r hr; simp only [hr, EqLower]; simp

@[step] theorem env_ok_spec (c e : Option (alloc.vec.Vec U8)) :
    trustpub.env_ok c e ⦃ b => (b = true ↔ EnvOk (c.map (·.val)) (e.map (·.val))) ⦄ := by
  unfold trustpub.env_ok
  rcases c with _ | c <;> rcases e with _ | e <;> simp [EnvOk]
  step*; rw [← b_post]; simp

@[step] theorem jti_used_spec (used : alloc.vec.Vec (alloc.vec.Vec U8)) (j : Slice U8) :
    trustpub.jti_used used j ⦃ b => decide (j.val ∈ used.val.map (·.val)) = b ⦄ := by
  unfold trustpub.jti_used trustpub.jti_used_loop
  apply WP.spec_mono (loop_search used.val (fun u => decide (u.val = j.val)) (fun b : Bool => b)
    (fun _ _ => true) false _ ?_ 0#usize (by simp))
  · intro r hr
    rw [search_any _ _ _ hr, eq_comm, Bool.eq_iff_iff]
    simp only [List.any_eq_true, decide_eq_true_eq, List.mem_map]
  · intro k hk; unfold trustpub.jti_used_loop.body; h5i_step

/-- A config matches the token's repository (owner and name ignoring case),
owner id, workflow file and environment. -/
def Matches (c : trustpub.GitHubConfig) (owner nm : List U8) (oid : I32) (wf : List U8)
    (env : Option (List U8)) : Prop :=
  EqLower c.repository_owner.val owner ∧ EqLower c.repository_name.val nm ∧
    c.repository_owner_id = oid ∧ c.workflow_filename.val = wf ∧ EnvOk (c.environment.map (·.val)) env

theorem filter_configs_ids (configs : alloc.vec.Vec trustpub.GitHubConfig) (owner nm : Slice U8) (oid : I32)
    (wf : Slice U8) (env : Option (alloc.vec.Vec U8)) (x : Usize × Usize × Usize × alloc.vec.Vec I32)
    (h : trustpub.filter_configs configs owner nm oid wf env = ok x) :
    ∀ id ∈ x.2.2.2.val, ∃ c ∈ configs.val, c.crate_id = id ∧
      Matches c owner.val nm.val oid wf.val (env.map (·.val)) := by
  unfold trustpub.filter_configs trustpub.filter_configs_loop at h
  refine loop_ok (fun y => trustpub.filter_configs_loop.body configs owner nm oid wf env
      y.1 y.2.1 y.2.2.1 y.2.2.2.1 y.2.2.2.2)
    (fun y => y.2.2.2.2.val ≤ configs.val.length ∧ y.2.2.2.1.val.length ≤ y.2.2.2.2.val ∧
      ∀ id ∈ y.2.2.2.1.val, ∃ c ∈ configs.val, c.crate_id = id ∧
        Matches c owner.val nm.val oid wf.val (env.map (·.val)))
    (fun x => ∀ id ∈ x.2.2.2.val, ∃ c ∈ configs.val, c.crate_id = id ∧
        Matches c owner.val nm.val oid wf.val (env.map (·.val)))
    (fun y => configs.val.length - y.2.2.2.2.val) ?_ _ x (by simp [vec_new_val]) h
  rintro ⟨r, bi, bw, ids, i⟩ res ⟨hi, hl, hinv⟩ hb
  unfold trustpub.filter_configs_loop.body at hb
  done

end cratesio_kernel.Verified.Exchange
