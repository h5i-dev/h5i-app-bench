#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum RoomPowerLevelsIntField {UsersDefault,EventsDefault,StateDefault,Ban,Redact,Kick,Invite}
impl RoomPowerLevelsIntField {
	/// The string representation of this field.
	#[inline]
	#[must_use]
	pub fn as_str(&self) -> &str { self.as_ref() }
	#[inline]
	fn as_ref(&self) -> &'static str {
		match self {
			| Self::UsersDefault => "users_default",
			| Self::EventsDefault => "events_default",
			| Self::StateDefault => "state_default",
			| Self::Ban => "ban",
			| Self::Redact => "redact",
			| Self::Kick => "kick",
			| Self::Invite => "invite",
		}
	}
}
fn main(){
println!("as_str/UsersDefault\t{:?}",RoomPowerLevelsIntField::UsersDefault.as_str().as_bytes());
println!("as_str/EventsDefault\t{:?}",RoomPowerLevelsIntField::EventsDefault.as_str().as_bytes());
println!("as_str/StateDefault\t{:?}",RoomPowerLevelsIntField::StateDefault.as_str().as_bytes());
println!("as_str/Ban\t{:?}",RoomPowerLevelsIntField::Ban.as_str().as_bytes());
println!("as_str/Redact\t{:?}",RoomPowerLevelsIntField::Redact.as_str().as_bytes());
println!("as_str/Kick\t{:?}",RoomPowerLevelsIntField::Kick.as_str().as_bytes());
println!("as_str/Invite\t{:?}",RoomPowerLevelsIntField::Invite.as_str().as_bytes());
println!("as_ref/UsersDefault\t{:?}",RoomPowerLevelsIntField::UsersDefault.as_ref().as_bytes());
println!("as_ref/EventsDefault\t{:?}",RoomPowerLevelsIntField::EventsDefault.as_ref().as_bytes());
println!("as_ref/StateDefault\t{:?}",RoomPowerLevelsIntField::StateDefault.as_ref().as_bytes());
println!("as_ref/Ban\t{:?}",RoomPowerLevelsIntField::Ban.as_ref().as_bytes());
println!("as_ref/Redact\t{:?}",RoomPowerLevelsIntField::Redact.as_ref().as_bytes());
println!("as_ref/Kick\t{:?}",RoomPowerLevelsIntField::Kick.as_ref().as_bytes());
println!("as_ref/Invite\t{:?}",RoomPowerLevelsIntField::Invite.as_ref().as_bytes());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(RoomPowerLevelsIntField::UsersDefault.as_str().as_bytes(),tuwunel_kernel::finite_catalog::room_power_levels_int_field_b809be58::RoomPowerLevelsIntField::UsersDefault.as_str(),"room_power_levels_int_field_b809be58/as_str/UsersDefault");
assert_eq!(RoomPowerLevelsIntField::EventsDefault.as_str().as_bytes(),tuwunel_kernel::finite_catalog::room_power_levels_int_field_b809be58::RoomPowerLevelsIntField::EventsDefault.as_str(),"room_power_levels_int_field_b809be58/as_str/EventsDefault");
assert_eq!(RoomPowerLevelsIntField::StateDefault.as_str().as_bytes(),tuwunel_kernel::finite_catalog::room_power_levels_int_field_b809be58::RoomPowerLevelsIntField::StateDefault.as_str(),"room_power_levels_int_field_b809be58/as_str/StateDefault");
assert_eq!(RoomPowerLevelsIntField::Ban.as_str().as_bytes(),tuwunel_kernel::finite_catalog::room_power_levels_int_field_b809be58::RoomPowerLevelsIntField::Ban.as_str(),"room_power_levels_int_field_b809be58/as_str/Ban");
assert_eq!(RoomPowerLevelsIntField::Redact.as_str().as_bytes(),tuwunel_kernel::finite_catalog::room_power_levels_int_field_b809be58::RoomPowerLevelsIntField::Redact.as_str(),"room_power_levels_int_field_b809be58/as_str/Redact");
assert_eq!(RoomPowerLevelsIntField::Kick.as_str().as_bytes(),tuwunel_kernel::finite_catalog::room_power_levels_int_field_b809be58::RoomPowerLevelsIntField::Kick.as_str(),"room_power_levels_int_field_b809be58/as_str/Kick");
assert_eq!(RoomPowerLevelsIntField::Invite.as_str().as_bytes(),tuwunel_kernel::finite_catalog::room_power_levels_int_field_b809be58::RoomPowerLevelsIntField::Invite.as_str(),"room_power_levels_int_field_b809be58/as_str/Invite");
assert_eq!(RoomPowerLevelsIntField::UsersDefault.as_ref().as_bytes(),tuwunel_kernel::finite_catalog::room_power_levels_int_field_b809be58::RoomPowerLevelsIntField::UsersDefault.as_ref(),"room_power_levels_int_field_b809be58/as_ref/UsersDefault");
assert_eq!(RoomPowerLevelsIntField::EventsDefault.as_ref().as_bytes(),tuwunel_kernel::finite_catalog::room_power_levels_int_field_b809be58::RoomPowerLevelsIntField::EventsDefault.as_ref(),"room_power_levels_int_field_b809be58/as_ref/EventsDefault");
assert_eq!(RoomPowerLevelsIntField::StateDefault.as_ref().as_bytes(),tuwunel_kernel::finite_catalog::room_power_levels_int_field_b809be58::RoomPowerLevelsIntField::StateDefault.as_ref(),"room_power_levels_int_field_b809be58/as_ref/StateDefault");
assert_eq!(RoomPowerLevelsIntField::Ban.as_ref().as_bytes(),tuwunel_kernel::finite_catalog::room_power_levels_int_field_b809be58::RoomPowerLevelsIntField::Ban.as_ref(),"room_power_levels_int_field_b809be58/as_ref/Ban");
assert_eq!(RoomPowerLevelsIntField::Redact.as_ref().as_bytes(),tuwunel_kernel::finite_catalog::room_power_levels_int_field_b809be58::RoomPowerLevelsIntField::Redact.as_ref(),"room_power_levels_int_field_b809be58/as_ref/Redact");
assert_eq!(RoomPowerLevelsIntField::Kick.as_ref().as_bytes(),tuwunel_kernel::finite_catalog::room_power_levels_int_field_b809be58::RoomPowerLevelsIntField::Kick.as_ref(),"room_power_levels_int_field_b809be58/as_ref/Kick");
assert_eq!(RoomPowerLevelsIntField::Invite.as_ref().as_bytes(),tuwunel_kernel::finite_catalog::room_power_levels_int_field_b809be58::RoomPowerLevelsIntField::Invite.as_ref(),"room_power_levels_int_field_b809be58/as_ref/Invite");
}
