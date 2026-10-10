//! Lossless condition data and helpers from policy/function/{condition,func,...}.rs.
//! Keep the existing evaluation types unchanged; retain wrapper depth for equality/keys.
use crate::{
    bytes,
    condfuncs::{IpAddr, Key},
};

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct FuncKeyValue<T> {
    pub key: Key,
    pub values: T,
}
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct InnerFunc<T> {
    pub entries: Vec<FuncKeyValue<T>>,
}
/// `FuncKeyValue::clone`.
pub fn clone_key_value<T: Clone>(entry: &FuncKeyValue<T>) -> FuncKeyValue<T> {
    FuncKeyValue {
        key: entry.key.clone(),
        values: entry.values.clone(),
    }
}
/// `InnerFunc::clone`.
pub fn clone_inner<T: Clone>(inner: &InnerFunc<T>) -> InnerFunc<T> {
    let mut entries = Vec::new();
    let mut i = 0;
    while i < inner.entries.len() {
        entries.push(clone_key_value(&inner.entries[i]));
        i += 1;
    }
    InnerFunc { entries }
}
/// `Key::is`: compare full key name, independently of the variable suffix.
pub fn key_is(key: &Key, name: &[u8]) -> bool {
    bytes::eq(&key.key_name, name)
}
/// `InnerFunc::key_names`.
pub fn key_names<T>(inner: &InnerFunc<T>) -> Vec<Vec<u8>> {
    let mut names = Vec::new();
    let mut i = 0;
    while i < inner.entries.len() {
        names.push(crate::condfuncs::key_lookup_name(&inner.entries[i].key));
        i += 1;
    }
    names
}
/// `InnerFunc::contains_key_name`.
pub fn contains_key_name<T>(inner: &InnerFunc<T>, name: &[u8]) -> bool {
    let mut i = 0;
    while i < inner.entries.len() {
        if key_is(&inner.entries[i].key, name) {
            return true;
        }
        i += 1;
    }
    false
}
pub type AddrFuncValue = Vec<(IpAddr, u8)>;
pub type AddrFunc = InnerFunc<AddrFuncValue>;
pub type BoolFuncValue = bool;
pub type BoolFunc = InnerFunc<BoolFuncValue>;
pub type NumberFuncValue = i64;
pub type NumberFunc = InnerFunc<NumberFuncValue>;
#[derive(Clone, Debug)]
pub struct DateFuncValue {
    pub unix_nanos: i128,
    pub offset_seconds: i32,
}
pub type DateFunc = InnerFunc<DateFuncValue>;
pub type StringFunc = InnerFunc<Vec<Vec<u8>>>;
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum BinaryFuncValueError {
    InvalidBase64,
}
#[derive(Clone, Debug)]
pub struct BinaryFuncValue {
    pub encoded: Vec<Vec<u8>>,
    pub decoded: Vec<Vec<u8>>,
}
pub type BinaryFunc = InnerFunc<BinaryFuncValue>;
/// `BinaryFuncValue::eq`: decoded sequence, not encoded spelling.
pub fn binary_eq(left: &BinaryFuncValue, right: &BinaryFuncValue) -> bool {
    left.decoded == right.decoded
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Op {
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
    BinaryEquals,
    IpAddress,
    NotIpAddress,
    Null,
    Boolean,
    NumericEquals,
    NumericNotEquals,
    NumericLessThan,
    NumericLessThanEquals,
    NumericGreaterThan,
    NumericGreaterThanIfExists,
    NumericGreaterThanEquals,
    DateEquals,
    DateNotEquals,
    DateLessThan,
    DateLessThanEquals,
    DateGreaterThan,
    DateGreaterThanEquals,
}
#[derive(Clone, Debug)]
pub enum Data {
    Str(StringFunc),
    Addr(AddrFunc),
    Boolean(BoolFunc),
    Num(NumberFunc),
    Date(DateFunc),
    Binary(BinaryFunc),
}
#[derive(Clone, Debug)]
pub struct Condition {
    pub op: Op,
    pub wrappers: usize,
    pub data: Data,
}
#[derive(Clone, Debug)]
pub struct Functions {
    pub for_any_value: Vec<Condition>,
    pub for_all_values: Vec<Condition>,
    pub for_normal: Vec<Condition>,
}
/// `Condition::to_key`, the base name used by to_key_with_suffix.
pub fn op_name(op: Op) -> Vec<u8> {
    match op {
        Op::StringEquals => b"StringEquals".to_vec(),
        Op::StringNotEquals => b"StringNotEquals".to_vec(),
        Op::StringEqualsIgnoreCase => b"StringEqualsIgnoreCase".to_vec(),
        Op::StringNotEqualsIgnoreCase => b"StringNotEqualsIgnoreCase".to_vec(),
        Op::StringLike => b"StringLike".to_vec(),
        Op::StringNotLike => b"StringNotLike".to_vec(),
        Op::ArnLike => b"ArnLike".to_vec(),
        Op::ArnNotLike => b"ArnNotLike".to_vec(),
        Op::ArnEquals => b"ArnEquals".to_vec(),
        Op::ArnNotEquals => b"ArnNotEquals".to_vec(),
        Op::BinaryEquals => b"BinaryEquals".to_vec(),
        Op::IpAddress => b"IpAddress".to_vec(),
        Op::NotIpAddress => b"NotIpAddress".to_vec(),
        Op::Null => b"Null".to_vec(),
        _ => op_name_late(op),
    }
}
fn op_name_late(op: Op) -> Vec<u8> {
    match op {
        Op::Boolean => b"Bool".to_vec(),
        Op::NumericEquals => b"NumericEquals".to_vec(),
        Op::NumericNotEquals => b"NumericNotEquals".to_vec(),
        Op::NumericLessThan => b"NumericLessThan".to_vec(),
        Op::NumericLessThanEquals => b"NumericLessThanEquals".to_vec(),
        Op::NumericGreaterThan => b"NumericGreaterThan".to_vec(),
        Op::NumericGreaterThanIfExists => b"NumericGreaterThanIfExists".to_vec(),
        Op::NumericGreaterThanEquals => b"NumericGreaterThanEquals".to_vec(),
        Op::DateEquals => b"DateEquals".to_vec(),
        Op::DateNotEquals => b"DateNotEquals".to_vec(),
        Op::DateLessThan => b"DateLessThan".to_vec(),
        Op::DateLessThanEquals => b"DateLessThanEquals".to_vec(),
        Op::DateGreaterThan => b"DateGreaterThan".to_vec(),
        Op::DateGreaterThanEquals => b"DateGreaterThanEquals".to_vec(),
        _ => Vec::new(),
    }
}
/// `Condition::to_key_with_suffix`, retaining nested wrappers.
pub fn to_key_with_suffix(condition: &Condition) -> Vec<u8> {
    let mut name = op_name(condition.op);
    let mut i = 0;
    while i < condition.wrappers {
        name = bytes::concat(&name, b"IfExists");
        i += 1;
    }
    name
}
/// `Condition::is_negate`: only an unwrapped NotIpAddress is negated here.
pub fn is_negate(condition: &Condition) -> bool {
    condition.wrappers == 0 && condition.op == Op::NotIpAddress
}
fn string_covers(left: &[Vec<u8>], right: &[Vec<u8>]) -> bool {
    let mut i = 0;
    while i < left.len() {
        if !bytes::member(right, &left[i]) {
            return false;
        }
        i += 1;
    }
    true
}
fn string_set_eq(left: &[Vec<u8>], right: &[Vec<u8>]) -> bool {
    string_covers(left, right) && string_covers(right, left)
}
fn string_inner_eq(left: &StringFunc, right: &StringFunc) -> bool {
    if left.entries.len() != right.entries.len() {
        return false;
    }
    let mut i = 0;
    while i < left.entries.len() {
        if left.entries[i].key != right.entries[i].key
            || !string_set_eq(&left.entries[i].values, &right.entries[i].values)
        {
            return false;
        }
        i += 1;
    }
    true
}
fn binary_inner_eq(left: &BinaryFunc, right: &BinaryFunc) -> bool {
    if left.entries.len() != right.entries.len() {
        return false;
    }
    let mut i = 0;
    while i < left.entries.len() {
        if left.entries[i].key != right.entries[i].key
            || !binary_eq(&left.entries[i].values, &right.entries[i].values)
        {
            return false;
        }
        i += 1;
    }
    true
}
/// `Condition::eq`: different variants or wrapper depths differ; inner entries remain ordered.
pub fn condition_eq(left: &Condition, right: &Condition) -> bool {
    if left.op != right.op || left.wrappers != right.wrappers {
        return false;
    }
    match (&left.data, &right.data) {
        (Data::Str(l), Data::Str(r)) => string_inner_eq(l, r),
        (Data::Binary(l), Data::Binary(r)) => binary_inner_eq(l, r),
        (Data::Addr(l), Data::Addr(r)) => l == r,
        (Data::Boolean(l), Data::Boolean(r)) => l == r,
        (Data::Num(l), Data::Num(r)) => l == r,
        (Data::Date(l), Data::Date(r)) => date_inner_eq(l, r),
        _ => false,
    }
}
fn contains_condition(set: &[Condition], c: &Condition) -> bool {
    let mut i = 0;
    while i < set.len() {
        if condition_eq(&set[i], c) {
            return true;
        }
        i += 1;
    }
    false
}
fn list_covers(left: &[Condition], right: &[Condition]) -> bool {
    let mut i = 0;
    while i < left.len() {
        if !contains_condition(right, &left[i]) {
            return false;
        }
        i += 1;
    }
    true
}
/// `Functions::eq`: equal lengths per qualifier and one-way membership, as upstream.
pub fn functions_eq(left: &Functions, right: &Functions) -> bool {
    if left.for_any_value.len() != right.for_any_value.len()
        || left.for_all_values.len() != right.for_all_values.len()
        || left.for_normal.len() != right.for_normal.len()
    {
        return false;
    }
    list_covers(&left.for_any_value, &right.for_any_value)
        && list_covers(&left.for_all_values, &right.for_all_values)
        && list_covers(&left.for_normal, &right.for_normal)
}
/// `Functions::is_empty`.
pub fn is_empty(functions: &Functions) -> bool {
    functions.for_any_value.len() == 0
        && functions.for_all_values.len() == 0
        && functions.for_normal.len() == 0
}
/// Missing std/dependency primitive: STANDARD base64 alphabet.
pub fn base64_digit(c: u8) -> Option<u8> {
    if c >= b'A' && c <= b'Z' {
        return Some(c - b'A');
    }
    if c >= b'a' && c <= b'z' {
        return Some(c - b'a' + 26);
    }
    if c >= b'0' && c <= b'9' {
        return Some(c - b'0' + 52);
    }
    if c == b'+' {
        return Some(62);
    }
    if c == b'/' {
        return Some(63);
    }
    None
}
/// `base64_simd::STANDARD.decode_to_vec`, written out for Aeneas.
pub fn decode_base64(encoded: &[u8]) -> Result<Vec<u8>, BinaryFuncValueError> {
    if encoded.len() % 4 != 0 {
        return Err(BinaryFuncValueError::InvalidBase64);
    }
    let mut out = Vec::new();
    let mut i = 0;
    while i < encoded.len() {
        let a = match base64_digit(encoded[i]) {
            Some(a) => a,
            None => return Err(BinaryFuncValueError::InvalidBase64),
        };
        let b = match base64_digit(encoded[i + 1]) {
            Some(b) => b,
            None => return Err(BinaryFuncValueError::InvalidBase64),
        };
        out.push((a << 2) | (b >> 4));
        if encoded[i + 2] == b'=' {
            if i + 4 != encoded.len() || encoded[i + 3] != b'=' || b & 15 != 0 {
                return Err(BinaryFuncValueError::InvalidBase64);
            }
            return Ok(out);
        }
        let c = match base64_digit(encoded[i + 2]) {
            Some(c) => c,
            None => return Err(BinaryFuncValueError::InvalidBase64),
        };
        out.push((b << 4) | (c >> 2));
        if encoded[i + 3] == b'=' {
            if i + 4 != encoded.len() || c & 3 != 0 {
                return Err(BinaryFuncValueError::InvalidBase64);
            }
            return Ok(out);
        }
        let d = match base64_digit(encoded[i + 3]) {
            Some(d) => d,
            None => return Err(BinaryFuncValueError::InvalidBase64),
        };
        out.push((c << 6) | d);
        i += 4;
    }
    Ok(out)
}
/// `BinaryFuncValue::new`.
pub fn binary_new(encoded: &[u8]) -> Result<BinaryFuncValue, BinaryFuncValueError> {
    binary_from_encoded_values(vec![encoded.to_vec()])
}
/// `BinaryFuncValue::from_encoded_values`: retain order and stop at the first invalid value.
pub fn binary_from_encoded_values(
    encoded: Vec<Vec<u8>>,
) -> Result<BinaryFuncValue, BinaryFuncValueError> {
    let mut decoded = Vec::new();
    let mut i = 0;
    while i < encoded.len() {
        decoded.push(decode_base64(&encoded[i])?);
        i += 1;
    }
    Ok(BinaryFuncValue { encoded, decoded })
}

fn binary_key_matches(expected: &BinaryFuncValue, requests: &[Vec<u8>]) -> bool {
    let mut matched = false;
    let mut i = 0;
    while i < requests.len() {
        let decoded = match decode_base64(&requests[i]) {
            Ok(d) => d,
            Err(_) => return false,
        };
        if bytes::member(&expected.decoded, &decoded) {
            matched = true;
        }
        i += 1;
    }
    matched
}
/// `BinaryFunc::evaluate`: all keys match; every request value must decode, even after a match.
pub fn binary_evaluate(inner: &BinaryFunc, values: &crate::condfuncs::CondValues) -> bool {
    let mut i = 0;
    while i < inner.entries.len() {
        let entry = &inner.entries[i];
        let requests = match crate::condfuncs::get_value(
            values,
            &crate::condfuncs::key_lookup_name(&entry.key),
        ) {
            Some(v) => v,
            None => return false,
        };
        if !binary_key_matches(&entry.values, &requests) {
            return false;
        }
        i += 1;
    }
    true
}
/// List projection for the existing evaluation representation.
pub fn legacy_pairs<T: Clone>(inner: &InnerFunc<T>) -> Vec<(Key, T)> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < inner.entries.len() {
        out.push((
            inner.entries[i].key.clone(),
            inner.entries[i].values.clone(),
        ));
        i += 1;
    }
    out
}
pub fn str_op(op: Op) -> crate::condfuncs::StrOp {
    use crate::condfuncs::StrOp as S;
    match op {
        Op::StringNotEquals => S::StringNotEquals,
        Op::StringEqualsIgnoreCase => S::StringEqualsIgnoreCase,
        Op::StringNotEqualsIgnoreCase => S::StringNotEqualsIgnoreCase,
        Op::StringLike => S::StringLike,
        Op::StringNotLike => S::StringNotLike,
        Op::ArnLike => S::ArnLike,
        Op::ArnNotLike => S::ArnNotLike,
        Op::ArnEquals => S::ArnEquals,
        Op::ArnNotEquals => S::ArnNotEquals,
        _ => S::StringEquals,
    }
}
pub fn num_op(op: Op) -> crate::condfuncs::NumOp {
    use crate::condfuncs::NumOp as N;
    match op {
        Op::NumericNotEquals => N::Ne,
        Op::NumericLessThan => N::Lt,
        Op::NumericLessThanEquals => N::Le,
        Op::NumericGreaterThan => N::Gt,
        Op::NumericGreaterThanIfExists | Op::NumericGreaterThanEquals => N::Ge,
        _ => N::Eq,
    }
}
/// Date/Binary matching views retain their keys; they are evaluated by the full evaluator.
pub fn condition_view(c: &Condition) -> crate::condfuncs::Condition {
    use crate::condfuncs::Cond as C;
    let cond = match &c.data {
        Data::Str(f) => C::Str(str_op(c.op), legacy_pairs(f)),
        Data::Addr(f) => C::Ip(c.op == Op::NotIpAddress, legacy_pairs(f)),
        Data::Boolean(f) => {
            if c.op == Op::Null {
                C::Null(legacy_pairs(f))
            } else {
                C::Bool(legacy_pairs(f))
            }
        }
        Data::Num(f) => C::Num(
            num_op(c.op),
            c.op == Op::NumericGreaterThanIfExists,
            legacy_pairs(f),
        ),
        Data::Date(f) => C::Null(key_presence(f)),
        Data::Binary(f) => C::Null(key_presence(f)),
    };
    crate::condfuncs::Condition {
        if_exists: c.wrappers > 0,
        cond,
    }
}
fn key_presence<T>(f: &InnerFunc<T>) -> Vec<(Key, bool)> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < f.entries.len() {
        out.push((f.entries[i].key.clone(), false));
        i += 1;
    }
    out
}
fn views(cs: &[Condition]) -> Vec<crate::condfuncs::Condition> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < cs.len() {
        out.push(condition_view(&cs[i]));
        i += 1;
    }
    out
}
pub fn matching_view(f: &Functions) -> crate::condfuncs::Functions {
    crate::condfuncs::Functions {
        for_any_value: views(&f.for_any_value),
        for_all_values: views(&f.for_all_values),
        for_normal: views(&f.for_normal),
    }
}
fn inner_has_value<T>(f: &InnerFunc<T>, values: &crate::condfuncs::CondValues) -> bool {
    let mut i = 0;
    while i < f.entries.len() {
        if crate::condfuncs::get_value(
            values,
            &crate::condfuncs::key_lookup_name(&f.entries[i].key),
        )
        .is_some()
        {
            return true;
        }
        i += 1;
    }
    false
}
pub fn has_any_key_in(c: &Condition, values: &crate::condfuncs::CondValues) -> bool {
    match &c.data {
        Data::Str(f) => inner_has_value(f, values),
        Data::Addr(f) => inner_has_value(f, values),
        Data::Boolean(f) => inner_has_value(f, values),
        Data::Num(f) => inner_has_value(f, values),
        Data::Date(f) => inner_has_value(f, values),
        Data::Binary(f) => inner_has_value(f, values),
    }
}
/// Full Date/Binary support alongside the unchanged prior condition evaluators.
pub fn condition_evaluate(
    c: &Condition,
    q: crate::condfuncs::Quantifier,
    values: &crate::condfuncs::CondValues,
    ctx: &Option<crate::awsvars::VarContext>,
    env: &crate::condfuncs::Env,
) -> bool {
    if c.wrappers > 0 && !has_any_key_in(c, values) {
        return true;
    }
    match &c.data {
        Data::Date(f) => crate::dates::evaluate(f, c.op, values),
        Data::Binary(f) => binary_evaluate(f, values),
        _ => crate::condfuncs::condition_evaluate(&condition_view(c), q, values, ctx, env),
    }
}
fn all_hold(
    cs: &[Condition],
    q: crate::condfuncs::Quantifier,
    values: &crate::condfuncs::CondValues,
    ctx: &Option<crate::awsvars::VarContext>,
    env: &crate::condfuncs::Env,
) -> bool {
    let mut i = 0;
    while i < cs.len() {
        if !condition_evaluate(&cs[i], q, values, ctx, env) {
            return false;
        }
        i += 1;
    }
    true
}
pub fn functions_evaluate(
    f: &Functions,
    values: &crate::condfuncs::CondValues,
    ctx: &Option<crate::awsvars::VarContext>,
    env: &crate::condfuncs::Env,
) -> bool {
    all_hold(
        &f.for_any_value,
        crate::condfuncs::Quantifier::ForAnyValue,
        values,
        ctx,
        env,
    ) && all_hold(
        &f.for_all_values,
        crate::condfuncs::Quantifier::ForAllValues,
        values,
        ctx,
        env,
    ) && all_hold(
        &f.for_normal,
        crate::condfuncs::Quantifier::None,
        values,
        ctx,
        env,
    )
}

fn date_inner_eq(left: &DateFunc, right: &DateFunc) -> bool {
    if left.entries.len() != right.entries.len() {
        return false;
    }
    let mut i = 0;
    while i < left.entries.len() {
        if left.entries[i].key != right.entries[i].key
            || left.entries[i].values.unix_nanos != right.entries[i].values.unix_nanos
        {
            return false;
        }
        i += 1;
    }
    true
}

/// `Condition::to_key`, including the wrapper variant itself.
pub fn to_key(c: &Condition) -> Vec<u8> {
    if c.wrappers > 0 {
        b"IfExists".to_vec()
    } else {
        op_name(c.op)
    }
}
