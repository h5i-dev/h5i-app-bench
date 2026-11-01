#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum OauthClaimMapJoin {CommaSeparatedValue,SpaceSeparatedValue,JsonArray}
impl OauthClaimMapJoin {
    pub(crate) fn to_str(self) -> &'static str {
        match self {
            OauthClaimMapJoin::CommaSeparatedValue => ",",
            OauthClaimMapJoin::SpaceSeparatedValue => " ",
            // Should this be something else?
            OauthClaimMapJoin::JsonArray => ";",
        }
    }
}
fn main(){
println!("to_str/CommaSeparatedValue\t{:?}",OauthClaimMapJoin::CommaSeparatedValue.to_str().as_bytes());
println!("to_str/SpaceSeparatedValue\t{:?}",OauthClaimMapJoin::SpaceSeparatedValue.to_str().as_bytes());
println!("to_str/JsonArray\t{:?}",OauthClaimMapJoin::JsonArray.to_str().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(OauthClaimMapJoin::CommaSeparatedValue.to_str().as_bytes(),kanidm_kernel::finite_catalog::oauth_claim_map_join_edc7b397::OauthClaimMapJoin::CommaSeparatedValue.to_str(),"oauth_claim_map_join_edc7b397/to_str/CommaSeparatedValue");
assert_eq!(OauthClaimMapJoin::SpaceSeparatedValue.to_str().as_bytes(),kanidm_kernel::finite_catalog::oauth_claim_map_join_edc7b397::OauthClaimMapJoin::SpaceSeparatedValue.to_str(),"oauth_claim_map_join_edc7b397/to_str/SpaceSeparatedValue");
assert_eq!(OauthClaimMapJoin::JsonArray.to_str().as_bytes(),kanidm_kernel::finite_catalog::oauth_claim_map_join_edc7b397::OauthClaimMapJoin::JsonArray.to_str(),"oauth_claim_map_join_edc7b397/to_str/JsonArray");
}
