//! Share snapshots, password requirements, token updates, and access accounting.
use oxicloud::domain::entities::share as upstream;
use oxicloud_kernel::share as port;
use uuid::Uuid;
use crate::tests::Rng;
fn item(t: port::ShareItemType) -> upstream::ShareItemType {
    match t { port::ShareItemType::File => upstream::ShareItemType::File,
        port::ShareItemType::Folder => upstream::ShareItemType::Folder }
}
fn text(rng: &mut Rng) -> String {
    let alphabet = ['a', 'Z', '\0', 'é', '世', '🦀', '-', '_', ' '];
    (0..rng.below(24)).map(|_| rng.pick(&alphabet)).collect()
}
fn optional(rng: &mut Rng) -> Option<String> {
    if rng.below(2) == 0 { None } else { Some(text(rng)) }
}
fn check(p: &port::Share, u: &upstream::Share) {
    assert_eq!(Uuid::from_u128(port::id(p)), u.id());
    assert_eq!(port::item_id(p), u.item_id().as_bytes());
    assert_eq!(port::item_name(p).as_deref(), u.item_name().map(str::as_bytes));
    assert_eq!(&item(*port::item_type(p)), u.item_type());
    assert_eq!(port::token(p), u.token().as_bytes());
    assert_eq!(port::password_hash(p).as_deref(), u.password_hash().map(str::as_bytes));
    assert_eq!(port::has_password(p), u.has_password());
    assert_eq!(port::expires_at(p), u.expires_at());
    assert_eq!(port::created_at(p), u.created_at());
    assert_eq!(Uuid::from_u128(port::created_by(p)), u.created_by());
    assert_eq!(port::access_count(p), u.access_count());
}
#[test]
fn sharing_state_differential() {
    let mut rng = Rng(0x46db_ca59_206f_113d);
    for trial in 0..10_000 {
        let id = (u128::from(rng.next()) << 64) | u128::from(rng.next());
        let creator = (u128::from(rng.next()) << 64) | u128::from(rng.next());
        let item_id = text(&mut rng); let name = optional(&mut rng);
        let kind = if rng.below(2) == 0 { port::ShareItemType::File } else { port::ShareItemType::Folder };
        let token = text(&mut rng); let hash = optional(&mut rng);
        let expiry = match trial % 4 { 0 => None, 1 => Some(0), 2 => Some(u64::MAX), _ => Some(rng.next()) };
        let created = rng.next(); let count = rng.next();
        let mut p = port::from_raw(id, item_id.as_bytes().to_vec(), name.as_ref().map(|s| s.as_bytes().to_vec()),
            kind, token.as_bytes().to_vec(), hash.as_ref().map(|s| s.as_bytes().to_vec()), expiry, created, creator, count);
        let mut u = upstream::Share::from_raw(Uuid::from_u128(id), item_id, name, item(kind), token, hash,
            expiry, created, Uuid::from_u128(creator), count);
        check(&p, &u);
        for hash in [None, Some(String::new()), Some(text(&mut rng))] {
            p = port::with_password(p, hash.as_ref().map(|s| s.as_bytes().to_vec()));
            u = u.with_password(hash); check(&p, &u);
        }
        let token = text(&mut rng);
        p = port::with_token(p, token.as_bytes().to_vec()); u = u.with_token(token); check(&p, &u);
        if count < u64::MAX {
            p = port::increment_access_count(p); u = u.increment_access_count(); check(&p, &u);
        }
    }
    let p = port::from_raw(0, Vec::new(), None, port::ShareItemType::File, Vec::new(), None, None, 0, 0, u64::MAX);
    let u = upstream::Share::from_raw(Uuid::nil(), String::new(), None, upstream::ShareItemType::File,
        String::new(), None, None, 0, Uuid::nil(), u64::MAX);
    assert!(std::panic::catch_unwind(|| port::increment_access_count(p)).is_err());
    assert!(std::panic::catch_unwind(|| u.increment_access_count()).is_err());
}
