# defguard: status

Upstream DefGuard/defguard @ `12508b40a49121f5439cdb2701b751df1b72826c`.
Gate (2026-11-06): `extract --check` ok, `check` ok (167 theorems in 8 modules, only `propext`,
`Classical.choice`, `Quot.sound`), `lint` ok.
Mutation: MUTATION_SUMMARY

## Theorems

**S / C / F = 15 / 7 / 5** (of the 27 theorems in `[check] theorems`; the gate checks 167 in all,
the rest are helper lemmas, class C).

| Theorem | Class | Statement (informal) | Mutant it kills |
|---|---|---|---|
| `Properties.locked_name_blocked` | S | a name with ≥ 5 recorded failures, the last within 5 minutes, is refused before the password is looked at | `lockout_not_enforced`, `lockout_threshold_six` |
| `Properties.verified_needs_password` | S | a login succeeds only if the name is not locked and the password verifies | `password_ignored` |
| `Properties.failure_recorded` | S | a wrong password typed with a username is recorded under it, at `now` | `failure_not_logged` |
| `Properties.fifth_failure_locks` | S | the fifth failure inside the window locks the username for the next 5 minutes | `lockout_threshold_six`, `failure_not_logged` |
| `Properties.session_info_sound` | S | `SessionInfo` needs a stored unexpired session (or, with a business licence, an admin's API token); MFA users need an MFA-verified session; `is_admin` is admin-group membership | `mfa_gate_dropped`, `api_token_for_everyone`, `session_expiry_ignored` |
| `Properties.expired_session_rejected` | S | an expired session cookie authorizes nothing | `session_expiry_ignored` |
| `Properties.admin_role_sound` | S | `AdminRole` admits only an active admin with a valid credential | `disabled_admin_allowed` |
| `Properties.other_user_needs_admin` | S | another user's account goes only to an admin | `any_user_for_anyone` |
| `Properties.other_device_needs_admin` | S | another user's device goes only to an admin, and it is the requested id | `any_device_for_anyone` |
| `Properties.expired_token_never_starts` | S | an expired enrollment token opens no session and is not changed | `expired_token_starts` |
| `Properties.token_single_session` | S | a token's first use is recorded once and never moved; a repeat start is accepted only before `first use + timeout` | `token_reused_after_window` |
| `Properties.enrollment_session_sound` | S | enrollment requests need an enrollment token with an open session and act for its user | `any_token_type` |
| `Properties.fresh_addresses_valid` | S | a fresh assignment gives each subnet its lowest address that is inside it, not the network, broadcast or gateway address, not used, not reserved | `gateway_assignable`, `reserved_ignored`, `used_ignored`, `first_host_skipped` |
| `Properties.full_only_when_full` | S | `NetworkFull` only for a subnet with no assignable address | `first_host_skipped` |
| `Properties.merge_ranges_exact` | S | merged firewall ranges cover exactly the input's values (for ranges with `start ≤ end ≤ max`) | `merge_always`, `merge_end_shrinks`, `last_range_dropped` |
| `Verified.verify_username_ok` | C | `verify_username` = the tracker's reset/refuse rule | |
| `Verified.log_failed_attempt_ok` | C | `log_failed_attempt` = the tracker's update rule | |
| `Verified.find_account_ok` | C | the username-then-email lookup | |
| `Verified.authenticate_cases` | C | the cases of `authenticate` | |
| `Verified.extract_session_ok` | C | `SessionExtractor` cases | |
| `Verified.start_session_ok` | C | `start_session` cases | |
| `Verified.is_session_valid_ok` | C | `is_session_valid` = `SessionOpen` | |
| `Properties.email_login_never_locked` | F | logins typed with the account's email are never locked out (FINDINGS F1) | fix mutant `fix_log_failure_under_typed_name` breaks it |
| `Properties.session_outlives_token` | F | an open enrollment session is served after the token expired (F2) | `fix_validate_checks_expiry` |
| `Properties.merge_ranges_overlap` | F | ports `1024-65535` and `2000` merge to two overlapping ranges (F3) | `fix_next_saturates` |
| `Properties.kept_address_unchecked` | F | on readdressing, a current address inside the subnet is kept unchecked (F4) | `fix_recheck_kept_address` |
| `Properties.keeps_gateway_address` | F | a device at the subnet's gateway address keeps it (F4) | `fix_recheck_kept_address` |

S ≥ C/3 holds (15 ≥ 7/3). Every S theorem has at least one mutant that makes it false; the
mapping above is by what the mutant changes (the mutation run reports only that a proof broke).

Limits of the statements:

- The S theorems are partial correctness: they constrain successful results (`= ok ...`). A kernel
  that always failed would satisfy them; the difftest is the evidence that it does not.
- `kept_address_unchecked` and `keeps_gateway_address` assume the call succeeds; the difftest has
  9,127 such results (FINDINGS F4).
- `merge_ranges_exact` assumes well-formed input ranges (`start ≤ end ≤ max`). Upstream builds them
  from the ACL's configured ports and addresses; whether a caller can pass an empty range
  (`start > end`) was not checked.

## Mutation results

- Run 1 (the 15 lockout, guard and token mutants): 15 caught, 0 survived, 0 invalid.
- Run 2 (the 9 address and range mutants, `--only`): RUN2_SUMMARY

## Done

- Kernel (`kernel/src/`): `lockout.rs` (tracker, `authenticate`), `auth.rs` (session extraction,
  `SessionInfo`, `AdminRole`, per-user guards), `token.rs` (enrollment tokens), `ranges.rs`
  (`merge_ranges`), `ipalloc.rs` (`assign_next_network_ip`), `util.rs`.
- Difftest (`difftest/`): pinned upstream source compiled with seams (DEVIATIONS.md). Seeds 1-4:
  400,000 tracker operations, 400,000 token cases, 40,000 `merge_ranges` port sets (all exact),
  40,000 locations for address assignment (26,898 assignments, 13,102 full subnets). All agree.
- Proofs: `proofs/Spec.lean` (policy), `proofs/Verified/{Lockout,LoginGate,Guards,Tokens,IpAlloc,Ranges}.lean`,
  `proofs/Properties.lean`.

## Next

1. Firewall rule generation (`enterprise/firewall/mod.rs` `create_rules`): allowed and denied
   users/devices per ACL. It is the largest remaining security decision.
2. Totality: `merge_ranges` and `assign_next_network_ip` do not fail on well-formed input.
3. Non-overlap of `merge_ranges` output when no range ends at the maximum (the positive side of F3).

## How to resume

```sh
ln -sfn /mnt/scratch/oss-sec/upstream/defguard prove/results/upstream/defguard   # pinned checkout
cd prove
h5i app extract --check ports/defguard && h5i app check ports/defguard && h5i app lint ports/defguard
h5i app mutate ports/defguard
cargo build --release --manifest-path ports/defguard/difftest/Cargo.toml
$CARGO_TARGET_DIR/release/defguard-difftest --seed 1 --steps 100000
```

For quick iteration check single files with plain `lean` and `LEAN_PATH` (see
`/mnt/scratch/oss-sec/tmp/b/lcd.sh`, not committed); `lake` waits on the shared package lock.
