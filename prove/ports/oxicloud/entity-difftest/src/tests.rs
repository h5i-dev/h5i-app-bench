use oxicloud_kernel::model::*;
use crate::domain::services::authorization::{Permission as UP,Resource as UR,Subject as US};
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

pub fn usubject(s: Subject) -> US {
    match s {
        Subject::User(x) => US::User(uid(x)),
        Subject::Group(x) => US::Group(uid(x)),
        Subject::Token(x) => US::Token(uid(x)),
    }
}
pub fn uresource(r: Resource) -> UR {
    match r {
        Resource::Folder(x) => UR::Folder(uid(x)),
        Resource::File(x) => UR::File(uid(x)),
        Resource::Drive(x) => UR::Drive(uid(x)),
        Resource::Calendar(x) => UR::Calendar(uid(x)),
        Resource::AddressBook(x) => UR::AddressBook(uid(x)),
        Resource::Playlist(x) => UR::Playlist(uid(x)),
    }
}
pub fn uperm(p: Permission) -> UP {
    match p {
        Permission::Read => UP::Read,
        Permission::Create => UP::Create,
        Permission::Share => UP::Share,
        Permission::Comment => UP::Comment,
        Permission::Delete => UP::Delete,
        Permission::Update => UP::Update,
        Permission::Manage => UP::Manage,
    }
}
pub fn role_str(r: Role) -> &'static str {
    match r {
        Role::Owner => "owner",
        Role::Editor => "editor",
        Role::Contributor => "contributor",
        Role::Commenter => "commenter",
        Role::Viewer => "viewer",
    }
}

pub fn engine() -> crate::application::ports::authorization_ports::Oracle { crate::application::ports::authorization_ports::Oracle }
