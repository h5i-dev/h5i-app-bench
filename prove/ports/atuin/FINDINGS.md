# atuin: findings

Upstream atuinsh/atuin @ `df152cd4d68b4dbc2a6f13732b31b0e013470c70`, crate `crates/atuin-server`,
SQLite backend. Each finding has a theorem (class F) that states the upstream behaviour, and a
`fix_*` mutant in `h5i-app.toml` showing that the obvious fix breaks that theorem. No upstream
issues were filed.

## F1. Changing the password does not revoke sessions (low, by design)

- Theorem: `Properties.password_change_keeps_sessions`. After a successful
  `PATCH /account/password`, the `sessions` table is unchanged.
- Upstream: `src/handlers/user.rs:160-184` (`change_password` calls only
  `update_user_password`); `src/db/mod.rs` `UPDATE_USER_PASSWORD` touches only `users`.
  `src/admin/user.rs:30` documents the same for the operator command ("The user's machines stay
  logged in").
- Combined with `login` (`src/handlers/user.rs:189-232`), which hands out the user's *existing*
  session token rather than minting one, an account has a single, never-rotated token: a token
  that leaked once stays valid after the user changes the password. The only revocation is deleting
  the account.
- Severity: low (documented, deliberate). Reachable from the HTTP API: yes. Exploitability:
  needs a previously stolen token.
- Fix mutant: `fix_password_change_revokes_sessions`.

## F2. `count` above `i64::MAX` means "no limit" (info)

- Theorem: `Properties.next_huge_count_is_unlimited`. For every two counts `n, m > 2^63 - 1`,
  `GET /api/v0/record/next` returns the same rows: the whole series from `start` on.
- Upstream: `src/db/mod.rs:454` binds `i64::conv(count)`. `easy-cast`'s `Conv` for `u64 -> i64`
  asserts the range only with `debug_assertions` (or its `assert_int` feature, which the workspace
  does not enable: `Cargo.toml` enables `assert_nonzero` only), so a release build wraps the count
  to a negative `LIMIT`, which SQLite treats as unlimited. A debug build panics in the handler
  instead (the connection is dropped without a response). On PostgreSQL a negative `LIMIT` is an
  error (500); not checked here, the difftest uses SQLite.
- Scope: only the requester's own records are returned, so this is a resource-use issue (a client
  can ask for its whole store in one response, bypassing the 100-record page size the server
  advertises), not a confidentiality issue.
- Severity: info. Reachable: yes, query parameter of an authenticated route.
- Fix mutant: `fix_count_limit`.

## F3. `idx` and `start` are compared as signed integers (info)

- Theorem: `Properties.next_start_wraps`. With `start = 2^63` a record at `idx = 0` is selected
  as "at or after start". More generally the kernel orders by `signed_key(idx) = idx ^ 2^63`,
  which is the signed `i64` order the database applies; the difftest confirms this on records with
  `idx` in {0..5, 2^63 - 1, 2^63, 2^64 - 1}.
- Upstream: `src/db/mod.rs:421` (`i64::conv(i.idx)` on insert), `:453` (`i64::conv(start)`),
  `NEXT_RECORDS` / `STATUS` SQL (`idx >= $4 ORDER BY idx`, `MAX(idx)`). The client's index is a
  `u64` (`atuin-domain/src/record/mod.rs` `RecordIdx`); values from 2^63 on are stored negative in
  release builds and panic the handler in debug builds. `status` then reports the signed maximum,
  so a series holding indexes 5 and 2^63 reports 5 as its tail.
- Scope: one user's own store only. A client can corrupt its own sync state (records past 2^63
  sort first and are never reported as the tail); it cannot affect other users
  (`outcome_independent_of_other_users`, `other_accounts_untouched`).
- Severity: info. Reachable: yes (record upload and `next` query).
- Fix mutant: `fix_unsigned_start`.

## Observations without a theorem

- Login distinguishes "user not found" (404) from "password is not correct" (401)
  (`src/handlers/user.rs:195-224`), and `GET /user/{username}` (`:47-66`) is public and
  unauthenticated, so account names are enumerable. The kernel models both exactly (difftest);
  this is upstream's intended public-profile behaviour. Severity: info.
- Registration accepts an empty password and any email string (`src/handlers/user.rs:72-128`);
  only the operator command rejects empty passwords (`src/admin/user.rs` `read_password`).
  Not modelled as a theorem because the password reaches the kernel only as its hash.
  Severity: info.
- `totp_code` fields in `LoginRequest`, `DeleteUserRequest` and `ChangePasswordRequest`
  (`crates/atuin-domain/src/api.rs:53,70,86`) are ignored by this server. Severity: info
  (this server has no TOTP enrolment, so nothing is bypassed).
