//! General VariableContext helpers from policy/variables.rs, alongside the fixed evaluation context.
use crate::{
    bytes,
    claims::{Claims, Value, find},
    condfuncs::CondValues,
};
pub struct VariableContext {
    pub is_https: bool,
    pub source_ip: Option<Vec<u8>>,
    pub account_id: Option<Vec<u8>>,
    pub region: Option<Vec<u8>>,
    pub username: Option<Vec<u8>>,
    pub claims: Option<Claims>,
    pub conditions: CondValues,
    pub custom_variables: Vec<(Vec<u8>, Vec<u8>)>,
}
pub struct VariableResolver {
    pub context: VariableContext,
}
/// `VariableContext::new`.
pub fn context_new() -> VariableContext {
    VariableContext {
        is_https: false,
        source_ip: None,
        account_id: None,
        region: None,
        username: None,
        claims: None,
        conditions: Vec::new(),
        custom_variables: Vec::new(),
    }
}
/// `VariableResolver::new`.
pub fn resolver_new(context: VariableContext) -> VariableResolver {
    VariableResolver { context }
}
fn clone_option(value: &Option<Vec<u8>>) -> Option<Vec<u8>> {
    match value {
        Some(v) => Some(v.clone()),
        None => None,
    }
}
fn scalar_string(value: &Value) -> Option<Vec<u8>> {
    match value {
        Value::String(s) | Value::Number(s) => Some(s.clone()),
        Value::Bool(true) => Some(b"true".to_vec()),
        Value::Bool(false) => Some(b"false".to_vec()),
        _ => None,
    }
}
fn array_strings(array: &[Value]) -> Vec<Vec<u8>> {
    let mut strings = Vec::new();
    let mut j = 0;
    while j < array.len() {
        if let Some(s) = scalar_string(&array[j]) {
            strings.push(s);
        }
        j += 1;
    }
    strings
}
/// `VariableResolver::get_claim_as_strings` on all decoded JSON scalar/array forms.
pub fn get_claim_as_strings(resolver: &VariableResolver, name: &[u8]) -> Option<Vec<Vec<u8>>> {
    let table = match &resolver.context.claims {
        Some(c) => c,
        None => return None,
    };
    let i = match find(table, name) {
        Some(i) => i,
        None => return None,
    };
    match &table[i].1 {
        Value::Array(array) => Some(array_strings(array)),
        value => match scalar_string(value) {
            Some(s) => Some(vec![s]),
            None => None,
        },
    }
}
/// `VariableResolver::resolve_username`.
pub fn resolve_username(resolver: &VariableResolver) -> Option<Vec<u8>> {
    clone_option(&resolver.context.username)
}
/// `VariableResolver::resolve_userid`.
pub fn resolve_userid(resolver: &VariableResolver) -> Option<Vec<u8>> {
    let values = match get_claim_as_strings(resolver, b"sub") {
        Some(v) => Some(v),
        None => get_claim_as_strings(resolver, b"parent"),
    };
    match values {
        Some(v) => {
            if v.len() == 0 {
                None
            } else {
                Some(v[v.len() - 1].clone())
            }
        }
        None => None,
    }
}
/// `VariableResolver::resolve_principal_type`: key presence is enough, regardless of value type.
pub fn resolve_principal_type(resolver: &VariableResolver) -> Vec<u8> {
    if let Some(table) = &resolver.context.claims {
        if find(table, b"roleArn").is_some() {
            return b"AssumedRole".to_vec();
        }
        if find(table, b"parent").is_some() && find(table, b"sa-policy").is_some() {
            return b"ServiceAccount".to_vec();
        }
    }
    b"User".to_vec()
}
/// `VariableResolver::resolve_secure_transport`.
pub fn resolve_secure_transport(resolver: &VariableResolver) -> Vec<u8> {
    if resolver.context.is_https {
        b"true".to_vec()
    } else {
        b"false".to_vec()
    }
}
/// `VariableResolver::resolve_account_id`.
pub fn resolve_account_id(resolver: &VariableResolver) -> Option<Vec<u8>> {
    clone_option(&resolver.context.account_id)
}
/// `VariableResolver::resolve_region`.
pub fn resolve_region(resolver: &VariableResolver) -> Option<Vec<u8>> {
    clone_option(&resolver.context.region)
}
/// `VariableResolver::resolve_source_ip`.
pub fn resolve_source_ip(resolver: &VariableResolver) -> Option<Vec<u8>> {
    clone_option(&resolver.context.source_ip)
}
/// `VariableResolver::resolve_custom_variable`.
pub fn resolve_custom_variable(resolver: &VariableResolver, name: &[u8]) -> Option<Vec<u8>> {
    if !bytes::starts_with(name, b"custom:") {
        return None;
    }
    let key = bytes::slice(name, 7, name.len());
    let mut i = 0;
    while i < resolver.context.custom_variables.len() {
        let (candidate, value) = &resolver.context.custom_variables[i];
        if bytes::eq(candidate, &key) {
            return Some(value.clone());
        }
        i += 1;
    }
    None
}
/// `VariableResolver::is_dynamic`.
pub fn is_dynamic(name: &[u8]) -> bool {
    bytes::eq(name, b"aws:CurrentTime") || bytes::eq(name, b"aws:EpochTime")
}
/// Trait dispatch; the two clock values arrive as explicit environment inputs.
pub fn resolve(
    resolver: &VariableResolver,
    name: &[u8],
    env: &crate::condfuncs::Env,
) -> Option<Vec<u8>> {
    if bytes::eq(name, b"aws:username") {
        return resolve_username(resolver);
    }
    if bytes::eq(name, b"aws:userid") {
        return resolve_userid(resolver);
    }
    if bytes::eq(name, b"aws:PrincipalType") {
        return Some(resolve_principal_type(resolver));
    }
    if bytes::eq(name, b"aws:SecureTransport") {
        return Some(resolve_secure_transport(resolver));
    }
    if bytes::eq(name, b"aws:CurrentTime") {
        return Some(env.now_rfc3339.clone());
    }
    if bytes::eq(name, b"aws:EpochTime") {
        return Some(env.now_epoch.clone());
    }
    if bytes::eq(name, b"aws:AccountId") {
        return resolve_account_id(resolver);
    }
    if bytes::eq(name, b"aws:Region") {
        return resolve_region(resolver);
    }
    if bytes::eq(name, b"aws:SourceIp") {
        return resolve_source_ip(resolver);
    }
    resolve_custom_variable(resolver, name)
}
pub fn resolve_multiple(
    resolver: &VariableResolver,
    name: &[u8],
    env: &crate::condfuncs::Env,
) -> Option<Vec<Vec<u8>>> {
    if bytes::eq(name, b"aws:username") {
        return match resolve_username(resolver) {
            Some(v) => Some(vec![v]),
            None => None,
        };
    }
    if bytes::eq(name, b"aws:userid") {
        return match get_claim_as_strings(resolver, b"sub") {
            Some(v) => Some(v),
            None => get_claim_as_strings(resolver, b"parent"),
        };
    }
    match resolve(resolver, name, env) {
        Some(v) => Some(vec![v]),
        None => None,
    }
}
