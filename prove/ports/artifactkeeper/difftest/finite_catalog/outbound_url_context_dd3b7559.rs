#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum OutboundUrlContext {Upstream,Webhook,SsoDiscovery,TrustedInternal}
impl OutboundUrlContext {
    /// Name of the env var that, when set to a truthy value, exempts
    /// RFC1918 / IPv6 unique-local addresses for this context.
    fn env_var(self) -> &'static str {
        match self {
            OutboundUrlContext::Upstream => "UPSTREAM_ALLOW_PRIVATE_IPS",
            OutboundUrlContext::Webhook => "WEBHOOK_ALLOW_PRIVATE_IPS",
            OutboundUrlContext::SsoDiscovery => "SSO_ALLOW_PRIVATE_IPS",
            // TrustedInternal permits private addresses via the
            // `private_ip_allowed` short-circuit, so this env var is never
            // consulted. Name an undefined var so that even a hypothetical
            // future caller reaching this arm falls through to "blocked"
            // (fail-closed) rather than panicking.
            OutboundUrlContext::TrustedInternal => "AK_TRUSTED_INTERNAL_ALLOW_PRIVATE_IPS",
        }
    }
}
fn main(){
println!("env_var/Upstream\t{:?}",OutboundUrlContext::Upstream.env_var().as_bytes());
println!("env_var/Webhook\t{:?}",OutboundUrlContext::Webhook.env_var().as_bytes());
println!("env_var/SsoDiscovery\t{:?}",OutboundUrlContext::SsoDiscovery.env_var().as_bytes());
println!("env_var/TrustedInternal\t{:?}",OutboundUrlContext::TrustedInternal.env_var().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(OutboundUrlContext::Upstream.env_var().as_bytes(),artifactkeeper_kernel::finite_catalog::outbound_url_context_dd3b7559::OutboundUrlContext::Upstream.env_var(),"outbound_url_context_dd3b7559/env_var/Upstream");
assert_eq!(OutboundUrlContext::Webhook.env_var().as_bytes(),artifactkeeper_kernel::finite_catalog::outbound_url_context_dd3b7559::OutboundUrlContext::Webhook.env_var(),"outbound_url_context_dd3b7559/env_var/Webhook");
assert_eq!(OutboundUrlContext::SsoDiscovery.env_var().as_bytes(),artifactkeeper_kernel::finite_catalog::outbound_url_context_dd3b7559::OutboundUrlContext::SsoDiscovery.env_var(),"outbound_url_context_dd3b7559/env_var/SsoDiscovery");
assert_eq!(OutboundUrlContext::TrustedInternal.env_var().as_bytes(),artifactkeeper_kernel::finite_catalog::outbound_url_context_dd3b7559::OutboundUrlContext::TrustedInternal.env_var(),"outbound_url_context_dd3b7559/env_var/TrustedInternal");
}
