#[path="../../../kernel/src/closed_records.rs"]
mod kernel;
#[test]
fn plugin_resource_limits_default_a005c35c_complete() {let r=kernel::plugin_resource_limits_default_a005c35c::make();
assert_eq!(r.memory_mb,64);
assert_eq!(r.timeout_secs,5);
assert_eq!(r.fuel,500000000);
}
#[test]
fn plugin_capabilities_default_a005c35c_complete() {let r=kernel::plugin_capabilities_default_a005c35c::make();
assert_eq!(r.parse_metadata,true);
assert_eq!(r.generate_index,false);
assert_eq!(r.validate_artifact,true);
assert_eq!(r.handle_request,false);
}
#[test]
fn capabilities_config_default_75c080e9_complete() {let r=kernel::capabilities_config_default_75c080e9::make();
assert_eq!(r.parse_metadata,true);
assert_eq!(r.generate_index,false);
assert_eq!(r.validate_artifact,true);
assert_eq!(r.handle_request,false);
}
#[test]
fn telemetry_settings_default_453927f4_complete() {let r=kernel::telemetry_settings_default_453927f4::make();
assert_eq!(r.enabled,false);
assert_eq!(r.review_before_send,true);
assert_eq!(r.scrub_level,&[115u8,116u8,97u8,110u8,100u8,97u8,114u8,100u8]);
assert_eq!(r.include_logs,false);
}
#[test]
fn password_policy_config_default_97110402_complete() {let r=kernel::password_policy_config_default_97110402::make();
assert_eq!(r.min_length,8);
assert_eq!(r.max_length,128);
assert_eq!(r.require_uppercase,false);
assert_eq!(r.require_lowercase,false);
assert_eq!(r.require_digit,false);
assert_eq!(r.require_special,false);
assert_eq!(r.min_strength,0);
}
