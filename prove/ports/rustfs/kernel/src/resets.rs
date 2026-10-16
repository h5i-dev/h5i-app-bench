//! ResourceSet conveniences from `policy/resource.rs`.
use crate::{rsrc::{Resource, resource_is_match, set_is_match}, condfuncs::CondValues};
/// `ResourceSet` keeps its list representation.
pub type ResourceSet = Vec<Resource>;
/// `ResourceSet::is_empty`.
pub fn is_empty(set: &[Resource]) -> bool { set.len() == 0 }
/// `ResourceSet::deref`.
pub fn as_slice(set: &[Resource]) -> &[Resource] { set }
/// List membership, shared by unique insertion and set equality.
pub fn member(set: &[Resource], resource: &Resource) -> bool {
    let mut i = 0;
    while i < set.len() { if set[i] == *resource { return true; } i += 1; }
    false
}
/// `ResourceSet::push_unique`.
pub fn push_unique(set: &mut Vec<Resource>, resource: Resource) {
    if !member(set, &resource) { set.push(resource); }
}
fn covers(left: &[Resource], right: &[Resource]) -> bool {
    let mut i = 0;
    while i < left.len() { if !member(right, &left[i]) { return false; } i += 1; }
    true
}
/// `ResourceSet::eq`: order and multiplicity do not affect equality.
pub fn eq(left: &[Resource], right: &[Resource]) -> bool { covers(left, right) && covers(right, left) }
/// `Resource::is_match`.
pub fn is_match(resource: &Resource, name: &[u8], values: &CondValues) -> bool {
    resource_is_match(resource, name, values, &None)
}
/// `ResourceSet::is_match`.
pub fn set_matches(set: &[Resource], name: &[u8], values: &CondValues) -> bool {
    set_is_match(set, name, values, &None)
}
/// `Resource::match_resource`.
pub fn match_resource(resource: &Resource, name: &[u8]) -> bool { is_match(resource, name, &Vec::new()) }
/// `ResourceSet::match_resource`.
pub fn set_match_resource(set: &[Resource], name: &[u8]) -> bool {
    let mut i = 0;
    while i < set.len() { if match_resource(&set[i], name) { return true; } i += 1; }
    false
}
