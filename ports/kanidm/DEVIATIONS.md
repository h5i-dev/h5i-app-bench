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
