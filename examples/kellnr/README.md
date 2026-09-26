# Kellnr authorization, before and after PR #1243

[Kellnr](https://github.com/kellnr/kellnr) is a private crate registry on
axum. [PR #1243](https://github.com/kellnr/kellnr/pull/1243) (commit 45043ee)
fixed a privilege escalation: session logins hardcoded `is_read_only: false`,
and the crate-group endpoints skipped `check_can_modify`, so a read-only user
could change crate owners and ACLs.

`kernel/` models `crates/registry/src/kellnr_api.rs` as an i5h kernel.
`transition` follows the code after the PR; `transition_pre1243` the code
before it. They share everything except the two lines the PR changed.

## What is proven (`proofs/`)

For every principal, login path, state and command, about the extracted
`transition`:

- `read_only_commits_nothing`: a read-only non-admin commits no write at all.
- `writes_authorized`: every ACL or yank write comes from an admin or an owner
  of that crate; publishing a new crate makes the publisher its first owner.
- `owner_removal_needs_two` and `owner_remains`: an owner can only be removed
  from a crate with at least two owners (unless ownerless crates are allowed),
  so with unique owner rows one always remains.
- `download_authorized`: a restricted crate is served only to a token of an
  admin, owner, crate user or member of a granted group.
- `transition_total`: no input makes the kernel fail.

About `transition_pre1243` (`Counterexample.lean`):

- `pre1243_violates_read_only`: the first theorem is false for the old code.
  Witness: user 1 is read-only, owns crate 7, logs in by session, and adds an
  owner (`pre1243_session_adds_owner`).
- `pre1243_token_adds_group`: the same user, by token, grants a group.
- `fixed_refuses_session`, `fixed_refuses_group`: the fixed kernel returns
  `ReadOnlyModify` on both.

All theorems depend only on `propext`, `Classical.choice` and `Quot.sound`.

## Fidelity

Modeled: the checks `check_ownership`, `check_can_modify`,
`check_download_auth`; `MaybeUser` construction for session and token logins;
the single-user owner endpoints, crate users, crate groups, yank, unyank,
publish (authorization only) and download.

Not modeled: `remove_owner` with several users at once (its last-owner check
differs slightly), `add_empty_crate`, required crate fields, storage, webhooks,
sessions expiring, and the web UI routes. Names are numeric ids. `apply` is
written in Rust and tested, but not extracted; the theorems are about the
write sets.

## Build

```
../../scripts/extract-kellnr.sh      # regenerate proofs/KellnrKernel.lean
cd proofs && lake build              # .lake/packages -> ../../docs/proofs/.lake/packages
```

## Size (2026-09-25)

Rust kernel: 374 code lines (329 extracted). Spec: 60 lines. Proofs: 466
lines (about 1.4 per extracted kernel line). Counterexamples: 61 lines.
