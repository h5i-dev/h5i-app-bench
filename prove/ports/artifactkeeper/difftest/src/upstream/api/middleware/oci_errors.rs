use axum::http::StatusCode;
use axum::response::Response;

include!("oci_errors_copied.rs");

/// Stub: the distribution-spec 401. The kernel only records that this shape
/// was chosen, so the test marks it with a header.
pub(crate) fn oci_unauthorized_response(base_url: &str) -> Response {
    Response::builder()
        .status(StatusCode::UNAUTHORIZED)
        .header("x-stub", "oci-unauthorized")
        .body(axum::body::Body::from(base_url.to_string()))
        .unwrap()
}
