//! Runs the kernel and Bootstrap Academy's own services on the same random
//! requests.
pub mod upstream;

#[cfg(test)]
mod mem;
#[cfg(test)]
mod tests;
#[cfg(test)]
mod props;
