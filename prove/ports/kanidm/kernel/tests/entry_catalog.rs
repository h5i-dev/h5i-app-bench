#[path = "../../difftest/entry_catalog/reference.rs"]
mod reference;
use kanidm_kernel::entry_catalog;
#[test]
fn account_records_match_every_field(){
let upstream=reference::account_records();
assert_eq!(upstream.len(),18);
for (name,expected) in upstream {
let actual=match name{
"dl11/BUILTIN_ACCOUNT_IDM_ADMIN" | "dl12/BUILTIN_ACCOUNT_IDM_ADMIN" | "dl13/BUILTIN_ACCOUNT_IDM_ADMIN" | "dl14/BUILTIN_ACCOUNT_IDM_ADMIN" | "dl15/BUILTIN_ACCOUNT_IDM_ADMIN" | "dl_1_12/BUILTIN_ACCOUNT_IDM_ADMIN"=>entry_catalog::dl11_builtin_account_idm_admin(),
"dl11/BUILTIN_ACCOUNT_ADMIN" | "dl12/BUILTIN_ACCOUNT_ADMIN" | "dl13/BUILTIN_ACCOUNT_ADMIN" | "dl14/BUILTIN_ACCOUNT_ADMIN" | "dl15/BUILTIN_ACCOUNT_ADMIN" | "dl_1_12/BUILTIN_ACCOUNT_ADMIN"=>entry_catalog::dl11_builtin_account_admin(),
"dl11/BUILTIN_ACCOUNT_ANONYMOUS_DL6" | "dl12/BUILTIN_ACCOUNT_ANONYMOUS_DL6" | "dl13/BUILTIN_ACCOUNT_ANONYMOUS_DL6" | "dl14/BUILTIN_ACCOUNT_ANONYMOUS_DL6" | "dl15/BUILTIN_ACCOUNT_ANONYMOUS_DL6" | "dl_1_12/BUILTIN_ACCOUNT_ANONYMOUS_DL6"=>entry_catalog::dl11_builtin_account_anonymous_dl6(),
_=>panic!("unexpected entry record: {name}"),
};
assert_eq!(actual,expected,"complete entry {name}");
}
println!("18 pinned Account records matched every field");
}
#[test]
fn entry_records_match_every_field(){
let upstream=reference::entry_records();
assert_eq!(upstream.len(),29);
for (name,expected) in upstream {
let actual=match name{
"dl11/E_KEY_PROVIDER_INTERNAL_DL6" | "dl12/E_KEY_PROVIDER_INTERNAL_DL6" | "dl13/E_KEY_PROVIDER_INTERNAL_DL6" | "dl14/e_key_provider_internal_dl6" | "dl15/e_key_provider_internal_dl6" | "dl_1_12/e_key_provider_internal_dl6"=>entry_catalog::dl11_e_key_provider_internal_dl6(),
"dl11/E_SYSTEM_INFO_V1" | "dl12/E_SYSTEM_INFO_V1" | "dl13/E_SYSTEM_INFO_V1" | "dl14/e_system_info_v1" | "dl15/e_system_info_v1" | "dl_1_12/e_system_info_v1"=>entry_catalog::dl11_e_system_info_v1(),
"dl11/E_DOMAIN_INFO_DL6" | "dl12/E_DOMAIN_INFO_DL6"=>entry_catalog::dl11_e_domain_info_dl6(),
"dl12/E_UUID_DOMAIN_ID_VERIFICATION_KEY_V1" | "dl13/E_UUID_DOMAIN_ID_VERIFICATION_KEY_V1" | "dl14/e_uuid_domain_id_verification_key_v1" | "dl15/e_uuid_domain_id_verification_key_v1" | "dl_1_12/e_uuid_domain_id_verification_key_v1"=>entry_catalog::dl12_e_uuid_domain_id_verification_key_v1(),
"dl12/E_HMAC_NAME_HISTORY_FEATURE" | "dl13/E_HMAC_NAME_HISTORY_FEATURE" | "dl14/e_hmac_name_history_feature" | "dl15/e_hmac_name_history_feature" | "dl_1_12/e_hmac_name_history_feature"=>entry_catalog::dl12_e_hmac_name_history_feature(),
"dl13/E_DOMAIN_INFO_DL6" | "dl14/e_domain_info_dl6" | "dl15/e_domain_info_dl6"=>entry_catalog::dl13_e_domain_info_dl6(),
"dl_1_12/e_domain_info_dl6"=>entry_catalog::dl_1_12_e_domain_info_dl6(),
"dl_1_12/e_account_signup_feature"=>entry_catalog::dl_1_12_e_account_signup_feature(),
_=>panic!("unexpected entry record: {name}"),
};
assert_eq!(actual,expected,"complete entry {name}");
}
println!("29 pinned Entry records matched every field");
}
