import Verified.RustfsDateFields
import Verified.RustfsDateNanos
import Verified.RustfsStatementMeaning
import Verified.RustfsKmsMeaning
import Verified.RustfsBPMeaning
import Verified.RustfsStatementContext
import Verified.RustfsResourceMeaning
import Verified.RustfsPathFull
import Verified.RustfsFunctionsMeaning
import Verified.RustfsStringEval
import Verified.RustfsAwsDepthMeaning
import Verified.RustfsAwsLayout
import Verified.RustfsAwsMeaning
import Verified.RustfsAwsScan
import Verified.RustfsAwsPasses
import Verified.RustfsAwsResolution
import Verified.RustfsExpansionModel
import Verified.RustfsConditionKeys
import Verified.RustfsKmsActions
import Verified.RustfsPrincipal
import Verified.RustfsKmsFilter
import Verified.RustfsFindExact
import Verified.RustfsAwsCollections
import Verified.RustfsAwsClosing
import Verified.RustfsAwsValues
import Verified.RustfsCommonSubstitution
import Verified.RustfsStatementSkips
import Verified.RustfsStatementResources
import Verified.RustfsStatementActions
import Verified.RustfsReplace
import Verified.RustfsStringEquals
import Verified.RustfsIpDecision
import Verified.RustfsUnicodeRoundtrip
import Verified.RustfsUnicodeLowerBytes
import Verified.RustfsUnicodeTrimExact
import Verified.RustfsIpNetworks
import Verified.RustfsUnicodeCodec
import Verified.RustfsLikeQuantifier
import Verified.RustfsUnicodeLower
import Verified.RustfsScalarOperators
import Verified.RustfsOperatorLookup
import Verified.RustfsIpLookup
import Verified.RustfsStringLike
import Verified.RustfsNullBool
import Verified.RustfsNumeric
import Verified.RustfsUnicodeSingleton
import Verified.RustfsUnicodeTrim
import Verified.RustfsUnicodeAppend
import Verified.RustfsUnicodeDecode
import Verified.RustfsUnicodeInterval
import Verified.RustfsUnicodeWhitespace
import Verified.RustfsUnicodeTables
import Verified.RustfsUnicodeStructure
import Verified.RustfsDateValues
import Verified.RustfsRequestTags
import Verified.RustfsPolicyMerge
import Verified.RustfsManagementTags
import Verified.RustfsManagementEquality
import Verified.RustfsManagementQueries
import Verified.RustfsDerivedMembership
import Verified.RustfsExtras
import Verified.RustfsPatternPrefix
import Verified.RustfsManagementViews
import Verified.RustfsManagementDecisions
import Verified.RustfsResourceSets
import Verified.RustfsDocuments
import Verified.RustfsVariableScalars
import Verified.RustfsVariableIdentity
import Verified.RustfsVariablePrincipal
import Verified.RustfsVariableCustom
import Verified.RustfsVariableDynamic
import Verified.RustfsVariableResolve
import Verified.RustfsClaimStrings
import Verified.RustfsClaimPath
import Verified.RustfsClaimTree
import Verified.RustfsClaimUnique
import Verified.RustfsActionTables
import Verified.RustfsActionSets
import Verified.RustfsConditionBinarySafety
import Verified.RustfsBinaryEvaluation
import Verified.RustfsBinaryConstruction
import Verified.RustfsBinaryMatch
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

/-- Path normalization removes slash and dot components, traverses parents with the
relative-path barrier, and represents an empty result as a dot. -/
theorem clean_exact (p : Slice U8) (c : alloc.vec.Vec U8) (h : pathclean.clean p=ok c) :
    nats c.val=CleanPath (nats p.val) :=
  Verified.RustfsPathFull.clean_meaning p c h


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

/-- Successful binary construction preserves inputs and their decoded order. -/
theorem binary_values_construction_sound (es : alloc.vec.Vec (alloc.vec.Vec U8))
    (v : conddata.BinaryFuncValue)
    (h : conddata.binary_from_encoded_values es = ok (.Ok v)) :
    v.encoded = es ∧ List.Forall₂ BinaryValueEncoding es.val v.decoded.val := by
  exact rustfs_kernel.Verified.RustfsBinaryConstruction.from_values_ok es v h

/-- A single-value constructor retains precisely that encoded value. -/
theorem binary_single_construction_sound (es : Slice U8) (v : conddata.BinaryFuncValue)
    (h : conddata.binary_new es = ok (.Ok v)) :
    v.encoded.val.map (fun e => e.val) = [es.val] ∧
      List.Forall₂ BinaryValueEncoding v.encoded.val v.decoded.val := by
  exact rustfs_kernel.Verified.RustfsBinaryConstruction.new_ok es v h

/-- A true binary match validates every request and matches an expected decoding. -/
theorem binary_request_match_sound (f : conddata.BinaryFuncValue)
    (requests : Slice (alloc.vec.Vec U8)) (b : Bool)
    (h : conddata.binary_key_matches f requests = ok b) (ht : b = true) :
    (∀ e ∈ requests.val, ValidBinaryRequest e) ∧
      ∃ e ∈ requests.val, MatchingBinaryRequest f e := by
  exact rustfs_kernel.Verified.RustfsBinaryMatch.match_sound f requests b h ht

/-- Returned request data belongs to an entry with the requested name. -/
theorem condition_lookup_payload_sound
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (needle : Slice U8) (v : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : condfuncs.get_value values needle = ok (some v)) :
    ∃ e ∈ values.val, e.1.val = needle.val ∧ e.2 = v := by
  exact rustfs_kernel.Verified.RustfsConditionLookupContents.get_contents_ok values needle v h

/-- Every entry of an accepted binary condition has valid named matching request data. -/
theorem binary_condition_evaluation_sound (inner : conddata.InnerFunc conddata.BinaryFuncValue)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (b : Bool) (h : conddata.binary_evaluate inner values = ok b) (ht : b = true) :
    ∀ e ∈ inner.entries.val, BinaryEntrySatisfied values e := by
  exact rustfs_kernel.Verified.RustfsBinaryEvaluation.evaluate_sound inner values b h ht

/-- Accepted binary conditions satisfy their entries or use a missing-key wrapper. -/
theorem condition_binary_acceptance_sound (c : conddata.Condition) (q : condfuncs.Quantifier)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (env : condfuncs.Env)
    (h : conddata.condition_evaluate c q values ctx env = ok true) :
    BinaryConditionSafe values c := by
  exact rustfs_kernel.Verified.RustfsConditionBinarySafety.condition_sound c q values ctx env h

/-- Conjunction preserves the binary acceptance guarantee for every condition. -/
theorem condition_group_binary_acceptance_sound (cs : Slice conddata.Condition)
    (q : condfuncs.Quantifier)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (env : condfuncs.Env)
    (h : conddata.all_hold cs q values ctx env = ok true) :
    ∀ c ∈ cs.val, BinaryConditionSafe values c := by
  exact rustfs_kernel.Verified.RustfsConditionBinarySafety.all_sound cs q values ctx env h

/-- Function evaluation preserves binary validation across all three quantifier groups. -/
theorem functions_binary_acceptance_sound (f : conddata.Functions)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (env : condfuncs.Env)
    (h : conddata.functions_evaluate f values ctx env = ok true) :
    (∀ c ∈ f.for_any_value.val, BinaryConditionSafe values c) ∧
    (∀ c ∈ f.for_all_values.val, BinaryConditionSafe values c) ∧
    (∀ c ∈ f.for_normal.val, BinaryConditionSafe values c) := by
  exact rustfs_kernel.Verified.RustfsConditionBinarySafety.functions_sound f values ctx env h

/-- Membership uses both the family and the action name. -/
theorem action_set_membership (xs : Slice acts.Action) (x : acts.Action) (b : Bool)
    (h : actsets.member xs x = ok b) : (b = true ↔ x ∈ xs.val) := by
  exact rustfs_kernel.Verified.RustfsActionSets.member_ok xs x b h

/-- Coverage is inclusion of members, independent of order and duplicates. -/
theorem action_set_containment (xs ys : Slice acts.Action) (b : Bool)
    (h : actsets.covers xs ys = ok b) :
    (b = true ↔ ∀ x ∈ xs.val, x ∈ ys.val) := by
  exact rustfs_kernel.Verified.RustfsActionSets.covers_ok xs ys b h

/-- Equality is extensional equality of action sets. -/
theorem action_set_equality (xs ys : Slice acts.Action) (b : Bool)
    (h : actsets.eq xs ys = ok b) :
    (b = true ↔ ∀ x, x ∈ xs.val ↔ x ∈ ys.val) := by
  exact rustfs_kernel.Verified.RustfsActionSets.eq_ok xs ys b h

/-- Insertion preserves existing members and appends only an absent action. -/
theorem action_set_unique_insertion (xs : alloc.vec.Vec acts.Action) (x : acts.Action)
    (ys : alloc.vec.Vec acts.Action) (h : actsets.push_unique xs x = ok ys) :
    ys.val = if x ∈ xs.val then xs.val else xs.val ++ [x] := by
  exact rustfs_kernel.Verified.RustfsActionSets.push_unique_ok xs x ys h

/-- Emptiness means that the set contains no entries. -/
theorem action_set_empty (xs : Slice acts.Action) :
    actsets.is_empty xs = ok (decide (xs.val = [])) := by
  exact rustfs_kernel.Verified.RustfsActionSets.empty_ok xs

/-- The action-set slice preserves all entries. -/
theorem action_set_slice (xs : Slice acts.Action) : actsets.as_slice xs = ok xs := by
  exact rustfs_kernel.Verified.RustfsActionSets.slice_ok xs

/-- Action-set validation accepts every represented action list. -/
theorem action_set_validation_total (xs : Slice acts.Action) : actsets.is_valid xs = ok true := by
  exact rustfs_kernel.Verified.RustfsActionSets.validation_total xs

/-- Wildcard action matching enforces the explicit-grant requirement. -/
theorem action_grant_match (pattern requested : acts.Action) (b : Bool)
    (h : actsets.action_is_match pattern requested = ok b) :
    (b = true ↔ ActionGrantMatches pattern requested) := by
  exact rustfs_kernel.Verified.RustfsActionSets.action_match_ok pattern requested b h

/-- Set matching follows entry matching and version-read compatibility. -/
theorem action_set_grant_match (xs : Slice acts.Action) (requested : acts.Action) (b : Bool)
    (h : actsets.set_is_match xs requested = ok b) :
    (b = true ↔ ActionSetGrantMatches xs.val requested) := by
  exact rustfs_kernel.Verified.RustfsActionSets.set_match_ok xs requested b h

/-- Data-table characterization: action lookup returns the indexed name or empty out of range. -/
theorem action_name_table_lookup (f : acts.Family) (i : Usize) (v : alloc.vec.Vec U8)
    (h : actsets.action_name f i = ok v) :
    nats v.val = ((actionNames f)[i.val]?).getD [] := by
  exact rustfs_kernel.Verified.RustfsActionTables.action_name_ok f i v h

/-- Data-table characterization: reported action counts equal table lengths. -/
theorem action_name_table_count (f : acts.Family) (n : Usize) (h : actsets.action_count f = ok n) :
    n.val = (actionNames f).length := by
  exact rustfs_kernel.Verified.RustfsActionTables.count_ok f n h

/-- Data-table characterization: the four family table sizes. -/
theorem action_name_table_sizes :
    (s3ActionNames.length = 71 ∧ adminActionNames.length = 91 ∧
      stsActionNames.length = 2 ∧ kmsActionNames.length = 18) := by
  exact rustfs_kernel.Verified.RustfsActionTables.table_counts

/-- Data-table structure: every family table has distinct entries. -/
theorem action_name_table_distinct (f : acts.Family) : (actionNames f).Nodup := by
  exact rustfs_kernel.Verified.RustfsActionTables.table_distinct f

/-- Data-table structure: all names are nonempty and carry the family prefix. -/
theorem action_name_table_prefixes (f : acts.Family) :
    ∀ n ∈ actionNames f, familyPrefix f <+: n ∧ n ≠ [] := by
  exact rustfs_kernel.Verified.RustfsActionTables.table_prefixes f

/-- Name recognition is exact membership in the selected family table. -/
theorem action_name_table_membership (f : acts.Family) (needle : Slice U8) (b : Bool)
    (h : actsets.contains_name f needle = ok b) :
    (b = true ↔ nats needle.val ∈ actionNames f) := by
  exact rustfs_kernel.Verified.RustfsActionTables.contains_name_ok f needle b h

/-- Admin name validation accepts exactly the Admin table entries. -/
theorem admin_action_name_validation (needle : Slice U8) (b : Bool)
    (h : actsets.admin_is_valid needle = ok b) :
    (b = true ↔ nats needle.val ∈ adminActionNames) := by
  exact rustfs_kernel.Verified.RustfsActionTables.admin_valid_ok needle b h


/-- Claim lookup returns the first exact name match, or certifies absence. -/
theorem claim_lookup_first (table : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
    (needle : Slice U8) (o : Option Usize) (h : claims.find table needle = ok o) :
    ClaimLookupResult table.val needle.val o := by
  exact rustfs_kernel.Verified.RustfsClaimLookup.find_ok table needle o h

/-- A returned role ARN is the string in the first roleArn entry. -/
theorem claim_role_arn_origin (table : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
    (v : alloc.vec.Vec U8) (h : claims.get_role_arn table = ok (some v)) :
    ∃ i : Usize, ∃ hi : i.val < table.val.length,
      FirstNamedClaim table.val table.val[i.val].1.val i.val ∧
      nats table.val[i.val].1.val = lit "roleArn" ∧
      table.val[i.val].2 = claims.Value.String v := by
  exact rustfs_kernel.Verified.RustfsClaimLookup.role_arn_sound table v h

/-- Service-account policies use the designated claim name. -/
theorem claim_service_policy_name (v : alloc.vec.Vec U8)
    (h : claims.iam_policy_claim_name_sa = ok v) : nats v.val = lit "sa-policy" := by
  exact rustfs_kernel.Verified.RustfsClaimLookup.service_policy_name_ok v h

/-- Existing-object tag recognition accepts exactly the supported key forms. -/
theorem claim_existing_tag_key (key : Slice U8) (b : Bool)
    (h : claims.is_existing_object_tag_condition_key key = ok b) :
    (b = true ↔ ExistingTagKey (nats key.val)) := by
  exact rustfs_kernel.Verified.RustfsClaimTags.tag_key_ok key b h

/-- Tag detection is exact across nested JSON objects and arrays. -/
theorem claim_existing_tag_tree (v : claims.Value) (b : Bool)
    (h : claims.value_uses_existing_object_tag v = ok b) :
    (b = true ↔ ExistingTagUse v) := by
  exact rustfs_kernel.Verified.RustfsClaimTree.value_ok v b h

/-- Splitting claim strings never introduces an empty policy token. -/
theorem claim_tokens_nonempty (s : Slice U8) (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : claims.split_values s = ok out) : NonemptyClaimTokens out.val := by
  exact rustfs_kernel.Verified.RustfsClaimTokens.split_nonempty s out h

/-- Deduplication removes repetition while preserving exactly the input tokens. -/
theorem claim_unique_membership (values : Slice (alloc.vec.Vec U8))
    (out : alloc.vec.Vec (alloc.vec.Vec U8)) (h : claims.unique_values values = ok out) :
    out.val.Nodup ∧ ∀ x, x ∈ out.val ↔ x ∈ values.val := by
  exact rustfs_kernel.Verified.RustfsClaimUnique.unique_ok values out h


/-- Claim strings and arrays are accepted and produce nonempty tokens. -/
theorem claim_string_container (v : claims.Value) (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (b : Bool) (h : claims.value_strings v = ok (out,b)) :
    NonemptyClaimTokens out.val ∧ (b = true ↔ ClaimStringContainer v) := by
  exact rustfs_kernel.Verified.RustfsClaimStrings.value_ok v out b h

/-- Policy extraction excludes empty names. -/
theorem claim_exact_tokens_nonempty (table : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
    (needle : Slice U8) (out : alloc.vec.Vec (alloc.vec.Vec U8)) (b : Bool)
    (h : claims.values_from_claims table needle = ok (out,b)) :
    NonemptyClaimTokens out.val := by
  exact rustfs_kernel.Verified.RustfsClaimStrings.exact_nonempty table needle out b h

/-- Policy extraction excludes empty names. -/
theorem claim_lookup_tokens_nonempty (table : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
    (needle : Slice U8) (out : alloc.vec.Vec (alloc.vec.Vec U8)) (b : Bool)
    (h : claims.lookup_strings table needle = ok (out,b)) :
    NonemptyClaimTokens out.val := by
  exact rustfs_kernel.Verified.RustfsClaimStrings.lookup_nonempty table needle out b h

/-- Policy extraction excludes empty names and repeated entries. -/
theorem claim_values_unique_nonempty (table : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
    (needle : Slice U8) (out : alloc.vec.Vec (alloc.vec.Vec U8)) (b : Bool)
    (h : claims.get_values_from_claims table needle = ok (out,b)) :
    NonemptyClaimTokens out.val ∧ out.val.Nodup := by
  exact rustfs_kernel.Verified.RustfsClaimStrings.get_values_ok table needle out b h

/-- Policy extraction excludes empty names and repeated entries. -/
theorem claim_policies_unique_nonempty (table : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
    (needle : Slice U8) (out : alloc.vec.Vec (alloc.vec.Vec U8)) (b : Bool)
    (h : claims.get_policies_from_claims table needle = ok (out,b)) :
    NonemptyClaimTokens out.val ∧ out.val.Nodup := by
  exact rustfs_kernel.Verified.RustfsClaimStrings.policies_ok table needle out b h

/-- Policy extraction excludes empty names and repeated entries. -/
theorem claim_args_policies_unique_nonempty (table : alloc.vec.Vec (alloc.vec.Vec U8 × claims.Value))
    (needle : Slice U8) (out : alloc.vec.Vec (alloc.vec.Vec U8)) (b : Bool)
    (h : claims.args_get_policies table needle = ok (out,b)) :
    NonemptyClaimTokens out.val ∧ out.val.Nodup := by
  exact rustfs_kernel.Verified.RustfsClaimStrings.args_ok table needle out b h

/-- Path splitting preserves every byte and its order. -/
theorem claim_path_split_lossless (path : Slice U8) (second : Bool) (left right : alloc.vec.Vec U8)
    (h : claims.split_path path second = ok (left,right)) : left.val ++ right.val = path.val := by
  exact rustfs_kernel.Verified.RustfsClaimPath.path_preserved path second left right h

/-- A fresh context contains no caller-supplied identity or variable values. -/
theorem variable_context_empty (c : varctx.VariableContext) (h : varctx.context_new = ok c) :
    c.is_https = false ∧ c.source_ip = none ∧ c.account_id = none ∧ c.region = none ∧
    c.username = none ∧ c.claims = none ∧ c.conditions.val = [] ∧ c.custom_variables.val = [] := by
  exact Verified.RustfsVariableScalars.context_empty c h

/-- Constructing a resolver preserves the supplied context. -/
theorem variable_resolver_context (c : varctx.VariableContext) (r : varctx.VariableResolver)
    (h : varctx.resolver_new c = ok r) : r.context = c := by
  exact Verified.RustfsVariableScalars.resolver_context c r h

/-- Identity-field resolution preserves the supplied value, including absence. -/
theorem variable_username_exact (r : varctx.VariableResolver) (o : Option (alloc.vec.Vec U8))
    (h : varctx.resolve_username r = ok o) : o = r.context.username := by
  exact Verified.RustfsVariableScalars.username_ok r o h

/-- Identity-field resolution preserves the supplied value, including absence. -/
theorem variable_account_id_exact (r : varctx.VariableResolver) (o : Option (alloc.vec.Vec U8))
    (h : varctx.resolve_account_id r = ok o) : o = r.context.account_id := by
  exact Verified.RustfsVariableScalars.account_ok r o h

/-- Identity-field resolution preserves the supplied value, including absence. -/
theorem variable_region_exact (r : varctx.VariableResolver) (o : Option (alloc.vec.Vec U8))
    (h : varctx.resolve_region r = ok o) : o = r.context.region := by
  exact Verified.RustfsVariableScalars.region_ok r o h

/-- Identity-field resolution preserves the supplied value, including absence. -/
theorem variable_source_ip_exact (r : varctx.VariableResolver) (o : Option (alloc.vec.Vec U8))
    (h : varctx.resolve_source_ip r = ok o) : o = r.context.source_ip := by
  exact Verified.RustfsVariableScalars.source_ok r o h

/-- The first exact-name claim supplies scalar values in their original order. -/
theorem variable_claim_strings_exact (r : varctx.VariableResolver) (needle : Slice U8)
    (o : Option (alloc.vec.Vec (alloc.vec.Vec U8)))
    (h : varctx.get_claim_as_strings r needle = ok o) :
    o.map (fun vs => vs.val.map (fun v => nats v.val)) = ResolverStrings r (nats needle.val) := by
  exact Verified.RustfsVariableScalars.claim_strings_ok r needle o h

/-- User-ID selection takes the last scalar, using parent only when sub supplies no string list. -/
theorem variable_userid_exact (r : varctx.VariableResolver) (o : Option (alloc.vec.Vec U8))
    (h : varctx.resolve_userid r = ok o) : o.map (fun v => nats v.val) = VariableUserID r := by
  exact Verified.RustfsVariableIdentity.userid_ok r o h

/-- Claim-key presence determines principal type, with role precedence. -/
theorem variable_principal_type_exact (r : varctx.VariableResolver) (out : alloc.vec.Vec U8)
    (h : varctx.resolve_principal_type r = ok out) : nats out.val = VariablePrincipalType r := by
  exact Verified.RustfsVariablePrincipal.principal_ok r out h

/-- SecureTransport faithfully reports the context's transport flag. -/
theorem variable_secure_transport_exact (r : varctx.VariableResolver) (v : alloc.vec.Vec U8)
    (h : varctx.resolve_secure_transport r = ok v) :
    nats v.val = if r.context.is_https then lit "true" else lit "false" := by
  exact Verified.RustfsVariableScalars.secure_ok r v h

/-- Custom names require the prefix and select the first exact suffix match. -/
theorem variable_custom_first (r : varctx.VariableResolver) (needle : Slice U8)
    (out : Option (alloc.vec.Vec U8)) (h : varctx.resolve_custom_variable r needle = ok out) :
    out = VariableCustom r needle.val := by
  exact Verified.RustfsVariableCustom.custom_ok r needle out h

/-- Exactly the two clock variable names are dynamic. -/
theorem variable_dynamic_names (needle : Slice U8) (b : Bool) (h : varctx.is_dynamic needle = ok b) :
    (b = true ↔ nats needle.val = lit "aws:CurrentTime" ∨ nats needle.val = lit "aws:EpochTime") := by
  exact Verified.RustfsVariableDynamic.dynamic_ok needle b h

/-- Standard variable substitution agrees with the context and explicit clock inputs. -/
theorem variable_resolution_exact (r : varctx.VariableResolver) (needle : Slice U8) (env : condfuncs.Env)
    (out : Option (alloc.vec.Vec U8)) (h : varctx.resolve r needle env = ok out) :
    out.map (fun v => nats v.val) = VariableResolution r needle.val env := by
  exact Verified.RustfsVariableResolve.resolve_ok r needle env out h

/-- Multi-value user IDs preserve every scalar; other substitutions are singletons. -/
theorem variable_multiple_exact (r : varctx.VariableResolver) (needle : Slice U8) (env : condfuncs.Env)
    (out : Option (alloc.vec.Vec (alloc.vec.Vec U8)))
    (h : varctx.resolve_multiple r needle env = ok out) :
    out.map (fun vs => vs.val.map (fun v => nats v.val)) = VariableMultiple r needle.val env := by
  exact Verified.RustfsVariableResolve.multiple_ok r needle env out h

section
open Verified.RustfsResolutionTerminates

/-- Resolution terminates for every context, including substituted placeholder text. -/
theorem variable_substitution_terminates (ctx : awsvars.VarContext) (p : Slice U8) (depth : Usize) :
    Finishes (awsvars.resolve_aws_variables_with_depth ctx p depth) (fun _ => True) := by
  exact depth_fin ctx p depth

/-- Every scan either preserves the work list or strictly decreases its remaining-work score. -/
theorem variable_scan_progress (ctx : awsvars.VarContext) (depth : Usize)
    (results : alloc.vec.Vec awsvars.Pending) (i : Usize) (p : awsvars.Pending)
    (hp : results.val[i.val]? = some p) (start : Usize) (hs : p.resume.val ≤ start.val) :
    Finishes (awsvars.scan ctx results i start depth) (ScanPost results i) := by
  exact scan_fin ctx depth (fun s d _ => depth_fin ctx s d) results i p hp start hs

/-- Resuming a work list cannot diverge. -/
theorem variable_pass_from_terminates (ctx : awsvars.VarContext) (depth : Usize)
    (results : alloc.vec.Vec awsvars.Pending) (i : Usize) :
    Finishes (awsvars.pass_from ctx results i depth) (fun _ => True) := by
  exact pass_from_fin ctx depth (fun s d _ => depth_fin ctx s d) results i

/-- A complete substitution pass cannot diverge. -/
theorem variable_single_pass_terminates (ctx : awsvars.VarContext) (p : Slice U8) (depth : Usize) :
    Finishes (awsvars.resolve_single_pass ctx p depth) (fun _ => True) := by
  exact single_fin ctx depth (fun s d _ => depth_fin ctx s d) p

/-- Iterating through an input list cannot diverge. -/
theorem variable_pass_all_terminates (ctx : awsvars.VarContext) (depth : Usize)
    (results : Slice (alloc.vec.Vec U8)) (k : Usize)
    (acc : alloc.vec.Vec (alloc.vec.Vec U8)) (changed : Bool) :
    Finishes (awsvars.pass_all ctx results k acc changed depth) (fun _ => True) := by
  exact pass_all_fin ctx depth (fun s d _ => depth_fin ctx s d) results k acc changed

/-- Repeated substitution terminates at every initial iteration and nesting depth. -/
theorem variable_fixpoint_terminates (ctx : awsvars.VarContext) (depth : Usize)
    (results : alloc.vec.Vec (alloc.vec.Vec U8)) (iteration : Usize) :
    Finishes (awsvars.fixpoint ctx results iteration depth) (fun _ => True) := by
  exact fixpoint_fin ctx depth (fun s d _ => depth_fin ctx s d) results iteration
end

/-- A successful update increments the revision and retains the original creation time. -/
theorem document_update_revision (d : docdata.PolicyDoc) (p : manage.Policy) (t : docdata.Timestamp)
    (out : docdata.PolicyDoc) (h : docdata.update_at d p t = ok out) :
    out.version.val = d.version.val + 1 ∧ out.policy = p ∧
    out.update_date = some t ∧ out.create_date = d.create_date.orElse (fun _ => some t) :=
  Verified.RustfsDocuments.update_ok d p t out h

theorem document_new_initialization (p : manage.Policy) (t : docdata.Timestamp) :
    ∃ out, docdata.new_at p t = ok out ∧ out.version.val = 1 ∧ out.policy = p ∧
      out.create_date = some t ∧ out.update_date = some t :=
  Verified.RustfsDocuments.new_ok p t

theorem document_policy_initialization (p : manage.Policy) :
    ∃ out, docdata.default_policy p = ok out ∧ out.version.val = 1 ∧ out.policy = p ∧
      out.create_date = none ∧ out.update_date = none :=
  Verified.RustfsDocuments.default_policy_ok p

theorem document_default_empty :
    ∃ out, docdata.default_doc = ok out ∧ out.version.val = 0 ∧
      out.policy.id.val = [] ∧ out.policy.version.val = [] ∧ out.policy.statements.val = [] ∧
      out.create_date = none ∧ out.update_date = none :=
  Verified.RustfsDocuments.default_doc_ok

/-- Resource-set equality compares membership, independently of order or multiplicity. -/
theorem resource_set_equality (xs ys : Slice rsrc.Resource) (b : Bool)
    (h : resets.eq xs ys = ok b) :
    (b = true ↔ ∀ x, x ∈ xs.val ↔ x ∈ ys.val) :=
  Verified.RustfsResourceSets.eq_ok xs ys b h

theorem resource_set_membership (xs : Slice rsrc.Resource) (x : rsrc.Resource) (b : Bool)
    (h : resets.member xs x = ok b) : (b = true ↔ x ∈ xs.val) :=
  Verified.RustfsResourceSets.member_ok xs x b h

theorem resource_unique_insertion (xs : alloc.vec.Vec rsrc.Resource) (x : rsrc.Resource)
    (ys : alloc.vec.Vec rsrc.Resource) (h : resets.push_unique xs x = ok ys) :
    ys.val = if x ∈ xs.val then xs.val else xs.val ++ [x] :=
  Verified.RustfsResourceSets.push_unique_ok xs x ys h

theorem resource_set_empty (xs : Slice rsrc.Resource) :
    resets.is_empty xs = ok (decide (xs.val = [])) :=
  Verified.RustfsResourceSets.empty_ok xs

theorem resource_slice_preserves (xs : Slice rsrc.Resource) : resets.as_slice xs = ok xs :=
  Verified.RustfsResourceSets.slice_ok xs

theorem resource_match_has_witness (xs : Slice rsrc.Resource) (needle : Slice U8) (b : Bool)
    (h : resets.set_match_resource xs needle = ok b) :
    (b = true ↔ ∃ x ∈ xs.val, resets.match_resource x needle = ok true) :=
  Verified.RustfsResourceSets.set_match_ok xs needle b h

theorem resource_empty_denies (xs : Slice rsrc.Resource) (needle : Slice U8)
    (values : alloc.vec.Vec ((alloc.vec.Vec U8) × (alloc.vec.Vec (alloc.vec.Vec U8))))
    (hx : xs.val = []) : resets.set_matches xs needle values = ok false :=
  Verified.RustfsResourceSets.empty_matches xs needle values hx

/-- Explicit deny is checked before owner and deny-only privileges. -/
theorem metadata_policy_decision (p : manage.Policy) (a : stmts.Args) (e : condfuncs.Env) (b : Bool)
    (h : manage.policy_is_allowed p a e = ok b) :
    (b = true ↔
      (∀ st ∈ p.statements.val, st.effect = .Deny → manage.statement_is_allowed st a e = ok true) ∧
      (a.deny_only = true ∨ a.is_owner = true ∨
        ∃ st ∈ p.statements.val, st.effect = .Allow ∧ manage.statement_is_allowed st a e = ok true)) :=
  Verified.RustfsManagementDecisions.decision_ok p a e b h

/-- Bucket owners remain subject to every explicit deny. -/
theorem metadata_bucket_decision (p : manage.BucketPolicy) (a : stmts.BucketPolicyArgs)
    (e : condfuncs.Env) (b : Bool) (h : manage.bucket_policy_is_allowed p a e = ok b) :
    (b = true ↔
      (∀ st ∈ p.statements.val, st.effect = .Deny → manage.bp_statement_is_allowed st a e = ok true) ∧
      (a.is_owner = true ∨
        ∃ st ∈ p.statements.val, st.effect = .Allow ∧ manage.bp_statement_is_allowed st a e = ok true)) :=
  Verified.RustfsManagementDecisions.bucket_decision_ok p a e b h

/-- Successful authorization supplies evidence that each deny permits the request. -/
theorem metadata_explicit_deny (p : manage.Policy) (a : stmts.Args) (e : condfuncs.Env)
    (h : manage.policy_is_allowed p a e = ok true) (st : manage.Statement)
    (hs : st ∈ p.statements.val) (hd : st.effect = .Deny) :
    manage.statement_is_allowed st a e = ok true :=
  ((metadata_policy_decision p a e true h).1 rfl).1 st hs hd

/-- Non-owner authorization needs a matching allow in the supplied policy. -/
theorem metadata_allow_witness (p : manage.Policy) (a : stmts.Args) (e : condfuncs.Env)
    (h : manage.policy_is_allowed p a e = ok true) (ho : a.is_owner = false)
    (hd : a.deny_only = false) :
    ∃ st ∈ p.statements.val, st.effect = .Allow ∧ manage.statement_is_allowed st a e = ok true := by
  have hh := ((metadata_policy_decision p a e true h).1 rfl).2
  simpa [ho,hd] using hh

/-- Policy validation requires a supported version and every statement's action/resource rules. -/
theorem metadata_policy_validity (p : manage.Policy) (out : core.result.Result Unit valids.ValidationError)
    (h : manage.is_valid p = ok out) : (out = .Ok () ↔ MetadataPolicyOK p) :=
  Verified.RustfsManagementViews.policy_ok p out h

theorem metadata_policy_validate (p : manage.Policy) (out : core.result.Result Unit valids.ValidationError)
    (h : manage.validate p = ok out) : (out = .Ok () ↔ MetadataPolicyOK p) :=
  Verified.RustfsManagementViews.policy_ok p out h

theorem metadata_bucket_validity (p : manage.BucketPolicy) (out : core.result.Result Unit valids.ValidationError)
    (h : manage.bucket_is_valid p = ok out) : (out = .Ok () ↔ MetadataBucketPolicyOK p) :=
  Verified.RustfsManagementViews.bucket_policy_ok p out h

/-- Projection preserves every action/resource field used by matching and validation. -/
theorem metadata_statement_projection (st : manage.Statement) (out : stmts.Statement)
    (h : manage.statement_view st = ok out) :
    out.effect = st.effect ∧ out.actions = st.actions ∧ out.not_actions = st.not_actions ∧
    out.resources = st.resources ∧ out.not_resources = st.not_resources ∧
    (StatementOK out ↔ MetadataStatementOK st) :=
  Verified.RustfsManagementViews.statement_view_ok st out h

theorem metadata_bucket_projection (st : manage.BPStatement) (out : stmts.BPStatement)
    (h : manage.bp_statement_view st = ok out) :
    out.effect = st.effect ∧ out.principal = st.principal ∧ out.actions = st.actions ∧
    out.not_actions = st.not_actions ∧ out.resources = st.resources ∧
    out.not_resources = st.not_resources ∧ (BPStatementOK out ↔ MetadataBPStatementOK st) :=
  Verified.RustfsManagementViews.bp_view_ok st out h

theorem metadata_version_validity (v : Slice U8) (out : core.result.Result Unit valids.ValidationError)
    (h : manage.version_is_valid v = ok out) :
    (out = .Ok () ↔ v.val = [] ∨ nats v.val = lit "2012-10-17") :=
  Verified.RustfsManagementViews.version_ok v out h


/-- Principal normalization retains precisely the supplied values without duplicates. -/
theorem principal_values_normalization (v : extras.PrincipalValues) (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : extras.principal_values_into_set v = ok out) :
    out.val.Nodup ∧ ∀ x, x ∈ out.val ↔ x ∈ (match v with
      | .Single s => [s]
      | .Multiple vs => vs.val) :=
  Verified.RustfsExtras.principal_set_ok v out h

theorem lazy_buffer_initialization (source : Slice U8) :
    ∃ out, extras.lazybuf_new source = ok out ∧ out.source = source ∧
      out.buffer = none ∧ out.written.val = 0 :=
  Verified.RustfsExtras.lazybuf_initial source

/-- Prefix acceptance has a compatible prefix ending at a star or at the end of the text. -/
theorem pattern_prefix_exact (p t : Slice U8) (b : Bool)
    (h : extras.is_match_as_pattern_prefix p t = ok b) : (b = true ↔ PatternPrefix p.val t.val) :=
  Verified.RustfsPatternPrefix.prefix_ok p t b h


/-- Object traversal finds a tag key or a recursively tag-using value in the remaining suffix. -/
theorem claim_object_tag_traversal (es : Slice (alloc.vec.Vec U8 × claims.Value)) (i : Usize)
    (b : Bool) (h : claims.object_uses_tag es i = ok b) :
    (b = true ↔ ∃ e ∈ es.val.drop i.val, ExistingTagKey (nats e.1.val) ∨ ExistingTagUse e.2) :=
  (Verified.RustfsClaimTree.all_ok (sizeOf (es.val.drop i.val))).2.1 es i (Nat.le_refl _) b h

/-- Array traversal finds a recursively tag-using value in the remaining suffix. -/
theorem claim_array_tag_traversal (es : Slice claims.Value) (i : Usize)
    (b : Bool) (h : claims.array_uses_tag es i = ok b) :
    (b = true ↔ ∃ v ∈ es.val.drop i.val, ExistingTagUse v) :=
  (Verified.RustfsClaimTree.all_ok (sizeOf (es.val.drop i.val))).2.2 es i (Nat.le_refl _) b h


/-- Data-table characterization: canonical condition-key lookup in declaration order. -/
theorem condition_key_table_lookup (f : keytables.KeyFamily) (i : Usize) (v : alloc.vec.Vec U8)
    (h : keytables.key_name f i = ok v) : nats v.val = ((keyNames f)[i.val]?).getD [] :=
  Verified.RustfsKeyTables.key_name_ok f i v h

/-- Data-table characterization: each family count is its table's length. -/
theorem condition_key_table_count (f : keytables.KeyFamily) (n : Usize)
    (h : keytables.key_count f = ok n) : n.val = (keyNames f).length :=
  Verified.RustfsKeyTables.count_ok f n h

theorem condition_key_table_distinct (f : keytables.KeyFamily) : (keyNames f).Nodup :=
  Verified.RustfsKeyTables.table_distinct f

theorem condition_key_table_prefixes (f : keytables.KeyFamily) :
    ∀ n ∈ keyNames f, keyPrefix f <+: n ∧ n ≠ [] :=
  Verified.RustfsKeyTables.table_prefixes f

/-- Canonical-name membership is exact table membership. -/
theorem condition_key_canonical_membership (f : keytables.KeyFamily) (needle : Slice U8) (b : Bool)
    (h : keytables.contains_name f needle = ok b) : (b = true ↔ nats needle.val ∈ keyNames f) :=
  Verified.RustfsKeyTables.contains_name_ok f needle b h

theorem condition_key_server_derived (f : keytables.KeyFamily) (needle : Slice U8) (b : Bool)
    (h : keytables.is_server_derived f needle = ok b) :
    (b = true ↔ nats needle.val ∈ keyNames f ∧
      (f ≠ .S3 ∨ ¬ lit "s3:x-amz-" <+: nats needle.val)) :=
  Verified.RustfsKeyTables.server_derived_ok f needle b h

/-- Data-table characterization of common names and their variable spellings. -/
theorem condition_common_key_table (i : Usize) (out : alloc.vec.Vec U8 × alloc.vec.Vec U8)
    (h : keynames.common_key i = ok out) :
    (nats out.1.val,nats out.2.val) = (commonKeyEntries[i.val]?).getD ([],[]) :=
  Verified.RustfsCommonKeys.common_ok i out h

/-- Filtering retains table order and repeated names. -/
theorem server_derived_name_list (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : keytables.server_derived_key_names = ok out) :
    out.val.map (fun v => nats v.val) = serverDerivedNames :=
  Verified.RustfsDerivedKeys.derived_names_ok out h

theorem server_derived_condition_membership (needle : Slice U8) (b : Bool)
    (h : keytables.is_server_derived_condition_key needle = ok b) :
    (b = true ↔ ∃ n ∈ serverDerivedNames, n.map asciiLower = (nats needle.val).map asciiLower) :=
  Verified.RustfsDerivedMembership.condition_key_ok needle b h


/-- Statement comparison ignores IDs and compares semantic set fields. -/
theorem metadata_statement_equality (a c : manage.Statement) (b : Bool)
    (h : manage.statement_eq a c = ok b) : (b = true ↔ MetadataStatementEquivalent a c) :=
  Verified.RustfsManagementEquality.statement_eq_ok a c b h

theorem metadata_index_membership (xs : Slice Usize) (x : Usize) (b : Bool)
    (h : manage.index_member xs x = ok b) : (b = true ↔ x ∈ xs.val) :=
  Verified.RustfsManagementQueries.index_member_ok xs x b h

theorem metadata_empty_policy (p : manage.Policy) :
    manage.is_empty p = ok (decide (p.statements.val = [])) :=
  Verified.RustfsManagementQueries.empty_ok p

theorem metadata_resource_witness (p : manage.Policy) (needle : Slice U8) (b : Bool)
    (h : manage.match_resource p needle = ok b) :
    (b = true ↔ ∃ st ∈ p.statements.val, ∃ r ∈ st.resources.val,
      resets.match_resource r needle = ok true) :=
  Verified.RustfsManagementQueries.match_resource_ok p needle b h

theorem metadata_condition_tag (c : conddata.Condition) (b : Bool)
    (h : manage.condition_uses_tag c = ok b) : (b = true ↔ ConditionUsesExistingTag c) :=
  Verified.RustfsManagementTags.condition_tag_ok c b h

theorem metadata_condition_replacement (cs : Slice conddata.Condition) (i : Usize)
    (hi : i.val < cs.val.length) (b : Bool) (h : manage.overwritten cs i = ok b) :
    (b = true ↔ ∃ j, i.val < j ∧ ∃ hj : j < cs.val.length,
      ConditionKeyName cs.val[i.val] = ConditionKeyName cs.val[j]) :=
  Verified.RustfsManagementTags.overwritten_ok cs i hi b h

theorem metadata_active_tag_conditions (cs : Slice conddata.Condition) (b : Bool)
    (h : manage.list_uses_tag cs = ok b) : (b = true ↔ ActiveTagConditions cs.val) :=
  Verified.RustfsManagementTags.list_tag_ok cs b h

theorem metadata_functions_tag (f : conddata.Functions) (b : Bool)
    (h : manage.functions_use_existing_object_tag f = ok b) : (b = true ↔ FunctionsUseExistingTag f) :=
  Verified.RustfsManagementTags.functions_tag_ok f b h

theorem metadata_policy_tag (p : manage.Policy) (b : Bool)
    (h : manage.policy_uses_existing_object_tag_conditions p = ok b) :
    (b = true ↔ ∃ st ∈ p.statements.val, FunctionsUseExistingTag st.conditions) :=
  Verified.RustfsManagementTags.policy_tag_ok p b h

theorem metadata_bucket_tag (p : manage.BucketPolicy) (b : Bool)
    (h : manage.bucket_policy_uses_existing_object_tag_conditions p = ok b) :
    (b = true ↔ ∃ st ∈ p.statements.val, FunctionsUseExistingTag st.conditions) :=
  Verified.RustfsManagementTags.bucket_tag_ok p b h

/-- Metadata copies preserve every field, including statement identifiers. -/
theorem metadata_statement_copy (s : manage.Statement) :
    manage.Statement.Insts.CoreCloneClone.clone s = ok s :=
  Verified.RustfsManagementCopies.statement_clone s

theorem metadata_append_statements (initial : alloc.vec.Vec manage.Statement)
    (ss : Slice manage.Statement) (out : alloc.vec.Vec manage.Statement)
    (h : manage.append_statements initial ss = ok out) :
    out.val = initial.val ++ ss.val :=
  Verified.RustfsStatementRetention.append_ok initial ss out h

theorem metadata_retained_statements (ss : Slice manage.Statement) (ds : Slice Usize)
    (out : alloc.vec.Vec manage.Statement) (h : manage.retained_statements ss ds = ok out) :
    out.val = RetainStatements ss.val (ds.val.map (fun k => k.val)) :=
  Verified.RustfsStatementRetention.retain_ok ss ds out h

theorem metadata_duplicate_marks (ss : Slice manage.Statement) (i : Usize)
    (hi : i.val < ss.val.length) (initial out : alloc.vec.Vec Usize)
    (h : manage.mark_duplicates ss i initial = ok out) :
    ∀ k, k ∈ out.val ↔ k ∈ initial.val ∨ i.val < k.val ∧
      ∃ hk : k.val < ss.val.length, MetadataStatementEquivalent ss.val[i.val] ss.val[k.val] :=
  Verified.RustfsDuplicateMarks.mark_ok ss i hi initial out h

theorem metadata_duplicate_selection (p out : manage.Policy)
    (h : manage.drop_duplicate_statements p = ok out) :
    out.id = p.id ∧ out.version = p.version ∧
      DeduplicatedStatements p.statements.val out.statements.val :=
  Verified.RustfsDuplicateSelection.drop_ok p out h

theorem metadata_policy_merge (ps : Slice manage.Policy) (out : manage.Policy)
    (h : manage.merge_policies ps = ok out) :
    out.id.val = [] ∧ out.version.val = FirstPolicyVersion ps.val ∧
      DeduplicatedStatements ((ps.val.map (fun p => p.statements.val)).flatten) out.statements.val :=
  Verified.RustfsPolicyMerge.merge_ok ps out h

/-- Tag loading for a force-delete allow requires an explicit matching grant. -/
theorem metadata_request_tag_grant (p : manage.Policy) (a : stmts.Args) (e : condfuncs.Env)
    (h : manage.policy_needs_existing_object_tag_for_args p a e = ok true) :
    ∃ st ∈ p.statements.val, FunctionsUseExistingTag st.conditions ∧
      (st.effect = .Allow → IsForceDelete a.action →
        ∃ x ∈ st.actions.val, acts.action_is_match_for_effect x a.action false = ok true) :=
  Verified.RustfsRequestTags.policy_needs_sound p a e h

/-- Bucket tag loading requires a tag-reading statement with a matching principal. -/
theorem metadata_bucket_request_tag_principal (p : manage.BucketPolicy) (a : stmts.BucketPolicyArgs)
    (h : manage.bucket_policy_needs_existing_object_tag_for_args p a = ok true) :
    ∃ st ∈ p.statements.val, FunctionsUseExistingTag st.conditions ∧
      stmts.principal_is_match st.principal a.account.deref = ok true :=
  Verified.RustfsRequestTags.bucket_needs_sound p a h

/-- Source timezone retention preserves the UTC timestamp. -/
theorem date_value_preserves_instant (s : Slice U8) (out : conddata.DateFuncValue)
    (h : dates.parse_value s = ok (some out)) :
    dates.parse_rfc3339 s = ok (some out.unix_nanos) :=
  Verified.RustfsDateValues.parsed_instant s out h

theorem date_value_rejects_invalid (s : Slice U8) (h : dates.parse_rfc3339 s = ok none) :
    dates.parse_value s = ok none :=
  Verified.RustfsDateValues.rejects_invalid s h

/-- UTC designators cannot introduce a nonzero serialization offset. -/
theorem date_value_utc_offset (s : Slice U8) (out : conddata.DateFuncValue)
    (hz : s.val[s.val.length - 1]? = some 90#u8 ∨ s.val[s.val.length - 1]? = some 122#u8)
    (h : dates.parse_value s = ok (some out)) : out.offset_seconds = 0#i32 :=
  Verified.RustfsDateValues.utc_offset s out hz h

/-- Table characterization of lowercase range chunk 0. -/
theorem unicode_range_0_table (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_0 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges0 :=
  Verified.RustfsUnicodeTables.range0_ok cp out h

/-- Table characterization of lowercase range chunk 1. -/
theorem unicode_range_1_table (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_1 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges1 :=
  Verified.RustfsUnicodeTables.range1_ok cp out h

/-- Table characterization of lowercase range chunk 2. -/
theorem unicode_range_2_table (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_2 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges2 :=
  Verified.RustfsUnicodeTables.range2_ok cp out h

/-- Table characterization of lowercase range chunk 3. -/
theorem unicode_range_3_table (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_3 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges3 :=
  Verified.RustfsUnicodeTables.range3_ok cp out h

/-- Table characterization of lowercase range chunk 4. -/
theorem unicode_range_4_table (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_4 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges4 :=
  Verified.RustfsUnicodeTables.range4_ok cp out h

/-- Table characterization of lowercase range chunk 5. -/
theorem unicode_range_5_table (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_5 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges5 :=
  Verified.RustfsUnicodeTables.range5_ok cp out h

/-- Table characterization of lowercase range chunk 6. -/
theorem unicode_range_6_table (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_6 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges6 :=
  Verified.RustfsUnicodeTables.range6_ok cp out h

/-- Table characterization of lowercase range chunk 7. -/
theorem unicode_range_7_table (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_7 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges7 :=
  Verified.RustfsUnicodeTables.range7_ok cp out h

/-- Table characterization of lowercase range chunk 8. -/
theorem unicode_range_8_table (cp : U32) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_8 cp = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) = LookupLowerRanges cp.val LowerRanges8 :=
  Verified.RustfsUnicodeTables.range8_ok cp out h

/-- Table structure: keys are unique and outputs are valid Unicode scalars. -/
theorem unicode_singleton_table_structure :
    (LowerSingletonEntries.map Prod.fst).Nodup ∧
    (∀ r ∈ LowerSingletonEntries,
      r.1 < 0x110000 ∧ r.2.1 < 0x110000 ∧ r.2.2.1 < 0x110000 ∧
      (r.2.1 < 0xD800 ∨ 0xDFFF < r.2.1) ∧
      (r.2.2.1 < 0xD800 ∨ 0xDFFF < r.2.2.1)) ∧
    (∀ r ∈ LowerSingletonEntries,
      r.2.2.2 = 1 ∨ (r.1 = 304 ∧ r.2.1 = 105 ∧ r.2.2.1 = 775 ∧ r.2.2.2 = 2)) :=
  ⟨Verified.RustfsUnicodeStructure.singleton_keys_distinct,
   Verified.RustfsUnicodeStructure.singleton_scalar_bounds,
   Verified.RustfsUnicodeStructure.singleton_expansion_shape⟩

/-- Table structure: ranges have ordered bounds and valid destination intervals. -/
theorem unicode_range_table_structure :
    ∀ r ∈ LowerRangeEntries,
      r.1 ≤ r.2.1 ∧ r.2.1 < 0x110000 ∧ r.2.2.1 ≤ 2 ∧
      (r.2.2.2 < 0 → (-r.2.2.2).toNat ≤ r.1) ∧
      LowerRangeValue r.1 r < 0x110000 ∧ LowerRangeValue r.2.1 r < 0x110000 ∧
      (LowerRangeValue r.2.1 r < 0xD800 ∨ 0xDFFF < LowerRangeValue r.1 r) :=
  Verified.RustfsUnicodeStructure.range_entries_well_formed

/-- Table characterization of the whitespace scalars used by trimming. -/
theorem unicode_whitespace_table (cp : U32) (b : Bool)
    (h : unicode.whitespace cp = ok b) :
    b = true ↔ cp.val ∈ UnicodeWhitespace :=
  Verified.RustfsUnicodeWhitespace.whitespace_ok cp b h

theorem unicode_whitespace_table_structure :
    UnicodeWhitespace.Nodup ∧ UnicodeWhitespace.length = 25 :=
  ⟨Verified.RustfsUnicodeStructure.whitespace_distinct,
   Verified.RustfsUnicodeStructure.whitespace_count⟩

/-- Range mappings cannot produce a surrogate or an out-of-range scalar. -/
theorem unicode_range_output_valid (cp : U32) (i : Usize) (out : U32 × U32 × Usize)
    (h : unicode.range_chunk cp i = ok (some out)) :
    out.2.1.val = 0 ∧ out.2.2.val = 1 ∧ out.1.val < 0x110000 ∧
      (out.1.val < 0xD800 ∨ 0xDFFF < out.1.val) :=
  Verified.RustfsUnicodeInterval.chunk_result_valid cp i out h

/-- Table characterization of range dispatch, including absent chunk indices. -/
theorem unicode_range_dispatch_table (cp : U32) (i : Usize) (out : Option (U32 × U32 × Usize))
    (h : unicode.range_chunk cp i = ok out) :
    out.map (fun r => (r.1.val,r.2.1.val,r.2.2.val)) =
      LookupLowerRanges cp.val ((Verified.RustfsUnicodeChunks.Chunks[i.val]?).getD []) :=
  Verified.RustfsUnicodeChunks.chunk_ok cp i out h

/-- Successful encoding preserves the existing prefix and appends the scalar's byte width. -/
theorem unicode_encoding_prefix (initial out : alloc.vec.Vec U8) (cp : U32)
    (h : unicode.append_scalar initial cp = ok out) :
    ∃ bs : List U8, out.val = initial.val ++ bs ∧
      bs.length = Verified.RustfsUnicodeAppend.Utf8Width cp.val :=
  Verified.RustfsUnicodeAppend.append_preserves_prefix initial out cp h

/-- Successful decoding advances by one to four bytes without crossing the input boundary. -/
theorem unicode_decoding_progress (s : Slice U8) (i : Usize) (out : U32 × Usize)
    (h : unicode.scalar_at s i = ok out) :
    i.val < out.2.val ∧ out.2.val ≤ s.val.length ∧ out.2.val ≤ i.val + 4 :=
  Verified.RustfsUnicodeDecode.scalar_advances s i out h

/-- Trimming preserves a contiguous segment of the original byte sequence. -/
theorem unicode_trim_segment (s : Slice U8) (out : alloc.vec.Vec U8)
    (h : unicode.trim s = ok out) :
    ∃ a b : Nat, out.val = (s.val.take b).drop a :=
  Verified.RustfsUnicodeTrim.trim_segment s out h

/-- Table characterization of singleton lowercase exceptions and identity fallback. -/
theorem unicode_singleton_table (cp : U32) (out : U32 × U32 × Usize)
    (h : unicode.singleton cp = ok out) :
    (out.1.val,out.2.1.val,out.2.2.val) = LookupLowerSingleton cp.val :=
  Verified.RustfsUnicodeSingleton.singleton_ok cp out h


/-- Numeric operators compare mathematical signed values. -/
theorem numeric_comparison_spec (op : condfuncs.NumOp) (a b : I64) (r : Bool)
    (h : condfuncs.num_op op a b = ok r) :
    r = true ↔ NumericComparison op a.val b.val :=
  Verified.RustfsScalarOperators.numeric_ok op a b r h

/-- CIDR membership is equality of same-family numeric address prefixes. -/
theorem ip_prefix_spec (net ip : condfuncs.IpAddr) (pref : U8) (r : Bool)
    (h : condfuncs.net_contains net pref ip = ok r) :
    r = true ↔ IpPrefix net pref.val ip :=
  Verified.RustfsScalarOperators.prefix_ok net ip pref r h

/-- The first exact text entry determines address parsing. -/
theorem ip_parse_spec (env : condfuncs.Env) (text : Slice U8) (out : Option condfuncs.IpAddr)
    (h : condfuncs.parse_ip env text = ok out) :
    out = ParsedAddress (env.ips.val.map (fun e => (e.1.val,e.2))) text.val :=
  Verified.RustfsIpLookup.parse_ip_ok env text out h

/-- Date operators compare UTC instants. -/
theorem date_comparison_spec (op : conddata.Op) (a b : I128) (r : Bool)
    (h : dates.compare op a b = ok r) :
    r = true ↔ DateComparison op a.val b.val :=
  Verified.RustfsScalarOperators.date_comparison_ok op a b r h

/-- Request lookup selects the first exact byte-name entry. -/
theorem condition_values_spec
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (needle : Slice U8) (out : Option (alloc.vec.Vec (alloc.vec.Vec U8)))
    (h : condfuncs.get_value values needle = ok out) :
    out.map (fun vs => vs.val.map (·.val)) =
      ConditionValues (RequestValueLists values.val) needle.val :=
  Verified.RustfsOperatorLookup.lookup_ok values needle out h

/-- Null requires the specified emptiness test for every condition key. -/
theorem null_conditions_spec (funcs : Slice (condfuncs.Key × Bool))
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (b : Bool) (h : condfuncs.null_func funcs values = ok b) :
    b = true ↔ NullConditions funcs.val (RequestValueLists values.val) :=
  Verified.RustfsNullBool.null_conditions_ok funcs values b h

/-- Bool requires the exact spelling in each key's first value. -/
theorem bool_conditions_spec (funcs : Slice (condfuncs.Key × Bool))
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (b : Bool) (h : condfuncs.bool_func funcs values = ok b) :
    b = true ↔ BoolConditions funcs.val (RequestValueLists values.val) :=
  Verified.RustfsNullBool.bool_conditions_ok funcs values b h

/-- Numeric evaluation follows the ordered missing-value and comparison rules. -/
theorem numeric_conditions_spec (op : condfuncs.NumOp) (ifExists : Bool)
    (funcs : Slice (condfuncs.Key × I64))
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (b : Bool) (h : condfuncs.num_func op ifExists funcs values = ok b) :
    b = true ↔ NumericConditions op ifExists (RequestValueLists values.val)
      (funcs.val.map (fun e => (e.1,e.2.val))) :=
  Verified.RustfsNumeric.numeric_conditions_ok op ifExists funcs values b h

/-- A glob candidate matches exactly when the independent glob predicate holds. -/
theorem string_any_like_spec (cands : Slice (alloc.vec.Vec U8)) (value : Slice U8) (b : Bool)
    (h : condfuncs.any_like cands value = ok b) :
    b = true ↔ AnyStringLike (cands.val.map (·.val)) value.val :=
  Verified.RustfsStringLike.any_like_ok cands value b h

/-- Scalar lowercasing uses the first range table image, then singleton or identity. -/
theorem unicode_lowercase_scalar_spec (cp : U32) (out : U32 × U32 × Usize)
    (h : unicode.lowercase_scalar cp = ok out) :
    (out.1.val,out.2.1.val,out.2.2.val) = LowercaseScalar cp.val :=
  Verified.RustfsUnicodeLower.scalar_ok cp out h

/-- Network-list matching is the union of the numeric CIDR prefixes. -/
theorem ip_networks_spec (networks : Slice (condfuncs.IpAddr × U8))
    (address : condfuncs.IpAddr) (b : Bool)
    (h : condfuncs.any_net networks address = ok b) :
    b = true ↔ AnyNetwork networks.val address :=
  Verified.RustfsIpNetworks.any_net_ok networks address b h

/-- Scalar encoding appends exactly the specified UTF-8 bit fields. -/
theorem unicode_append_scalar_spec (initial out : alloc.vec.Vec U8) (cp : U32)
    (h : unicode.append_scalar initial cp = ok out) :
    nats out.val = nats initial.val ++ EncodeScalar cp.val :=
  Verified.RustfsUnicodeCodec.append_ok initial out cp h

/-- Glob matching uses universal or existential request-value quantification. -/
theorem string_like_quantifier_spec (requests candidates : alloc.vec.Vec (alloc.vec.Vec U8))
    (q : condfuncs.Quantifier) (negate b : Bool)
    (h : condfuncs.str_eval_like_loop q negate requests candidates 0#usize = ok b) :
    b = true ↔ QuantifiedLike q negate (candidates.val.map (·.val))
      (requests.val.map (·.val)) :=
  Verified.RustfsLikeQuantifier.loop_ok requests candidates q negate b h


/-- Scalar decoding computes the numeric UTF-8 bit fields and next byte offset. -/
theorem unicode_decode_scalar_spec (s : Slice U8) (i : Usize) (out : U32 × Usize)
    (h : unicode.scalar_at s i = ok out) :
    (out.1.val,out.2.val) = DecodeScalar (nats s.val) i.val :=
  Verified.RustfsUnicodeCodec.decode_ok s i out h

/-- Decoding a scalar's emitted UTF-8 encoding returns the original scalar. -/
theorem unicode_scalar_roundtrip_spec (cp : U32) (encoded : alloc.vec.Vec U8)
    (actual : U32 × Usize) (hc : cp.val < 1114112)
    (he : unicode.append_scalar (alloc.vec.Vec.new U8) cp = ok encoded)
    (hd : unicode.scalar_at (alloc.vec.Vec.deref encoded) 0#usize = ok actual) :
    actual.1 = cp ∧ actual.2.val = encoded.val.length :=
  Verified.RustfsUnicodeRoundtrip.append_decode cp encoded actual hc he hd

/-- Lowercasing concatenates the independent table image of every input scalar. -/
theorem unicode_lower_spec (s : Slice U8) (out : alloc.vec.Vec U8)
    (h : unicode.lower s = ok out) : nats out.val = LowerBytes (nats s.val) :=
  Verified.RustfsUnicodeLowerBytes.lower_ok s out h

/-- Trimming retains exactly the bytes between the non-whitespace endpoints. -/
theorem unicode_trim_spec (s : Slice U8) (out : alloc.vec.Vec U8)
    (h : unicode.trim s = ok out) : nats out.val = TrimBytes (nats s.val) :=
  Verified.RustfsUnicodeTrimExact.trim_ok s out h

/-- IP conditions follow the ordered parse-table and numeric-prefix decisions. -/
theorem ip_conditions_spec
    (funcs : Slice (condfuncs.Key × alloc.vec.Vec (condfuncs.IpAddr × U8)))
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (env : condfuncs.Env) (b : Bool) (h : condfuncs.addr_func funcs values env = ok b) :
    b = AddressConditions (env.ips.val.map (fun e => (e.1.val,e.2)))
      (RequestValueLists values.val) (funcs.val.map (fun e => (e.1,e.2.val))) :=
  Verified.RustfsIpDecision.conditions_ok funcs values env b h

/-- Equality quantifies the request values after optional ASCII case conversion. -/
theorem string_equality_quantifier_spec (requests candidates : alloc.vec.Vec (alloc.vec.Vec U8))
    (q : condfuncs.Quantifier) (ignoreCase negate b : Bool)
    (h : condfuncs.str_eval_loop q ignoreCase negate requests candidates 0#usize = ok b) :
    b = EqualityDecision q ignoreCase negate (candidates.val.map (fun v => nats v.val))
      (requests.val.map (fun v => nats v.val)) :=
  Verified.RustfsStringEquals.loop_ok requests candidates q ignoreCase negate b h

/-- Action and NotAction coverage includes effect-specific force-delete rules. -/
theorem statement_action_coverage_spec (actions excluded : Slice acts.Action)
    (requested : acts.Action) (deny b : Bool)
    (h : acts.statement_covers actions excluded requested deny = ok b) :
    b = true ↔ StatementActionCoverage deny actions.val excluded.val requested :=
  Verified.RustfsStatementActions.coverage_ok actions excluded requested deny b h

/-- Literal substitutions replace every non-overlapping occurrence in order. -/
theorem byte_replacement_spec (s search replacement : Slice U8) (out : alloc.vec.Vec U8)
    (h : bytes.replace s search replacement = ok out) :
    out.val = ReplaceBytes s.val search.val replacement.val :=
  Verified.RustfsReplace.replace_ok s search replacement out h

/-- Bucket-only resources are selected by exactly these three listing actions. -/
theorem bucket_listing_action_spec (a : acts.Action) (b : Bool)
    (h : stmts.is_list_bucket a = ok b) : b=true ↔ ListBucketAction a :=
  Verified.RustfsStatementResources.list_bucket_ok a b h

/-- Resource construction preserves object bytes and inserts the bucket separator. -/
theorem statement_resource_bytes_spec (a : acts.Action) (bucket object : Slice U8)
    (bucketOnly : Bool) (out : alloc.vec.Vec U8)
    (h : stmts.build_resource a bucket object bucketOnly = ok out) :
    out.val = RequestResource a bucket.val object.val bucketOnly :=
  Verified.RustfsStatementResources.build_ok a bucket object bucketOnly out h

/-- Administrative table operations are exactly the twenty names in the table. -/
theorem administrative_table_actions_spec (a : acts.Action) (b : Bool)
    (h : acts.is_table_resource_scoped a = ok b) :
    b=true ↔ Spec.TableResourceAction a := Verified.RustfsStatementSkips.table_ok a b h

/-- Resource matching is skipped exactly for the stated STS and administrative cases. -/
theorem statement_resource_skip_spec (st : stmts.Statement) (args : stmts.Args) (b : Bool)
    (h : stmts.skips_resource_match st args = ok b) :
    b=true ↔ Spec.SkipResourceMatch st.actions.val args.action :=
  Verified.RustfsStatementSkips.skip_ok st args b h

/-- Resource substitution applies all eligible common keys in data-table order. -/
theorem resource_common_substitution_spec (pattern : Slice U8)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (out : alloc.vec.Vec U8) (h : rsrc.substitute_common pattern values = ok out) :
    out.val = Spec.SubstituteCommon pattern.val (Spec.RequestValueLists values.val) :=
  Verified.RustfsCommonSubstitution.all_ok pattern values out h

/-- String substitution selects the first eligible common key in data-table order. -/
theorem string_common_substitution_spec (pattern : Slice U8)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (out : alloc.vec.Vec U8) (h : condfuncs.replace_first_common pattern values = ok out) :
    out.val = Spec.SubstituteFirstCommon pattern.val (Spec.RequestValueLists values.val) :=
  Verified.RustfsCommonSubstitution.first_ok pattern values out h

/-- Exact scalar lookup in the policy variable context. -/
theorem policy_variable_value_spec (c : awsvars.VarContext) (needle : Slice U8)
    (out : Option (alloc.vec.Vec U8)) (h : awsvars.resolve c needle = ok out) :
    out.map (fun v => Spec.nats v.val) =
      Spec.AwsValue (Verified.RustfsAwsValues.context c) (Spec.nats needle.val) :=
  Verified.RustfsAwsValues.resolve_ok c needle out h

/-- Exact list lookup, including present empty user-ID lists. -/
theorem policy_variable_values_spec (c : awsvars.VarContext) (needle : Slice U8)
    (out : Option (alloc.vec.Vec (alloc.vec.Vec U8)))
    (h : awsvars.resolve_multiple c needle = ok out) :
    out.map (fun v => v.val.map (fun s => Spec.nats s.val)) =
      Spec.AwsValues (Verified.RustfsAwsValues.context c) (Spec.nats needle.val) :=
  Verified.RustfsAwsValues.multiple_ok c needle out h

/-- Balanced-brace scanning returns the first closing position, or the end
position with the remaining balance when no closing brace is found. -/
theorem policy_variable_closing_spec (s : Slice U8) (start : Usize) (out : Usize × Usize)
    (h : awsvars.closing s start = ok out) :
    (out.1.val,out.2.val) = Spec.ClosingAt (Spec.nats s.val) start.val 1 :=
  Verified.RustfsAwsClosing.closing_ok s start out h

/-- Literal byte search returns exactly the earliest occurrence from the offset. -/
theorem byte_first_occurrence_spec (s p : Slice U8) (start : Usize)
    (out : Option Usize) (expected : Option Nat)
    (h : bytes.find_from s start p = ok out) :
    out.map (·.val) = expected ↔ Spec.FirstOccurrence s.val p.val start.val expected :=
  Verified.RustfsFindExact.find_iff s p start out expected h

/-- Substitutions preserve replacement order and resume after the inserted bytes. -/
theorem policy_variable_wrap_spec (pre post : Slice U8)
    (values : Slice (alloc.vec.Vec U8)) (offset : Usize)
    (out : alloc.vec.Vec awsvars.Pending) (h : awsvars.wrap_all pre values post offset = ok out) :
    out.val.map Verified.RustfsAwsCollections.pending =
      Spec.WrappedValues pre.val (values.val.map (·.val)) post.val offset.val :=
  Verified.RustfsAwsCollections.wrap_ok pre post values offset out h

/-- Duplicate expansion texts are removed in first-occurrence order. -/
theorem policy_variable_dedup_spec (xs : Slice (alloc.vec.Vec U8))
    (out : alloc.vec.Vec (alloc.vec.Vec U8)) (h : awsvars.dedup xs = ok out) :
    out.val.map (·.val) = Spec.UniqueBytes (xs.val.map (·.val)) :=
  Verified.RustfsAwsCollections.dedup_ok xs out h

/-- Replacing a pending entry preserves exactly the prefix and suffix around it. -/
theorem policy_variable_splice_spec (xs replacements : Slice awsvars.Pending) (idx : Usize)
    (out : alloc.vec.Vec awsvars.Pending)
    (h : awsvars.splice xs idx replacements = ok out) :
    out.val = xs.val.take idx.val ++ replacements.val ++ xs.val.drop (idx.val+1) :=
  Verified.RustfsAwsCollections.splice_ok xs replacements idx out h

/-- Principal matching is existential over AWS and service wildcard patterns. -/
theorem statement_principal_match_spec (p : stmts.Principal) (account : Slice U8)
    (b : Bool) (h : stmts.principal_is_match p account = ok b) :
    b=true ↔ Spec.PrincipalMatches (p.aws.val.map (fun v => Spec.nats v.val))
      (p.service.val.map (fun v => Spec.nats v.val)) (Spec.nats account.val) := by
  rw [Verified.RustfsPrincipal.principal_ok p account b h]
  unfold Spec.PrincipalMatches
  rw [←List.map_append]
  constructor
  · rintro ⟨pat,hp,hm⟩
    exact ⟨Spec.nats pat.val,List.mem_map.mpr ⟨pat,hp,rfl⟩,hm⟩
  · rintro ⟨pat,hp,hm⟩
    obtain ⟨source,hs,rfl⟩ := List.mem_map.mp hp
    exact ⟨source,hs,hm⟩

/-- KMS statement resource filtering preserves exactly the KMS entries in order. -/
theorem statement_kms_resources_spec (rs : Slice rsrc.Resource)
    (out : alloc.vec.Vec rsrc.Resource) (h : stmts.kms_only rs = ok out) :
    out.val = Spec.KmsResources rs.val :=
  Verified.RustfsKmsFilter.filter_ok rs out h

/-- The principal wildcard mode accepts a question mark at an exhausted name. -/
theorem principal_wildcard_spec (pattern account : Slice U8) :
    wildmatch.is_simple_match pattern account =
      ok (Spec.simpleGlobSpec (Spec.nats pattern.val) (Spec.nats account.val)) :=
  Verified.RustfsSimpleWildcard.wildcard_is_glob pattern account

/-- The KMS-only action test quantifies over every action, including the empty list. -/
theorem statement_kms_actions_spec (actions : Slice acts.Action) (b : Bool)
    (h : stmts.all_kms actions = ok b) : b=true ↔ ∀ a ∈ actions.val, a.family=.Kms :=
  Verified.RustfsKmsActions.all_ok actions b h

/-- Operator key presence includes request entries with empty value lists. -/
theorem operator_key_presence_spec (c : condfuncs.Cond)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (b : Bool) (h : condfuncs.has_any_key_in c values = ok b) :
    b=true ↔ Spec.OperatorKeyPresent c (Spec.RequestValueLists values.val) :=
  Verified.RustfsConditionKeys.has_key_ok c values b h

/-- Resource-selection key references range over all three condition groups. -/
theorem condition_key_reference_spec (f : condfuncs.Functions) (needle : Slice U8)
    (b : Bool) (h : condfuncs.references_key_name f needle = ok b) :
    b=true ↔ Spec.FunctionsReference f needle.val :=
  Verified.RustfsConditionKeys.functions_ok f needle b h

/-- Collecting single-pass alternatives preserves input and alternative order.
The change flag records whether any input has alternatives other than itself. -/
theorem policy_variable_pass_collection_spec (ctx : awsvars.VarContext) (depth : Usize)
    (pass : List Nat → List (List Nat)) (hn : ∀ text, pass text ≠ [])
    (hs : ∀ (text : Slice U8) (result : alloc.vec.Vec (alloc.vec.Vec U8)),
      awsvars.resolve_single_pass ctx text depth=ok result →
        Verified.RustfsAwsPasses.texts result.val=pass (Spec.nats text.val))
    (inputs : Slice (alloc.vec.Vec U8)) (offset : Usize)
    (acc : alloc.vec.Vec (alloc.vec.Vec U8)) (changed : Bool)
    (out : alloc.vec.Vec (alloc.vec.Vec U8) × Bool)
    (h : awsvars.pass_all ctx inputs offset acc changed depth=ok out) :
    Verified.RustfsAwsPasses.texts out.1.val = Verified.RustfsAwsPasses.texts acc.val ++
      ((Verified.RustfsAwsPasses.texts (inputs.val.drop offset.val)).flatMap pass) ∧
    out.2 = (changed || (Verified.RustfsAwsPasses.texts (inputs.val.drop offset.val)).any
      (fun text => decide (pass text ≠ [text]))) :=
  Verified.RustfsAwsPasses.pass_all_ok ctx depth pass hn hs inputs offset acc changed out h

/-- Reaching nesting depth ten leaves the input as its sole expansion. -/
theorem policy_variable_depth_cap_spec (ctx : awsvars.VarContext) (text : Slice U8)
    (depth : Usize) (out : alloc.vec.Vec (alloc.vec.Vec U8)) (hd : 10 ≤ depth.val)
    (h : awsvars.resolve_aws_variables_with_depth ctx text depth=ok out) :
    out.val.map (fun v => Spec.nats v.val)=
      Spec.ExpandVariables (Verified.RustfsAwsValues.context ctx) depth.val (Spec.nats text.val) :=
  Verified.RustfsAwsResolution.depth_cap_ok ctx text depth out hd h

/-- Bounded expansion rounds concatenate alternatives and retain first occurrences.
The single-pass premise supplies the per-input expansion semantics. -/
theorem policy_variable_rounds_spec (ctx : awsvars.VarContext) (depth : Usize)
    (pass : List Nat → List (List Nat)) (hn : ∀ text, pass text ≠ [])
    (hs : ∀ (text : Slice U8) (result : alloc.vec.Vec (alloc.vec.Vec U8)),
      awsvars.resolve_single_pass ctx text depth=ok result →
        Verified.RustfsAwsPasses.texts result.val=pass (Spec.nats text.val))
    (inputs : alloc.vec.Vec (alloc.vec.Vec U8)) (iteration : Usize)
    (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : awsvars.fixpoint ctx inputs iteration depth=ok out) :
    Verified.RustfsAwsPasses.texts out.val =
      Spec.ExpansionRounds pass (10-iteration.val) (Verified.RustfsAwsPasses.texts inputs.val) :=
  Verified.RustfsAwsPasses.fixpoint_ok ctx depth pass hn hs inputs iteration out h

/-- A substitution pass preserves every byte when there is no placeholder introducer. -/
theorem policy_variable_literal_pass_spec (ctx : awsvars.VarContext) (text : Slice U8)
    (depth : Usize) (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (hm : Spec.HasPlaceholder (Spec.nats text.val)=false)
    (h : awsvars.resolve_single_pass ctx text depth=ok out) :
    out.val.map (fun v => Spec.nats v.val)=
      Spec.ExpansionPass (Spec.ExpandVariables (Verified.RustfsAwsValues.context ctx) (depth.val+1))
        (Verified.RustfsAwsValues.context ctx) (Spec.nats text.val) := by
  rw [Spec.expansion_literal _ _ _ hm]
  exact Verified.RustfsAwsScan.single_pass_literal_ok ctx text depth hm out h

/-- A scan with no placeholder in its remaining suffix preserves every pending text. -/
theorem policy_variable_scan_literal_suffix_spec (ctx : awsvars.VarContext)
    (inputs : alloc.vec.Vec awsvars.Pending) (i start depth : Usize) (entry : awsvars.Pending)
    (hp : inputs.val[i.val]?=some entry)
    (hm : Spec.HasPlaceholder (Spec.nats (entry.text.val.drop start.val))=false)
    (out : alloc.vec.Vec awsvars.Pending × Bool)
    (h : awsvars.scan ctx inputs i start depth=ok out) :
    out=(inputs,false) ∧
      Spec.ResumeAlternatives (Spec.ExpandVariables (Verified.RustfsAwsValues.context ctx) (depth.val+1))
        (Verified.RustfsAwsValues.context ctx) (Spec.nats entry.text.val) start.val=[Spec.nats entry.text.val] := by
  refine ⟨Verified.RustfsAwsScan.scan_suffix_literal_ok ctx inputs i start depth entry hp hm out h, ?_⟩
  apply Spec.resume_literal
  simpa only [Spec.nats,List.map_drop] using hm

/-- An unbalanced first placeholder ends the scan and remains literal. -/
theorem policy_variable_unbalanced_scan_spec (ctx : awsvars.VarContext)
    (inputs : alloc.vec.Vec awsvars.Pending) (i start depth : Usize) (entry : awsvars.Pending) (pos : Nat)
    (hp : inputs.val[i.val]?=some entry)
    (hf : Spec.FirstOccurrence entry.text.val [36#u8,123#u8] start.val (some pos))
    (hb : (Spec.ClosingAt (Spec.nats entry.text.val) (pos+2) 1).2 ≠ 0)
    (out : alloc.vec.Vec awsvars.Pending × Bool)
    (h : awsvars.scan ctx inputs i start depth=ok out) :
    out=(inputs,false) ∧
      Spec.ResumeAlternatives (Spec.ExpandVariables (Verified.RustfsAwsValues.context ctx) (depth.val+1))
        (Verified.RustfsAwsValues.context ctx) (Spec.nats entry.text.val) start.val=[Spec.nats entry.text.val] :=
  ⟨Verified.RustfsAwsScan.scan_unbalanced_ok ctx inputs i start depth entry pos hp hf hb out h,
    Verified.RustfsAwsScan.resume_unbalanced _ _ entry.text.val start.val pos hf hb⟩

/-- Replacement values combine with suffix alternatives in replacement-major order.
Inserted bytes remain literal during the current pass. -/
theorem policy_variable_wrapped_alternatives_spec
    (inner : List Nat → List (List Nat)) (ctx : Spec.AwsValueContext)
    (pre post : Slice U8) (values : Slice (alloc.vec.Vec U8)) (offset : Usize)
    (hout : offset.val=pre.val.length) (out : alloc.vec.Vec awsvars.Pending)
    (h : awsvars.wrap_all pre values post offset=ok out) :
    out.val.flatMap (Verified.RustfsAwsMeaning.pendingMeaning inner ctx) =
      values.val.flatMap (fun value => (Spec.ExpansionPass inner ctx (Spec.nats post.val)).map
        (fun suffix => Spec.nats pre.val ++ Spec.nats value.val ++ suffix)) :=
  Verified.RustfsAwsMeaning.wrap_meaning_ok inner ctx pre post values offset hout out h

/-- Splicing substitutes the selected pending entry and preserves the surrounding alternatives. -/
theorem policy_variable_spliced_alternatives_spec
    (inner : List Nat → List (List Nat)) (ctx : Spec.AwsValueContext)
    (inputs replacements : Slice awsvars.Pending) (idx : Usize)
    (out : alloc.vec.Vec awsvars.Pending) (hi : idx.val ≤ inputs.val.length)
    (h : awsvars.splice inputs idx replacements=ok out) :
    out.val.take idx.val=inputs.val.take idx.val ∧
      (out.val.drop idx.val).flatMap (Verified.RustfsAwsMeaning.pendingMeaning inner ctx) =
        replacements.val.flatMap (Verified.RustfsAwsMeaning.pendingMeaning inner ctx) ++
          (inputs.val.drop (idx.val+1)).flatMap (Verified.RustfsAwsMeaning.pendingMeaning inner ctx) :=
  Verified.RustfsAwsMeaning.splice_meaning_ok inner ctx inputs replacements idx out hi h

/-- A balanced placeholder is replaced by the ordered alternatives of its resolved values. -/
theorem policy_variable_balanced_replacement_spec (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (text : List U8) (start pos closing : Nat)
    (hf : FirstOccurrence text [36#u8,123#u8] start (some pos))
    (hc : ClosingTail (nats (text.drop (pos+2))) 1=(closing,0))
    (pre post : Slice U8) (values : Slice (alloc.vec.Vec U8)) (offset : Usize)
    (hp : pre.val=text.take pos) (hs : post.val=text.drop (pos+closing+3))
    (ho : offset.val=pos)
    (hr : PlaceholderAlternatives inner c ((nats (text.drop (pos+2))).take closing)
      ((36::123::nats (text.drop (pos+2))).take (closing+3))=
        values.val.map (fun value => nats value.val))
    (results : Slice awsvars.Pending) (idx : Usize) (new out : alloc.vec.Vec awsvars.Pending)
    (hi : idx.val ≤ results.val.length)
    (hw : awsvars.wrap_all pre values post offset=ok new)
    (hsplice : awsvars.splice results idx new.slice=ok out) :
    out.val.take idx.val=results.val.take idx.val ∧
      (out.val.drop idx.val).flatMap (Verified.RustfsAwsMeaning.pendingMeaning inner c)=
        ResumeAlternatives inner c (nats text) start ++
          (results.val.drop (idx.val+1)).flatMap (Verified.RustfsAwsMeaning.pendingMeaning inner c) :=
  Verified.RustfsAwsMeaning.wrapped_scan_ok inner c text start pos closing hf hc pre post values offset hp hs ho hr results idx new out hi hw hsplice

/-- An empty resolved value removes the placeholder and resumes at its prefix position. -/
theorem policy_variable_empty_replacement_spec (inner : List Nat → List (List Nat)) (c : AwsValueContext)
    (text : List U8) (start pos closing : Nat)
    (hf : FirstOccurrence text [36#u8,123#u8] start (some pos))
    (hc : ClosingTail (nats (text.drop (pos+2))) 1=(closing,0))
    (pre post : Slice U8) (offset : Usize)
    (hp : pre.val=text.take pos) (hs : post.val=text.drop (pos+closing+3))
    (ho : offset.val=pos)
    (hr : PlaceholderAlternatives inner c ((nats (text.drop (pos+2))).take closing)
      ((36::123::nats (text.drop (pos+2))).take (closing+3))=[[]])
    (results : Slice awsvars.Pending) (idx : Usize) (v : alloc.vec.Vec U8)
    (new out : alloc.vec.Vec awsvars.Pending) (hi : idx.val ≤ results.val.length)
    (hconcat : bytes.concat pre post=ok v)
    (hpush : (alloc.vec.Vec.new awsvars.Pending).push {text:=v,resume:=offset}=ok new)
    (hsplice : awsvars.splice results idx new.slice=ok out) :
    out.val.take idx.val=results.val.take idx.val ∧
      (out.val.drop idx.val).flatMap (Verified.RustfsAwsMeaning.pendingMeaning inner c)=
        ResumeAlternatives inner c (nats text) start ++
          (results.val.drop (idx.val+1)).flatMap (Verified.RustfsAwsMeaning.pendingMeaning inner c) :=
  Verified.RustfsAwsMeaning.empty_scan_ok inner c text start pos closing hf hc pre post offset hp hs ho hr results idx v new out hi hconcat hpush hsplice

/-- Variable resolution computes the ordered, bounded substitution specification. -/
theorem policy_variable_resolution_spec (ctx : awsvars.VarContext) (text : Slice U8)
    (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : awsvars.resolve_aws_variables ctx text=ok out) :
    out.val.map (fun v => nats v.val)=ExpandVariables (Verified.RustfsAwsValues.context ctx) 0 (nats text.val) := by
  apply Verified.RustfsAwsResolution.depth_ok ctx text 0#usize out
  exact h

/-- The explicit nesting-depth entry point computes the same bounded specification. -/
theorem policy_variable_depth_resolution_spec (ctx : awsvars.VarContext) (text : Slice U8) (depth : Usize)
    (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : awsvars.resolve_aws_variables_with_depth ctx text depth=ok out) :
    out.val.map (fun v => nats v.val)=ExpandVariables (Verified.RustfsAwsValues.context ctx) depth.val (nats text.val) :=
  Verified.RustfsAwsResolution.depth_ok ctx text depth out h

/-- String policy candidates resolve variables, substitute common keys, and optionally fold ASCII case. -/
theorem string_policy_candidates_spec (policy : Slice (alloc.vec.Vec U8))
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (ignoreCase : Bool)
    (out : alloc.vec.Vec (alloc.vec.Vec U8))
    (h : condfuncs.policy_values policy values ctx ignoreCase=ok out) :
    Verified.RustfsPolicyValues.texts out.val=PolicyCandidates (ctx.map Verified.RustfsAwsValues.context)
      (RequestValueLists values.val) ignoreCase (Verified.RustfsPolicyValues.texts policy.val) :=
  Verified.RustfsPolicyValues.policy_values_ok policy values ctx ignoreCase out h

/-- Equality operators compute the quantified comparison of fully resolved policy candidates. -/
theorem string_evaluation_spec (key : condfuncs.Key) (policy : Slice (alloc.vec.Vec U8))
    (q : condfuncs.Quantifier) (ignoreCase negate : Bool)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (b : Bool)
    (h : condfuncs.str_eval key policy q ignoreCase negate values ctx=ok b) :
    b=StringEqualityEval (ctx.map Verified.RustfsAwsValues.context) (RequestValueLists values.val)
      key (Verified.RustfsPolicyValues.texts policy.val) q ignoreCase negate :=
  Verified.RustfsStringEval.equality_ok key policy q ignoreCase negate values ctx b h

/-- Wildcard operators compute the quantified glob relation over resolved policy candidates. -/
theorem string_like_evaluation_spec (key : condfuncs.Key) (policy : Slice (alloc.vec.Vec U8))
    (q : condfuncs.Quantifier) (negate : Bool)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (b : Bool)
    (h : condfuncs.str_eval_like key policy q negate values ctx=ok b) :
    b=true ↔ StringLikeEval (ctx.map Verified.RustfsAwsValues.context) (RequestValueLists values.val)
      key (Verified.RustfsPolicyValues.texts policy.val) q negate :=
  Verified.RustfsStringEval.like_ok key policy q negate values ctx b h

/-- A string operator requires every key entry to satisfy its quantified comparison. -/
theorem string_function_spec (funcs : Slice (condfuncs.Key × alloc.vec.Vec (alloc.vec.Vec U8)))
    (q : condfuncs.Quantifier) (ignoreCase like negate : Bool)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (b : Bool)
    (h : condfuncs.str_func funcs q ignoreCase like negate values ctx=ok b) :
    b=true ↔ ∀ entry ∈ funcs.val, StringEntryHolds (ctx.map Verified.RustfsAwsValues.context)
      (RequestValueLists values.val) entry.1 (Verified.RustfsPolicyValues.texts entry.2.val) q ignoreCase like negate :=
  Verified.RustfsStringFunction.function_ok funcs q ignoreCase like negate values ctx b h

/-- Each condition operator computes its independent list and numeric meaning. -/
theorem condition_operator_evaluation_spec (c : condfuncs.Cond) (q : condfuncs.Quantifier)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (env : condfuncs.Env) (b : Bool)
    (h : condfuncs.eval_cond c q values ctx env=ok b) :
    b=true ↔ OperatorHolds (ctx.map Verified.RustfsAwsValues.context) (RequestValueLists values.val)
      (env.ips.val.map (fun e => (e.1.val,e.2))) q c :=
  Verified.RustfsFunctionsMeaning.operator_ok c q values ctx env b h

/-- IfExists bypasses the operator exactly when none of its request keys is present. -/
theorem condition_evaluation_spec (c : condfuncs.Condition) (q : condfuncs.Quantifier)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (env : condfuncs.Env) (b : Bool)
    (h : condfuncs.condition_evaluate c q values ctx env=ok b) :
    b=true ↔ ConditionHolds (ctx.map Verified.RustfsAwsValues.context) (RequestValueLists values.val)
      (env.ips.val.map (fun e => (e.1.val,e.2))) q c :=
  Verified.RustfsFunctionsMeaning.condition_ok c q values ctx env b h

/-- Functions require every condition in each of the three quantifier groups. -/
theorem functions_evaluation_spec (f : condfuncs.Functions)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (env : condfuncs.Env) (b : Bool)
    (h : condfuncs.functions_evaluate f values ctx env=ok b) :
    b=true ↔ FunctionsHold (ctx.map Verified.RustfsAwsValues.context) (RequestValueLists values.val)
      (env.ips.val.map (fun e => (e.1.val,e.2))) f :=
  Verified.RustfsFunctionsMeaning.functions_ok f values ctx env b h

theorem resource_pattern_evaluation_spec (pattern resource : Slice U8)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8))) (b : Bool)
    (h : rsrc.pattern_matches pattern resource values=ok b) :
    b=true ↔ ResourcePatternHolds (RequestValueLists values.val) (nats pattern.val) (nats resource.val) :=
  Verified.RustfsResourceMeaning.pattern_ok pattern resource values b h

theorem resource_evaluation_spec (r : rsrc.Resource) (resource : Slice U8)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (b : Bool)
    (h : rsrc.resource_is_match r resource values ctx=ok b) :
    b=true ↔ ResourceHolds (ctx.map Verified.RustfsAwsValues.context) (RequestValueLists values.val)
      (ResourceText r) (nats resource.val) :=
  Verified.RustfsResourceMeaning.resource_ok r resource values ctx b h

theorem resource_set_evaluation_spec (set : Slice rsrc.Resource) (resource : Slice U8)
    (values : alloc.vec.Vec (alloc.vec.Vec U8 × alloc.vec.Vec (alloc.vec.Vec U8)))
    (ctx : Option awsvars.VarContext) (b : Bool)
    (h : rsrc.set_is_match set resource values ctx=ok b) :
    b=true ↔ ResourceSetHolds (ctx.map Verified.RustfsAwsValues.context) (RequestValueLists values.val)
      (set.val.map ResourceText) (nats resource.val) :=
  Verified.RustfsResourceMeaning.set_ok set resource values ctx b h

/-- Bucket statements compute principal, action, and resource matching before conditions. -/
theorem bucket_statement_matching_spec (st : stmts.BPStatement) (args : stmts.BucketPolicyArgs)
    (b : Bool) (h : stmts.bp_reaches_condition_eval st args=ok b) :
    b=true ↔ BucketStatementReaches st args :=
  Verified.RustfsBPMeaning.reaches_ok st args b h

/-- Bucket-policy effects apply to the matching and condition conjunction. -/
theorem bucket_statement_allowed_spec (st : stmts.BPStatement) (args : stmts.BucketPolicyArgs)
    (env : condfuncs.Env) (b : Bool) (h : stmts.bp_statement_is_allowed st args env=ok b) :
    b=true ↔ BucketStatementAllowed st args (env.ips.val.map (fun e=>(e.1.val,e.2))) :=
  Verified.RustfsBPMeaning.allowed_ok st args env b h

/-- Resolver data is determined by the request claims and environment times. -/
theorem statement_context_spec (args : stmts.Args) (env : condfuncs.Env) (out : awsvars.VarContext)
    (h : stmts.resolver_for args env=ok out) :
    Verified.RustfsAwsValues.context out=PolicyContext args env :=
  Verified.RustfsStatementContext.resolver_ok args env out h

/-- KMS scope follows filtered key patterns and the explicit empty-object cases. -/
theorem kms_scope_evaluation_spec (st : stmts.Statement) (args : stmts.Args)
    (ctx : Option awsvars.VarContext) (b : Bool)
    (h : stmts.kms_key_scope_matches st args ctx=ok b) :
    b=true ↔ KmsScopeHolds (ctx.map Verified.RustfsAwsValues.context) st args :=
  Verified.RustfsKmsMeaning.scope_ok st args ctx b h

/-- Identity matching includes action coverage, KMS selection, and explicit resource skips. -/
theorem statement_matching_spec (st : stmts.Statement) (args : stmts.Args)
    (ctx : Option awsvars.VarContext) (b : Bool)
    (h : stmts.reaches_condition_eval st args ctx=ok b) :
    b=true ↔ StatementReaches (ctx.map Verified.RustfsAwsValues.context) st args :=
  Verified.RustfsStatementMeaning.reaches_ok st args ctx b h

/-- Identity statement effects apply to matching conjoined with condition satisfaction. -/
theorem statement_allowed_spec (st : stmts.Statement) (args : stmts.Args)
    (env : condfuncs.Env) (b : Bool) (h : stmts.statement_is_allowed st args env=ok b) :
    b=true ↔ StatementAllowed st args env :=
  Verified.RustfsStatementMeaning.allowed_ok st args env b h

/-- Decimal date fields are the value of the selected byte slice, or rejection. -/
theorem date_digits_spec (s : Slice U8) (start count : Usize) (r : Option I64)
    (h : dates.digits s start count=ok r) :
    r.map (·.val)=DateDigits (nats s.val) start.val count.val :=
  Verified.RustfsDateDigits.digits_ok s start count r h

theorem date_month_days_spec (year month r : I64) (h : dates.month_days year month=ok r) :
    r.val=MonthDays year.val month.val := Verified.RustfsDateMeaning.month_ok year month r h

theorem date_civil_days_spec (year month day r : I64) (h : dates.civil_days year month day=ok r) :
    r.val=CivilDays year.val month.val day.val := Verified.RustfsDateMeaning.civil_ok year month day r h

theorem date_time_fields_spec (s : Slice U8) (r : Option (I64 × I64 × I64))
    (h : dates.time_fields s=ok r) :
    r.map (fun (a,b,c)=>(a.val,b.val,c.val))=DateTimeFields (nats s.val) :=
  Verified.RustfsDateFields.time_ok s r h

theorem date_calendar_fields_spec (s : Slice U8) (r : Option (I64 × I64 × I64))
    (h : dates.calendar_fields s=ok r) :
    r.map (fun (a,b,c)=>(a.val,b.val,c.val))=DateCalendar (nats s.val) :=
  Verified.RustfsDateFields.calendar_ok s r h

theorem date_nanos_spec (utc nano : I64) (r : I128) (h : dates.nanos utc nano=ok r) :
    r.val=InstantNanos utc.val nano.val := Verified.RustfsDateNanos.nanos_ok utc nano r h

end rustfs_kernel.Properties
