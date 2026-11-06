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

theorem config_level_full (c : trustpub.GitHubConfig) (owner nm : Slice U8) (oid : I32) (wf : Slice U8)
    (env : Option (alloc.vec.Vec U8)) (k : U8)
    (h : trustpub.config_level c owner nm oid wf env = ok k) (hk : 4 ≤ k.val) :
    Matches c owner.val nm.val oid wf.val (env.map (·.val)) := by
  unfold trustpub.config_level at h
  h5i_invert h
  all_goals try (simp at hk)
  have h1 := post_of_ok (eq_lower_spec _ _) ‹trustpub.eq_lower c.repository_owner.deref owner = ok _›
  have h2 := post_of_ok (eq_lower_spec _ _) ‹trustpub.eq_lower c.repository_name.deref nm = ok _›
  have h3 := post_of_ok (eq_spec _ _) ‹bytes.eq c.workflow_filename.deref wf = ok _›
  have h4 := post_of_ok (env_ok_spec _ _) ‹trustpub.env_ok c.environment env = ok _›
  subst hc hc_1 hc_3
  refine ⟨by simpa using h1, by simpa using h2, by simp at hc_2; scalar_tac, by simpa using h3, h4.1 hc_4⟩

theorem push_val {α : Type} {v : alloc.vec.Vec α} {x : α} {w : alloc.vec.Vec α}
    (h : alloc.vec.Vec.push v x = ok w) : w.val = v.val ++ [x] := by
  by_cases hb : v.val.length < Usize.max
  · exact post_of_ok (P := fun w => w.val = v.val ++ [x]) (alloc.vec.Vec.push_spec v x hb) h
  · exfalso
    unfold alloc.vec.Vec.push at h
    dsimp only at h
    split at h
    · rename_i hc
      simp only [Bool.or_eq_true, decide_eq_true_eq] at hc
      have : U32.max ≤ Usize.max := by scalar_tac
      omega
    · simp at h

/-- Every crate id the exchange collects comes from a fully matching config. -/
theorem matching_ids_ok (configs : alloc.vec.Vec trustpub.GitHubConfig) (owner nm : Slice U8) (oid : I32)
    (wf : Slice U8) (env : Option (alloc.vec.Vec U8)) (ids : alloc.vec.Vec I32)
    (h : trustpub.matching_ids configs owner nm oid wf env = ok ids) :
    ∀ id ∈ ids.val, ∃ c ∈ configs.val, c.crate_id = id ∧
      Matches c owner.val nm.val oid wf.val (env.map (·.val)) := by
  unfold trustpub.matching_ids trustpub.matching_ids_loop at h
  refine loop_ok (fun y => trustpub.matching_ids_loop.body configs owner nm oid wf env y.1 y.2)
    (fun y => ∀ id ∈ y.1.val, ∃ c ∈ configs.val, c.crate_id = id ∧
        Matches c owner.val nm.val oid wf.val (env.map (·.val)))
    (fun x => ∀ id ∈ x.val, ∃ c ∈ configs.val, c.crate_id = id ∧
        Matches c owner.val nm.val oid wf.val (env.map (·.val)))
    (fun y => configs.val.length - y.2.val) ?_ _ ids (by simp [vec_new_val]) h
  rintro ⟨acc, i⟩ res hinv hb
  unfold trustpub.matching_ids_loop.body at hb
  simp only at hinv hb ⊢
  h5i_invert hb
  · h5i_ok_facts
    refine ⟨fun id hid => ?_, by scalar_tac⟩
    simp only at hid
    by_cases h4 : i2 ≥ 4#u8
    · simp only [h4, if_true] at hids1
      rw [push_val hids1] at hid
      rcases List.mem_append.1 hid with hm | hm
      · exact hinv id hm
      · simp only [List.mem_singleton] at hm; subst hm
        exact ⟨ghc, vec_index_ok_mem hghc, rfl, config_level_full _ _ _ _ _ _ _ hi2 (by scalar_tac)⟩
    · simp only [h4, if_false] at hids1
      have := Result.ok.inj hids1; subst this
      exact hinv id hid
  · exact hinv

@[step] theorem first_slash_spec (s : Slice U8) :
    trustpub.first_slash s ⦃ o => s.val.findIdx? (fun b => decide (b = 47#u8)) = o.map (·.val) ⦄ := by
  unfold trustpub.first_slash trustpub.first_slash_loop
  apply WP.spec_mono (loop_search s.val (fun b => decide (b = 47#u8))
    (fun o : Option Usize => (o.map (·.val) : Option Nat)) (fun k _ => some k) none _ ?_ 0#usize (by simp))
  · intro r hr; exact (search_findIdx _ _ _ hr).symm
  · intro j hj; unfold trustpub.first_slash_loop.body; h5i_step

/-- What a successful exchange establishes: the `jti` was unused and is now
recorded, the event is not a forbidden trigger, and every crate the new
token may publish has a config matching the token's repository, owner id,
workflow and environment. -/
theorem exchange_ok {used : alloc.vec.Vec (alloc.vec.Vec U8)} {configs : alloc.vec.Vec trustpub.GitHubConfig}
    {claims : trustpub.GitHubClaims} {ids : alloc.vec.Vec I32} {used' : alloc.vec.Vec (alloc.vec.Vec U8)}
    (h : trustpub.exchange_github used configs claims = ok (.Ok (ids, used'))) :
    claims.jti.val ∉ used.val.map (·.val) ∧ used'.val.map (·.val) = used.val.map (·.val) ++ [claims.jti.val] ∧
    claims.event_name.val ≠ trustpub.PULL_REQUEST_TARGET.val ∧ claims.event_name.val ≠ trustpub.WORKFLOW_RUN.val ∧
    ids.val ≠ [] ∧
    ∃ k wf oid, claims.repository.val.findIdx? (fun b => decide (b = 47#u8)) = some k ∧
      trustpub.workflow_filename claims.workflow_ref.deref = ok (some wf) ∧
      trustpub.parse_i32 claims.repository_owner_id.deref = ok (some oid) ∧
      ∀ id ∈ ids.val, ∃ c ∈ configs.val, c.crate_id = id ∧
        Matches c (claims.repository.val.take k) (claims.repository.val.drop (k + 1)) oid wf.val
          (claims.environment.map (·.val)) := by
  unfold trustpub.exchange_github at h
  h5i_invert h
  obtain ⟨rfl, rfl⟩ := h
  have hj := post_of_ok (jti_used_spec _ _) hb
  have he1 := post_of_ok (eq_spec _ _) hb1
  have he2 := post_of_ok (eq_spec _ _) hb2
  have hs2v : s2 = trustpub.PULL_REQUEST_TARGET.to_slice := by
    simp only [lift] at hs2; exact (Result.ok.inj hs2).symm
  have hs4v : s4 = trustpub.WORKFLOW_RUN.to_slice := by
    simp only [lift] at hs4; exact (Result.ok.inj hs4).symm
  have hsl := post_of_ok (first_slash_spec _) ho
  simp only [deref_val, Option.map_some] at hsl
  have hlt : i.val < claims.repository.val.length := (List.findIdx?_eq_some_iff_findIdx_eq.1 hsl).1
  have hown := post_of_ok (sub_spec claims.repository.deref 0#usize i (by simp) (by simp [Slice.length]; omega)) howner
  h5i_ok_facts
  have hnm := post_of_ok (sub_spec claims.repository.deref i1 claims.repository.len (by scalar_tac)
    (by simp [Slice.length])) hname
  have hm := matching_ids_ok _ _ _ _ _ _ _ hids_1
  have hcl := post_of_ok (CloneLaw.vec_clone_spec _ _) hout
  subst hcl
  have hv1v := post_of_ok (sub_spec claims.jti.deref 0#usize claims.jti.len (by simp) (by simp [Slice.length])) hv1
  have hpush := push_val hout1
  refine ⟨?_, ?_, ?_, ?_, ?_, i.val, h_1, uid, hsl, ho1, ho2, ?_⟩
  · intro hin; apply hc; rw [← hj]; simpa using hin
  · rw [hpush]; simp [hv1v, Slice.length]
  · intro he; apply hc_1; rw [← he1, hs2v]; simp [he, Array.to_slice]
  · intro he; apply hc_2; rw [← he2, hs4v]; simp [he, Array.to_slice]
  · intro he; apply hc_6; have : ids_1.val.length = 0 := by simp [he]
    scalar_tac
  · intro id hid
    obtain ⟨c, hc, hcid, hmt⟩ := hm id hid
    refine ⟨c, hc, hcid, ?_⟩
    simp only [deref_val, show ((0#usize : Usize) : Nat) = 0 from rfl, List.drop_zero] at hown hnm hmt
    rw [hown, hnm] at hmt
    have hl : claims.repository.len.val = claims.repository.val.length := by simp [Slice.len]
    rw [hl, List.take_length, hi1_val] at hmt
    simpa using hmt

end cratesio_kernel.Verified.Exchange
