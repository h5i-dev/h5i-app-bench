//! Kernel of the example app. Extracted to Lean by Aeneas (see `lean/`).
//!
//! Aeneas subset: no closures, iterators, traits, or `String`. Loops are
//! `while` over indices.

pub type Text = Vec<u8>;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Principal {
    pub org: u64,
    pub user: u64,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Role {
    Viewer,
    Editor,
    Owner,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Action {
    Read,
    Write,
    Approve,
    Manage,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Status {
    Draft,
    InReview,
    Approved,
    Published,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Project {
    pub id: u64,
    pub name: Text,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Member {
    pub project: u64,
    pub user: u64,
    pub role: Role,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Document {
    pub id: u64,
    pub project: u64,
    pub author: u64,
    pub title: Text,
    pub body: Text,
    pub status: Status,
    pub approver: Option<u64>,
    pub version: u64,
}

#[derive(Clone, Debug, PartialEq, Eq, Default)]
pub struct Counter {
    pub next_id: u64,
}

#[derive(Clone, Debug, PartialEq, Eq, Default)]
pub struct Snapshot {
    pub counter: Counter,
    pub projects: Vec<Project>,
    pub members: Vec<Member>,
    pub documents: Vec<Document>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Write {
    PutProject(Project),
    PutMember(Member),
    DelMember(u64, u64),
    PutDocument(Document),
    DelDocument(u64),
    SetCounter(Counter),
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Command {
    CreateProject { name: Text },
    SetMember { project: u64, user: u64, role: Role },
    RemoveMember { project: u64, user: u64 },
    CreateDocument { project: u64, title: Text, body: Text },
    EditDocument { doc: u64, body: Text, expected_version: u64 },
    Submit { doc: u64 },
    Approve { doc: u64 },
    Publish { doc: u64 },
    DeleteDocument { doc: u64 },
    GetDocument { doc: u64 },
    ListDocuments { project: u64 },
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Reply {
    Created(u64),
    Done,
    Version(u64),
    Doc(Document),
    Docs(Vec<Document>),
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    NotFound,
    Forbidden,
    Conflict,
    BadState,
    LastOwner,
    SelfApproval,
    Overflow,
}

/// The policy table. Proof obligations about it close by `decide`.
pub fn allows(role: Role, action: Action) -> bool {
    match role {
        Role::Owner => true,
        Role::Editor => match action {
            Action::Read => true,
            Action::Write => true,
            Action::Approve => false,
            Action::Manage => false,
        },
        Role::Viewer => match action {
            Action::Read => true,
            _ => false,
        },
    }
}

pub fn role_of(members: &Vec<Member>, project: u64, user: u64) -> Option<Role> {
    let mut i = 0;
    while i < members.len() {
        if members[i].project == project && members[i].user == user {
            return Some(members[i].role);
        }
        i += 1;
    }
    None
}

/// True if `user` may do `action` in `project`. Every command goes through this.
pub fn can(snap: &Snapshot, user: u64, project: u64, action: Action) -> bool {
    match role_of(&snap.members, project, user) {
        Some(role) => allows(role, action),
        None => false,
    }
}

pub fn project_exists(projects: &Vec<Project>, id: u64) -> bool {
    let mut i = 0;
    while i < projects.len() {
        if projects[i].id == id {
            return true;
        }
        i += 1;
    }
    false
}

pub fn find_document(docs: &Vec<Document>, id: u64) -> Option<Document> {
    let mut i = 0;
    while i < docs.len() {
        if docs[i].id == id {
            return Some(docs[i].clone());
        }
        i += 1;
    }
    None
}

pub fn count_owners(members: &Vec<Member>, project: u64) -> u64 {
    let mut n = 0;
    let mut i = 0;
    while i < members.len() {
        if members[i].project == project && members[i].role == Role::Owner {
            n += 1;
        }
        i += 1;
    }
    n
}

pub fn documents_in(docs: &Vec<Document>, project: u64) -> Vec<Document> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < docs.len() {
        if docs[i].project == project {
            out.push(docs[i].clone());
        }
        i += 1;
    }
    out
}

fn fresh_id(snap: &Snapshot) -> Result<(u64, Counter), Error> {
    let id = snap.counter.next_id;
    if id == u64::MAX {
        return Err(Error::Overflow);
    }
    Ok((id, Counter { next_id: id + 1 }))
}

/// Loads a document and checks `action` on its project.
fn authorized_doc(snap: &Snapshot, user: u64, doc: u64, action: Action) -> Result<Document, Error> {
    match find_document(&snap.documents, doc) {
        None => Err(Error::NotFound),
        Some(d) => {
            if can(snap, user, d.project, action) {
                Ok(d)
            } else {
                Err(Error::Forbidden)
            }
        }
    }
}

fn one(w: Write) -> Vec<Write> {
    let mut v = Vec::new();
    v.push(w);
    v
}

fn with_status(d: Document, status: Status, approver: Option<u64>) -> Result<Document, Error> {
    if d.version == u64::MAX {
        return Err(Error::Overflow);
    }
    Ok(Document {
        id: d.id,
        project: d.project,
        author: d.author,
        title: d.title,
        body: d.body,
        status,
        approver,
        version: d.version + 1,
    })
}

pub fn transition(actor: &Principal, snap: &Snapshot, cmd: &Command) -> Result<(Vec<Write>, Reply), Error> {
    let user = actor.user;
    match cmd {
        Command::CreateProject { name } => {
            let (id, counter) = fresh_id(snap)?;
            let mut ws = Vec::new();
            ws.push(Write::SetCounter(counter));
            ws.push(Write::PutProject(Project { id, name: name.clone() }));
            ws.push(Write::PutMember(Member { project: id, user, role: Role::Owner }));
            Ok((ws, Reply::Created(id)))
        }
        Command::SetMember { project, user: target, role } => {
            if !can(snap, user, *project, Action::Manage) {
                return Err(Error::Forbidden);
            }
            let demotes_owner = *role != Role::Owner
                && role_of(&snap.members, *project, *target) == Some(Role::Owner);
            if demotes_owner && count_owners(&snap.members, *project) <= 1 {
                return Err(Error::LastOwner);
            }
            let m = Member { project: *project, user: *target, role: *role };
            Ok((one(Write::PutMember(m)), Reply::Done))
        }
        Command::RemoveMember { project, user: target } => {
            if !can(snap, user, *project, Action::Manage) {
                return Err(Error::Forbidden);
            }
            match role_of(&snap.members, *project, *target) {
                None => Err(Error::NotFound),
                Some(r) => {
                    if r == Role::Owner && count_owners(&snap.members, *project) <= 1 {
                        return Err(Error::LastOwner);
                    }
                    Ok((one(Write::DelMember(*project, *target)), Reply::Done))
                }
            }
        }
        Command::CreateDocument { project, title, body } => {
            if !can(snap, user, *project, Action::Write) {
                return Err(Error::Forbidden);
            }
            let (id, counter) = fresh_id(snap)?;
            let d = Document {
                id,
                project: *project,
                author: user,
                title: title.clone(),
                body: body.clone(),
                status: Status::Draft,
                approver: None,
                version: 1,
            };
            let mut ws = Vec::new();
            ws.push(Write::SetCounter(counter));
            ws.push(Write::PutDocument(d));
            Ok((ws, Reply::Created(id)))
        }
        Command::EditDocument { doc, body, expected_version } => {
            let d = authorized_doc(snap, user, *doc, Action::Write)?;
            if d.version != *expected_version {
                return Err(Error::Conflict);
            }
            if d.status == Status::Published {
                return Err(Error::BadState);
            }
            let mut e = with_status(d, Status::Draft, None)?;
            e.body = body.clone();
            let v = e.version;
            Ok((one(Write::PutDocument(e)), Reply::Version(v)))
        }
        Command::Submit { doc } => {
            let d = authorized_doc(snap, user, *doc, Action::Write)?;
            if d.status != Status::Draft {
                return Err(Error::BadState);
            }
            let e = with_status(d, Status::InReview, None)?;
            let v = e.version;
            Ok((one(Write::PutDocument(e)), Reply::Version(v)))
        }
        Command::Approve { doc } => {
            let d = authorized_doc(snap, user, *doc, Action::Approve)?;
            if d.status != Status::InReview {
                return Err(Error::BadState);
            }
            if d.author == user {
                return Err(Error::SelfApproval);
            }
            let e = with_status(d, Status::Approved, Some(user))?;
            let v = e.version;
            Ok((one(Write::PutDocument(e)), Reply::Version(v)))
        }
        Command::Publish { doc } => {
            let d = authorized_doc(snap, user, *doc, Action::Write)?;
            if d.status != Status::Approved {
                return Err(Error::BadState);
            }
            let approver = d.approver;
            let e = with_status(d, Status::Published, approver)?;
            let v = e.version;
            Ok((one(Write::PutDocument(e)), Reply::Version(v)))
        }
        Command::DeleteDocument { doc } => {
            let d = authorized_doc(snap, user, *doc, Action::Manage)?;
            Ok((one(Write::DelDocument(d.id)), Reply::Done))
        }
        Command::GetDocument { doc } => {
            let d = authorized_doc(snap, user, *doc, Action::Read)?;
            Ok((Vec::new(), Reply::Doc(d)))
        }
        Command::ListDocuments { project } => {
            if !can(snap, user, *project, Action::Read) {
                return Err(Error::Forbidden);
            }
            Ok((Vec::new(), Reply::Docs(documents_in(&snap.documents, *project))))
        }
    }
}

fn put_project(v: &mut Vec<Project>, p: Project) {
    let mut i = 0;
    while i < v.len() {
        if v[i].id == p.id {
            v[i] = p;
            return;
        }
        i += 1;
    }
    v.push(p);
}

fn put_member(v: &mut Vec<Member>, m: Member) {
    let mut i = 0;
    while i < v.len() {
        if v[i].project == m.project && v[i].user == m.user {
            v[i] = m;
            return;
        }
        i += 1;
    }
    v.push(m);
}

fn put_document(v: &mut Vec<Document>, d: Document) {
    let mut i = 0;
    while i < v.len() {
        if v[i].id == d.id {
            v[i] = d;
            return;
        }
        i += 1;
    }
    v.push(d);
}

fn del_member(v: &Vec<Member>, project: u64, user: u64) -> Vec<Member> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < v.len() {
        if !(v[i].project == project && v[i].user == user) {
            out.push(v[i].clone());
        }
        i += 1;
    }
    out
}

fn del_document(v: &Vec<Document>, id: u64) -> Vec<Document> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < v.len() {
        if v[i].id != id {
            out.push(v[i].clone());
        }
        i += 1;
    }
    out
}

pub fn apply_write(s: &mut Snapshot, w: Write) {
    match w {
        Write::PutProject(p) => put_project(&mut s.projects, p),
        Write::PutMember(m) => put_member(&mut s.members, m),
        Write::DelMember(p, u) => s.members = del_member(&s.members, p, u),
        Write::PutDocument(d) => put_document(&mut s.documents, d),
        Write::DelDocument(id) => s.documents = del_document(&s.documents, id),
        Write::SetCounter(c) => s.counter = c,
    }
}

/// Meaning of a write set. The Postgres store must agree with this.
pub fn apply(snap: &Snapshot, ws: &Vec<Write>) -> Snapshot {
    let mut s = snap.clone();
    let mut i = 0;
    while i < ws.len() {
        apply_write(&mut s, ws[i].clone());
        i += 1;
    }
    s
}
