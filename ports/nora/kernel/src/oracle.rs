//! Cryptography and decoding the kernel does not compute. Each is an oracle
//! table filled by the shell from the real functions; the theorems hold for
//! every table.

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Crypto {
    /// `sha256_hex(input)`, lowercase hex.
    pub sha256: Vec<(Vec<u8>, Vec<u8>)>,
    /// `(token, hash)` pairs for which Argon2 verification succeeds.
    pub argon2_ok: Vec<(Vec<u8>, Vec<u8>)>,
    /// `(password, hash)` pairs for which bcrypt verification succeeds.
    pub bcrypt_ok: Vec<(Vec<u8>, Vec<u8>)>,
    /// `STANDARD.decode(input)`, `None` on a decoding error.
    pub base64: Vec<(Vec<u8>, Option<Vec<u8>>)>,
    /// `String::from_utf8(bytes).is_ok()`.
    pub utf8_ok: Vec<Vec<u8>>,
}

pub fn bytes_eq(a: &[u8], b: &[u8]) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut i = 0;
    while i < a.len() {
        if a[i] != b[i] {
            return false;
        }
        i += 1;
    }
    true
}

fn has_pair(t: &[(Vec<u8>, Vec<u8>)], a: &[u8], b: &[u8]) -> bool {
    let mut i = 0;
    while i < t.len() {
        if bytes_eq(&t[i].0, a) && bytes_eq(&t[i].1, b) {
            return true;
        }
        i += 1;
    }
    false
}

impl Crypto {
    pub fn sha256_hex(&self, input: &[u8]) -> Vec<u8> {
        let mut i = 0;
        while i < self.sha256.len() {
            if bytes_eq(&self.sha256[i].0, input) {
                return self.sha256[i].1.clone();
            }
            i += 1;
        }
        Vec::new()
    }

    pub fn argon2_verify(&self, token: &[u8], hash: &[u8]) -> bool {
        has_pair(&self.argon2_ok, token, hash)
    }

    pub fn bcrypt_verify(&self, password: &[u8], hash: &[u8]) -> bool {
        has_pair(&self.bcrypt_ok, password, hash)
    }

    pub fn base64_decode(&self, input: &[u8]) -> Option<Vec<u8>> {
        let mut i = 0;
        while i < self.base64.len() {
            if bytes_eq(&self.base64[i].0, input) {
                return match &self.base64[i].1 {
                    Some(d) => Some(d.clone()),
                    None => None,
                };
            }
            i += 1;
        }
        None
    }

    pub fn is_utf8(&self, bytes: &[u8]) -> bool {
        let mut i = 0;
        while i < self.utf8_ok.len() {
            if bytes_eq(&self.utf8_ok[i], bytes) {
                return true;
            }
            i += 1;
        }
        false
    }
}
