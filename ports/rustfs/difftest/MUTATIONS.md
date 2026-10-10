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

Full-condition helpers were checked individually as follows (including all
46 handwritten functions and their helpers):

| Function | Mutation | Test |
|---|---|---|
| `conddata::key_is` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::contains_key_name` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::is_negate` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::string_covers` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::string_set_eq` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::string_inner_eq` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::binary_inner_eq` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::date_inner_eq` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::condition_eq` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::contains_condition` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::list_covers` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::functions_eq` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::is_empty` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::inner_has_value` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::has_any_key_in` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::condition_evaluate` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::all_hold` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::functions_evaluate` | `false` | `condition_data::condition_metadata_agrees` |
| `conddata::key_names` | `Vec::new()` | `condition_data::condition_metadata_agrees` |
| `conddata::op_name` | `Vec::new()` | `condition_data::condition_metadata_agrees` |
| `conddata::op_name_late` | `Vec::new()` | `condition_data::condition_metadata_agrees` |
| `conddata::to_key_with_suffix` | `Vec::new()` | `condition_data::condition_metadata_agrees` |
| `conddata::legacy_pairs` | `Vec::new()` | `condition_data::condition_metadata_agrees` |
| `conddata::key_presence` | `Vec::new()` | `condition_data::condition_metadata_agrees` |
| `conddata::views` | `Vec::new()` | `condition_data::condition_metadata_agrees` |
| `conddata::to_key` | `Vec::new()` | `condition_data::condition_metadata_agrees` |
| `conddata::clone_key_value` | `let mut out = FuncKeyValue {key:entry.key.clone(),values:entry.values.clone()}; out.key.name=Vec::new(); out` | `condition_data::condition_metadata_agrees` |
| `conddata::clone_inner` | `InnerFunc {entries:Vec::new()}` | `condition_data::condition_metadata_agrees` |
| `conddata::str_op` | `crate::condfuncs::StrOp::StringEquals` | `condition_data::condition_metadata_agrees` |
| `conddata::num_op` | `crate::condfuncs::NumOp::Eq` | `condition_data::condition_metadata_agrees` |
| `conddata::condition_view` | `crate::condfuncs::Condition {if_exists:false,cond:crate::condfuncs::Cond::Null(Vec::new())}` | `condition_data::condition_metadata_agrees` |
| `conddata::matching_view` | `crate::condfuncs::Functions {for_any_value:Vec::new(),for_all_values:Vec::new(),for_normal:Vec::new()}` | `condition_data::condition_metadata_agrees` |
| `conddata::binary_eq` | `false` | `condition_data::binary_agrees` |
| `conddata::binary_key_matches` | `false` | `condition_data::binary_agrees` |
| `conddata::binary_evaluate` | `false` | `condition_data::binary_agrees` |
| `conddata::base64_digit` | `None` | `condition_data::binary_agrees` |
| `conddata::decode_base64` | `Err(BinaryFuncValueError::InvalidBase64)` | `condition_data::binary_agrees` |
| `conddata::binary_new` | `Err(BinaryFuncValueError::InvalidBase64)` | `condition_data::binary_agrees` |
| `conddata::binary_from_encoded_values` | `Err(BinaryFuncValueError::InvalidBase64)` | `condition_data::binary_agrees` |
| `dates::digits` | `None` | `condition_data::dates_agree` |
| `dates::parse_rfc3339` | `None` | `condition_data::dates_agree` |
| `dates::parse_value` | `None` | `condition_data::dates_agree` |
| `dates::month_days` | `31` | `condition_data::dates_agree` |
| `dates::civil_days` | `0` | `condition_data::dates_agree` |
| `dates::compare` | `false` | `condition_data::dates_agree` |
| `dates::evaluate` | `false` | `condition_data::dates_agree` |

After splitting the date parser for Lean extraction, `calendar_fields`,
`time_fields`, `fraction` and `offset` were individually changed to return None,
`leap_valid` to false, and `nanos` to zero. `condition_data::dates_agree`
compiled and failed for all six; the originals were restored.

All claim and Unicode functions were individually mutated; each compiled and failed its differential test, then was restored.

| Function | Mutation | Test |
|---|---|---|
| `claims::case_insensitive_eq` | `false` | `claim_tests` |
| `claims::is_existing_object_tag_condition_key` | `false` | `claim_tests` |
| `claims::value_uses_existing_object_tag` | `false` | `claim_tests` |
| `claims::object_uses_tag` | `false` | `claim_tests` |
| `claims::array_uses_tag` | `false` | `claim_tests` |
| `claims::get_claim_case_insensitive` | `ClaimLookup::Missing` | `claim_tests` |
| `claims::find` | `None` | `claim_tests` |
| `claims::split_values` | `Vec::new()` | `claim_tests` |
| `claims::append_string_values` | `{}` | `claim_tests` |
| `claims::value_strings` | `(Vec::new(),false)` | `claim_tests` |
| `claims::values_from_claims` | `(Vec::new(),false)` | `claim_tests` |
| `claims::get_values_from_claims` | `(Vec::new(),false)` | `claim_tests` |
| `claims::get_policies_from_claims` | `(Vec::new(),false)` | `claim_tests` |
| `claims::args_get_policies` | `(Vec::new(),false)` | `claim_tests` |
| `claims::get_role_arn` | `None` | `claim_tests` |
| `claims::iam_policy_claim_name_sa` | `Vec::new()` | `claim_tests` |
| `claims::split_path` | `(Vec::new(),Vec::new())` | `claim_tests` |
| `unicode::lowercase_scalar` | `(cp,0,1)` | `claim_tests::unicode_agrees` |
| `unicode::scalar_at` | `(0,i+1)` | `claim_tests::unicode_agrees` |
| `unicode::append_scalar` | `{}` | `claim_tests::unicode_agrees` |
| `unicode::lower` | `Vec::new()` | `claim_tests::unicode_agrees` |
| `unicode::whitespace` | `false` | `claim_tests::unicode_agrees` |
| `unicode::trim` | `Vec::new()` | `claim_tests::unicode_agrees` |

The chunked Unicode range predicates, dispatcher and singleton helper were also individually mutated and caught by exhaustive scalar comparison.

| Function | Mutation | Test |
|---|---|---|
| `unicode::within` | `false` | `claim_tests::unicode_agrees` |
| `unicode::range_chunk` | `None` | `claim_tests::unicode_agrees` |
| `unicode::singleton` | `(cp,0,1)` | `claim_tests::unicode_agrees` |
| `unicode::range_0` | `None` | `claim_tests::unicode_agrees` |
| `unicode::range_1` | `None` | `claim_tests::unicode_agrees` |
| `unicode::range_2` | `None` | `claim_tests::unicode_agrees` |
| `unicode::range_3` | `None` | `claim_tests::unicode_agrees` |
| `unicode::range_4` | `None` | `claim_tests::unicode_agrees` |
| `unicode::range_5` | `None` | `claim_tests::unicode_agrees` |
| `unicode::range_6` | `None` | `claim_tests::unicode_agrees` |
| `unicode::range_7` | `None` | `claim_tests::unicode_agrees` |
| `unicode::range_8` | `None` | `claim_tests::unicode_agrees` |

The lookup and deduplication phase helpers were individually mutated after the extraction rewrite, and all three were caught.

| Function | Mutation | Test |
|---|---|---|
| `claims::case_fold_lookup` | `ClaimLookup::Missing` | `claim_tests` |
| `claims::lookup_strings` | `(Vec::new(),false)` | `claim_tests` |
| `claims::unique_values` | `Vec::new()` | `claim_tests` |

Every condition-key table function, chunk helper and server-derived predicate was individually mutated and caught, then restored.

| Function | Mutation | Test |
|---|---|---|
| `keytables::key_count` | `0` | `keytables::key_tables_agree` |
| `keytables::key_name` | `Vec::new()` | `keytables::key_tables_agree` |
| `keytables::s3_name` | `Vec::new()` | `keytables::key_tables_agree` |
| `keytables::s3_name_0` | `Vec::new()` | `keytables::key_tables_agree` |
| `keytables::s3_name_1` | `Vec::new()` | `keytables::key_tables_agree` |
| `keytables::jwt_name` | `Vec::new()` | `keytables::key_tables_agree` |
| `keytables::jwt_name_0` | `Vec::new()` | `keytables::key_tables_agree` |
| `keytables::jwt_name_1` | `Vec::new()` | `keytables::key_tables_agree` |
| `keytables::svc_name` | `Vec::new()` | `keytables::key_tables_agree` |
| `keytables::ldap_name` | `Vec::new()` | `keytables::key_tables_agree` |
| `keytables::sts_name` | `Vec::new()` | `keytables::key_tables_agree` |
| `keytables::aws_name` | `Vec::new()` | `keytables::key_tables_agree` |
| `keytables::contains_name` | `false` | `keytables::key_tables_agree` |
| `keytables::is_server_derived` | `false` | `keytables::key_tables_agree` |
| `keytables::server_derived_key_names` | `Vec::new()` | `keytables::key_tables_agree` |
| `keytables::is_server_derived_condition_key` | `false` | `keytables::key_tables_agree` |

Every policy metadata, management, tag and full-evaluation function was individually mutated and caught. The is_empty mutation initially survived; adding generated empty policies caught it, and all remaining mutations passed after that correction.

| Function | Mutation | Test |
|---|---|---|
| `manage::statement_eq` | `false` | `management::management_agrees` |
| `manage::index_member` | `false` | `management::management_agrees` |
| `manage::mark_duplicates` | `{}` | `management::management_agrees` |
| `manage::drop_duplicate_statements` | `{}` | `management::management_agrees` |
| `manage::retained_statements` | `Vec::new()` | `management::management_agrees` |
| `manage::merge_policies` | `Policy{id:Vec::new(),version:Vec::new(),statements:Vec::new()}` | `management::management_agrees` |
| `manage::append_statements` | `{}` | `management::management_agrees` |
| `manage::is_empty` | `false` | `management::management_agrees` |
| `manage::match_resource` | `false` | `management::management_agrees` |
| `manage::version_is_valid` | `Ok(())` | `management::management_agrees` |
| `manage::statement_view` | `crate::stmts::Statement{effect:st.effect,actions:Vec::new(),not_actions:Vec::new(),resources:Vec::new(),not_resources:Vec::new(),conditions:crate::conddata::matching_view(&st.conditions)}` | `management::tag_and_full_evaluation_agree` |
| `manage::bp_statement_view` | `crate::stmts::BPStatement{effect:st.effect,principal:st.principal.clone(),actions:Vec::new(),not_actions:Vec::new(),resources:Vec::new(),not_resources:Vec::new(),conditions:crate::conddata::matching_view(&st.conditions)}` | `management::tag_and_full_evaluation_agree` |
| `manage::is_valid` | `Ok(())` | `management::management_agrees` |
| `manage::validate` | `Ok(())` | `management::management_agrees` |
| `manage::bucket_is_valid` | `Ok(())` | `management::tag_and_full_evaluation_agree` |
| `manage::overwritten` | `false` | `management::tag_and_full_evaluation_agree` |
| `manage::condition_uses_tag` | `false` | `management::tag_and_full_evaluation_agree` |
| `manage::list_uses_tag` | `false` | `management::tag_and_full_evaluation_agree` |
| `manage::functions_use_existing_object_tag` | `false` | `management::tag_and_full_evaluation_agree` |
| `manage::policy_uses_existing_object_tag_conditions` | `false` | `management::tag_and_full_evaluation_agree` |
| `manage::bucket_policy_uses_existing_object_tag_conditions` | `false` | `management::tag_and_full_evaluation_agree` |
| `manage::policy_needs_existing_object_tag_for_args` | `false` | `management::tag_and_full_evaluation_agree` |
| `manage::bucket_policy_needs_existing_object_tag_for_args` | `false` | `management::tag_and_full_evaluation_agree` |
| `manage::statement_is_allowed` | `false` | `management::tag_and_full_evaluation_agree` |
| `manage::bp_statement_is_allowed` | `false` | `management::tag_and_full_evaluation_agree` |
| `manage::policy_is_allowed` | `false` | `management::tag_and_full_evaluation_agree` |
| `manage::denies_clear` | `false` | `management::tag_and_full_evaluation_agree` |
| `manage::allows_match` | `false` | `management::tag_and_full_evaluation_agree` |
| `manage::bucket_policy_is_allowed` | `false` | `management::tag_and_full_evaluation_agree` |
| `manage::bucket_denies_clear` | `false` | `management::tag_and_full_evaluation_agree` |
| `manage::bucket_allows_match` | `false` | `management::tag_and_full_evaluation_agree` |

All four principal, buffer and wildcard functions were individually mutated and caught.

| Function | Mutation | Test |
|---|---|---|
| `extras::principal_values_into_set` | `Vec::new()` | `extras::extras_agree` |
| `extras::unique_values` | `Vec::new()` | `extras::extras_agree` |
| `extras::lazybuf_new` | `LazyBuf{source,buffer:None,written:1}` | `extras::extras_agree` |
| `extras::is_match_as_pattern_prefix` | `false` | `extras::extras_agree` |

All four explicit-time and default document functions were individually mutated and caught.

| Function | Mutation | Test |
|---|---|---|
| `docdata::new_at` | `PolicyDoc{version:0,policy,create_date:Some(at),update_date:Some(at)}` | `documents::documents_agree` |
| `docdata::update_at` | `{}` | `documents::documents_agree` |
| `docdata::default_policy` | `PolicyDoc{version:0,policy,create_date:None,update_date:None}` | `documents::documents_agree` |
| `docdata::default_doc` | `PolicyDoc{version:1,policy:Policy{id:Vec::new(),version:Vec::new(),statements:Vec::new()},create_date:None,update_date:None}` | `documents::documents_agree` |

All sixteen general variable-context functions were individually mutated and caught.

| Function | Mutation | Test |
|---|---|---|
| `varctx::clone_option` | `None` | `variable_context::context_agrees` |
| `varctx::scalar_string` | `None` | `variable_context::context_agrees` |
| `varctx::get_claim_as_strings` | `None` | `variable_context::context_agrees` |
| `varctx::resolve_username` | `None` | `variable_context::context_agrees` |
| `varctx::resolve_userid` | `None` | `variable_context::context_agrees` |
| `varctx::resolve_account_id` | `None` | `variable_context::context_agrees` |
| `varctx::resolve_region` | `None` | `variable_context::context_agrees` |
| `varctx::resolve_source_ip` | `None` | `variable_context::context_agrees` |
| `varctx::resolve_custom_variable` | `None` | `variable_context::context_agrees` |
| `varctx::resolve` | `None` | `variable_context::context_agrees` |
| `varctx::resolve_multiple` | `None` | `variable_context::context_agrees` |
| `varctx::resolve_principal_type` | `Vec::new()` | `variable_context::context_agrees` |
| `varctx::resolve_secure_transport` | `Vec::new()` | `variable_context::context_agrees` |
| `varctx::is_dynamic` | `false` | `variable_context::context_agrees` |
| `varctx::context_new` | `VariableContext{is_https:true,source_ip:None,account_id:None,region:None,username:None,claims:None,conditions:Vec::new(),custom_variables:Vec::new()}` | `variable_context::context_agrees` |
| `varctx::resolver_new` | `let mut c=context;c.username=None;VariableResolver{context:c}` | `variable_context::context_agrees` |

After the extraction rewrite, claim coercion and its new array helper were individually mutated and caught again.

| Function | Mutation | Test |
|---|---|---|
| `varctx::get_claim_as_strings` | `None` | `variable_context::context_agrees` |
| `varctx::array_strings` | `Vec::new()` | `variable_context::context_agrees` |

Final audit: all 236 new handwritten kernel functions have an individual mutation
that compiled and failed a differential test. No function was missing from the
mutation failure logs.
- awsvars::pass_from scanning from 0 instead of `Pending::resume`: resolver_backport cycle tests do not terminate.
