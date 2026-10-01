# nora: what the kernel covers and where it differs

Upstream: getnora-io/nora @ f864a9a, `nora-registry/src/`. The kernel covers
977 lines of it (`difftest/count_loc.py`).

## Covered

| Kernel | Upstream |
|---|---|
| `middleware::auth_middleware` and its branches (`open_path`, `bearer`, `basic`, `token_identity`) | `auth/mod.rs` `auth_middleware`, `anonymous_read_passthrough`, `try_basic_auth` |
| `middleware::is_public_path`, `is_web_surface`, `is_docker_path`, `is_admin_path` | `auth/mod.rs` |
| `lockout::AuthFailureTracker::check_blocked`, `after_failure` | `auth/mod.rs` `AuthFailureTracker` |
| `net::TrustedProxies::contains`, `net::resolve_client_ip` | `config/auth.rs` `TrustedProxies::contains`; `auth/mod.rs` `resolve_client_ip`, `extract_client_ip` |
| `tokens::verify_token`, `revoke_token`, `revoke_all_for_user`, `is_valid_hash_prefix` | `tokens.rs` |
| `middleware::authenticate` | `auth/htpasswd.rs` `HtpasswdAuth::authenticate` |
| `validate_claims`, `match_role`, `glob_match` | `auth/oidc.rs` (the claims half of `validate_token`) |
| `from_oidc_scopes`, `enforce_namespace_scope` | `auth/namespace.rs` |
| `validation::*`, `namespace_match`, `segments_match`, `segment_glob` | `validation.rs` |
| `transition` | the OIDC branch of the middleware followed by a write handler's `enforce_namespace_scope` call |

## How it is checked

`difftest/extract_upstream.py` builds `difftest/upstream`, a crate laid out
like nora's: `tokens.rs`, `validation.rs`, `auth/mod.rs`, `auth/htpasswd.rs`
and `auth/namespace.rs` are copied whole up to their test modules, so
`crate::` paths resolve unchanged. `config`, `metrics`, `AppState` and the JWT
half of `auth/oidc.rs` are stubs; the claims half, `match_role`, `glob_match`
and `classify_rejection` are copied. Small seams appended after the copied
text seed and read the token cache and the failure tracker.

`middleware_tests.rs` runs nora's `auth_middleware` through an axum router,
with token files in a temporary directory hashed by real SHA-256 and Argon2,
an htpasswd file hashed by bcrypt, and seeded cache and tracker entries. It
compares the response (status, body, the extensions the handler receives) and
the state afterwards (tracker, cache, `last_used`) with the kernel's outcome
and writes, on 20,000 random requests. `revoke_agrees` does the same for
revocation, comparing the files on disk. `tests.rs` and `validation_tests.rs`
compare the OIDC pipeline, the glob matchers and the validators on millions
of inputs. Mutations of the kernel make these tests fail.

## Not covered (trusted input)

- Cryptography and decoding: SHA-256, Argon2 and bcrypt verification, base64,
  UTF-8 validation. `oracle::Crypto` holds them as tables; the theorems hold
  for every table, and the difftest fills them from the real functions.
- JWT signature, issuer and audience checks, and JWKS fetching: `Jwt` carries
  the claims the validator accepted.
- Parsing IP addresses from headers and the trusted-proxy list
  (`TrustedProxies::parse`): the request carries parsed addresses.
- How each registry handler derives the namespace coordinate from its URL.
- Writing token files (the Argon2 migration is a `Migrate` write), and the
  periodic flush of `last_used`.
- Metrics and logs.

## Differences in form

| Where | Upstream | Kernel | Why |
|---|---|---|---|
| everywhere | `&str`, `String` | `&[u8]`, `Vec<u8>` | Aeneas has no strings; upstream's comparisons are bytewise. |
| `HashMap`, `RwLock`, files on disk | maps and a directory | lists of entries | no maps in the subset |
| clocks | `SystemTime`, `Instant` | `now` (seconds) and `mono` (nanoseconds) in the request | time is an input |
| `auth_middleware` | inserts request extensions, calls `next` | returns `Outcome::Next` with them, or the response as `Deny` | |
| tracker, cache | mutated in place | `Write`s for the shell to apply | h5i-app's kernel shape |
| validation errors | messages | one variant per message | |
| `NamespaceAuthority` | `Arc<[Arc<[String]>]>`, provider name | `Vec<Vec<Vec<u8>>>`, no name | no `Arc`; the name only labels logs |
| `from_oidc_scopes` | an iterator of scopes | the provider scope and the optional rule scope | the only call site passes these two |
| `glob_match`, `segment_glob` | string methods, two loops in one function | helper functions | Aeneas rejects `continue` next to an early return, and returns from a second loop |
| `segments_match` | slices, `(0..n).any(..)` | indices, `segments_match_any` recursion | no loop inside a recursive function |
| `Option::clone`, `?` on `Option` | | `match` | not in Aeneas' library |
| `revoke_token` | `fs::remove_file` errors other than NotFound give `Storage` | not modeled | removing a listed file succeeds |
| module names | | `oracle`, `lockout` | a module may not share a name with a local variable in the generated Lean |
