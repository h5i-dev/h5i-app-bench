// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
use futures::Stream;
use futures::StreamExt;
use futures::TryFutureExt;
use ruma::UserId;
use serde::Deserialize;
use tuwunel_core::utils::BoolExt;
use tuwunel_core::utils::ReadyExt;
use tuwunel_core::utils::stream::TryIgnore;
use tuwunel_database::Deserialized;

impl Service {
	/// Returns true/false based on whether the recipient/receiving user has
	/// blocked the sender
	pub async fn user_is_ignored(&self, sender_user: &UserId, recipient_user: &UserId) -> bool {
		self.ignored_users(recipient_user)
			.await
			.is_some_and(|ignored| {
				ignored
					.ignored_users
					.keys()
					.any(|blocked_user| blocked_user == sender_user)
			})
	}

}

mod stub;
pub use stub::*;
