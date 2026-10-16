import Verified.RustfsForceDelete
import Verified.RustfsAllowNeedsStatement
import SpecKernel
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit
open rustfs_kernel.Verified.RustfsForceDelete (is_s3_ok deref_val nats_inj lift_slice is_match_exact effect_eq_ok)

/-!
The built-in `readonly` policy allows only its read actions: the statements of
`defaults::default_policies`' `readonly` entry, then evaluation through
`policies::policy_is_allowed`.
-/

namespace rustfs_kernel.Verified.RustfsDefaults

theorem lit_GOV : lit "s3:GetObjectVersion" =
    [115, 51, 58, 71, 101, 116, 79, 98, 106, 101, 99, 116, 86, 101, 114, 115, 105, 111, 110] := by decide +kernel
theorem lit_GO : lit "s3:GetObject" = [115, 51, 58, 71, 101, 116, 79, 98, 106, 101, 99, 116] := by decide +kernel

theorem action_match_general (x a : acts.Action) (h : acts.action_is_match_for_effect x a false = ok true) :
    wildmatch.is_match (alloc.vec.Vec.deref x.name) (alloc.vec.Vec.deref a.name) = ok true := by
  unfold acts.action_is_match_for_effect at h
  h5i_invert h
  all_goals first | assumption | simp_all

theorem set_match_general (set : Slice acts.Action) (a : acts.Action) (i : Usize)
    (h : acts.set_is_match_for_effect_loop set a false i = ok true) :
    ∃ x ∈ set.val, acts.action_is_match_for_effect x a false = ok true ∨
      (nats x.name.val = lit "s3:GetObjectVersion" ∧ nats a.name.val = lit "s3:GetObject") := by
  unfold acts.set_is_match_for_effect_loop at h
  refine loop_true_witness _ (fun _ => True) (fun i : Usize => set.val.length - i.val) _ ?_ i trivial h
  intro x r _ hr
  unfold acts.set_is_match_for_effect_loop.body at hr
  h5i_invert hr
  · intro _
    exact ⟨a1, slice_index_ok_mem ha1, Or.inl (hc_1 ▸ hb)⟩
  · intro _
    have h1 := ((is_s3_ok _ _ _ hb1).1 hc_2).2
    have h2 := ((is_s3_ok _ _ _ hb2).1 hc_3).2
    rw [lift_slice hs] at h1
    rw [lift_slice hs1] at h2
    refine ⟨a1, slice_index_ok_mem ha1, Or.inr ⟨?_, ?_⟩⟩
    · rw [h1, lit_GOV]; rfl
    · rw [h2, lit_GO]; rfl
  all_goals first
    | (simp only [true_and]; have := add_ok_val (by assumption : _ + 1#usize = ok _); scalar_tac)
    | (simp; done)

theorem covers_general (acs nacs : Slice acts.Action) (a : acts.Action) (hne : acs.val ≠ [])
    (h : acts.statement_covers acs nacs a false = ok true) :
    ∃ x ∈ acs.val, acts.action_is_match_for_effect x a false = ok true ∨
      (nats x.name.val = lit "s3:GetObjectVersion" ∧ nats a.name.val = lit "s3:GetObject") := by
  unfold acts.statement_covers at h
  h5i_invert h
  all_goals try simp_all
  all_goals try (exfalso; apply hne; have := congrArg UScalar.val hc_1; simp at this; exact List.eq_nil_of_length_eq_zero this)
  all_goals try (unfold acts.set_is_match_for_effect at h; exact set_match_general _ _ _ h)

theorem stmt_covers (st : stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (hst : st.effect = .Allow) (h : stmts.statement_is_allowed st a e = ok true) :
    acts.statement_covers (alloc.vec.Vec.deref st.actions) (alloc.vec.Vec.deref st.not_actions) a.action false
      = ok true := by
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
    · exact hc




theorem vec_slice_val' {α} (v : alloc.vec.Vec α) : v.slice.val = v.val := rfl

@[simp] theorem from_slice_eq {α} {n : Usize} (l : List α) (h) (v : alloc.vec.Vec α) :
    (Array.from (n := n) l h).to_slice = v.slice ↔ v.val = l := by
  constructor
  · intro hs
    have := congrArg Slice.val hs
    rw [array_to_slice_val, Array.from_val, vec_slice_val'] at this
    exact this.symm
  · intro hv
    apply Slice.ext
    rw [array_to_slice_val, Array.from_val, vec_slice_val', hv]


@[simp] theorem litk_0 : lit "KMSAuditor" = [75, 77, 83, 65, 117, 100, 105, 116, 111, 114] := by decide +kernel
@[simp] theorem litk_1 : lit "KMSKeyAdministrator" = [75, 77, 83, 75, 101, 121, 65, 100, 109, 105, 110, 105, 115, 116, 114, 97, 116, 111, 114] := by decide +kernel
@[simp] theorem litk_2 : lit "KMSKeyUser" = [75, 77, 83, 75, 101, 121, 85, 115, 101, 114] := by decide +kernel
@[simp] theorem litk_3 : lit "admin:BandwidthMonitor" = [97, 100, 109, 105, 110, 58, 66, 97, 110, 100, 119, 105, 100, 116, 104, 77, 111, 110, 105, 116, 111, 114] := by decide +kernel
@[simp] theorem litk_4 : lit "admin:ConsoleLog" = [97, 100, 109, 105, 110, 58, 67, 111, 110, 115, 111, 108, 101, 76, 111, 103] := by decide +kernel
@[simp] theorem litk_5 : lit "admin:OBDInfo" = [97, 100, 109, 105, 110, 58, 79, 66, 68, 73, 110, 102, 111] := by decide +kernel
@[simp] theorem litk_6 : lit "admin:Profiling" = [97, 100, 109, 105, 110, 58, 80, 114, 111, 102, 105, 108, 105, 110, 103] := by decide +kernel
@[simp] theorem litk_7 : lit "admin:Prometheus" = [97, 100, 109, 105, 110, 58, 80, 114, 111, 109, 101, 116, 104, 101, 117, 115] := by decide +kernel
@[simp] theorem litk_8 : lit "admin:ServerInfo" = [97, 100, 109, 105, 110, 58, 83, 101, 114, 118, 101, 114, 73, 110, 102, 111] := by decide +kernel
@[simp] theorem litk_9 : lit "admin:ServerTrace" = [97, 100, 109, 105, 110, 58, 83, 101, 114, 118, 101, 114, 84, 114, 97, 99, 101] := by decide +kernel
@[simp] theorem litk_10 : lit "admin:TopLocksInfo" = [97, 100, 109, 105, 110, 58, 84, 111, 112, 76, 111, 99, 107, 115, 73, 110, 102, 111] := by decide +kernel
@[simp] theorem litk_11 : lit "diagnostics" = [100, 105, 97, 103, 110, 111, 115, 116, 105, 99, 115] := by decide +kernel
@[simp] theorem litk_12 : lit "kms:Decrypt" = [107, 109, 115, 58, 68, 101, 99, 114, 121, 112, 116] := by decide +kernel
@[simp] theorem litk_13 : lit "kms:DeleteKey" = [107, 109, 115, 58, 68, 101, 108, 101, 116, 101, 75, 101, 121] := by decide +kernel
@[simp] theorem litk_14 : lit "kms:DescribeKey" = [107, 109, 115, 58, 68, 101, 115, 99, 114, 105, 98, 101, 75, 101, 121] := by decide +kernel
@[simp] theorem litk_15 : lit "kms:DisableKey" = [107, 109, 115, 58, 68, 105, 115, 97, 98, 108, 101, 75, 101, 121] := by decide +kernel
@[simp] theorem litk_16 : lit "kms:EnableKey" = [107, 109, 115, 58, 69, 110, 97, 98, 108, 101, 75, 101, 121] := by decide +kernel
@[simp] theorem litk_17 : lit "kms:GenerateDataKey" = [107, 109, 115, 58, 71, 101, 110, 101, 114, 97, 116, 101, 68, 97, 116, 97, 75, 101, 121] := by decide +kernel
@[simp] theorem litk_18 : lit "kms:ListKeys" = [107, 109, 115, 58, 76, 105, 115, 116, 75, 101, 121, 115] := by decide +kernel
@[simp] theorem litk_19 : lit "kms:RotateKey" = [107, 109, 115, 58, 82, 111, 116, 97, 116, 101, 75, 101, 121] := by decide +kernel
@[simp] theorem litk_20 : lit "readonly" = [114, 101, 97, 100, 111, 110, 108, 121] := by decide +kernel
@[simp] theorem litk_21 : lit "s3:GetBucketLocation" = [115, 51, 58, 71, 101, 116, 66, 117, 99, 107, 101, 116, 76, 111, 99, 97, 116, 105, 111, 110] := by decide +kernel
@[simp] theorem litk_22 : lit "s3:GetBucketQuota" = [115, 51, 58, 71, 101, 116, 66, 117, 99, 107, 101, 116, 81, 117, 111, 116, 97] := by decide +kernel
@[simp] theorem litk_23 : lit "s3:GetObject" = [115, 51, 58, 71, 101, 116, 79, 98, 106, 101, 99, 116] := by decide +kernel
@[simp] theorem litk_24 : lit "s3:GetObjectVersion" = [115, 51, 58, 71, 101, 116, 79, 98, 106, 101, 99, 116, 86, 101, 114, 115, 105, 111, 110] := by decide +kernel
@[simp] theorem litk_25 : lit "s3:PutObject" = [115, 51, 58, 80, 117, 116, 79, 98, 106, 101, 99, 116] := by decide +kernel
@[simp] theorem litk_26 : lit "sts:AssumeRole" = [115, 116, 115, 58, 65, 115, 115, 117, 109, 101, 82, 111, 108, 101] := by decide +kernel
@[simp] theorem litk_27 : lit "writeonly" = [119, 114, 105, 116, 101, 111, 110, 108, 121] := by decide +kernel

@[step] theorem allow_spec (acs : alloc.vec.Vec acts.Action) (rs : alloc.vec.Vec rsrc.Resource) :
    defaults.allow acs rs ⦃ st => st.effect = .Allow ∧ st.actions = acs ∧ st.not_actions.val = [] ⦄ := by
  unfold defaults.allow; step*; try simp_all

@[step] theorem kms_allow_spec (acs : alloc.vec.Vec acts.Action) :
    defaults.kms_allow acs ⦃ st => st.effect = .Allow ∧ st.actions = acs ∧ st.not_actions.val = [] ⦄ := by
  unfold defaults.kms_allow defaults.all_kms_keys; step*; all_goals first | scalar_tac | simp_all

@[step] theorem assume_role_allow_spec :
    defaults.assume_role_allow ⦃ st => st.effect = .Allow ∧ st.not_actions.val = [] ∧ st.actions.val ≠ [] ∧
      ∀ ac ∈ st.actions.val, nats ac.name.val = lit "sts:AssumeRole" ⦄ := by
  unfold defaults.assume_role_allow; step*
  all_goals first | scalar_tac | skip
  all_goals (subst_vars; simp_all [nats, Array.make])

@[step] theorem version_spec : defaults.default_version ⦃ _ => True ⦄ := by
  unfold defaults.default_version; step*

@[step] theorem kms_key_administrator_spec : defaults.kms_key_administrator ⦃ v => v.val = [75#u8, 77#u8, 83#u8, 75#u8, 101#u8, 121#u8, 65#u8, 100#u8, 109#u8, 105#u8, 110#u8, 105#u8, 115#u8, 116#u8, 114#u8, 97#u8, 116#u8, 111#u8, 114#u8] ⦄ := by
  unfold defaults.kms_key_administrator; step*; all_goals (subst_vars; simp_all [Array.make])
@[step] theorem kms_key_user_spec : defaults.kms_key_user ⦃ v => v.val = [75#u8, 77#u8, 83#u8, 75#u8, 101#u8, 121#u8, 85#u8, 115#u8, 101#u8, 114#u8] ⦄ := by
  unfold defaults.kms_key_user; step*; all_goals (subst_vars; simp_all [Array.make])
@[step] theorem kms_auditor_spec : defaults.kms_auditor ⦃ v => v.val = [75#u8, 77#u8, 83#u8, 65#u8, 117#u8, 100#u8, 105#u8, 116#u8, 111#u8, 114#u8] ⦄ := by
  unfold defaults.kms_auditor; step*; all_goals (subst_vars; simp_all [Array.make])

/-- Every statement of the built-in policy named `pname` is an Allow without
`NotAction` whose (non-empty) action list names only actions in `names`. -/
def AllowsOnlyNames (ps : List (alloc.vec.Vec U8 × defaults.Policy)) (pname : List Nat) (names : List (List Nat)) : Prop :=
  ∀ x ∈ ps, nats x.1.val = pname →
    ∀ st ∈ x.2.statements.val, st.effect = .Allow ∧ st.not_actions.val = [] ∧ st.actions.val ≠ [] ∧
      ∀ ac ∈ st.actions.val, nats ac.name.val ∈ names

/-- `AllowsOnlyNames` for every policy listed in `builtinOnly`. -/
def BuiltinOK (ps : List (alloc.vec.Vec U8 × defaults.Policy)) : Prop :=
  ∀ p ∈ builtinOnly, AllowsOnlyNames ps p.1 p.2

set_option maxRecDepth 200000 in
set_option maxHeartbeats 160000000 in
theorem builtin_statements : defaults.default_policies ⦃ ps => BuiltinOK ps.val ⦄ := by
  unfold defaults.default_policies
  step*
  all_goals try scalar_tac
  all_goals try (subst_vars; simp_all [Array.make]; scalar_tac)
  unfold BuiltinOK AllowsOnlyNames
  intro p hp x hx hn st hst
  subst_vars
  simp only [*, alloc.vec.Vec.new, alloc.vec.Vec.from_val, List.mem_append, List.mem_cons, List.mem_singleton,
    List.not_mem_nil, or_false, false_or, or_assoc, List.nil_append] at hx
  simp only [builtinOnly, List.mem_cons, List.not_mem_nil, or_false] at hp
  rcases hp with rfl | rfl | rfl | rfl | rfl | rfl <;>
    rcases hx with h | h | h | h | h | h | h | h <;> subst h <;>
    (try simp_all [nats, Array.make, readonlyNames, writeonlyNames, diagnosticsNames, kmsAdministratorNames,
      kmsUserNames, kmsAuditorNames]) <;>
    (rcases hst with rfl | rfl <;> simp_all [nats, Array.make, readonlyNames, writeonlyNames, diagnosticsNames,
      kmsAdministratorNames, kmsUserNames, kmsAuditorNames])

/-- The names of the listed built-in policies have no wildcard and are not
`s3:GetObjectVersion` (which also covers `s3:GetObject`). -/
theorem builtin_names_plain : ∀ q ∈ builtinOnly, ∀ n ∈ q.2, 42 ∉ n ∧ 63 ∉ n ∧ n ≠ lit "s3:GetObjectVersion" := by
  simp only [builtinOnly, readonlyNames, writeonlyNames, diagnosticsNames, kmsAdministratorNames, kmsUserNames,
    kmsAuditorNames, litk_0, litk_1, litk_2, litk_3, litk_4, litk_5, litk_6, litk_7, litk_8, litk_9, litk_10,
    litk_11, litk_12, litk_13, litk_14, litk_15, litk_16, litk_17, litk_18, litk_19, litk_20, litk_21, litk_22,
    litk_23, litk_24, litk_25, litk_26, litk_27]
  decide

/-- When a listed built-in policy allows a request (not as owner, not
deny-only), the action is one the policy names. -/
theorem builtin_allows_only_listed (ps : alloc.vec.Vec (alloc.vec.Vec U8 × defaults.Policy))
    (hps : defaults.default_policies = ok ps) (q : List Nat × List (List Nat)) (hq : q ∈ builtinOnly)
    (x : alloc.vec.Vec U8 × defaults.Policy) (hx : x ∈ ps.val) (hn : nats x.1.val = q.1)
    (a : stmts.Args) (e : condfuncs.Env)
    (h : policies.policy_is_allowed (alloc.vec.Vec.deref x.2.statements) a e = ok true)
    (ho : a.is_owner = false) (hd : a.deny_only = false) :
    nats a.action.name.val ∈ q.2 := by
  have hok : AllowsOnlyNames ps.val q.1 q.2 := by
    have := builtin_statements
    rw [hps, WP.spec_ok] at this
    exact this q hq
  obtain ⟨st, hst, he, hsa⟩ :=
    rustfs_kernel.Verified.RustfsAllowNeedsStatement.allow_needs_allow_statement _ a e h ho hd
  rw [deref_val] at hst
  obtain ⟨_, _, hne, hacts⟩ := hok x hx hn st hst
  have hc := stmt_covers st a e he hsa
  obtain ⟨y, hy, hm | ⟨hgov, _⟩⟩ := covers_general _ _ _ (by rwa [deref_val]) hc
  · rw [deref_val] at hy
    have hyn := hacts y hy
    obtain ⟨h42, h63, _⟩ := builtin_names_plain q hq _ hyn
    have := is_match_exact _ _ (action_match_general _ _ hm) (by rwa [deref_val]) (by rwa [deref_val])
    rw [deref_val, deref_val] at this
    rw [this]; exact hyn
  · exfalso
    rw [deref_val] at hy
    exact (builtin_names_plain q hq _ (hacts y hy)).2.2 hgov

/-- The `readonly` case of `builtin_allows_only_listed`. -/
theorem readonly_allows_only_reads (ps : alloc.vec.Vec (alloc.vec.Vec U8 × defaults.Policy))
    (hps : defaults.default_policies = ok ps) (x : alloc.vec.Vec U8 × defaults.Policy) (hx : x ∈ ps.val)
    (hn : nats x.1.val = lit "readonly") (a : stmts.Args) (e : condfuncs.Env)
    (h : policies.policy_is_allowed (alloc.vec.Vec.deref x.2.statements) a e = ok true)
    (ho : a.is_owner = false) (hd : a.deny_only = false) :
    nats a.action.name.val ∈ readonlyNames :=
  builtin_allows_only_listed ps hps (lit "readonly", readonlyNames) (by simp [builtinOnly]) x hx hn a e h ho hd

end rustfs_kernel.Verified.RustfsDefaults
