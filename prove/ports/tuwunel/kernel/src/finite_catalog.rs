//! Exhaustive finite enum decisions; see DEVIATIONS.md.
pub mod field_bea9b175 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Field {Name,Version,Compiler}
impl Field {
	pub fn label(self) -> Vec<u8> {
		match self {
			| Self::Name => Vec::from([110u8, 97u8, 109u8, 101u8]),
			| Self::Version => Vec::from([118u8, 101u8, 114u8, 115u8, 105u8, 111u8, 110u8]),
			| Self::Compiler => Vec::from([99u8, 111u8, 109u8, 112u8, 105u8, 108u8, 101u8, 114u8]),
		}
	}
}
}
pub mod state_after_c4e3af58 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum StateAfter {Off,Stable,Unstable}
impl StateAfter {
	pub fn requested(self) -> bool { !matches!(self, Self::Off) }
}
}
pub mod fallback_08cb57a8 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Fallback {Absent,Ceiling,AuthMissing,AllCommitted,Entries,Canary,CreateMismatch,Unevaluable,Error}
impl Fallback {
	pub fn name(self) -> Vec<u8> {
		match self {
			| Self::Absent => Vec::from([97u8, 98u8, 115u8, 101u8, 110u8, 116u8]),
			| Self::Ceiling => Vec::from([99u8, 101u8, 105u8, 108u8, 105u8, 110u8, 103u8]),
			| Self::AuthMissing => Vec::from([97u8, 117u8, 116u8, 104u8, 95u8, 109u8, 105u8, 115u8, 115u8, 105u8, 110u8, 103u8]),
			| Self::AllCommitted => Vec::from([97u8, 108u8, 108u8, 95u8, 99u8, 111u8, 109u8, 109u8, 105u8, 116u8, 116u8, 101u8, 100u8]),
			| Self::Entries => Vec::from([101u8, 110u8, 116u8, 114u8, 105u8, 101u8, 115u8]),
			| Self::Canary => Vec::from([99u8, 97u8, 110u8, 97u8, 114u8, 121u8]),
			| Self::CreateMismatch => Vec::from([99u8, 114u8, 101u8, 97u8, 116u8, 101u8, 95u8, 109u8, 105u8, 115u8, 109u8, 97u8, 116u8, 99u8, 104u8]),
			| Self::Unevaluable => Vec::from([117u8, 110u8, 101u8, 118u8, 97u8, 108u8, 117u8, 97u8, 98u8, 108u8, 101u8]),
			| Self::Error => Vec::from([101u8, 114u8, 114u8, 111u8, 114u8]),
		}
	}
}
}
pub mod room_power_levels_int_field_b809be58 {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum RoomPowerLevelsIntField {UsersDefault,EventsDefault,StateDefault,Ban,Redact,Kick,Invite}
impl RoomPowerLevelsIntField {
	
	#[inline]
	#[must_use]
	pub fn as_str(&self) -> Vec<u8> { self.as_ref() }
	#[inline]
	pub fn as_ref(&self) -> Vec<u8> {
		match self {
			| Self::UsersDefault => Vec::from([117u8, 115u8, 101u8, 114u8, 115u8, 95u8, 100u8, 101u8, 102u8, 97u8, 117u8, 108u8, 116u8]),
			| Self::EventsDefault => Vec::from([101u8, 118u8, 101u8, 110u8, 116u8, 115u8, 95u8, 100u8, 101u8, 102u8, 97u8, 117u8, 108u8, 116u8]),
			| Self::StateDefault => Vec::from([115u8, 116u8, 97u8, 116u8, 101u8, 95u8, 100u8, 101u8, 102u8, 97u8, 117u8, 108u8, 116u8]),
			| Self::Ban => Vec::from([98u8, 97u8, 110u8]),
			| Self::Redact => Vec::from([114u8, 101u8, 100u8, 97u8, 99u8, 116u8]),
			| Self::Kick => Vec::from([107u8, 105u8, 99u8, 107u8]),
			| Self::Invite => Vec::from([105u8, 110u8, 118u8, 105u8, 116u8, 101u8]),
		}
	}
}
}
pub mod status_4004009f {
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum Status {Scheduled,Active,Complete,Failed}
impl Status {
	
	
	
	
	#[must_use]
	pub fn is_terminal(self) -> bool { matches!(self, Self::Complete | Self::Failed) }
	
	
	
	
	#[must_use]
	pub fn as_str(self) -> Vec<u8> {
		match self {
			| Self::Scheduled => Vec::from([115u8, 99u8, 104u8, 101u8, 100u8, 117u8, 108u8, 101u8, 100u8]),
			| Self::Active => Vec::from([97u8, 99u8, 116u8, 105u8, 118u8, 101u8]),
			| Self::Complete => Vec::from([99u8, 111u8, 109u8, 112u8, 108u8, 101u8, 116u8, 101u8]),
			| Self::Failed => Vec::from([102u8, 97u8, 105u8, 108u8, 101u8, 100u8]),
		}
	}
}
}
