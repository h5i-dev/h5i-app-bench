pub fn is_valid_entry_name(name: &str) -> bool {
    let len = name.len();
    if !(1..=32).contains(&len) {
        return false;
    }
    name.chars()
        .all(|c| c.is_ascii_lowercase() || c.is_ascii_digit() || c == '_' || c == '-')
}
