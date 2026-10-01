// Copied from artifact-keeper/artifact-keeper @ 7c42891 by extract_upstream.py. Do not edit.
use sqlx::PgPool;
use uuid::Uuid;

use crate::error::{AppError, Result};

pub struct AuthConfigService;

impl AuthConfigService {
    /// Validate and consume a download ticket (single-use).
    /// Returns (user_id, purpose, resource_path) if valid.
    pub async fn validate_download_ticket(
        pool: &PgPool,
        ticket: &str,
    ) -> Result<(Uuid, String, Option<String>)> {
        let row: (Uuid, String, Option<String>) = sqlx::query_as(
            r#"DELETE FROM download_tickets
               WHERE ticket = $1 AND expires_at > NOW()
               RETURNING user_id, purpose, resource_path"#,
        )
        .bind(ticket)
        .fetch_optional(pool)
        .await
        .map_err(|e| AppError::Database(e.to_string()))?
        .ok_or_else(|| AppError::Authentication("Invalid or expired download ticket".into()))?;

        Ok(row)
    }
}
