//! rustfs's IAM and bucket policy evaluation (rustfs/rustfs @ e870a6d,
//! `crates/policy`) in the Aeneas subset. Each function follows the upstream
//! function named in its comment; the differences are in ../DEVIATIONS.md.
pub mod acts;
pub mod awsvars;
pub mod bytes;
pub mod condfuncs;
pub mod keynames;
pub mod pathclean;
pub mod policies;
pub mod rsrc;
pub mod stmts;
pub mod wildmatch;
pub mod defaults;
pub mod actsets;
pub mod valids;
pub mod resets;
pub mod conddata;
pub mod dates;

pub mod claims;
pub mod unicode;

pub mod keytables;

pub mod manage;
