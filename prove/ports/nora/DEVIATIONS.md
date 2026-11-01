# nora: what the kernel covers and where it differs

Upstream: getnora-io/nora @ f864a9a, `nora-registry/src/`. The current verified source reach is recorded by the full-project checks and
`harness/project_reach.py`; `difftest/count_loc.py` is a historical port inventory.

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

## Permission import proposal

`permission_import` ports the complete pure `import/permissions.rs`
`map_to_proposal` decision pipeline: group flattening, maximum effective verb,
repo-scope provenance, sorted user emission, admin narrowing, write opt-in,
OIDC suggestions, ordered audit events and both warnings. It creates no
credentials. Names and repositories use order-preserving interned `u64` ids;
text rendering, source-host metadata and the inert notice are outside the
kernel. Typed audit events render back to the original strings in the
reference test; OIDC repository ids render as the original name plus `/**`.
The differential test compares the complete rendered report against verbatim
pinned upstream bodies on 200,512 cases. Numeric ids are not a claim about
arbitrary UTF-8 interning or display escaping; those stay at the boundary.

## Circuit breaker state transitions

`kernel/src/circuit_breaker.rs` ports `BreakerInner::{new,is_stale,grant_probe}`
and `CircuitBreakerRegistry::{check,record_success,record_alive,record_failure,
threshold_for,reset_timeout_for}` from the same immutable Nora revision.
The theorems compare every state field and returned probe token with a pure
model over unbounded natural numbers. They include disabled operation, absent
clock values, stalled probe recovery, background token zero, stale generation
fencing, and the deliberate preservation of Closed/Open failure counts on 4xx.

The port is one already-selected registry's decision core. Registry map lookup,
locking, allocation, metrics, logging, and configuration override lookup are
adapter boundaries. The resolver receives the result of that lookup as an
`Option`; no registry map correctness or concurrent interleaving is claimed.
An Instant is represented by the seconds elapsed at the current invocation;
a freshly written Instant is `Some(0)`. A clock adapter must advance ages
between calls and supply the same elapsed-second observations as upstream.
No clock arithmetic or wall-clock synchronization is proved. CircuitOpen's
registry-string payload is supplied by the adapter; `None` represents rejection.
The checked counter preconditions are `generation < u64::MAX` for a potentially
new probe and `failures < u32::MAX` for a potentially incremented failure tally.
These exclude counter overflow, rather than assuming a successful decision.

From `prove/`, `python3 ports/nora/difftest/circuit_breaker/prepare.py
results/upstream/nora.git` regenerates the production reference directly from
the pinned git object. Its decision methods
are unchanged; the test supplies a deterministic clock, lock/config/metric/log
adapters, and removes the serde derive. `cargo test --manifest-path
ports/nora/kernel/Cargo.toml --test circuit_breaker` compares all state fields
and tokens in 921,600 boundary-case comparisons, including arbitrary unreachable
states, missing timestamps, zero timeout, stale generations, and integer limits.
This differential evidence and source reach do not constitute a proof of the
adapters or equivalence of the complete concurrent upstream service.


## Curation control flow at f864a9a

`curation.rs` ports CurationEngine::evaluate_inner/evaluate/is_active and the
check_download, namespace and integrity handler decisions. A request adapter
supplies each deterministic ProxyFilter outcome for the same request, preserving
order, filter name, rule and reason. Filter internals are not included in this
batch. Text is represented by stable injective u64 handles (the bypass name uses
the same handle space); the rule's `contains("integrity")` predicate is supplied
with its handle. Header decoding failure/missing header is None, and decoded
header/token equality is exact. Constant-time execution is outside the model.
SHA-256, request construction, text/JSON/header rendering, logs, trait dispatch
and metrics sinks are adapters. The proof retains the exact selected payload,
attribution, audit flag, all three counter increments, effective telemetry label,
and whether a 403 response is returned. Counter increments are represented as
booleans/effects because each invocation increments a counter at most once.
`verify_integrity_by_hash` requires the adapter to check the upstream debug assertion: the hash starts
with `sha256:` and has byte length 71. This does not assert hexadecimal content. These source spans are dependency reach,
not a proof of the crypto, formatting or individual ProxyFilter implementations.

## Exhaustive finite enum decisions (2026-11-01)

`finite_catalog` retains the pinned unit variants, explicit discriminants,
method branches and supported callees. Returned UTF-8 strings become their
exact byte vectors; scalar and boolean results retain their original types.
Derive implementations, visibility and module paths are carrier changes.
Methods needing unresolved external dependencies are excluded. Each accepted
method has a complete output theorem over every enum variant, and differential
tests compare every input against unchanged pinned method bodies.

`difftest/finite_catalog/plan.json` records the upstream revision, exact source
spans and hashes, all reference outputs, excluded candidates, and extraction
roots. Regenerate with `python3 harness/finite_catalog.py generate --app nora`
from `prove/`. Integration is a separate one-time action; standard extraction,
project gates and source-reach validation are still required for credit.
Enum declarations, test data and generated code add no upstream line credit.

## Complete rendering outputs

`rendering` ports seven complete pinned functions: HTML escaping, URI component
encoding, the activity row and log, the polling script string, the dark header,
and the registry search bar. String inputs and outputs use UTF-8 bytes without
normalization. The HTML proof relates its byte loop to upstream's five ordered
replacements. URI encoding preserves ASCII letters, digits and `-_.~`, and
percent-encodes other bytes with uppercase hexadecimal digits.

Renderer models retain every literal byte and dynamic insertion. Translations
carry the seven fields read by the activity log; the language carrier retains
all three upstream variants. The capacity hypothesis requires the complete
output length to fit `usize`. JavaScript is compared as returned text; browser
execution and DOM behavior are outside this claim. Registry and placeholder
values retain upstream's direct insertion behavior.

The header kernel folds the literal template substitutions separately for each
of its three language variants. The generator reads the exact upstream class
tuples; exhaustive differential checks cover the entire language domain. Its
Lean model retains the separate template literals and substitutions.
The folded bytes are split into shared bounded fragments. Each fragment has a
complete-output lemma; their composition is proved equal to the independent
template model. These helper functions receive no additional upstream credit.

`harness/nora_rendering.py` regenerates the kernels and retains unchanged source
bodies, spans and SHA-256 hashes under `difftest/rendering`. Differential tests
compare complete fragments and exercise both encoders across every Unicode
scalar plus randomized strings. Only mapped upstream function spans qualify
for source credit; helper code and proof definitions add no lines.

## Complete pinned sidebar byte output

`sidebar::sidebar` reaches the complete pinned
`components.rs::sidebar_dark_with_registries` body. Its canonical theorem
states termination and equality of every decoded output byte to an independent
model of the four original format templates. The model preserves navigation
order, active classes, fill/stroke attributes, visibility, unescaped caller
text, all icon bytes, whitespace and the version field. Empty registry
membership suppresses the entire registry section; the dashboard remains
visible, and authentication controls the token section.

Caller adapters embed `active_page.unwrap_or("")` and the three fields actually
read from `Translations` as UTF-8 byte vectors. `Enabled` carries the membership
bit for each of the exact 16 registry enum variants; `None` becomes all enabled.
The source enum order and navigation order differ for Go/Raw, so the reference
adapter obtains each bit by variant membership. The `PubDart` bit is named
`pub_dart` to avoid the Rust keyword `pub`; its source navigation ID stays `pub`.
The theorem also admits arbitrary byte strings outside the UTF-8 caller image.

The source VERSION expression `env!("CARGO_PKG_VERSION")` resolves to 1.3.2 in
the pinned workspace. The kernel receives version bytes explicitly, and the
reference adapter passes that exact value. No build environment behavior is
included in the source credit. The kernel returns bounded, at most 128-byte
constant fragments plus caller text in fixed-size arrays; `decode` concatenates
them mathematically. This representation avoids a machine-size bound on the
combined logical output. It proves the byte result and pure kernel termination
under the extraction's allocation model; it does not model allocator failure or
verify a host allocator. Independent models split source literals at 96-byte
boundaries before relating them to the kernel fragments.

`python3 prove/harness/nora_sidebar.py audit --port prove/ports/nora` regenerates
all five generated artifacts byte identically from the immutable source. It
compiles the unchanged upstream function and all icon constants with projected
translation and registry carriers, then compares complete output on 135,160
cases. These include every registry subset with both authentication choices,
None/empty enabled selections over all recognized and several unknown active
IDs, and arbitrary Unicode/control-character translation fields. The proof
covers every carrier input, beyond this finite differential evidence. Helpers,
carrier definitions and icon constants receive no independent line credit.
