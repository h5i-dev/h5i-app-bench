// Copied from matrix-construct/tuwunel @ 7801b8e by extract_upstream.py. Do not edit.
use futures::Stream;
use futures::StreamExt;
use ruma::OwnedUserId;
use ruma::UserId;
use ruma::api::Direction;
use ruma::events::relation::RelationType;
use tuwunel_core::PduId;
use tuwunel_core::arrayvec::ArrayVec;
use tuwunel_core::implement;
use tuwunel_core::is_equal_to;
use tuwunel_core::matrix::Event;
use tuwunel_core::matrix::Pdu;
use tuwunel_core::matrix::PduCount;
use tuwunel_core::matrix::RawPduId;
use tuwunel_core::matrix::event::RelationTypeEqual;
use tuwunel_core::utils::stream::ReadyExt;
use tuwunel_core::utils::stream::TryIgnore;
use tuwunel_core::utils::stream::WidebandExt;
use tuwunel_core::utils::u64_from_u8;
use super::Service;
use crate::rooms::short::ShortRoomId;

type StartKey = ArrayVec<u8, 16>;

#[implement(Service)]
pub fn get_relations<'a>(
	&'a self,
	shortroomid: ShortRoomId,
	target: PduCount,
	from: Option<PduCount>,
	dir: Direction,
	user_id: Option<&'a UserId>,
) -> impl Stream<Item = (PduCount, Pdu)> + Send + '_ {
	let target = target.to_be_bytes();
	let from = from
		.map(|from| from.saturating_inc(dir))
		.unwrap_or_else(|| match dir {
			| Direction::Backward => PduCount::max(),
			| Direction::Forward => PduCount::default(),
		})
		.to_be_bytes();

	let mut buf = StartKey::new();
	let start = {
		buf.extend(target);
		buf.extend(from);
		buf.as_slice()
	};

	match dir {
		| Direction::Backward => self
			.db
			.tofrom_relation
			.rev_raw_keys_from(start)
			.left_stream(),

		| Direction::Forward => self
			.db
			.tofrom_relation
			.raw_keys_from(start)
			.right_stream(),
	}
	.ignore_err()
	.ready_take_while(move |key| key.starts_with(&target))
	.map(|to_from| u64_from_u8(&to_from[8..16]))
	.map(PduCount::from_unsigned)
	.map(move |count| (user_id, shortroomid, count))
	.wide_filter_map(async |(user_id, shortroomid, count)| {
		let pdu_id: RawPduId = PduId { shortroomid, count }.into();
		let mut pdu = self
			.services
			.timeline
			.get_pdu_from_id(&pdu_id)
			.await
			.ok()?;

		pdu.remove_transaction_id_unless_sender(user_id)
			.ok()?;

		Some((count, pdu))
	})
}

/// MSC3440 `related_by_*`: whether any event relates to `target` with a
/// `rel_type` in `rel_types` and a `sender` in `senders`. An empty list is
/// unconstrained on that axis; a single relating event must satisfy both.
#[implement(Service)]
pub async fn has_incoming_relation(
	&self,
	target: PduId,
	senders: &[OwnedUserId],
	rel_types: &[RelationType],
) -> bool {
	self.get_relations(target.shortroomid, target.count, None, Direction::Forward, None)
		.ready_any(|(_, pdu)| {
			let sender_matches =
				senders.is_empty() || senders.iter().any(is_equal_to!(pdu.sender()));

			let rel_type_matches = rel_types.is_empty()
				|| rel_types
					.iter()
					.any(|rel_type| rel_type.relation_type_equal(&pdu));

			sender_matches && rel_type_matches
		})
		.await
}

