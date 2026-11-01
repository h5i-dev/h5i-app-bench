//! Complete closed defaults; String fields preserve their UTF-8 bytes.
pub mod signing_config_default_942b3541 {
pub struct SigningConfig{pub enabled:bool,pub key_path:Vec<u8>}
pub fn make() -> SigningConfig { SigningConfig {enabled: true,key_path: Vec::new()} }
}
pub mod env_provider_new_23e18cff {
pub struct EnvProvider{pub clear_after_read:bool}
pub fn make() -> EnvProvider { EnvProvider {clear_after_read: false} }
}
