//! Conduit decisions that do not need I/O: who may change an article or
//! comment, follow and favorite transitions, field validation, slug rules,
//! and whether a response includes the article body.
//!
//! The HTTP shell loads rows, checks the JWT and the password hash, and
//! calls `transition`. Actor id 0 is a guest. User ids from PostgreSQL
//! start at 1.

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct View {
    pub actor: u64,
    pub article_exists: bool,
    pub article_author: u64,
    pub comment_exists: bool,
    pub comment_author: u64,
    pub profile_exists: bool,
    pub already: bool,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum RawText {
    Absent,
    Null,
    Invalid,
    Text(Vec<u8>),
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TagInput {
    Absent,
    Null,
    Invalid,
    List,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum RawNum {
    Absent,
    Invalid,
    Value(u64),
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Command {
    Register {
        username: RawText,
        email: RawText,
        password: RawText,
    },
    Login {
        email: RawText,
        password: RawText,
    },
    UpdateUser {
        username: RawText,
        email: RawText,
        password: RawText,
        bio: RawText,
        image: RawText,
    },
    CreateArticle {
        title: RawText,
        description: RawText,
        body: RawText,
        tags: TagInput,
    },
    UpdateArticle {
        title: RawText,
        description: RawText,
        body: RawText,
        tags: TagInput,
    },
    DeleteArticle,
    CreateComment {
        body: RawText,
    },
    DeleteComment,
    Follow,
    Unfollow,
    Favorite,
    Unfavorite,
    CurrentUser,
    Feed,
    Page {
        limit: RawNum,
        offset: RawNum,
    },
    Slug {
        title: Vec<u8>,
        n: u64,
    },
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Norm {
    Keep,
    Clear,
    Set,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum TagDecision {
    Keep,
    Replace,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Delta {
    Up,
    Same,
    Down,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Reply {
    Allow,
    UserUpdate {
        username: Norm,
        email: Norm,
        password: Norm,
        bio: Norm,
        image: Norm,
    },
    ArticleUpdate {
        title: Norm,
        description: Norm,
        body: Norm,
        tags: TagDecision,
    },
    Follow {
        following: bool,
        changed: bool,
    },
    Favorite {
        favorited: bool,
        delta: Delta,
    },
    Page {
        limit: u64,
        offset: u64,
    },
    Slug(Vec<u8>),
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    Unauthenticated,
    ForbiddenArticle,
    ForbiddenComment,
    ArticleNotFound,
    CommentNotFound,
    ProfileNotFound,
    BlankUsername,
    BlankEmail,
    BlankPassword,
    BlankTitle,
    BlankDescription,
    BlankBody,
    ShortPassword,
    InvalidUsername,
    InvalidEmail,
    InvalidPassword,
    InvalidBio,
    InvalidImage,
    InvalidTitle,
    InvalidDescription,
    InvalidBody,
    InvalidTags,
    InvalidUser,
    InvalidArticle,
    InvalidLimit,
    InvalidOffset,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum ArticleView {
    List,
    Detail,
}

/// List responses omit `body`. Detail responses include it.
pub fn shows_body(view: ArticleView) -> bool {
    match view {
        ArticleView::List => false,
        ArticleView::Detail => true,
    }
}

fn authed(cmd: &Command) -> bool {
    match cmd {
        Command::Register { .. }
        | Command::Login { .. }
        | Command::Page { .. }
        | Command::Slug { .. } => false,
        Command::UpdateUser { .. }
        | Command::CreateArticle { .. }
        | Command::UpdateArticle { .. }
        | Command::DeleteArticle
        | Command::CreateComment { .. }
        | Command::DeleteComment
        | Command::Follow
        | Command::Unfollow
        | Command::Favorite
        | Command::Unfavorite
        | Command::CurrentUser
        | Command::Feed => true,
    }
}

fn require_text(field: &RawText, blank: Error, invalid: Error) -> Result<(), Error> {
    match field {
        RawText::Text(v) => {
            if v.len() == 0 {
                Err(blank)
            } else {
                Ok(())
            }
        }
        RawText::Invalid => Err(invalid),
        RawText::Absent | RawText::Null => Err(blank),
    }
}

fn password_new(field: &RawText) -> Result<(), Error> {
    match field {
        RawText::Text(v) => {
            if v.len() == 0 {
                Err(Error::BlankPassword)
            } else if v.len() < 8 {
                Err(Error::ShortPassword)
            } else {
                Ok(())
            }
        }
        RawText::Invalid => Err(Error::InvalidPassword),
        RawText::Absent | RawText::Null => Err(Error::BlankPassword),
    }
}

fn password_login(field: &RawText) -> Result<(), Error> {
    match field {
        RawText::Text(v) => {
            if v.len() == 0 {
                Err(Error::BlankPassword)
            } else {
                Ok(())
            }
        }
        RawText::Invalid => Err(Error::InvalidPassword),
        RawText::Absent | RawText::Null => Err(Error::BlankPassword),
    }
}

fn password_update(field: &RawText) -> Result<Norm, Error> {
    match field {
        RawText::Absent => Ok(Norm::Keep),
        RawText::Null => Err(Error::BlankPassword),
        RawText::Invalid => Err(Error::InvalidPassword),
        RawText::Text(v) => {
            if v.len() == 0 {
                Err(Error::BlankPassword)
            } else if v.len() < 8 {
                Err(Error::ShortPassword)
            } else {
                Ok(Norm::Set)
            }
        }
    }
}

fn optional_required(field: &RawText, blank: Error, invalid: Error) -> Result<Norm, Error> {
    match field {
        RawText::Absent => Ok(Norm::Keep),
        RawText::Null => Err(blank),
        RawText::Invalid => Err(invalid),
        RawText::Text(v) => {
            if v.len() == 0 {
                Err(blank)
            } else {
                Ok(Norm::Set)
            }
        }
    }
}

fn optional_clear(field: &RawText, invalid: Error) -> Result<Norm, Error> {
    match field {
        RawText::Absent => Ok(Norm::Keep),
        RawText::Null => Ok(Norm::Clear),
        RawText::Invalid => Err(invalid),
        RawText::Text(v) => {
            if v.len() == 0 {
                Ok(Norm::Clear)
            } else {
                Ok(Norm::Set)
            }
        }
    }
}

fn tags_of(tags: &TagInput) -> Result<TagDecision, Error> {
    match tags {
        TagInput::Absent => Ok(TagDecision::Keep),
        TagInput::List => Ok(TagDecision::Replace),
        TagInput::Null | TagInput::Invalid => Err(Error::InvalidTags),
    }
}

fn register(username: &RawText, email: &RawText, password: &RawText) -> Result<Reply, Error> {
    match require_text(username, Error::BlankUsername, Error::InvalidUsername) {
        Ok(()) => {}
        Err(e) => return Err(e),
    }
    match require_text(email, Error::BlankEmail, Error::InvalidEmail) {
        Ok(()) => {}
        Err(e) => return Err(e),
    }
    match password_new(password) {
        Ok(()) => Ok(Reply::Allow),
        Err(e) => Err(e),
    }
}

fn login(email: &RawText, password: &RawText) -> Result<Reply, Error> {
    match require_text(email, Error::BlankEmail, Error::InvalidEmail) {
        Ok(()) => {}
        Err(e) => return Err(e),
    }
    match password_login(password) {
        Ok(()) => Ok(Reply::Allow),
        Err(e) => Err(e),
    }
}

fn update_user(
    username: &RawText,
    email: &RawText,
    password: &RawText,
    bio: &RawText,
    image: &RawText,
) -> Result<Reply, Error> {
    let username = match optional_required(username, Error::BlankUsername, Error::InvalidUsername) {
        Ok(v) => v,
        Err(e) => return Err(e),
    };
    let email = match optional_required(email, Error::BlankEmail, Error::InvalidEmail) {
        Ok(v) => v,
        Err(e) => return Err(e),
    };
    let password = match password_update(password) {
        Ok(v) => v,
        Err(e) => return Err(e),
    };
    let bio = match optional_clear(bio, Error::InvalidBio) {
        Ok(v) => v,
        Err(e) => return Err(e),
    };
    let image = match optional_clear(image, Error::InvalidImage) {
        Ok(v) => v,
        Err(e) => return Err(e),
    };
    if username == Norm::Keep
        && email == Norm::Keep
        && password == Norm::Keep
        && bio == Norm::Keep
        && image == Norm::Keep
    {
        return Err(Error::InvalidUser);
    }
    Ok(Reply::UserUpdate {
        username,
        email,
        password,
        bio,
        image,
    })
}

fn create_article(
    title: &RawText,
    description: &RawText,
    body: &RawText,
    tags: &TagInput,
) -> Result<Reply, Error> {
    match require_text(title, Error::BlankTitle, Error::InvalidTitle) {
        Ok(()) => {}
        Err(e) => return Err(e),
    }
    match require_text(description, Error::BlankDescription, Error::InvalidDescription) {
        Ok(()) => {}
        Err(e) => return Err(e),
    }
    match require_text(body, Error::BlankBody, Error::InvalidBody) {
        Ok(()) => {}
        Err(e) => return Err(e),
    }
    match tags {
        TagInput::Absent | TagInput::List => Ok(Reply::Allow),
        TagInput::Null | TagInput::Invalid => Err(Error::InvalidTags),
    }
}

fn update_article(
    view: &View,
    title: &RawText,
    description: &RawText,
    body: &RawText,
    tags: &TagInput,
) -> Result<Reply, Error> {
    let title = match optional_required(title, Error::BlankTitle, Error::InvalidTitle) {
        Ok(v) => v,
        Err(e) => return Err(e),
    };
    let description = match optional_required(description, Error::BlankDescription, Error::InvalidDescription) {
        Ok(v) => v,
        Err(e) => return Err(e),
    };
    let body = match optional_required(body, Error::BlankBody, Error::InvalidBody) {
        Ok(v) => v,
        Err(e) => return Err(e),
    };
    let tags = match tags_of(tags) {
        Ok(v) => v,
        Err(e) => return Err(e),
    };
    if title == Norm::Keep && description == Norm::Keep && body == Norm::Keep && tags == TagDecision::Keep {
        return Err(Error::InvalidArticle);
    }
    if !view.article_exists {
        return Err(Error::ArticleNotFound);
    }
    if view.article_author != view.actor {
        return Err(Error::ForbiddenArticle);
    }
    Ok(Reply::ArticleUpdate {
        title,
        description,
        body,
        tags,
    })
}

fn delete_article(view: &View) -> Result<Reply, Error> {
    if !view.article_exists {
        return Err(Error::ArticleNotFound);
    }
    if view.article_author != view.actor {
        return Err(Error::ForbiddenArticle);
    }
    Ok(Reply::Allow)
}

fn create_comment(view: &View, body: &RawText) -> Result<Reply, Error> {
    match require_text(body, Error::BlankBody, Error::InvalidBody) {
        Ok(()) => {}
        Err(e) => return Err(e),
    }
    if !view.article_exists {
        return Err(Error::ArticleNotFound);
    }
    Ok(Reply::Allow)
}

fn delete_comment(view: &View) -> Result<Reply, Error> {
    if !view.article_exists {
        return Err(Error::ArticleNotFound);
    }
    if !view.comment_exists {
        return Err(Error::CommentNotFound);
    }
    if view.comment_author != view.actor {
        return Err(Error::ForbiddenComment);
    }
    Ok(Reply::Allow)
}

fn follow(view: &View, on: bool) -> Result<Reply, Error> {
    if !view.profile_exists {
        return Err(Error::ProfileNotFound);
    }
    if on {
        Ok(Reply::Follow {
            following: true,
            changed: !view.already,
        })
    } else {
        Ok(Reply::Follow {
            following: false,
            changed: view.already,
        })
    }
}

fn favorite(view: &View, on: bool) -> Result<Reply, Error> {
    if !view.article_exists {
        return Err(Error::ArticleNotFound);
    }
    if on {
        if view.already {
            Ok(Reply::Favorite {
                favorited: true,
                delta: Delta::Same,
            })
        } else {
            Ok(Reply::Favorite {
                favorited: true,
                delta: Delta::Up,
            })
        }
    } else if view.already {
        Ok(Reply::Favorite {
            favorited: false,
            delta: Delta::Down,
        })
    } else {
        Ok(Reply::Favorite {
            favorited: false,
            delta: Delta::Same,
        })
    }
}

fn page(limit: &RawNum, offset: &RawNum) -> Result<Reply, Error> {
    let limit_n = match limit {
        RawNum::Absent => 20,
        RawNum::Invalid => return Err(Error::InvalidLimit),
        RawNum::Value(n) => {
            if *n < 1 {
                return Err(Error::InvalidLimit);
            } else if *n > 100 {
                100
            } else {
                *n
            }
        }
    };
    let offset_n = match offset {
        RawNum::Absent => 0,
        RawNum::Invalid => return Err(Error::InvalidOffset),
        RawNum::Value(n) => *n,
    };
    Ok(Reply::Page {
        limit: limit_n,
        offset: offset_n,
    })
}

fn lower_ascii(c: u8) -> u8 {
    match c {
        b'A' => b'a',
        b'B' => b'b',
        b'C' => b'c',
        b'D' => b'd',
        b'E' => b'e',
        b'F' => b'f',
        b'G' => b'g',
        b'H' => b'h',
        b'I' => b'i',
        b'J' => b'j',
        b'K' => b'k',
        b'L' => b'l',
        b'M' => b'm',
        b'N' => b'n',
        b'O' => b'o',
        b'P' => b'p',
        b'Q' => b'q',
        b'R' => b'r',
        b'S' => b's',
        b'T' => b't',
        b'U' => b'u',
        b'V' => b'v',
        b'W' => b'w',
        b'X' => b'x',
        b'Y' => b'y',
        b'Z' => b'z',
        _ => c,
    }
}

fn is_alnum(c: u8) -> bool {
    (c >= b'a' && c <= b'z') || (c >= b'0' && c <= b'9')
}

fn is_sep(c: u8) -> bool {
    c == b' ' || c == b'\t' || c == b'\n' || c == b'\r' || c == b'-' || c == b'_'
}

fn push_article(out: &mut Vec<u8>) {
    out.push(b'a');
    out.push(b'r');
    out.push(b't');
    out.push(b'i');
    out.push(b'c');
    out.push(b'l');
    out.push(b'e');
}

fn slug_base(title: &Vec<u8>) -> Vec<u8> {
    let mut out: Vec<u8> = Vec::new();
    let mut i: usize = 0;
    // A separator is remembered and emitted only before the next letter,
    // so the slug never starts or ends with a hyphen and never doubles one.
    let mut pending_hyphen = false;
    while i < title.len() {
        let c = lower_ascii(title[i]);
        if is_alnum(c) {
            if pending_hyphen && out.len() > 0 {
                out.push(b'-');
            }
            out.push(c);
            pending_hyphen = false;
        } else if is_sep(c) && out.len() > 0 {
            pending_hyphen = true;
        }
        i += 1;
    }
    if out.len() == 0 {
        push_article(&mut out);
    }
    out
}

fn digit(n: u64) -> u8 {
    match n {
        0 => b'0',
        1 => b'1',
        2 => b'2',
        3 => b'3',
        4 => b'4',
        5 => b'5',
        6 => b'6',
        7 => b'7',
        8 => b'8',
        _ => b'9',
    }
}

fn push_u64(out: &mut Vec<u8>, mut n: u64) {
    if n == 0 {
        out.push(b'0');
        return;
    }
    let mut rev: Vec<u8> = Vec::new();
    let mut guard: u64 = 0;
    while n > 0 && guard < 20 {
        let rem = n % 10;
        rev.push(digit(rem));
        n = n / 10;
        guard = guard + 1;
    }
    let mut i = rev.len();
    while i > 0 {
        i -= 1;
        out.push(rev[i]);
    }
}

/// ASCII slug. `n == 0` is the base slug; a later `n` appends `-n`.
pub fn make_slug(title: &Vec<u8>, n: u64) -> Vec<u8> {
    let mut out = slug_base(title);
    if n > 0 {
        out.push(b'-');
        push_u64(&mut out, n);
    }
    out
}

pub fn transition(view: &View, cmd: &Command) -> Result<Reply, Error> {
    if authed(cmd) && view.actor == 0 {
        return Err(Error::Unauthenticated);
    }
    match cmd {
        Command::Register {
            username,
            email,
            password,
        } => register(username, email, password),
        Command::Login { email, password } => login(email, password),
        Command::UpdateUser {
            username,
            email,
            password,
            bio,
            image,
        } => update_user(username, email, password, bio, image),
        Command::CreateArticle {
            title,
            description,
            body,
            tags,
        } => create_article(title, description, body, tags),
        Command::UpdateArticle {
            title,
            description,
            body,
            tags,
        } => update_article(view, title, description, body, tags),
        Command::DeleteArticle => delete_article(view),
        Command::CreateComment { body } => create_comment(view, body),
        Command::DeleteComment => delete_comment(view),
        Command::Follow => follow(view, true),
        Command::Unfollow => follow(view, false),
        Command::Favorite => favorite(view, true),
        Command::Unfavorite => favorite(view, false),
        Command::CurrentUser | Command::Feed => Ok(Reply::Allow),
        Command::Page { limit, offset } => page(limit, offset),
        Command::Slug { title, n } => Ok(Reply::Slug(make_slug(title, *n))),
    }
}
