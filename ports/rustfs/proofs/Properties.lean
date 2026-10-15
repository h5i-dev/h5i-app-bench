import Verified.RustfsBase64
import Verified.RustfsValids
import Verified.RustfsCondData
import Verified.RustfsConditionEval
import Verified.RustfsConditionNames
import Verified.RustfsConditionEquality
import Verified.RustfsCompleteConditionEquality
import Verified.RustfsConditionGroups
import Verified.RustfsConditionCopies
import Verified.RustfsConditionViews
import Verified.RustfsDefaults
import SpecKernel
import Verified.RustfsCleanIdempotent
import Verified.RustfsCleanCanonical
import Verified.RustfsParseI64
import Verified.RustfsResolutionTerminates
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

/-! ## Matchers and parsers -/

/-- `wildcard::is_match` is the glob `globSpec`. -/
theorem wildcard_is_glob (p n : Slice U8) :
    wildmatch.is_match p n = ok (globSpec (nats p.val) (nats n.val)) := by
  apply rustfs_kernel.Verified.RustfsWildcard.wildcard_is_glob <;> assumption

/-- `path::clean` is idempotent. -/
theorem clean_idempotent (p : Slice U8) (c : alloc.vec.Vec U8) (h : pathclean.clean p = ok c) :
    pathclean.clean c.deref = ok c := by
  apply rustfs_kernel.Verified.RustfsCleanIdempotent.clean_idempotent <;> assumption

/-- A cleaned path has no empty or `.` segment. -/
theorem clean_canonical (p : Slice U8) (c : alloc.vec.Vec U8) (h : pathclean.clean p = ok c) :
    CleanShape (nats c.val) := by
  apply rustfs_kernel.Verified.RustfsCleanCanonical.clean_canonical <;> assumption

/-- The condition parser reads integers as `str::parse::<i64>` does. -/
theorem parse_i64_spec (s : Slice U8) :
    ∃ r, bytes.parse_i64 s = ok r ∧ r.map (·.val) = parseI64Spec (nats s.val) := by
  apply rustfs_kernel.Verified.RustfsParseI64.parse_i64_spec <;> assumption

/-! ## Policy variables -/

/-- Variable resolution terminates when no value it substitutes contains a
variable reference: it returns, or fails, but does not diverge. It can fail:
each `${aws:userid}` yields one result per claim value, so the results can
outgrow `Usize.max` (in Rust, a capacity-overflow panic or out of memory). -/
theorem resolution_terminates (ctx : awsvars.VarContext) (p : Slice U8) (hv : PlainValues ctx) :
    (∃ r, awsvars.resolve_aws_variables ctx p = ok r) ∨
      ∃ err, awsvars.resolve_aws_variables ctx p = fail err := by
  apply rustfs_kernel.Verified.RustfsResolutionTerminates.resolution_terminates <;> assumption

/-! ## Built-in policies (`defaults`) -/

/-- When the built-in `readonly` policy allows a request (not as owner, not
deny-only), the action is one of the policy's read actions: `s3:GetBucketLocation`,
`s3:GetObject`, `s3:GetBucketQuota` or `sts:AssumeRole`. -/
theorem readonly_allows_only_reads (ps : alloc.vec.Vec (alloc.vec.Vec U8 × defaults.Policy))
    (hps : defaults.default_policies = ok ps) (x : alloc.vec.Vec U8 × defaults.Policy) (hx : x ∈ ps.val)
    (hn : nats x.1.val = lit "readonly") (a : stmts.Args) (e : condfuncs.Env)
    (h : policies.policy_is_allowed (alloc.vec.Vec.deref x.2.statements) a e = ok true)
    (ho : a.is_owner = false) (hd : a.deny_only = false) :
    nats a.action.name.val ∈ readonlyNames := by
  apply rustfs_kernel.Verified.RustfsDefaults.readonly_allows_only_reads <;> assumption

/-- The built-in policies that name their actions exactly (`readonly`,
`writeonly`, `diagnostics`, `KMSKeyAdministrator`, `KMSKeyUser`, `KMSAuditor`)
allow, apart from owners and deny-only checks, only the actions they name. -/
theorem builtin_allows_only_listed (ps : alloc.vec.Vec (alloc.vec.Vec U8 × defaults.Policy))
    (hps : defaults.default_policies = ok ps) (q : List Nat × List (List Nat)) (hq : q ∈ builtinOnly)
    (x : alloc.vec.Vec U8 × defaults.Policy) (hx : x ∈ ps.val) (hn : nats x.1.val = q.1)
    (a : stmts.Args) (e : condfuncs.Env)
    (h : policies.policy_is_allowed (alloc.vec.Vec.deref x.2.statements) a e = ok true)
    (ho : a.is_owner = false) (hd : a.deny_only = false) :
    nats a.action.name.val ∈ q.2 := by
  apply rustfs_kernel.Verified.RustfsDefaults.builtin_allows_only_listed <;> assumption

/-! ## Validation (`valids`) -/

/-- `Resource::is_valid` accepts exactly the patterns of `resourceOK`: a
nonempty S3 pattern not starting with `/`, or a KMS `*`, `key/<id>` or
`alias/<name>` without backslashes. -/
theorem resource_valid_iff (x : rsrc.Resource) (o : core.result.Result Unit valids.ValidationError)
    (h : valids.resource_is_valid x = ok o) : (o = .Ok () ↔ resourceOK x) := by
  apply rustfs_kernel.Verified.RustfsValids.resource_ok <;> assumption

/-- `BPStatement::is_valid` accepts exactly the statements of `BPStatementOK`:
a principal, exactly one of `Action`/`NotAction` and of `Resource`/`NotResource`,
no KMS action or resource, and every resource pattern valid. -/
theorem bp_statement_valid_iff (st : stmts.BPStatement) (sid : Slice U8)
    (o : core.result.Result Unit valids.ValidationError)
    (h : valids.bp_statement_is_valid st sid = ok o) : (o = .Ok () ↔ BPStatementOK st) := by
  apply rustfs_kernel.Verified.RustfsValids.bp_statement_ok <;> assumption

/-- `Statement::action_family` reports `Mixed` for a nonempty `Action` list
exactly when the actions do not all belong to one family. -/
theorem action_family_mixed_iff (st : stmts.Statement) (o : Option valids.ActionFamily)
    (h : valids.action_family st = ok o) (hne : st.actions.val ≠ []) :
    (o = some .Mixed ↔ ¬ ∃ f, UniformFamily st.actions.val f) := by
  apply rustfs_kernel.Verified.RustfsValids.action_family_mixed <;> assumption

/-- Validation enforces action-family and resource boundaries. -/
theorem statement_valid_iff (st : stmts.Statement) (sid : Slice U8)
    (o : core.result.Result Unit valids.ValidationError)
    (h : valids.statement_is_valid st sid = ok o) : (o = .Ok () ↔ StatementOK st) := by
  exact rustfs_kernel.Verified.RustfsValids.statement_ok st sid o h

/-- Admin classification requires an explicitly selected Admin action. -/
theorem statement_admin_iff (st : stmts.Statement) (b : Bool)
    (h : valids.is_admin st = ok b) : (b = true ↔ ∃ a ∈ st.actions.val, a.family = .Admin) := by
  exact rustfs_kernel.Verified.RustfsValids.is_admin_ok st b h

/-- STS classification requires an explicitly selected STS action. -/
theorem statement_sts_iff (st : stmts.Statement) (b : Bool)
    (h : valids.is_sts st = ok b) : (b = true ↔ ∃ a ∈ st.actions.val, a.family = .Sts) := by
  exact rustfs_kernel.Verified.RustfsValids.is_sts_ok st b h

/-- ID views preserve bytes and emptiness; default validation is unconditional. -/
theorem validation_interfaces (id : Slice U8) (b : Bool) (view : Slice U8)
    (he : valids.id_is_empty id = ok b) (hv : valids.id_as_slice id = ok view) :
    (b = true ↔ id.val = []) ∧ view = id ∧ valids.default_is_valid = ok true := by
  obtain ⟨hempty, hview⟩ := rustfs_kernel.Verified.RustfsValids.id_interface id b view he hv
  exact ⟨hempty, hview, rustfs_kernel.Verified.RustfsValids.default_valid⟩

/-- Full condition-key membership ignores variable suffixes. -/
theorem condition_key_membership_iff {T : Type} (f : conddata.InnerFunc T) (needle : Slice U8) (b : Bool)
    (h : conddata.contains_key_name f needle = ok b) :
    (b = true ↔ ∃ e ∈ f.entries.val, e.key.key_name.val = needle.val) := by
  exact rustfs_kernel.Verified.RustfsCondData.contains_key_name_ok f needle b h

/-- A condition key's two names and optional suffix all participate in equality. -/
theorem condition_key_equality_iff (a c : condfuncs.Key) (b : Bool) (h : conddata.key_eq a c = ok b) :
    (b = true ↔ a.key_name.val = c.key_name.val ∧ a.name.val = c.name.val ∧
      a.variable.map (·.val) = c.variable.map (·.val)) := by
  exact rustfs_kernel.Verified.RustfsCondData.key_eq_ok a c b h

/-- String condition sets have equal membership regardless of order or duplication. -/
theorem condition_string_set_equality_iff (l r : Slice (alloc.vec.Vec U8)) (b : Bool)
    (h : conddata.string_set_eq l r = ok b) :
    (b = true ↔ (∀ x ∈ l.val, ∃ y ∈ r.val, y.val = x.val) ∧
      (∀ y ∈ r.val, ∃ x ∈ l.val, x.val = y.val)) := by
  exact rustfs_kernel.Verified.RustfsCondData.string_set_eq_ok l r b h

/-- Empty condition groups and negative IP classification are literal. -/
theorem condition_structure_iff (f : conddata.Functions) (c : conddata.Condition) (empty neg : Bool)
    (he : conddata.is_empty f = ok empty) (hn : conddata.is_negate c = ok neg) :
    (empty = true ↔ f.for_any_value.val = [] ∧ f.for_all_values.val = [] ∧ f.for_normal.val = []) ∧
    (neg = true ↔ c.wrappers.val = 0 ∧ c.op = .NotIpAddress) := by
  exact ⟨rustfs_kernel.Verified.RustfsCondData.empty_ok f empty he,
    rustfs_kernel.Verified.RustfsCondData.negate_ok c neg hn⟩

/-- Base64 digit decoding is exact for the STANDARD alphabet. -/
theorem base64_symbol_iff (c : U8) (o : Option U8) (h : conddata.base64_digit c = ok o) :
    ∀ i : U8, o = some i ↔ Base64Symbol c.val i.val := by
  exact rustfs_kernel.Verified.RustfsCondData.base64_digit_ok c o h

/-- Invalid alphabet bytes are rejected and returned indices fit six bits. -/
theorem base64_symbol_boundary (c : U8) (o : Option U8) (h : conddata.base64_digit c = ok o) :
    (∀ i, o = some i → i.val < 64) ∧ (o = none ↔ ¬ ∃ i : U8, Base64Symbol c.val i.val) := by
  exact rustfs_kernel.Verified.RustfsCondData.base64_digit_boundary c o h

/-- Lookup keys and their enumeration preserve the optional variable suffix. -/
theorem condition_lookup_names_exact {T : Type} (k : condfuncs.Key)
    (v : alloc.vec.Vec U8) (f : conddata.InnerFunc T) (names : alloc.vec.Vec (alloc.vec.Vec U8))
    (hk : condfuncs.key_lookup_name k = ok v) (hf : conddata.key_names f = ok names) :
    v.val = LookupName k ∧ names.val.map (·.val) = f.entries.val.map (fun e => LookupName e.key) := by
  exact ⟨rustfs_kernel.Verified.RustfsConditionEval.lookup_name_ok k v hk,
    rustfs_kernel.Verified.RustfsConditionEval.key_names_ok f names hf⟩

/-- A present request key is detected even when its value list is empty. -/
theorem request_key_presence_iff
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (needle : Slice U8) (o : Option (alloc.vec.Vec (alloc.vec.Vec U8)))
    (h : condfuncs.get_value values needle = ok o) :
    (o.isSome = true ↔ ∃ e ∈ values.val, e.1.val = needle.val) := by
  exact rustfs_kernel.Verified.RustfsConditionEval.get_value_present_ok values needle o h

/-- Presence depends on condition lookup names across all data variants. -/
theorem condition_request_key_presence_iff (c : conddata.Condition)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (b : Bool) (h : conddata.has_any_key_in c values = ok b) :
    (b = true ↔ RequestHasConditionKey c values) := by
  exact rustfs_kernel.Verified.RustfsConditionEval.has_any_key_ok c values b h

/-- Wrapped conditions accept a request when all associated keys are absent. -/
theorem wrapped_condition_missing_keys_accept (c : conddata.Condition) (q : condfuncs.Quantifier)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (env : condfuncs.Env) (b : Bool)
    (hw : 0 < c.wrappers.val) (hm : ¬ RequestHasConditionKey c values)
    (h : conddata.condition_evaluate c q values ctx env = ok b) : b = true := by
  exact rustfs_kernel.Verified.RustfsConditionEval.missing_wrapped_key_ok c q values ctx env b hw hm h

/-- Table characterization: condition operators have canonical policy spellings. -/
theorem condition_operator_name_exact (op : conddata.Op) (v : alloc.vec.Vec U8)
    (h : conddata.op_name op = ok v) : nats v.val = lit (OpSpelling op) := by
  exact rustfs_kernel.Verified.RustfsConditionNames.op_name_ok op v h

/-- Serialization preserves one IfExists suffix per wrapper, including nesting. -/
theorem condition_wrapped_name_exact (c : conddata.Condition) (v : alloc.vec.Vec U8)
    (h : conddata.to_key_with_suffix c = ok v) : nats v.val = ConditionKeyName c := by
  exact rustfs_kernel.Verified.RustfsConditionNames.suffixed_key_ok c v h

/-- Table structure: canonical operator spellings uniquely identify their operators. -/
theorem condition_operator_names_injective (a b : conddata.Op) :
    OpSpelling a = OpSpelling b ↔ a = b := by
  cases a <;> cases b <;> decide

/-- String condition entries retain key order and compare values as sets. -/
theorem condition_string_equality_iff (a b : conddata.InnerFunc (alloc.vec.Vec (alloc.vec.Vec U8)))
    (r : Bool) (h : conddata.string_inner_eq a b = ok r) :
    (r = true ↔ SameStringCondition a b) := by
  exact rustfs_kernel.Verified.RustfsConditionEquality.string_inner_ok a b r h

/-- Numeric condition entries compare key fields and numeric values exactly. -/
theorem condition_numeric_equality_iff (a b : conddata.InnerFunc (I64))
    (r : Bool) (h : conddata.num_inner_eq a b = ok r) :
    (r = true ↔ SameNumberCondition a b) := by
  exact rustfs_kernel.Verified.RustfsConditionEquality.num_inner_ok a b r h

/-- Date condition equality compares instants independently of source offsets. -/
theorem condition_date_equality_iff (a b : conddata.InnerFunc (conddata.DateFuncValue))
    (r : Bool) (h : conddata.date_inner_eq a b = ok r) :
    (r = true ↔ SameDateCondition a b) := by
  exact rustfs_kernel.Verified.RustfsConditionEquality.date_inner_ok a b r h

/-- Binary condition equality compares decoded sequences in entry order. -/
theorem condition_binary_equality_iff (a b : conddata.InnerFunc (conddata.BinaryFuncValue))
    (r : Bool) (h : conddata.binary_inner_eq a b = ok r) :
    (r = true ↔ SameBinaryCondition a b) := by
  exact rustfs_kernel.Verified.RustfsConditionEquality.binary_inner_ok a b r h

/-- Binary equality depends only on decoded bytes, preserving order and duplication. -/
theorem condition_binary_value_equality_iff (a b : conddata.BinaryFuncValue) (r : Bool)
    (h : conddata.binary_eq a b = ok r) : (r = true ↔ a.decoded.val = b.decoded.val) := by
  exact rustfs_kernel.Verified.RustfsConditionEquality.binary_eq_ok a b r h

/-- Boolean conditions compare ordered keys and Boolean values. -/
theorem condition_boolean_equality_iff (a b : conddata.InnerFunc Bool) (r : Bool)
    (h : conddata.bool_inner_eq a b = ok r) : (r = true ↔ SameBoolCondition a b) := by
  exact rustfs_kernel.Verified.RustfsCompleteConditionEquality.bool_inner_ok a b r h

/-- Address conditions compare ordered keys, addresses and prefix widths. -/
theorem condition_address_equality_iff
    (a b : conddata.InnerFunc (alloc.vec.Vec (condfuncs.IpAddr × U8))) (r : Bool)
    (h : conddata.addr_inner_eq a b = ok r) : (r = true ↔ SameAddrCondition a b) := by
  exact rustfs_kernel.Verified.RustfsCompleteConditionEquality.addr_inner_ok a b r h

/-- Condition equality preserves operators, wrappers and typed data contents. -/
theorem condition_equality_iff (a b : conddata.Condition) (r : Bool)
    (h : conddata.condition_eq a b = ok r) : (r = true ↔ SameCondition a b) := by
  exact rustfs_kernel.Verified.RustfsCompleteConditionEquality.condition_eq_ok a b r h

/-- Group membership finds an operator-, wrapper- and data-equivalent condition. -/
theorem condition_membership_iff (xs : Slice conddata.Condition) (c : conddata.Condition) (r : Bool)
    (h : conddata.contains_condition xs c = ok r) :
    (r = true ↔ ∃ d ∈ xs.val, SameCondition d c) := by
  exact rustfs_kernel.Verified.RustfsConditionGroups.contains_ok xs c r h

/-- Group coverage requires every source condition to have an equivalent target. -/
theorem condition_group_coverage_iff (a b : Slice conddata.Condition) (r : Bool)
    (h : conddata.list_covers a b = ok r) :
    (r = true ↔ ConditionGroupCovered a.val b.val) := by
  exact rustfs_kernel.Verified.RustfsConditionGroups.covers_ok a b r h

/-- Function comparison preserves quantifier boundaries, counts and coverage. -/
theorem condition_groups_comparison_iff (a b : conddata.Functions) (r : Bool)
    (h : conddata.functions_eq a b = ok r) : (r = true ↔ ConditionGroupsMatch a b) := by
  exact rustfs_kernel.Verified.RustfsConditionGroups.functions_eq_ok a b r h

/-- Copying a condition entry preserves its key and typed value. -/
theorem condition_entry_copy_exact {T : Type} (inst : core.clone.Clone T) [CloneLaw inst]
    (e : conddata.FuncKeyValue T) : conddata.clone_key_value inst e = ok e := by
  exact rustfs_kernel.Verified.RustfsConditionCopies.entry_clone inst e

/-- Copying condition data preserves every entry and its position. -/
theorem condition_data_copy_exact {T : Type} (inst : core.clone.Clone T) [CloneLaw inst]
    (a b : conddata.InnerFunc T) (h : conddata.clone_inner inst a = ok b) : b = a := by
  exact rustfs_kernel.Verified.RustfsConditionCopies.inner_clone inst a b h

/-- Conversion to matching pairs preserves ordered keys and typed values. -/
theorem condition_legacy_pairs_exact {T : Type} (inst : core.clone.Clone T) [CloneLaw inst]
    (a : conddata.InnerFunc T) (b : alloc.vec.Vec (condfuncs.Key × T))
    (h : conddata.legacy_pairs inst a = ok b) :
    b.val = a.entries.val.map (fun e => (e.key, e.values)) := by
  exact rustfs_kernel.Verified.RustfsConditionCopies.legacy_pairs_ok inst a b h

/-- Presence views retain every key in its original position. -/
theorem condition_presence_keys_exact {T : Type}
    (a : conddata.InnerFunc T) (b : alloc.vec.Vec (condfuncs.Key × Bool))
    (h : conddata.key_presence a = ok b) :
    b.val = a.entries.val.map (fun e => (e.key, false)) := by
  exact rustfs_kernel.Verified.RustfsConditionCopies.key_presence_ok a b h

/-- A matching view preserves wrapper presence and the typed entry projection. -/
theorem condition_matching_view_exact (c : conddata.Condition) (v : condfuncs.Condition)
    (h : conddata.condition_view c = ok v) : MatchingView c v := by
  exact rustfs_kernel.Verified.RustfsConditionViews.condition_view_ok c v h

/-- Matching views preserve order and quantifier group boundaries. -/
theorem condition_group_views_exact (f : conddata.Functions) (v : condfuncs.Functions)
    (h : conddata.matching_view f = ok v) :
    MatchingViews f.for_any_value.val v.for_any_value.val ∧
    MatchingViews f.for_all_values.val v.for_all_values.val ∧
    MatchingViews f.for_normal.val v.for_normal.val := by
  exact rustfs_kernel.Verified.RustfsConditionViews.matching_view_ok f v h

/-- Base-key serialization exposes the wrapper marker whenever a wrapper exists. -/
theorem condition_base_key_exact (c : conddata.Condition) (v : alloc.vec.Vec U8)
    (h : conddata.to_key c = ok v) : nats v.val = ConditionBaseKeyName c := by
  exact rustfs_kernel.Verified.RustfsConditionViews.base_key_ok c v h

/-- Successful decoding returns exactly the bytes of a canonical Base64 encoding. -/
theorem base64_decoding_sound (encoded : Slice U8) (v : alloc.vec.Vec U8)
    (h : conddata.decode_base64 encoded = ok (.Ok v)) :
    Base64Encoding (nats encoded.val) (v.val.map (·.bv)) := by
  exact rustfs_kernel.Verified.RustfsBase64.decode_sound encoded v h

/-- Accepted inputs consist of four-symbol blocks, with at most two padding bytes. -/
theorem base64_decoding_lengths (encoded : Slice U8) (v : alloc.vec.Vec U8)
    (h : conddata.decode_base64 encoded = ok (.Ok v)) :
    encoded.val.length % 4 = 0 ∧ v.val.length ≤ 3 * (encoded.val.length / 4) ∧
      3 * (encoded.val.length / 4) ≤ v.val.length + 2 := by
  have hl := (rustfs_kernel.Verified.RustfsBase64.decode_sound encoded v h).lengths
  simpa only [nats, List.length_map] using hl

end rustfs_kernel.Properties
