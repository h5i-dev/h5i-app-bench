#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum EgressProxyMode {Inherit,Direct,Explicit}
impl EgressProxyMode {
    /// Stable wire/storage token for this mode.
    pub fn as_str(self) -> &'static str {
        match self {
            EgressProxyMode::Inherit => "inherit",
            EgressProxyMode::Direct => "direct",
            EgressProxyMode::Explicit => "explicit",
        }
    }
}
fn main(){
println!("as_str/Inherit\t{:?}",EgressProxyMode::Inherit.as_str().as_bytes());
println!("as_str/Direct\t{:?}",EgressProxyMode::Direct.as_str().as_bytes());
println!("as_str/Explicit\t{:?}",EgressProxyMode::Explicit.as_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(EgressProxyMode::Inherit.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::egress_proxy_mode_2d09e195::EgressProxyMode::Inherit.as_str(),"egress_proxy_mode_2d09e195/as_str/Inherit");
assert_eq!(EgressProxyMode::Direct.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::egress_proxy_mode_2d09e195::EgressProxyMode::Direct.as_str(),"egress_proxy_mode_2d09e195/as_str/Direct");
assert_eq!(EgressProxyMode::Explicit.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::egress_proxy_mode_2d09e195::EgressProxyMode::Explicit.as_str(),"egress_proxy_mode_2d09e195/as_str/Explicit");
}
