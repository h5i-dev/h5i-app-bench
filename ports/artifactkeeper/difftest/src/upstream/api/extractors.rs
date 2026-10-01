//! Stub: the external base URL the OCI challenge names.
pub fn request_base_url_from_request(_headers: &axum::http::HeaderMap, _uri: Option<&axum::http::Uri>) -> String {
    "http://registry.test".to_string()
}
