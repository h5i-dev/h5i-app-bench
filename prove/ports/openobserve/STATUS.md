# OpenObserve port: status

**Theorems in the gate: S 13 / C 18 / F 1.** S ≥ C/3 holds.
**Gate:** `h5i app doctor`, `h5i app extract --check`, `h5i app check` (397 theorems in 9 modules, only
propext/Classical.choice/Quot.sound) and `h5i app lint` pass. Lint only passes with the
`upstream-src` symlink moved away, because otherwise lint scans upstream's server code.
**Mutation:** see the table below. The mutation runs are in progress; results are filled in as they finish.

Upstream: openobserve/openobserve @ `a7745479a44bb2dd6f3498b2b3902304600bb466`. Scope, trusted
boundary and deviations are in [DEVIATIONS.md](DEVIATIONS.md); findings are in [FINDINGS.md](FINDINGS.md).

## Theorems

`V` = `openobserve_kernel.Verified`, `P` = `openobserve_kernel.Properties`. Every S theorem is a
statement about the extracted `validate_delegated` (one request with a delegated token) that holds
for every input. The route theorems assume `path.length < usize::MAX`.

| Theorem | Class | Statement (for every accepted `validate_delegated` request `d`) | Bug it rules out | Mutant that kills it |
|---|---|---|---|---|
| `P.expired_token_never_accepted` | S | the token's decoded claims have `now < exp` | off-by-one or missing expiry check | `expiry_off_by_one` (caught) |
| `P.forged_token_never_accepted` | S | the presented MAC equals the MAC under the current key, or under the previous key when configured | signature check skipped or OR-ed wrongly | `signature_ignored` (caught) |
| `P.previous_key_only_when_configured` | S | without a previous key, only the current key's MAC verifies | a missing key treated as a match | `missing_previous_key_verifies` |
| `P.accepted_token_lifetime_bounded` | S | `v = 1` and `exp ≤ now + 3720`, in integer arithmetic | missing skew or lifetime limit, wrong constant | `no_issued_at_skew_check`, `lifetime_two_hours` |
| `P.delegated_identity_is_org_member` | S | some membership row matches `(d.org, d.user_email)` with role `d.user_role` and `is_internal = !is_external` | cross-org lookup, role escalation | `member_of_any_org`, `role_escalated_to_root` |
| `P.revoked_link_denies` | S | if every link row with the token's link id is revoked, nothing is accepted | revocation ignored | `revoked_link_kept` |
| `P.delegated_subject_is_linked_user` | S | the link row is live, its user is the token subject, and its installation is live and serves `d.org` | subject, installation or org-connection checks dropped | `subject_not_checked`, `revoked_installation_kept`, `org_connection_not_checked` |
| `P.slack_off_denies` | S | Slack is on, signing keys are available, and `d.org` is not Slack-disabled | kill switch or per-org disable ignored | `slack_switch_ignored`, `disabled_org_ignored` |
| `P.blocked_external_denied` | S | an identity on the domain blocklist is accepted only if it is internal | blocklist ignored | `blocklist_ignored` |
| `P.delegated_route_in_token_org` | S | the path's org (`/{org}/…`, `/v2/{org}/…`) is the token's org | cross-org route access | `path_org_not_compared` |
| `P.delegated_methods_limited` | S | the method is GET, POST or PATCH (never DELETE or PUT) | method allowlist ignored | `any_method_on_any_route` |
| `P.delegated_never_on_proxy` | S | the mount prefix is not `/proxy/` | proxy refusal dropped | `proxy_allowed` |
| `P.slack_action_only_alerts_and_oncall` | S | a `slack_action` token's second org-relative segment is `alerts` or `oncall` | the Slack button scope given the wider assistant table | `slack_action_gets_assistant_scope` |
| `P.lifetime_check_overflows` | F | `check_claims` fails on `exp = i64::MAX, iat = -10` (upstream release builds wrap and accept) | — | FINDINGS F1 |
| `P.accepted_claims` | C | bridge: claims behind an accepted request | | |
| `P.accepted_route` | C | bridge: `Spec.checkRoute` holds for an accepted request | | |
| `V.validate_delegated_ok` | C | inversion of a successful `validate_delegated` | | |
| `V.verify_ok` | C | inversion of `verify` (no bound needed) | | |
| `V.verify_spec` | C | `verify = Spec.verifySpec`, when claims arithmetic fits `i64` | | |
| `V.check_claims_spec` / `V.check_claims_ok` | C | `check_claims = Spec.checkClaims`; inversion | | |
| `V.constant_time_eq_spec` | C | `constant_time_eq a b = (a = b)` | | |
| `V.load_link_facts_ok`, `V.admit_ok` | C | store lookup / `LinkFacts::admit` inversions | | |
| `V.split_slash_spec` | C | `split('/')` = `Spec.splitSlash` | | |
| `V.path_org_spec` | C | `path_org` = `Spec.pathOrg` | | |
| `V.segments_match_spec`, `V.in_scope_spec`, `V.check_route_spec` | C | route matcher = `Spec` | | |
| `V.checkRoute_ok` | C | inversion of `Spec.checkRoute` | | |
| `V.assistant_scope_spec`, `V.slack_action_scope_spec` | C | the kernel tables equal the generated spec tables | | |

That is 13 S, 18 C (counting each row of the list; the two-name rows count two) and 1 F.

## Mutation results

`h5i app mutate ports/openobserve` (run with `-j 2` on a shared 4-core host, about 15 min per mutant):

| Mutant | Result |
|---|---|
| baseline | ok |
| `expiry_off_by_one` | caught |
| `signature_ignored` | caught |
| the remaining 16 | running |

## What is next

1. Finish the mutation runs, plus `--auto`, and record survivors.
2. S theorem: the token org equals the org that RBAC and the user lookup use (`Spec.orgFromPath`,
   the model of `core::auth::org_from_path`), so the delegation check and the permission check
   agree on the org. The tables are already proved; port `org_from_path` into the kernel and difftest it.
3. Port the gRPC `check_auth_inner` decision (internal/super-cluster token, ingestion token,
   user token/password, membership in the header org) and alert-ack `decide`; then
   `PublicLinkStatus::derive` and `validate_password_strength`.
4. Then the second project, spacedrive.

## How to resume

- Toolchain: `source /mnt/scratch/oss-sec/env.sh`. `proofs/.lake/packages` must be the shared-cache
  symlink. Never let lake rebuild Mathlib.
- `python3 difftest/gen_tables.py` regenerates `kernel/src/tables.rs`, `proofs/SpecTables.lean` and
  `proofs/Verified/Tables.lean` from upstream. Then run `h5i app extract ports/openobserve`.
- Difftests: `cd difftest && cargo test --release` (needs `ports/openobserve/upstream-src`).
- Move `upstream-src` away before `h5i app lint` or `h5i app mutate` (they walk the directory).
