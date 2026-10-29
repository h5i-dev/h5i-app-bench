// Verbatim pinned items; declarations/imports only adapted for the test crate.
use crate::config::{CurationConfig,CurationMode};
use crate::RegistryType;
use crate::{axum,sha2,hex};
use crate::ConstantTimeEq;
use crate::axum::response::{Response,IntoResponse};
use std::sync::atomic::{AtomicU64,Ordering};
pub struct FilterRequest {
    /// Which registry format this request targets.
    pub registry: RegistryType,
    /// Upstream URL being proxied to (if any).
    pub upstream: Option<String>,
    /// Package/artifact name (e.g., "lodash", "com.google.guava:guava").
    pub name: String,
    /// Version string (e.g., "4.17.21", "33.0.0-jre").
    pub version: Option<String>,
    /// Integrity hash provided by the client (e.g., sha256 checksum).
    pub integrity: Option<String>,
    /// Whether the request carries a valid bypass token.
    pub bypass: bool,
    /// Publish date as Unix timestamp (seconds). None = unknown.
    pub publish_date: Option<i64>,
}

#[derive(Debug,Clone,PartialEq)]
pub enum Decision {
    /// Explicitly allow this request.
    Allow,
    /// Block this request with a rule name and human-readable reason.
    Block { rule: String, reason: String },
    /// This filter has no opinion — continue to the next filter.
    Skip,
}

pub trait ProxyFilter: Send + Sync {
    /// Unique name of this filter (e.g., "blocklist", "allowlist").
    fn name(&self) -> &'static str;

    /// Evaluate a request and return a decision.
    fn evaluate(&self, request: &FilterRequest) -> Decision;
}

pub struct EvaluationResult {
    /// The final decision after the chain ran.
    pub decision: Decision,
    /// Name of the filter that produced the decision (None if no filter matched).
    pub decided_by: Option<String>,
    /// Whether this result is audit-only (decision logged but not enforced).
    pub audited: bool,
}

pub struct CurationEngine {
    config: CurationConfig,
    filters: Vec<Box<dyn ProxyFilter>>,
    /// Namespace isolation filter — always active, even in Off mode.
    namespace_filter: Option<Box<dyn ProxyFilter>>,
    metrics: CurationMetrics,
}

impl CurationEngine {
    /// Create a new engine with no filters.
    pub fn new(config: CurationConfig) -> Self {
        Self {
            config,
            filters: Vec::new(),
            namespace_filter: None,
            metrics: CurationMetrics::new(),
        }
    }

    /// Add a filter to the end of the chain.
    /// Evaluation order = insertion order.
    pub fn add_filter(&mut self, filter: Box<dyn ProxyFilter>) {
        self.filters.push(filter);
    }

    /// Set the namespace isolation filter (always active, even in Off mode).
    pub fn set_namespace_filter(&mut self, filter: Box<dyn ProxyFilter>) {
        self.namespace_filter = Some(filter);
    }

    /// Current operating mode.
    pub fn mode(&self) -> &CurationMode {
        &self.config.mode
    }

    /// Whether curation is active (not off).
    pub fn is_active(&self) -> bool {
        self.config.mode != CurationMode::Off
    }

    /// Access raw metrics counters.
    pub fn metrics(&self) -> &CurationMetrics {
        &self.metrics
    }

    /// Evaluate a request through the filter chain.
    ///
    /// - **Off**: returns Allow immediately, no filters run, no metrics.
    /// - **Bypass**: returns Allow with a security warning log.
    /// - **Chain**: first Block or Allow wins; Skip continues.
    /// - **Audit**: Block decisions are returned with `audited=true`.
    /// - **Enforce**: Block decisions are final.
    /// - All Skip → Allow.
    pub fn evaluate(&self, request: &FilterRequest) -> EvaluationResult {
        let result = self.evaluate_inner(request);
        // Expose the effective curation decision in Prometheus — previously only
        // internal counters existed, so allow/block was invisible in telemetry.
        let decision = match &result.decision {
            Decision::Allow => "allow",
            Decision::Block { .. } if result.audited => "audit",
            Decision::Block { .. } => "block",
            Decision::Skip => "skip",
        };
        crate::metrics::CURATION_DECISIONS_TOTAL
            .with_label_values(&[decision])
            .inc();
        result
    }

    fn evaluate_inner(&self, request: &FilterRequest) -> EvaluationResult {
        // Namespace isolation: ALWAYS active, even in Off mode.
        // Prevents dependency confusion regardless of curation config.
        if let Some(ref ns_filter) = self.namespace_filter {
            let decision = ns_filter.evaluate(request);
            if let Decision::Block { .. } = &decision {
                self.metrics.blocked.fetch_add(1, Ordering::Relaxed);
                return EvaluationResult {
                    decision,
                    decided_by: Some(ns_filter.name().to_string()),
                    audited: false, // namespace blocks are never audit-only
                };
            }
        }

        // Mode=Off: no-op
        if self.config.mode == CurationMode::Off {
            return EvaluationResult {
                decision: Decision::Allow,
                decided_by: None,
                audited: false,
            };
        }

        // Bypass token
        if request.bypass {
            self.metrics.allowed.fetch_add(1, Ordering::Relaxed);
            tracing::warn!(
                registry = %request.registry,
                package = %request.name,
                "[SECURITY] Curation bypassed via token"
            );
            return EvaluationResult {
                decision: Decision::Allow,
                decided_by: Some("bypass".to_string()),
                audited: false,
            };
        }

        // Track integrity presence
        if request.integrity.is_none() {
            self.metrics
                .without_integrity
                .fetch_add(1, Ordering::Relaxed);
        }

        // Run filter chain
        for filter in &self.filters {
            let decision = filter.evaluate(request);
            match &decision {
                Decision::Allow => {
                    self.metrics.allowed.fetch_add(1, Ordering::Relaxed);
                    return EvaluationResult {
                        decision,
                        decided_by: Some(filter.name().to_string()),
                        audited: false,
                    };
                }
                Decision::Block { .. } => {
                    let audited = self.config.mode == CurationMode::Audit;
                    if audited {
                        self.metrics.allowed.fetch_add(1, Ordering::Relaxed);
                    } else {
                        self.metrics.blocked.fetch_add(1, Ordering::Relaxed);
                    }
                    return EvaluationResult {
                        decision,
                        decided_by: Some(filter.name().to_string()),
                        audited,
                    };
                }
                Decision::Skip => continue,
            }
        }

        // All filters skipped → Allow
        self.metrics.allowed.fetch_add(1, Ordering::Relaxed);
        EvaluationResult {
            decision: Decision::Allow,
            decided_by: None,
            audited: false,
        }
    }
}

pub struct CurationMetrics {
    pub blocked: AtomicU64,
    pub allowed: AtomicU64,
    pub without_integrity: AtomicU64,
}

impl CurationMetrics {
    fn new() -> Self {
        Self {
            blocked: AtomicU64::new(0),
            allowed: AtomicU64::new(0),
            without_integrity: AtomicU64::new(0),
        }
    }
}

pub fn check_download(
    engine: &CurationEngine,
    bypass_token: Option<&str>,
    headers: &axum::http::HeaderMap,
    registry: RegistryType,
    name: &str,
    version: Option<&str>,
    publish_date: Option<i64>,
) -> Option<Response> {
    let bypass = match bypass_token {
        Some(token) => headers
            .get("x-nora-bypass-token")
            .and_then(|v| v.to_str().ok())
            .map(|v| {
                // Constant-time comparison to prevent timing side-channel
                v.as_bytes().ct_eq(token.as_bytes()).into()
            })
            .unwrap_or(false),
        None => false,
    };

    let request = FilterRequest {
        registry,
        upstream: None,
        name: name.to_string(),
        version: version.map(|v| v.to_string()),
        integrity: None,
        bypass,
        publish_date,
    };

    let result = engine.evaluate(&request);

    match &result.decision {
        Decision::Block { rule, reason } => {
            if result.audited {
                tracing::info!(
                    registry = %registry,
                    package = %name,
                    version = version.unwrap_or("*"),
                    rule = %rule,
                    reason = %reason,
                    "[AUDIT] Download would be blocked"
                );
                None
            } else {
                Some(
                    BlockedResponse {
                        rule: rule.clone(),
                        reason: reason.clone(),
                        registry: registry.to_string(),
                        package: name.to_string(),
                        version: version.map(|v| v.to_string()),
                    }
                    .into_response(),
                )
            }
        }
        Decision::Allow | Decision::Skip => None,
    }
}

pub fn check_namespace_isolation(
    engine: &CurationEngine,
    registry: RegistryType,
    name: &str,
) -> Option<Response> {
    let request = FilterRequest {
        registry,
        upstream: None,
        name: name.to_string(),
        version: None,
        integrity: None,
        bypass: false,
        publish_date: None,
    };

    if let Some(ref ns_filter) = engine.namespace_filter {
        let decision = ns_filter.evaluate(&request);
        if let Decision::Block { rule, reason } = &decision {
            engine.metrics.blocked.fetch_add(1, Ordering::Relaxed);
            crate::metrics::record_namespace_isolation_refused(registry.as_str());
            return Some(
                BlockedResponse {
                    rule: rule.clone(),
                    reason: reason.clone(),
                    registry: registry.to_string(),
                    package: name.to_string(),
                    version: None,
                }
                .into_response(),
            );
        }
    }
    None
}

pub fn is_internal_namespace(engine: &CurationEngine, registry: RegistryType, name: &str) -> bool {
    let Some(ref ns_filter) = engine.namespace_filter else {
        return false;
    };
    let request = FilterRequest {
        registry,
        upstream: None,
        name: name.to_string(),
        version: None,
        integrity: None,
        bypass: false,
        publish_date: None,
    };
    matches!(ns_filter.evaluate(&request), Decision::Block { .. })
}

pub fn namespace_filter_active(engine: &CurationEngine) -> bool {
    engine.namespace_filter.is_some()
}

pub fn verify_integrity(
    engine: &CurationEngine,
    registry: RegistryType,
    name: &str,
    version: Option<&str>,
    data: &[u8],
) -> Option<Response> {
    // Only run if curation is active (not Off)
    if !engine.is_active() {
        return None;
    }

    use sha2::Digest;
    let hash = sha2::Sha256::digest(data);
    let integrity = format!("sha256:{}", hex::encode(hash));

    let request = FilterRequest {
        registry,
        upstream: None,
        name: name.to_string(),
        version: version.map(|v| v.to_string()),
        integrity: Some(integrity),
        bypass: false, // bypass already checked in pre-download phase
        publish_date: None,
    };

    let result = engine.evaluate(&request);

    match &result.decision {
        Decision::Block { rule, reason } => {
            // Only act on integrity-related blocks
            if !rule.contains("integrity") {
                return None;
            }
            if result.audited {
                tracing::info!(
                    registry = %registry,
                    package = %name,
                    version = version.unwrap_or("*"),
                    rule = %rule,
                    reason = %reason,
                    "[AUDIT] Integrity check would block download"
                );
                None
            } else {
                Some(
                    BlockedResponse {
                        rule: rule.clone(),
                        reason: reason.clone(),
                        registry: registry.to_string(),
                        package: name.to_string(),
                        version: version.map(|v| v.to_string()),
                    }
                    .into_response(),
                )
            }
        }
        Decision::Allow | Decision::Skip => None,
    }
}

pub fn verify_integrity_by_hash(
    engine: &CurationEngine,
    registry: RegistryType,
    name: &str,
    version: Option<&str>,
    hash: &str,
) -> Option<Response> {
    debug_assert!(
        hash.starts_with("sha256:") && hash.len() == 71,
        "verify_integrity_by_hash: expected sha256:<64hex>, got: {hash}"
    );

    if !engine.is_active() {
        return None;
    }

    let request = FilterRequest {
        registry,
        upstream: None,
        name: name.to_string(),
        version: version.map(|v| v.to_string()),
        integrity: Some(hash.to_string()),
        bypass: false,
        publish_date: None,
    };

    let result = engine.evaluate(&request);

    match &result.decision {
        Decision::Block { rule, reason } => {
            if !rule.contains("integrity") {
                return None;
            }
            if result.audited {
                tracing::info!(
                    registry = %registry,
                    package = %name,
                    version = version.unwrap_or("*"),
                    rule = %rule,
                    reason = %reason,
                    "[AUDIT] Integrity check would block download (hash-based)"
                );
                None
            } else {
                Some(
                    BlockedResponse {
                        rule: rule.clone(),
                        reason: reason.clone(),
                        registry: registry.to_string(),
                        package: name.to_string(),
                        version: version.map(|v| v.to_string()),
                    }
                    .into_response(),
                )
            }
        }
        Decision::Allow | Decision::Skip => None,
    }
}

struct BlockedResponse { rule:String,reason:String,registry:String,package:String,version:Option<String> }
impl IntoResponse for BlockedResponse {fn into_response(self)->Response {(self.rule,self.reason)}}
