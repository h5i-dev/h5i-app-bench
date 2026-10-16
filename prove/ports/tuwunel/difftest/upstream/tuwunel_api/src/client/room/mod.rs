mod event;
mod initial_sync;

pub(crate) use self::{event::get_room_event_route, initial_sync::room_initial_sync_route};
