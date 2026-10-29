use std::borrow::Cow; use http::StatusCode;
#[derive(Debug)]
pub struct AppError {
    pub status_code: StatusCode,
    pub message: String,
    pub error_type: Cow<'static, str>,
}
impl AppError {
    pub fn new(
        status_code: StatusCode,
        message: impl Into<String>,
        error_type: impl Into<Cow<'static, str>>,
    ) -> Self {
        Self {
            status_code,
            message: message.into(),
            error_type: error_type.into(),
        }
    }
}
