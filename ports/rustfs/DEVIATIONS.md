# rustfs: what the kernel covers and where it differs

Upstream: rustfs/rustfs @ e870a6d, `crates/policy/src/policy/`. The kernel
covers 1,141 lines of it (`difftest/count_loc.py`).

## Covered

| Kernel | Upstream |
|---|---|
| `policies::policy_is_allowed`, `bucket_policy_is_allowed` | `policy.rs` `Policy::is_allowed`, `BucketPolicy::is_allowed` |
| `stmts::*` | `statement.rs`: `Statement` and `BPStatement` evaluation, `build_resource`, `kms_key_scope_matches`, `variable_resolver_for_policy_args`; `principal.rs` `is_match`; `effect.rs` `is_allowed` |
| `acts::*` | `action.rs`: `ActionSet::is_match_for_effect`, `statement_covers`, `Action::is_match_for_effect`, `action_requires_explicit_grant`, `is_table_resource_scoped` |
| `rsrc::*` | `resource.rs`: `ResourceSet` and `Resource` `is_match_with_resolver` |
| `condfuncs::*` | `function.rs` `Functions`; `function/condition.rs`; `function/{string,bool_null,number,addr}.rs`; `function/key.rs` `Key::name` |
| `keynames::common_key` | `function/key_name.rs` `COMMON_KEYS`, `name`, `var_name` |
| `awsvars::*` | `variables.rs`: `VariableResolver`, `resolve_aws_variables`, `resolve_single_pass` |
| `wildmatch::*`, `pathclean::clean` | `utils/wildcard.rs`, `utils/path.rs` |
| `bytes::parse_i64` | `str::parse::<i64>`, which `NumberFunc` calls |

## How it is checked

`difftest` depends on upstream's own `rustfs-policy` crate from the pinned
checkout; nothing is copied. `tests.rs` draws identity and bucket policies
(actions, `NotAction`, S3 and KMS resources with variables, `NotResource`,
string/IP/null/bool/numeric conditions with qualifiers and `IfExists`,
principals) and requests (actions, buckets, objects with `..` and `.`
segments, condition values, JWT claims), builds the same policy as JSON for
upstream and as kernel values, and compares `is_allowed` on 400,000 identity
and 400,000 bucket cases. Kernel mutations in each module make it fail.

## Not covered (trusted input)

- Parsing policies from JSON, and `Validator::is_valid`. The kernel takes
  parsed statements; the difftest builds both sides from the same draws.
- `Date*` and `BinaryEquals` conditions.
- Parsing IP addresses (`str::parse::<IpAddr>`) and CIDR values, and JSON
  claims into strings (`get_claim_as_strings`).
- The clock behind `aws:CurrentTime` and `aws:EpochTime`, an input in `Env`.
- `CachedAwsVariableResolver`, OPA, and how the server builds `Args`.

## Differences in form

| Where | Upstream | Kernel | Why |
|---|---|---|---|
| everywhere | `&str`, `String`, `HashMap`, `HashSet` | `&[u8]`, `Vec<u8>`, lists | Aeneas subset |
| actions | an enum per family, matched by name | `(family, name)` with the `IntoStaticStr` name | matching is on names |
| `deep_match` | a loop that recurses on `*` | recursion on indices | no loop inside a recursive function |
| `resolve_aws_variables`, `resolve_single_pass` | loops calling each other | recursion (`fixpoint`, `pass_all`, `pass_from`, `scan`) | same reason |
| `path::clean` | a lazily copied buffer (an `Option` check and a byte compare per append), then `String::from_utf8_lossy(..).to_string()` | a copy of the input written in place, returning bytes; the shell converts them back to a `String` | same bytes; with that conversion timed on the kernel side it still runs at about 0.86× upstream's time |
| `to_lowercase` (`*IgnoreCase`) | Unicode | ASCII | strings with non-ASCII capitals differ |
| `IfExists` | `IfExists(Box<Condition>)`, nestable | a flag | nested wrappers behave as one |
| `Option::clone`, `?` on `Option`, `&'static [u8]` tables | | hand-written `Clone`, `match`, `Vec<u8>` | not in Aeneas' library |
| module names | | `acts`, `rsrc` | a module may not share a name with a local variable in the generated Lean |

## Built-in policies (`policy.rs::default`)

- `LazyLock<[(&str, Policy); 8]>` becomes `defaults::default_policies()`, a
  pure constructor returning the same ordered names and policy values.
  Constants become byte-vector functions because Aeneas does not support
  static string tables. Each action retains its existing family/name form.
- `defaults::Policy` adds ID and version metadata alongside the unchanged
  evaluation `Statement`. Canned SIDs are empty and have no evaluation
  meaning. `kms_allow` and `assume_role_allow` construct the same statements;
  the literal statements share a constructor for their empty fields.
- Differential tests compare every field of all eight built-ins, generated
  requests, and constructor inputs including empty and mixed action lists.

## Action names and sets (`action.rs`)

- `actsets::action_count`, `action_name`, and `contains_name` represent the
  four enum tables over the existing `(family, name)` representation. An
  out-of-range index returns empty bytes; membership rejects invalid names.
  `AdminAction::is_valid` lists every variant upstream, so its name version
  checks membership in that table.
- Action sets remain lists. Their equality uses mutual membership and
  ignores order and duplicate counts, exactly as upstream. `push_unique`
  uses an index loop. Dereferencing becomes an explicit slice accessor.
  Validation still accepts every constructed set, including `Action::None`.
- Differential tests enumerate every upstream enum variant independently,
  draw invalid names, and compare generated sets including duplicates,
  reversed order, empty lists and `None`.

- Action-name tables are split by family to keep Aeneas translation of match
  expressions tractable. Set membership is a helper because Aeneas rejects
  early returns from nested loops (breaks to an outer loop).

- Family tables are divided into chunks of at most sixteen entries to bound
  translation memory. Mutual membership uses one-loop helpers because
  Charon also reconstructs two early-return loops as unsupported outer breaks.

- New policy metadata has no derived `Clone`/`PartialEq`: deriving these
  would cause Aeneas to extract the existing condition enum's derived
  implementations, where its `Bool` variant shadows Lean's `Bool`. The
  canned constructor needs neither trait; existing types remain unchanged.
