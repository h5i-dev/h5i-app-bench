//! synctv's security decisions (synctv-org/synctv @ 38970e0, `synctv-core`) as an
//! h5i-app kernel: room permission bitspaces and effective permissions, member role and
//! override policy, global roles, and token / guest / session acceptance.
//! See `../DEVIATIONS.md` for the mapping to upstream.
pub mod auth;
pub mod perms;
pub mod policy;
