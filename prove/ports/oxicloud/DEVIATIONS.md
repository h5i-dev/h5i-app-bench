# OxiCloud: what the kernel covers and where it differs

Upstream: AtalayaLabs/OxiCloud @ 8c0dd33. The kernel covers 1,257 lines of
it (`difftest/count_loc.py`, which leaves out logging calls and the branches
listed under "Not covered").

## Covered

| Kernel | Upstream |
|---|---|
| `acl::check` and its helpers | `infrastructure/services/pg_acl_engine.rs` `check_inner`, `expand_user`, `subject_match_set`, `drive_of`, `direct_grant_exists`, `folder_cascade_grant_exists`, `file_direct_grant_exists`, `query_parent_point`, `cascade_grant_cached`, `direct_grant_cached`, `caller_role_on_drive_cached`, `drive_policies_cached`, `read_only_gate_applies` |
| `acl::groups_for_user` | `subject_group_pg_repository.rs` `groups_for_user` (the recursive CTE) |
| `acl::set_role`, `clear_role`, `grantapi::revoke` | `PgAclEngine::set_role` (`INSERT .. ON CONFLICT DO UPDATE`), `clear_role`, `revoke` |
| `acl::role_grants`, `role_implies` | `domain/services/authorization.rs` `Role::expand`, `roles_implying` |
| `grantapi::require` | `application/ports/authorization_ports.rs` `require` |
| `grantapi::create_grant`, `set_role_handler`, `revoke_grant` | `interfaces/api/handlers/grant_handler.rs` `create_grant`, `set_role`, `revoke_grant` |
| `grantapi::set_member_role`, `remove_member` and the `refuse_if_*` gates | `application/services/drive_management_service.rs` |
| `grantapi::refuse_external_sharing` and the policy gates in `create_grant` | `domain/entities/drive.rs` `DrivePolicies::refuse_*` |

## How it is checked

`difftest` depends on the `oxicloud` crate from the pinned checkout and runs
against PostgreSQL 17 with OxiCloud's 99 migrations applied (a container on
port 55433; see `src/tests.rs`). Each case writes random users, nested
groups, drives (with policy JSON, sometimes malformed), folder trees, files
and grants (expired, live, on missing resources), then:

- `tests.rs` asks `PgAclEngine::check` and the kernel the same questions,
  biased toward subjects and resources near existing grants;
- `endpoints.rs` runs the grant endpoints through OxiCloud's own engine,
  repositories and `DriveManagementService`, with the handlers' gate
  sequence transcribed (they take the whole `AppState`), and compares the
  reply and the `storage.role_grants` table afterwards.

The folder `lpath` the database trigger computes and the effective drive
policies (`storage.drives_effective`, decoded by `DrivePolicies::from_value`)
are read back and given to the kernel. Kernel mutations in both modules
make the tests fail. `props.rs` checks every statement in
`proofs/Properties.lean` on in-memory worlds.

## Not covered (trusted input)

- The caches in `PgAclEngine` (user groups, owners, drive roles, policies,
  cascade and direct grants, file parents) and the batched parent lookup.
  The kernel decides from the current tables, as an engine with empty caches
  does; each difftest case builds a fresh engine.
- Computing `lpath` (a database trigger) and the effective policy JSON (a
  view), and decoding it.
- E-mail subjects in `create_grant` (the magic-link invitation service), the
  message-bus notification after `revoke_grant`, and audit logging.
- Admin callers (`caller_is_admin`), listing endpoints, calendars and address
  books beyond direct grants.

## Differences in form

| Where | Upstream | Kernel | Why |
|---|---|---|---|
| ids | UUIDs | `u64`; the internal group is 1 | |
| tables | SQL queries | scans with the same `WHERE` clause; `MIN(role)` is the role with the lowest `storage.grant_role` position | |
| `groups_for_user` | a recursive CTE | rounds until no group is added, at most one per membership row | |
| time | `NOW()`, `chrono` | `now` in seconds, an input | |
| errors | `DomainError` | its `ErrorKind` | messages are not compared |
| new grant ids | `gen_random_uuid()` | `Env::fresh` | the difftest compares grants without ids |
| `role_grants`, `role_implies` | `Role::expand(..).contains(..)`, `roles_implying(..).contains(..)`: linear search of static slices | the same tables written out as a `match` of comparisons | equal on all 35 role/permission pairs (`difftest/src/bin/performance.rs`); compiles to a few comparisons instead of a slice scan, so it runs faster |
| module names | | `grantapi` | a module may not share a name with a local variable in the generated Lean |

## Scope of the statements

`drive_keeps_an_owner` and `refused_create_or_set_writes_nothing` are about
creating grants and setting roles; revocation is outside them.
`create_respects_sharing_policies` is about `create_grant`.

## Policy expansion (2026-10-29)

`drivepolicy` models all ten typed policy fields, explicit boolean overrides,
and expiry-cap inheritance from pinned `domain/entities/drive.rs`.
`policycompare` models canonical knob order, the non-defaultable read-only knob,
kind applicability, typed values, the three strictness directions, and ordered
drift findings. Comparison includes an `Other` knob for unknown names; mapping
raw strings/JSON values to the typed carriers remains a trusted input boundary.
The fixed ten-element comparison pipeline replaces the upstream iterator.

Five policy guards preserve their allow/refuse decisions. Audit events, refusal
messages, UUID representation and caller context stay outside the formal model.
The owner-change guard explicitly models the administrator flag; this does not
extend the older ACL/grant API statements to general administrator callers.
Cross-drive callers still establish that source and destination differ.

The new canonical statements prove override resolution, exact successful-result
specifications for comparison and guard decisions, and comparison transitivity.
Vector-returning statements retain their successful-execution hypotheses; they
are not unconditional allocation/termination guarantees.

`policy-difftest` compiles the entire pinned upstream `drive.rs` unchanged,
including its tests. Its only upstream-facing adapters are the authorization
subject carrier and unsupported-operation error construction/display. It checks
20,000 seeded policy scenarios against upstream, including expiry boundaries,
all three principal kinds, administrator bypass, both drive kinds, every known
knob and an unknown knob. These are differential tests, not formal equivalence.
The two kernels and proof modules are adapted from `oxicloud-verify` at
`61cd60e`; unrelated modules from that branch are not imported.
