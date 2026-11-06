# crates.io: status

Upstream rust-lang/crates.io @ e0fc83aa64e4d53b5447576f8018e3287d4e8982 (2026-11-05).

## Done
- Kernel: `bytes`, `validation` (crate/dependency names), `scopes` (EndpointScope, CrateScope
  pattern validity and matching), `auth` (header parsing, verify_origin, session cookie + epoch,
  API token lookup, account locks, `AuthCheck::check`).
- Proofs: 9 authentication/authorization theorems; gate passes.

## Next
- Kernel + proofs: `Rights::get`, publish authorization (trustpub vs token, trustpub_only, rights),
  Trusted Publishing token exchange (GitHub config matching, jti replay, event filter),
  rate-limit token bucket.
- Difftest against pinned upstream items (scopes, validation, header parsing, scope checks).
- DEVIATIONS.md, FINDINGS.md, theorem classification, mutate.
