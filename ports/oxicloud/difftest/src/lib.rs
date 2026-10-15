//! Runs the kernel and OxiCloud on the same tables.
pub mod tests;
#[cfg(test)]
mod endpoints;
#[cfg(test)]
mod props;
#[cfg(test)]
mod userrole;
#[cfg(test)]
mod authwire;
#[cfg(test)]
mod drivepolicy;

#[cfg(test)]
mod session;

#[cfg(test)]
mod validation;

#[cfg(test)]
mod share;

#[cfg(test)]
mod subjectgroup;

#[cfg(test)]
mod magiclink;

#[cfg(test)]
mod userstate;

#[cfg(test)]
mod admin;

#[cfg(test)]
mod liveauth;

#[cfg(test)]
mod policydefaults;
