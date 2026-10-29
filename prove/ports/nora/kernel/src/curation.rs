//! Curation control flow at f864a9a. Adapter supplies each ProxyFilter's
//! deterministic outcome for the same request. Text is represented by stable
//! opaque u64 handles; rule.contains("integrity") is carried with the rule.
//! Formatting, SHA-256, request construction, trait dispatch and metrics sinks
//! are boundaries. We retain exact rule/reason/filter identity, audit behavior,
//! metric increments (at most one per counter), and final HTTP-block payload.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Mode { Off, Audit, Enforce }
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Decision { Allow, Block { rule: u64, reason: u64, integrity_rule: bool }, Skip }
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Filter { pub name: u64, pub decision: Decision }
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Effect { None, Allowed, Blocked }
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Evaluation {
    pub decision: Decision,
    pub decided_by: Option<u64>,
    pub audited: bool,
    pub effect: Effect,
    pub without_integrity: bool,
}
pub fn is_active(mode: Mode) -> bool { !matches!(mode, Mode::Off) }
pub fn evaluate_chain(mode: Mode, filters: &[Filter]) -> Evaluation {
    let mut i = 0;
    while i < filters.len() {
        let filter = filters[i];
        match filter.decision {
            Decision::Allow => return Evaluation { decision: filter.decision,
                decided_by: Some(filter.name), audited: false, effect: Effect::Allowed,
                without_integrity: false },
            Decision::Block { .. } => {
                let audited = matches!(mode, Mode::Audit);
                let effect = if audited { Effect::Allowed } else { Effect::Blocked };
                return Evaluation { decision: filter.decision, decided_by: Some(filter.name),
                    audited, effect, without_integrity: false };
            }
            Decision::Skip => { i += 1; }
        }
    }
    Evaluation { decision: Decision::Allow, decided_by: None, audited: false,
        effect: Effect::Allowed, without_integrity: false }
}
pub fn evaluate_inner(mode: Mode, namespace: Option<Filter>, filters: &[Filter],
    bypass: bool, integrity_present: bool, bypass_name: u64) -> Evaluation {
    if let Some(ns) = namespace {
        if let Decision::Block { .. } = ns.decision {
            return Evaluation { decision: ns.decision, decided_by: Some(ns.name),
                audited: false, effect: Effect::Blocked, without_integrity: false };
        }
    }
    if matches!(mode, Mode::Off) {
        return Evaluation { decision: Decision::Allow, decided_by: None,
            audited: false, effect: Effect::None, without_integrity: false };
    }
    if bypass {
        return Evaluation { decision: Decision::Allow, decided_by: Some(bypass_name),
            audited: false, effect: Effect::Allowed, without_integrity: false };
    }
    let mut result = evaluate_chain(mode, filters);
    result.without_integrity = !integrity_present;
    result
}
/// Telemetry label: allow=0, audit=1, block=2, skip=3.
pub fn evaluate(mode: Mode, namespace: Option<Filter>, filters: &[Filter],
    bypass: bool, integrity_present: bool, bypass_name: u64) -> (Evaluation, u8) {
    let result = evaluate_inner(mode, namespace, filters, bypass, integrity_present, bypass_name);
    let label = match result.decision {
        Decision::Allow => 0,
        Decision::Block { .. } => if result.audited { 1 } else { 2 },
        Decision::Skip => 3,
    };
    (result, label)
}
/// Response payload for enforced download blocks. None means continue.
pub fn download_response(result: Evaluation) -> Option<(u64,u64)> {
    match result.decision {
        Decision::Block { rule, reason, .. } => if result.audited { None } else { Some((rule,reason)) },
        _ => None,
    }
}
pub fn check_namespace_isolation(namespace: Option<Filter>) -> (Option<(u64,u64)>, Effect) {
    if let Some(ns) = namespace {
        if let Decision::Block { rule, reason, .. } = ns.decision {
            return (Some((rule,reason)), Effect::Blocked);
        }
    }
    (None, Effect::None)
}
pub fn is_internal_namespace(namespace: Option<Filter>) -> bool {
    match namespace { Some(ns) => matches!(ns.decision, Decision::Block { .. }), None => false }
}
pub fn namespace_filter_active(namespace: Option<Filter>) -> bool { namespace.is_some() }
/// Integrity handlers share this post-evaluation branch, with the rule's
/// substring result supplied by the stable-text adapter.
pub fn integrity_response(result: Evaluation) -> Option<(u64,u64)> {
    match result.decision {
        Decision::Block { rule, reason, integrity_rule } => {
            if !integrity_rule { return None; }
            if result.audited { None } else { Some((rule,reason)) }
        }
        _ => None,
    }
}
/// Header text is parsed before this boundary; an invalid/missing header is None.
/// Stable handles use the same equality as UTF-8 text. Constant-time execution
/// of the upstream comparison is not modeled by this decision-only port.
pub fn check_download(mode: Mode, namespace: Option<Filter>, filters: &[Filter],
    configured_token: Option<u64>, header_token: Option<u64>, bypass_name: u64)
    -> Option<(u64,u64)> {
    let bypass = match configured_token {
        Some(token) => match header_token { Some(header) => header == token, None => false },
        None => false,
    };
    let (result, _) = evaluate(mode, namespace, filters, bypass, false, bypass_name);
    download_response(result)
}
/// Filters are evaluated for the post-download request with the computed
/// SHA-256 in its integrity field. Hash computation itself is a crypto boundary.
pub fn verify_integrity(mode: Mode, namespace: Option<Filter>, filters: &[Filter],
    bypass_name: u64) -> Option<(u64,u64)> {
    if !is_active(mode) { return None; }
    let (result, _) = evaluate(mode, namespace, filters, false, true, bypass_name);
    integrity_response(result)
}
/// Caller adapter validates the upstream sha256:<64hex> assertion.
pub fn verify_integrity_by_hash(mode: Mode, namespace: Option<Filter>, filters: &[Filter],
    bypass_name: u64, hash_valid: bool) -> Option<(u64,u64)> {
    assert!(hash_valid);
    if !is_active(mode) { return None; }
    let (result, _) = evaluate(mode, namespace, filters, false, true, bypass_name);
    integrity_response(result)
}
