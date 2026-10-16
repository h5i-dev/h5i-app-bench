//! Request validation, URL normalization, and SQL compiled from the kernel AST.
//! Text comparison in SQL is `ILIKE`. The kernel predicate uses ASCII case-folding.

use chrono::{DateTime, NaiveDateTime, Utc};
use linkding_kernel::{
    page_of, parse_search, Parsed, NODE_AND, NODE_KEYWORD, NODE_NOT, NODE_OR, NODE_TAG, NODE_TERM,
};
use serde_json::{Map, Value};
use url::Url;

pub const VERSION: &str = "1.47.0";
const DT_ERROR: &str = "Datetime has wrong format. Use one of these formats instead: YYYY-MM-DDThh:mm[:ss[.uuuuuu]][+HH:MM|-HH:MM|Z].";

const TRUE_VALUES: &[&str] = &[
    "t", "T", "y", "Y", "yes", "YES", "Yes", "true", "True", "TRUE", "on", "On", "ON", "1",
];
const FALSE_VALUES: &[&str] = &[
    "f", "F", "n", "N", "no", "NO", "No", "false", "False", "FALSE", "off", "Off", "OFF", "0",
];

#[derive(Clone, Debug)]
pub enum Arg {
    I64(i64),
    Text(String),
    Bool(bool),
    Time(DateTime<Utc>),
}

#[derive(Clone, Debug)]
pub struct Sql {
    pub text: String,
    pub args: Vec<Arg>,
}

impl Sql {
    pub fn new() -> Self {
        Self {
            text: String::new(),
            args: Vec::new(),
        }
    }

    pub fn bind(&mut self, arg: Arg) -> String {
        self.args.push(arg);
        format!("${}", self.args.len())
    }
}

#[derive(Clone, Debug)]
pub struct BookmarkIn {
    pub present: Vec<String>,
    pub url: String,
    pub title: String,
    pub description: String,
    pub notes: String,
    pub unread: bool,
    pub shared: bool,
    pub is_archived: bool,
    pub tag_names: Vec<String>,
    pub date_added: Option<DateTime<Utc>>,
    pub date_modified: Option<DateTime<Utc>>,
}

impl BookmarkIn {
    fn new() -> Self {
        Self {
            present: Vec::new(),
            url: String::new(),
            title: String::new(),
            description: String::new(),
            notes: String::new(),
            unread: false,
            shared: false,
            is_archived: false,
            tag_names: Vec::new(),
            date_added: None,
            date_modified: None,
        }
    }

    pub fn has(&self, field: &str) -> bool {
        self.present.iter().any(|item| item == field)
    }
}

#[derive(Clone, Debug)]
pub struct BundleIn {
    pub present: Vec<String>,
    pub name: String,
    pub search: String,
    pub any_tags: String,
    pub all_tags: String,
    pub excluded_tags: String,
    pub filter_unread: String,
    pub filter_shared: String,
    pub order: i32,
}

impl BundleIn {
    fn new() -> Self {
        Self {
            present: Vec::new(),
            name: String::new(),
            search: String::new(),
            any_tags: String::new(),
            all_tags: String::new(),
            excluded_tags: String::new(),
            filter_unread: String::new(),
            filter_shared: String::new(),
            order: 0,
        }
    }

    pub fn has(&self, field: &str) -> bool {
        self.present.iter().any(|item| item == field)
    }
}

fn mark(present: &mut Vec<String>, field: &str) {
    present.push(field.to_string());
}

fn add_error(errors: &mut Map<String, Value>, field: &str, message: &str) {
    errors
        .entry(field)
        .or_insert_with(|| Value::Array(Vec::new()))
        .as_array_mut()
        .expect("error list")
        .push(Value::String(message.to_string()));
}

pub fn fmt_time(value: DateTime<Utc>) -> String {
    let nanos = value.timestamp_subsec_nanos();
    if nanos == 0 {
        value.format("%Y-%m-%dT%H:%M:%SZ").to_string()
    } else {
        let micro = nanos / 1000;
        format!("{}{:06}Z", value.format("%Y-%m-%dT%H:%M:%S."), micro)
    }
}

pub fn archive_url(raw: &str, when: DateTime<Utc>) -> String {
    format!(
        "https://web.archive.org/web/{}/{}",
        when.format("%Y%m%d%H%M%S"),
        raw
    )
}

pub fn parse_time(raw: &str) -> Option<DateTime<Utc>> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return None;
    }
    let normalized = if let Some(rest) = trimmed.strip_suffix('Z') {
        format!("{rest}+00:00")
    } else {
        trimmed.to_string()
    };
    let zoned = [
        "%Y-%m-%dT%H:%M:%S%.f%:z",
        "%Y-%m-%dT%H:%M:%S%:z",
        "%Y-%m-%dT%H:%M%:z",
        "%Y-%m-%dT%H:%M:%S%.f%z",
        "%Y-%m-%dT%H:%M:%S%z",
        "%Y-%m-%dT%H:%M%z",
    ];
    for layout in zoned {
        if let Ok(parsed) = DateTime::parse_from_str(&normalized, layout) {
            return Some(parsed.with_timezone(&Utc));
        }
    }
    let naive = [
        "%Y-%m-%dT%H:%M:%S%.f",
        "%Y-%m-%dT%H:%M:%S",
        "%Y-%m-%dT%H:%M",
    ];
    for layout in naive {
        if let Ok(parsed) = NaiveDateTime::parse_from_str(&normalized, layout) {
            return Some(parsed.and_utc());
        }
    }
    None
}

fn py_quote(value: &str) -> String {
    let mut out = String::new();
    for byte in value.as_bytes() {
        match byte {
            b'a'..=b'z' | b'A'..=b'Z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' | b'/' => {
                out.push(*byte as char)
            }
            _ => out.push_str(&format!("%{byte:02X}")),
        }
    }
    out
}

fn percent_encode(value: &str) -> String {
    let mut out = String::new();
    for byte in value.as_bytes() {
        match byte {
            b'a'..=b'z' | b'A'..=b'Z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => {
                out.push(*byte as char)
            }
            _ => out.push_str(&format!("%{byte:02X}")),
        }
    }
    out
}

pub fn normalize_url(raw: &str) -> String {
    let raw = raw.trim();
    if raw.is_empty() {
        return String::new();
    }
    let Ok(parsed) = Url::parse(raw) else {
        return raw.to_string();
    };
    let Some(host) = parsed.host_str() else {
        return raw.to_string();
    };
    if host.is_empty() {
        return raw.to_string();
    }
    let mut netloc = host.to_lowercase();
    if let Some(port) = parsed.port() {
        netloc = format!("{netloc}:{port}");
    }
    if !parsed.username().is_empty() {
        let mut auth = parsed.username().to_string();
        let password = parsed.password().unwrap_or("");
        if !password.is_empty() {
            auth.push(':');
            auth.push_str(password);
        }
        netloc = format!("{auth}@{netloc}");
    }
    let path = parsed.path().trim_end_matches('/');
    let mut pairs: Vec<(String, String)> = parsed
        .query_pairs()
        .map(|(k, v)| (k.into_owned(), v.into_owned()))
        .collect();
    pairs.sort_by(|a, b| a.0.cmp(&b.0).then(a.1.cmp(&b.1)));
    let query = pairs
        .iter()
        .map(|(k, v)| format!("{}={}", py_quote(k), py_quote(v)))
        .collect::<Vec<_>>()
        .join("&");
    let mut out = format!("{}://{}{}", parsed.scheme(), netloc, path);
    if !query.is_empty() {
        out.push('?');
        out.push_str(&query);
    }
    if let Some(fragment) = parsed.fragment() {
        if !fragment.is_empty() {
            out.push('#');
            out.push_str(fragment);
        }
    }
    out
}

pub fn valid_url(value: &str) -> bool {
    let bytes = value.as_bytes().to_vec();
    linkding_kernel::valid_url(&bytes)
}

fn decode_component(raw: &str) -> String {
    let mut out = String::new();
    let bytes = raw.as_bytes();
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'+' {
            out.push(' ');
            i += 1;
        } else if bytes[i] == b'%' && i + 2 < bytes.len() {
            let hex = &raw[i + 1..i + 3];
            if let Ok(value) = u8::from_str_radix(hex, 16) {
                out.push(value as char);
                i += 3;
            } else {
                out.push('%');
                i += 1;
            }
        } else {
            out.push(bytes[i] as char);
            i += 1;
        }
    }
    out
}

fn split_raw(raw: &str) -> (String, String, String) {
    let (body, fragment) = match raw.split_once('#') {
        Some((left, right)) => (left.to_string(), right.to_string()),
        None => (raw.to_string(), String::new()),
    };
    let (base, query) = match body.split_once('?') {
        Some((left, right)) => (left.to_string(), right.to_string()),
        None => (body, String::new()),
    };
    (base, query, fragment)
}

fn parse_query(raw: &str) -> Vec<(String, Vec<String>)> {
    let mut keys: Vec<String> = Vec::new();
    let mut values: Vec<Vec<String>> = Vec::new();
    if raw.is_empty() {
        return Vec::new();
    }
    for part in raw.split('&') {
        if part.is_empty() {
            continue;
        }
        let (key, val) = match part.split_once('=') {
            Some((k, v)) => (decode_component(k), decode_component(v)),
            None => (decode_component(part), String::new()),
        };
        if let Some(pos) = keys.iter().position(|item| item == &key) {
            values[pos].push(val);
        } else {
            keys.push(key);
            values.push(vec![val]);
        }
    }
    keys.into_iter().zip(values).collect()
}

fn encode_query(pairs: &[(String, Vec<String>)]) -> String {
    let mut keys: Vec<&str> = pairs.iter().map(|(k, _)| k.as_str()).collect();
    keys.sort();
    let mut parts = Vec::new();
    for key in keys {
        if let Some((_, values)) = pairs.iter().find(|(k, _)| k == key) {
            for value in values {
                parts.push(format!("{}={}", percent_encode(key), percent_encode(value)));
            }
        }
    }
    parts.join("&")
}

fn replace_query_param(raw: &str, key: &str, val: &str) -> String {
    let (base, query, fragment) = split_raw(raw);
    let mut pairs = parse_query(&query);
    if let Some(pos) = pairs.iter().position(|(k, _)| k == key) {
        pairs[pos].1 = vec![val.to_string()];
    } else {
        pairs.push((key.to_string(), vec![val.to_string()]));
    }
    let encoded = encode_query(&pairs);
    let mut out = base;
    if !encoded.is_empty() {
        out.push('?');
        out.push_str(&encoded);
    }
    if !fragment.is_empty() {
        out.push('#');
        out.push_str(&fragment);
    }
    out
}

fn remove_query_param(raw: &str, key: &str) -> String {
    let (base, query, fragment) = split_raw(raw);
    let pairs: Vec<(String, Vec<String>)> = parse_query(&query)
        .into_iter()
        .filter(|(k, _)| k != key)
        .collect();
    let encoded = encode_query(&pairs);
    let mut out = base;
    if !encoded.is_empty() {
        out.push('?');
        out.push_str(&encoded);
    }
    if !fragment.is_empty() {
        out.push('#');
        out.push_str(&fragment);
    }
    out
}

/// Last value wins, matching Django's QueryDict.get.
pub fn query_map(raw: &str) -> Vec<(String, String)> {
    parse_query(raw)
        .into_iter()
        .filter_map(|(k, v)| v.last().cloned().map(|last| (k, last)))
        .collect()
}

pub fn query_get<'a>(pairs: &'a [(String, String)], key: &str) -> Option<&'a str> {
    pairs
        .iter()
        .rev()
        .find(|(k, _)| k == key)
        .map(|(_, v)| v.as_str())
}

pub fn page_params(pairs: &[(String, String)]) -> (bool, u64, bool, u64) {
    let limit = match query_get(pairs, "limit") {
        None | Some("") => (true, 0),
        Some(text) => match text.parse::<i64>() {
            Ok(n) if n > 0 => (false, n as u64),
            _ => (true, 0),
        },
    };
    let offset = match query_get(pairs, "offset") {
        None | Some("") => (false, 0),
        Some(text) => match text.parse::<i64>() {
            Ok(n) if n >= 0 => (false, n as u64),
            _ => (true, 0),
        },
    };
    (limit.0, limit.1, offset.0, offset.1)
}

pub fn page_links(raw: &str, count: i64, limit_bad: bool, limit: u64, offset_bad: bool, offset: u64) -> (Option<String>, Option<String>) {
    let count_u = if count < 0 { 0 } else { count as u64 };
    let page = page_of(limit_bad, limit, offset_bad, offset, count_u);
    let mut next = None;
    if page.has_next {
        let advanced = page.offset.saturating_add(page.limit);
        let with_limit = replace_query_param(raw, "limit", &page.limit.to_string());
        next = Some(replace_query_param(&with_limit, "offset", &advanced.to_string()));
    }
    let mut prev = None;
    if page.has_prev {
        let with_limit = replace_query_param(raw, "limit", &page.limit.to_string());
        if page.prev_drop_offset {
            prev = Some(remove_query_param(&with_limit, "offset"));
        } else {
            prev = Some(replace_query_param(
                &with_limit,
                "offset",
                &page.prev_offset.to_string(),
            ));
        }
    }
    (next, prev)
}

pub fn page_limit_offset(count: i64, limit_bad: bool, limit: u64, offset_bad: bool, offset: u64) -> (i64, i64) {
    let count_u = if count < 0 { 0 } else { count as u64 };
    let page = page_of(limit_bad, limit, offset_bad, offset, count_u);
    (page.limit as i64, page.offset as i64)
}

pub fn classify_auth(header: &str) -> (&'static str, String) {
    if header.trim().is_empty() {
        return ("absent", String::new());
    }
    let parts: Vec<&str> = header.split_whitespace().collect();
    if parts.is_empty() {
        return ("absent", String::new());
    }
    let keyword = parts[0].to_ascii_lowercase();
    if keyword != "token" && keyword != "bearer" {
        return ("absent", String::new());
    }
    if parts.len() == 1 {
        return ("nocreds", String::new());
    }
    if parts.len() > 2 {
        return ("spaces", String::new());
    }
    ("token", parts[1].to_string())
}

pub fn auth_detail(kind: &str) -> &'static str {
    match kind {
        "nocreds" => "Invalid token header. No credentials provided.",
        "spaces" => "Invalid token header. Token string should not contain spaces.",
        "bad" => "Invalid token.",
        _ => "Authentication credentials were not provided.",
    }
}

fn parse_bool(value: &Value) -> Option<bool> {
    match value {
        Value::Bool(flag) => Some(*flag),
        Value::Number(number) => {
            if number.as_i64() == Some(1) || number.as_u64() == Some(1) {
                Some(true)
            } else if number.as_i64() == Some(0) || number.as_u64() == Some(0) {
                Some(false)
            } else {
                None
            }
        }
        Value::String(text) => {
            if TRUE_VALUES.contains(&text.as_str()) {
                Some(true)
            } else if FALSE_VALUES.contains(&text.as_str()) {
                Some(false)
            } else {
                None
            }
        }
        _ => None,
    }
}

fn py_type_name(value: &Value) -> &'static str {
    match value {
        Value::String(_) => "str",
        Value::Bool(_) => "bool",
        Value::Array(_) => "list",
        Value::Object(_) => "dict",
        Value::Number(number) => {
            if number.as_f64().is_some_and(|n| n.fract() != 0.0) {
                "float"
            } else {
                "int"
            }
        }
        Value::Null => "NoneType",
    }
}

fn take_text(
    data: &Map<String, Value>,
    field: &str,
    errors: &mut Map<String, Value>,
    required: bool,
    allow_blank: bool,
    max_len: usize,
) -> Option<String> {
    let Some(value) = data.get(field) else {
        if required {
            add_error(errors, field, "This field is required.");
        }
        return None;
    };
    if value.is_null() {
        add_error(errors, field, "This field may not be null.");
        return Some(String::new());
    }
    let Some(text) = value.as_str() else {
        add_error(errors, field, "Not a valid string.");
        return Some(String::new());
    };
    let text = text.trim();
    if text.is_empty() && !allow_blank {
        add_error(errors, field, "This field may not be blank.");
        return Some(String::new());
    }
    if max_len > 0 && text.chars().count() > max_len {
        add_error(
            errors,
            field,
            &format!("Ensure this field has no more than {max_len} characters."),
        );
        return Some(String::new());
    }
    Some(text.to_string())
}

fn take_url(data: &Map<String, Value>, errors: &mut Map<String, Value>, required: bool) -> Option<String> {
    let Some(value) = data.get("url") else {
        if required {
            add_error(errors, "url", "This field is required.");
        }
        return None;
    };
    if value.is_null() {
        add_error(errors, "url", "This field may not be null.");
        return Some(String::new());
    }
    let Some(text) = value.as_str() else {
        add_error(errors, "url", "Enter a valid URL.");
        return Some(String::new());
    };
    let text = text.trim();
    if text.is_empty() {
        add_error(errors, "url", "This field may not be blank.");
        return Some(String::new());
    }
    let mut messages = Vec::new();
    if text.len() > 2048 || !valid_url(text) {
        messages.push("Enter a valid URL.");
    }
    if text.len() > 2048 {
        messages.push("Ensure this field has no more than 2048 characters.");
    }
    if !messages.is_empty() {
        errors.insert(
            "url".to_string(),
            Value::Array(messages.into_iter().map(|m| Value::String(m.to_string())).collect()),
        );
        return Some(String::new());
    }
    Some(text.to_string())
}

pub fn validate_bookmark(data: &Map<String, Value>, partial: bool) -> (Map<String, Value>, BookmarkIn) {
    let mut errors = Map::new();
    let mut cleaned = BookmarkIn::new();
    if let Some(url) = take_url(data, &mut errors, !partial) {
        if !errors.contains_key("url") {
            mark(&mut cleaned.present, "url");
            cleaned.url = url;
        }
    }
    for (field, max_len) in [("title", 512usize), ("description", 0), ("notes", 0)] {
        if let Some(text) = take_text(data, field, &mut errors, false, true, max_len) {
            if !errors.contains_key(field) {
                mark(&mut cleaned.present, field);
                match field {
                    "title" => cleaned.title = text,
                    "description" => cleaned.description = text,
                    "notes" => cleaned.notes = text,
                    _ => {}
                }
            }
        }
    }
    for field in ["unread", "shared", "is_archived"] {
        let Some(value) = data.get(field) else {
            continue;
        };
        if value.is_null() {
            add_error(&mut errors, field, "This field may not be null.");
            continue;
        }
        let Some(flag) = parse_bool(value) else {
            add_error(&mut errors, field, "Must be a valid boolean.");
            continue;
        };
        mark(&mut cleaned.present, field);
        match field {
            "unread" => cleaned.unread = flag,
            "shared" => cleaned.shared = flag,
            "is_archived" => cleaned.is_archived = flag,
            _ => {}
        }
    }
    if let Some(value) = data.get("tag_names") {
        if value.is_null() {
            add_error(&mut errors, "tag_names", "This field may not be null.");
        } else if let Some(list) = value.as_array() {
            let mut names = Vec::new();
            let mut bad = false;
            for item in list {
                if let Some(text) = item.as_str() {
                    names.push(text.to_string());
                } else {
                    add_error(&mut errors, "tag_names", "Not a valid string.");
                    bad = true;
                    break;
                }
            }
            if !bad {
                mark(&mut cleaned.present, "tag_names");
                cleaned.tag_names = names;
            }
        } else {
            add_error(
                &mut errors,
                "tag_names",
                &format!(
                    "Expected a list of items but got type \"{}\".",
                    py_type_name(value)
                ),
            );
        }
    }
    for field in ["date_added", "date_modified"] {
        let Some(value) = data.get(field) else {
            continue;
        };
        if value.is_null() {
            add_error(&mut errors, field, "This field may not be null.");
            continue;
        }
        let parsed = value.as_str().and_then(parse_time);
        let Some(parsed) = parsed else {
            add_error(&mut errors, field, DT_ERROR);
            continue;
        };
        mark(&mut cleaned.present, field);
        if field == "date_added" {
            cleaned.date_added = Some(parsed);
        } else {
            cleaned.date_modified = Some(parsed);
        }
    }
    (errors, cleaned)
}

pub fn validate_tag(data: &Map<String, Value>) -> (Map<String, Value>, String) {
    let mut errors = Map::new();
    let name = take_text(data, "name", &mut errors, true, false, 64).unwrap_or_default();
    if errors.is_empty() {
        (errors, name)
    } else {
        (errors, String::new())
    }
}

fn shown_choice(value: &Value) -> String {
    match value {
        Value::String(text) => text.clone(),
        Value::Number(number) => number.to_string(),
        Value::Bool(flag) => flag.to_string(),
        Value::Null => "null".to_string(),
        other => other.to_string(),
    }
}

pub fn validate_bundle(data: &Map<String, Value>, partial: bool) -> (Map<String, Value>, BundleIn) {
    let mut errors = Map::new();
    let mut cleaned = BundleIn::new();
    if let Some(name) = take_text(data, "name", &mut errors, !partial, false, 256) {
        if !errors.contains_key("name") {
            mark(&mut cleaned.present, "name");
            cleaned.name = name;
        }
    }
    for (field, max_len) in [
        ("search", 256usize),
        ("any_tags", 1024),
        ("all_tags", 1024),
        ("excluded_tags", 1024),
    ] {
        if let Some(text) = take_text(data, field, &mut errors, false, true, max_len) {
            if !errors.contains_key(field) {
                mark(&mut cleaned.present, field);
                match field {
                    "search" => cleaned.search = text,
                    "any_tags" => cleaned.any_tags = text,
                    "all_tags" => cleaned.all_tags = text,
                    "excluded_tags" => cleaned.excluded_tags = text,
                    _ => {}
                }
            }
        }
    }
    for field in ["filter_unread", "filter_shared"] {
        let Some(value) = data.get(field) else {
            continue;
        };
        if value.is_null() {
            add_error(&mut errors, field, "This field may not be null.");
            continue;
        }
        let text = value.as_str();
        if text.is_none_or(|item| item != "off" && item != "yes" && item != "no") {
            add_error(
                &mut errors,
                field,
                &format!("\"{}\" is not a valid choice.", shown_choice(value)),
            );
            continue;
        }
        mark(&mut cleaned.present, field);
        let text = text.unwrap_or("off").to_string();
        if field == "filter_unread" {
            cleaned.filter_unread = text;
        } else {
            cleaned.filter_shared = text;
        }
    }
    if let Some(value) = data.get("order") {
        if value.is_null() {
            add_error(&mut errors, "order", "This field may not be null.");
        } else if value.is_boolean() {
            add_error(&mut errors, "order", "A valid integer is required.");
        } else if let Some(number) = value.as_i64() {
            if let Ok(order) = i32::try_from(number) {
                mark(&mut cleaned.present, "order");
                cleaned.order = order;
            } else {
                add_error(&mut errors, "order", "A valid integer is required.");
            }
        } else {
            add_error(&mut errors, "order", "A valid integer is required.");
        }
    }
    (errors, cleaned)
}

fn unique_ci(items: Vec<String>) -> Vec<String> {
    let mut keys: Vec<String> = Vec::new();
    let mut out: Vec<String> = Vec::new();
    for item in items {
        let key = item.to_lowercase();
        if let Some(pos) = keys.iter().position(|existing| existing == &key) {
            out[pos] = item;
        } else {
            keys.push(key);
            out.push(item);
        }
    }
    out
}

pub fn parse_tag_string(raw: &str, delimiter: &str) -> Vec<String> {
    if raw.trim().is_empty() {
        return Vec::new();
    }
    let mut names = Vec::new();
    for part in raw.trim().split(delimiter) {
        if part.trim().is_empty() {
            continue;
        }
        names.push(part.trim().replace(' ', "-"));
    }
    let mut names = unique_ci(names);
    names.sort_by(|a, b| a.to_lowercase().cmp(&b.to_lowercase()));
    names
}

pub fn bookmark_tag_names(raw: &[String]) -> Vec<String> {
    parse_tag_string(&raw.join(","), ",")
}

fn like_contains(text: &str) -> String {
    let mut out = String::from("%");
    for ch in text.chars() {
        if ch == '\\' || ch == '%' || ch == '_' {
            out.push('\\');
        }
        out.push(ch);
    }
    out.push('%');
    out
}

const UNTAGGED_SQL: &str = "NOT EXISTS (SELECT 1 FROM bookmark_tags bt WHERE bt.bookmark_id = b.id)";

fn term_sql(term: &str, lax: bool, sql: &mut Sql) -> String {
    let placeholder = sql.bind(Arg::Text(like_contains(term)));
    let mut out = format!(
        "(b.title ILIKE {placeholder} ESCAPE '\\' OR b.description ILIKE {placeholder} ESCAPE '\\' OR b.notes ILIKE {placeholder} ESCAPE '\\' OR b.url ILIKE {placeholder} ESCAPE '\\'"
    );
    if lax {
        let tag = sql.bind(Arg::Text(term.to_lowercase()));
        out.push_str(&format!(
            " OR EXISTS (SELECT 1 FROM bookmark_tags bt JOIN tags t ON t.id = bt.tag_id WHERE bt.bookmark_id = b.id AND t.name_lower = {tag})"
        ));
    }
    out.push(')');
    out
}

fn tag_sql(tag: &str, sql: &mut Sql) -> String {
    let placeholder = sql.bind(Arg::Text(tag.to_lowercase()));
    format!(
        "EXISTS (SELECT 1 FROM bookmark_tags bt JOIN tags t ON t.id = bt.tag_id WHERE bt.bookmark_id = b.id AND t.name_lower = {placeholder})"
    )
}

fn keyword_sql(keyword: &str) -> String {
    match keyword.to_ascii_lowercase().as_str() {
        "unread" => "b.unread".to_string(),
        "untagged" => UNTAGGED_SQL.to_string(),
        _ => "TRUE".to_string(),
    }
}

fn node_text(parsed: &Parsed, idx: usize) -> String {
    if idx >= parsed.nodes.len() {
        return String::new();
    }
    String::from_utf8_lossy(&parsed.nodes[idx].text).into_owned()
}

fn compile_at(parsed: &Parsed, idx: usize, lax: bool, sql: &mut Sql) -> String {
    if idx >= parsed.nodes.len() {
        return "FALSE".to_string();
    }
    let kind = parsed.nodes[idx].kind;
    let left = parsed.nodes[idx].left;
    let right = parsed.nodes[idx].right;
    if kind == NODE_TERM {
        term_sql(&node_text(parsed, idx), lax, sql)
    } else if kind == NODE_TAG {
        tag_sql(&node_text(parsed, idx), sql)
    } else if kind == NODE_KEYWORD {
        keyword_sql(&node_text(parsed, idx))
    } else if kind == NODE_AND {
        let l = compile_at(parsed, left, lax, sql);
        let r = compile_at(parsed, right, lax, sql);
        format!("({l} AND {r})")
    } else if kind == NODE_OR {
        let l = compile_at(parsed, left, lax, sql);
        let r = compile_at(parsed, right, lax, sql);
        format!("({l} OR {r})")
    } else if kind == NODE_NOT {
        let inner = compile_at(parsed, left, lax, sql);
        format!("(NOT ({inner}))")
    } else {
        "FALSE".to_string()
    }
}

fn legacy_sql(query: &str, lax: bool, sql: &mut Sql) -> String {
    let mut terms = Vec::new();
    let mut tags = Vec::new();
    let mut untagged = false;
    let mut unread = false;
    for word in query.trim().split(' ') {
        if word.is_empty() {
            continue;
        }
        if let Some(tag) = word.strip_prefix('#') {
            if !tag.is_empty() {
                tags.push(tag.to_string());
            }
        } else if let Some(keyword) = word.strip_prefix('!') {
            if keyword == "untagged" {
                untagged = true;
            }
            if keyword == "unread" {
                unread = true;
            }
        } else {
            terms.push(word.to_string());
        }
    }
    tags = unique_ci(tags);
    let mut conds = Vec::new();
    for term in terms {
        conds.push(term_sql(&term, lax, sql));
    }
    for tag in tags {
        conds.push(tag_sql(&tag, sql));
    }
    if untagged {
        conds.push(UNTAGGED_SQL.to_string());
    }
    if unread {
        conds.push("b.unread".to_string());
    }
    if conds.is_empty() {
        String::new()
    } else {
        format!("({})", conds.join(" AND "))
    }
}

/// Compiles `q`. The default parser is the kernel. Legacy profile mode splits
/// on spaces in the shell and does not treat `and` / `or` / `not` as operators.
pub fn search_sql(query: &str, legacy: bool, lax: bool, sql: &mut Sql) -> String {
    if legacy {
        return legacy_sql(query, lax, sql);
    }
    let bytes = query.as_bytes().to_vec();
    let parsed = parse_search(&bytes);
    if parsed.failed {
        return "FALSE".to_string();
    }
    if parsed.empty {
        return String::new();
    }
    compile_at(&parsed, parsed.root, lax, sql)
}

pub fn bundle_search_sql(search: &str, sql: &mut Sql) -> String {
    let mut terms = Vec::new();
    for word in search.trim().split(' ') {
        if word.is_empty() || word.starts_with('#') || word.starts_with('!') {
            continue;
        }
        terms.push(word.to_string());
    }
    if terms.is_empty() {
        return String::new();
    }
    let mut conds = Vec::new();
    for term in terms {
        conds.push(term_sql(&term, false, sql));
    }
    format!("({})", conds.join(" AND "))
}

pub fn order_sql(sort_key: &str) -> &'static str {
    match sort_key {
        "added_asc" => "b.date_added ASC",
        "added_desc" => "b.date_added DESC",
        "modified_asc" => "b.date_modified ASC",
        "modified_desc" => "b.date_modified DESC",
        "title_asc" => "lower(CASE WHEN b.title <> '' THEN b.title ELSE b.url END) ASC",
        "title_desc" => "lower(CASE WHEN b.title <> '' THEN b.title ELSE b.url END) DESC",
        _ => "b.date_added DESC",
    }
}

pub fn flag_sql(field: &str, raw: &str) -> String {
    match raw {
        "yes" => format!("b.{field}"),
        "no" => format!("NOT b.{field}"),
        _ => String::new(),
    }
}

pub fn since_sql(column: &str, raw: &str, sql: &mut Sql) -> String {
    if raw.is_empty() {
        return String::new();
    }
    let Some(parsed) = parse_time(raw) else {
        return String::new();
    };
    let placeholder = sql.bind(Arg::Time(parsed));
    format!("{column} > {placeholder}")
}

pub fn json_detail(raw: &[u8]) -> String {
    let mut pos = 0;
    while pos < raw.len() && matches!(raw[pos], b' ' | b'\t' | b'\n' | b'\r') {
        pos += 1;
    }
    let trimmed = &raw[pos..];
    if trimmed.is_empty() || (trimmed[0] != b'{' && trimmed[0] != b'[' && trimmed[0] != b'"') {
        let mut line = 1;
        let mut col = 1;
        let mut i = 0;
        while i < pos && i < raw.len() {
            if raw[i] == b'\n' {
                line += 1;
                col = 1;
            } else {
                col += 1;
            }
            i += 1;
        }
        return format!("JSON parse error - Expecting value: line {line} column {col} (char {pos})");
    }
    "JSON parse error - Expecting value: line 1 column 1 (char 0)".to_string()
}

pub fn sort_names(names: &mut [String]) {
    names.sort();
}
