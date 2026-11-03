//! Exhaustive finite enum decisions; see DEVIATIONS.md.
pub mod index_type_edc7b397 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum IndexType {Equality,Presence,SubString,Ordering}
impl IndexType {
    pub fn as_idx_str(&self) -> Vec<u8> {
        match self {
            IndexType::Equality => Vec::from([101u8, 113u8]),
            IndexType::Presence => Vec::from([112u8, 114u8, 101u8, 115u8]),
            IndexType::SubString => Vec::from([115u8, 117u8, 98u8]),
            IndexType::Ordering => Vec::from([111u8, 114u8, 100u8]),
        }
    }
}
}
pub mod oauth_claim_map_join_edc7b397 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum OauthClaimMapJoin {CommaSeparatedValue,SpaceSeparatedValue,JsonArray}
impl OauthClaimMapJoin {
    pub fn to_str(self) -> Vec<u8> {
        match self {
            OauthClaimMapJoin::CommaSeparatedValue => Vec::from([44u8]),
            OauthClaimMapJoin::SpaceSeparatedValue => Vec::from([32u8]),
            
            OauthClaimMapJoin::JsonArray => Vec::from([59u8]),
        }
    }
}
}
