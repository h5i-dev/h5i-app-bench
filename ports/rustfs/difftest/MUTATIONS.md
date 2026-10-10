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
