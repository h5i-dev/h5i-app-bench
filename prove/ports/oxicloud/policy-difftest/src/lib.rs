// The entire pinned drive.rs is compiled unchanged. Only the error constructor
// and authorization Subject carrier are adapters; decision logic and audit calls
// remain upstream code. No database or policy JSON parsing equivalence is claimed.
pub mod common { pub mod errors {
    #[derive(Debug)] pub enum ErrorKind { UnsupportedOperation }
    #[derive(Debug)] pub struct DomainError { pub kind: ErrorKind, message: String }
    impl DomainError { pub fn operation_not_supported(_: &str, message: &str) -> Self {
        Self { kind: ErrorKind::UnsupportedOperation, message: message.into() }
    } }
    impl std::fmt::Display for DomainError {
        fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result { self.message.fmt(f) }
    }
} }
pub mod domain {
    pub mod services { pub mod authorization {
        #[derive(Debug, Clone, Copy)] pub enum Subject {
            User(uuid::Uuid), Group(uuid::Uuid), Token(uuid::Uuid),
        }
    } }
    pub mod entities { include!(concat!(env!("OUT_DIR"), "/entities.rs")); }
}
#[cfg(test)]
mod tests {
use uuid::Uuid;
pub struct Rng(pub u64);
impl Rng {
    pub fn next(&mut self) -> u64 {
        self.0 ^= self.0 >> 12;
        self.0 ^= self.0 << 25;
        self.0 ^= self.0 >> 27;
        self.0.wrapping_mul(0x2545F4914F6CDD1D)
    }
    pub fn below(&mut self, n: u64) -> u64 {
        self.next() % n
    }
    pub fn chance(&mut self, pct: u64) -> bool {
        self.below(100) < pct
    }
    pub fn pick<T: Copy>(&mut self, xs: &[T]) -> T {
        xs[self.below(xs.len() as u64) as usize]
    }
}

pub fn uid(n: u64) -> Uuid {
    Uuid::from_u128(n as u128)
}

fn usubject(s: Subject) -> crate::domain::services::authorization::Subject {
    use crate::domain::services::authorization::Subject as U;
    match s { Subject::User(x)=>U::User(uid(x)), Subject::Group(x)=>U::Group(uid(x)), Subject::Token(x)=>U::Token(uid(x)) }
}
// Full policy defaults, explicit overrides, and sharing guard behavior.
use crate::domain::entities::drive as upstream;
use oxicloud_kernel::{drivepolicy as port, model::*};


fn gate_result(r: Result<(), crate::common::errors::DomainError>) -> Result<(), ErrorKind> {
    r.map_err(|e| {
        assert!(matches!(e.kind, crate::common::errors::ErrorKind::UnsupportedOperation));
        ErrorKind::OperationNotSupported
    })
}

fn policies(rng: &mut Rng) -> port::Policies {
    port::Policies {
        forbid_sharing: rng.chance(50),
        forbid_external_sharing: rng.chance(50),
        forbid_public_links: rng.chance(50),
        forbid_cross_drive_move: rng.chance(50),
        forbid_owner_role_change: rng.chance(50),
        include_in_photo_index: rng.chance(50),
        include_in_music_index: rng.chance(50),
        read_only: rng.chance(50),
        require_public_link_password: rng.chance(50),
        max_public_link_days: if rng.chance(50) { Some(rng.next() as u32) } else { None },
    }
}
fn original(p: port::Policies) -> upstream::DrivePolicies {
    upstream::DrivePolicies {
        forbid_sharing: p.forbid_sharing,
        forbid_external_sharing: p.forbid_external_sharing,
        forbid_public_links: p.forbid_public_links,
        forbid_cross_drive_move: p.forbid_cross_drive_move,
        forbid_owner_role_change: p.forbid_owner_role_change,
        include_in_photo_index: p.include_in_photo_index,
        include_in_music_index: p.include_in_music_index,
        read_only: p.read_only,
        require_public_link_password: p.require_public_link_password,
        max_public_link_days: p.max_public_link_days,
    }
}
fn overrides(rng: &mut Rng) -> port::Overrides {
    port::Overrides {
        forbid_sharing: if rng.chance(50) { Some(rng.chance(50)) } else { None },
        forbid_external_sharing: if rng.chance(50) { Some(rng.chance(50)) } else { None },
        forbid_public_links: if rng.chance(50) { Some(rng.chance(50)) } else { None },
        forbid_cross_drive_move: if rng.chance(50) { Some(rng.chance(50)) } else { None },
        forbid_owner_role_change: if rng.chance(50) { Some(rng.chance(50)) } else { None },
        include_in_photo_index: if rng.chance(50) { Some(rng.chance(50)) } else { None },
        include_in_music_index: if rng.chance(50) { Some(rng.chance(50)) } else { None },
        read_only: if rng.chance(50) { Some(rng.chance(50)) } else { None },
        require_public_link_password: if rng.chance(50) { Some(rng.chance(50)) } else { None },
        max_public_link_days: if rng.chance(50) { Some(rng.next() as u32) } else { None },
    }
}
fn original_overrides(p: port::Overrides) -> upstream::DrivePolicyOverrides {
    upstream::DrivePolicyOverrides {
        forbid_sharing: p.forbid_sharing,
        forbid_external_sharing: p.forbid_external_sharing,
        forbid_public_links: p.forbid_public_links,
        forbid_cross_drive_move: p.forbid_cross_drive_move,
        forbid_owner_role_change: p.forbid_owner_role_change,
        include_in_photo_index: p.include_in_photo_index,
        include_in_music_index: p.include_in_music_index,
        read_only: p.read_only,
        require_public_link_password: p.require_public_link_password,
        max_public_link_days: p.max_public_link_days,
    }
}

#[test]
fn drive_policy_differential() {
    let mut rng = Rng(0xb29c_47de_851a_0643);
    for trial in 0..10_000 {
        let mut p = policies(&mut rng);
        let mut o = overrides(&mut rng);
        if trial < 8 {
            p.max_public_link_days = [None, Some(0), Some(1), Some(u32::MAX)][trial % 4];
            o.max_public_link_days = [None, Some(0), Some(1), Some(u32::MAX)][trial / 2];
        }
        let up = original(p);
        let got = port::resolve(&p, &o);
        assert_eq!(original(got), upstream::DrivePolicies::resolve(&up, &original_overrides(o)));
        let caller = uid(rng.next());
        let item = uid(rng.next());
        let public = upstream::PublicLinkGateContext { caller_id: caller, item_type: "file", item_id: item };
        let sharing = upstream::SharingGateContext { caller_id: caller, resource_type: "file", resource_id: item };
        let cross = upstream::CrossDriveMoveGateContext { caller_id: caller, resource_type: "file", resource_id: item, src_drive_id: uid(rng.next()), dst_drive_id: uid(rng.next()) };
        assert_eq!(port::refuse_public_links(&p), gate_result(up.refuse_public_links(public)));
        assert_eq!(port::refuse_sharing(&p), gate_result(up.refuse_sharing(sharing)));
        assert_eq!(port::refuse_cross_drive_move(&p), gate_result(up.refuse_cross_drive_move(cross)));
        for admin in [false, true] {
            let owner = upstream::OwnerRoleChangeGateContext { caller_id: caller, caller_is_admin: admin, drive_id: item, operation: "set_member_role", subject_type: "user", subject_id: uid(rng.next()) };
            assert_eq!(port::refuse_owner_role_change(&p, admin), gate_result(up.refuse_owner_role_change(owner)));
        }
        let id = rng.next();
        for s in [Subject::User(id), Subject::Group(id), Subject::Token(id)] {
            for external in [false, true] {
                let ctx = upstream::ExternalSharingGateContext { caller_id: caller, stage: "drive_member", drive_id: Some(item), resource_type: None, resource_id: None };
                assert_eq!(port::refuse_external_sharing(&p, s, external), gate_result(up.refuse_external_sharing(usubject(s), external, ctx)));
            }
        }
    }
}

#[test]
fn policy_comparison_differential() {
    use oxicloud_kernel::policycompare as pc;
    fn name(k: pc::Knob) -> &'static str { match k {
        pc::Knob::ForbidSharing=>"forbid_sharing",pc::Knob::ForbidExternalSharing=>"forbid_external_sharing",
        pc::Knob::ForbidPublicLinks=>"forbid_public_links",pc::Knob::ForbidCrossDriveMove=>"forbid_cross_drive_move",
        pc::Knob::ForbidOwnerRoleChange=>"forbid_owner_role_change",pc::Knob::IncludeInPhotoIndex=>"include_in_photo_index",
        pc::Knob::IncludeInMusicIndex=>"include_in_music_index",pc::Knob::ReadOnly=>"read_only",
        pc::Knob::MaxPublicLinkDays=>"max_public_link_days",pc::Knob::RequirePublicLinkPassword=>"require_public_link_password",pc::Knob::Other=>"unrecognized_knob",
    } }
    assert_eq!(pc::policy_knobs().into_iter().map(name).collect::<Vec<_>>(),upstream::POLICY_KNOBS);
    assert_eq!(pc::non_defaultable_knobs().into_iter().map(name).collect::<Vec<_>>(),upstream::NON_DEFAULTABLE_KNOBS);
    let mut rng=Rng(0xb349_91c3_4452_195a);
    for trial in 0..10_000 {
        let mut p=policies(&mut rng);let mut q=policies(&mut rng);
        if trial<16 {p.max_public_link_days=[None,Some(0),Some(1),Some(u32::MAX)][trial%4];q.max_public_link_days=[None,Some(0),Some(1),Some(u32::MAX)][trial/4];}
        let up=original(p);let uq=original(q);
        let mut knobs=pc::policy_knobs();knobs.push(pc::Knob::Other);
        for k in knobs {
            let n=name(k);
            let v=match pc::knob_value(&p,k) {pc::KnobValue::Bool(b)=>serde_json::Value::Bool(b),pc::KnobValue::Number(v)=>serde_json::Value::from(v),pc::KnobValue::Null=>serde_json::Value::Null};
            assert_eq!(v,up.knob_value(n));
            assert_eq!(pc::knob_bool(&p,k),matches!(up.knob_value(n),serde_json::Value::Bool(true)));
            let st=match pc::knob_strictness(k) {pc::Strictness::TrueIsStricter=>upstream::Strictness::TrueIsStricter,pc::Strictness::FalseIsStricter=>upstream::Strictness::FalseIsStricter,pc::Strictness::SmallerIsStricter=>upstream::Strictness::SmallerIsStricter};
            assert_eq!(st,upstream::knob_strictness(n));
            assert_eq!(pc::at_least_as_strict_on(&p,&q,k),up.at_least_as_strict_on(&uq,n));
            for (kind,ukind) in [(DriveKind::Personal,upstream::DriveKind::Personal),(DriveKind::Shared,upstream::DriveKind::Shared)] {
                assert_eq!(pc::knob_applies_to_kind(k,kind),upstream::knob_applies_to_kind(n,ukind));
            }
        }
        for (kind,ukind) in [(DriveKind::Personal,upstream::DriveKind::Personal),(DriveKind::Shared,upstream::DriveKind::Shared)] {
            assert_eq!(pc::weaker_than(&p,&q,kind).into_iter().map(name).collect::<Vec<_>>(),up.weaker_than(&uq,ukind));
        }
    }
}
}
