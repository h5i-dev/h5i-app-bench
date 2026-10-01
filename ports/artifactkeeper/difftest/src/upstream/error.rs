//! `error.rs` `AppError`, the variants the copied code builds or matches.
#[derive(Debug)]
pub enum AppError {
    Config(String),
    Database(String),
    Sqlx(sqlx::Error),
    Authentication(String),
    Unauthorized(String),
    Authorization(String),
    NotFound(String),
    Conflict(String),
    Validation(String),
    ServiceUnavailable(String),
    Internal(String),
}

pub type Result<T> = std::result::Result<T, AppError>;

include!("error_copied.rs");
