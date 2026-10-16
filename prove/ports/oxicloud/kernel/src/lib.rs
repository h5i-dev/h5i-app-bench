//! OxiCloud's access control (AtalayaLabs/OxiCloud @ 8c0dd33) in the Aeneas
//! subset: the ACL engine's permission check and grant writes, the drive
//! policy gates, and the grant endpoints. Each function follows the
//! upstream function named in its comment; ../DEVIATIONS.md lists where the
//! form differs. Tables are lists of rows; the clock is an input.
pub mod acl;
pub mod grantapi;
pub mod model;
