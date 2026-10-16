import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result nora_kernel nora_kernel.Spec
open H5iAppLib hiding lit
open Aeneas.Std.WP
set_option maxHeartbeats 1000000

namespace nora_kernel.Solution

@[step] theorem is_star_total (p : Slice U8) : is_star p ⦃ _ => True ⦄ := by
  unfold is_star
  h5i_steps

@[step] theorem bytes_eq_total (a b : Slice U8) : bytes_eq a b ⦃ _ => True ⦄ := by
  unfold bytes_eq
  dsimp only
  split
  · simp
  · rename_i h
    have heq : a.length = b.length := by scalar_tac
    unfold bytes_eq_loop
    h5i_total (fun i => i) a.length

@[step] theorem starts_with_at_total (s p : Slice U8) (off : Usize)
    (hoff : off.val ≤ s.length) :
    starts_with_at s off p ⦃ b => b = true → off.val + p.length ≤ s.length ⦄ := by
  unfold starts_with_at
  step*
  have hb : off.val + p.length ≤ s.length := by scalar_tac
  apply spec_mono (P₀ := fun _ => True) _ (by intro _ _; exact fun _ => hb)
  unfold starts_with_at_loop
  h5i_total (fun i => i) p.length

@[step] theorem find_from_total (s p : Slice U8) (off : Usize)
    (hoff : off.val ≤ s.length) (hp : 0 < p.length) :
    find_from s off p ⦃ o => ∀ j, o = some j → j.val + p.length ≤ s.length ⦄ := by
  unfold find_from find_from_loop
  apply loop_idx_spec _ (fun i => i) s.length (fun _ => True) _ ?_ off trivial hoff
  intro i _ hi
  unfold find_from_loop.body
  h5i_steps

-- Splitting can add one final piece, so its input must be shorter than usize::MAX.
@[step] theorem split_total (s : Slice U8) (sep : U8) (hs : s.length < Usize.max) :
    split s sep ⦃ parts => parts.length ≤ s.length + 1 ∧
      ∀ part ∈ parts.val, part.length ≤ s.length ⦄ := by
  have hl : split_loop s sep (alloc.vec.Vec.new _) (alloc.vec.Vec.new _) 0#usize
      ⦃ pair => pair.1.length ≤ s.length ∧ pair.2.length ≤ s.length ∧
        ∀ part ∈ pair.1.val, part.length ≤ s.length ⦄ := by
    unfold split_loop
    apply loop_idx_spec _ (fun x => x.2.2) s.length
      (fun x => x.1.length ≤ x.2.2.val ∧ x.2.1.length ≤ x.2.2.val ∧
        ∀ part ∈ x.1.val, part.length ≤ s.length) _ ?_ _ ?_ (by simp)
    · rintro ⟨out, cur, i⟩ ⟨ho, hc, hp⟩ hi
      unfold split_loop.body
      h5i_steps
      all_goals simp_all [alloc.vec.Vec.new, alloc.vec.Vec.length, Slice.length]
      all_goals (try scalar_tac)
      constructor
      · rintro part (hm | rfl)
        · exact hp part hm
        · scalar_tac
      · scalar_tac
    · simp [alloc.vec.Vec.new]
  unfold split
  step with hl
  h5i_steps
  all_goals simp_all [alloc.vec.Vec.length, Slice.length]
  all_goals (rintro part (hm | rfl); exact out_post2 part hm; exact out_post1)

@[step] theorem glob_parts_total (parts : Slice (alloc.vec.Vec U8)) (value : Slice U8) :
    glob_parts parts value ⦃ _ => True ⦄ := by
  unfold glob_parts glob_parts_loop
  apply loop_idx_spec _ (fun x => x.2) parts.length
    (fun x => x.1.val ≤ value.length) _ ?_ _ (by simp) (by simp)
  rintro ⟨rem, i⟩ hr hi
  unfold glob_parts_loop.body
  h5i_steps
  all_goals (try have hpos : 0 < part.length := by scalar_tac)
  all_goals simp_all [alloc.vec.Vec.deref, alloc.vec.Vec.length, Slice.length]
  all_goals scalar_tac

@[step] theorem glob_match_total (pattern value : Slice U8)
    (hp : pattern.length < Usize.max) : glob_match pattern value ⦃ _ => True ⦄ := by
  unfold glob_match
  h5i_steps

@[step] theorem has_star_total (scope : Slice (alloc.vec.Vec U8)) :
    has_star scope ⦃ _ => True ⦄ := by
  unfold has_star has_star_loop
  h5i_total (fun i => i) scope.length

@[step] theorem contains_star_total (p : Slice U8) : contains_star p ⦃ _ => True ⦄ := by
  unfold contains_star contains_star_loop
  h5i_total (fun i => i) p.length

@[step] theorem all_stars_from_total (p : Slice U8) (i : Usize)
    (hi : i.val ≤ p.length) : all_stars_from p i ⦃ _ => True ⦄ := by
  unfold all_stars_from all_stars_from_loop
  h5i_total (fun i => i) p.length

def ScanInv (p v : Slice U8) (s : Usize × Usize × Option (Usize × Usize)) : Prop :=
  s.1.val ≤ p.length ∧ s.2.1.val ≤ v.length ∧
  ∀ sp sv, s.2.2 = some (sp, sv) → sp.val < s.1.val ∧ sv.val ≤ s.2.1.val

def scanAnchor (s : Usize × Usize × Option (Usize × Usize)) : Nat :=
  match s.2.2 with
  | none => s.2.1.val
  | some (_, sv) => sv.val

theorem lex_decrease (a b x y : Nat) (hab : a ≤ b) (hxy : x < y) :
    WellFoundedRelation.rel (a, x) (b, y) := by
  rcases Nat.lt_or_eq_of_le hab with h | rfl
  · exact Prod.Lex.left _ _ h
  · exact Prod.Lex.right _ hxy

@[step] theorem glob_scan_total (p v : Slice U8) :
    glob_scan p v ⦃ o => ∀ pi, o = some pi → pi.val ≤ p.length ⦄ := by
  unfold glob_scan glob_scan_loop
  -- Backtracking advances the saved value index; other steps advance the pattern
  -- or the value index. The remaining distances therefore decrease lexicographically.
  apply loop.spec (measure := fun s => (v.length - scanAnchor s, p.length - s.1.val))
    (inv := ScanInv p v)
  · rintro ⟨pi, vi, bt⟩ ⟨hp, hv, hb⟩
    rcases bt with _ | ⟨sp, sv⟩
    all_goals try obtain ⟨hsp, hsv⟩ := hb _ _ rfl
    all_goals unfold glob_scan_loop.body
    all_goals h5i_steps
    all_goals simp_all [ScanInv, scanAnchor]
    all_goals repeat' apply And.intro
    all_goals first
      | scalar_tac
      | (apply lex_decrease <;> scalar_tac)
      | (apply Prod.Lex.left; change (_ : Nat) < _; simp only [sizeOf_nat]; scalar_tac)
  · simp [ScanInv]

@[step] theorem segment_glob_total (p v : Slice U8) : segment_glob p v ⦃ _ => True ⦄ := by
  unfold segment_glob
  h5i_steps

theorem segments_total (pat val : Slice (alloc.vec.Vec U8)) (pi vi : Usize)
    (hp : pi.val ≤ pat.length) (hv : vi.val ≤ val.length) :
    (segments_match pat pi val vi ⦃ _ => True ⦄) ∧
    (segments_match_any pat pi val vi ⦃ _ => True ⦄) := by
  generalize hm : pat.length - pi.val + (val.length - vi.val) = n
  induction n using Nat.strong_induction_on generalizing pi vi with
  | h n ih =>
    have hmatch (pj vj : Usize) (hpj : pj.val ≤ pat.length) (hvj : vj.val ≤ val.length)
        (hlt : pat.length - pj.val + (val.length - vj.val) < n) :
        segments_match pat pj val vj ⦃ _ => True ⦄ :=
      (ih _ hlt pj vj hpj hvj rfl).1
    have hany (pj vj : Usize) (hpj : pj.val ≤ pat.length) (hvj : vj.val ≤ val.length)
        (hlt : pat.length - pj.val + (val.length - vj.val) < n) :
        segments_match_any pat pj val vj ⦃ _ => True ⦄ :=
      (ih _ hlt pj vj hpj hvj rfl).2
    constructor
    · unfold segments_match
      h5i_steps
    · unfold segments_match_any
      h5i_steps

@[step] theorem namespace_match_total (p v : Slice U8)
    (hp : p.length < Usize.max) (hv : v.length < Usize.max) :
    namespace_match p v ⦃ _ => True ⦄ := by
  unfold namespace_match
  h5i_steps
  exact (segments_total _ _ _ _ (by simp) (by simp)).1

def ScopeBound (sc : List (alloc.vec.Vec U8)) : Prop :=
  ∀ s ∈ sc, s.length < Usize.max

def RuleScopeBound (sc : Option (alloc.vec.Vec (alloc.vec.Vec U8))) : Prop :=
  ∀ v, sc = some v → ScopeBound v.val

@[step] theorem scopes_clone_total (sc : alloc.vec.Vec (alloc.vec.Vec U8)) :
    alloc.vec.CloneVec.clone (core.clone.CloneallocvecVec core.clone.CloneU8) sc
      ⦃ v => v = sc ⦄ := by
  simp [vec_clone_ok, core.clone.CloneallocvecVec]

@[step] theorem scopes_to_vec_total (sc : Slice (alloc.vec.Vec U8)) :
    alloc.slice.Slice.to_vec (core.clone.CloneallocvecVec core.clone.CloneU8) sc
      ⦃ v => v.val = sc.val ⦄ := by
  apply spec_mono (alloc.slice.Slice.to_vec_spec _ sc ?_) ?_
  · intro v _; exact u8vec_clone v
  · intro v h; exact congrArg Slice.val h.symm

@[step] theorem match_role_total (p : OidcProvider) (subject : Slice U8)
    (hpat : ∀ rule ∈ p.role_rules.val, rule.pattern.length < Usize.max)
    (hns : ∀ rule ∈ p.role_rules.val, RuleScopeBound rule.namespace_scope) :
    match_role p subject ⦃ o => ∀ role sc, o = some (role, sc) → RuleScopeBound sc ⦄ := by
  unfold match_role match_role_loop
  apply loop_idx_spec _ (fun i => i) p.role_rules.length (fun _ => True) _ ?_
    _ trivial (by simp)
  intro i _ hi
  unfold match_role_loop.body
  dsimp only
  split
  · step as ⟨rule, hrule⟩
    have hmem : rule ∈ p.role_rules.val := by
      rw [hrule]; apply List.getElem_mem
    have hpa := hpat rule hmem
    have hsc := hns rule hmem
    h5i_steps
    all_goals simp_all [RuleScopeBound, alloc.vec.Vec.deref]
  · simp

def IdentityBound (id : OidcIdentity) : Prop :=
  ScopeBound id.namespace_scope.val ∧ RuleScopeBound id.rule_namespace_scope

@[step] theorem validate_claims_total (p : OidcProvider) (c : Claims)
    (hpat : ∀ rule ∈ p.role_rules.val, rule.pattern.length < Usize.max)
    (hns : ScopeBound p.namespace_scope.val)
    (hrules : ∀ rule ∈ p.role_rules.val, RuleScopeBound rule.namespace_scope) :
    validate_claims p c ⦃ res => ∀ id, res = .Ok id → IdentityBound id ⦄ := by
  unfold validate_claims
  simp only [lift]
  h5i_steps
  all_goals try rcases x with ⟨role, scope⟩
  all_goals h5i_steps
  all_goals simp_all [IdentityBound]

def AuthorityBound : NamespaceAuthority → Prop
  | .Unrestricted => True
  | .Scoped scopes _ => ∀ sc ∈ scopes.val, ScopeBound sc.val

@[step] theorem from_oidc_scopes_total (provider : Slice (alloc.vec.Vec U8))
    (rule : Option (alloc.vec.Vec (alloc.vec.Vec U8))) (mode : ScopeEnforcement)
    (hp : ScopeBound provider.val) (hr : RuleScopeBound rule) :
    from_oidc_scopes provider rule mode ⦃ auth => AuthorityBound auth ⦄ := by
  have hmax := usize_max_ge
  unfold from_oidc_scopes
  h5i_steps
  all_goals simp_all [AuthorityBound, RuleScopeBound, ScopeBound, alloc.vec.Vec.new]

@[step] theorem scope_matches_total (scope : Slice (alloc.vec.Vec U8)) (ns : Slice U8)
    (hscope : ScopeBound scope.val) (hns : ns.length < Usize.max) :
    scope_matches scope ns ⦃ _ => True ⦄ := by
  unfold scope_matches scope_matches_loop
  apply loop_idx_spec _ (fun i => i) scope.length (fun _ => True) _ ?_
    _ trivial (by simp)
  intro i _ hi
  unfold scope_matches_loop.body
  dsimp only
  split
  · step as ⟨v, hv⟩
    have hmem : v ∈ scope.val := by rw [hv]; apply List.getElem_mem
    have hp := hscope v hmem
    h5i_steps
    all_goals simp_all [alloc.vec.Vec.deref]
  · simp

@[step] theorem enforce_namespace_scope_total (auth : NamespaceAuthority) (ns : Slice U8)
    (ha : AuthorityBound auth) (hns : ns.length < Usize.max) :
    enforce_namespace_scope auth ns ⦃ _ => True ⦄ := by
  have hl (scopes : alloc.vec.Vec (alloc.vec.Vec (alloc.vec.Vec U8)))
      (hs : ∀ sc ∈ scopes.val, ScopeBound sc.val) :
      enforce_namespace_scope_loop scopes ns true 0#usize ⦃ _ => True ⦄ := by
    unfold enforce_namespace_scope_loop
    apply loop_idx_spec _ (fun x => x.2) scopes.length (fun _ => True) _ ?_
      _ trivial (by simp)
    rintro ⟨all, i⟩ _ hi
    unfold enforce_namespace_scope_loop.body
    dsimp only
    split
    · step as ⟨sc, hsc⟩
      have hmem : sc ∈ scopes.val := by rw [hsc]; apply List.getElem_mem
      have hbound := hs sc hmem
      h5i_steps
      all_goals simp_all [alloc.vec.Vec.deref]
    · simp
  unfold enforce_namespace_scope
  cases auth with
  | Unrestricted => simp
  | Scoped scopes mode =>
    have hs : ∀ sc ∈ scopes.val, ScopeBound sc.val := ha
    h5i_steps

@[step] theorem can_write_total (role : Role) : Role.can_write role ⦃ _ => True ⦄ := by
  cases role <;> simp [Role.can_write]

@[step] theorem can_admin_total (role : Role) : Role.can_admin role ⦃ _ => True ⦄ := by
  cases role <;> simp [Role.can_admin]

theorem transition_total (p : OidcProvider) (c : Claims) (r : Request)
    (hpat : ∀ rule ∈ p.role_rules.val, rule.pattern.length < Usize.max)
    (hns : (∀ s ∈ p.namespace_scope.val, s.length < Usize.max) ∧
      ∀ rule ∈ p.role_rules.val, ∀ sc, rule.namespace_scope = some sc → ∀ s ∈ sc.val, s.length < Usize.max)
    (hreq : ∀ ns, r.«namespace» = some ns → ns.length < Usize.max) :
    ∃ y, transition p c r = ok y := by
  have hprovider : ScopeBound p.namespace_scope.val := hns.1
  have hrules : ∀ rule ∈ p.role_rules.val, RuleScopeBound rule.namespace_scope := hns.2
  apply ok_of (P := fun _ => True)
  unfold transition
  step as ⟨res, hres⟩
  rw [bind_branch]
  cases res with
  | Ok id =>
    dsimp only
    obtain ⟨his, hirs⟩ := hres id rfl
    h5i_steps
    all_goals simp_all [alloc.vec.Vec.deref]
  | Err err => simp

end nora_kernel.Solution
