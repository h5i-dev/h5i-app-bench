// Copied from Bootstrap-Academy/backend @ fbe5e60 by extract_upstream.py. Do not edit.
#[allow(unused_imports)]
use crate::upstream::academy_models;
use chrono::{DateTime, Utc};

pub trait TimeService: Send + Sync + 'static {
    /// Return the current time.
    fn now(&self) -> DateTime<Utc>;
}
