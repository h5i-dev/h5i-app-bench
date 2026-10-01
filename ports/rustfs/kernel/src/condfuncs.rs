//! `policy/function.rs` and `function/{condition,string,bool_null,number,addr}.rs`.
//! `Date*` and `BinaryEquals` conditions are not ported (see DEVIATIONS.md).
use crate::awsvars::{resolve_aws_variables, VarContext};
use crate::keynames::{common_key, COMMON_KEYS_LEN};
use crate::bytes;

/// The request's condition values (`HashMap<String, Vec<String>>`), one
/// entry per key.
pub type CondValues = Vec<(Vec<u8>, Vec<Vec<u8>>)>;

/// `values.get(name)`.
pub fn get_value(values: &CondValues, name: &[u8]) -> Option<Vec<Vec<u8>>> {
    let mut i = 0;
    while i < values.len() {
        if bytes::eq(&values[i].0, name) {
            return Some(values[i].1.clone());
        }
        i += 1;
    }
    None
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum IpAddr {
    V4(u32),
    V6(u128),
}

/// Parsing the request's addresses is std's (`str::parse::<IpAddr>`), given
/// as a table; so is the clock.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Env {
    pub ips: Vec<(Vec<u8>, Option<IpAddr>)>,
    pub now_rfc3339: Vec<u8>,
    pub now_epoch: Vec<u8>,
}

fn parse_ip(env: &Env, s: &[u8]) -> Option<IpAddr> {
    let mut i = 0;
    while i < env.ips.len() {
        if bytes::eq(&env.ips[i].0, s) {
            return env.ips[i].1;
        }
        i += 1;
    }
    None
}

/// A condition key (`function/key.rs` `Key`): the full key name
/// (`s3:prefix`), `KeyName::name()` (`prefix`) and the optional `/variable`.
#[derive(Debug, PartialEq, Eq)]
pub struct Key {
    pub key_name: Vec<u8>,
    pub name: Vec<u8>,
    pub variable: Option<Vec<u8>>,
}

// By hand: Aeneas has no `Option::clone`.
impl Clone for Key {
    fn clone(&self) -> Key {
        Key {
            key_name: self.key_name.clone(),
            name: self.name.clone(),
            variable: match &self.variable {
                Some(v) => Some(v.clone()),
                None => None,
            },
        }
    }
}

/// `Key::name`.
pub fn key_lookup_name(k: &Key) -> Vec<u8> {
    match &k.variable {
        Some(v) => bytes::concat(&bytes::concat(&k.name, b"/"), v),
        None => k.name.clone(),
    }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Quantifier {
    None,
    ForAnyValue,
    ForAllValues,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum StrOp {
    StringEquals,
    StringNotEquals,
    StringEqualsIgnoreCase,
    StringNotEqualsIgnoreCase,
    StringLike,
    StringNotLike,
    ArnLike,
    ArnNotLike,
    ArnEquals,
    ArnNotEquals,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum NumOp {
    Eq,
    Ne,
    Lt,
    Le,
    Gt,
    Ge,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Cond {
    Str(StrOp, Vec<(Key, Vec<Vec<u8>>)>),
    /// `IpAddress`, or `NotIpAddress` when negated. Networks are `(addr, prefix)`.
    Ip(bool, Vec<(Key, Vec<(IpAddr, u8)>)>),
    Null(Vec<(Key, bool)>),
    Bool(Vec<(Key, bool)>),
    /// The comparison and the `if_exists` argument `Condition::evaluate`
    /// passes (true only for `NumericGreaterThanIfExists`).
    Num(NumOp, bool, Vec<(Key, i64)>),
}

/// A `Condition`; `if_exists` stands for an `IfExists(..)` wrapper.
/// Nested wrappers behave as one, so one flag is enough.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Condition {
    pub if_exists: bool,
    pub cond: Cond,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Functions {
    pub for_any_value: Vec<Condition>,
    pub for_all_values: Vec<Condition>,
    pub for_normal: Vec<Condition>,
}

/// The first `COMMON_KEYS` entry with a nonempty first value replaces its
/// `${..}` name in `c`; later keys are not tried (`return` in upstream's loop).
fn replace_first_common(c: &[u8], values: &CondValues) -> Vec<u8> {
    let mut k = 0;
    while k < COMMON_KEYS_LEN {
        let (name, var_name) = common_key(k);
        match get_value(values, &name) {
            Some(vs) => {
                if vs.len() > 0 && vs[0].len() > 0 {
                    return bytes::replace(c, &var_name, &vs[0]);
                }
            }
            None => {}
        }
        k += 1;
    }
    c.to_vec()
}

/// The policy's values for one key: variables resolved, the first common key
/// substituted, lowercased when `ignore_case`.
fn policy_values(policy: &[Vec<u8>], values: &CondValues, ctx: &Option<VarContext>, ignore_case: bool) -> Vec<Vec<u8>> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < policy.len() {
        let resolved = match ctx {
            Some(c) => resolve_aws_variables(c, &policy[i]),
            None => {
                let mut v = Vec::new();
                v.push(policy[i].clone());
                v
            }
        };
        let mut j = 0;
        while j < resolved.len() {
            let x = replace_first_common(&resolved[j], values);
            out.push(if ignore_case { bytes::lower(&x) } else { x });
            j += 1;
        }
        i += 1;
    }
    out
}

/// `FuncKeyValue<StringFuncValue>::eval`.
fn str_eval(key: &Key, policy: &[Vec<u8>], q: Quantifier, ignore_case: bool, negate: bool, values: &CondValues,
            ctx: &Option<VarContext>) -> bool {
    let rvalues = match get_value(values, &key_lookup_name(key)) {
        Some(v) => v,
        None => Vec::new(),
    };
    let fvalues = policy_values(policy, values, ctx, ignore_case);
    let mut i = 0;
    while i < rvalues.len() {
        let r = if ignore_case { bytes::lower(&rvalues[i]) } else { rvalues[i].clone() };
        let hit = bytes::member(&fvalues, &r);
        match q {
            Quantifier::None => {
                if hit {
                    return true;
                }
            }
            Quantifier::ForAllValues => {
                if !(hit ^ negate) {
                    return false;
                }
            }
            Quantifier::ForAnyValue => {
                if hit ^ negate {
                    return true;
                }
            }
        }
        i += 1;
    }
    q == Quantifier::ForAllValues
}

fn any_like(cands: &[Vec<u8>], v: &[u8]) -> bool {
    let mut i = 0;
    while i < cands.len() {
        if crate::wildmatch::is_match(&cands[i], v) {
            return true;
        }
        i += 1;
    }
    false
}

/// One value of the `eval_like` loop: `Some(answer)` when it decides.
fn like_step(cands: &[Vec<u8>], v: &[u8], q: Quantifier, negate: bool) -> Option<bool> {
    let matched = any_like(cands, v);
    let holds = match q {
        Quantifier::None => matched,
        _ => matched ^ negate,
    };
    match q {
        Quantifier::ForAllValues => {
            if !holds { Some(false) } else { None }
        }
        _ => {
            if holds { Some(true) } else { None }
        }
    }
}

/// `FuncKeyValue<StringFuncValue>::eval_like`.
fn str_eval_like(key: &Key, policy: &[Vec<u8>], q: Quantifier, negate: bool, values: &CondValues,
                 ctx: &Option<VarContext>) -> bool {
    let rvalues = match get_value(values, &key_lookup_name(key)) {
        Some(v) => v,
        None => return q == Quantifier::ForAllValues,
    };
    let cands = policy_values(policy, values, ctx, false);
    let mut i = 0;
    while i < rvalues.len() {
        match like_step(&cands, &rvalues[i], q, negate) {
            Some(b) => return b,
            None => {}
        }
        i += 1;
    }
    q == Quantifier::ForAllValues
}

/// `StringFunc::evaluate_with_resolver`.
fn str_func(funcs: &[(Key, Vec<Vec<u8>>)], q: Quantifier, ignore_case: bool, like: bool, negate: bool,
            values: &CondValues, ctx: &Option<VarContext>) -> bool {
    let mut i = 0;
    while i < funcs.len() {
        let (key, policy) = (&funcs[i].0, &funcs[i].1);
        let result = match q {
            Quantifier::None => {
                let matched = if like {
                    str_eval_like(key, policy, q, false, values, ctx)
                } else {
                    str_eval(key, policy, q, ignore_case, false, values, ctx)
                };
                matched ^ negate
            }
            _ => {
                if like {
                    str_eval_like(key, policy, q, negate, values, ctx)
                } else {
                    str_eval(key, policy, q, ignore_case, negate, values, ctx)
                }
            }
        };
        if !result {
            return false;
        }
        i += 1;
    }
    true
}

fn net_contains(net: IpAddr, prefix: u8, ip: IpAddr) -> bool {
    match (net, ip) {
        (IpAddr::V4(n), IpAddr::V4(a)) => {
            if prefix == 0 {
                return true;
            }
            if prefix >= 32 {
                return n == a;
            }
            (n >> (32 - prefix)) == (a >> (32 - prefix))
        }
        (IpAddr::V6(n), IpAddr::V6(a)) => {
            if prefix == 0 {
                return true;
            }
            if prefix >= 128 {
                return n == a;
            }
            (n >> (128 - prefix)) == (a >> (128 - prefix))
        }
        _ => false,
    }
}

fn any_net(nets: &[(IpAddr, u8)], ip: IpAddr) -> bool {
    let mut i = 0;
    while i < nets.len() {
        if net_contains(nets[i].0, nets[i].1, ip) {
            return true;
        }
        i += 1;
    }
    false
}

/// One key of `AddrFunc::evaluate`: `Some(answer)` when it decides.
fn addr_key(rvalues: &[Vec<u8>], nets: &[(IpAddr, u8)], env: &Env) -> Option<bool> {
    let mut i = 0;
    while i < rvalues.len() {
        let ip = match parse_ip(env, &rvalues[i]) {
            Some(ip) => ip,
            None => return Some(false),
        };
        if any_net(nets, ip) {
            return Some(true);
        }
        i += 1;
    }
    None
}

/// `AddrFunc::evaluate`: any address of any key in any network; an
/// unparseable address ends it with `false`.
fn addr_func(funcs: &[(Key, Vec<(IpAddr, u8)>)], values: &CondValues, env: &Env) -> bool {
    let mut i = 0;
    while i < funcs.len() {
        let rvalues = match get_value(values, &key_lookup_name(&funcs[i].0)) {
            Some(v) => v,
            None => Vec::new(),
        };
        match addr_key(&rvalues, &funcs[i].1, env) {
            Some(b) => return b,
            None => {}
        }
        i += 1;
    }
    false
}

fn first_value(values: &CondValues, key: &Key) -> Option<Vec<u8>> {
    match get_value(values, &key_lookup_name(key)) {
        Some(v) => {
            if v.len() > 0 { Some(v[0].clone()) } else { None }
        }
        None => None,
    }
}

/// `BoolFunc::evaluate_bool`: the first value is `"true"` or `"false"` as written.
fn bool_func(funcs: &[(Key, bool)], values: &CondValues) -> bool {
    let mut i = 0;
    while i < funcs.len() {
        let ok = match first_value(values, &funcs[i].0) {
            Some(x) => {
                if funcs[i].1 { bytes::eq(&x, b"true") } else { bytes::eq(&x, b"false") }
            }
            None => false,
        };
        if !ok {
            return false;
        }
        i += 1;
    }
    true
}

/// `values.get(key.name()).map(Vec::len).unwrap_or(0)`.
fn value_count(values: &CondValues, key: &Key) -> usize {
    match get_value(values, &key_lookup_name(key)) {
        Some(v) => v.len(),
        None => 0,
    }
}

/// `if inner.values.0 { len == 0 } else { len != 0 }`.
fn null_ok(want_null: bool, len: usize) -> bool {
    if want_null { len == 0 } else { len != 0 }
}

/// `BoolFunc::evaluate_null`.
fn null_func(funcs: &[(Key, bool)], values: &CondValues) -> bool {
    let mut i = 0;
    while i < funcs.len() {
        if !null_ok(funcs[i].1, value_count(values, &funcs[i].0)) {
            return false;
        }
        i += 1;
    }
    true
}

fn num_op(op: NumOp, a: i64, b: i64) -> bool {
    match op {
        NumOp::Eq => a == b,
        NumOp::Ne => a != b,
        NumOp::Lt => a < b,
        NumOp::Le => a <= b,
        NumOp::Gt => a > b,
        NumOp::Ge => a >= b,
    }
}

/// `NumberFunc::evaluate`: a missing key ends it with `if_exists`.
fn num_func(op: NumOp, if_exists: bool, funcs: &[(Key, i64)], values: &CondValues) -> bool {
    let mut i = 0;
    while i < funcs.len() {
        let v = match first_value(values, &funcs[i].0) {
            Some(v) => v,
            None => return if_exists,
        };
        let rv = match bytes::parse_i64(&v) {
            Some(n) => n,
            None => return false,
        };
        if !num_op(op, rv, funcs[i].1) {
            return false;
        }
        i += 1;
    }
    true
}

fn keys_present<T>(funcs: &[(Key, T)], values: &CondValues) -> bool {
    let mut i = 0;
    while i < funcs.len() {
        match get_value(values, &key_lookup_name(&funcs[i].0)) {
            Some(_) => return true,
            None => {}
        }
        i += 1;
    }
    false
}

/// `Condition::has_any_key_in`.
fn has_any_key_in(c: &Cond, values: &CondValues) -> bool {
    match c {
        Cond::Str(_, f) => keys_present(f, values),
        Cond::Ip(_, f) => keys_present(f, values),
        Cond::Null(f) => keys_present(f, values),
        Cond::Bool(f) => keys_present(f, values),
        Cond::Num(_, _, f) => keys_present(f, values),
    }
}

/// `Condition::evaluate_with_resolver` without an `IfExists` wrapper.
fn eval_cond(c: &Cond, q: Quantifier, values: &CondValues, ctx: &Option<VarContext>, env: &Env) -> bool {
    match c {
        Cond::Str(op, f) => {
            let (ignore_case, like, negate) = match op {
                StrOp::StringEquals => (false, false, false),
                StrOp::StringNotEquals => (false, false, true),
                StrOp::StringEqualsIgnoreCase => (true, false, false),
                StrOp::StringNotEqualsIgnoreCase => (true, false, true),
                StrOp::StringLike => (false, true, false),
                StrOp::StringNotLike => (false, true, true),
                StrOp::ArnLike => (false, true, false),
                StrOp::ArnNotLike => (false, true, true),
                StrOp::ArnEquals => (false, false, false),
                StrOp::ArnNotEquals => (false, false, true),
            };
            str_func(f, q, ignore_case, like, negate, values, ctx)
        }
        Cond::Ip(negate, f) => {
            let r = addr_func(f, values, env);
            if *negate { !r } else { r }
        }
        Cond::Null(f) => null_func(f, values),
        Cond::Bool(f) => bool_func(f, values),
        Cond::Num(op, if_exists, f) => num_func(*op, *if_exists, f, values),
    }
}

/// `Condition::evaluate_with_resolver`.
pub fn condition_evaluate(c: &Condition, q: Quantifier, values: &CondValues, ctx: &Option<VarContext>, env: &Env) -> bool {
    if c.if_exists && !has_any_key_in(&c.cond, values) {
        return true;
    }
    eval_cond(&c.cond, q, values, ctx, env)
}

fn all_hold(cs: &[Condition], q: Quantifier, values: &CondValues, ctx: &Option<VarContext>, env: &Env) -> bool {
    let mut i = 0;
    while i < cs.len() {
        if !condition_evaluate(&cs[i], q, values, ctx, env) {
            return false;
        }
        i += 1;
    }
    true
}

/// `Functions::evaluate_with_resolver`.
pub fn functions_evaluate(f: &Functions, values: &CondValues, ctx: &Option<VarContext>, env: &Env) -> bool {
    all_hold(&f.for_any_value, Quantifier::ForAnyValue, values, ctx, env)
        && all_hold(&f.for_all_values, Quantifier::ForAllValues, values, ctx, env)
        && all_hold(&f.for_normal, Quantifier::None, values, ctx, env)
}

fn keys_named<T>(funcs: &[(Key, T)], key_name: &[u8]) -> bool {
    let mut i = 0;
    while i < funcs.len() {
        if bytes::eq(&funcs[i].0.key_name, key_name) {
            return true;
        }
        i += 1;
    }
    false
}

fn cond_references(c: &Cond, key_name: &[u8]) -> bool {
    match c {
        Cond::Str(_, f) => keys_named(f, key_name),
        Cond::Ip(_, f) => keys_named(f, key_name),
        Cond::Null(f) => keys_named(f, key_name),
        Cond::Bool(f) => keys_named(f, key_name),
        Cond::Num(_, _, f) => keys_named(f, key_name),
    }
}

fn any_references(cs: &[Condition], key_name: &[u8]) -> bool {
    let mut i = 0;
    while i < cs.len() {
        if cond_references(&cs[i].cond, key_name) {
            return true;
        }
        i += 1;
    }
    false
}

/// `Functions::references_key_name`.
pub fn references_key_name(f: &Functions, key_name: &[u8]) -> bool {
    any_references(&f.for_any_value, key_name) || any_references(&f.for_all_values, key_name)
        || any_references(&f.for_normal, key_name)
}
