/// `models/repository.rs` `RepositoryVisibility`, without its serde and
/// sqlx derives.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum RepositoryVisibility {
    Public,
    Internal,
    Private,
}

include!("repository_copied.rs");

impl sqlx::Decode for RepositoryVisibility {
    fn decode(v: &sqlx::Value) -> sqlx::Result<Self> {
        match v {
            sqlx::Value::Text(s) => {
                Self::from_db_str(s).ok_or_else(|| sqlx::Error::Decode(format!("visibility {s}")))
            }
            _ => Err(sqlx::Error::Decode("visibility".into())),
        }
    }
}
