//! Stub of the audit log: `audit_fire_and_forget` records the entry with the
//! test's backend.
use uuid::Uuid;

use super::audit_export::details::AuthDetails;

pub enum AuditAction {
    PermissionDenied,
}

pub enum ResourceType {
    User,
}

pub struct AuditEntry {
    pub user: Option<Uuid>,
    pub details: Option<AuthDetails>,
}

impl AuditEntry {
    pub fn new(_action: AuditAction, _resource_type: ResourceType) -> Self {
        AuditEntry { user: None, details: None }
    }
    pub fn user(mut self, id: Uuid) -> Self {
        self.user = Some(id);
        self
    }
    pub fn resource(self, _id: Uuid) -> Self {
        self
    }
    pub fn actor_name(self, _name: String) -> Self {
        self
    }
    pub fn details_typed(mut self, d: AuthDetails) -> Self {
        self.details = Some(d);
        self
    }
}

pub async fn audit_fire_and_forget(db: sqlx::PgPool, entry: AuditEntry) {
    let d = entry.details.expect("details");
    db.backend.log("audit_permission_denied", vec![
        sqlx::Value::Uuid(entry.user.expect("user")),
        sqlx::Value::Text(d.path),
        sqlx::Value::Text(d.method),
    ]);
}
