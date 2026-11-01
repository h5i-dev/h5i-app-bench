//! Complete closed defaults; String fields preserve their UTF-8 bytes.
pub mod plugin_resource_limits_default_a005c35c {
pub struct PluginResourceLimits{pub memory_mb:u32,pub timeout_secs:u32,pub fuel:u64}
pub fn make() -> PluginResourceLimits { PluginResourceLimits {memory_mb: 64,timeout_secs: 5,fuel: 500_000_000} }
}
pub mod plugin_capabilities_default_a005c35c {
pub struct PluginCapabilities{pub parse_metadata:bool,pub generate_index:bool,pub validate_artifact:bool,pub handle_request:bool}
pub fn make() -> PluginCapabilities { PluginCapabilities {parse_metadata: true,generate_index: false,validate_artifact: true,handle_request: false} }
}
pub mod capabilities_config_default_75c080e9 {
pub struct CapabilitiesConfig{pub parse_metadata:bool,pub generate_index:bool,pub validate_artifact:bool,pub handle_request:bool}
pub fn make() -> CapabilitiesConfig { CapabilitiesConfig {parse_metadata: true,generate_index: false,validate_artifact: true,handle_request: false} }
}
pub mod telemetry_settings_default_453927f4 {
pub struct TelemetrySettings{pub enabled:bool,pub review_before_send:bool,pub scrub_level:Vec<u8>,pub include_logs:bool}
pub fn make() -> TelemetrySettings { TelemetrySettings {enabled: false,review_before_send: true,scrub_level: b"standard".to_vec(),include_logs: false} }
}
pub mod password_policy_config_default_97110402 {
pub struct PasswordPolicyConfig{pub min_length:usize,pub max_length:usize,pub require_uppercase:bool,pub require_lowercase:bool,pub require_digit:bool,pub require_special:bool,pub min_strength:u8}
pub fn make() -> PasswordPolicyConfig { PasswordPolicyConfig {min_length: 8,max_length: 128,require_uppercase: false,require_lowercase: false,require_digit: false,require_special: false,min_strength: 0} }
}
