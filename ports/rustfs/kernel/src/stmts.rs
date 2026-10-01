//! `policy/statement.rs`: `Statement` (identity policies) and `BPStatement`
//! (bucket policies).
use crate::acts::{is_table_resource_scoped, statement_covers, Action, Family};
use crate::awsvars::{ClaimStrings, VarContext};
use crate::condfuncs::{functions_evaluate, references_key_name, CondValues, Env, Functions};
use crate::rsrc::{is_kms, set_is_match, Resource};
use crate::{bytes, wildmatch};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Effect {
    Allow,
    Deny,
}

/// `Effect::is_allowed`.
pub fn effect_is_allowed(e: Effect, allowed: bool) -> bool {
    match e {
        Effect::Allow => allowed,
        Effect::Deny => !allowed,
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Statement {
    pub effect: Effect,
    pub actions: Vec<Action>,
    pub not_actions: Vec<Action>,
    pub resources: Vec<Resource>,
    pub not_resources: Vec<Resource>,
    pub conditions: Functions,
}

/// `Principal`: AWS and service patterns.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Principal {
    pub aws: Vec<Vec<u8>>,
    pub service: Vec<Vec<u8>>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct BPStatement {
    pub effect: Effect,
    pub principal: Principal,
    pub actions: Vec<Action>,
    pub not_actions: Vec<Action>,
    pub resources: Vec<Resource>,
    pub not_resources: Vec<Resource>,
    pub conditions: Functions,
}

/// `policy::Args`, with the claims as the resolver reads them.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Args {
    pub account: Vec<u8>,
    pub action: Action,
    pub bucket: Vec<u8>,
    pub conditions: CondValues,
    pub is_owner: bool,
    pub object: Vec<u8>,
    pub claims: ClaimStrings,
    pub deny_only: bool,
}

/// `BucketPolicyArgs`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct BucketPolicyArgs {
    pub account: Vec<u8>,
    pub action: Action,
    pub bucket: Vec<u8>,
    pub conditions: CondValues,
    pub is_owner: bool,
    pub object: Vec<u8>,
}

/// `variable_resolver_for_policy_args`.
pub fn resolver_for(args: &Args, env: &Env) -> VarContext {
    let username = match &args.claims.parent_str {
        Some(p) => p.clone(),
        None => args.account.clone(),
    };
    VarContext {
        username,
        account: args.account.clone(),
        claims: args.claims.clone(),
        now_rfc3339: env.now_rfc3339.clone(),
        now_epoch: env.now_epoch.clone(),
    }
}

fn is_list_bucket(a: &Action) -> bool {
    a.family == Family::S3
        && (bytes::eq(&a.name, b"s3:ListBucket") || bytes::eq(&a.name, b"s3:ListBucketVersions")
            || bytes::eq(&a.name, b"s3:ListBucketMultipartUploads"))
}

/// `build_resource`.
pub fn build_resource(a: &Action, bucket: &[u8], object: &[u8], bucket_resource_only: bool) -> Vec<u8> {
    let bucket_only = is_list_bucket(a) && bucket_resource_only;
    let mut resource = bucket.to_vec();
    if bucket_only || object.len() == 0 {
        resource.push(b'/');
        return resource;
    }
    if !(object[0] == b'/') {
        resource.push(b'/');
    }
    bytes::concat(&resource, object)
}

fn has_family(actions: &[Action], f: Family) -> bool {
    let mut i = 0;
    while i < actions.len() {
        if actions[i].family == f {
            return true;
        }
        i += 1;
    }
    false
}

/// `skips_resource_match_for_args`.
fn skips_resource_match(st: &Statement, args: &Args) -> bool {
    if has_family(&st.actions, Family::Sts) {
        return true;
    }
    if !has_family(&st.actions, Family::Admin) {
        return false;
    }
    !(args.action.family == Family::Admin && is_table_resource_scoped(&args.action))
}

fn kms_only(rs: &[Resource]) -> Vec<Resource> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < rs.len() {
        let r = rs[i].clone();
        if is_kms(&r) {
            out.push(r);
        }
        i += 1;
    }
    out
}

/// `kms_key_scope_matches`.
fn kms_key_scope_matches(st: &Statement, args: &Args, ctx: &Option<VarContext>) -> bool {
    let backup_restore = args.action.family == Family::Kms
        && (bytes::eq(&args.action.name, b"kms:Backup") || bytes::eq(&args.action.name, b"kms:Restore"));
    if backup_restore && (st.resources.len() > 0 || st.not_resources.len() > 0) {
        return st.effect == Effect::Deny;
    }
    let kms_resources = kms_only(&st.resources);
    let kms_not_resources = kms_only(&st.not_resources);
    if kms_resources.len() == 0 && kms_not_resources.len() == 0 {
        return true;
    }
    if args.object.len() == 0 {
        return true;
    }
    let requested = bytes::concat(b"key/", &args.object);
    if kms_resources.len() > 0 && !set_is_match(&kms_resources, &requested, &args.conditions, ctx) {
        return false;
    }
    !set_is_match(&kms_not_resources, &requested, &args.conditions, ctx)
}

/// `Statement::request_reaches_condition_eval`.
pub fn reaches_condition_eval(st: &Statement, args: &Args, ctx: &Option<VarContext>) -> bool {
    let deny = st.effect == Effect::Deny;
    if !statement_covers(&st.actions, &st.not_actions, &args.action, deny) {
        return false;
    }
    if has_family(&st.actions, Family::Kms) {
        return kms_key_scope_matches(st, args, ctx);
    }
    let resource = build_resource(&args.action, &args.bucket, &args.object,
                                  references_key_name(&st.conditions, b"s3:prefix"));
    let is_admin = has_family(&st.actions, Family::Admin);
    let is_sts = has_family(&st.actions, Family::Sts);
    if st.resources.len() == 0 && st.not_resources.len() == 0 && !is_admin && !is_sts {
        return false;
    }
    if st.resources.len() > 0 && !set_is_match(&st.resources, &resource, &args.conditions, ctx)
        && !skips_resource_match(st, args) {
        return false;
    }
    if st.not_resources.len() > 0 && set_is_match(&st.not_resources, &resource, &args.conditions, ctx)
        && !skips_resource_match(st, args) {
        return false;
    }
    true
}

/// `Statement::is_allowed`.
pub fn statement_is_allowed(st: &Statement, args: &Args, env: &Env) -> bool {
    let ctx = Some(resolver_for(args, env));
    let check = reaches_condition_eval(st, args, &ctx) && functions_evaluate(&st.conditions, &args.conditions, &ctx, env);
    effect_is_allowed(st.effect, check)
}

fn any_simple_match(patterns: &[Vec<u8>], name: &[u8]) -> bool {
    let mut i = 0;
    while i < patterns.len() {
        if wildmatch::is_simple_match(&patterns[i], name) {
            return true;
        }
        i += 1;
    }
    false
}

/// `Principal::is_match`.
pub fn principal_is_match(p: &Principal, account: &[u8]) -> bool {
    any_simple_match(&p.aws, account) || any_simple_match(&p.service, account)
}

fn all_kms(actions: &[Action]) -> bool {
    let mut i = 0;
    while i < actions.len() {
        if actions[i].family != Family::Kms {
            return false;
        }
        i += 1;
    }
    true
}

/// `BPStatement::request_reaches_condition_eval`.
pub fn bp_reaches_condition_eval(st: &BPStatement, args: &BucketPolicyArgs) -> bool {
    if st.actions.len() > 0 && all_kms(&st.actions) {
        return false;
    }
    if !principal_is_match(&st.principal, &args.account) {
        return false;
    }
    let deny = st.effect == Effect::Deny;
    if !statement_covers(&st.actions, &st.not_actions, &args.action, deny) {
        return false;
    }
    let resource = build_resource(&args.action, &args.bucket, &args.object,
                                  references_key_name(&st.conditions, b"s3:prefix"));
    let none: Option<VarContext> = None;
    if st.resources.len() > 0 && !set_is_match(&st.resources, &resource, &args.conditions, &none) {
        return false;
    }
    if st.not_resources.len() > 0 && set_is_match(&st.not_resources, &resource, &args.conditions, &none) {
        return false;
    }
    true
}

/// `BPStatement::is_allowed`.
pub fn bp_statement_is_allowed(st: &BPStatement, args: &BucketPolicyArgs, env: &Env) -> bool {
    let none: Option<VarContext> = None;
    let check = bp_reaches_condition_eval(st, args) && functions_evaluate(&st.conditions, &args.conditions, &none, env);
    effect_is_allowed(st.effect, check)
}
