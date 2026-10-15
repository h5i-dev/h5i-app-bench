use conduit_kernel::make_slug;

fn slug(title: &str, n: u64) -> String {
    String::from_utf8(make_slug(&title.as_bytes().to_vec(), n)).unwrap()
}

#[test]
fn slug_rules() {
    assert_eq!(slug("Test Article 12", 0), "test-article-12");
    assert_eq!(slug("Test Article 12", 1), "test-article-12-1");
    assert_eq!(slug("  --Hi-- ", 0), "hi");
    assert_eq!(slug("", 0), "article");
    assert_eq!(slug("!!!", 0), "article");
    assert_eq!(slug("A_B", 0), "a-b");
    assert_eq!(slug("Dup Title", 2), "dup-title-2");
    assert_eq!(slug("a  b", 0), "a-b");
    assert_eq!(slug("already-slugged", 0), "already-slugged");
}
