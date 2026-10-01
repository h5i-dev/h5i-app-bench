//! `policy/policy.rs`: `Policy::is_allowed` and `BucketPolicy::is_allowed`.
use crate::condfuncs::Env;
use crate::stmts::{bp_statement_is_allowed, statement_is_allowed, Args, BPStatement, BucketPolicyArgs, Effect, Statement};

fn denies_pass(sts: &[Statement], args: &Args, env: &Env) -> bool {
    let mut i = 0;
    while i < sts.len() {
        if sts[i].effect == Effect::Deny && !statement_is_allowed(&sts[i], args, env) {
            return false;
        }
        i += 1;
    }
    true
}

fn some_allow(sts: &[Statement], args: &Args, env: &Env) -> bool {
    let mut i = 0;
    while i < sts.len() {
        if sts[i].effect == Effect::Allow && statement_is_allowed(&sts[i], args, env) {
            return true;
        }
        i += 1;
    }
    false
}

/// `Policy::is_allowed`: any matching Deny refuses; then `deny_only` or
/// ownership allow; then an Allow must match.
pub fn policy_is_allowed(statements: &[Statement], args: &Args, env: &Env) -> bool {
    if !denies_pass(statements, args, env) {
        return false;
    }
    if args.deny_only {
        return true;
    }
    if args.is_owner {
        return true;
    }
    some_allow(statements, args, env)
}

fn bp_denies_pass(sts: &[BPStatement], args: &BucketPolicyArgs, env: &Env) -> bool {
    let mut i = 0;
    while i < sts.len() {
        if sts[i].effect == Effect::Deny && !bp_statement_is_allowed(&sts[i], args, env) {
            return false;
        }
        i += 1;
    }
    true
}

fn bp_some_allow(sts: &[BPStatement], args: &BucketPolicyArgs, env: &Env) -> bool {
    let mut i = 0;
    while i < sts.len() {
        if sts[i].effect == Effect::Allow && bp_statement_is_allowed(&sts[i], args, env) {
            return true;
        }
        i += 1;
    }
    false
}

/// `BucketPolicy::is_allowed`.
pub fn bucket_policy_is_allowed(statements: &[BPStatement], args: &BucketPolicyArgs, env: &Env) -> bool {
    if !bp_denies_pass(statements, args, env) {
        return false;
    }
    if args.is_owner {
        return true;
    }
    bp_some_allow(statements, args, env)
}
