//! Request and response structs of the client endpoints, with the fields the
//! handlers read and write.
pub mod filter {
    use crate::{OwnedRoomId, OwnedUserId};

    #[derive(Clone, Copy, Debug, PartialEq, Eq)]
    pub enum UrlFilter {
        EventsWithUrl,
        EventsWithoutUrl,
    }

    /// Lazy loading of members; the tests leave it off.
    #[derive(Clone, Debug, Default)]
    pub struct LazyLoadOptions {
        pub enabled: bool,
    }

    impl LazyLoadOptions {
        pub fn is_enabled(&self) -> bool {
            self.enabled
        }
    }

    #[derive(Clone, Debug, Default)]
    pub struct RoomEventFilter {
        pub not_types: Vec<String>,
        pub types: Option<Vec<String>>,
        pub not_rooms: Vec<OwnedRoomId>,
        pub rooms: Option<Vec<OwnedRoomId>>,
        pub not_senders: Vec<OwnedUserId>,
        pub senders: Option<Vec<OwnedUserId>>,
        pub url_filter: Option<UrlFilter>,
        pub lazy_load_options: LazyLoadOptions,
        pub related_by_senders: Vec<OwnedUserId>,
        pub related_by_rel_types: Vec<String>,
    }

    #[derive(Clone, Debug, Default)]
    pub struct Filter {
        pub not_senders: Vec<OwnedUserId>,
        pub senders: Option<Vec<OwnedUserId>>,
    }

    #[derive(Clone, Debug, Default)]
    pub struct RoomFilter {
        pub not_rooms: Vec<OwnedRoomId>,
        pub rooms: Option<Vec<OwnedRoomId>>,
    }
}

pub mod message {
    pub mod get_message_events {
        pub mod v3 {
            use crate::{
                OwnedRoomId, UInt,
                api::{Direction, client::filter::RoomEventFilter},
                events::{AnyStateEvent, AnyTimelineEvent},
                serde::Raw,
            };

            pub struct Request {
                pub room_id: OwnedRoomId,
                pub from: Option<String>,
                pub to: Option<String>,
                pub dir: Direction,
                pub limit: UInt,
                pub filter: RoomEventFilter,
            }

            #[derive(Debug)]
            pub struct Response {
                pub start: String,
                pub end: Option<String>,
                pub chunk: Vec<Raw<AnyTimelineEvent>>,
                pub state: Vec<Raw<AnyStateEvent>>,
            }
        }
    }
}

pub mod context {
    pub mod get_context {
        pub mod v3 {
            use crate::{
                OwnedEventId, OwnedRoomId, UInt,
                api::client::filter::RoomEventFilter,
                events::{AnyStateEvent, AnyTimelineEvent},
                serde::Raw,
            };

            pub struct Request {
                pub room_id: OwnedRoomId,
                pub event_id: OwnedEventId,
                pub limit: UInt,
                pub filter: RoomEventFilter,
            }

            #[derive(Debug)]
            pub struct Response {
                pub start: Option<String>,
                pub end: Option<String>,
                pub events_before: Vec<Raw<AnyTimelineEvent>>,
                pub event: Option<Raw<AnyTimelineEvent>>,
                pub events_after: Vec<Raw<AnyTimelineEvent>>,
                pub state: Vec<Raw<AnyStateEvent>>,
            }
        }
    }
}

pub mod relations {
    macro_rules! relations_v1 {
        ($($field:ident: $ty:ty),*) => {
            pub mod v1 {
                use crate::{
                    OwnedEventId, OwnedRoomId, UInt,
                    api::Direction,
                    events::{AnyTimelineEvent, TimelineEventType, relation::RelationType},
                    serde::Raw,
                };

                #[allow(unused_imports)]
                use TimelineEventType as _T;
                #[allow(unused_imports)]
                use RelationType as _R;

                pub struct Request {
                    pub room_id: OwnedRoomId,
                    pub event_id: OwnedEventId,
                    $(pub $field: $ty,)*
                    pub from: Option<String>,
                    pub to: Option<String>,
                    pub limit: Option<UInt>,
                    pub recurse: bool,
                    pub dir: Direction,
                }

                #[derive(Debug)]
                pub struct Response {
                    pub chunk: Vec<Raw<AnyTimelineEvent>>,
                    pub next_batch: Option<String>,
                    pub prev_batch: Option<String>,
                    pub recursion_depth: Option<UInt>,
                }

                impl Response {
                    pub fn new(chunk: Vec<Raw<AnyTimelineEvent>>) -> Self {
                        Self { chunk, next_batch: None, prev_batch: None, recursion_depth: None }
                    }
                }
            }
        };
    }

    pub mod get_relating_events {
        relations_v1!();
    }
    pub mod get_relating_events_with_rel_type {
        relations_v1!(rel_type: RelationType);
    }
    pub mod get_relating_events_with_rel_type_and_event_type {
        relations_v1!(rel_type: RelationType, event_type: TimelineEventType);
    }
}

pub mod threads {
    pub mod get_threads {
        pub mod v1 {
            use crate::{OwnedRoomId, UInt, events::AnyTimelineEvent, serde::Raw};

            #[derive(Clone, Copy, Debug, PartialEq, Eq)]
            pub enum IncludeThreads {
                All,
                Participated,
            }

            pub struct Request {
                pub room_id: OwnedRoomId,
                pub from: Option<String>,
                pub limit: Option<UInt>,
                pub include: IncludeThreads,
            }

            #[derive(Debug)]
            pub struct Response {
                pub chunk: Vec<Raw<AnyTimelineEvent>>,
                pub next_batch: Option<String>,
            }
        }
    }
}

pub mod state {
    pub mod get_state_events {
        pub mod v3 {
            use crate::{OwnedRoomId, events::AnyStateEvent, serde::Raw};

            pub struct Request {
                pub room_id: OwnedRoomId,
            }

            #[derive(Debug)]
            pub struct Response {
                pub room_state: Vec<Raw<AnyStateEvent>>,
            }
        }
    }

    pub mod get_state_event_for_key {
        pub mod v3 {
            use crate::{OwnedRoomId, events::StateEventType};

            #[derive(Clone, Copy, Debug, PartialEq, Eq)]
            pub enum StateEventFormat {
                Event,
                Content,
            }

            pub struct Request {
                pub room_id: OwnedRoomId,
                pub event_type: StateEventType,
                pub state_key: String,
                pub format: StateEventFormat,
            }

            #[derive(Debug)]
            pub struct Response {
                pub event_or_content: Box<serde_json::value::RawValue>,
            }

            impl Response {
                pub fn new(event_or_content: Box<serde_json::value::RawValue>) -> Self {
                    Self { event_or_content }
                }
            }
        }
    }
}

pub mod membership {
    pub mod get_member_events {
        pub mod v3 {
            use crate::{OwnedRoomId, events::{AnyStateEvent, room::member::MembershipState}, serde::Raw};

            pub struct Request {
                pub room_id: OwnedRoomId,
                pub at: Option<String>,
                pub membership: Option<MembershipState>,
                pub not_membership: Option<MembershipState>,
            }

            #[derive(Debug)]
            pub struct Response {
                pub chunk: Vec<Raw<AnyStateEvent>>,
            }
        }
    }

    pub mod joined_members {
        pub mod v3 {
            use std::collections::BTreeMap;

            use crate::{OwnedRoomId, OwnedUserId};

            pub struct Request {
                pub room_id: OwnedRoomId,
            }

            #[derive(Clone, Debug)]
            pub struct RoomMember {
                pub display_name: Option<String>,
                pub avatar_url: Option<String>,
            }

            #[derive(Debug)]
            pub struct Response {
                pub joined: BTreeMap<OwnedUserId, RoomMember>,
            }
        }
    }
}

pub mod room {
    pub mod get_room_event {
        pub mod v3 {
            use crate::{OwnedEventId, OwnedRoomId, events::AnyTimelineEvent, serde::Raw};

            pub struct Request {
                pub room_id: OwnedRoomId,
                pub event_id: OwnedEventId,
                pub include_unredacted_content: bool,
            }

            #[derive(Debug)]
            pub struct Response {
                pub event: Raw<AnyTimelineEvent>,
            }
        }
    }

    pub mod initial_sync {
        pub mod v3 {
            use crate::{
                OwnedRoomId,
                events::{AnyRoomAccountDataEvent, AnyStateEvent, AnyTimelineEvent, room::member::MembershipState},
                serde::Raw,
            };

            #[derive(Clone, Copy, Debug, PartialEq, Eq)]
            pub enum Visibility {
                Public,
                Private,
            }

            pub struct Request {
                pub room_id: OwnedRoomId,
                pub limit: Option<usize>,
            }

            #[derive(Debug)]
            pub struct PaginationChunk {
                pub start: Option<String>,
                pub end: String,
                pub chunk: Vec<Raw<AnyTimelineEvent>>,
            }

            #[derive(Debug)]
            pub struct Response {
                pub room_id: OwnedRoomId,
                pub membership: Option<MembershipState>,
                pub visibility: Option<Visibility>,
                pub account_data: Option<Vec<Raw<AnyRoomAccountDataEvent>>>,
                pub state: Option<Vec<Raw<AnyStateEvent>>>,
                pub messages: Option<PaginationChunk>,
            }
        }
    }
}
