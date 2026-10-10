import Verified.RustfsGetObjectVersion
import Verified.RustfsNotActionForceDelete
import Verified.RustfsExplicitDeny
import Verified.RustfsAllowNeedsStatement
import Verified.RustfsOwner
import Verified.RustfsDenyOnly
import Verified.RustfsForceDelete
import Verified.RustfsBucketPrincipal
import Verified.RustfsWildcard
import Spec
open Aeneas Aeneas.Std Result rustfs_kernel rustfs_kernel.Spec
open H5iAppLib hiding lit

namespace rustfs_kernel.Properties

/-! ## Identity policies (`Policy::is_allowed`) -/

/-- An explicit Deny that applies refuses the request, whatever else the
policy allows. -/
theorem explicit_deny_wins (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (st : stmts.Statement) (hm : st ∈ sts.val) (hd : st.effect = .Deny)
    (hs : stmts.statement_is_allowed st a e = ok false) :
    policies.policy_is_allowed sts a e ≠ ok true := by
  apply rustfs_kernel.Verified.RustfsExplicitDeny.explicit_deny_wins <;> assumption

/-- Unless the caller owns the resource or only denials are checked, an
allowed request has an Allow statement that applies. -/
theorem allow_needs_allow_statement (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (h : policies.policy_is_allowed sts a e = ok true) (ho : a.is_owner = false) (hd : a.deny_only = false) :
    ∃ st ∈ sts.val, st.effect = .Allow ∧ stmts.statement_is_allowed st a e = ok true := by
  apply rustfs_kernel.Verified.RustfsAllowNeedsStatement.allow_needs_allow_statement <;> assumption

/-- An owner is allowed unless a Deny applies. -/
theorem owner_allowed_unless_denied (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (ho : a.is_owner = true)
    (hd : ∀ st ∈ sts.val, st.effect = .Deny → stmts.statement_is_allowed st a e = ok true) :
    policies.policy_is_allowed sts a e = ok true := by
  apply rustfs_kernel.Verified.RustfsOwner.owner_allowed_unless_denied <;> assumption

/-- With `deny_only`, Allow statements play no part: a request no Deny
refuses is allowed. -/
theorem deny_only_ignores_allows (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (ho : a.deny_only = true)
    (hd : ∀ st ∈ sts.val, st.effect = .Deny → stmts.statement_is_allowed st a e = ok true) :
    policies.policy_is_allowed sts a e = ok true := by
  apply rustfs_kernel.Verified.RustfsDenyOnly.deny_only_ignores_allows <;> assumption

/-- Force-delete is granted only by an Allow statement that names it:
`s3:*` and `NotAction` statements never grant it. The statements' actions are
ones upstream can parse; the port's wider `(family, name)` would let e.g.
`(Admin, "*")` match force-delete by wildcard. -/
theorem force_delete_needs_explicit_grant (sts : Slice stmts.Statement) (a : stmts.Args) (e : condfuncs.Env)
    (h : policies.policy_is_allowed sts a e = ok true) (ho : a.is_owner = false) (hd : a.deny_only = false)
    (hf : IsForceDelete a.action) (hw : ∀ st ∈ sts.val, ∀ x ∈ st.actions.val, UpstreamAction x) :
    ∃ st ∈ sts.val, st.effect = .Allow ∧ ∃ x ∈ st.actions.val, x.name = a.action.name := by
  apply rustfs_kernel.Verified.RustfsForceDelete.force_delete_needs_explicit_grant <;> assumption

/-- An Allow whose action list is empty (a `NotAction` statement) never
covers a force-delete. -/
theorem not_action_never_grants_force_delete (none not : Slice acts.Action) (x : acts.Action)
    (hn : none.val = []) (hf : IsForceDelete x) :
    acts.statement_covers none not x false = ok false := by
  apply rustfs_kernel.Verified.RustfsNotActionForceDelete.not_action_never_grants_force_delete <;> assumption

/-- A statement naming `s3:GetObjectVersion` also covers `s3:GetObject`, for
Allow and Deny alike. -/
theorem get_object_version_covers_get_object (s n : Slice acts.Action) (g o : acts.Action) (deny : Bool)
    (hs : s.val = [g]) (hn : n.val = [])
    (hg : g.family = .S3 ∧ nats g.name.val = lit "s3:GetObjectVersion")
    (hgo : o.family = .S3 ∧ nats o.name.val = lit "s3:GetObject") :
    acts.statement_covers s n o deny = ok true := by
  apply rustfs_kernel.Verified.RustfsGetObjectVersion.get_object_version_covers_get_object <;> assumption

/-! ## Bucket policies (`BucketPolicy::is_allowed`) -/

/-- A non-owner is allowed by a bucket policy only through an Allow statement
whose principal matches the account. -/
theorem bucket_allow_needs_principal (sts : Slice stmts.BPStatement) (a : stmts.BucketPolicyArgs)
    (e : condfuncs.Env) (h : policies.bucket_policy_is_allowed sts a e = ok true) (ho : a.is_owner = false) :
    ∃ st ∈ sts.val, st.effect = .Allow ∧ stmts.principal_is_match st.principal a.account.deref = ok true ∧
      stmts.bp_statement_is_allowed st a e = ok true := by
  apply rustfs_kernel.Verified.RustfsBucketPrincipal.bucket_allow_needs_principal <;> assumption

/-- Bucket policy evaluation always terminates without a panic, for an S3
bucket name of at most 63 bytes and an object key of at most 1024, the limits
S3 enforces before policy evaluation; for condition keys whose lookup name
(`name/variable`) fits in a `Vec`; and for request condition values of at most
8 KiB (header-sized) and resource patterns of at most 20 KiB (S3's bucket policy
size limit), since the substituted pattern grows with both. Without them a bucket name or key name
of `Usize.max` bytes exceeds a `Vec`'s capacity. -/
theorem bucket_policy_total (sts : Slice stmts.BPStatement) (a : stmts.BucketPolicyArgs) (e : condfuncs.Env)
    (hb : a.bucket.length ≤ 63) (ho : a.object.length ≤ 1024)
    (hk : ∀ st ∈ sts.val, ∀ c ∈ st.conditions.for_any_value.val ++ st.conditions.for_all_values.val ++
        st.conditions.for_normal.val,
      ∀ k ∈ (match c.cond with
        | .Str _ l => l.val.map Prod.fst | .Ip _ l => l.val.map Prod.fst | .Null l => l.val.map Prod.fst
        | .Bool l => l.val.map Prod.fst | .Num _ _ l => l.val.map Prod.fst),
      ∀ v, k.variable = some v → k.name.length + v.length < Usize.max)
    (hc : ∀ kv ∈ a.conditions.val, ∀ v ∈ kv.2.val, v.length ≤ 8192)
    (hr : ∀ st ∈ sts.val, ∀ r ∈ st.resources.val ++ st.not_resources.val,
      (match r with | .S3 p => p.length | .Kms p => p.length) ≤ 20480) :
    ∃ r, policies.bucket_policy_is_allowed sts a e = ok r := by
  sorry

/-! ## Matchers and parsers -/

/-- `wildcard::is_match` is the glob `globSpec`. -/
theorem wildcard_is_glob (p n : Slice U8) :
    wildmatch.is_match p n = ok (globSpec (nats p.val) (nats n.val)) := by
  apply rustfs_kernel.Verified.RustfsWildcard.wildcard_is_glob <;> assumption

/-- `path::clean` is idempotent. -/
theorem clean_idempotent (p : Slice U8) (c : alloc.vec.Vec U8) (h : pathclean.clean p = ok c) :
    pathclean.clean c.deref = ok c := by
  sorry

/-- A cleaned path has no empty or `.` segment. -/
theorem clean_canonical (p : Slice U8) (c : alloc.vec.Vec U8) (h : pathclean.clean p = ok c) :
    CleanShape (nats c.val) := by
  sorry

/-- The condition parser reads integers as `str::parse::<i64>` does. -/
theorem parse_i64_spec (s : Slice U8) :
    ∃ r, bytes.parse_i64 s = ok r ∧ r.map (·.val) = parseI64Spec (nats s.val) := by
  sorry

/-! ## Policy variables -/

/-- Variable resolution terminates when no value it substitutes contains a
variable reference: it returns, or fails, but does not diverge. It can fail:
each `${aws:userid}` yields one result per claim value, so the results can
outgrow `Usize.max` (in Rust, a capacity-overflow panic or out of memory). -/
theorem resolution_terminates (ctx : awsvars.VarContext) (p : Slice U8) (hv : PlainValues ctx) :
    (∃ r, awsvars.resolve_aws_variables ctx p = ok r) ∨
      ∃ err, awsvars.resolve_aws_variables ctx p = fail err := by
  sorry

end rustfs_kernel.Properties
