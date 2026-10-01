// Copied from getnora-io/nora @ f864a9a by extract_upstream.py. Do not edit.
// Copyright (c) 2026 The NORA Authors
// SPDX-License-Identifier: MIT

use std::collections::HashMap;
use std::path::Path;

/// Htpasswd-based authentication
#[derive(Clone)]
pub struct HtpasswdAuth {
    users: HashMap<String, String>, // username -> bcrypt hash
}

impl HtpasswdAuth {
    /// Load users from htpasswd file
    pub fn from_file(path: &Path) -> Option<Self> {
        let content = std::fs::read_to_string(path).ok()?;
        let mut users = HashMap::new();

        for line in content.lines() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') {
                continue;
            }
            if let Some((username, hash)) = line.split_once(':') {
                users.insert(username.to_string(), hash.to_string());
            }
        }

        if users.is_empty() {
            None
        } else {
            Some(Self { users })
        }
    }

    /// Verify username and password
    pub fn authenticate(&self, username: &str, password: &str) -> bool {
        if let Some(hash) = self.users.get(username) {
            bcrypt::verify(password, hash).unwrap_or(false)
        } else {
            false
        }
    }

    /// Get list of usernames
    pub fn list_users(&self) -> Vec<&str> {
        self.users.keys().map(|s| s.as_str()).collect()
    }
}

