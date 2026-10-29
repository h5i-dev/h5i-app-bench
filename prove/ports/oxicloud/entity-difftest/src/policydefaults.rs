//! Compare ordered default-key validation with the pinned private method.
use oxicloud_kernel::{policydefaults as port, model::DriveKind};
use oxicloud::domain::entities::drive as upstream;
use crate::tests::Rng;
mod oracle { include!(concat!(env!("CARGO_MANIFEST_DIR"), "/reference/defaults_oracle.rs")); }
fn compare(bag: serde_json::Value) {
    let keys: Vec<Vec<u8>> = bag.as_object().map(|o|o.keys().map(|k|k.as_bytes().to_vec()).collect()).unwrap_or_default();
    for (kind,original) in [(DriveKind::Personal,upstream::DriveKind::Personal),(DriveKind::Shared,upstream::DriveKind::Shared)] {
        let result=port::validate(kind,bag.is_object(),&keys);
        let expected=oracle::validate(original,&bag);
        let message=match result {
            port::Validation::Valid=>None,
            port::Validation::NotObject=>Some("policies must be a JSON object".to_owned()),
            port::Validation::Rejected(index,reason)=>{
                let key=std::str::from_utf8(&keys[index]).unwrap();
                Some(match reason {
                    port::KeyRejection::NotDefaultable=>format!("`{key}` cannot be a default: it is an operational state, set per drive"),
                    port::KeyRejection::Unknown=>format!("unknown policy `{key}`"),
                    port::KeyRejection::NotApplicable=>format!("`{key}` does not apply to {} drives",original.as_str()),
                })
            }
        };
        match expected {
            Ok(())=>assert!(message.is_none()),
            Err(e)=>{assert!(matches!(e.kind,oxicloud::common::errors::ErrorKind::InvalidInput));assert_eq!(message,Some(e.message));}
        }
    }
}
#[test]
fn policy_defaults_validation_differential() {
    use serde_json::{Value,Map};
    for v in [Value::Null,Value::Bool(true),Value::from(42),Value::from("object"),Value::Array(vec![])] {compare(v);}
    compare(Value::Object(Map::new()));
    let mut names=upstream::POLICY_KNOBS.to_vec();
    names.extend(["", "READ_ONLY", "read_only\0", "forbid_owner_role_change ","unknown", "未知"]);
    let mut rng=Rng(0xb83a_4821_aaca_9843);
    for _ in 0..20_000 {
        let mut bag=Map::new();
        for name in &names {
            if rng.chance(30) {
                let value=match rng.next()%6 {0=>Value::Null,1=>Value::Bool(rng.chance(50)),2=>Value::from(rng.next()),3=>Value::from("arbitrary"),4=>Value::Array(vec![]),_=>Value::Object(Map::new())};
                bag.insert((*name).into(),value);
            }
        }
        compare(Value::Object(bag));
    }
    for name in names {let mut bag=Map::new();bag.insert(name.into(),Value::Null);compare(Value::Object(bag));}
}
