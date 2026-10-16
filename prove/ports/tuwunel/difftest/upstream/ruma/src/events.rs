//! Event types and the contents the copied code deserializes.
use std::{borrow::Cow, cmp::Ordering, collections::BTreeMap};

use serde::{Deserialize, Deserializer, Serialize, Serializer};

use crate::{OwnedUserId, serde::Raw};

macro_rules! string_enum {
    ($name:ident { $($v:ident = $s:literal),* $(,)? }) => {
        #[derive(Clone, Debug, PartialEq, Eq, Hash)]
        pub enum $name {
            $($v,)*
            _Custom(String),
        }

        impl $name {
            pub fn to_cow_str(&self) -> Cow<'_, str> {
                match self {
                    $(Self::$v => Cow::Borrowed($s),)*
                    Self::_Custom(s) => Cow::Borrowed(s.as_str()),
                }
            }
        }

        impl From<&str> for $name {
            fn from(s: &str) -> Self {
                match s {
                    $($s => Self::$v,)*
                    _ => Self::_Custom(s.to_owned()),
                }
            }
        }

        impl From<String> for $name {
            fn from(s: String) -> Self {
                Self::from(s.as_str())
            }
        }

        impl From<Cow<'_, str>> for $name {
            fn from(s: Cow<'_, str>) -> Self {
                Self::from(&*s)
            }
        }

        impl Ord for $name {
            fn cmp(&self, o: &Self) -> Ordering {
                self.to_cow_str().cmp(&o.to_cow_str())
            }
        }

        impl PartialOrd for $name {
            fn partial_cmp(&self, o: &Self) -> Option<Ordering> {
                Some(self.cmp(o))
            }
        }

        impl std::fmt::Display for $name {
            fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
                f.write_str(&self.to_cow_str())
            }
        }

        impl Serialize for $name {
            fn serialize<S: Serializer>(&self, s: S) -> Result<S::Ok, S::Error> {
                s.serialize_str(&self.to_cow_str())
            }
        }

        impl<'de> Deserialize<'de> for $name {
            fn deserialize<D: Deserializer<'de>>(d: D) -> Result<Self, D::Error> {
                Ok(Self::from(String::deserialize(d)?))
            }
        }
    };
}

string_enum!(TimelineEventType {
    CallInvite = "m.call.invite",
    KeyVerificationStart = "m.key.verification.start",
    Location = "m.location",
    PollStart = "m.poll.start",
    Reaction = "m.reaction",
    RoomEncrypted = "m.room.encrypted",
    RoomMessage = "m.room.message",
    Sticker = "m.sticker",
    Audio = "org.matrix.msc1767.audio",
    Emote = "org.matrix.msc1767.emote",
    File = "org.matrix.msc1767.file",
    Image = "org.matrix.msc1767.image",
    Video = "org.matrix.msc1767.video",
    Voice = "org.matrix.msc3245.voice.v2",
    UnstablePollStart = "org.matrix.msc3381.poll.start",
    Beacon = "org.matrix.msc3672.beacon",
    CallNotify = "org.matrix.msc4075.call.notify",
    RoomCreate = "m.room.create",
    RoomMember = "m.room.member",
    RoomPowerLevels = "m.room.power_levels",
    RoomJoinRules = "m.room.join_rules",
    RoomHistoryVisibility = "m.room.history_visibility",
    RoomEncryption = "m.room.encryption",
    RoomName = "m.room.name",
    RoomRedaction = "m.room.redaction",
    RoomServerAcl = "m.room.server_acl",
});

string_enum!(StateEventType {
    RoomCreate = "m.room.create",
    RoomMember = "m.room.member",
    RoomPowerLevels = "m.room.power_levels",
    RoomJoinRules = "m.room.join_rules",
    RoomHistoryVisibility = "m.room.history_visibility",
    RoomEncryption = "m.room.encryption",
    RoomName = "m.room.name",
    RoomServerAcl = "m.room.server_acl",
});

impl PartialEq<StateEventType> for &StateEventType {
    fn eq(&self, o: &StateEventType) -> bool {
        **self == *o
    }
}

string_enum!(GlobalAccountDataEventType {
    IgnoredUserList = "m.ignored_user_list",
    Direct = "m.direct",
});

pub mod relation {
    use super::*;

    string_enum!(RelationType {
        Annotation = "m.annotation",
        Reference = "m.reference",
        Replacement = "m.replace",
        Thread = "m.thread",
    });
}

pub mod room {
    pub mod history_visibility {
        use crate::events::*;

        string_enum!(HistoryVisibility {
            Invited = "invited",
            Joined = "joined",
            Shared = "shared",
            WorldReadable = "world_readable",
        });

        #[derive(Clone, Debug, Deserialize)]
        pub struct RoomHistoryVisibilityEventContent {
            pub history_visibility: HistoryVisibility,
        }
    }

    pub mod member {
        use crate::events::*;

        string_enum!(MembershipState {
            Ban = "ban",
            Invite = "invite",
            Join = "join",
            Knock = "knock",
            Leave = "leave",
        });

        #[derive(Clone, Debug, Deserialize)]
        pub struct RoomMemberEventContent {
            pub membership: MembershipState,
            #[serde(default)]
            pub displayname: Option<String>,
            #[serde(default)]
            pub avatar_url: Option<String>,
        }
    }
}

pub mod ignored_user_list {
    use super::*;

    #[derive(Clone, Debug, Default, Deserialize)]
    pub struct IgnoredUser {}

    #[derive(Clone, Debug, Default, Deserialize)]
    pub struct IgnoredUserListEventContent {
        pub ignored_users: BTreeMap<OwnedUserId, IgnoredUser>,
    }

    #[derive(Clone, Debug, Default, Deserialize)]
    pub struct IgnoredUserListEvent {
        pub content: IgnoredUserListEventContent,
    }
}

/// Markers for `Raw<T>`.
#[derive(Clone, Debug)]
pub enum AnyStateEvent {}
#[derive(Clone, Debug)]
pub enum AnyTimelineEvent {}
#[derive(Clone, Debug)]
pub enum AnySyncMessageLikeEvent {}
#[derive(Clone, Debug)]
pub enum AnyRoomAccountDataEvent {}

#[derive(Clone, Debug)]
pub enum AnyRawAccountDataEvent {
    Global(Raw<()>),
    Room(Raw<AnyRoomAccountDataEvent>),
}
