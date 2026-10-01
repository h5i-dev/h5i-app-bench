// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use std::fmt::Debug;

use crate::upstream::uuid::Uuid;

pub trait IdService: Send + Sync + 'static {
    /// Generate a new unique ID.
    fn generate<I: From<Uuid> + Debug + 'static>(&self) -> I;
}
