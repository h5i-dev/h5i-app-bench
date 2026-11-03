#![allow(dead_code)]
trait Wire { fn wire(&self) -> String; }
macro_rules! scalar { ($($t:ty),*) => {$(impl Wire for $t {fn wire(&self)->String{self.to_string()}})*}; }
scalar!(bool,u8,u16,u32,u64,usize);
impl Wire for String { fn wire(&self)->String {format!("{:?}",self.as_bytes())} }
impl<T:Wire> Wire for Vec<T> { fn wire(&self)->String {format!("[{}]",self.iter().map(Wire::wire).collect::<Vec<_>>().join(","))} }
impl<T:Wire> Wire for Option<T> {fn wire(&self)->String {match self {None=>"null".into(),Some(x)=>x.wire()}}}
mod signing_config_default_942b3541 {
use super::Wire;
pub struct SigningConfig{pub enabled:bool,pub key_path:String}
impl Default for SigningConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            key_path: String::new(),
        }
    }
}
pub fn emit() {let x = SigningConfig::default();
println!("signing_config_default_942b3541.enabled\t{}",x.enabled.wire());
println!("signing_config_default_942b3541.key_path\t{}",x.key_path.wire());
}
}
mod env_provider_new_23e18cff {
use super::Wire;
pub struct EnvProvider{pub clear_after_read:bool}
impl EnvProvider {
    /// Create a new environment provider
    pub fn new() -> Self {
        Self {
            clear_after_read: false,
        }
    }
}
pub fn emit() {let x = EnvProvider::new();
println!("env_provider_new_23e18cff.clear_after_read\t{}",x.clear_after_read.wire());
}
}
fn main(){signing_config_default_942b3541::emit();env_provider_new_23e18cff::emit();}
