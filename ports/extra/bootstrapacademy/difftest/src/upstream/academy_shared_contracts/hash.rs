// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::fmt::Debug;

use crate::upstream::academy_models::Sha256Hash;

pub trait HashService: Send + Sync + 'static {
    /// Compute the SHA-256 hash of the given data.
    fn sha256<T: AsRef<[u8]> + Debug + 'static>(&self, data: &T) -> Sha256Hash;
}
