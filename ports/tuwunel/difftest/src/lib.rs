//! Differential test of the tuwunel kernel against the copied upstream code
//! (upstream/), and falsification tests for the Lean statements.
pub mod world;
pub mod generate;

#[cfg(test)]
mod tests;
#[cfg(test)]
mod props;
