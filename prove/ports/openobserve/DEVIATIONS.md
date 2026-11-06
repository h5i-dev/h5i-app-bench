# OpenObserve port: scope, deviations, trusted boundary

## Upstream pin

- Repository: https://github.com/openobserve/openobserve (AGPL-3.0)
- Commit: `a7745479a44bb2dd6f3498b2b3902304600bb466` (2026-11-05, "fix(auth): gate workflow hooks and answer locked routes clearly (#16445)")
- Local checkout: `ports/openobserve/upstream-src` → `/mnt/scratch/oss-sec/upstream/openobserve`
  (a gitignored symlink). The difftest reads files with `git show <commit>:<path>`, so edits to the
  working tree do not affect it.
- License: the kernel is a rewrite of AGPL-3.0 code and stays under AGPL-3.0. No upstream source is
  committed. `difftest/build.rs` copies the upstream items into the build directory at build time.

## Threat model

The open-source tree's RBAC (OpenFGA model, `o2_openfga`), rate limiter (`o2_ratelimit`), lockout
and password policy live in private enterprise crates. The repository has only 16-line stubs for
them (`src/enterprise/*/lib.rs`), so they cannot be ported. The security-critical logic that *is* in
the tree and is pure is the **delegated-token** path, which lets a Slack-linked identity call a fixed
set of org-scoped routes with an `o2dt.<claims>.<mac>` bearer token:

| Asset / decision | Upstream | Attacker goal |
|---|---|---|
| Token authenticity (HMAC, current/previous key) | `config/src/utils/delegation.rs` `verify` | forge or replay a token |
| Expiry, issued-at skew, max lifetime | same, lines 129-141 | use a stale or long-lived token |
| Slack enablement, per-org disablement, known scope | `api/common/src/auth/delegation.rs` `verified_claims` (389) | use a token where Slack is off |
| Route scope: org in the path = token org; route on the scope's allowlist; no DELETE; no `/proxy/` | `check_route` (418), `path_org`, `in_scope`, `segments_match` | cross-org access, out-of-scope routes |
| Link and installation revocation; subject = linked user; org connected to the installation | `LinkFacts::from_rows` (227), `admit` (264) | use a revoked link, impersonate another user |
| Org membership and role; blocked external identities | `validate_delegated` (285-323) | escalate role, cross-org identity |

## What the kernel ports (`kernel/src/`)

| Kernel | Upstream | Notes |
|---|---|---|
| `bytes::constant_time_eq` | `config/src/utils/str.rs:207` | index loop instead of `zip().fold()` |
| `bytes::{starts_with, strip_prefix, split_once, split_slash, contains, ...}` | `str` methods | `&[u8]`, index loops |
| `delegation::check_claims`, `verify` | `config/src/utils/delegation.rs:109-143` | see "Differences" |
| `delegation::verified_claims` | `api/common/src/auth/delegation.rs:389` | closures replaced by inputs |
| `delegation::{scope_routes, relative_path, path_org, seg_matches, segments_match, in_scope, in_assistant_scope, in_slack_action_scope, check_route}` | 418-492, 351-358 | |
| `tables.rs` (generated) | `ASSISTANT_SCOPE` (56 routes), `SLACK_ACTION_SCOPE` (13), `RESERVED_STREAM_SLOTS` (31), `ALERT_ID_LITERALS` (8) | `difftest/gen_tables.py` parses upstream and writes `tables.rs`, `SpecTables.lean` and `Verified/Tables.lean` |
| `delegation::{refused, from_rows, admit}` | 227-276 | without the `loaded: Instant` field |
| `delegation::{load_link_facts, find_link, find_installation, find_member, validate_delegated}` | 285-323, 528-552 | store reads become table lookups |
| `delegation::touch_due` | 585 | |
| `auth::{v2_org_modules, org_from_path, org_from_path_prefix, extractor_org_id}` | `core/src/auth.rs:42-108`, `AuthExtractor` 346-360 | the trailing-empty-segment `pop()` becomes a length `n` |
| `grpc::{auth_token, token_matches, check_internal_auth, check_auth_inner, attach_user_id, valid_metadata}` | `api/grpc/src/handler/grpc/auth/mod.rs:43-163` | |
| `grpc::{is_root_user, get_cached_user_org, lookup_user, password_matches, try_get_hash, join_key, ascii_lower}` | `db/src/user.rs:35`, `db/src/org_users.rs:208`, `db/src/org_ingestion_tokens.rs:39` | caches become tables keyed by upstream's own strings |

## Differences from upstream

- **Decoding and crypto are inputs.** `verify` takes a `VerifyOracle` that the shell fills, for this
  token, with `BASE64_URL_SAFE_NO_PAD.decode(mac_b64)`, HMAC-SHA256 of the claims under the current
  key and (if configured) the previous key, and the base64+JSON decoding of the claims. The kernel
  does the prefix/shape parse, the constant-time MAC comparison, the version, expiry, skew and
  lifetime checks, in upstream's order.
- **Error detail.** Upstream returns `AuthError::Forbidden("Unauthorized Access")` for every route
  refusal and logs the reason. The kernel returns the reason as an enum. The difftest recovers
  upstream's reason from its `log::debug!` output and compares the two exactly.
  `DelegationError::Malformed(String)` becomes `Malformed(kind)`, with one kind per upstream message.
- **Methods.** `http::Method` becomes an enum; every extension method maps to `Other`. That is
  faithful because the route tables only name GET, POST and PATCH.
- **`Seg::Id(ALERT_ID_LITERALS)`** becomes `Seg::AlertId`, since it is the only `Id` table.
- **Stores.** `link_facts`, `get_user` and `domain_management::evaluate_cached` become table lookups
  (`DelegationEnv`). Membership is an exact `(org, email)` match. Upstream's cache lowercases the
  email key (`db::org_users::get_cached_user_org`); that is not modelled. The 30 s `LinkFacts` cache
  is not modelled: the kernel always loads fresh, and a failed read is `store_ok = false` (503).
- **Arithmetic.** The extracted Lean uses checked `i64` arithmetic, so overflow is a failure. That
  matches Rust with overflow checks on (debug), not openobserve's release profiles. See FINDINGS F1.
- **gRPC caches.** `ORG_USERS`, `USERS`, `ROOT_USER` and `ORG_INGESTION_TOKENS` are lists of rows
  with upstream's string keys (`"{org}/{email}"`, the lowercased email, `"{org}/{token}"`). The
  kernel builds the keys exactly as upstream does, so collisions between keys that contain `/`
  are modelled, not ruled out. If several rows share a key, the first one wins; DashMap keys are
  unique. `str::to_lowercase` becomes ASCII lowercase. They agree on ASCII. The difftest
  includes non-ASCII ids, which upstream lowercases differently, but no case in the corpus
  depends on that difference; see the limitation below. `try_get_hash` (Argon2) is an oracle
  table; rows that are not listed hash to `None`. `http_auth_basic::Credentials::from_header`
  is decoded by the shell. Super-cluster mode is an input (`super_cluster_token`).
- **Not ported:** `authorize` (step 6, the private OpenFGA `check_permissions`), `touch_if_due`'s
  store write, key derivation (`derive_key`, `effective_keys`), `sign`.

## Trusted boundary

The following are assumed, not proved: HMAC-SHA256, base64 and serde_json; that the shell fills
`VerifyOracle` from the presented token; the Slack link/installation/membership stores and the
domain blocklist; axum routing (that the path the router dispatches is the path checked); the
private OpenFGA permission step; Charon/Aeneas/Lean.

## Differential tests (`difftest/`)

`cargo test --release` (and `cargo test`) in `difftest/` compiles upstream's own files at the pinned
commit (`build.rs`: whole files up to their test module; enterprise-only async items and the
permission hook dropped; `use` lines redirected to stand-ins in `src/lib.rs`; every edit asserted to
apply exactly once). Seeds are fixed (splitmix64).

| Test | Cases | Compared |
|---|---:|---|
| `verify_agrees` | 60,000 | full `Result<Claims, DelegationError>`; 11 distinct outcomes, 1,337 accepted |
| `check_route_agrees` | 200,000 | `Result` with reason, plus `relative_path`, `path_org`, `in_assistant_scope`, `in_slack_action_scope`; 6 outcomes, 23,546 accepted |
| `verified_claims_agrees` | 40,000 | `Result<Claims, AuthError>` with reason |
| `link_facts_agree` | 50,000 | `from_rows` + `admit` result with reason, installation id, last use |
| `constant_time_eq_agrees` | 50,000 | bool |
| `touch_due_agrees` | 50,000 | bool |
| `upstream_release_wraps_lifetime_check` / `upstream_debug_panics_on_lifetime_overflow` | 1 | FINDINGS F1 |

| `org_from_path_agrees` | 100,000 | `org_from_path`, `routed_path`, extractor org |
| `upstream_route_org_is_extractor_org` | 200,000 | upstream only: whenever upstream's `check_route` accepts, upstream's extractor org is the token org (more than 10,000 accepted) |
| `grpc::check_auth_inner_agrees` | 150,000 | the whole `check_auth_inner` file compiled from upstream (tonic `Request`, DashMap caches, `http-auth-basic`), compared on accept/`user_id`/`[n]` reject tag |
| `grpc::token_matches_agrees`, `grpc::metadata_validity_agrees` | 20,000 / all bytes | `token_matches`; `MetadataValue::try_from` accepts bytes ≥ 0x80 and rejects control bytes except tab |

The gRPC difftest builds upstream's `auth/mod.rs` without the `enterprise` feature, so its
super-cluster token is always `None`. The kernel's super-cluster path is covered by
`token_matches_agrees`. Lowercasing: upstream's `to_lowercase` is Unicode. The kernel lowercases
ASCII only. The test ids include `zoë@x.io`, which both lowercase the same way, so a
counterexample needs non-ASCII uppercase.

All pass. This is testing evidence, not an equivalence proof. `validate_delegated` as a whole has
no upstream counterpart that compiles without the enterprise crates and a database. It is tested
only through its parts.

## Unsuccessful or abandoned attempts (kept for the record)

- `bv_decide` / `h5i_bv` for the constant-time XOR/OR loop were avoided: they add the
  `Lean.ofReduceBool` axiom, which the gate rejects. The proof uses `BitVec.or_eq_zero_iff` instead.
- A first build with `lake build` and no shared package cache started recompiling Mathlib. The
  operator replaced `.lake/packages` with the shared cache symlink.
- Proving the 56-route table as one function (`h5i_steps` + `simp_all`) needed more than 2 minutes
  for 8 routes. The generator now emits one kernel function per route, plus one generated Lean
  lemma per route (`Verified/Tables.lean`, about 4.5 min to build).
- Using `lit "…"` (String → UTF-8) in spec tables made `step*` time out. Spec literals are now byte
  lists with the text in a comment.
- **Parked:** the full `check_route = Spec.checkRoute` correspondence. `segments_match`'s loop spec
  was nearly done, and `in_scope` and `check_route` are not started. They are not in the gate, so the
  route-scope security properties ("no DELETE", "path org = token org", "slack scope reaches only
  alert/on-call routes") are tested (`check_route_agrees`) but **not yet proved**.
