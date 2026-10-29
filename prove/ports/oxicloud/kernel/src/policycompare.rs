//! Per-knob strictness and ordered comparison of drive policy snapshots.
use crate::{drivepolicy::Policies, model::DriveKind};
#[derive(Clone, Copy)]
pub enum Knob {
    ForbidSharing, ForbidExternalSharing, ForbidPublicLinks, ForbidCrossDriveMove,
    ForbidOwnerRoleChange, IncludeInPhotoIndex, IncludeInMusicIndex, ReadOnly,
    MaxPublicLinkDays, RequirePublicLinkPassword, Other,
}
#[derive(Clone, Copy)]
pub enum Strictness { TrueIsStricter, FalseIsStricter, SmallerIsStricter }
pub enum KnobValue { Bool(bool), Number(u32), Null }
pub fn policy_knobs() -> Vec<Knob> {
    let mut out=Vec::new();
    out.push(Knob::ForbidSharing);out.push(Knob::ForbidExternalSharing);
    out.push(Knob::ForbidPublicLinks);out.push(Knob::ForbidCrossDriveMove);
    out.push(Knob::ForbidOwnerRoleChange);out.push(Knob::IncludeInPhotoIndex);
    out.push(Knob::IncludeInMusicIndex);out.push(Knob::ReadOnly);
    out.push(Knob::MaxPublicLinkDays);out.push(Knob::RequirePublicLinkPassword);
    out
}
pub fn non_defaultable_knobs() -> Vec<Knob> {
    let mut out=Vec::new();out.push(Knob::ReadOnly);out
}
pub fn knob_applies_to_kind(knob: Knob, kind: DriveKind) -> bool {
    match knob {
        Knob::ForbidOwnerRoleChange => match kind { DriveKind::Personal=>false, _=>true },
        _=>true,
    }
}
pub fn knob_strictness(knob: Knob) -> Strictness {
    match knob {
        Knob::IncludeInPhotoIndex|Knob::IncludeInMusicIndex=>Strictness::FalseIsStricter,
        Knob::MaxPublicLinkDays=>Strictness::SmallerIsStricter,
        _=>Strictness::TrueIsStricter,
    }
}
pub fn knob_value(p: &Policies, knob: Knob) -> KnobValue {
    match knob {
        Knob::ForbidSharing=>KnobValue::Bool(p.forbid_sharing),
        Knob::ForbidExternalSharing=>KnobValue::Bool(p.forbid_external_sharing),
        Knob::ForbidPublicLinks=>KnobValue::Bool(p.forbid_public_links),
        Knob::ForbidCrossDriveMove=>KnobValue::Bool(p.forbid_cross_drive_move),
        Knob::ForbidOwnerRoleChange=>KnobValue::Bool(p.forbid_owner_role_change),
        Knob::IncludeInPhotoIndex=>KnobValue::Bool(p.include_in_photo_index),
        Knob::IncludeInMusicIndex=>KnobValue::Bool(p.include_in_music_index),
        Knob::ReadOnly=>KnobValue::Bool(p.read_only),
        Knob::RequirePublicLinkPassword=>KnobValue::Bool(p.require_public_link_password),
        Knob::MaxPublicLinkDays=>match p.max_public_link_days {Some(n)=>KnobValue::Number(n),None=>KnobValue::Null},
        Knob::Other=>KnobValue::Null,
    }
}
pub fn knob_bool(p: &Policies, knob: Knob) -> bool {
    match knob_value(p,knob) { KnobValue::Bool(value)=>value, _=>false }
}
pub fn at_least_as_strict_on(p: &Policies, other: &Policies, knob: Knob) -> bool {
    match knob_strictness(knob) {
        Strictness::TrueIsStricter=>{let a=knob_bool(p,knob);let b=knob_bool(other,knob);a || !b},
        Strictness::FalseIsStricter=>{let a=knob_bool(p,knob);let b=knob_bool(other,knob);!a || b},
        Strictness::SmallerIsStricter=>match other.max_public_link_days {
            None=>true,
            Some(b)=>match p.max_public_link_days {None=>false,Some(a)=>a<=b},
        },
    }
}
fn append_weaker(mut out: Vec<Knob>, p: &Policies, default: &Policies, kind: DriveKind, knob: Knob) -> Vec<Knob> {
    if knob_applies_to_kind(knob,kind) {
        let defaultable=match knob { Knob::ReadOnly=>false,_=>true };
        if defaultable && !at_least_as_strict_on(p,default,knob) {out.push(knob);}
    }
    out
}
pub fn weaker_than(p: &Policies, default: &Policies, kind: DriveKind) -> Vec<Knob> {
    let mut out=Vec::new();
    out=append_weaker(out,p,default,kind,Knob::ForbidSharing);
    out=append_weaker(out,p,default,kind,Knob::ForbidExternalSharing);
    out=append_weaker(out,p,default,kind,Knob::ForbidPublicLinks);
    out=append_weaker(out,p,default,kind,Knob::ForbidCrossDriveMove);
    out=append_weaker(out,p,default,kind,Knob::ForbidOwnerRoleChange);
    out=append_weaker(out,p,default,kind,Knob::IncludeInPhotoIndex);
    out=append_weaker(out,p,default,kind,Knob::IncludeInMusicIndex);
    out=append_weaker(out,p,default,kind,Knob::ReadOnly);
    out=append_weaker(out,p,default,kind,Knob::MaxPublicLinkDays);
    append_weaker(out,p,default,kind,Knob::RequirePublicLinkPassword)
}

/// Exact canonical policy-name classification; every other spelling is Other.
pub fn knob_from_bytes(raw: &[u8]) -> Knob {
    if crate::bytes::equal(raw,b"forbid_sharing") {return Knob::ForbidSharing;}
    if crate::bytes::equal(raw,b"forbid_external_sharing") {return Knob::ForbidExternalSharing;}
    if crate::bytes::equal(raw,b"forbid_public_links") {return Knob::ForbidPublicLinks;}
    if crate::bytes::equal(raw,b"forbid_cross_drive_move") {return Knob::ForbidCrossDriveMove;}
    if crate::bytes::equal(raw,b"forbid_owner_role_change") {return Knob::ForbidOwnerRoleChange;}
    if crate::bytes::equal(raw,b"include_in_photo_index") {return Knob::IncludeInPhotoIndex;}
    if crate::bytes::equal(raw,b"include_in_music_index") {return Knob::IncludeInMusicIndex;}
    if crate::bytes::equal(raw,b"read_only") {return Knob::ReadOnly;}
    if crate::bytes::equal(raw,b"max_public_link_days") {return Knob::MaxPublicLinkDays;}
    if crate::bytes::equal(raw,b"require_public_link_password") {return Knob::RequirePublicLinkPassword;}
    Knob::Other
}
pub fn knob_applies_to_kind_bytes(raw: &[u8], kind: DriveKind) -> bool {
    knob_applies_to_kind(knob_from_bytes(raw),kind)
}
pub fn knob_strictness_bytes(raw: &[u8]) -> Strictness { knob_strictness(knob_from_bytes(raw)) }
pub fn knob_value_bytes(p: &Policies, raw: &[u8]) -> KnobValue { knob_value(p,knob_from_bytes(raw)) }
pub fn knob_bool_bytes(p: &Policies, raw: &[u8]) -> bool { knob_bool(p,knob_from_bytes(raw)) }
pub fn at_least_as_strict_on_bytes(p: &Policies, other: &Policies, raw: &[u8]) -> bool {
    at_least_as_strict_on(p,other,knob_from_bytes(raw))
}
