#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum CachedObjectVerdict {NotProxyCache,Vouched,Unvouched,Held}
impl CachedObjectVerdict {
    fn may_serve_stored_object(self) -> bool {
        matches!(self, Self::NotProxyCache | Self::Vouched)
    }
}
fn main(){
println!("may_serve_stored_object/NotProxyCache\t{:?}",CachedObjectVerdict::NotProxyCache.may_serve_stored_object());
println!("may_serve_stored_object/Vouched\t{:?}",CachedObjectVerdict::Vouched.may_serve_stored_object());
println!("may_serve_stored_object/Unvouched\t{:?}",CachedObjectVerdict::Unvouched.may_serve_stored_object());
println!("may_serve_stored_object/Held\t{:?}",CachedObjectVerdict::Held.may_serve_stored_object());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(CachedObjectVerdict::NotProxyCache.may_serve_stored_object(),artifactkeeper_kernel::finite_catalog::cached_object_verdict_b87a78e2::CachedObjectVerdict::NotProxyCache.may_serve_stored_object(),"cached_object_verdict_b87a78e2/may_serve_stored_object/NotProxyCache");
assert_eq!(CachedObjectVerdict::Vouched.may_serve_stored_object(),artifactkeeper_kernel::finite_catalog::cached_object_verdict_b87a78e2::CachedObjectVerdict::Vouched.may_serve_stored_object(),"cached_object_verdict_b87a78e2/may_serve_stored_object/Vouched");
assert_eq!(CachedObjectVerdict::Unvouched.may_serve_stored_object(),artifactkeeper_kernel::finite_catalog::cached_object_verdict_b87a78e2::CachedObjectVerdict::Unvouched.may_serve_stored_object(),"cached_object_verdict_b87a78e2/may_serve_stored_object/Unvouched");
assert_eq!(CachedObjectVerdict::Held.may_serve_stored_object(),artifactkeeper_kernel::finite_catalog::cached_object_verdict_b87a78e2::CachedObjectVerdict::Held.may_serve_stored_object(),"cached_object_verdict_b87a78e2/may_serve_stored_object/Held");
}
