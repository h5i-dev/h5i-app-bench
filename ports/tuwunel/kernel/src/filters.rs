//! `core/matrix/event/filter.rs`: `Matches<&E> for RoomEventFilter`, and
//! `core/config/net.rs` `is_forbidden_remote_server_name`.
use crate::*;

fn any_kind(v: &[Kind], k: Kind) -> bool {
    let mut i = 0;
    while i < v.len() {
        if kind_eq(v[i], k) {
            return true;
        }
        i += 1;
    }
    false
}

/// `matches`: sender, room, type and url, in that order.
pub fn matches(filter: &Filter, p: &Pdu) -> bool {
    if !matches_sender(p, filter) {
        return false;
    }
    if !matches_room(p, filter) {
        return false;
    }
    if !matches_type(p, filter) {
        return false;
    }
    if !matches_url(p, filter) {
        return false;
    }
    true
}

pub fn matches_room(p: &Pdu, filter: &Filter) -> bool {
    if contains_u64(&filter.not_rooms, p.room) {
        return false;
    }
    match &filter.rooms {
        Some(rooms) => contains_u64(rooms, p.room),
        None => true,
    }
}

pub fn matches_sender(p: &Pdu, filter: &Filter) -> bool {
    if contains_u64(&filter.not_senders, p.sender) {
        return false;
    }
    match &filter.senders {
        Some(senders) => contains_u64(senders, p.sender),
        None => true,
    }
}

pub fn matches_type(p: &Pdu, filter: &Filter) -> bool {
    if any_kind(&filter.not_types, p.kind) {
        return false;
    }
    match &filter.types {
        Some(types) => any_kind(types, p.kind),
        None => true,
    }
}

pub fn matches_url(p: &Pdu, filter: &Filter) -> bool {
    match filter.url_filter {
        UrlFilter::Any => true,
        UrlFilter::WithUrl => p.has_url,
        UrlFilter::WithoutUrl => !p.has_url,
    }
}

/// `Config::is_forbidden_remote_server_name`: never the own server; a
/// deny-list match or, with an allow list, a miss.
pub fn is_forbidden_remote_server_name(c: &Config, server: u64) -> bool {
    if server == c.server_name {
        return false;
    }
    let deny_list_active = c.forbidden_remote_server_names.len() != 0;
    let allow_list_active = c.allowed_remote_server_names.len() != 0;
    if deny_list_active && contains_u64(&c.forbidden_remote_server_names, server) {
        return true;
    }
    if allow_list_active && !contains_u64(&c.allowed_remote_server_names, server) {
        return true;
    }
    false
}
