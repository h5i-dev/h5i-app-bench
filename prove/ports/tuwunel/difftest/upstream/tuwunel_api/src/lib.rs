//! Stub of tuwunel_api around the copied client endpoints: the `Ruma`
//! request wrapper, `State`, and test seams that call the `pub(crate)`
//! routes.
#![allow(unused_imports, unused_variables, dead_code)]

use std::{ops::Deref, sync::Arc};

use axum::extract::State as AxumState;
use ruma::{OwnedDeviceId, OwnedUserId, UserId, api::client as c};
use tuwunel_core::Result;

pub mod client;

pub type State = Arc<tuwunel_service::Services>;

/// An authenticated request.
pub struct Ruma<T> {
    pub body: T,
    pub sender_user: Option<OwnedUserId>,
    pub sender_device: Option<OwnedDeviceId>,
    pub appservice_info: Option<()>,
}

impl<T> Deref for Ruma<T> {
    type Target = T;
    fn deref(&self) -> &T {
        &self.body
    }
}

impl<T> Ruma<T> {
    pub fn sender_user(&self) -> &UserId {
        self.sender_user.as_deref().expect("user must be authenticated for this handler")
    }
}

pub struct RumaResponse<T>(pub T);

fn ruma<T>(user: &UserId, body: T) -> Ruma<T> {
    Ruma { body, sender_user: Some(user.to_owned()), sender_device: None, appservice_info: None }
}

// Test seams: one per route.

pub async fn messages(s: State, user: &UserId, b: c::message::get_message_events::v3::Request) -> Result<c::message::get_message_events::v3::Response> {
    client::get_message_events_route(AxumState(s), ruma(user, b)).await
}

pub async fn context(s: State, user: &UserId, b: c::context::get_context::v3::Request) -> Result<c::context::get_context::v3::Response> {
    client::get_context_route(AxumState(s), ruma(user, b)).await
}

pub async fn relations(s: State, user: &UserId, b: c::relations::get_relating_events::v1::Request) -> Result<c::relations::get_relating_events::v1::Response> {
    client::get_relating_events_route(AxumState(s), ruma(user, b)).await
}

pub async fn relations_with_rel_type(
    s: State,
    user: &UserId,
    b: c::relations::get_relating_events_with_rel_type::v1::Request,
) -> Result<c::relations::get_relating_events_with_rel_type::v1::Response> {
    client::get_relating_events_with_rel_type_route(AxumState(s), ruma(user, b)).await
}

pub async fn relations_with_rel_type_and_event_type(
    s: State,
    user: &UserId,
    b: c::relations::get_relating_events_with_rel_type_and_event_type::v1::Request,
) -> Result<c::relations::get_relating_events_with_rel_type_and_event_type::v1::Response> {
    client::get_relating_events_with_rel_type_and_event_type_route(AxumState(s), ruma(user, b)).await
}

pub async fn threads(s: State, user: &UserId, b: c::threads::get_threads::v1::Request) -> Result<c::threads::get_threads::v1::Response> {
    client::get_threads_route(AxumState(s), ruma(user, b)).await
}

pub async fn state_events(s: State, user: &UserId, b: c::state::get_state_events::v3::Request) -> Result<c::state::get_state_events::v3::Response> {
    client::get_state_events_route(AxumState(s), ruma(user, b)).await
}

pub async fn state_event_for_key(
    s: State,
    user: &UserId,
    b: c::state::get_state_event_for_key::v3::Request,
) -> Result<c::state::get_state_event_for_key::v3::Response> {
    client::get_state_events_for_key_route(AxumState(s), ruma(user, b)).await
}

pub async fn members(s: State, user: &UserId, b: c::membership::get_member_events::v3::Request) -> Result<c::membership::get_member_events::v3::Response> {
    client::get_member_events_route(AxumState(s), ruma(user, b)).await
}

pub async fn joined_members(s: State, user: &UserId, b: c::membership::joined_members::v3::Request) -> Result<c::membership::joined_members::v3::Response> {
    client::joined_members_route(AxumState(s), ruma(user, b)).await
}

pub async fn initial_sync(s: State, user: &UserId, b: c::room::initial_sync::v3::Request) -> Result<c::room::initial_sync::v3::Response> {
    client::room_initial_sync_route(AxumState(s), ruma(user, b)).await
}

pub async fn room_event(s: State, user: &UserId, b: c::room::get_room_event::v3::Request) -> Result<c::room::get_room_event::v3::Response> {
    client::get_room_event_route(AxumState(s), ruma(user, b)).await
}
