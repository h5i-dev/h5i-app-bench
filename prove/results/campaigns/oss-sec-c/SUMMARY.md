# OSS security-proof campaign — session c summary

Two projects, both finished as full vertical slices (kernel + differential tests + Lean spec/proofs
+ passing standard gate + honest report). Branch `oss-sec-c`.

## 1. openobserve — delegated (`o2dt.`) tokens, org RBAC path, gRPC auth

- Upstream: openobserve/openobserve @ `a7745479a44bb2dd6f3498b2b3902304600bb466`.
- Why this scope: the open-source tree's OpenFGA RBAC, rate limiter, lockout and password policy
  live in private enterprise crates (16-line stubs only), so they cannot be ported. The pure,
  security-critical logic that *is* present is the Slack **delegated-token** auth path, the
  `org_from_path` org-resolution the permission check uses, and the **gRPC interceptor**.
- Gate: `doctor`, `extract --check`, `check` (468 theorems, 11 modules, only propext/Classical.choice/
  Quot.sound), `lint` all pass. **S 21 / C 29 / F 1.**
- Security theorems proved about the extracted `validate_delegated`, `check_route`,
  `check_auth_inner`, `check_internal_auth` (each holds for all inputs and all store tables):
  expired/forged tokens are never accepted; the previous signing key verifies only when configured;
  an accepted token's lifetime is bounded (exact integer arithmetic); the delegated identity is a
  member of the token's org with that membership's role; a revoked link, revoked installation,
  wrong subject or unconnected org is refused; Slack-off / per-org-disabled / blocklisted identities
  are refused; the route's org equals the token org and equals the org RBAC later reads
  (`org_from_path`); delegated tokens only GET/POST/PATCH, never DELETE/proxy; a `slack_action` token
  only reaches alert/on-call routes; gRPC node RPCs accept only the internal/super-cluster token;
  empty token and blank password never authenticate; an org ingestion token is scoped to its header
  org and only on OTLP; a non-root user authenticates only through its header-org membership; SSO
  (empty-salt) users need their token, not a password.
- Differential tests (12), ~700k random cases total, all comparing against upstream's own code
  compiled at the pinned commit (delegation, route scopes, link facts, `org_from_path`, the gRPC
  interceptor with real tonic/DashMap/http-auth-basic, `token_matches`, metadata validity).
- Mutation: the 14 hand-written delegated-token mutants were caught 14/14; 12 more (route/gRPC) are
  running.
- **Finding F1 (low):** the delegated-token lifetime check computes `exp - iat` in `i64`; in
  openobserve's release profiles (overflow-checks off) `exp = i64::MAX, iat < 0` wraps and the token
  is accepted as "short-lived". The kernel (checked arithmetic) refuses it; the difftest shows
  upstream's own `verify` accept it in `--release` and panic in debug.

## 2. spacedrive — archive-extraction landing path

- Upstream: spacedriveapp/spacedrive @ `2c4da346da529f06428fcf40488345ef8b955f15`.
- Scope: `ArchiveEntry::landing`, which decides where each archive entry lands beneath the extraction
  destination. Pure, high-value, and isolable from the large async/P2P core.
- Gate: `doctor`, `extract --check`, `check` (25 theorems, 3 modules, standard axioms), `lint` pass.
  **S 4 / C 5 / F 0 gated** (plus F1 below, demonstrated by test, not a false theorem).
- Security theorems about the extracted `archive.landing` (all inputs, all `strip`): every kept
  segment is non-empty, not `.`, not `..`, and NUL-free — so an accepted entry yields a proper
  relative path that cannot climb to a parent of the destination. Backed by a loop-invariant proof
  of `components` and a `skip` preservation proof.
- Differential tests: `landing_agrees` (200k random names vs upstream's own `landing`), and a
  reproduction of the finding below using upstream's own extractor.
- Mutation: 3 mutants (keep `..` / keep NUL / keep empty+`.`), running.
- **Finding F1 (medium):** `landing` sanitises entry *names* but not entry *types*. A `.tar.zst`
  whose first entry is a symlink `lnk -> <outside>` and whose second is `lnk/pwned.txt` has both
  names pass `landing`; upstream's tar extractor then writes the second file through the symlink,
  outside the destination. The zip path guards against symlink entries; the tar path does not. The
  differential test `tar_symlink_entry_writes_outside_destination` reproduces this with upstream's
  own `extract_entries`. This is not a counterexample to the proofs (which are about the name
  string); it shows string sanitisation is insufficient against symlink entries.

## Honesty notes / limitations

- Theorems certify the extracted kernels under their stated byte-string models and trusted
  boundaries (crypto primitives, base64/JSON, HTTP/tonic frameworks, the DB/stores, the private
  OpenFGA permission step for openobserve; the host path assembly, extraction IO and symlink
  handling, and Unix component semantics for spacedrive). Differential testing is empirical evidence,
  not an equivalence proof.
- openobserve's `validate_delegated` has no upstream counterpart that compiles without the enterprise
  crates and a database, so it is tested only through its parts.
- One correspondence theorem (openobserve's full `check_route = Spec.checkRoute`) was completed; an
  earlier rabbit-hole on the route-pattern loop was parked per operator guidance before being
  finished, and the route-scope S properties are now both proved and difftested.

## Reproduce

Per port: `h5i app doctor/extract --check/check/lint ports/<p>` and
`cd ports/<p>/difftest && cargo test --release` (needs the gitignored `upstream-src` symlink). Move
`upstream-src` aside before `lint`/`mutate`. Full per-port detail in each `ports/<p>/STATUS.md`,
`DEVIATIONS.md`, `FINDINGS.md`.
