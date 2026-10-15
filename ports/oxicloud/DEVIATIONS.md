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

## User-role hierarchy

`userrole` ports `domain/entities/user.rs` `UserRole`, including stored and
session parsing, wire spelling, rank and privilege predicates. Wire inputs
are byte slices and wire outputs are owned byte vectors; `as_bytes` is upstream `as_str`. The accepted spellings are
ASCII, so comparison over UTF-8 bytes preserves string equality. Arbitrary
byte slices are also accepted as inputs and unrecognized spellings are refused.
`bytes::equal` replaces string equality with an indexed loop.

## Authorization discriminators and identity

`authwire` ports the `Subject`, `Resource`, `Permission`, and `Role` wire
and identity helpers in `domain/services/authorization.rs`. String inputs
are UTF-8 byte slices and static string results are owned byte vectors, as
for user roles. UUID payloads retain the existing injective `u64` identity
representation. `Permission::ALL` and `Role::ALL` become functions returning
owned vectors in exactly the upstream order. Enumeration order is independent
of the kernel's existing role variant order.


## Drive policy resolution and guards

`drivepolicy::Policies` retains all ten upstream `DrivePolicies` knobs, while
`model::DrivePolicies` remains the existing projection used by the ACL engine.
`Overrides` preserves the distinction between an absent override and an explicit
false value. The policy guard functions return the existing error-kind representation;
error formatting and audit emission stay in the shell. Audit-only context is
omitted from the pure interface; the owner guard retains `caller_is_admin`
and the external-sharing guard retains both principal kind and external flag.

### Session state (`domain/entities/session.rs`)

- UUIDs in this module use their full 128-bit integer representation. UTC timestamps
  use opaque `(seconds: i64, nanoseconds: u32)` components, including chrono's
  leap-second representation. The pure state operations do no time arithmetic.
  Timestamp validity and wall-clock reads remain in the shell.
- Strings use UTF-8 byte vectors. Borrowed string getters return references to
  those vectors; optional borrowed strings return references to optional vectors.
  These expose the same immutable contents and presence information.
- `SessionOrigin::as_str` returns owned bytes; `from_wire` compares bytes exactly,
  retaining Unknown for every unrecognized spelling. No normalization is added.
- Session fields are public for the extracted snapshot representation. Upstream
  constructors, getters, revocation, and binding setters remain distinct functions.
  `with_dpop_jkt` retains the panic on an already-bound session. Clock/randomness
  in `new` and clock-based `is_expired` stay outside the pure state kernel.

### Login and storage-boundary validation

- `classify_email_verification` keeps both its rejection bit and all three audit
  reason distinctions. Static reason strings use `EmailReason` variants; the shell
  maps each variant back to its original string.
- `validate_dpop_jkt` accepts UTF-8 bytes and returns an owned exact copy on success.
  Its two static error messages use `JktError` variants, preserving length-error
  precedence over alphabet errors. Byte scanning loops replace iterator `all`.
- `is_valid_entry_name` scans bytes instead of Unicode scalar values. The permitted
  characters are all ASCII, so every non-ASCII scalar is rejected by both versions;
  the length check remains the upstream UTF-8 byte length check.
- The differential-test build extracts the pinned private classification and JKT
  validation function bodies verbatim into an oracle. Public storage validation is
  called directly from the upstream crate. No upstream source is modified.
- `AuthApplicationService::available_disk_space` and its caller `capped_quota` stay
  in the shell: both execute a filesystem space query, although the ceiling's
  syntactic classifier did not identify that I/O.

### Share state (`domain/entities/share.rs`)

- Share UUIDs use full 128-bit integers, strings use UTF-8 byte vectors, and optional
  strings use optional vectors. Borrowed getters return references to these values.
- `ShareItemType` retains both variants. Timestamps and expiry are the original
  unsigned seconds, without normalization or an added expiry check in restoration.
- Share snapshots expose their fields for extraction. Each upstream restoration,
  observation, password/token update, and access-counter operation is retained.
  Password presence includes an empty stored hash, as upstream does.
- The access counter retains checked integer addition in the kernel and differential
  tests; extraction models an overflowing increment as failure. Clock and randomness
  in share creation and expiry checks remain in the shell.

### Subject-group namespace and virtual groups

- UUIDs use their complete `u128` value; text uses UTF-8 bytes, timestamps use
  the existing seconds/nanoseconds transport, and member tags retain their UUID.
  The well-known Internal UUID and nesting bound retain their pinned values.
- Name validation accepts precisely the upstream ASCII namespace and preserves
  byte-length bounds and error precedence. ASCII predicates replace Unicode
  character iteration; every non-ASCII character is rejected. The complete
  byte scan also rechecks the already accepted initial alphanumeric byte.
- `InvalidName(String)` diagnostics are represented by four typed reasons.
  The shell can format the same diagnostic from the original input and first
  invalid character; differential tests reconstruct and compare those strings.
  Random IDs and clock reads in group creation remain in the shell.

### Magic-link row state and redemption

- The complete row is transported: UUIDs use `u128`, text uses UTF-8 bytes,
  timestamp seconds/nanoseconds use the session representation, and optional
  resource kinds, IDs, use timestamps, and browser challenges remain independent.
  Borrowed string views use borrowed byte vectors; absent and empty stay distinct.
- Resource and lifecycle discriminators retain exact, case-sensitive spellings.
- Expiry and redeemability take an explicit UTC timestamp instead of consulting
  `Utc::now()`. The shell supplies that clock read. Timestamp comparison uses
  signed seconds followed by nanoseconds, including Chrono's leap-second encoding.
  Expiry is strict: equality remains within the lifetime; only Pending can redeem.
  Random minting, timestamp arithmetic in minting, and display formatting stay
  in the shell. The pure decision does not implement the transactional state change.
- Differential tests compile the pinned expiry and redeemability method bodies
  with only an explicit clock parameter substituted, compare boundary instants,
  and also bracket calls to the original clock-reading methods.

### Account snapshot and credential signals

- `User` and `UserParts` retain all 22 upstream fields. UUIDs use all 128 bits;
  text and optional borrowed text use UTF-8 byte vectors and borrowed vectors;
  timestamps reuse the seconds/nanoseconds representation. Signed quota/usage
  values and independent federation fields are preserved without extra validation.
- The opaque `serde_json::Value` UI-preferences field is transported as canonical
  JSON bytes supplied by the shell (`serde_json::to_vec`). These functions never
  inspect it. Minimal restoration supplies the bytes `{}`, matching the upstream
  empty-object default. Full restoration preserves any supplied JSON value.
- Owned decomposition constructs a separate complete `UserParts` record by moving
  all fields. Credential presence distinguishes absent from present-empty values;
  password and federation-subject presence determine the non-magic-link signal.
  Federation-issuer presence and email-verification timestamp presence retain
  their independent meanings. Federation discriminator spellings remain exact.

### Deployment administrator decision

- Administrator checks transport subject variants with full `u128` UUIDs. Their
  outcome depends only on the variant; no identity bits are truncated.
- Stable denial labels are typed `AdminDenial` values with an exact byte encoder.
  `require_system_admin` returns `Allowed` or `Denied(reason)`; the shell maps
  Allowed to `Ok(())`, and every Denied to the upstream `DomainError` with kind
  AccessDenied, entity type `System`, message `Admin access required`, and no ID
  or source. The reason is retained for the upstream audit event. Logging stays
  in the shell; the pure decision uses the same reason and ordering.
- Differential tests compile the pinned private reason function verbatim and
  call the original public trait method on `PgAclEngine` using a lazy pool;
  these administrator checks perform no database queries.

### Reviewed discovery serialization boundary

The CalDAV and CardDAV principal PROPFIND response generators, their standard
and requested principal-property writers, and the CardDAV principal/home-set
URL writers remain in the shell. Their only work is XML event serialization
through `quick_xml::Writer<W: Write>` (including response-property selection
and server-base-path URL formatting). The ledger records each reviewed item
individually as outside; these are not counted as ported authorization logic.

### Live-account role reconciliation

- `UserFlags` preserves all four account flags. The lookup input is represented
  by `FlagsLookup`: Found carries those flags, NotFound is exactly the upstream
  NotFound error kind, and Unavailable represents every other domain error.
  These decisions observe no other error fields. UUID inputs retain all 128 bits.
- Live roles use owned UTF-8 bytes instead of SmolStr. A successful live lookup
  supplies the canonical current account role; inactive or missing accounts
  produce Revoked. Other lookup errors preserve the claim bytes exactly.
- Internal-account failures use typed External/NoAccount results. The shell
  maps both to status 403 and error type Forbidden, with the respective exact
  messages `External users cannot access this endpoint` and
  `This endpoint requires a user account`. Other outcomes map to `Ok(())`.
- Audit events remain in the shell. Differential oracles compile the pinned
  decision bodies, substituting inferred owned-string construction and the
  numeric 403 status, and replacing audit calls with no-op test events.
