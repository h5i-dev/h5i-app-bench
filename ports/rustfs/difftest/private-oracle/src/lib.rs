#![allow(dead_code, unexpected_cfgs)]
include!(concat!(env!("OUT_DIR"), "/oracle.rs"));
pub use time;
pub use base64_simd;
pub use serde;
