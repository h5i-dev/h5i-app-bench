use oxicloud::{common::errors::{DomainError,ErrorKind},domain::entities::drive::{DriveKind,POLICY_KNOBS,NON_DEFAULTABLE_KNOBS,knob_applies_to_kind}}; struct Oracle; impl Oracle {    fn validate(&self, kind: DriveKind, bag: &serde_json::Value) -> Result<(), DomainError> {
        let obj = bag.as_object().ok_or_else(|| {
            DomainError::new(
                ErrorKind::InvalidInput,
                "DrivePolicyDefaults",
                "policies must be a JSON object",
            )
        })?;

        for key in obj.keys() {
            if NON_DEFAULTABLE_KNOBS.contains(&key.as_str()) {
                return Err(DomainError::new(
                    ErrorKind::InvalidInput,
                    "DrivePolicyDefaults",
                    format!(
                        "`{key}` cannot be a default: it is an operational state, set per drive"
                    ),
                ));
            }
            if !POLICY_KNOBS.contains(&key.as_str()) {
                return Err(DomainError::new(
                    ErrorKind::InvalidInput,
                    "DrivePolicyDefaults",
                    format!("unknown policy `{key}`"),
                ));
            }
            if !knob_applies_to_kind(key, kind) {
                return Err(DomainError::new(
                    ErrorKind::InvalidInput,
                    "DrivePolicyDefaults",
                    format!("`{key}` does not apply to {} drives", kind.as_str()),
                ));
            }
        }
        Ok(())
    }}
pub fn validate(kind:DriveKind,bag:&serde_json::Value)->Result<(),DomainError>{Oracle.validate(kind,bag)}
