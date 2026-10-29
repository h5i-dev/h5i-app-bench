//! Canonical authorization discriminators, identity projections, and enumeration order.
use oxicloud::domain::services::authorization as upstream;
use oxicloud_kernel::{authwire as port, model::*};
use crate::tests::{uid, usubject, uresource, uperm, role_str, Rng};

fn check_raw(raw: &str, id: u64) {
    assert_eq!(port::subject_parse(raw.as_bytes(), id).map(usubject),
        upstream::Subject::from_parts(raw, uid(id)));
    assert_eq!(port::resource_parse(raw.as_bytes(), id).map(uresource),
        upstream::Resource::from_parts(raw, uid(id)));
    assert_eq!(port::permission_parse(raw.as_bytes()).map(uperm),
        upstream::Permission::parse(raw));
    assert_eq!(port::role_parse(raw.as_bytes()).map(role_str),
        upstream::Role::parse(raw).map(|r| r.as_str()));
}

#[test]
fn authorization_wire_differential() {
    assert_eq!(port::permission_all().into_iter().map(uperm).collect::<Vec<_>>(), upstream::Permission::ALL);
    assert_eq!(port::role_all().into_iter().map(role_str).collect::<Vec<_>>(),
        upstream::Role::ALL.map(|r| r.as_str()));
    let words = ["user", "group", "token", "folder", "file", "drive", "calendar", "address_book",
        "playlist", "read", "create", "share", "comment", "delete", "update", "manage", "viewer",
        "commenter", "contributor", "editor", "owner", "admin", "external", "", "User", "read\0", "管理员"];
    let mut rng = Rng(0x73c9_e438_82d7_0125);
    for trial in 0..10_000 {
        let id = match trial { 0 => 0, 1 => u64::MAX, _ => rng.next() };
        for s in [Subject::User(id), Subject::Group(id), Subject::Token(id)] {
            let u = usubject(s);
            assert_eq!(port::subject_bytes(s), u.type_str().as_bytes());
            assert_eq!(uid(port::subject_id(s)), u.id());
            assert_eq!(port::subject_user_id(s).map(uid), u.user_id());
            assert_eq!(port::subject_token_id(s).map(uid), u.token_id());
        }
        for r in [Resource::Folder(id), Resource::File(id), Resource::Drive(id),
            Resource::Calendar(id), Resource::AddressBook(id), Resource::Playlist(id)] {
            let u = uresource(r);
            assert_eq!(port::resource_bytes(r), u.type_str().as_bytes());
            assert_eq!(uid(port::resource_id(r)), u.id());
        }
        for p in port::permission_all() { assert_eq!(port::permission_bytes(p), uperm(p).as_str().as_bytes()); }
        for r in port::role_all() { assert_eq!(port::role_bytes(r), role_str(r).as_bytes()); }
        for raw in words { check_raw(raw, id); }
        let mut raw = rng.pick(&words).as_bytes().to_vec();
        if !raw.is_empty() && raw.is_ascii() {
            let index = rng.below(raw.len() as u64) as usize;
            raw[index] = rng.below(128) as u8;
            check_raw(std::str::from_utf8(&raw).unwrap(), id);
        }
        let mut raw = String::new();
        for _ in 0..rng.below(24) {
            if let Some(c) = char::from_u32(rng.below(0x11_0000) as u32) { raw.push(c); }
        }
        check_raw(&raw, id);
    }
}
