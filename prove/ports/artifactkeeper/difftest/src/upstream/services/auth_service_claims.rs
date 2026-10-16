// Copied from artifact-keeper/artifact-keeper @ 7c42891 by extract_upstream.py. Do not edit.
impl Claims {
    /// Millisecond issued-at used for credential-invalidation ordering.
    /// Falls back to `iat * 1000` (floored to the second) for legacy tokens
    /// minted before the `iat_ms` claim existed. The floored fallback is the
    /// conservative/secure side: a legacy same-second token is treated as
    /// minted at the *start* of its second, so a same-second credential change
    /// (full-ms watermark) still rejects it.
    pub fn effective_iat_ms(&self) -> i64 {
        self.iat_ms.unwrap_or_else(|| self.iat.saturating_mul(1000))
    }
}
