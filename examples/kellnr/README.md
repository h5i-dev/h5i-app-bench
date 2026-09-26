# Kellnr

[Kellnr](https://github.com/kellnr/kellnr) is a private crate registry built on
axum. [PR #1243](https://github.com/kellnr/kellnr/pull/1243) (commit 45043ee)
fixed a privilege escalation: session logins hardcoded `is_read_only: false`,
and the crate-group endpoints skipped `check_can_modify`, so a read-only user
could change crate owners and access lists.

This example models `crates/registry/src/kellnr_api.rs` as an i5h kernel with
two variants. `transition` follows the code after the PR and
`transition_pre1243` the code before it, and the two share everything except
the lines the PR changed.

## The model

The kernel models the checks `check_ownership`, `check_can_modify` and
`check_download_auth`, how session and token logins build a `MaybeUser`, and
the endpoints for single owners, crate users, crate groups, yanking,
publishing (its authorization only) and downloads.

It leaves out `remove_owner` with several users at once, whose last-owner
check differs slightly, as well as `add_empty_crate`, required crate fields,
storage, webhooks, session expiry and the web UI routes. Names are numeric
ids. `apply` is written in Rust and tested but not extracted, so the theorems
are about the write sets the kernel returns.

## Theorems

The following hold for every principal, login path, state and command of the
fixed kernel:

| Theorem | Statement |
|---|---|
| `read_only_commits_nothing` | A read-only user who is not an admin commits no write at all. |
| `writes_authorized` | Every access-list or yank write comes from an admin or an owner of that crate, and publishing a new crate makes the publisher its first owner. |
| `owner_removal_needs_two`, `owner_remains` | An owner can only be removed from a crate with at least two owners (unless ownerless crates are allowed), so one owner always remains. |
| `download_authorized` | A restricted crate is served only to an admin, an owner, a crate user or a member of a granted group. |
| `transition_total` | No input makes the kernel fail. |

For the code before the PR, `Counterexample.lean` proves the first theorem
false (`pre1243_violates_read_only`). In `pre1243_session_adds_owner`, user 1 is read-only, owns crate 7,
logs in with a session and adds an owner, and in `pre1243_token_adds_group`
the same user grants a group through a token. The fixed kernel refuses both
with `ReadOnlyModify` (`fixed_refuses_session`, `fixed_refuses_group`).

All theorems depend only on Lean's standard axioms.

## Building the proofs

```
../../scripts/extract-kellnr.sh      # regenerates proofs/generated/KellnrKernel.lean
cd proofs && lake build
```
