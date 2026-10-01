// Copied from artifact-keeper/artifact-keeper @ 7c42891 by extract_upstream.py. Do not edit.
/// Detect SQLx connection-pool saturation across both the typed
/// `sqlx::Error::PoolTimedOut` and its stringified forms.
///
/// The hot proxy path wraps DB errors as `AppError::Database(e.to_string())`,
/// which erases the typed variant. `e.to_string()` for `PoolTimedOut` renders
/// "pool timed out while waiting for an open connection" (sqlx 0.8), which does
/// NOT contain the literal "PoolTimedOut". Matching only the variant name
/// therefore missed every stringified pool timeout on the proxy hot path and
/// surfaced 500 instead of 503 (#1437 follow-up). We match both fragments so
/// the mapping holds whether the error arrived typed or stringified.
pub(crate) fn is_pool_timeout(msg: &str) -> bool {
    let lower = msg.to_ascii_lowercase();
    lower.contains("pool timed out") || lower.contains("pooltimedout")
}

impl AppError {
    /// True when this error is a SQLx connection-pool acquire timeout, in
    /// either its typed (`Sqlx(PoolTimedOut)`) or stringified
    /// (`Database("pool timed out …")`) form.
    ///
    /// This is the single source of truth for the POOL_EXHAUSTED -> 503
    /// classification (#1437 / #2101 / #2102): `status_and_code` and
    /// `user_message` consult it below, and callers outside this module reuse
    /// it instead of re-deriving the variant/string check. In particular the
    /// auth pre-check (`api::middleware::auth`) uses it to reclassify a
    /// pool-acquire timeout during its own DB lookup as a retryable 503 rather
    /// than flattening it to a misleading 401 (#2125). A pool timeout is a
    /// transient capacity problem, never a bad credential.
    pub(crate) fn is_pool_timeout(&self) -> bool {
        match self {
            Self::Sqlx(sqlx::Error::PoolTimedOut) => true,
            Self::Database(msg) => is_pool_timeout(msg),
            _ => false,
        }
    }
}
