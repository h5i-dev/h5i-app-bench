# crates.io: findings

Upstream rust-lang/crates.io @ `e0fc83aa64e4d53b5447576f8018e3287d4e8982`. No upstream issues
were filed. Nothing found so far breaks an authorization property; the proved S theorems
(STATUS.md) hold for the ported decisions.

## F1. A GitHub token that fails to decrypt locks out direct owners (info)

**Theorem:** `rights_decrypt_failure_denies_direct_owner`.

`Rights::get` (`src/controllers/helpers/authorization.rs:25-40`) decrypts the user's stored GitHub
OAuth token *before* scanning the owners and returns the error on failure. A user who is a listed
user owner of the crate, and so needs no team lookup, is then refused publish, yank and owner
changes with a server error until the token is re-issued (e.g. after a `TokenEncryption` key
rotation that left old ciphertexts behind).

- Severity: info (availability only; fails closed).
- Reachable: yes, every endpoint calling `Rights::get`, but only when decryption fails.
- Fix idea: decrypt lazily, on the first `Owner::Team` entry.

## Observations (not findings)

- `Rights::get` also returns an error as soon as a team lookup fails, even if a later owner entry
  would give the user full rights. `Crate::owners` (`crates/crates_io_database/src/models/krate.rs:206-213`)
  lists users before teams, so a user owner is always seen first; not reachable.
- Cookie authentication takes precedence over the `Authorization` header (`src/auth.rs:333-352`):
  with a valid session, token scopes are not consulted. This is by design (the session user has
  all rights anyway) and `verify_origin` guards it against cross-origin requests.
- `HashedToken::parse` accepts any `cio`-prefixed string, including Trusted Publishing tokens
  (`cio_tp_…`); on non-publish endpoints those are simply not found in `api_tokens` (403).
- `extract_workflow_filename`'s regex is unanchored and greedy; for a crafted `workflow_ref`
  such as `o/r/.github/workflows/x.yml@y.yml@z` it yields `x.yml@y.yml`. The claim is signed by
  GitHub, so not attacker-controlled.
- The publish endpoint chooses the `publish-new`/`publish-update` scope from a lookup made before
  authentication; a concurrent first publish of the same name lets a `publish-new`-only token
  publish an update. The ownership check still applies (`publish_existing_needs_ownership`), and
  upstream documents this race in a comment (`publish.rs:178-181`).
