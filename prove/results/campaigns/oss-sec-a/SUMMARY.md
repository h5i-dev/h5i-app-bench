# OSS security-proof campaign, session a: summary

Branch `oss-sec-a`. Projects: wastebin, then crates.io. Both ports are gated
(`h5i app check`: no `sorry`, no `native_decide`, axioms only `propext`, `Classical.choice`,
`Quot.sound`; `h5i app extract --check` up to date) and have passing differential tests against
the pinned upstream code.

| Project | Upstream (pinned) | Listed theorems | S / C / F | Difftests |
|---|---|---|---|---|
| wastebin | matze/wastebin @ `c0ec968` | 30 (182 checked) | 23 / 4 / 3 | 7 pass: real `wastebin_core::Database` (SQLite, zstd, argon2+XChaCha20) on 1,200 random ops; ids/keys/extensions/`Content-Disposition` on 200k-400k inputs each |
| crates.io | rust-lang/crates.io @ `e0fc83a` | 23 (148 checked) | 22 / 0 / 1 | 8 pass: `crates_io_validation` linked; scopes, `AuthCheck` scope checks, account locks, `Authorization` parsing, access tokens, workflow-filename regex, owner ids copied verbatim; 100k-300k inputs each |
| **Total** | | **53** | **45 / 4 / 4** | |

S = security property (implementation-independent statement, falsifiable by a plausible bug,
backed by a named killing mutant); C = correspondence/helper; F = finding. The roughly 250
correspondence lemmas in `proofs/Verified/` are not listed and not counted.

## What was proved

**wastebin** (anonymous pastebin):
- Deletion only with a verified `uid` cookie listing the paste's owner; it removes only that
  owner's paste; refusals and cookie-less requests change nothing.
- Reads: content only for an existing, unexpired paste, opened by its password if encrypted;
  expired pastes are deleted, never shown; a wrong or missing password neither reveals nor burns.
- Burn after reading: a successful read deletes the paste; every later read is `NotFound`; for
  any number of concurrent readers that all fetched the paste, exactly one gets the content.
- HTML view: content gated as above plus burn confirmation; encrypted pages are `no-store`; the
  server cache only ever receives plaintext, non-burning pastes read without a password; the
  view changes the table only for expired or confirmed-burned pastes; the `?owner=` handoff
  touches no paste and adds only the verified uid.
- Raw/download gated like the view; extensions in keys are at most 32 URL-safe bytes (no markup
  or path injection); insert never reuses an existing id; purge deletes exactly expired rows.

**crates.io** (package registry):
- Authentication: cross-origin requests never authenticate; API tokens only via a live
  (unrevoked, unexpired) row for an existing, unlocked user; sessions need the user's current
  epoch; locked accounts never authenticate.
- `AuthCheck`: cookie-only endpoints reject tokens; scoped tokens need the endpoint's scope;
  crate-scoped tokens stay within their patterns, and on crate-less endpoints need opt-in.
- `Rights::get`: full rights only for listed user owners; publish rights via teams only for
  active members with working GitHub credentials.
- Publish: Trusted Publishing tokens are bound to the crates they were issued for, never create
  crates, and trusted-publishing-only crates reject users; user publishes to existing crates need
  ownership (also under the concurrent-creation race) and properly scoped tokens.
- Trusted Publishing exchange: tokens only for configs matching repository, owner id, workflow
  and environment; `jti` single use and replay rejected; `pull_request_target`/`workflow_run`
  rejected.
- Publish rate limit: over any run of requests at nondecreasing times, at most
  `burst + (t_n - t_1) / rate` pass.

## Findings (details in each port's FINDINGS.md)

| Id | Project | Severity | Summary |
|---|---|---|---|
| wastebin F1 | wastebin | low | Metadata (title) of expired pastes stays visible via `/qr/{id}` and the burn interstitial until a manual purge |
| wastebin F2 | wastebin | low | Magic-link handoff fixes the owner uid of a cookie-less browser; the link's author can delete the victim's later pastes |
| wastebin F3 | wastebin | info | Paste ids are not canonical: several URLs decode to the same id (difftest evidence) |
| wastebin F4 | wastebin | info | Configured expiration choices are not enforced server-side (observation, not proved) |
| crates.io F1 | crates.io | info | `Rights::get` decrypts the GitHub token first; a decryption failure refuses even direct owners |

## Gaps and honesty notes

- Differential tests are evidence, not equivalence proofs. Handler-level control flow that needs
  Postgres or the HTTP stack (wastebin's view/raw/qr/delete handlers; crates.io's
  `authenticate`, `Rights::get`, `publish`, token exchange) is ported by reading and covered only
  through its tested helpers.
- Trusted: cryptography (AEAD/argon2, SHA-256 injectivity, HMAC cookies, JWT verification),
  SQLite/Postgres query semantics, ASCII case folding for Postgres `lower()`.
- Not covered: wastebin's `safe_referer`, markdown rendering; crates.io's GitLab
  Trusted Publishing, yank/owner-management handlers, config-creation validators.
- Parsers without Lean specs (wastebin id codec; crates.io header/token/workflow parsers) are
  difftest-only; their mutants survive by design and are listed in each STATUS.md.
- `h5i app lint` fails on wastebin only because it scans the symlinked upstream server
  (`upstream-src/`), whose anonymous routes have no `Actor<>`; proposal in wastebin STATUS.md.
- Several kernel functions were restructured for Aeneas (tail-loop helpers, numeric codes
  instead of enum matches in loops, indices instead of cloned rows); each is listed in the
  port's DEVIATIONS.md with the reason.
