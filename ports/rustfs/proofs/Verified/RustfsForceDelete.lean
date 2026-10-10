import Verified.Derived
import Spec
import H5iAppLib
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit

namespace rustfs_kernel.Verified.RustfsForceDelete


theorem eq_loop_ok (a b : Slice U8) (hl : a.val.length = b.val.length) (i : Usize) (r : Bool)
    (hi : ∀ j < i.val, a.val[j]? = b.val[j]?) (h : bytes.eq_loop a b i = ok r) :
    (r = true ↔ a.val = b.val) := by
  unfold bytes.eq_loop at h
  refine loop_ok _ (fun i : Usize => ∀ j < i.val, a.val[j]? = b.val[j]?) (fun r => r = true ↔ a.val = b.val)
    (fun i : Usize => a.val.length - i.val) ?_ i r hi h
  intro x r hx hr
  unfold bytes.eq_loop.body at hr
  h5i_invert hr
  · obtain ⟨h1, h2⟩ := slice_index_ok hi2
    obtain ⟨h3, h4⟩ := slice_index_ok hi3
    simp only [Bool.false_eq_true, false_iff]
    intro he
    simp only [he] at h2
    simp_all
  · obtain ⟨h1, h2⟩ := slice_index_ok hi2
    obtain ⟨h3, h4⟩ := slice_index_ok hi3
    have := add_ok_val hi4
    simp only
    refine ⟨fun j hj => ?_, by scalar_tac⟩
    by_cases hjx : j < x.val
    · exact hx j hjx
    · have : j = x.val := by scalar_tac
      subst this
      have : i2 = i3 := (u8_eq_iff _ _).2 (by simpa using hc_1)
      simp_all
  · simp only [true_iff]
    apply List.ext_getElem?
    intro j
    by_cases hjx : j < x.val
    · exact hx j hjx
    · have : a.val.length ≤ j := by scalar_tac
      rw [List.getElem?_eq_none this, List.getElem?_eq_none (by omega)]

theorem bytes_eq_ok (a b : Slice U8) (r : Bool) (h : bytes.eq a b = ok r) :
    (r = true ↔ a.val = b.val) := by
  unfold bytes.eq at h
  h5i_invert h
  · simp only [Bool.false_eq_true, false_iff]
    intro he; simp_all
  · exact eq_loop_ok a b (by simp_all) _ r (by simp) h

theorem family_eq_ok (f g : acts.Family) :
    acts.Family.Insts.CoreCmpPartialEqFamily.eq f g = ok (decide (f = g)) := by
  unfold acts.Family.Insts.CoreCmpPartialEqFamily.eq
  cases f <;> cases g <;> simp [acts.Family.read_discriminant]

theorem effect_eq_ok (f g : stmts.Effect) :
    stmts.Effect.Insts.CoreCmpPartialEqEffect.eq f g = ok (decide (f = g)) := by
  unfold stmts.Effect.Insts.CoreCmpPartialEqEffect.eq
  cases f <;> cases g <;> simp [stmts.Effect.read_discriminant]

theorem nats_inj {a b : List U8} (h : nats a = nats b) : a = b := by
  unfold nats at h
  exact List.map_injective_iff.2 (fun x y hxy => (u8_eq_iff x y).2 hxy) h

theorem deref_val {T} (v : alloc.vec.Vec T) : (alloc.vec.Vec.deref v).val = v.val := by
  simp [alloc.vec.Vec.deref]

theorem lift_slice {n : Usize} {l : List U8} {hl} {s : Slice U8}
    (h : lift (Array.make n l hl).to_slice = ok s) : nats s.val = l.map (·.val) := by
  simp only [lift, Result.ok.injEq] at h
  subst h
  simp [Array.make_val, nats]

theorem lit_FDB : lit "s3:ForceDeleteBucket" =
    [115, 51, 58, 70, 111, 114, 99, 101, 68, 101, 108, 101, 116, 101, 66, 117, 99, 107, 101, 116] := by
  decide +kernel
theorem lit_FDO : lit "s3:ForceDeleteObject" =
    [115, 51, 58, 70, 111, 114, 99, 101, 68, 101, 108, 101, 116, 101, 79, 98, 106, 101, 99, 116] := by
  decide +kernel
theorem lit_star : lit "*" = [42] := by decide +kernel
theorem lit_s3 : lit "s3:" = [115, 51, 58] := by decide +kernel
theorem lit_admin : lit "admin:" = [97, 100, 109, 105, 110, 58] := by decide +kernel
theorem lit_sts : lit "sts:" = [115, 116, 115, 58] := by decide +kernel
theorem lit_kms : lit "kms:" = [107, 109, 115, 58] := by decide +kernel

theorem is_s3_ok (x : acts.Action) (s : Slice U8) (r : Bool) (h : acts.is_s3 x s = ok r) :
    (r = true ↔ x.family = .S3 ∧ nats x.name.val = nats s.val) := by
  unfold acts.is_s3 at h
  rw [family_eq_ok] at h
  h5i_invert h
  · have := bytes_eq_ok _ _ _ h
    rw [deref_val] at this
    have hc' : x.family = .S3 := of_decide_eq_true hc
    simp only [hc', true_and, this]
    exact ⟨fun h => by rw [h], nats_inj⟩
  · simp_all

theorem requires_ok (a : acts.Action) (r : Bool) (h : acts.action_requires_explicit_grant a = ok r) :
    (r = true ↔ IsForceDelete a) := by
  unfold acts.action_requires_explicit_grant at h
  h5i_invert h
  · have h1 := is_s3_ok _ _ _ hb
    have h2 := lift_slice hs
    simp only [hc, true_iff] at h1 ⊢
    refine ⟨h1.1, Or.inl ?_⟩
    rw [h1.2, h2, lit_FDB]; rfl
  · have h1 := is_s3_ok _ _ _ hb
    have h2 := lift_slice hs
    have h3 := is_s3_ok _ _ _ h
    have h4 := lift_slice hs1
    rw [h3, h4]
    rw [h2] at h1
    unfold IsForceDelete
    rw [lit_FDB, lit_FDO]
    simp_all

theorem action_match_ok (x a : acts.Action) (hf : IsForceDelete a)
    (h : acts.action_is_match_for_effect x a false = ok true) :
    ¬ (x.family = .S3 ∧ nats x.name.val = lit "s3:" ++ lit "*") ∧
      wildmatch.is_match (alloc.vec.Vec.deref x.name) (alloc.vec.Vec.deref a.name) = ok true := by
  unfold acts.action_is_match_for_effect at h
  h5i_invert h
  · have h1 := requires_ok _ _ hb1
    simp_all
  · have h1 := is_s3_ok _ _ _ hb
    have h2 := lift_slice hs
    refine ⟨?_, h⟩
    rw [lit_s3, lit_star]
    simp_all

theorem set_match_ok (set : Slice acts.Action) (a : acts.Action) (hf : IsForceDelete a) (i : Usize)
    (h : acts.set_is_match_for_effect_loop set a false i = ok true) :
    ∃ x ∈ set.val, acts.action_is_match_for_effect x a false = ok true := by
  unfold acts.set_is_match_for_effect_loop at h
  refine loop_true_witness _ (fun _ => True) (fun i : Usize => set.val.length - i.val) _ ?_ i trivial h
  intro x r _ hr
  unfold acts.set_is_match_for_effect_loop.body at hr
  h5i_invert hr
  · intro _
    exact ⟨a1, slice_index_ok_mem ha1, hc_1 ▸ hb⟩
  all_goals first
    | (simp only [true_and]; have := add_ok_val (by assumption : _ + 1#usize = ok _); scalar_tac)
    | (simp; done)
    | (exfalso
       have h1 := (is_s3_ok _ _ _ hb2).1 hc_3
       rw [lift_slice hs1] at h1
       obtain ⟨_, hn⟩ := hf
       rw [lit_FDB, lit_FDO] at hn
       simp at h1
       rcases hn with hn | hn <;> rw [hn] at h1 <;> simp at h1)

theorem covers_ok (acs nacs : Slice acts.Action) (a : acts.Action) (hf : IsForceDelete a)
    (h : acts.statement_covers acs nacs a false = ok true) :
    ∃ x ∈ acs.val, acts.action_is_match_for_effect x a false = ok true := by
  unfold acts.statement_covers at h
  h5i_invert h
  · have := (requires_ok _ _ hb1).2 hf
    simp_all
  · exact set_match_ok _ _ hf _ h

theorem stmt_allowed_ok (st : stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (hst : st.effect = .Allow) (hf : IsForceDelete a.action)
    (h : stmts.statement_is_allowed st a e = ok true) :
    ∃ x ∈ st.actions.val, acts.action_is_match_for_effect x a.action false = ok true := by
  unfold stmts.statement_is_allowed at h
  h5i_invert h
  obtain ⟨st1, chk⟩ := x
  cases b
  · simp only [Bool.false_eq_true, ↓reduceIte, Result.ok.injEq, Prod.mk.injEq] at hx
    obtain ⟨rfl, rfl⟩ := hx
    simp [stmts.effect_is_allowed, hst] at h
  · unfold stmts.reaches_condition_eval at hb
    rw [effect_eq_ok, hst] at hb
    obtain ⟨d, hd, hb⟩ := bind_eq_ok.1 hb
    obtain rfl : d = false := (Result.ok.inj hd).symm
    obtain ⟨c, hc, hk⟩ := bind_eq_ok.1 hb
    cases c
    · simp at hk
    · obtain ⟨x, hx, hm⟩ := covers_ok _ _ _ hf hc
      rw [deref_val] at hx
      exact ⟨x, hx, hm⟩

theorem some_allow_ok (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env) (i : Usize)
    (h : policies.some_allow_loop sts a e i = ok true) :
    ∃ st ∈ sts.val, st.effect = .Allow ∧ stmts.statement_is_allowed st a e = ok true := by
  unfold policies.some_allow_loop at h
  refine loop_true_witness _ (fun _ => True) (fun i : Usize => sts.val.length - i.val) _ ?_ i trivial h
  intro x r _ hr
  unfold policies.some_allow_loop.body at hr
  simp only [effect_eq_ok] at hr
  h5i_invert hr
  · intro _
    exact ⟨s, slice_index_ok_mem hs, of_decide_eq_true hc_1, hc_2 ▸ hb1⟩
  all_goals first
    | (simp only [true_and]; have := add_ok_val (by assumption : _ + 1#usize = ok _); scalar_tac)
    | simp

theorem policy_ok (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (h : policies.policy_is_allowed sts a e = ok true) (ho : a.is_owner = false) (hd : a.deny_only = false)
    (hf : IsForceDelete a.action) :
    ∃ st ∈ sts.val, st.effect = .Allow ∧
      ∃ x ∈ st.actions.val, acts.action_is_match_for_effect x a.action false = ok true := by
  unfold policies.policy_is_allowed at h
  h5i_invert h
  all_goals try simp_all
  obtain ⟨st, hst, he, ha⟩ := some_allow_ok _ _ _ _ h
  exact ⟨st, hst, he, stmt_allowed_ok _ _ _ he hf ha⟩

theorem drop_cons_iff {l : List Nat} {i : Nat} {c : Nat} {t : List Nat} (h : l.drop i = c :: t) :
    ∃ hi : i < l.length, l[i] = c ∧ l.drop (i + 1) = t := by
  have hi : i < l.length := by
    by_contra hc
    rw [List.drop_eq_nil_of_le (by omega)] at h
    simp at h
  rw [List.drop_eq_getElem_cons hi] at h
  simp only [List.cons.injEq] at h
  exact ⟨hi, h.1, h.2⟩

theorem deep_lit (p n : Slice U8) (s : Bool) : ∀ (l rest : List Nat) (pi ni : Usize),
    (nats p.val).drop pi.val = l ++ rest → 42 ∉ l → 63 ∉ l →
    wildmatch.deep_match p pi n ni s = ok true →
    ∃ (k : List Nat) (pi' ni' : Usize), (nats n.val).drop ni.val = l ++ k ∧
      pi'.val = pi.val + l.length ∧ ni'.val = ni.val + l.length ∧
      wildmatch.deep_match p pi' n ni' s = ok true := by
  intro l
  induction l with
  | nil => intro rest pi ni _ _ _ h; exact ⟨_, pi, ni, rfl, rfl, rfl, h⟩
  | cons c l ih =>
    intro rest pi ni hp h42 h63 h
    simp only [List.cons_append] at hp
    obtain ⟨hi, hc, hp'⟩ := drop_cons_iff hp
    simp only [List.mem_cons, not_or] at h42 h63
    rw [wildmatch.deep_match] at h
    h5i_invert h
    · exfalso; simp [nats] at hi; scalar_tac
    all_goals obtain ⟨_, hpe⟩ := slice_index_ok hc_1_1
    all_goals have hcv : c_1.val = c := by rw [← hc, ← hpe]; simp [nats]
    · subst hc_2; simp at hcv; omega
    · subst hc_2; simp at hcv; omega
    · subst hc_3; simp at hcv; omega
    · subst hc_3; simp at hcv; omega
    · subst hc_3; simp at hcv; omega
    · obtain ⟨_, hne⟩ := slice_index_ok hi2
      have hv : i2.val = c_1.val := by simpa using hc_5
      have h3 : i3.val = pi.val + 1 := by have := add_ok_val hi3; simpa using this
      have h4 : i4.val = ni.val + 1 := by have := add_ok_val hi4; simpa using this
      obtain ⟨k, pi', ni', hk, hpi, hni, hd⟩ := ih rest i3 i4 (by rw [h3]; exact hp') h42.2 h63.2 h
      refine ⟨k, pi', ni', ?_, by simp; omega, by simp; omega, hd⟩
      have hlt : ni.val < (nats n.val).length := by simp [nats]; scalar_tac
      rw [List.drop_eq_getElem_cons hlt, ← h4, hk]
      simp [nats, hne, hv, hcv]

theorem is_match_prefix (p n : Slice U8) (h : wildmatch.is_match p n = ok true) (l rest : List Nat)
    (hp : nats p.val = l ++ rest) (h42 : 42 ∉ l) (h63 : 63 ∉ l) (hne : l ≠ []) :
    ∃ k, nats n.val = l ++ k := by
  unfold wildmatch.is_match wildmatch.inner_match at h
  h5i_invert h
  · exfalso
    have : (nats p.val).length = 0 := by
      have := congrArg (·.val) hc; simp at this; simp [nats]; exact this
    rw [hp] at this; simp at this; exact hne this.1
  · exfalso
    obtain ⟨hi, hpe⟩ := slice_index_ok hi2
    obtain ⟨c, l', rfl⟩ := List.exists_cons_of_ne_nil hne
    have h0 : (nats p.val)[0]? = some c := by rw [hp]; simp
    simp [nats, List.getElem?_map] at h0
    have : p.val[0]? = some i2 := by simp at hpe; simp [← hpe]
    rw [this] at h0
    simp at h0
    subst hc_2
    simp at h0; subst h0
    simp at h42
  all_goals
    obtain ⟨k, _, _, hk, _⟩ := deep_lit p n false l rest 0#usize 0#usize (by simpa using hp) h42 h63 h
    exact ⟨k, by simpa using hk⟩

theorem deep_end (p n : Slice U8) (s : Bool) (pi ni : Usize) (hpi : p.val.length ≤ pi.val)
    (h : wildmatch.deep_match p pi n ni s = ok true) : n.val.length ≤ ni.val := by
  rw [wildmatch.deep_match] at h
  h5i_invert h
  · simp at h; scalar_tac
  all_goals exfalso; scalar_tac

theorem is_match_exact (p n : Slice U8) (h : wildmatch.is_match p n = ok true)
    (h42 : 42 ∉ nats p.val) (h63 : 63 ∉ nats p.val) : nats n.val = nats p.val := by
  unfold wildmatch.is_match wildmatch.inner_match at h
  h5i_invert h
  · have h1 := congrArg (·.val) hc; simp at h1
    simp at h
    have h2 := congrArg (·.val) h; simp at h2
    simp [nats, h1, h2]
  · exfalso
    obtain ⟨hi, hpe⟩ := slice_index_ok hi2
    apply h42
    subst hc_2
    simp [nats]
    refine ⟨_, List.getElem_mem hi, ?_⟩
    have := congrArg (·.val) hpe
    simpa using this
  all_goals
    obtain ⟨k, pi', ni', hk, hpi, hni, hd⟩ :=
      deep_lit p n false (nats p.val) [] 0#usize 0#usize (by simp) h42 h63 h
    have := deep_end p n false pi' ni' (by simp [nats] at hpi; omega) hd
    simp at hk
    have hl := congrArg List.length hk
    simp [nats] at hl hni
    have : k = [] := by apply List.eq_nil_of_length_eq_zero; omega
    simp [hk, this]

theorem force_delete_needs_explicit_grant (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (h : policies.policy_is_allowed sts a e = ok true) (ho : a.is_owner = false) (hd : a.deny_only = false)
    (hf : IsForceDelete a.action) (hw : ∀ st ∈ sts.val, ∀ x ∈ st.actions.val, UpstreamAction x) :
    ∃ st ∈ sts.val, st.effect = .Allow ∧ ∃ x ∈ st.actions.val, x.name = a.action.name := by
  obtain ⟨st, hst, he, x, hx, hm⟩ := policy_ok sts a e h ho hd hf
  refine ⟨st, hst, he, x, hx, ?_⟩
  obtain ⟨hns3, hmatch⟩ := action_match_ok x a.action hf hm
  obtain ⟨hnone, _, hshape⟩ := hw st hst x hx
  have hfn := hf.2
  rw [lit_FDB, lit_FDO] at hfn
  rcases hshape with hwild | ⟨h42, h63⟩
  · exfalso
    cases hfam : x.family
    · exact hns3 ⟨hfam, by rw [hwild, hfam]; rfl⟩
    all_goals rw [hfam] at hwild
    · obtain ⟨k, hk⟩ := is_match_prefix _ _ hmatch (familyPrefix .Admin) (lit "*")
        (by rw [deref_val]; exact hwild) (by simp [familyPrefix, lit_admin]) (by simp [familyPrefix, lit_admin])
        (by simp [familyPrefix, lit_admin])
      rw [deref_val] at hk
      simp only [familyPrefix, lit_admin] at hk
      rcases hfn with hfn | hfn <;> rw [hfn] at hk <;> simp at hk
    · obtain ⟨k, hk⟩ := is_match_prefix _ _ hmatch (familyPrefix .Sts) (lit "*")
        (by rw [deref_val]; exact hwild) (by simp [familyPrefix, lit_sts]) (by simp [familyPrefix, lit_sts])
        (by simp [familyPrefix, lit_sts])
      rw [deref_val] at hk
      simp only [familyPrefix, lit_sts] at hk
      rcases hfn with hfn | hfn <;> rw [hfn] at hk <;> simp at hk
    · obtain ⟨k, hk⟩ := is_match_prefix _ _ hmatch (familyPrefix .Kms) (lit "*")
        (by rw [deref_val]; exact hwild) (by simp [familyPrefix, lit_kms]) (by simp [familyPrefix, lit_kms])
        (by simp [familyPrefix, lit_kms])
      rw [deref_val] at hk
      simp only [familyPrefix, lit_kms] at hk
      rcases hfn with hfn | hfn <;> rw [hfn] at hk <;> simp at hk
    · have := hnone hfam
      rw [this] at hwild
      simp [nats, familyPrefix, lit_star] at hwild
  · have := is_match_exact _ _ hmatch (by rw [deref_val]; exact h42) (by rw [deref_val]; exact h63)
    rw [deref_val, deref_val] at this
    exact (alloc.vec.Vec.eq_iff _ _).2 (nats_inj this).symm

end rustfs_kernel.Verified.RustfsForceDelete
