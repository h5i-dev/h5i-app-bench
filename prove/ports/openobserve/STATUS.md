# OpenObserve port: status

**Theorems in the gate: S 21 / C 29 / F 1** (51 in `[check] theorems`). S ≥ C/3 holds.

**Gate:** all of these pass:
- `h5i app doctor`
- `h5i app extract --check`
- `h5i app check`: 468 theorems in 11 modules, using only propext, Classical.choice and Quot.sound
- `h5i app lint`, which passes only when the `upstream-src` symlink is moved away first; otherwise lint scans upstream's server code.

**Mutation:** the first 14 hand-written mutants were all caught (14/14, 0 survived). The 12
mutants added later are still running (`/mnt/scratch/oss-sec/tmp/c/mutate2.log`).

**Upstream:** openobserve/openobserve @ `a7745479a44bb2dd6f3498b2b3902304600bb466`. Scope, trusted
boundary and deviations are in [DEVIATIONS.md](DEVIATIONS.md). Findings are in [FINDINGS.md](FINDINGS.md).

## Theorems

Prefixes: `V` = `openobserve_kernel.Verified`, `P` = `openobserve_kernel.Properties`.

The delegated-token S theorems are about the extracted `validate_delegated`. The gRPC S
theorems are about `check_auth_inner` and `check_internal_auth`. Each holds for every input
and every store table. The route theorems assume `path.length < usize::MAX`.

### S: security properties

| Theorem | Statement (for every accepted request) | Bug ruled out | Killing mutant (result) |
|---|---|---|---|
| `P.expired_token_never_accepted` | the token's decoded claims have `now < exp` | off-by-one or missing expiry check | `expiry_off_by_one` (caught) |
| `P.forged_token_never_accepted` | the presented MAC equals the MAC under the current key, or under the previous key when configured | signature check skipped | `signature_ignored` (caught) |
| `P.previous_key_only_when_configured` | with no previous key configured, only the current key's MAC verifies | a missing key treated as a match | `missing_previous_key_verifies` (caught) |
| `P.accepted_token_lifetime_bounded` | `v = 1` and `exp ≤ now + 3720`, in integer arithmetic | skew or lifetime limit missing or wrong | `no_issued_at_skew_check`, `lifetime_two_hours` (caught) |
| `P.delegated_identity_is_org_member` | a membership row `(d.org, d.user_email)` exists with role `d.user_role` | cross-org lookup, role escalation | `member_of_any_org`, `role_escalated_to_root` (caught) |
| `P.revoked_link_denies` | if every link row with the token's link id is revoked, the request is refused | revocation ignored | `revoked_link_kept` (caught) |
| `P.delegated_subject_is_linked_user` | the link is live and its user is the subject; its installation is live and serves `d.org` | checks dropped | `subject_not_checked`, `revoked_installation_kept`, `org_connection_not_checked` (caught) |
| `P.slack_off_denies` | Slack is on, keys are available, and `d.org` is not Slack-disabled | kill switch ignored | `slack_switch_ignored`, `disabled_org_ignored` (caught) |
| `P.blocked_external_denied` | a blocklisted identity is accepted only if it is internal | blocklist ignored | `blocklist_ignored` (caught) |
| `P.delegated_route_in_token_org` | the path's org (`/{org}/…`, `/v2/{org}/…`) is the token's org | cross-org route | `path_org_not_compared` |
| `P.delegated_methods_limited` | the method is GET, POST or PATCH | method allowlist ignored | `any_method_on_any_route` |
| `P.delegated_never_on_proxy` | the mount prefix is not `/proxy/` | proxy refusal dropped | `proxy_allowed` |
| `P.slack_action_only_alerts_and_oncall` | a `slack_action` token's second org-relative segment is `alerts` or `oncall` | wrong scope table | `slack_action_gets_assistant_scope` |
| `P.delegated_org_is_rbac_org` | the org the `AuthExtractor` derives for the permission check (`org_from_path`) is the token's org | the delegation check and RBAC reading different orgs | `downtimes_not_a_v2_org_module` |
| `P.internal_rpc_only_internal_token` | node RPCs accept only a non-empty internal or super-cluster token | an ingestion token or user credential reaching node APIs | `any_token_is_internal` |
| `P.grpc_empty_token_never_authenticates` | the token is present and non-empty, even when the internal token is unset | an empty token matching an empty internal token | `empty_token_allowed` |
| `P.grpc_empty_password_never_authenticates` | the password is non-empty, and the attached `user_id` is the presented one | a blank password matching a blank stored token | `blank_password_allowed` |
| `P.ingestion_token_scoped_to_header_org` | an `o2oi_` token is in `ORG_INGESTION_TOKENS` under `"{header org}/{token}"` | an ingestion token used in another org | `ingestion_token_any_org` |
| `P.ingestion_token_only_on_otlp` | outside OTLP, acceptance always went through a user record's token or password | ingestion tokens accepted by non-OTLP services | `ingestion_token_on_all_services` |
| `P.grpc_user_is_member_of_header_org` | a non-root user's record is the `"{header org}/{lowercased id}"` membership, matched by that record's token or the user's password hash | cross-org authentication, password check skipped | `membership_in_default_org`, `any_hash_matches` |
| `P.sso_user_needs_token` | an SSO user (empty salt) authenticates outside OTLP only with its token | password login for SSO users | `any_hash_matches` |

### F: findings

| Theorem | Statement |
|---|---|
| `P.lifetime_check_overflows` | `check_claims` fails for `exp = i64::MAX, iat = -10` (`exp - iat` overflows). Upstream release builds wrap and accept the token. See FINDINGS F1. |

### C: correspondence and foundations

| Theorems | What they establish |
|---|---|
| `P.accepted_claims`, `P.accepted_route`, `P.sso_credential_is_token` | bridges from an accepted request to its claims, route and credential |
| `V.validate_delegated_ok`, `V.verify_ok`, `V.check_claims_ok`, `V.load_link_facts_ok`, `V.admit_ok` | inversions of the delegated-token path |
| `V.verify_spec`, `V.check_claims_spec` | `verify = Spec.verifySpec`, when the claims arithmetic fits in `i64` |
| `V.constant_time_eq_spec` | `constant_time_eq a b = (a = b)` |
| `V.split_slash_spec`, `V.path_org_spec`, `V.segments_match_spec`, `V.in_scope_spec`, `V.check_route_spec`, `V.checkRoute_ok` | the route matcher equals the `Spec` model |
| `V.assistant_scope_spec`, `V.slack_action_scope_spec` | the kernel tables equal the generated spec tables |
| `V.checkRoute_org_consistent`, `V.org_from_path_prefix_spec`, `V.extractor_org_id_spec` | `org_from_path` and the extractor org; a route the delegation check admits names the same org |
| `V.check_auth_inner_user`, `V.check_auth_inner_internal`, `V.check_internal_auth_ok`, `V.lookup_user_ok`, `V.get_cached_user_org_ok`, `V.join_key_ok`, `V.ascii_lower_ok` | inversions of the gRPC interceptor and its cache lookups |

## Mutation results

`h5i app mutate -j 2 ports/openobserve` on a shared 4-core host takes about 16 minutes per mutant.

- Run 1: baseline ok, then 14/14 caught: `expiry_off_by_one`, `signature_ignored`,
  `missing_previous_key_verifies`, `no_issued_at_skew_check`, `lifetime_two_hours`,
  `member_of_any_org`, `role_escalated_to_root`, `revoked_link_kept`, `revoked_installation_kept`,
  `subject_not_checked`, `org_connection_not_checked`, `slack_switch_ignored`,
  `disabled_org_ignored`, `blocklist_ignored`.
- Run 2 (`--only` for the 12 later mutants): in progress.
- Known unspecified behaviour, which is a candidate survivor: the `RESERVED_STREAM_SLOTS` and
  `ALERT_ID_LITERALS` exclusions in `seg_matches`. No S theorem states what they prevent (a
  `{stream}` slot capturing a router literal). They are pinned only by C theorems (route matcher = Spec).

## What is next

1. Record run 2 of the mutants, then run `--auto` and record its survivors.
2. Alert-ack `decide` (`core/src/alerts/ack.rs:291`), `PublicLinkStatus::derive` and
   `validate_password_strength`. These are pure and small.
3. Second project: spacedrive.

## How to resume

- Toolchain: `source /mnt/scratch/oss-sec/env.sh`. `proofs/.lake/packages` must be the shared-cache
  symlink. Never let lake rebuild Mathlib.
- `python3 difftest/gen_tables.py` regenerates `kernel/src/tables.rs`, `proofs/SpecTables.lean` and
  `proofs/Verified/Tables.lean` from upstream. Then run `h5i app extract ports/openobserve`.
- Difftests: run `cd difftest && cargo test --release`; this needs `ports/openobserve/upstream-src`.
  Twelve tests: delegated tokens, route scopes, link facts, `org_from_path`, the extractor org,
  the gRPC interceptor compiled from upstream's own file, `token_matches`, metadata validity, and the F1 demonstration.
- Move `upstream-src` away before `h5i app lint` or `h5i app mutate`, because both walk the
  project directory. The background mutate commands put it back when they finish.
