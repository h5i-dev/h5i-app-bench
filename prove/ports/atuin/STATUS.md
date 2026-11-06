# atuin: status

Upstream atuinsh/atuin @ `df152cd4d68b4dbc2a6f13732b31b0e013470c70`, `crates/atuin-server` (SQLite).
Gate (2026-11-06): `doctor` ok, `extract --check` ok, `check` ok (238 theorems in 13 modules, only
`propext`, `Classical.choice`, `Quot.sound`), `lint` ok ("authorization: proven (schema)").
Mutation: 23 declared mutants, 23 caught, 0 survived (runs of 20 + 3, see below).

## Theorems

**S / C / F = 15 / 10 / 3** (of the 28 theorems in `[check] theorems`; the gate checks 238 in all,
the rest are helper lemmas, class C).

| Theorem | Class | Statement (informal) | Bug it rules out / mutant it kills |
|---|---|---|---|
| `Properties.authorized` | S | every write of a successful request satisfies `Spec.allowed` (registration only when open, valid and unused name; password change / account deletion only for the authenticated user after their password verifies; records only into the requester's store and within the limit; store deletion only of the requester's) | `registration_always_open`, `email_uniqueness_dropped`, `delete_without_password`, `change_password_without_password`, `records_for_user_zero`, `size_limit_ignored` |
| `Properties.unauthenticated_never_writes` | S | no `Token <t>` header of an existing session ⇒ no writes, except registration | `any_auth_scheme`, `session_token_ignored`, `session_user_ignored` |
| `Properties.writes_owned` | S | every non-registration write belongs to the authenticated user | `records_for_user_zero`, `delete_store_of_user_zero` |
| `Properties.delete_account_needs_password` | S | `DeleteUser` only after the current password verifies | `delete_without_password` |
| `Properties.change_password_needs_password` | S | `SetPassword` only after the current password verifies | `change_password_without_password` |
| `Properties.closed_registration` | S | a closed server writes no user or session | `registration_always_open` |
| `Properties.stored_records_fit` | S | every stored record is within `max_record_size` (or the limit is 0) | `size_limit_ignored` |
| `Properties.login_needs_password` | S | login discloses a session token only of the named user and only after the password verifies | `login_without_password` |
| `Properties.outcome_independent_of_other_users` | S | the whole outcome of a request (reply, writes, error) is the same on two databases that agree on accounts, sessions, counters and the requester's own records | `next_ignores_user`, `status_ignores_user` |
| `Properties.other_accounts_untouched` | S | after a successful request, every account other than the requester's (and the next registration id) has the same user row, sessions, history and records | `delete_account_wrong_sessions` |
| `Properties.account_deletion_purges` | S | after account deletion no user row, session, history row or record with that id remains | `delete_account_keeps_history`, `delete_account_wrong_sessions` |
| `Properties.records_append_only` | S | except account/store deletion, the old store is a prefix of the new one (no overwrite) | `insert_overwrites` |
| `Properties.no_orphans` | S | in every reachable database each session, history row and record belongs to an existing user (an earlier upstream version left orphaned records; see migration `20260828000000_purge-orphaned-store.sql`) | `delete_account_keeps_records` |
| `Properties.new_account_starts_empty` | S | a newly registered account has no records or history and exactly its one new session (it cannot inherit a deleted account's data) | `user_counter_not_advanced` |
| `Properties.token_identifies_one_account` | S | in every reachable database a token authenticates at most one account | `duplicate_tokens_allowed` |
| `Properties.writes_authorized` | C | `authorized`/`writes_owned` restated in `H5iAppLib.WritesAuthorized` form for `h5i app lint` | (restatement) |
| `Verified.parse_authorization_spec` | C | header parser = `Spec.presentedToken` | |
| `Verified.authenticate_spec` | C | a found user is `Spec.Authenticated` | |
| `Verified.transition_writes` | C | shape of a successful request's write set | |
| `Verified.apply_write_ok` | C | each write's effect on the four tables | |
| `Verified.status_eq` | C | `status` = a monadic fold over the store | |
| `Verified.next_records_eq` | C | `next_records` = a monadic fold over the store, then `take` | |
| `Verified.loop_eq_foldlM` | C | index loops are `List.foldlM` (generic) | |
| `Verified.reachable_inv` | C | `Spec.Inv` holds in every reachable database | |
| `Verified.inv_step` | C | every successful request keeps `Spec.Inv` | |
| `Properties.password_change_keeps_sessions` | F | a password change leaves all sessions valid (FINDINGS F1) | fix mutant `fix_password_change_revokes_sessions` breaks it |
| `Properties.next_huge_count_is_unlimited` | F | every `count > i64::MAX` returns the whole series (F2) | `fix_count_limit` |
| `Properties.next_start_wraps` | F | `start = 2^63` selects `idx = 0` (signed comparison, F3) | `fix_unsigned_start` |

S ≥ C/3 holds (15 ≥ 10/3).

Mutants without an S theorem: `size_limit_strict` (rejects records of exactly the limit) makes no
S statement false, because a stricter limit is safe; it is caught only by the C lemma
`records_fit_spec`. Kept on purpose; an acceptance (liveness) theorem would be needed to cover it.

## Mutation results

- Run 1 (12 mutants, before the isolation/purge theorems): 11 caught, 0 survived, 1 invalid
  (`session_token_ignored`: its `old` text occurred twice; fixed).
- Run 2 (20 mutants): 20 caught, 0 survived, 0 invalid.
- Run 3 (the 3 invariant mutants, `--only`): 3 caught.

No survivors. `size_limit_strict` is caught only by the C lemma `records_fit_spec` (see above).

## Done

- Kernel (`kernel/src/lib.rs`, ~830 lines): authentication, the four account handlers, the four
  record handlers, `apply` over the SQLite tables. `client_ip.rs`: ported, extracted, not proved.
- Difftest (`difftest/`): real upstream server over HTTP + SQLite vs `transition` + `apply`;
  22,500+ requests, all agree. See DEVIATIONS.md.
- Proofs: `proofs/Spec.lean` (policy over lists), `proofs/Verified/*.lean`, `proofs/Properties.lean`.

## Next

1. `client_ip`: untrusted peer is the client; a non-peer result is only reported by a trusted chain.
   Difftest it against the pinned `client_ip.rs`. (Low security weight: upstream only logs the
   address.)
2. Totality of `transition` (no panic or overflow).
3. The full ordering spec of `next_records` (sorted by signed index, a prefix of the series).

Done since: reachability invariants (no orphans, fresh accounts empty, unique tokens).

## How to resume

```sh
ln -sfn /mnt/scratch/oss-sec/upstream/atuin prove/results/upstream/atuin   # pinned checkout
cd prove
h5i app extract --check ports/atuin && h5i app check ports/atuin && h5i app lint ports/atuin
h5i app mutate ports/atuin
cargo run --release --manifest-path ports/atuin/difftest/Cargo.toml -- --seed 1 --steps 1500
```

The machine is shared; `lake` waits on the shared package lock while other sessions build. For
quick iteration check single files with plain `lean` and `LEAN_PATH` set to the package build
directories (see `/mnt/scratch/oss-sec/tmp/b/lc.sh`, not committed). Delete `proofs/Scratch.lean`
before `h5i app check`: the gate scans it.
