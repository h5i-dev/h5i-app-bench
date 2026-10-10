# Manual mutation checks

Each mutation was applied individually, the named differential tests were run
with `cargo test --release --offline`, and the original source was restored.
Every run compiled and failed an assertion. The normal suite passes after restoration.

| Functions | Mutation | Tests |
|---|---|---|
| `defaults::{default_version,kms_key_administrator,kms_key_user,kms_auditor,all_kms_keys,default_policies}` | return an empty value | `defaults::builtin_policies_agree` |
| `defaults::allow` | change Allow to Deny | `defaults::builtin_policies_agree` |
| `defaults::kms_allow` | remove KMS resource | `defaults::builtin_policies_agree` |
| `defaults::assume_role_allow` | remove action | `defaults::builtin_policies_agree` |
| `actsets::{action_count,action_name,s3_name,admin_name,sts_name,kms_name,contains_name,admin_is_valid}` | return zero/empty/false | `actions::action_tables_agree` |
| `actsets::{is_empty,set_is_match,action_is_match,is_valid,member,covers,eq}` | return false | `actions::action_sets_agree` |
| `actsets::as_slice` | return an empty slice | `actions::action_sets_agree` |
| `actsets::push_unique` | always push duplicates | `actions::action_sets_agree` |

The table chunk helpers (`s3_name_0` through `s3_name_4`,
`admin_name_0` through `admin_name_5`, and `kms_name_{0,1}`) were each
mutated to return an empty value; the enum enumeration test failed each time.

| Functions | Mutation | Tests |
|---|---|---|
| `valids::{default_is_valid,id_is_empty,id_is_valid,effect_is_valid,is_admin,is_sts}` | return false | `validation::statement_validation_agrees` |
| `valids::id_as_slice` | return empty slice | `validation::statement_validation_agrees` |
| `valids::action_family` | return None | `validation::statement_validation_agrees` |
| `valids::{principal_is_valid,statement_is_valid,bp_statement_is_valid}` | accept every input | `validation::statement_validation_agrees` |
| `valids::{resource_is_valid,resources_is_valid}` | accept every input | `validation::resource_helpers_agree` |
| `valids::{has_kms_action,has_kms_resource}` | return false | `validation::statement_validation_agrees` |
| `valids::error` | return InvalidVersion for every error | `validation::statement_validation_agrees` |
| `resets::{is_empty,member,covers,eq,is_match,set_matches,match_resource,set_match_resource}` | return false | `validation::resource_helpers_agree` |
| `resets::as_slice` | return empty slice | `validation::resource_helpers_agree` |
| `resets::push_unique` | always append duplicates | `validation::resource_helpers_agree` |

The validation mutations were rerun after correcting the empty-principal
fixture; the normal validation tests pass and every listed mutation still fails.
The resource predicate helpers `valids::{kms_key_valid,kms_alias_valid,resource_pattern_valid}`
were individually mutated to accept every resource; `resource_helpers_agree`
failed for each.

The phase helpers `valids::{action_selection_valid,statement_resource_rules}`
were each mutated to accept every statement; `checked_action_family` returned
None, and `family_is_mixed`, `family_is_kms`, `family_allows_empty_resource`
returned false. Each mutation failed `statement_validation_agrees`.
