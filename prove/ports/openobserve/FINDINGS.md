# OpenObserve findings (pinned commit a7745479a44bb2dd6f3498b2b3902304600bb466)

No upstream issue has been filed.

## F1. The delegated-token lifetime check can wrap in release builds

- **Upstream:** `src/config/src/utils/delegation.rs:137`, `if claims.exp - claims.iat > MAX_LIFETIME_SECS`.
  The same pattern appears at line 132 (`now + MAX_IAT_SKEW_SECS`) and in
  `src/api/common/src/auth/delegation.rs:585-587` (`touch_due`, `now - last_used_at`).
- **Description:** `exp` and `iat` are `i64` values taken from the token's JSON claims. In
  `Cargo.toml`, the `release`, `release-prod` and `release-profiling` profiles leave
  `overflow-checks` at its default, which is off. For `exp = i64::MAX` and a negative `iat`, the
  subtraction wraps to a negative number. The "lifetime over an hour" check then passes, and
  `verify` returns `Ok` for a token that never expires. In builds with overflow checks on
  (`dev`, and `release-ci` via `debug-assertions = true`), the same input panics instead of being refused.
- **Evidence:**
  - Lean: `openobserve_kernel.Properties.lifetime_check_overflows` shows that the extracted kernel
    (whose arithmetic is checked) fails on this input and does not answer.
    `accepted_token_lifetime_bounded` proves that with checked arithmetic, every accepted token
    satisfies `exp ≤ now + 3720` over the integers.
  - Rust: the difftest `upstream_release_wraps_lifetime_check` (`cargo test --release`) signs such
    claims and runs upstream's own `verify`, which accepts the token with `exp = i64::MAX`.
    `upstream_debug_panics_on_lifetime_overflow` (`cargo test`) shows the panic.
- **Severity:** low.
- **Exploitability:** the claims sit under an HMAC-SHA256. An attacker can only present such
  claims with the signing key, or through a minting bug in the private Slack code that calls
  `sign`, which this repository does not contain. The check exists precisely to catch tokens
  "not minted by O2" (see its comment at line 39). With these inputs it fails open in release
  builds, so the defence-in-depth it is meant to provide is lost.
- **Reachable from the API:** yes, if a crafted token is signed. Any request carrying a bearer
  `o2dt.` token reaches `verify` through `validate_delegated` (enterprise builds with Slack on).
- **Fix suggestion:** use `claims.exp.checked_sub(claims.iat)` (treating `None` as malformed), or
  compute in `i128`. Use `now.saturating_add(MAX_IAT_SKEW_SECS)` for the skew check.

## Observations (not findings)

- `LinkFacts` are cached for 30 s per node (`LINK_CACHE_TTL`, `delegation.rs:44`), so a revoked
  link or installation can keep authenticating for up to 30 s on a node that cached it. This is
  documented upstream. The kernel models a fresh load, and `revoked_link_denies` holds for that model.
- The gRPC ingestion path (`src/api/grpc/src/handler/grpc/auth/mod.rs:92-98`) accepts an org
  ingestion token with any client-chosen `user_id` and attaches that id to the request. Not yet
  ported; to be examined.
