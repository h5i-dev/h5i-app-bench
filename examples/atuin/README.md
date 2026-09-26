# Atuin port

The account and record rules of the [Atuin](https://github.com/atuinsh/atuin)
sync server (`crates/atuin-server` at 5b10eb0) as an i5h kernel, with Lean
proofs about the extracted code.

## What is modeled

- Registration: closed-registration switch, username alphabet
  (alphanumeric and `-`), unique usernames, one session per user.
- Password change: needs the current password.
- Account deletion: removes the user's session, records and account.
- Records: upload with the size cap (0 means no cap), paged reads of one
  series, the status listing, and deleting the store.

Not modeled:

- hashing and token checks: the shell passes hashes and "password matched" flags,
- the history table, which the current server only deletes,
- metrics, webhooks, rate limits.

Host ids and record tags are numbers here.

## Issue #3297

In Atuin today, a valid session alone can delete an account; changing the
password needs the current one. The kernel has both behaviors: `transition`
requires the password to delete (the change the issue asks for), and
`transition_current` matches Atuin.

## What is proven

Unless noted, for both variants, every principal, every state and every
command:

- `step_total`: the kernel never fails.
- `isolation`: every write touches only the caller's own account, or the
  account being created.
- `reply_confined`: `NextRecords` and `Status` return only the caller's records.
- `inv_preserved`, `reachable_inv`: in every reachable state,
  - every session and record belongs to an existing user, so deleting an
    account leaves nothing behind,
  - ids and usernames are unique,
  - ids are fresh,
  - stored records respect the size cap.
- `registration_closed`: closed registration refuses every sign-up.
- `change_needs_password`: a password change without the current password fails.
- `delete_needs_password` (the `transition` variant only): deleting an account
  needs the password.
- `current_deletes_without_password`: in `transition_current`, any signed-in
  user can delete their account without the password.

All of these depend only on `propext`, `Classical.choice` and `Quot.sound`.

## Size

| Part | Lines |
|---|---|
| Rust kernel | 470 |
| Spec | 65 |
| Proofs | 660 (about 1.4 per kernel line) |

The proofs reuse `I5hLib`'s loop lemmas and `walk`.

## Build

```
scripts/extract-atuin.sh        # regenerate AtuinKernel.lean
cd examples/atuin/proofs && lake build
```
