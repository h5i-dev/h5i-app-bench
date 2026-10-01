// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
/// Infers a user's cached membership state for one room.
///
/// Current indexes take precedence in join, leave, knock, then invite order.
/// When none exists, a once-joined marker is reported as `Ban`; no marker
/// returns `None`. Read failures from the boolean probes are treated as
/// absence.
use futures::Stream;
use futures::StreamExt;
use futures::TryStreamExt;
use futures::future::join5;
use ruma::RoomId;
use ruma::UserId;
use ruma::events::room::member::MembershipState;
use tuwunel_core::Result;
use tuwunel_core::implement;
use tuwunel_core::matrix::Event;
use tuwunel_core::trace;
use tuwunel_core::utils::BoolExt;
use tuwunel_core::utils::result::NotFound;
use tuwunel_core::utils::stream::BroadbandExt;
use tuwunel_core::utils::stream::IterStream;
use tuwunel_core::utils::stream::ReadyExt;
use tuwunel_core::utils::stream::TryIgnore;
use tuwunel_database::Deserialized;
use tuwunel_database::Ignore;
use tuwunel_database::Interfix;

#[implement(Service)]
#[tracing::instrument(skip(self), level = "trace")]
pub async fn user_membership(
	&self,
	user_id: &UserId,
	room_id: &RoomId,
) -> Option<MembershipState> {
	let states = join5(
		self.is_joined(user_id, room_id),
		self.is_left(user_id, room_id),
		self.is_knocked(user_id, room_id),
		self.is_invited(user_id, room_id),
		self.once_joined(user_id, room_id),
	)
	.await;

	match states {
		| (true, ..) => Some(MembershipState::Join),
		| (_, true, ..) => Some(MembershipState::Leave),
		| (_, _, true, ..) => Some(MembershipState::Knock),
		| (_, _, _, true, ..) => Some(MembershipState::Invite),
		| (false, false, false, false, true) => Some(MembershipState::Ban),
		| _ => None,
	}
}

/// Tests whether a user has ever been marked as joined to a room.
///
/// The durable marker survives later membership transitions and explicit
/// forget operations. Missing rows and storage failures both return `false`.
#[implement(Service)]
#[tracing::instrument(skip(self), level = "debug")]
pub async fn once_joined(&self, user_id: &UserId, room_id: &RoomId) -> bool {
	let key = (user_id, room_id);
	self.db.roomuseroncejoinedids.contains(&key).await
}

/// Tests whether a user is currently indexed as joined to a room.
///
/// The user-to-room join index supplies the answer. Missing rows and storage
/// failures both return `false`.
#[implement(Service)]
#[tracing::instrument(skip(self), level = "trace")]
pub async fn is_joined<'a>(&'a self, user_id: &'a UserId, room_id: &'a RoomId) -> bool {
	let key = (user_id, room_id);
	self.db
		.userroomid_joinedcount
		.contains(&key)
		.await
}

/// Tests whether a user is currently indexed as knocking on a room.
///
/// The stored knock-state row supplies the answer. Missing rows and storage
/// failures both return `false`.
#[implement(Service)]
#[tracing::instrument(skip(self), level = "trace")]
pub async fn is_knocked<'a>(&'a self, user_id: &'a UserId, room_id: &'a RoomId) -> bool {
	let key = (user_id, room_id);
	self.db
		.userroomid_knockedstate
		.contains(&key)
		.await
}

/// Tests whether a user is currently indexed as invited to a room.
///
/// The stored invite-state row supplies the answer. Missing rows and storage
/// failures both return `false`.
#[implement(Service)]
#[tracing::instrument(skip(self), level = "trace")]
pub async fn is_invited(&self, user_id: &UserId, room_id: &RoomId) -> bool {
	let key = (user_id, room_id);
	self.db
		.userroomid_invitestate
		.contains(&key)
		.await
}

/// Tests whether a user's leave state is currently retained for a room.
///
/// Explicitly forgotten rooms have no row and return `false`. Missing rows and
/// storage failures are otherwise indistinguishable.
#[implement(Service)]
#[tracing::instrument(skip(self), level = "trace")]
pub async fn is_left(&self, user_id: &UserId, room_id: &RoomId) -> bool {
	let key = (user_id, room_id);
	self.db.userroomid_leftstate.contains(&key).await
}

/// Returns the stream position associated with a user's current leave row.
///
/// This value identifies the membership transition rather than counting
/// leaves. Missing or malformed index rows return an error.
#[implement(Service)]
#[tracing::instrument(skip(self), level = "trace")]
pub async fn get_left_count(&self, room_id: &RoomId, user_id: &UserId) -> Result<u64> {
	let key = (room_id, user_id);
	self.db
		.roomuserid_leftcount
		.qry(&key)
		.await
		.deserialized()
}

/// Streams all users currently indexed as joined to a room.
///
/// Storage and key-decoding failures are skipped. Each user identifier borrows
/// the cursor and must be consumed or owned before the stream advances.
#[implement(Service)]
#[tracing::instrument(skip(self), level = "debug")]
pub fn room_members<'a>(
	&'a self,
	room_id: &'a RoomId,
) -> impl Stream<Item = &UserId> + Send + 'a {
	self.room_members_checked(room_id).ignore_err()
}

/// Streams joined users within the room's exact encoded prefix.
///
/// Storage and user-key decoding failures are surfaced as error items rather
/// than dropped. User IDs borrow the cursor and must be consumed or owned
/// before advancing it.
#[implement(Service)]
#[tracing::instrument(skip(self), level = "debug")]
pub fn room_members_checked<'a>(
	&'a self,
	room_id: &'a RoomId,
) -> impl Stream<Item = Result<&'a UserId>> + Send + 'a {
	let prefix = (room_id, Interfix);

	self.db
		.roomuserid_joinedcount
		.keys_prefix(&prefix)
		.map_ok(|(_, user_id): (Ignore, &UserId)| user_id)
}


mod stub;
pub use stub::*;
