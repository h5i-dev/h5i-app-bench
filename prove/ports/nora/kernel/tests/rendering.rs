#[path = "../../difftest/rendering/reference.rs"]
mod reference;
use nora_kernel::rendering as k;

#[test]
fn escaping_matches_all_unicode_scalars_and_combinations() {
    let mut comparisons = 0;
    for n in 0..=0x10ffff {
        if let Some(c) = char::from_u32(n) {
            let s = c.to_string();
            assert_eq!(k::html_escape(s.as_bytes()), reference::html_escape(&s).as_bytes());
            assert_eq!(k::encode_uri_component(s.as_bytes()), reference::encode_uri_component(&s).as_bytes());
            comparisons += 2;
        }
    }
    let mut seed = 0x08bda9345f7u64;
    for _ in 0..10000 {
        let mut s = String::from("&amp;<>&\"' /%?#\0");
        for _ in 0..64 {
            seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
            if let Some(c) = char::from_u32((seed >> 32) as u32 % 0x110000) { s.push(c); }
        }
        assert_eq!(k::html_escape(s.as_bytes()), reference::html_escape(&s).as_bytes());
        assert_eq!(k::encode_uri_component(s.as_bytes()), reference::encode_uri_component(&s).as_bytes());
        comparisons += 2;
    }
    eprintln!("{comparisons} complete escaping string comparisons");
}

#[test]
fn complete_fragments_match_retained_upstream() {
    let strings = ["", "plain", "<script>&\"'", "Русский/中文/🦀", "PULL", "PUSH", "CACHE", "PROXY", "pull", "\0\r\n"];
    let mut comparisons = 0;
    for a in strings { for b in strings { for c in strings {
        assert_eq!(k::render_activity_row(a.as_bytes(), b.as_bytes(), c.as_bytes(), a.as_bytes(), c.as_bytes()), reference::render_activity_row(a,b,c,a,c).as_bytes());
        assert_eq!(k::registry_search_bar(a.as_bytes(),b.as_bytes()), reference::search(a,b).as_bytes());
        let t = reference::Translations { recent_activity:a,last_n_events:b,time:c,action:a,artifact:b,registry:c,source:a };
        let kt = k::Translations { recent_activity:a.into(),last_n_events:b.into(),time:c.into(),action:a.into(),artifact:b.into(),registry:c.into(),source:a.into() };
        assert_eq!(k::render_activity_log(c.as_bytes(),&kt), reference::render_activity_log(c,&t).as_bytes());
        comparisons += 3;
    }}}
    for (kl,l) in [(k::Lang::En,reference::Lang::En),(k::Lang::Ru,reference::Lang::Ru),(k::Lang::Zh,reference::Lang::Zh)] {
        assert_eq!(k::header_dark(kl),reference::header(l).as_bytes()); comparisons += 1;
    }
    assert_eq!(k::render_polling_script(),reference::render_polling_script().as_bytes()); comparisons+=1;
    eprintln!("{comparisons} complete HTML fragment comparisons");
}

#[test]
fn fragment_fields_remain_distinct() {
    let values = ["", "PULL", "PUSH", "CACHE", "PROXY", "other", "<>&\"'", "Русский/中文/🦀", "\0\r\n"];
    let mut seed = 0xd87454a4e0d32bc9u64;
    for _ in 0..2000 {
        let mut choose = || {
            seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
            values[(seed >> 32) as usize % values.len()]
        };
        let (timestamp, action, artifact, registry, source) = (choose(), choose(), choose(), choose(), choose());
        assert_eq!(k::render_activity_row(timestamp.as_bytes(), action.as_bytes(), artifact.as_bytes(), registry.as_bytes(), source.as_bytes()), reference::render_activity_row(timestamp, action, artifact, registry, source).as_bytes());
        let (recent_activity, last_n_events, time, action, artifact, registry, source, rows) = (choose(), choose(), choose(), choose(), choose(), choose(), choose(), choose());
        let t = reference::Translations { recent_activity, last_n_events, time, action, artifact, registry, source };
        let kt = k::Translations { recent_activity: recent_activity.into(), last_n_events: last_n_events.into(), time: time.into(), action: action.into(), artifact: artifact.into(), registry: registry.into(), source: source.into() };
        assert_eq!(k::render_activity_log(rows.as_bytes(), &kt), reference::render_activity_log(rows, &t).as_bytes());
    }
    eprintln!("4000 additional comparisons with independently selected fields");
}
