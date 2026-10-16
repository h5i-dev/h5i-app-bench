use linkding_kernel::{bookmark_matches, parse_search, valid_url, BookmarkFacts};

fn facts(title: &str, tags: &[&str], unread: bool, untagged: bool) -> BookmarkFacts {
    BookmarkFacts {
        title: title.as_bytes().to_vec(),
        description: Vec::new(),
        notes: Vec::new(),
        url: Vec::new(),
        unread,
        untagged,
        tag_names: tags.iter().map(|tag| tag.as_bytes().to_vec()).collect(),
    }
}

fn matches(query: &str, title: &str) -> bool {
    let parsed = parse_search(&query.as_bytes().to_vec());
    assert!(!parsed.failed, "parse failed: {query}");
    bookmark_matches(&parsed, false, &facts(title, &[], false, true))
}

#[test]
fn operators() {
    assert!(matches("alpha or beta gamma", "alpha"));
    assert!(matches("alpha or beta gamma", "beta gamma"));
    assert!(!matches("alpha or beta gamma", "beta"));
    assert!(matches("(alpha or beta) gamma", "alpha gamma"));
    assert!(!matches("(alpha or beta) gamma", "alpha"));
    assert!(!matches("alpha and missing", "alpha"));
    let parsed = parse_search(&b"(alpha".to_vec());
    assert!(parsed.failed);
    assert!(!bookmark_matches(&parsed, false, &facts("alpha", &[], false, true)));
    let empty = parse_search(&Vec::new());
    assert!(empty.empty);
    assert!(bookmark_matches(&empty, false, &facts("z", &[], false, true)));
}

#[test]
fn urls() {
    assert!(valid_url(&b"https://example.com/x".to_vec()));
    assert!(valid_url(&b"http://127.0.0.1:9/blocked".to_vec()));
    assert!(valid_url(&b"ftp://example.com/file".to_vec()));
    assert!(valid_url(&b"http://user:pass@example.com/x".to_vec()));
    assert!(!valid_url(&b"http://example".to_vec()));
    assert!(!valid_url(&b"not a url".to_vec()));
}
