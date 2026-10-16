//! Policy metadata, equality and management from policy/{policy,statement}.rs.
use crate::{
    acts::Action,
    bytes,
    conddata::Functions,
    rsrc::Resource,
    stmts::{Effect, Principal},
    valids::{ErrorKind, ValidationError},
};
#[derive(Clone, Debug)]
pub struct Statement {
    pub sid: Vec<u8>,
    pub effect: Effect,
    pub actions: Vec<Action>,
    pub not_actions: Vec<Action>,
    pub resources: Vec<Resource>,
    pub not_resources: Vec<Resource>,
    pub conditions: Functions,
}
#[derive(Clone, Debug)]
pub struct BPStatement {
    pub sid: Vec<u8>,
    pub effect: Effect,
    pub principal: Principal,
    pub actions: Vec<Action>,
    pub not_actions: Vec<Action>,
    pub resources: Vec<Resource>,
    pub not_resources: Vec<Resource>,
    pub conditions: Functions,
}
#[derive(Clone, Debug)]
pub struct Policy {
    pub id: Vec<u8>,
    pub version: Vec<u8>,
    pub statements: Vec<Statement>,
}
#[derive(Clone, Debug)]
pub struct BucketPolicy {
    pub id: Vec<u8>,
    pub version: Vec<u8>,
    pub statements: Vec<BPStatement>,
}
/// Statement equality ignores SID, and uses each upstream field's equality.
pub fn statement_eq(left: &Statement, right: &Statement) -> bool {
    left.effect == right.effect
        && crate::actsets::eq(&left.actions, &right.actions)
        && crate::actsets::eq(&left.not_actions, &right.not_actions)
        && crate::resets::eq(&left.resources, &right.resources)
        && crate::resets::eq(&left.not_resources, &right.not_resources)
        && crate::conddata::functions_eq(&left.conditions, &right.conditions)
}
fn index_member(indices: &[usize], index: usize) -> bool {
    let mut i = 0;
    while i < indices.len() {
        if indices[i] == index {
            return true;
        }
        i += 1;
    }
    false
}
fn mark_duplicates(statements: &[Statement], i: usize, dups: &mut Vec<usize>) {
    let mut j = i + 1;
    while j < statements.len() {
        if statement_eq(&statements[i], &statements[j]) {
            if !index_member(dups, j) {
                dups.push(j);
            }
        }
        j += 1;
    }
}
/// Preserve upstream's comparison direction and the first retained SID.
pub fn drop_duplicate_statements(policy: &mut Policy) {
    let mut dups = Vec::new();
    let mut i = 0;
    while i < policy.statements.len() {
        if !index_member(&dups, i) {
            mark_duplicates(&policy.statements, i, &mut dups);
        }
        i += 1;
    }
    policy.statements = retained_statements(&policy.statements, &dups);
}
fn retained_statements(statements: &[Statement], dups: &[usize]) -> Vec<Statement> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < statements.len() {
        if !index_member(dups, i) {
            out.push(statements[i].clone());
        }
        i += 1;
    }
    out
}
/// Empty merged ID, first nonempty version, concatenated statements then deduplication.
pub fn merge_policies(inputs: &[Policy]) -> Policy {
    let mut merged = Policy {
        id: Vec::new(),
        version: Vec::new(),
        statements: Vec::new(),
    };
    let mut i = 0;
    while i < inputs.len() {
        if merged.version.len() == 0 {
            merged.version = inputs[i].version.clone();
        }
        append_statements(&mut merged.statements, &inputs[i].statements);
        i += 1;
    }
    drop_duplicate_statements(&mut merged);
    merged
}
fn append_statements(out: &mut Vec<Statement>, entries: &[Statement]) {
    let mut i = 0;
    while i < entries.len() {
        out.push(entries[i].clone());
        i += 1;
    }
}
pub fn is_empty(policy: &Policy) -> bool {
    policy.statements.len() == 0
}
pub fn match_resource(policy: &Policy, resource: &[u8]) -> bool {
    let mut i = 0;
    while i < policy.statements.len() {
        if crate::resets::set_match_resource(&policy.statements[i].resources, resource) {
            return true;
        }
        i += 1;
    }
    false
}
fn version_is_valid(version: &[u8]) -> Result<(), ValidationError> {
    if version.len() != 0 && !bytes::eq(version, &crate::defaults::default_version()) {
        return Err(ValidationError {
            kind: ErrorKind::InvalidVersion,
            family: Vec::new(),
            value: version.to_vec(),
        });
    }
    Ok(())
}
/// The matching view retains every key reference; conditions are evaluated separately.
pub fn statement_view(st: &Statement) -> crate::stmts::Statement {
    crate::stmts::Statement {
        effect: st.effect,
        actions: st.actions.clone(),
        not_actions: st.not_actions.clone(),
        resources: st.resources.clone(),
        not_resources: st.not_resources.clone(),
        conditions: crate::conddata::matching_view(&st.conditions),
    }
}
pub fn bp_statement_view(st: &BPStatement) -> crate::stmts::BPStatement {
    crate::stmts::BPStatement {
        effect: st.effect,
        principal: st.principal.clone(),
        actions: st.actions.clone(),
        not_actions: st.not_actions.clone(),
        resources: st.resources.clone(),
        not_resources: st.not_resources.clone(),
        conditions: crate::conddata::matching_view(&st.conditions),
    }
}
pub fn is_valid(policy: &Policy) -> Result<(), ValidationError> {
    version_is_valid(&policy.version)?;
    let mut i = 0;
    while i < policy.statements.len() {
        let st = &policy.statements[i];
        crate::valids::statement_is_valid(&statement_view(st), &st.sid)?;
        i += 1;
    }
    Ok(())
}
pub fn validate(policy: &Policy) -> Result<(), ValidationError> {
    is_valid(policy)
}
pub fn bucket_is_valid(policy: &BucketPolicy) -> Result<(), ValidationError> {
    version_is_valid(&policy.version)?;
    let mut i = 0;
    while i < policy.statements.len() {
        let st = &policy.statements[i];
        crate::valids::bp_statement_is_valid(&bp_statement_view(st), &st.sid)?;
        i += 1;
    }
    Ok(())
}
/// Serialized duplicate operator names overwrite earlier conditions, as in serde_json::to_value.
fn overwritten(cs: &[crate::conddata::Condition], i: usize) -> bool {
    let name = crate::conddata::to_key_with_suffix(&cs[i]);
    let mut j = i + 1;
    while j < cs.len() {
        if bytes::eq(&name, &crate::conddata::to_key_with_suffix(&cs[j])) {
            return true;
        }
        j += 1;
    }
    false
}
fn condition_uses_tag(c: &crate::conddata::Condition) -> bool {
    match &c.data {
        crate::conddata::Data::Str(f) => {
            crate::conddata::contains_key_name(f, b"s3:ExistingObjectTag")
        }
        crate::conddata::Data::Addr(f) => {
            crate::conddata::contains_key_name(f, b"s3:ExistingObjectTag")
        }
        crate::conddata::Data::Boolean(f) => {
            crate::conddata::contains_key_name(f, b"s3:ExistingObjectTag")
        }
        crate::conddata::Data::Num(f) => {
            crate::conddata::contains_key_name(f, b"s3:ExistingObjectTag")
        }
        crate::conddata::Data::Date(f) => {
            crate::conddata::contains_key_name(f, b"s3:ExistingObjectTag")
        }
        crate::conddata::Data::Binary(f) => {
            crate::conddata::contains_key_name(f, b"s3:ExistingObjectTag")
        }
    }
}
fn list_uses_tag(cs: &[crate::conddata::Condition]) -> bool {
    let mut i = 0;
    while i < cs.len() {
        if !overwritten(cs, i) && condition_uses_tag(&cs[i]) {
            return true;
        }
        i += 1;
    }
    false
}
pub fn functions_use_existing_object_tag(f: &Functions) -> bool {
    list_uses_tag(&f.for_all_values)
        || list_uses_tag(&f.for_any_value)
        || list_uses_tag(&f.for_normal)
}
pub fn policy_uses_existing_object_tag_conditions(p: &Policy) -> bool {
    let mut i = 0;
    while i < p.statements.len() {
        if functions_use_existing_object_tag(&p.statements[i].conditions) {
            return true;
        }
        i += 1;
    }
    false
}
pub fn bucket_policy_uses_existing_object_tag_conditions(p: &BucketPolicy) -> bool {
    let mut i = 0;
    while i < p.statements.len() {
        if functions_use_existing_object_tag(&p.statements[i].conditions) {
            return true;
        }
        i += 1;
    }
    false
}
pub fn policy_needs_existing_object_tag_for_args(
    p: &Policy,
    args: &crate::stmts::Args,
    env: &crate::condfuncs::Env,
) -> bool {
    if !policy_uses_existing_object_tag_conditions(p) {
        return false;
    }
    let ctx = Some(crate::stmts::resolver_for(args, env));
    let mut i = 0;
    while i < p.statements.len() {
        let st = &p.statements[i];
        if functions_use_existing_object_tag(&st.conditions)
            && crate::stmts::reaches_condition_eval(&statement_view(st), args, &ctx)
        {
            return true;
        }
        i += 1;
    }
    false
}
pub fn bucket_policy_needs_existing_object_tag_for_args(
    p: &BucketPolicy,
    args: &crate::stmts::BucketPolicyArgs,
) -> bool {
    if !bucket_policy_uses_existing_object_tag_conditions(p) {
        return false;
    }
    let mut i = 0;
    while i < p.statements.len() {
        let st = &p.statements[i];
        if functions_use_existing_object_tag(&st.conditions)
            && crate::stmts::bp_reaches_condition_eval(&bp_statement_view(st), args)
        {
            return true;
        }
        i += 1;
    }
    false
}
/// Full metadata entry points compose prior request matching with Date/Binary-aware evaluation.
pub fn statement_is_allowed(
    st: &Statement,
    args: &crate::stmts::Args,
    env: &crate::condfuncs::Env,
) -> bool {
    let ctx = Some(crate::stmts::resolver_for(args, env));
    crate::stmts::effect_is_allowed(
        st.effect,
        crate::stmts::reaches_condition_eval(&statement_view(st), args, &ctx)
            && crate::conddata::functions_evaluate(&st.conditions, &args.conditions, &ctx, env),
    )
}
pub fn bp_statement_is_allowed(
    st: &BPStatement,
    args: &crate::stmts::BucketPolicyArgs,
    env: &crate::condfuncs::Env,
) -> bool {
    crate::stmts::effect_is_allowed(
        st.effect,
        crate::stmts::bp_reaches_condition_eval(&bp_statement_view(st), args)
            && crate::conddata::functions_evaluate(&st.conditions, &args.conditions, &None, env),
    )
}
pub fn policy_is_allowed(
    p: &Policy,
    args: &crate::stmts::Args,
    env: &crate::condfuncs::Env,
) -> bool {
    if !denies_clear(p, args, env) {
        return false;
    }
    if args.deny_only || args.is_owner {
        return true;
    }
    allows_match(p, args, env)
}
fn denies_clear(p: &Policy, args: &crate::stmts::Args, env: &crate::condfuncs::Env) -> bool {
    let mut i = 0;
    while i < p.statements.len() {
        let st = &p.statements[i];
        if st.effect == Effect::Deny && !statement_is_allowed(st, args, env) {
            return false;
        }
        i += 1;
    }
    true
}
fn allows_match(p: &Policy, args: &crate::stmts::Args, env: &crate::condfuncs::Env) -> bool {
    let mut i = 0;
    while i < p.statements.len() {
        let st = &p.statements[i];
        if st.effect == Effect::Allow && statement_is_allowed(st, args, env) {
            return true;
        }
        i += 1;
    }
    false
}
pub fn bucket_policy_is_allowed(
    p: &BucketPolicy,
    args: &crate::stmts::BucketPolicyArgs,
    env: &crate::condfuncs::Env,
) -> bool {
    if !bucket_denies_clear(p, args, env) {
        return false;
    }
    if args.is_owner {
        return true;
    }
    bucket_allows_match(p, args, env)
}
fn bucket_denies_clear(
    p: &BucketPolicy,
    args: &crate::stmts::BucketPolicyArgs,
    env: &crate::condfuncs::Env,
) -> bool {
    let mut i = 0;
    while i < p.statements.len() {
        let st = &p.statements[i];
        if st.effect == Effect::Deny && !bp_statement_is_allowed(st, args, env) {
            return false;
        }
        i += 1;
    }
    true
}
fn bucket_allows_match(
    p: &BucketPolicy,
    args: &crate::stmts::BucketPolicyArgs,
    env: &crate::condfuncs::Env,
) -> bool {
    let mut i = 0;
    while i < p.statements.len() {
        let st = &p.statements[i];
        if st.effect == Effect::Allow && bp_statement_is_allowed(st, args, env) {
            return true;
        }
        i += 1;
    }
    false
}
