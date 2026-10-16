#![allow(unused_imports, unused_variables, dead_code)]
//! Stub of tuwunel_service: the `Services` hub and the services the copied
//! code reaches, each with its columns as in-memory maps. The copied files
//! sit at their upstream paths; `stub.rs` files hold the hand-written rest.
use std::{ops::Deref, sync::{Arc, OnceLock}};

pub mod account_data;
pub mod admin;
pub mod globals;
pub mod rooms;
pub mod users;

pub use tuwunel_core::config::Config;

/// `OnceServices`: every service reaches the others through it.
#[derive(Default)]
pub struct OnceServices(OnceLock<usize>);

pub type Svc = Arc<OnceServices>;

impl OnceServices {
    /// Points at the finished `Services`, which must outlive every use.
    pub fn set(&self, s: &Services) {
        self.0.set(s as *const Services as usize).ok();
    }
}

impl Deref for OnceServices {
    type Target = Services;
    fn deref(&self) -> &Services {
        // SAFETY: set once to a `Services` held in an `Arc` that lives as long
        // as the services themselves.
        unsafe { &*(*self.0.get().expect("services set") as *const Services) }
    }
}

pub struct Services {
    pub config: Config,
    pub globals: globals::Service,
    pub account_data: account_data::Service,
    pub admin: admin::Service,
    pub users: users::Service,
    pub metadata: rooms::metadata::Service,
    pub short: rooms::short::Service,
    pub state: rooms::state::Service,
    pub state_accessor: rooms::state_accessor::Service,
    pub state_cache: rooms::state_cache::Service,
    pub state_compressor: rooms::state_compressor::Service,
    pub timeline: rooms::timeline::Service,
    pub pdu_metadata: rooms::pdu_metadata::Service,
    pub threads: rooms::threads::Service,
    pub lazy_loading: rooms::lazy_loading::Service,
    pub read_receipt: rooms::read_receipt::Service,
    pub directory: rooms::directory::Service,
    pub retention: rooms::retention::Service,
}
