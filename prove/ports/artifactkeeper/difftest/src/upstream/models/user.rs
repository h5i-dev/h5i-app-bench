use uuid::Uuid;

/// `models/user.rs` `User`, the fields the copied code reads.
#[derive(Debug, Clone)]
pub struct User {
    pub id: Uuid,
    pub username: String,
    pub email: String,
    pub is_active: bool,
    pub is_admin: bool,
    pub is_service_account: bool,
    pub must_change_password: bool,
}

impl sqlx::FromRow for User {
    fn from_row(r: &sqlx::PgRow) -> sqlx::Result<Self> {
        use sqlx::Row;
        Ok(User {
            id: r.try_get("id")?,
            username: r.try_get("username")?,
            email: r.try_get("email")?,
            is_active: r.try_get("is_active")?,
            is_admin: r.try_get("is_admin")?,
            is_service_account: r.try_get("is_service_account")?,
            must_change_password: r.try_get("must_change_password")?,
        })
    }
}
