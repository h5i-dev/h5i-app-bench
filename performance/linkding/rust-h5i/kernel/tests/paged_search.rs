//! A paged listing selects by its `simple_query` (tags and `!unread`), not by
//! the search code. This checks, on generated states and queries, that it
//! selects what the search code selects: the same listing in another order
//! (which reads the whole scope and runs the search) returns the same
//! bookmarks, in both search modes and with lax search.

use linkding_kernel::*;

struct Rng(u64);

impl Rng {
    fn next(&mut self) -> u64 {
        self.0 ^= self.0 << 13;
        self.0 ^= self.0 >> 7;
        self.0 ^= self.0 << 17;
        self.0
    }
    fn below(&mut self, n: u64) -> u64 {
        self.next() % n
    }
}

const NAMES: [&str; 5] = ["Rust", "go", "Web", "db", "x-y"];

fn user(id: u64, lax: bool, legacy: bool) -> User {
    User {
        id,
        username: format!("u{id}").into_bytes(),
        theme: b"auto".to_vec(),
        date_display: b"relative".to_vec(),
        link_target: b"_blank".to_vec(),
        web_archive: b"auto".to_vec(),
        lax,
        sharing: false,
        public_sharing: false,
        favicons: false,
        display_url: false,
        permanent_notes: false,
        search_prefs: b"{}".to_vec(),
        legacy,
    }
}

fn state(rng: &mut Rng, lax: bool, legacy: bool) -> Snapshot {
    let mut s = Snapshot::default();
    s.users.push(user(1, lax, legacy));
    s.tokens.push(Token { key: b"t1".to_vec(), user: 1 });
    for (i, n) in NAMES.iter().enumerate() {
        let name = n.as_bytes().to_vec();
        s.tags.push(Tag { id: i as u64 + 1, owner: 1, name_lower: lower_text(&name), name, added: 0 });
    }
    for id in 1..=30u64 {
        s.bookmarks.push(Bookmark {
            owner: 1,
            added: id,
            id,
            url: format!("https://e.com/{id}").into_bytes(),
            url_norm: Vec::new(),
            title: Vec::new(),
            description: Vec::new(),
            notes: Vec::new(),
            unread: rng.below(2) == 0,
            archived: rng.below(5) == 0,
            shared: rng.below(2) == 0,
            modified: id,
        });
        for t in 1..=NAMES.len() as u64 {
            if rng.below(3) == 0 {
                s.links.push(Link { bookmark: id, tag: t });
            }
        }
    }
    s
}

fn query(rng: &mut Rng) -> Vec<u8> {
    let mut q = String::new();
    for _ in 0..rng.below(4) {
        let w = match rng.below(6) {
            0 => "!unread".to_string(),
            1 => "!other".to_string(),
            _ => {
                let n = NAMES[rng.below(NAMES.len() as u64) as usize];
                let n = if rng.below(2) == 0 { n.to_uppercase() } else { n.to_string() };
                format!("#{n}")
            }
        };
        q.push_str(&w);
        q.push_str(if rng.below(3) == 0 { "  " } else { " " });
    }
    q.into_bytes()
}

fn ids(s: &Snapshot, flt: Filter) -> Vec<u64> {
    let cmd = Command::List { filter: flt, limit: 1000, offset: 0 };
    match transition(&Principal { org: 0, token: b"t1".to_vec() }, s, &cmd) {
        Ok((_, Reply::Bookmarks { items, .. })) => items.iter().map(|v| v.bookmark.id).collect(),
        other => panic!("unexpected {other:?}"),
    }
}

#[test]
fn paged_listing_selects_what_search_selects() {
    let mut rng = Rng(0x9e3779b97f4a7c15);
    let mut paged_seen = 0;
    for round in 0..600 {
        let s = state(&mut rng, round % 3 == 1, round % 3 == 2);
        let q = query(&mut rng);
        let flt = Filter {
            scope: (rng.below(2)) as u8,
            q,
            user: None,
            unread: rng.below(3) as u8,
            shared: rng.below(3) as u8,
            added_since: None,
            modified_since: None,
            sort: SORT_ADDED_DESC,
            bundle: None,
        };
        if paged(&flt) {
            paged_seen += 1;
        }
        let by_rule = ids(&s, flt.clone());
        let mut by_search = ids(&s, Filter { sort: SORT_ADDED_ASC, ..flt.clone() });
        by_search.reverse();
        assert_eq!(by_rule, by_search, "query {:?}", String::from_utf8_lossy(&flt.q));
    }
    assert!(paged_seen > 300);
}
