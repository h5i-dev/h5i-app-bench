//! The linkding REST API (bookmarks, tags, bundles, the user profile) as an
//! h5i-app kernel.
//!
//! The caller is an API token, not a user id: `actor` resolves it against the
//! token table the read plan loads, so authentication is the kernel's too. An
//! empty token is a guest.
//!
//! Field validation, URL normalization, tag-string parsing, date parsing and
//! the clock stay in the shell, which passes their results in commands.
//! Search (`search::parse_search`, `search::bookmark_matches`), visibility,
//! ownership, duplicate URLs, tag creation, bundle filters, ordering, paging
//! and counts are decided here.
//!
//! A bookmark's key is `(owner, added, id)`, so one owner's bookmarks load
//! newest first by key: a plain listing reads only the page it shows. Text
//! search, date filters, `!untagged`, `not`, the other sort orders, bundles
//! and the shared list read the owner's (or every sharing user's) bookmarks
//! and filter them here.

pub mod search;

pub use search::*;

pub type Text = Vec<u8>;

/// A caller: the API token it presented, empty for a guest.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Principal {
    pub org: u64,
    pub token: Text,
}

h5i_app_schema::schema! {
    mapping linkding_tables for linkding_kernel, writes Write, lean "../proofs/generated/Schema.lean";

    /// The whole site. linkding has a single tenant.
    #[derive(Clone, Debug, Default, PartialEq, Eq)]
    pub struct Snapshot {
        counter: Counter,
        users: Vec<User>,
        tokens: Vec<Token>,
        bookmarks: Vec<Bookmark>,
        tags: Vec<Tag>,
        links: Vec<Link>,
        bundles: Vec<Bundle>,
    }

    /// A user and their profile settings. `search_prefs` is JSON text.
    #[derive(Clone, Debug, PartialEq, Eq)]
    pub struct User in "linkding_users" {
        key { id: u64 }
        username: Text,
        theme: Text,
        date_display: Text,
        link_target: Text,
        web_archive: Text,
        lax: bool,
        sharing: bool,
        public_sharing: bool,
        favicons: bool,
        display_url: bool,
        permanent_notes: bool,
        search_prefs: Text,
        legacy: bool,
    }

    #[derive(Clone, Debug, PartialEq, Eq)]
    pub struct Token in "linkding_tokens" {
        key { key: Text }
        user: u64,
    }

    /// Times are microseconds since 1970.
    #[derive(Clone, Debug, PartialEq, Eq)]
    pub struct Bookmark in "linkding_bookmarks" {
        key { owner: u64, added: u64, id: u64 }
        url: Text,
        url_norm: Text,
        title: Text,
        description: Text,
        notes: Text,
        unread: bool,
        archived: bool,
        shared: bool,
        modified: u64,
    }

    /// `name_lower` is `name` with ASCII letters lowercased, set here.
    #[derive(Clone, Debug, PartialEq, Eq)]
    pub struct Tag in "linkding_tags" {
        key { id: u64 }
        owner: u64,
        name: Text,
        name_lower: Text,
        added: u64,
    }

    /// Bookmark `bookmark` has tag `tag`.
    #[derive(Clone, Copy, Debug, PartialEq, Eq)]
    pub struct Link in "linkding_bookmark_tags" {
        key { bookmark: u64, tag: u64 }
    }

    /// `order` is the bundle's position plus `ORDER_BIAS`, so negative
    /// positions fit an unsigned column.
    #[derive(Clone, Debug, PartialEq, Eq)]
    pub struct Bundle in "linkding_bundles" {
        key { id: u64 }
        owner: u64,
        name: Text,
        search: Text,
        any_tags: Text,
        all_tags: Text,
        excluded_tags: Text,
        filter_unread: Text,
        filter_shared: Text,
        order: u64,
        created: u64,
        modified: u64,
    }

    /// The last id handed out per table; ids start at 1.
    #[derive(Clone, Copy, Debug, PartialEq, Eq, Default)]
    pub struct Counter in "linkding_counters" {
        key {}
        last_bookmark: u64,
        last_tag: u64,
        last_bundle: u64,
    }
}

/// Bundle position 0 as stored.
pub const ORDER_BIAS: u64 = 2147483648;

/// Which list a listing reads.
pub const SCOPE_ACTIVE: u8 = 0;
pub const SCOPE_ARCHIVED: u8 = 1;
pub const SCOPE_SHARED: u8 = 2;

/// `?unread=` / `?shared=`: anything else is no filter.
pub const FLAG_ANY: u8 = 0;
pub const FLAG_YES: u8 = 1;
pub const FLAG_NO: u8 = 2;

/// `?sort=`; anything else is `added_desc`.
pub const SORT_ADDED_DESC: u8 = 0;
pub const SORT_ADDED_ASC: u8 = 1;
pub const SORT_MODIFIED_ASC: u8 = 2;
pub const SORT_MODIFIED_DESC: u8 = 3;
pub const SORT_TITLE_ASC: u8 = 4;
pub const SORT_TITLE_DESC: u8 = 5;

/// A listing's filters, as the shell parsed them from the query string.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Filter {
    pub scope: u8,
    pub q: Text,
    /// `?user=` of the shared list.
    pub user: Option<Text>,
    pub unread: u8,
    pub shared: u8,
    pub added_since: Option<u64>,
    pub modified_since: Option<u64>,
    pub sort: u8,
    pub bundle: Option<u64>,
}

/// A bookmark's fields from a request; `None` is a field the request left out.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct BookmarkFields {
    pub url: Option<Text>,
    /// The shell's normalization of `url`, given with it.
    pub url_norm: Option<Text>,
    pub title: Option<Text>,
    pub description: Option<Text>,
    pub notes: Option<Text>,
    pub unread: Option<bool>,
    pub shared: Option<bool>,
    pub archived: Option<bool>,
    /// Tag names, already split, trimmed and deduplicated by the shell.
    pub tags: Option<Vec<Text>>,
    pub added: Option<u64>,
    pub modified: Option<u64>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct BundleFields {
    pub name: Option<Text>,
    pub search: Option<Text>,
    pub any_tags: Option<Text>,
    pub all_tags: Option<Text>,
    pub excluded_tags: Option<Text>,
    pub filter_unread: Option<Text>,
    pub filter_shared: Option<Text>,
    pub order: Option<u64>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Command {
    Profile,
    /// `limit` and `offset` as `page_of` settles them.
    List { filter: Filter, limit: u64, offset: u64 },
    /// `GET /api/bookmarks/check/?url=`: the owner's bookmark of this URL.
    Check { url: Text, url_norm: Text },
    GetBookmark { id: u64 },
    /// `POST /api/bookmarks/`. `url` and `url_norm` are set. A bookmark of
    /// the same URL is updated instead.
    CreateBookmark { fields: BookmarkFields, now: u64 },
    /// `PUT` (every field set by the shell) and `PATCH`.
    UpdateBookmark { id: u64, fields: BookmarkFields, now: u64 },
    DeleteBookmark { id: u64 },
    Archive { id: u64, archived: bool, now: u64 },
    ListTags { limit: u64, offset: u64 },
    CreateTag { name: Text, now: u64 },
    GetTag { id: u64 },
    DeleteTag { id: u64 },
    ListBundles { limit: u64, offset: u64 },
    CreateBundle { fields: BundleFields, now: u64 },
    GetBundle { id: u64 },
    UpdateBundle { id: u64, fields: BundleFields, now: u64 },
    DeleteBundle { id: u64 },
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Write {
    PutBookmark(Bookmark),
    DelBookmark(u64, u64, u64),
    PutTag(Tag),
    DelTag(u64),
    PutLink(Link),
    /// Every link of a bookmark.
    DelLinksOf(u64),
    /// Every link to a tag.
    DelLinksTo(u64),
    PutBundle(Bundle),
    DelBundle(u64),
    SetCounter(Counter),
}

/// A bookmark with its tag names, in link order.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct BookmarkView {
    pub bookmark: Bookmark,
    pub tags: Vec<Text>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Reply {
    Profile(User),
    /// A page of bookmarks. `count` is the number before paging when the
    /// kernel read them all; otherwise the shell counts `list_count`'s read.
    Bookmarks { items: Vec<BookmarkView>, count: Option<u64> },
    Bookmark(BookmarkView),
    /// `Check`: the bookmark of that URL, if any.
    Found(Option<BookmarkView>),
    /// A page of tags; the shell counts `list_count`'s read.
    Tags(Vec<Tag>),
    Tag(Tag),
    Bundles { items: Vec<Bundle>, count: u64 },
    Bundle(Bundle),
    Done,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Error {
    /// No token was presented.
    Unauthenticated,
    /// A token was presented that no user holds.
    BadToken,
    NotFound,
    /// Another of the owner's bookmarks has this URL.
    DuplicateUrl,
    Overflow,
}

type Outcome = Result<(Vec<Write>, Reply), Error>;

/// `?` without the `Try` trait, which Aeneas does not model.
macro_rules! tri {
    ($e:expr) => {
        match $e {
            Ok(v) => v,
            Err(e) => return Err(e),
        }
    };
}

fn one(w: Write) -> Vec<Write> {
    let mut ws = Vec::new();
    ws.push(w);
    ws
}

/* Text */

/// ASCII letters lowercased.
pub fn lower_text(t: &Text) -> Text {
    let mut out = Vec::new();
    let mut i = 0;
    while i < t.len() {
        out.push(lower_ascii(t[i]));
        i += 1;
    }
    out
}

/// Equal up to ASCII case.
pub fn eq_ci(a: &Text, b: &Text) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut i = 0;
    while i < a.len() {
        if lower_ascii(a[i]) != lower_ascii(b[i]) {
            return false;
        }
        i += 1;
    }
    true
}

/// `a < b` comparing ASCII-lowercased bytes.
fn less_ci(a: &Text, b: &Text) -> bool {
    let mut i = 0;
    while i < a.len() && i < b.len() {
        let x = lower_ascii(a[i]);
        let y = lower_ascii(b[i]);
        if x < y {
            return true;
        }
        if x > y {
            return false;
        }
        i += 1;
    }
    a.len() < b.len()
}

fn contains_text(v: &Vec<Text>, t: &Text) -> bool {
    let mut i = 0;
    while i < v.len() {
        if v[i] == *t {
            return true;
        }
        i += 1;
    }
    false
}

fn or_keep(new: &Option<Text>, old: &Text) -> Text {
    match new {
        Some(t) => t.clone(),
        None => old.clone(),
    }
}

fn or_empty(new: &Option<Text>) -> Text {
    match new {
        Some(t) => t.clone(),
        None => Vec::new(),
    }
}

fn flag_or(new: &Option<bool>, old: bool) -> bool {
    match new {
        Some(b) => *b,
        None => old,
    }
}

fn time_or(new: &Option<u64>, old: u64) -> u64 {
    match new {
        Some(t) => *t,
        None => old,
    }
}

fn yes_word() -> Text {
    let mut w = Vec::new();
    w.push(b'y');
    w.push(b'e');
    w.push(b's');
    w
}

fn no_word() -> Text {
    let mut w = Vec::new();
    w.push(b'n');
    w.push(b'o');
    w
}

fn off_word() -> Text {
    let mut w = Vec::new();
    w.push(b'o');
    w.push(b'f');
    w.push(b'f');
    w
}

/* Lookups */

/// The user `token` names: `Ok(0)` for a guest (no token), `Err` for a token
/// no user holds.
pub fn actor(s: &Snapshot, token: &Text) -> Result<u64, Error> {
    if token.len() == 0 {
        return Ok(0);
    }
    let mut i = 0;
    while i < s.tokens.len() {
        if s.tokens[i].key == *token {
            let u = s.tokens[i].user;
            if find_user(&s.users, u).is_some() {
                return Ok(u);
            }
            return Err(Error::BadToken);
        }
        i += 1;
    }
    Err(Error::BadToken)
}

/// The signed-in user, or why there is none.
fn signed_in(s: &Snapshot, token: &Text) -> Result<User, Error> {
    let u = tri!(actor(s, token));
    if u == 0 {
        return Err(Error::Unauthenticated);
    }
    match find_user(&s.users, u) {
        Some(me) => Ok(me),
        None => Err(Error::BadToken),
    }
}

pub fn find_user(us: &Vec<User>, id: u64) -> Option<User> {
    let mut i = 0;
    while i < us.len() {
        if us[i].id == id {
            return Some(us[i].clone());
        }
        i += 1;
    }
    None
}

pub fn find_user_by_name(us: &Vec<User>, name: &Text) -> Option<User> {
    let mut i = 0;
    while i < us.len() {
        if us[i].username == *name {
            return Some(us[i].clone());
        }
        i += 1;
    }
    None
}

pub fn find_bookmark(v: &Vec<Bookmark>, id: u64) -> Option<Bookmark> {
    let mut i = 0;
    while i < v.len() {
        if v[i].id == id {
            return Some(v[i].clone());
        }
        i += 1;
    }
    None
}

pub fn find_tag(v: &Vec<Tag>, id: u64) -> Option<Tag> {
    let mut i = 0;
    while i < v.len() {
        if v[i].id == id {
            return Some(v[i].clone());
        }
        i += 1;
    }
    None
}

/// The owner's tag whose lowercased name is `lower`.
pub fn find_tag_named(v: &Vec<Tag>, owner: u64, lower: &Text) -> Option<Tag> {
    let mut i = 0;
    while i < v.len() {
        if v[i].owner == owner && v[i].name_lower == *lower {
            return Some(v[i].clone());
        }
        i += 1;
    }
    None
}

pub fn find_bundle(v: &Vec<Bundle>, id: u64) -> Option<Bundle> {
    let mut i = 0;
    while i < v.len() {
        if v[i].id == id {
            return Some(v[i].clone());
        }
        i += 1;
    }
    None
}

/// The names of a bookmark's tags, in link order.
pub fn tag_names(s: &Snapshot, bookmark: u64) -> Vec<Text> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < s.links.len() {
        if s.links[i].bookmark == bookmark {
            match find_tag(&s.tags, s.links[i].tag) {
                Some(t) => out.push(t.name.clone()),
                None => {}
            }
        }
        i += 1;
    }
    out
}

/// The lowercased names of a bookmark's tags.
fn tag_lowers(s: &Snapshot, bookmark: u64) -> Vec<Text> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < s.links.len() {
        if s.links[i].bookmark == bookmark {
            match find_tag(&s.tags, s.links[i].tag) {
                Some(t) => out.push(t.name_lower.clone()),
                None => {}
            }
        }
        i += 1;
    }
    out
}

pub fn view(s: &Snapshot, b: &Bookmark) -> BookmarkView {
    BookmarkView { bookmark: b.clone(), tags: tag_names(s, b.id) }
}

fn same_url(b: &Bookmark, owner: u64, url: &Text, url_norm: &Text) -> bool {
    b.owner == owner && (b.url_norm == *url_norm || (b.url_norm.len() == 0 && b.url == *url))
}

/// The owner's bookmark of a URL: same normalized URL, or, for a bookmark
/// stored without one, the same URL; the lowest id if several.
pub fn existing(s: &Snapshot, owner: u64, url: &Text, url_norm: &Text) -> Option<Bookmark> {
    let mut found = false;
    let mut best: u64 = 0;
    let mut i = 0;
    while i < s.bookmarks.len() {
        if same_url(&s.bookmarks[i], owner, url, url_norm) && (!found || s.bookmarks[i].id < best) {
            found = true;
            best = s.bookmarks[i].id;
        }
        i += 1;
    }
    if found {
        find_bookmark(&s.bookmarks, best)
    } else {
        None
    }
}

/// Another of the owner's bookmarks with exactly this URL.
fn url_taken(s: &Snapshot, owner: u64, url: &Text, id: u64) -> bool {
    let mut i = 0;
    while i < s.bookmarks.len() {
        let b = &s.bookmarks[i];
        if b.owner == owner && b.url == *url && b.id != id {
            return true;
        }
        i += 1;
    }
    false
}

/* Listing */

fn facts(s: &Snapshot, b: &Bookmark) -> BookmarkFacts {
    let tags = tag_lowers(s, b.id);
    BookmarkFacts {
        title: b.title.clone(),
        description: b.description.clone(),
        notes: b.notes.clone(),
        url: b.url.clone(),
        unread: b.unread,
        untagged: tags.len() == 0,
        tag_names: tags,
    }
}

/// A term matches title, description, notes or URL, ignoring ASCII case,
/// and in lax mode also an exact tag name.
fn term_hit(f: &BookmarkFacts, term: &Text, lax: bool) -> bool {
    let mut p = Vec::new();
    p.push(Node { kind: NODE_TERM, text: term.clone(), left: 0, right: 0 });
    let parsed = Parsed { nodes: p, root: 0, failed: false, empty: false };
    bookmark_matches(&parsed, lax, f)
}

fn has_tag_ci(f: &BookmarkFacts, name: &Text) -> bool {
    let lower = lower_text(name);
    contains_text(&f.tag_names, &lower)
}

/// The words of `t` split on single spaces, empty ones dropped.
fn words(t: &Text) -> Vec<Text> {
    let mut out = Vec::new();
    let mut cur: Text = Vec::new();
    let mut i = 0;
    while i < t.len() {
        if t[i] == b' ' {
            if cur.len() > 0 {
                out.push(cur.clone());
            }
            cur = Vec::new();
        } else {
            cur.push(t[i]);
        }
        i += 1;
    }
    if cur.len() > 0 {
        out.push(cur);
    }
    out
}

fn rest_of(w: &Text) -> Text {
    let mut out = Vec::new();
    let mut i = 1;
    while i < w.len() {
        out.push(w[i]);
        i += 1;
    }
    out
}

/// The legacy search of a profile with `legacy_search`: space-separated
/// words, all required; `#tag`, `!unread`, `!untagged`, other words terms.
fn legacy_matches(q: &Text, lax: bool, f: &BookmarkFacts) -> bool {
    let ws = words(&trim_text(q));
    let mut i = 0;
    while i < ws.len() {
        let w = &ws[i];
        if w[0] == b'#' {
            if w.len() > 1 && !has_tag_ci(f, &rest_of(w)) {
                return false;
            }
        } else if w[0] == b'!' {
            let k = rest_of(w);
            if k == untagged_word() && !f.untagged {
                return false;
            }
            if k == unread_word() && !f.unread {
                return false;
            }
        } else if !term_hit(f, w, lax) {
            return false;
        }
        i += 1;
    }
    true
}

fn trim_text(t: &Text) -> Text {
    let mut start = 0;
    while start < t.len() && is_space(t[start]) {
        start += 1;
    }
    let mut end = t.len();
    while end > start && is_space(t[end - 1]) {
        end -= 1;
    }
    let mut out = Vec::new();
    let mut i = start;
    while i < end {
        out.push(t[i]);
        i += 1;
    }
    out
}

/// The tag names of a bundle's tag field: space-separated.
fn tag_words(t: &Text) -> Vec<Text> {
    words(&trim_text(t))
}

fn any_of(f: &BookmarkFacts, names: &Vec<Text>) -> bool {
    let mut i = 0;
    while i < names.len() {
        if has_tag_ci(f, &names[i]) {
            return true;
        }
        i += 1;
    }
    false
}

fn all_of(f: &BookmarkFacts, names: &Vec<Text>) -> bool {
    let mut i = 0;
    while i < names.len() {
        if !has_tag_ci(f, &names[i]) {
            return false;
        }
        i += 1;
    }
    true
}

fn flag_ok(rule: &Text, value: bool) -> bool {
    if *rule == yes_word() {
        return value;
    }
    if *rule == no_word() {
        return !value;
    }
    true
}

/// A bundle's filter: every search word that is not a `#tag` or `!keyword`
/// is a term; any of `any_tags`, all of `all_tags`, none of `excluded_tags`;
/// the unread and shared rules.
fn bundle_matches(bu: &Bundle, b: &Bookmark, f: &BookmarkFacts) -> bool {
    let ws = words(&trim_text(&bu.search));
    let mut i = 0;
    while i < ws.len() {
        let w = &ws[i];
        if w[0] != b'#' && w[0] != b'!' && !term_hit(f, w, false) {
            return false;
        }
        i += 1;
    }
    let any = tag_words(&bu.any_tags);
    if any.len() > 0 && !any_of(f, &any) {
        return false;
    }
    if !all_of(f, &tag_words(&bu.all_tags)) {
        return false;
    }
    let ex = tag_words(&bu.excluded_tags);
    if ex.len() > 0 && any_of(f, &ex) {
        return false;
    }
    flag_ok(&bu.filter_unread, b.unread) && flag_ok(&bu.filter_shared, b.shared)
}

fn flag_filter(rule: u8, value: bool) -> bool {
    if rule == FLAG_YES {
        return value;
    }
    if rule == FLAG_NO {
        return !value;
    }
    true
}

fn since_ok(since: &Option<u64>, t: u64) -> bool {
    match since {
        None => true,
        Some(x) => t > *x,
    }
}

/// Who a shared listing shows: shared bookmarks of users who share; a guest
/// sees only users who share publicly. `owner_filter` is `?user=`'s id.
fn shared_visible(s: &Snapshot, viewer: u64, b: &Bookmark, owner_filter: Option<u64>) -> bool {
    if !b.shared {
        return false;
    }
    match owner_filter {
        Some(o) => {
            if b.owner != o {
                return false;
            }
        }
        None => {}
    }
    match find_user(&s.users, b.owner) {
        None => false,
        Some(o) => o.sharing && (viewer != 0 || o.public_sharing),
    }
}

/// Every filter of a listing but the scope.
fn selected(s: &Snapshot, flt: &Filter, parsed: &Parsed, lax: bool, legacy: bool, bundle: &Option<Bundle>, b: &Bookmark) -> bool {
    if !since_ok(&flt.added_since, b.added) || !since_ok(&flt.modified_since, b.modified) {
        return false;
    }
    if !flag_filter(flt.unread, b.unread) || !flag_filter(flt.shared, b.shared) {
        return false;
    }
    let f = facts(s, b);
    let q_ok = if legacy { legacy_matches(&flt.q, lax, &f) } else { bookmark_matches(parsed, lax, &f) };
    if !q_ok {
        return false;
    }
    match bundle {
        None => true,
        Some(bu) => bundle_matches(bu, b, &f),
    }
}

/// `x` comes before `y` in `sort` order; ties newest id first.
fn before(sort: u8, x: &Bookmark, y: &Bookmark) -> bool {
    if sort == SORT_ADDED_ASC {
        if x.added != y.added {
            return x.added < y.added;
        }
    } else if sort == SORT_MODIFIED_ASC {
        if x.modified != y.modified {
            return x.modified < y.modified;
        }
    } else if sort == SORT_MODIFIED_DESC {
        if x.modified != y.modified {
            return x.modified > y.modified;
        }
    } else if sort == SORT_TITLE_ASC || sort == SORT_TITLE_DESC {
        let tx = if x.title.len() > 0 { x.title.clone() } else { x.url.clone() };
        let ty = if y.title.len() > 0 { y.title.clone() } else { y.url.clone() };
        if !eq_ci(&tx, &ty) {
            if sort == SORT_TITLE_ASC {
                return less_ci(&tx, &ty);
            }
            return less_ci(&ty, &tx);
        }
    } else if x.added != y.added {
        return x.added > y.added;
    }
    x.id > y.id
}

/// `a` and `b`, each in `sort` order, merged.
fn merge(a: &Vec<Bookmark>, b: &Vec<Bookmark>, sort: u8) -> Vec<Bookmark> {
    let mut out = Vec::new();
    let mut i = 0;
    let mut j = 0;
    while i < a.len() || j < b.len() {
        if j >= b.len() || (i < a.len() && !before(sort, &b[j], &a[i])) {
            out.push(a[i].clone());
            i += 1;
        } else {
            out.push(b[j].clone());
            j += 1;
        }
    }
    out
}

/// Bottom-up merge sort by `before`; stable.
pub fn sort_bookmarks(v: &Vec<Bookmark>, sort: u8) -> Vec<Bookmark> {
    let mut runs: Vec<Vec<Bookmark>> = Vec::new();
    let mut i = 0;
    while i < v.len() {
        let mut r = Vec::new();
        r.push(v[i].clone());
        runs.push(r);
        i += 1;
    }
    while runs.len() > 1 {
        let mut next: Vec<Vec<Bookmark>> = Vec::new();
        let mut k = 0;
        while k < runs.len() {
            if k + 1 < runs.len() {
                next.push(merge(&runs[k], &runs[k + 1], sort));
            } else {
                next.push(runs[k].clone());
            }
            k += 2;
        }
        runs = next;
    }
    if runs.len() == 0 {
        return Vec::new();
    }
    runs[0].clone()
}

fn reversed(v: &Vec<Bookmark>) -> Vec<Bookmark> {
    let mut out = Vec::new();
    let mut i = v.len();
    while i > 0 {
        i -= 1;
        out.push(v[i].clone());
    }
    out
}

/// Whether `k` (0-based) is on the page `offset`, `limit`.
fn on_page(k: u64, offset: u64, limit: u64) -> bool {
    k >= offset && k - offset < limit
}

fn page_bookmarks(v: &Vec<Bookmark>, offset: u64, limit: u64) -> Vec<Bookmark> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < v.len() {
        if on_page(i as u64, offset, limit) {
            out.push(v[i].clone());
        }
        i += 1;
    }
    out
}

fn page_tags(v: &Vec<Tag>, offset: u64, limit: u64) -> Vec<Tag> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < v.len() {
        if on_page(i as u64, offset, limit) {
            out.push(v[i].clone());
        }
        i += 1;
    }
    out
}

fn page_bundles(v: &Vec<Bundle>, offset: u64, limit: u64) -> Vec<Bundle> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < v.len() {
        if on_page(i as u64, offset, limit) {
            out.push(v[i].clone());
        }
        i += 1;
    }
    out
}

fn is_quote_or_paren(c: u8) -> bool {
    c == b'(' || c == b')' || c == b'"' || c == b'\''
}

/// A query both search modes read the same way and a read can select
/// exactly: space-separated words, each `#tag` or `!keyword` (no other
/// whitespace, quotes or parentheses; no `!untagged`; `!unread` only in
/// lowercase). It selects the bookmarks with every tag, and unread ones if
/// `!unread` is among them. `None` for any other query.
pub fn simple_query(q: &Text) -> Option<(Vec<Text>, bool)> {
    let t = trim_text(q);
    let mut ok = true;
    let mut i = 0;
    while i < t.len() {
        if (is_space(t[i]) && t[i] != b' ') || is_quote_or_paren(t[i]) {
            ok = false;
        }
        i += 1;
    }
    let ws = words(&t);
    let mut tags: Vec<Text> = Vec::new();
    let mut unread = false;
    let mut j = 0;
    while j < ws.len() {
        let w = ws[j].clone();
        if w[0] == b'#' {
            if w.len() > 1 {
                tags.push(rest_of(&w));
            }
        } else if w[0] == b'!' {
            let k = rest_of(&w);
            if k == unread_word() {
                unread = true;
            } else if eq_ci(&k, &unread_word()) || eq_ci(&k, &untagged_word()) {
                ok = false;
            }
        } else {
            ok = false;
        }
        j += 1;
    }
    if ok {
        Some((tags, unread))
    } else {
        None
    }
}

/// Whether a listing reads only its page: an own or archived list in the
/// default order, a `simple_query`, no date filter, no bundle.
pub fn paged(flt: &Filter) -> bool {
    if flt.scope == SCOPE_SHARED || flt.sort != SORT_ADDED_DESC {
        return false;
    }
    if flt.added_since.is_some() || flt.modified_since.is_some() || flt.bundle.is_some() {
        return false;
    }
    simple_query(&flt.q).is_some()
}

fn list(s: &Snapshot, token: &Text, flt: &Filter, limit: u64, offset: u64) -> Outcome {
    let viewer = tri!(actor(s, token));
    if viewer == 0 && flt.scope != SCOPE_SHARED {
        return Err(Error::Unauthenticated);
    }
    let me = find_user(&s.users, viewer);
    let (lax, legacy) = match &me {
        Some(u) => (u.lax, u.legacy),
        None => (false, false),
    };
    let owner_filter = if flt.scope == SCOPE_SHARED {
        match &flt.user {
            None => None,
            Some(name) => {
                if name.len() == 0 {
                    None
                } else {
                    match find_user_by_name(&s.users, name) {
                        Some(o) => Some(o.id),
                        None => None,
                    }
                }
            }
        }
    } else {
        None
    };
    let bundle = match flt.bundle {
        None => None,
        Some(id) => {
            if viewer == 0 {
                None
            } else {
                match find_bundle(&s.bundles, id) {
                    Some(b) => {
                        if b.owner == viewer {
                            Some(b)
                        } else {
                            None
                        }
                    }
                    None => None,
                }
            }
        }
    };
    let parsed = parse_search(&flt.q);
    let mut sel: Vec<Bookmark> = Vec::new();
    let mut i = 0;
    while i < s.bookmarks.len() {
        let b = &s.bookmarks[i];
        let in_scope = if flt.scope == SCOPE_SHARED {
            shared_visible(s, viewer, b, owner_filter)
        } else {
            b.owner == viewer && b.archived == (flt.scope == SCOPE_ARCHIVED)
        };
        if in_scope && selected(s, flt, &parsed, lax, legacy, &bundle, b) {
            sel.push(b.clone());
        }
        i += 1;
    }
    // One owner's bookmarks load in key order: by date added, then id.
    let sorted = if flt.scope != SCOPE_SHARED && flt.sort == SORT_ADDED_DESC {
        reversed(&sel)
    } else {
        sort_bookmarks(&sel, flt.sort)
    };
    let page = page_bookmarks(&sorted, offset, limit);
    let mut items = Vec::new();
    let mut j = 0;
    while j < page.len() {
        items.push(view(s, &page[j]));
        j += 1;
    }
    let count = if paged(flt) { None } else { Some(sorted.len() as u64) };
    Ok((Vec::new(), Reply::Bookmarks { items, count }))
}

/* Bookmarks */

/// Links for `names` on bookmark `id`, creating the owner's missing tags.
/// Returns the writes, the tag names as stored, and the counter after.
fn tag_writes(
    s: &Snapshot,
    owner: u64,
    id: u64,
    names: &Vec<Text>,
    now: u64,
    ws: Vec<Write>,
    last: u64,
) -> Result<(Vec<Write>, Vec<Text>, u64), Error> {
    // Each name makes at most one tag.
    if last > u64::MAX - (names.len() as u64) {
        return Err(Error::Overflow);
    }
    let mut out = ws;
    let mut shown: Vec<Text> = Vec::new();
    let mut made: Vec<Tag> = Vec::new();
    let mut next = last;
    let mut i = 0;
    while i < names.len() {
        let lower = lower_text(&names[i]);
        let found = match find_tag_named(&s.tags, owner, &lower) {
            Some(t) => Some(t),
            None => find_tag_named(&made, owner, &lower),
        };
        let t = match found {
            Some(t) => t,
            None => {
                next += 1;
                let t = Tag { id: next, owner, name: names[i].clone(), name_lower: lower, added: now };
                out.push(Write::PutTag(t.clone()));
                made.push(t.clone());
                t
            }
        };
        if !contains_text(&shown, &t.name) {
            out.push(Write::PutLink(Link { bookmark: id, tag: t.id }));
            shown.push(t.name.clone());
        }
        i += 1;
    }
    Ok((out, shown, next))
}

fn set_counter(s: &Snapshot, last_bookmark: u64, last_tag: u64) -> Write {
    Write::SetCounter(Counter { last_bookmark, last_tag, last_bundle: s.counter.last_bundle })
}

fn create_bookmark(s: &Snapshot, token: &Text, f: &BookmarkFields, now: u64) -> Outcome {
    let me = tri!(signed_in(s, token));
    let url = or_empty(&f.url);
    let url_norm = or_empty(&f.url_norm);
    let names = match &f.tags {
        Some(t) => t.clone(),
        None => Vec::new(),
    };
    match existing(s, me.id, &url, &url_norm) {
        Some(b) => {
            // linkding updates the bookmark of an already saved URL.
            let b2 = Bookmark {
                owner: b.owner,
                added: b.added,
                id: b.id,
                url: b.url.clone(),
                url_norm: b.url_norm.clone(),
                title: or_empty(&f.title),
                description: or_empty(&f.description),
                notes: or_empty(&f.notes),
                unread: flag_or(&f.unread, false),
                archived: b.archived,
                shared: flag_or(&f.shared, false),
                modified: now,
            };
            let mut ws = Vec::new();
            ws.push(Write::PutBookmark(b2.clone()));
            ws.push(Write::DelLinksOf(b.id));
            let (ws, shown, last_tag) = tri!(tag_writes(s, me.id, b.id, &names, now, ws, s.counter.last_tag));
            let mut ws = ws;
            ws.push(set_counter(s, s.counter.last_bookmark, last_tag));
            Ok((ws, Reply::Bookmark(BookmarkView { bookmark: b2, tags: shown })))
        }
        None => {
            let last = s.counter.last_bookmark;
            if last == u64::MAX {
                return Err(Error::Overflow);
            }
            let b = Bookmark {
                owner: me.id,
                added: time_or(&f.added, now),
                id: last + 1,
                url,
                url_norm,
                title: or_empty(&f.title),
                description: or_empty(&f.description),
                notes: or_empty(&f.notes),
                unread: flag_or(&f.unread, false),
                archived: flag_or(&f.archived, false),
                shared: flag_or(&f.shared, false),
                modified: time_or(&f.modified, now),
            };
            let ws = one(Write::PutBookmark(b.clone()));
            let (ws, shown, last_tag) = tri!(tag_writes(s, me.id, last + 1, &names, now, ws, s.counter.last_tag));
            let mut ws = ws;
            ws.push(set_counter(s, last + 1, last_tag));
            Ok((ws, Reply::Bookmark(BookmarkView { bookmark: b, tags: shown })))
        }
    }
}

/// The caller's bookmark `id`; anyone else's is not found.
fn own_bookmark(s: &Snapshot, me: &User, id: u64) -> Result<Bookmark, Error> {
    match find_bookmark(&s.bookmarks, id) {
        Some(b) => {
            if b.owner == me.id {
                Ok(b)
            } else {
                Err(Error::NotFound)
            }
        }
        None => Err(Error::NotFound),
    }
}

fn get_bookmark(s: &Snapshot, token: &Text, id: u64) -> Outcome {
    let me = tri!(signed_in(s, token));
    let b = tri!(own_bookmark(s, &me, id));
    Ok((Vec::new(), Reply::Bookmark(view(s, &b))))
}

fn update_bookmark(s: &Snapshot, token: &Text, id: u64, f: &BookmarkFields, now: u64) -> Outcome {
    let me = tri!(signed_in(s, token));
    let b = tri!(own_bookmark(s, &me, id));
    match &f.url {
        Some(u) => {
            if url_taken(s, me.id, u, id) {
                return Err(Error::DuplicateUrl);
            }
        }
        None => {}
    }
    let url = or_keep(&f.url, &b.url);
    let url_norm = match &f.url {
        Some(_) => or_empty(&f.url_norm),
        None => b.url_norm.clone(),
    };
    let b2 = Bookmark {
        owner: b.owner,
        added: time_or(&f.added, b.added),
        id: b.id,
        url,
        url_norm,
        title: or_keep(&f.title, &b.title),
        description: or_keep(&f.description, &b.description),
        notes: or_keep(&f.notes, &b.notes),
        unread: flag_or(&f.unread, b.unread),
        archived: flag_or(&f.archived, b.archived),
        shared: flag_or(&f.shared, b.shared),
        modified: now,
    };
    let mut ws = Vec::new();
    // A new date moves the row: its key holds the date.
    if b2.added != b.added {
        ws.push(Write::DelBookmark(b.owner, b.added, b.id));
    }
    ws.push(Write::PutBookmark(b2.clone()));
    match &f.tags {
        None => Ok((ws, Reply::Bookmark(BookmarkView { bookmark: b2, tags: tag_names(s, b.id) }))),
        Some(names) => {
            ws.push(Write::DelLinksOf(b.id));
            let (ws, shown, last_tag) = tri!(tag_writes(s, me.id, b.id, names, now, ws, s.counter.last_tag));
            let mut ws = ws;
            ws.push(set_counter(s, s.counter.last_bookmark, last_tag));
            Ok((ws, Reply::Bookmark(BookmarkView { bookmark: b2, tags: shown })))
        }
    }
}

fn delete_bookmark(s: &Snapshot, token: &Text, id: u64) -> Outcome {
    let me = tri!(signed_in(s, token));
    let b = tri!(own_bookmark(s, &me, id));
    let mut ws = Vec::new();
    ws.push(Write::DelLinksOf(b.id));
    ws.push(Write::DelBookmark(b.owner, b.added, b.id));
    Ok((ws, Reply::Done))
}

fn archive(s: &Snapshot, token: &Text, id: u64, archived: bool, now: u64) -> Outcome {
    let me = tri!(signed_in(s, token));
    let b = tri!(own_bookmark(s, &me, id));
    let b2 = Bookmark {
        owner: b.owner,
        added: b.added,
        id: b.id,
        url: b.url.clone(),
        url_norm: b.url_norm.clone(),
        title: b.title.clone(),
        description: b.description.clone(),
        notes: b.notes.clone(),
        unread: b.unread,
        archived,
        shared: b.shared,
        modified: now,
    };
    Ok((one(Write::PutBookmark(b2)), Reply::Done))
}

fn check(s: &Snapshot, token: &Text, url: &Text, url_norm: &Text) -> Outcome {
    let me = tri!(signed_in(s, token));
    let found = match existing(s, me.id, url, url_norm) {
        Some(b) => Some(view(s, &b)),
        None => None,
    };
    Ok((Vec::new(), Reply::Found(found)))
}

/* Tags */

/// The caller's tags in id order, a page of them.
fn list_tags(s: &Snapshot, token: &Text, limit: u64, offset: u64) -> Outcome {
    let me = tri!(signed_in(s, token));
    let mut mine: Vec<Tag> = Vec::new();
    let mut i = 0;
    while i < s.tags.len() {
        if s.tags[i].owner == me.id {
            mine.push(s.tags[i].clone());
        }
        i += 1;
    }
    Ok((Vec::new(), Reply::Tags(page_tags(&mine, offset, limit))))
}

/// The caller's tag of this name (any case), or a new one.
fn create_tag(s: &Snapshot, token: &Text, name: &Text, now: u64) -> Outcome {
    let me = tri!(signed_in(s, token));
    let lower = lower_text(name);
    match find_tag_named(&s.tags, me.id, &lower) {
        Some(t) => Ok((Vec::new(), Reply::Tag(t))),
        None => {
            let last = s.counter.last_tag;
            if last == u64::MAX {
                return Err(Error::Overflow);
            }
            let t = Tag { id: last + 1, owner: me.id, name: name.clone(), name_lower: lower, added: now };
            let mut ws = Vec::new();
            ws.push(Write::PutTag(t.clone()));
            ws.push(set_counter(s, s.counter.last_bookmark, last + 1));
            Ok((ws, Reply::Tag(t)))
        }
    }
}

fn own_tag(s: &Snapshot, me: &User, id: u64) -> Result<Tag, Error> {
    match find_tag(&s.tags, id) {
        Some(t) => {
            if t.owner == me.id {
                Ok(t)
            } else {
                Err(Error::NotFound)
            }
        }
        None => Err(Error::NotFound),
    }
}

fn get_tag(s: &Snapshot, token: &Text, id: u64) -> Outcome {
    let me = tri!(signed_in(s, token));
    let t = tri!(own_tag(s, &me, id));
    Ok((Vec::new(), Reply::Tag(t)))
}

fn delete_tag(s: &Snapshot, token: &Text, id: u64) -> Outcome {
    let me = tri!(signed_in(s, token));
    let t = tri!(own_tag(s, &me, id));
    let mut ws = Vec::new();
    ws.push(Write::DelLinksTo(t.id));
    ws.push(Write::DelTag(t.id));
    Ok((ws, Reply::Done))
}

/* Bundles */

/// `x` before `y`: by position, then id.
fn bundle_before(x: &Bundle, y: &Bundle) -> bool {
    if x.order != y.order {
        return x.order < y.order;
    }
    x.id < y.id
}

/// `v` with `x` inserted before the first bundle it comes before.
fn insert_bundle(v: &Vec<Bundle>, x: &Bundle) -> Vec<Bundle> {
    let mut out = Vec::new();
    let mut placed = false;
    let mut i = 0;
    while i < v.len() {
        if !placed && bundle_before(x, &v[i]) {
            out.push(x.clone());
            placed = true;
        }
        out.push(v[i].clone());
        i += 1;
    }
    if !placed {
        out.push(x.clone());
    }
    out
}

/// The owner's bundles by position.
pub fn bundles_of(s: &Snapshot, owner: u64) -> Vec<Bundle> {
    let mut out: Vec<Bundle> = Vec::new();
    let mut i = 0;
    while i < s.bundles.len() {
        if s.bundles[i].owner == owner {
            out = insert_bundle(&out, &s.bundles[i]);
        }
        i += 1;
    }
    out
}

fn list_bundles(s: &Snapshot, token: &Text, limit: u64, offset: u64) -> Outcome {
    let me = tri!(signed_in(s, token));
    let mine = bundles_of(s, me.id);
    Ok((Vec::new(), Reply::Bundles { items: page_bundles(&mine, offset, limit), count: mine.len() as u64 }))
}

fn off_text(t: &Option<Text>) -> Text {
    match t {
        Some(x) => x.clone(),
        None => off_word(),
    }
}

fn create_bundle(s: &Snapshot, token: &Text, f: &BundleFields, now: u64) -> Outcome {
    let me = tri!(signed_in(s, token));
    let order = match f.order {
        Some(o) => o,
        None => {
            // One past the highest position, 0 for the first.
            let mine = bundles_of(s, me.id);
            let mut top = ORDER_BIAS;
            let mut i = 0;
            while i < mine.len() {
                if mine[i].order >= top {
                    top = mine[i].order;
                }
                i += 1;
            }
            // `top` is the highest position, or the bias when there is none.
            if mine.len() == 0 {
                ORDER_BIAS
            } else if top == u64::MAX {
                return Err(Error::Overflow);
            } else {
                top + 1
            }
        }
    };
    let last = s.counter.last_bundle;
    if last == u64::MAX {
        return Err(Error::Overflow);
    }
    let b = Bundle {
        id: last + 1,
        owner: me.id,
        name: or_empty(&f.name),
        search: or_empty(&f.search),
        any_tags: or_empty(&f.any_tags),
        all_tags: or_empty(&f.all_tags),
        excluded_tags: or_empty(&f.excluded_tags),
        filter_unread: off_text(&f.filter_unread),
        filter_shared: off_text(&f.filter_shared),
        order,
        created: now,
        modified: now,
    };
    let c = Counter { last_bookmark: s.counter.last_bookmark, last_tag: s.counter.last_tag, last_bundle: last + 1 };
    let mut ws = Vec::new();
    ws.push(Write::PutBundle(b.clone()));
    ws.push(Write::SetCounter(c));
    Ok((ws, Reply::Bundle(b)))
}

fn own_bundle(s: &Snapshot, me: &User, id: u64) -> Result<Bundle, Error> {
    match find_bundle(&s.bundles, id) {
        Some(b) => {
            if b.owner == me.id {
                Ok(b)
            } else {
                Err(Error::NotFound)
            }
        }
        None => Err(Error::NotFound),
    }
}

fn get_bundle(s: &Snapshot, token: &Text, id: u64) -> Outcome {
    let me = tri!(signed_in(s, token));
    let b = tri!(own_bundle(s, &me, id));
    Ok((Vec::new(), Reply::Bundle(b)))
}

fn update_bundle(s: &Snapshot, token: &Text, id: u64, f: &BundleFields, now: u64) -> Outcome {
    let me = tri!(signed_in(s, token));
    let b = tri!(own_bundle(s, &me, id));
    let b2 = Bundle {
        id: b.id,
        owner: b.owner,
        name: or_keep(&f.name, &b.name),
        search: or_keep(&f.search, &b.search),
        any_tags: or_keep(&f.any_tags, &b.any_tags),
        all_tags: or_keep(&f.all_tags, &b.all_tags),
        excluded_tags: or_keep(&f.excluded_tags, &b.excluded_tags),
        filter_unread: or_keep(&f.filter_unread, &b.filter_unread),
        filter_shared: or_keep(&f.filter_shared, &b.filter_shared),
        order: time_or(&f.order, b.order),
        created: b.created,
        modified: now,
    };
    Ok((one(Write::PutBundle(b2.clone())), Reply::Bundle(b2)))
}

/// Deletes the bundle and renumbers the owner's others 0, 1, 2, ...
fn delete_bundle(s: &Snapshot, token: &Text, id: u64) -> Outcome {
    let me = tri!(signed_in(s, token));
    let b = tri!(own_bundle(s, &me, id));
    let mine = bundles_of(s, me.id);
    let mut ws = one(Write::DelBundle(b.id));
    // Positions count up from the bias; there are fewer bundles than ids.
    let mut pos: u64 = 0;
    let mut i = 0;
    while i < mine.len() {
        if mine[i].id != b.id {
            let mut x = mine[i].clone();
            x.order = ORDER_BIAS + pos;
            ws.push(Write::PutBundle(x));
            pos += 1;
        }
        i += 1;
    }
    Ok((ws, Reply::Done))
}

fn profile(s: &Snapshot, token: &Text) -> Outcome {
    let me = tri!(signed_in(s, token));
    Ok((Vec::new(), Reply::Profile(me)))
}

/// The kernel: what a command writes and replies, or why it is refused.
pub fn transition(actor: &Principal, s: &Snapshot, cmd: &Command) -> Outcome {
    let t = &actor.token;
    match cmd {
        Command::Profile => profile(s, t),
        Command::List { filter, limit, offset } => list(s, t, filter, *limit, *offset),
        Command::Check { url, url_norm } => check(s, t, url, url_norm),
        Command::GetBookmark { id } => get_bookmark(s, t, *id),
        Command::CreateBookmark { fields, now } => create_bookmark(s, t, fields, *now),
        Command::UpdateBookmark { id, fields, now } => update_bookmark(s, t, *id, fields, *now),
        Command::DeleteBookmark { id } => delete_bookmark(s, t, *id),
        Command::Archive { id, archived, now } => archive(s, t, *id, *archived, *now),
        Command::ListTags { limit, offset } => list_tags(s, t, *limit, *offset),
        Command::CreateTag { name, now } => create_tag(s, t, name, *now),
        Command::GetTag { id } => get_tag(s, t, *id),
        Command::DeleteTag { id } => delete_tag(s, t, *id),
        Command::ListBundles { limit, offset } => list_bundles(s, t, *limit, *offset),
        Command::CreateBundle { fields, now } => create_bundle(s, t, fields, *now),
        Command::GetBundle { id } => get_bundle(s, t, *id),
        Command::UpdateBundle { id, fields, now } => update_bundle(s, t, *id, fields, *now),
        Command::DeleteBundle { id } => delete_bundle(s, t, *id),
    }
}

/// Commands that never write; the engine runs them on a read-only snapshot.
pub fn read_only(cmd: &Command) -> bool {
    match cmd {
        Command::Profile
        | Command::List { .. }
        | Command::Check { .. }
        | Command::GetBookmark { .. }
        | Command::ListTags { .. }
        | Command::GetTag { .. }
        | Command::ListBundles { .. }
        | Command::GetBundle { .. } => true,
        _ => false,
    }
}

/* Read plans */

// Table numbers and columns, in `schema!` order (`linkding_tables`).
const T_USERS: u32 = 0;
const T_TOKENS: u32 = 1;
const T_BOOKMARKS: u32 = 2;
const T_TAGS: u32 = 3;
const T_LINKS: u32 = 4;
const T_BUNDLES: u32 = 5;
const T_COUNTER: u32 = 6;
const USER_ID: u32 = 0;
const USER_NAME: u32 = 1;
const USER_SHARING: u32 = 7;
const TOKEN_KEY: u32 = 0;
const TOKEN_USER: u32 = 1;
const BM_OWNER: u32 = 0;
const BM_ID: u32 = 2;
const BM_URL: u32 = 3;
const BM_URL_NORM: u32 = 4;
const BM_UNREAD: u32 = 8;
const BM_ARCHIVED: u32 = 9;
const BM_SHARED: u32 = 10;
const TAG_ID: u32 = 0;
const TAG_OWNER: u32 = 1;
const TAG_LOWER: u32 = 3;
const LINK_BOOKMARK: u32 = 0;
const LINK_TAG: u32 = 1;
const BUNDLE_ID: u32 = 0;
const BUNDLE_OWNER: u32 = 1;

type Pred = h5i_app_sql::Pred;
type Read = h5i_app_sql::Read;
type Window = h5i_app_sql::Window;

fn v_int(x: u64) -> h5i_app_sql::Val {
    h5i_app_sql::Column::to_val(&x)
}

fn v_bool(x: bool) -> h5i_app_sql::Val {
    h5i_app_sql::Column::to_val(&x)
}

fn v_bytes(t: &Text) -> h5i_app_sql::Val {
    h5i_app_sql::Column::to_val(t)
}

fn p_eq(col: u32, v: h5i_app_sql::Val) -> Pred {
    Pred::Eq { col, val: v }
}

fn p_or(a: Pred, b: Pred) -> Pred {
    Pred::Or(Box::new(a), Box::new(b))
}

fn p_and(a: Pred, b: Pred) -> Pred {
    Pred::And(Box::new(a), Box::new(b))
}

fn p_in(col: u32, table: u32, pred: Pred, of: u32, window: Window) -> Pred {
    Pred::In { col, table, pred: Box::new(pred), of, window }
}

fn whole() -> Window {
    h5i_app_sql::whole()
}

fn rd(table: u32, pred: Pred) -> Read {
    Read { table, pred, window: whole() }
}

/// Column `col` is the caller's user id.
fn mine(col: u32, token: &Text) -> Pred {
    p_in(col, T_TOKENS, p_eq(TOKEN_KEY, v_bytes(token)), TOKEN_USER, whole())
}

/// The caller's token row and user row.
fn caller_reads(token: &Text) -> Vec<Read> {
    let mut out = Vec::new();
    out.push(rd(T_TOKENS, p_eq(TOKEN_KEY, v_bytes(token))));
    out.push(rd(T_USERS, mine(USER_ID, token)));
    out
}

/// The caller's token, users `extra` names, the caller's user row.
fn caller_reads_and(token: &Text, extra: Pred) -> Vec<Read> {
    let mut out = Vec::new();
    out.push(rd(T_TOKENS, p_eq(TOKEN_KEY, v_bytes(token))));
    out.push(rd(T_USERS, p_or(mine(USER_ID, token), extra)));
    out
}

/// Which bookmarks a plan views, as a predicate built afresh for each use
/// (a `Pred` is never cloned).
enum Sel {
    /// A paged listing's selection before paging.
    Paged(Text, Filter),
    /// The caller's bookmarks of a scope.
    Scope(Text, u8),
    /// Shared bookmarks of users who share.
    Shared,
    /// The caller's bookmarks of a URL.
    Url(Text, Text, Text),
    /// One bookmark.
    Id(u64),
}

fn sel_pred(sel: &Sel) -> Pred {
    match sel {
        Sel::Paged(t, f) => paged_pred(t, f),
        Sel::Scope(t, scope) => scope_pred(t, *scope),
        Sel::Shared => shared_pred(),
        Sel::Url(t, url, norm) => url_pred(t, url, norm),
        Sel::Id(id) => by_id(*id),
    }
}

/// Links of the bookmarks `sel` and `w` keep, and their tags.
fn tag_reads(sel: &Sel, w: Window, out: &mut Vec<Read>) {
    out.push(rd(T_LINKS, p_in(LINK_BOOKMARK, T_BOOKMARKS, sel_pred(sel), BM_ID, w)));
    out.push(rd(T_TAGS, p_in(TAG_ID, T_LINKS, p_in(LINK_BOOKMARK, T_BOOKMARKS, sel_pred(sel), BM_ID, w), LINK_TAG, whole())));
}

/// Bookmarks with a tag of this lowercased name.
fn tagged(lower: &Text) -> Pred {
    p_in(BM_ID, T_LINKS, p_in(LINK_TAG, T_TAGS, p_eq(TAG_LOWER, v_bytes(lower)), TAG_ID, whole()), LINK_BOOKMARK, whole())
}

/// What a `simple_query` selects; everything for any other query (the
/// listing is then not paged and the kernel filters).
fn search_pred(q: &Text) -> Pred {
    match simple_query(q) {
        None => Pred::All,
        Some((tags, unread)) => {
            let mut p = if unread { p_eq(BM_UNREAD, v_bool(true)) } else { Pred::All };
            let mut i = 0;
            while i < tags.len() {
                p = p_and(p, tagged(&lower_text(&tags[i])));
                i += 1;
            }
            p
        }
    }
}

fn flag_pred(col: u32, rule: u8, base: Pred) -> Pred {
    if rule == FLAG_YES {
        p_and(base, p_eq(col, v_bool(true)))
    } else if rule == FLAG_NO {
        p_and(base, p_eq(col, v_bool(false)))
    } else {
        base
    }
}

/// The caller's bookmarks of the scope.
fn scope_pred(token: &Text, scope: u8) -> Pred {
    p_and(mine(BM_OWNER, token), p_eq(BM_ARCHIVED, v_bool(scope == SCOPE_ARCHIVED)))
}

/// The bookmarks a paged listing selects (before paging).
fn paged_pred(token: &Text, flt: &Filter) -> Pred {
    let base = p_and(scope_pred(token, flt.scope), search_pred(&flt.q));
    flag_pred(BM_SHARED, flt.shared, flag_pred(BM_UNREAD, flt.unread, base))
}

/// Shared bookmarks of users who share.
fn shared_pred() -> Pred {
    p_and(p_eq(BM_SHARED, v_bool(true)), p_in(BM_OWNER, T_USERS, p_eq(USER_SHARING, v_bool(true)), USER_ID, whole()))
}

/// The newest `offset + limit` rows by key.
fn newest(offset: u64, limit: u64) -> Window {
    let lim = if limit > u64::MAX - offset { None } else { Some(offset + limit) };
    Window { desc: true, offset: 0, limit: lim }
}

/// A paged listing reads its page of the selection and counts the
/// selection (`list_count`); any other reads the whole scope.
fn list_reads(token: &Text, flt: &Filter, limit: u64, offset: u64) -> Vec<Read> {
    if flt.scope == SCOPE_SHARED {
        let extra = match &flt.user {
            Some(n) => p_or(p_eq(USER_SHARING, v_bool(true)), p_eq(USER_NAME, v_bytes(n))),
            None => p_eq(USER_SHARING, v_bool(true)),
        };
        let mut out = caller_reads_and(token, extra);
        out.push(rd(T_BOOKMARKS, shared_pred()));
        tag_reads(&Sel::Shared, whole(), &mut out);
        bundle_read(token, flt, &mut out);
        return out;
    }
    let mut out = caller_reads(token);
    if paged(flt) {
        let w = newest(offset, limit);
        let sel = Sel::Paged(token.clone(), flt.clone());
        out.push(Read { table: T_BOOKMARKS, pred: sel_pred(&sel), window: w });
        tag_reads(&sel, w, &mut out);
    } else {
        let sel = Sel::Scope(token.clone(), flt.scope);
        out.push(rd(T_BOOKMARKS, sel_pred(&sel)));
        tag_reads(&sel, whole(), &mut out);
        bundle_read(token, flt, &mut out);
    }
    out
}

/// The caller's bundle `?bundle=` names.
fn bundle_read(token: &Text, flt: &Filter, out: &mut Vec<Read>) {
    match flt.bundle {
        Some(id) => out.push(rd(T_BUNDLES, p_and(p_eq(BUNDLE_ID, v_int(id)), mine(BUNDLE_OWNER, token)))),
        None => {}
    }
}

/// The caller's bookmarks of this URL (`existing`).
fn url_pred(token: &Text, url: &Text, url_norm: &Text) -> Pred {
    let same = p_or(
        p_eq(BM_URL_NORM, v_bytes(url_norm)),
        p_and(p_eq(BM_URL_NORM, v_bytes(&Vec::new())), p_eq(BM_URL, v_bytes(url))),
    );
    p_and(mine(BM_OWNER, token), same)
}

/// The caller's tags with these names, any case.
fn named_tags(token: &Text, names: &Vec<Text>) -> Pred {
    let mut any = p_none_tag();
    let mut i = 0;
    while i < names.len() {
        any = p_or(any, p_eq(TAG_LOWER, v_bytes(&lower_text(&names[i]))));
        i += 1;
    }
    p_and(mine(TAG_OWNER, token), any)
}

fn p_none_tag() -> Pred {
    p_and(p_eq(TAG_ID, v_int(0)), p_eq(TAG_ID, v_int(1)))
}

fn by_id(id: u64) -> Pred {
    p_eq(BM_ID, v_int(id))
}

/// The rows `cmd` reads, one read per table it needs (a table without a read
/// loads empty), or `None` for the whole site.
pub fn reads(actor: &Principal, cmd: &Command) -> Option<Vec<Read>> {
    let t = &actor.token;
    match cmd {
        Command::Profile => Some(caller_reads(t)),
        Command::List { filter, limit, offset } => Some(list_reads(t, filter, *limit, *offset)),
        Command::Check { url, url_norm } => {
            let mut out = caller_reads(t);
            out.push(rd(T_BOOKMARKS, url_pred(t, url, url_norm)));
            tag_reads(&Sel::Url(t.clone(), url.clone(), url_norm.clone()), whole(), &mut out);
            Some(out)
        }
        Command::GetBookmark { id } => {
            let mut out = caller_reads(t);
            out.push(rd(T_BOOKMARKS, by_id(*id)));
            tag_reads(&Sel::Id(*id), whole(), &mut out);
            Some(out)
        }
        Command::CreateBookmark { fields, now: _ } => {
            let url = or_empty(&fields.url);
            let norm = or_empty(&fields.url_norm);
            let names = match &fields.tags {
                Some(n) => n.clone(),
                None => Vec::new(),
            };
            let mut out = caller_reads(t);
            out.push(rd(T_BOOKMARKS, url_pred(t, &url, &norm)));
            out.push(rd(T_TAGS, named_tags(t, &names)));
            out.push(rd(T_COUNTER, Pred::All));
            Some(out)
        }
        Command::UpdateBookmark { id, fields, now: _ } => {
            let mut out = caller_reads(t);
            let dup = match &fields.url {
                Some(u) => p_or(by_id(*id), p_and(mine(BM_OWNER, t), p_eq(BM_URL, v_bytes(u)))),
                None => by_id(*id),
            };
            out.push(rd(T_BOOKMARKS, dup));
            out.push(rd(T_LINKS, p_eq(LINK_BOOKMARK, v_int(*id))));
            let names = match &fields.tags {
                Some(n) => n.clone(),
                None => Vec::new(),
            };
            out.push(rd(
                T_TAGS,
                p_or(p_in(TAG_ID, T_LINKS, p_eq(LINK_BOOKMARK, v_int(*id)), LINK_TAG, whole()), named_tags(t, &names)),
            ));
            out.push(rd(T_COUNTER, Pred::All));
            Some(out)
        }
        Command::DeleteBookmark { id } | Command::Archive { id, archived: _, now: _ } => {
            let mut out = caller_reads(t);
            out.push(rd(T_BOOKMARKS, by_id(*id)));
            Some(out)
        }
        Command::ListTags { limit, offset } => {
            let mut out = caller_reads(t);
            let lim = if *limit > u64::MAX - *offset { None } else { Some(*offset + *limit) };
            out.push(Read { table: T_TAGS, pred: mine(TAG_OWNER, t), window: Window { desc: false, offset: 0, limit: lim } });
            Some(out)
        }
        Command::CreateTag { name, now: _ } => {
            let mut names = Vec::new();
            names.push(name.clone());
            let mut out = caller_reads(t);
            out.push(rd(T_TAGS, named_tags(t, &names)));
            out.push(rd(T_COUNTER, Pred::All));
            Some(out)
        }
        Command::GetTag { id } | Command::DeleteTag { id } => {
            let mut out = caller_reads(t);
            out.push(rd(T_TAGS, p_eq(TAG_ID, v_int(*id))));
            Some(out)
        }
        Command::ListBundles { limit: _, offset: _ }
        | Command::GetBundle { id: _ }
        | Command::UpdateBundle { id: _, fields: _, now: _ }
        | Command::DeleteBundle { id: _ } => {
            let mut out = caller_reads(t);
            out.push(rd(T_BUNDLES, mine(BUNDLE_OWNER, t)));
            Some(out)
        }
        Command::CreateBundle { fields: _, now: _ } => {
            let mut out = caller_reads(t);
            out.push(rd(T_BUNDLES, mine(BUNDLE_OWNER, t)));
            out.push(rd(T_COUNTER, Pred::All));
            Some(out)
        }
    }
}

/// What a paged listing or the tag list counts for its `count`: the rows
/// before paging.
pub fn list_count(actor: &Principal, cmd: &Command) -> Option<Read> {
    let t = &actor.token;
    match cmd {
        Command::List { filter, limit: _, offset: _ } => {
            if paged(filter) {
                Some(rd(T_BOOKMARKS, paged_pred(t, filter)))
            } else {
                None
            }
        }
        Command::ListTags { limit: _, offset: _ } => Some(rd(T_TAGS, mine(TAG_OWNER, t))),
        _ => None,
    }
}

/* Apply */

/// What one write does to the state. `schema!` runs it over a write set.
fn apply_write(s: &mut Snapshot, w: Write) {
    match w {
        Write::PutBookmark(x) => Bookmark::put(&mut s.bookmarks, x),
        Write::DelBookmark(o, a, id) => s.bookmarks = Bookmark::del(&s.bookmarks, o, a, id),
        Write::PutTag(x) => Tag::put(&mut s.tags, x),
        Write::DelTag(id) => s.tags = Tag::del(&s.tags, id),
        Write::PutLink(x) => Link::put(&mut s.links, x),
        Write::DelLinksOf(id) => s.links = Link::del_where(&s.links, LINK_BOOKMARK, &h5i_app_sql::Column::to_val(&id)),
        Write::DelLinksTo(id) => s.links = Link::del_where(&s.links, LINK_TAG, &h5i_app_sql::Column::to_val(&id)),
        Write::PutBundle(x) => Bundle::put(&mut s.bundles, x),
        Write::DelBundle(id) => s.bundles = Bundle::del(&s.bundles, id),
        Write::SetCounter(c) => s.counter = c,
    }
}

/// The table writes one write makes.
fn sql_write(w: &Write, out: &mut Vec<h5i_app_sql::Write>) {
    match w {
        Write::PutBookmark(x) => out.push(x.sql_put()),
        Write::DelBookmark(o, a, id) => out.push(Bookmark::sql_del(*o, *a, *id)),
        Write::PutTag(x) => out.push(x.sql_put()),
        Write::DelTag(id) => out.push(Tag::sql_del(*id)),
        Write::PutLink(x) => out.push(x.sql_put()),
        Write::DelLinksOf(id) => out.push(Link::sql_del_where(LINK_BOOKMARK, h5i_app_sql::Column::to_val(id))),
        Write::DelLinksTo(id) => out.push(Link::sql_del_where(LINK_TAG, h5i_app_sql::Column::to_val(id))),
        Write::PutBundle(x) => out.push(x.sql_put()),
        Write::DelBundle(id) => out.push(Bundle::sql_del(*id)),
        Write::SetCounter(c) => out.push(c.sql_put()),
    }
}
