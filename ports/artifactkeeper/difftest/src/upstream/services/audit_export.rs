pub mod details {
    /// Stub of the audit detail payload.
    pub struct AuthDetails {
        pub path: String,
        pub method: String,
        pub reason: String,
    }

    impl AuthDetails {
        pub fn permission_denied(path: &str, method: &str, reason: &str) -> Self {
            AuthDetails { path: path.to_string(), method: method.to_string(), reason: reason.to_string() }
        }
    }
}
