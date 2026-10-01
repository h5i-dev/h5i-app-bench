//! Runs the kernel and artifact-keeper's own code on the same random inputs.
pub mod upstream;
// The copied code names its modules from the crate root (`crate::api::...`).
pub use upstream::{api, config, error, models, services, util};

#[cfg(test)]
mod gen;
#[cfg(test)]
mod shell;
#[cfg(test)]
mod tests;
#[cfg(test)]
mod props;
