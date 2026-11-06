import Lemmas
/-!
# Security properties of windmill's path and scope checks
-/
open Aeneas Aeneas.Std Result windmill_kernel windmill_kernel.Spec windmill_kernel.Lemmas H5iAppLib

namespace windmill_kernel.Properties

/-- Path ownership: a non-admin passes `require_owner_of_path` only for a path in their
own user namespace `u/<username>/...` or in a folder they own `f/<folder>/...`. -/
theorem owner_of_path_sound (a : authz.Authed) (p : Slice U8) (hp : p.length < Usize.max)
    (h : authz.require_owner_of_path a p = ok (.Ok ())) : ownerOfPath a p.val := by
  unfold authz.require_owner_of_path at h
  h5i_invert h
  · exact Or.inl hc
  all_goals
    have hs := post_of_ok (split_spec p 47#u8 hp) hparts
    change parts.val.map (·.val) = segments slashB p.val at hs
    have hl : 2 ≤ (segments slashB p.val).length := by
      rw [← hs]; simp only [List.length_map]; scalar_tac
    refine Or.inr ⟨_, rfl, hl, ?_⟩
    have e0 := seg_of hs hv
    have e1 := seg_of hs hv1
    simp only [UScalar.ofNatCore_val_eq, Usize.ofNatCore_val_eq] at e0 e1
    rw [e0, e1]
  · left
    exact ⟨by simpa [vec_deref_val, U_val] using eq_true hb hc_3, by simpa [vec_deref_val] using eq_true hb1 hc_4⟩
  · right
    exact ⟨by simpa [vec_deref_val, F_val] using eq_true hb1 hc_4, by simpa [vec_deref_val] using require_is_owner_ok h⟩

/-- What a successful preview access check establishes. -/
def previewOk (a : authz.Authed) (path : Bytes) : Prop :=
  ¬ traversal path ∧
  (a.is_admin = true ∨ path = [] ∨
    ∃ segs, segments slashB path = segs ∧ 2 ≤ segs.length ∧
      ((segs[0]! = uB ∧ segs[1]! = a.username.val) ∨ (segs[0]! = fB ∧ readsFolder a segs[1]!) ∨
        segs[0]! = [104#u8, 117#u8, 98#u8]))

theorem preview_spec (a : authz.Authed) (p : Slice U8) (hp : p.length < Usize.max) :
    authz.require_path_read_access_for_preview a p ⦃ r => r = .Ok () → previewOk a p.val ⦄ := by
  unfold authz.require_path_read_access_for_preview
  step*
  all_goals
    intro _
    refine ⟨not_traversal_of p parts parts_post (by intro h0; simp_all) (by simp_all [vec_deref_val])
      (by simp_all), ?_⟩
  all_goals first
    | exact Or.inl ‹_›
    | (right; left
       have h0 := ‹p.len = 0#usize›
       have : p.val.length = 0 := by simpa using congrArg (·.val) h0
       exact List.eq_nil_of_length_eq_zero this)
    | (right; right
       have hpl : 2 ≤ parts.val.length := by scalar_tac
       have hl : 2 ≤ (segments slashB p.val).length := by
         change 2 ≤ (segments 47#u8 p.val).length
         rw [← parts_post]; simp only [List.length_map]; exact hpl
       refine ⟨_, rfl, hl, ?_⟩
       have e0 : (segments slashB p.val)[0]! = (parts.val[0]'(by omega)).val := by
         change (segments 47#u8 p.val)[0]! = _
         rw [← parts_post]; simp [List.getElem!_eq_getElem?_getD, show 0 < parts.val.length by omega]
       have e1 : (segments slashB p.val)[1]! = (parts.val[1]'(by omega)).val := by
         change (segments 47#u8 p.val)[1]! = _
         rw [← parts_post]; simp [List.getElem!_eq_getElem?_getD, show 1 < parts.val.length by omega]
       rw [e0, e1]
       simp_all [vec_deref_val, U_val, F_val, readsFolder, authz.HUB, array_to_slice_val])

/-- A preview job's path never escapes its directory: no leading `/`, no `..`
segment, no NUL byte, whoever asks (the check runs before the admin bypass). -/
theorem preview_never_traverses (a : authz.Authed) (p : Slice U8) (hp : p.length < Usize.max)
    (h : authz.require_path_read_access_for_preview a p = ok (.Ok ())) : ¬ traversal p.val :=
  (post_of_ok (preview_spec a p hp) h rfl).1

/-- A non-admin previews only in their own user namespace, a folder they can read,
or the hub. -/
theorem preview_requires_namespace (a : authz.Authed) (p : Slice U8) (hp : p.length < Usize.max)
    (h : authz.require_path_read_access_for_preview a p = ok (.Ok ())) (hna : a.is_admin = false)
    (hne : p.val ≠ []) :
    ∃ segs, segments slashB p.val = segs ∧ 2 ≤ segs.length ∧
      ((segs[0]! = uB ∧ segs[1]! = a.username.val) ∨ (segs[0]! = fB ∧ readsFolder a segs[1]!) ∨
        segs[0]! = [104#u8, 117#u8, 98#u8]) := by
  have := (post_of_ok (preview_spec a p hp) h rfl).2
  rcases this with h1 | h2 | h3
  · simp [hna] at h1
  · exact absurd h2 hne
  · exact h3

/-- `is_owner` grants only admins and owners of the folder. -/
theorem is_owner_sound (a : authz.Authed) (n : Slice U8) (h : authz.is_owner a n = ok true) :
    ownsFolder a n.val :=
  (post_of_ok (is_owner_spec a n) h).1 rfl

/-- Instance-global admin actions are never allowed to a job token (`WM_TOKEN`) and
always require admin. -/
theorem instance_admin_never_job_token (a : authz.Authed)
    (h : authz.require_instance_admin a = ok (.Ok ())) : a.has_job_id = false ∧ a.is_admin = true := by
  unfold authz.require_instance_admin at h
  split_ifs at h <;> simp_all

theorem covers_spec (c r : Slice U8) :
    scopes.resource_covers c r ⦃ b => b = true → coversSem c.val r.val ⦄ := by
  unfold scopes.resource_covers
  h5i_steps
  -- `2 ≤ len` side conditions of the `- 2`
  all_goals first
    | (obtain ⟨q, hq⟩ := b1_post.1 ‹_›; have := congrArg List.length hq; simp at this; scalar_tac)
    | (obtain ⟨q, hq⟩ := b2_post.1 ‹_›; have := congrArg List.length hq; simp at this; scalar_tac)
    | skip
  -- equal patterns
  all_goals first
    | (intro _; have e : c.val = r.val := by simpa [b_post] using ‹b = true›
       intro x hx; rw [e]; exact hx)
    | skip
  all_goals intro hfin
  all_goals
    have hc : endsSS c.val := b1_post.1 ‹_›
    have hpre : pre.val = c.val.take (c.val.length - 2) := by rw [pre_post, i1_post]; simp
    apply covers_core hc hpre (base := base.val)
  all_goals first
    | exact Or.inl ⟨b2_post.1 ‹_›, by rw [base_post, x_post]; simp⟩
    | exact Or.inr ⟨fun h => ‹¬b2 = true› (b2_post.2 h), by rw [r_post]; rfl⟩
    | (left; have h3 := ‹b3 = true›; rw [b3_post] at h3; simpa [vec_deref_val] using h3)
    | (right
       have h4 := ‹b4 = true›; rw [b4_post] at h4
       refine ⟨by simpa [vec_deref_val] using h4, by scalar_tac, ?_⟩
       have hl : pre.val.length < base.val.length := by scalar_tac
       rw [List.getElem?_eq_getElem hl]
       simp only [decide_eq_true_eq] at hfin
       have : pre.len.val = pre.val.length := by simp
       simp_all [slashB])

/-- Delegation never widens a path grant: when the minting check `resource_covers`
accepts a requested resource pattern, every concrete path the requested pattern
names (itself, or the subtree of a `p/*`) is also named by the caller's pattern. -/
theorem resource_covers_sound (c r : Slice U8) (h : scopes.resource_covers c r = ok true) :
    coversSem c.val r.val :=
  post_of_ok (covers_spec c r) h rfl

/-- For ASCII resources, a `p/*` wildcard matches only paths in the subtree of `p`:
`p` itself or `p/...`, never a sibling such as `p-x/...` or `px/...`. -/
theorem wildcard_ascii_boundary (pat r : Slice U8) (ha : ascii r.val)
    (h : scopes.matches_wildcard pat r = ok true) : names pat.val r.val := by
  obtain ⟨⟨q, hq⟩, hp, hrest⟩ := (post_of_ok (matches_wildcard_spec pat r) h).1 rfl
  have hqt : pat.val.take (pat.val.length - 2) = q := by rw [hq]; simp
  rw [hqt] at hp hrest
  rw [hq, names_wild]
  right
  rcases hrest with hl | hs
  · left; exact (hp.eq_of_length hl.symm).symm
  · right
    rw [leads_ascii ha] at hs
    exact prefix_slash hp (by
      rcases Nat.lt_or_ge q.length r.val.length with h1 | h1
      · exact h1
      · rw [List.getElem?_eq_none h1] at hs; simp at hs) hs

/-- FINDING (W1): with a multi-byte character in the wildcard's prefix, the `/`
boundary check of `resource_matches_pattern` reads a character index as a byte offset.
The grant `f/dé/*` then matches `f/déx/y`, a path outside its subtree. -/
theorem wildcard_unicode_crosses_boundary (pat r : Slice U8)
    (hpat : pat.val = [102#u8, 47#u8, 100#u8, 195#u8, 169#u8, 47#u8, 42#u8])
    (hr : r.val = [102#u8, 47#u8, 100#u8, 195#u8, 169#u8, 120#u8, 47#u8, 121#u8]) :
    scopes.matches_wildcard pat r = ok true ∧ ¬ names pat.val r.val := by
  obtain ⟨b, hb, hiff⟩ := WP.spec_imp_exists (matches_wildcard_spec pat r)
  have hm : wildcardModel pat.val r.val := by
    rw [hpat, hr]
    refine ⟨⟨[102#u8, 47#u8, 100#u8, 195#u8, 169#u8], by simp [slashB, starB]⟩, by decide, Or.inr ?_⟩
    decide
  refine ⟨by rw [hb, hiff.2 hm], ?_⟩
  rw [hpat, hr, show [102#u8, 47#u8, 100#u8, 195#u8, 169#u8, 47#u8, 42#u8] =
    [102#u8, 47#u8, 100#u8, 195#u8, 169#u8] ++ [slashB, starB] by simp [slashB, starB], names_wild]
  simp only [inSubtree]
  decide

theorem includes_true {s o : scopes.Scope} (h : scopes.includes s o = ok true) :
    s.domain.val = o.domain.val ∧ actionCov s.domain.val s.action.val o.action.val := by
  unfold scopes.includes at h
  simp only [eq_eq, bind_ok] at h
  h5i_invert h
  all_goals
    subst hc_1
    refine ⟨by simpa [vec_deref_val] using hc, ?_⟩
    simpa [vec_deref_val] using action_covers_true hb1

/-- A token scope never grants anything in another domain. -/
theorem scope_never_crosses_domain (s o : scopes.Scope) (h : scopes.includes s o = ok true) :
    s.domain.val = o.domain.val :=
  (includes_true h).1

/-- A `read` scope never grants a `write` (or `run`, `cancel`) requirement. -/
theorem read_never_grants_more (s o : scopes.Scope) (h : scopes.includes s o = ok true)
    (hr : s.action.val = readB) : o.action.val = readB := by
  have := (includes_true h).2
  unfold actionCov at this
  rw [hr] at this
  rcases this with h1 | ⟨h1, _⟩ | ⟨h1, _⟩ | ⟨h1, _⟩
  · exact h1.symm
  all_goals simp [readB, writeB] at h1

/-- `jobs:write` never grants running a job (only `apps:write` covers `run`). -/
theorem jobs_write_never_runs (s o : scopes.Scope) (hd : s.domain.val = jobsB) (ha : s.action.val = writeB)
    (hr : o.action.val = runB) : scopes.includes s o ≠ ok true := by
  intro h
  have := (includes_true h).2
  unfold actionCov at this
  rw [hd, ha, hr] at this
  simp [jobsB, appsB, writeB, runB, readB, cancelB] at this

theorem contains_true {c r : scopes.Scope} (h : scopes.scope_contains c r = ok true) :
    c.domain.val = r.domain.val ∧ actionCov c.domain.val c.action.val r.action.val := by
  unfold scopes.scope_contains at h
  simp only [eq_eq, bind_ok] at h
  h5i_invert h
  all_goals
    subst hc_1
    refine ⟨by simpa [vec_deref_val] using hc, ?_⟩
    simpa [vec_deref_val] using action_covers_true hb1

/-- Minting never moves a token to another domain or to an action its caller's scope
does not cover: a scope accepted by `scope_contains` has the caller's domain and an
action the caller's action covers. -/
theorem delegation_stays_in_domain_and_action (c r : scopes.Scope)
    (h : scopes.scope_contains c r = ok true) :
    c.domain.val = r.domain.val ∧ actionCov c.domain.val c.action.val r.action.val :=
  contains_true h

/-- A `read` caller can only delegate `read`. -/
theorem read_delegates_only_read (c r : scopes.Scope) (h : scopes.scope_contains c r = ok true)
    (hr : c.action.val = readB) : r.action.val = readB := by
  have := (contains_true h).2
  unfold actionCov at this
  rw [hr] at this
  rcases this with h1 | ⟨h1, _⟩ | ⟨h1, _⟩ | ⟨h1, _⟩
  · exact h1.symm
  all_goals simp [readB, writeB] at h1

/-- `extra_perms` grants (`Some(true)`) only through an explicit JSON `true` entry
for `u/<username>` or `g/<group>` of one of the caller's groups. -/
theorem extra_perms_true_needs_entry (is_object : Bool) (obj : Slice authz.PermEntry) (a : authz.Authed)
    (hu : a.username.length + 2 < Usize.max) (hg : ∀ g ∈ a.groups.val, g.length + 2 < Usize.max)
    (h : authz.get_perm_in_extra_perms is_object obj a = ok (true, true)) :
    grantedByEntry obj.val a := by
  unfold authz.get_perm_in_extra_perms at h
  h5i_invert h
  · obtain ⟨f, v1⟩ := x
    have hk := post_of_ok (key_for_spec 117#u8 a.username.deref (by simpa [vec_deref_val] using hu)) hv
    have hl := post_of_ok (lookup_spec obj v.deref) hx
    dsimp only at hl
    cases f <;> cases v1 <;> simp at h
    all_goals first
      | (obtain ⟨e, he, hb, hval, g, hgm, hkey⟩ := post_of_ok (perm_loop1_sound obj a.groups hg) h rfl
         exact ⟨e, he, hb, hval, Or.inr ⟨g, hgm, hkey⟩⟩)
      | (obtain ⟨e, he, hkey, hb, hval⟩ := hl rfl rfl
         exact ⟨e, he, hb, hval, Or.inl (by rw [hkey]; simpa [vec_deref_val] using hk)⟩)
      | (h5i_invert h
         obtain ⟨e, he, hb, hval, g, hgm, hkey⟩ := post_of_ok (perm_loop0_sound obj a.groups hg)
           ‹authz.get_perm_in_extra_perms_loop0 obj a.groups 0#usize = ok _› (by simp_all)
         exact ⟨e, he, hb, hval, Or.inr ⟨g, hgm, hkey⟩⟩)
  · exact h.1.elim

end windmill_kernel.Properties
