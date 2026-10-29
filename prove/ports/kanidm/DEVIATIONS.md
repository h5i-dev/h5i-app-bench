# kanidm: what the kernel covers and where it differs

Upstream: kanidm/kanidm @ f608c4f, `server/lib/src/`. The kernel covers 2553
lines of it (`difftest/count_loc.py`): the whole access control module
(`server/access/`) except profile parsing, and the entry, filter, value-set
and identity code it calls.

## Covered

| Kernel | Upstream |
|---|---|
| `access::*` (`search_related_acp`, `filter_entries`, `search_filter_entries`, `search_filter_entry_attributes`, `modify_related_acp`, `modify_allow_operation`, `batch_modify_allow_operation`, `modify_allow_operation_per_entry`, `create_allow_operation`, `delete_related_acp`, `delete_allow_operation`, `effective_permission_check`, `entry_effective_permission_check`), `resolve_access_conditions` | `access/mod.rs`, the `AccessControlsTransaction` trait |
| `search_acc::*` | `access/search.rs` |
| `modify_acc::*` | `access/modify.rs` |
| `create_acc::*` | `access/create.rs` |
| `delete_acc::*` | `access/delete.rs` |
| `protected::*`, `migration::*` | `access/protected.rs`, `access/migration.rs` |
| `profiles::*` | the profile types of `access/profiles.rs` |
| `entry_impl::*` | `entry.rs`: the `get_ava_*` accessors, `attribute_*`, `entry_match_no_index(_inner)`, `reduce_attributes`, `get_uuid` |
| `filter_impl::*` | `filter.rs`: `resolve_no_idx`, both `get_attr_set` |
| `valueset::*` | `contains`, `substring`, `startswith`, `endswith`, `lessthan` and the accessors of `valueset/{utf8,iutf8,iname,uuid,uint32,oauth}.rs`; `Value::to_str` |
| `identity_impl::*` | `server/identity.rs`: `get_uuid`, `get_memberof`, `access_scope`, `InternalRole::get_uuid` |

## How it is checked

`difftest/extract_upstream.py` builds `difftest/upstream`, a crate named
`kanidmd_lib` laid out like `server/lib/src`. The six files of the access
module other than `mod.rs` and `profiles.rs` are copied whole; from those two,
and from `entry.rs`, `filter.rs`, `value.rs`, `valueset/*.rs`, `modify.rs`,
`event.rs`, `server/identity.rs`, `server/batch_modify.rs`,
`constants/{entries,uuids}.rs` and `macros.rs`, the items the module uses are
cut by name, so `crate::` paths resolve unchanged. `kanidm_proto`'s
`attribute.rs` and `constants.rs` are copied into `upstream/proto` (without
the OpenAPI derive, which is not available offline). Stubs
(`upstream/stubs/`) stand in for the entry states, the `ValueSetT` trait
object, the filter cache and the logging macros (no-ops). Seams appended after
the copied text build profiles, entries, filters and modify lists and
implement `AccessControlsTransaction` over given profiles.

`src/tests.rs` runs all seven public operations of the trait on both sides
for 100,000 random cases (profiles with group, entry-manager and empty
receivers and random target filters, user, sync and internal identities with
every access scope, entries with protected, sync, OAuth2, application and
migration classes, modify lists, batch modify sets, created entries) and
compares released entries, reduced attribute sets, effective permissions and
decisions. Mutating the kernel (13 mutations, `if !grant && !denied` →
`if !grant` excepted, which is equivalent) makes it fail. `src/props.rs`
checks each statement of `proofs/Properties.lean` on 150,000 cases and
requires its premises to hold at least 300 times.

## Not covered (trusted input)

- Parsing profiles from entries (`AccessControl*::try_from`): the kernel
  starts from the parsed `AccessControlSearch`/`Create`/`Modify`/`Delete`.
  The rule that searching `memberof` implies `directmemberof` lives there.
- Filter validation against the schema, the index-aware resolution
  (`resolve_idx`), `optimise` and the resolve cache. With no index metadata
  `resolve` is `resolve_no_idx` followed by `fast_optimise`, which only sorts
  and deduplicates `And` and `Inclusion` terms; matching is unaffected, so it
  is left out.
- The transaction machinery (`CowCell`, `ARCache`), SCIM conversions, logs.
- Value syntaxes other than utf8, iutf8, iname, uuid, reference, uint32 and
  OAuth2 scope maps.

## Differences in form

| Where | Upstream | Kernel | Why |
|---|---|---|---|
| everywhere | `Attribute` enum, `String`, `&str` | attribute and class names as `Vec<u8>` | no strings in Aeneas; `Attribute` is a bijection with its lower-case name |
| everywhere | `BTreeSet`, `BTreeMap`, `HashMap` | vectors; inserts skip present elements; lookups take the first match | no maps in the subset; the difftest compares as sets |
| `Uuid` | `uuid::Uuid` | `u128` | `Uuid`'s order is its big-endian bytes, which is `u128`'s |
| `Entry<VALID, STATE>` | type-state generic, `Arc` | one `Entry { uuid, attrs }`; sealed entries carry their uuid, created ones read it from `attrs` | no generics over states or `Arc` |
| `ValueSet` | `Box<dyn ValueSetT>` | an enum, one variant per implementation; OAuth2 scope maps keep only their keys (the groups) | no trait objects; the access module reads only the keys |
| `PartialValue`, `Value` | two enums | one enum | the module only reads `Value::to_str` |
| `Identity` | also source, session, limits, verification time | origin and scope | not read by the module |
| `FilterResolved` | carries index slopes | no slopes | slopes only order terms |
| `*Resolved` profiles | borrow the profile | copy the sets the checks read (`attrs`, `classes`, the four modify sets) | no borrows inside structs |
| protected and migration class sets | `LazyLock<BTreeSet<String>>` | membership functions; `is_disjoint`, `is_subset`, `sub`, `remove` written over them | no statics of sets |
| closures and iterator chains (`filter_map`, `any`, `all`, `flat_map`) | | loops in helper functions (`search_allowed_attrs`, `modify_scoped_acp`, `create_any_acp`, `delete_any_acp`, `*_all_entries`, `requested_*`) | no closures or iterator adapters |
| `search_related_acp` | resolves, then trims by requested attributes | trims as it resolves | same result, one pass |
| `?` on `get_ava_refer(EntryManagedBy)` | returns `None` from the closure | `receiver_applies` returns `false` | same effect: the profile is skipped |
| `entry_match_no_index_inner` | `l.iter().any/all` | mutual recursion with `match_any`, `match_all` | no loop inside a recursive function |
| `Utf8` substring tests | `to_lowercase` (Unicode) | ASCII lower-casing | no Unicode tables; the difftest uses ASCII |
| conditional pushes | `if ok { v.push(x) }` | `push_if`, `extend_if` helpers | Aeneas could not join the branches |
| `constrain` sets that are always empty (search, create) | kept | kept | |
| byte-string constants | `ATTR_*`, `ENTRYCLASS_*` | literals (`b"class"`) | Aeneas rejects a constant reference used in two branches |
| errors | `OperationError` | `OperationError::InvalidState` only | the only one returned |

`valueset::str_contains` loops while `i <= hay.len() - needle.len()` rather
than `i + needle.len() <= hay.len()`. The two agree in Rust, where a slice holds
at most `isize::MAX` bytes; in the extracted model a slice may hold
`Usize.max`, where the sum overflows. The rewrite keeps the original theorem
statements free of a length precondition.

## Credential soft-lock expansion (2026-10-28)

`softlock.rs` ports `credential/softlock.rs` at the same full revision
`f608c4fe14dfd8d5df8edeed470bf1fb92060abd`. `Time { secs, nanos }` represents
canonical `std::time::Duration` components, preserving nanosecond precision.
The Rust adapter must supply `nanos < 1_000_000_000`. Time comparison and
addition by whole seconds agree on canonical durations; reset deadlines
explicitly have zero nanoseconds. Count, time overflow, and zero TOTP period
retain checked Rust failure behavior. `apply_time_step` and `record_failure`
return the updated record instead of mutating a borrowed record. Source maps
are in `source-map.json`; helpers implementing Duration primitives add no
upstream application source coverage.

The canonical time-step theorem proves its complete result for all extracted
states, with no length/time precondition. New/validity are exact. Failure
policy and recording theorems prove security properties of successful results
(counter retention/increment, locking, and saturated reset deadlines), rather
than absence of arithmetic failure or full behavioral equivalence. Differential
tests compare every state field and validity against unmodified pinned bodies
with controlled arbitrary states: 600,000 fixed-seed random comparisons and
3,168 exact time/threshold cases. The reference reproduction command is
`python3 difftest/extract_softlock.py <pinned-bare-git-dir>`; the test is
`cargo test --release --locked --manifest-path kernel/Cargo.toml --test softlock`.

## Schema dispatch (2026-10 coverage batch)

`schema_tags::{partial_accepts,value_accepts,ava_accepts}` ports the complete
schema discrimination decisions in `SchemaAttribute::{validate_partialvalue,
validate_value,validate_ava}` at the same pin. The 47 syntax constructors are
preserved. Partial/full value constructors are represented by explicit U16 tag
IDs in `difftest/schema/tags.json`; arbitrary tag IDs outside that table are
outside the upstream representation. Payload fields are observationally
irrelevant to partial dispatch. Full payload `Value::validate`, AVA intrinsic
`ValueSet::validate`, AVA count and actual syntax are caller projections. Their
implementations are not covered by the dispatch proof. Rejection's attribute
name is the caller's same attribute and is omitted from the Boolean return.

All 41,830 combinations of upstream tags, payload validity and AVA structural
conditions agree with the unmodified pinned method bodies. Reference extraction
is reproducible with `python3 difftest/schema/prepare.py <pinned-bare-git>`.
Run `cargo test --release --locked --test schema_tags -- --nocapture` in kernel.
The Lean membership specifications cover arbitrary U16 tags, not just the finite
differential cases, and the exact AVA relation covers arbitrary Usize counts.

## Credential update commit decision (2026-10 coverage batch)

`credential_commit::can_commit` ports the entire commit/warning policy decision
at `idm/credupdatesession.rs::CredentialUpdateSession::can_commit`. Its inputs
are exact observations used by that function: credential policy, primary
presence and `Credential::is_mfa`, passkey/attested-passkey collection presence,
and optional attestation-list emptiness. It does not validate credential
cryptography or list contents. Ordered warnings are represented as three slots
(policy warning, attestation warning, missing credentials); this is isomorphic
to the upstream warning list, including the fact an empty attestation list
warns without itself preventing commit. No warnings are conflated or reordered.
The 252 input combinations are exhaustively compared with the original pinned
method body and exact ordered warning vectors. `difftest/credential_commit/`
retains a reproducible method extractor and immutable source identity.

## Scalar account-policy resolution (2026-10 coverage batch)

`account_policy::fold_from` preserves the scalar projection of
`ResolvedAccountPolicy::fold_from` at f608c4f, including defaults, expiry minima,
password and credential-rank maxima, optional search-limit maxima, optional
fallback conjunction, and the final single-factor NIST minimum. Credential types
are their exact upstream ordered U16 discriminants. CA-list intersection and
its cryptographic payload result are excluded; this projection does not claim
complete behavioral equivalence of the entire upstream method. Differential
reference copies the full original method unchanged and independently varies
CA masks while comparing every scalar output field. Current test includes
20,049 resolution cases, including empty input and policy/password boundaries.
