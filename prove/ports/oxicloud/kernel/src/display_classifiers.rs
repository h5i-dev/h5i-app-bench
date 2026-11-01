//! Ordered display classifiers; output enum variants intern exact UTF-8 strings.
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum DisplayValue { V0,V1,V2,V3,V4,V5,V6,V7,V8,V9,V10,V11,V12,V13,V14,V15,V16,V17,V18,V19,V20,V21,V22,V23,V24,V25,V26,V27,V28,V29,V30,V31,V32,V33,V34,V35,V36,V37,V38,V39,V40,V41,V42,V43,V44,V45,V46,V47,V48,V49,V50,V51,V52,V53 }

pub fn starts_at(hay: &[u8], needle: &[u8], at: usize) -> bool {
    if at > hay.len() { return false; }
    if needle.len() > hay.len() - at { return false; }
    &hay[at..at + needle.len()] == needle
}
pub fn prefix(hay: &[u8], needle: &[u8]) -> bool { starts_at(hay, needle, 0) }
pub fn contains(hay: &[u8], needle: &[u8]) -> bool {
    if needle.len() > hay.len() { return false; }
    let last = hay.len() - needle.len();
    let mut i = 0;
    loop {
        if starts_at(hay, needle, i) { return true; }
        if i == last { return false; }
        i += 1;
    }
}
pub fn icon_class_with_ext_exact_0(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/pdf".as_slice() { return Some(DisplayValue::V41); }
    if raw == b"application/msword".as_slice() { return Some(DisplayValue::V44); }
    if raw == b"application/vnd.openxmlformats-officedocument.wordprocessingml.document".as_slice() { return Some(DisplayValue::V44); }
    if raw == b"application/vnd.oasis.opendocument.text".as_slice() { return Some(DisplayValue::V44); }
    if raw == b"application/vnd.ms-excel".as_slice() { return Some(DisplayValue::V39); }
    if raw == b"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".as_slice() { return Some(DisplayValue::V39); }
    None
}
pub fn icon_class_with_ext_exact_1(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/vnd.oasis.opendocument.spreadsheet".as_slice() { return Some(DisplayValue::V39); }
    if raw == b"text/csv".as_slice() { return Some(DisplayValue::V39); }
    if raw == b"application/vnd.ms-powerpoint".as_slice() { return Some(DisplayValue::V42); }
    if raw == b"application/vnd.openxmlformats-officedocument.presentationml.presentation".as_slice() { return Some(DisplayValue::V42); }
    if raw == b"application/vnd.oasis.opendocument.presentation".as_slice() { return Some(DisplayValue::V42); }
    if raw == b"application/zip".as_slice() { return Some(DisplayValue::V36); }
    None
}
pub fn icon_class_with_ext_exact_2(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/x-rar-compressed".as_slice() { return Some(DisplayValue::V36); }
    if raw == b"application/vnd.rar".as_slice() { return Some(DisplayValue::V36); }
    if raw == b"application/x-7z-compressed".as_slice() { return Some(DisplayValue::V36); }
    if raw == b"application/gzip".as_slice() { return Some(DisplayValue::V36); }
    if raw == b"application/x-gzip".as_slice() { return Some(DisplayValue::V36); }
    if raw == b"application/x-tar".as_slice() { return Some(DisplayValue::V36); }
    None
}
pub fn icon_class_with_ext_exact_3(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/x-bzip2".as_slice() { return Some(DisplayValue::V36); }
    if raw == b"application/x-xz".as_slice() { return Some(DisplayValue::V36); }
    if raw == b"application/x-compress".as_slice() { return Some(DisplayValue::V36); }
    if raw == b"application/json".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"application/ld+json".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"application/javascript".as_slice() { return Some(DisplayValue::V38); }
    None
}
pub fn icon_class_with_ext_exact_4(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/typescript".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"application/x-httpd-php".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"application/xml".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"application/xhtml+xml".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"application/sql".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"application/x-yaml".as_slice() { return Some(DisplayValue::V38); }
    None
}
pub fn icon_class_with_ext_exact_5(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/toml".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"application/x-sh".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"application/x-shellscript".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"application/x-csh".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"application/x-apple-diskimage".as_slice() { return Some(DisplayValue::V45); }
    if raw == b"application/x-ms-dos-executable".as_slice() { return Some(DisplayValue::V45); }
    None
}
pub fn icon_class_with_ext_exact_6(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/x-msdownload".as_slice() { return Some(DisplayValue::V45); }
    if raw == b"application/x-msi".as_slice() { return Some(DisplayValue::V45); }
    if raw == b"application/vnd.debian.binary-package".as_slice() { return Some(DisplayValue::V45); }
    if raw == b"application/x-rpm".as_slice() { return Some(DisplayValue::V45); }
    if raw == b"application/vnd.appimage".as_slice() { return Some(DisplayValue::V45); }
    None
}
pub fn icon_class_with_ext_mime_0(raw: &[u8]) -> Option<DisplayValue> {
    if prefix(raw, b"image/") { return Some(DisplayValue::V40); }
    if prefix(raw, b"video/") { return Some(DisplayValue::V43); }
    if prefix(raw, b"audio/") { return Some(DisplayValue::V37); }
    if prefix(raw, b"text/x-script") { return Some(DisplayValue::V38); }
    if prefix(raw, b"text/x-python") { return Some(DisplayValue::V38); }
    if prefix(raw, b"text/x-java") { return Some(DisplayValue::V38); }
    None
}
pub fn icon_class_with_ext_mime_1(raw: &[u8]) -> Option<DisplayValue> {
    if prefix(raw, b"text/x-c") { return Some(DisplayValue::V38); }
    if prefix(raw, b"text/x-rust") { return Some(DisplayValue::V38); }
    if prefix(raw, b"text/x-go") { return Some(DisplayValue::V38); }
    if prefix(raw, b"text/x-ruby") { return Some(DisplayValue::V38); }
    if prefix(raw, b"text/x-shellscript") { return Some(DisplayValue::V38); }
    if prefix(raw, b"text/x-php") { return Some(DisplayValue::V38); }
    None
}
pub fn icon_class_with_ext_mime_2(raw: &[u8]) -> Option<DisplayValue> {
    if contains(raw, b"javascript") { return Some(DisplayValue::V38); }
    if contains(raw, b"typescript") { return Some(DisplayValue::V38); }
    if prefix(raw, b"text/") { return Some(DisplayValue::V35); }
    None
}
pub fn icon_class_with_ext_ext_0(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"pdf".as_slice() { return Some(DisplayValue::V41); }
    if raw == b"doc".as_slice() { return Some(DisplayValue::V44); }
    if raw == b"docx".as_slice() { return Some(DisplayValue::V44); }
    if raw == b"odt".as_slice() { return Some(DisplayValue::V44); }
    if raw == b"rtf".as_slice() { return Some(DisplayValue::V44); }
    if raw == b"xls".as_slice() { return Some(DisplayValue::V39); }
    None
}
pub fn icon_class_with_ext_ext_1(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"xlsx".as_slice() { return Some(DisplayValue::V39); }
    if raw == b"ods".as_slice() { return Some(DisplayValue::V39); }
    if raw == b"csv".as_slice() { return Some(DisplayValue::V39); }
    if raw == b"ppt".as_slice() { return Some(DisplayValue::V42); }
    if raw == b"pptx".as_slice() { return Some(DisplayValue::V42); }
    if raw == b"odp".as_slice() { return Some(DisplayValue::V42); }
    None
}
pub fn icon_class_with_ext_ext_2(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"key".as_slice() { return Some(DisplayValue::V42); }
    if raw == b"jpg".as_slice() { return Some(DisplayValue::V40); }
    if raw == b"jpeg".as_slice() { return Some(DisplayValue::V40); }
    if raw == b"png".as_slice() { return Some(DisplayValue::V40); }
    if raw == b"gif".as_slice() { return Some(DisplayValue::V40); }
    if raw == b"bmp".as_slice() { return Some(DisplayValue::V40); }
    None
}
pub fn icon_class_with_ext_ext_3(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"svg".as_slice() { return Some(DisplayValue::V40); }
    if raw == b"webp".as_slice() { return Some(DisplayValue::V40); }
    if raw == b"ico".as_slice() { return Some(DisplayValue::V40); }
    if raw == b"tiff".as_slice() { return Some(DisplayValue::V40); }
    if raw == b"tif".as_slice() { return Some(DisplayValue::V40); }
    if raw == b"heic".as_slice() { return Some(DisplayValue::V40); }
    None
}
pub fn icon_class_with_ext_ext_4(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"heif".as_slice() { return Some(DisplayValue::V40); }
    if raw == b"avif".as_slice() { return Some(DisplayValue::V40); }
    if raw == b"mp4".as_slice() { return Some(DisplayValue::V43); }
    if raw == b"avi".as_slice() { return Some(DisplayValue::V43); }
    if raw == b"mkv".as_slice() { return Some(DisplayValue::V43); }
    if raw == b"mov".as_slice() { return Some(DisplayValue::V43); }
    None
}
pub fn icon_class_with_ext_ext_5(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"wmv".as_slice() { return Some(DisplayValue::V43); }
    if raw == b"flv".as_slice() { return Some(DisplayValue::V43); }
    if raw == b"webm".as_slice() { return Some(DisplayValue::V43); }
    if raw == b"m4v".as_slice() { return Some(DisplayValue::V43); }
    if raw == b"mp3".as_slice() { return Some(DisplayValue::V37); }
    if raw == b"wav".as_slice() { return Some(DisplayValue::V37); }
    None
}
pub fn icon_class_with_ext_ext_6(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"ogg".as_slice() { return Some(DisplayValue::V37); }
    if raw == b"flac".as_slice() { return Some(DisplayValue::V37); }
    if raw == b"aac".as_slice() { return Some(DisplayValue::V37); }
    if raw == b"wma".as_slice() { return Some(DisplayValue::V37); }
    if raw == b"m4a".as_slice() { return Some(DisplayValue::V37); }
    if raw == b"opus".as_slice() { return Some(DisplayValue::V37); }
    None
}
pub fn icon_class_with_ext_ext_7(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"zip".as_slice() { return Some(DisplayValue::V36); }
    if raw == b"rar".as_slice() { return Some(DisplayValue::V36); }
    if raw == b"7z".as_slice() { return Some(DisplayValue::V36); }
    if raw == b"tar".as_slice() { return Some(DisplayValue::V36); }
    if raw == b"gz".as_slice() { return Some(DisplayValue::V36); }
    if raw == b"bz2".as_slice() { return Some(DisplayValue::V36); }
    None
}
pub fn icon_class_with_ext_ext_8(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"xz".as_slice() { return Some(DisplayValue::V36); }
    if raw == b"zst".as_slice() { return Some(DisplayValue::V36); }
    if raw == b"lz4".as_slice() { return Some(DisplayValue::V36); }
    if raw == b"exe".as_slice() { return Some(DisplayValue::V45); }
    if raw == b"msi".as_slice() { return Some(DisplayValue::V45); }
    if raw == b"dmg".as_slice() { return Some(DisplayValue::V45); }
    None
}
pub fn icon_class_with_ext_ext_9(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"deb".as_slice() { return Some(DisplayValue::V45); }
    if raw == b"rpm".as_slice() { return Some(DisplayValue::V45); }
    if raw == b"appimage".as_slice() { return Some(DisplayValue::V45); }
    if raw == b"pkg".as_slice() { return Some(DisplayValue::V45); }
    if raw == b"snap".as_slice() { return Some(DisplayValue::V45); }
    if raw == b"flatpak".as_slice() { return Some(DisplayValue::V45); }
    None
}
pub fn icon_class_with_ext_ext_10(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"js".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"jsx".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"mjs".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"cjs".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"ts".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"tsx".as_slice() { return Some(DisplayValue::V38); }
    None
}
pub fn icon_class_with_ext_ext_11(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"py".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"pyw".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"rs".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"go".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"java".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"kt".as_slice() { return Some(DisplayValue::V38); }
    None
}
pub fn icon_class_with_ext_ext_12(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"kts".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"scala".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"c".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"h".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"cpp".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"hpp".as_slice() { return Some(DisplayValue::V38); }
    None
}
pub fn icon_class_with_ext_ext_13(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"cc".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"cxx".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"cs".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"rb".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"php".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"swift".as_slice() { return Some(DisplayValue::V38); }
    None
}
pub fn icon_class_with_ext_ext_14(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"r".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"lua".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"pl".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"pm".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"html".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"htm".as_slice() { return Some(DisplayValue::V38); }
    None
}
pub fn icon_class_with_ext_ext_15(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"css".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"scss".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"sass".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"less".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"json".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"xml".as_slice() { return Some(DisplayValue::V38); }
    None
}
pub fn icon_class_with_ext_ext_16(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"yaml".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"yml".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"toml".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"ini".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"cfg".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"conf".as_slice() { return Some(DisplayValue::V38); }
    None
}
pub fn icon_class_with_ext_ext_17(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"sql".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"graphql".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"proto".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"vue".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"svelte".as_slice() { return Some(DisplayValue::V38); }
    if raw == b"sh".as_slice() { return Some(DisplayValue::V46); }
    None
}
pub fn icon_class_with_ext_ext_18(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"bash".as_slice() { return Some(DisplayValue::V46); }
    if raw == b"zsh".as_slice() { return Some(DisplayValue::V46); }
    if raw == b"fish".as_slice() { return Some(DisplayValue::V46); }
    if raw == b"ps1".as_slice() { return Some(DisplayValue::V46); }
    if raw == b"bat".as_slice() { return Some(DisplayValue::V46); }
    if raw == b"cmd".as_slice() { return Some(DisplayValue::V46); }
    None
}
pub fn icon_class_with_ext_ext_19(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"md".as_slice() { return Some(DisplayValue::V35); }
    if raw == b"markdown".as_slice() { return Some(DisplayValue::V35); }
    if raw == b"rst".as_slice() { return Some(DisplayValue::V35); }
    if raw == b"txt".as_slice() { return Some(DisplayValue::V35); }
    None
}
pub fn icon_class_with_ext(mime: &[u8], ext: Option<&[u8]>) -> DisplayValue {
    if let Some(v) = icon_class_with_ext_exact_0(mime) { return v; }
    if let Some(v) = icon_class_with_ext_exact_1(mime) { return v; }
    if let Some(v) = icon_class_with_ext_exact_2(mime) { return v; }
    if let Some(v) = icon_class_with_ext_exact_3(mime) { return v; }
    if let Some(v) = icon_class_with_ext_exact_4(mime) { return v; }
    if let Some(v) = icon_class_with_ext_exact_5(mime) { return v; }
    if let Some(v) = icon_class_with_ext_exact_6(mime) { return v; }
    if let Some(v) = icon_class_with_ext_mime_0(mime) { return v; }
    if let Some(v) = icon_class_with_ext_mime_1(mime) { return v; }
    if let Some(v) = icon_class_with_ext_mime_2(mime) { return v; }
    if let Some(ext) = ext {
        if let Some(v) = icon_class_with_ext_ext_0(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_1(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_2(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_3(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_4(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_5(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_6(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_7(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_8(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_9(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_10(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_11(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_12(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_13(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_14(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_15(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_16(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_17(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_18(ext) { return v; }
        if let Some(v) = icon_class_with_ext_ext_19(ext) { return v; }
    }
    DisplayValue::V34
}
pub fn icon_special_class_with_ext_exact_0(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/pdf".as_slice() { return Some(DisplayValue::V49); }
    if raw == b"application/msword".as_slice() { return Some(DisplayValue::V33); }
    if raw == b"application/vnd.openxmlformats-officedocument.wordprocessingml.document".as_slice() { return Some(DisplayValue::V33); }
    if raw == b"application/vnd.oasis.opendocument.text".as_slice() { return Some(DisplayValue::V33); }
    if raw == b"application/vnd.ms-excel".as_slice() { return Some(DisplayValue::V52); }
    if raw == b"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".as_slice() { return Some(DisplayValue::V52); }
    None
}
pub fn icon_special_class_with_ext_exact_1(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/vnd.oasis.opendocument.spreadsheet".as_slice() { return Some(DisplayValue::V52); }
    if raw == b"text/csv".as_slice() { return Some(DisplayValue::V52); }
    if raw == b"application/vnd.ms-powerpoint".as_slice() { return Some(DisplayValue::V50); }
    if raw == b"application/vnd.openxmlformats-officedocument.presentationml.presentation".as_slice() { return Some(DisplayValue::V50); }
    if raw == b"application/vnd.oasis.opendocument.presentation".as_slice() { return Some(DisplayValue::V50); }
    if raw == b"application/zip".as_slice() { return Some(DisplayValue::V13); }
    None
}
pub fn icon_special_class_with_ext_exact_2(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/x-rar-compressed".as_slice() { return Some(DisplayValue::V13); }
    if raw == b"application/vnd.rar".as_slice() { return Some(DisplayValue::V13); }
    if raw == b"application/x-7z-compressed".as_slice() { return Some(DisplayValue::V13); }
    if raw == b"application/gzip".as_slice() { return Some(DisplayValue::V13); }
    if raw == b"application/x-gzip".as_slice() { return Some(DisplayValue::V13); }
    if raw == b"application/x-tar".as_slice() { return Some(DisplayValue::V13); }
    None
}
pub fn icon_special_class_with_ext_exact_3(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/x-bzip2".as_slice() { return Some(DisplayValue::V13); }
    if raw == b"application/x-xz".as_slice() { return Some(DisplayValue::V13); }
    if raw == b"application/x-compress".as_slice() { return Some(DisplayValue::V13); }
    if raw == b"application/json".as_slice() { return Some(DisplayValue::V24); }
    if raw == b"application/ld+json".as_slice() { return Some(DisplayValue::V24); }
    if raw == b"application/javascript".as_slice() { return Some(DisplayValue::V23); }
    None
}
pub fn icon_special_class_with_ext_exact_4(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/typescript".as_slice() { return Some(DisplayValue::V32); }
    if raw == b"application/xml".as_slice() { return Some(DisplayValue::V21); }
    if raw == b"application/xhtml+xml".as_slice() { return Some(DisplayValue::V21); }
    if raw == b"application/sql".as_slice() { return Some(DisplayValue::V30); }
    if raw == b"application/x-yaml".as_slice() { return Some(DisplayValue::V17); }
    if raw == b"application/toml".as_slice() { return Some(DisplayValue::V17); }
    None
}
pub fn icon_special_class_with_ext_exact_5(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/x-httpd-php".as_slice() { return Some(DisplayValue::V26); }
    if raw == b"application/x-sh".as_slice() { return Some(DisplayValue::V51); }
    if raw == b"application/x-shellscript".as_slice() { return Some(DisplayValue::V51); }
    if raw == b"application/x-csh".as_slice() { return Some(DisplayValue::V51); }
    if raw == b"application/x-apple-diskimage".as_slice() { return Some(DisplayValue::V48); }
    if raw == b"application/x-ms-dos-executable".as_slice() { return Some(DisplayValue::V48); }
    None
}
pub fn icon_special_class_with_ext_exact_6(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/x-msdownload".as_slice() { return Some(DisplayValue::V48); }
    if raw == b"application/x-msi".as_slice() { return Some(DisplayValue::V48); }
    if raw == b"application/vnd.debian.binary-package".as_slice() { return Some(DisplayValue::V48); }
    if raw == b"application/x-rpm".as_slice() { return Some(DisplayValue::V48); }
    if raw == b"application/vnd.appimage".as_slice() { return Some(DisplayValue::V48); }
    None
}
pub fn icon_special_class_with_ext_mime_0(raw: &[u8]) -> Option<DisplayValue> {
    if prefix(raw, b"image/") { return Some(DisplayValue::V47); }
    if prefix(raw, b"video/") { return Some(DisplayValue::V53); }
    if prefix(raw, b"audio/") { return Some(DisplayValue::V14); }
    if prefix(raw, b"text/x-python") { return Some(DisplayValue::V27); }
    if prefix(raw, b"text/x-rust") { return Some(DisplayValue::V29); }
    if prefix(raw, b"text/x-java") { return Some(DisplayValue::V15); }
    None
}
pub fn icon_special_class_with_ext_mime_1(raw: &[u8]) -> Option<DisplayValue> {
    if prefix(raw, b"text/x-c") { return Some(DisplayValue::V15); }
    if prefix(raw, b"text/x-go") { return Some(DisplayValue::V20); }
    if prefix(raw, b"text/x-ruby") { return Some(DisplayValue::V28); }
    if prefix(raw, b"text/x-shellscript") { return Some(DisplayValue::V51); }
    if prefix(raw, b"text/x-script") { return Some(DisplayValue::V15); }
    if prefix(raw, b"text/x-php") { return Some(DisplayValue::V15); }
    None
}
pub fn icon_special_class_with_ext_mime_2(raw: &[u8]) -> Option<DisplayValue> {
    if prefix(raw, b"text/markdown") { return Some(DisplayValue::V25); }
    if prefix(raw, b"text/html") { return Some(DisplayValue::V21); }
    if prefix(raw, b"text/css") { return Some(DisplayValue::V19); }
    if contains(raw, b"javascript") { return Some(DisplayValue::V23); }
    if contains(raw, b"typescript") { return Some(DisplayValue::V32); }
    if prefix(raw, b"text/") { return Some(DisplayValue::V33); }
    None
}
pub fn icon_special_class_with_ext_ext_0(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"pdf".as_slice() { return Some(DisplayValue::V49); }
    if raw == b"doc".as_slice() { return Some(DisplayValue::V33); }
    if raw == b"docx".as_slice() { return Some(DisplayValue::V33); }
    if raw == b"odt".as_slice() { return Some(DisplayValue::V33); }
    if raw == b"rtf".as_slice() { return Some(DisplayValue::V33); }
    if raw == b"xls".as_slice() { return Some(DisplayValue::V52); }
    None
}
pub fn icon_special_class_with_ext_ext_1(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"xlsx".as_slice() { return Some(DisplayValue::V52); }
    if raw == b"ods".as_slice() { return Some(DisplayValue::V52); }
    if raw == b"csv".as_slice() { return Some(DisplayValue::V52); }
    if raw == b"ppt".as_slice() { return Some(DisplayValue::V50); }
    if raw == b"pptx".as_slice() { return Some(DisplayValue::V50); }
    if raw == b"odp".as_slice() { return Some(DisplayValue::V50); }
    None
}
pub fn icon_special_class_with_ext_ext_2(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"key".as_slice() { return Some(DisplayValue::V50); }
    if raw == b"jpg".as_slice() { return Some(DisplayValue::V47); }
    if raw == b"jpeg".as_slice() { return Some(DisplayValue::V47); }
    if raw == b"png".as_slice() { return Some(DisplayValue::V47); }
    if raw == b"gif".as_slice() { return Some(DisplayValue::V47); }
    if raw == b"bmp".as_slice() { return Some(DisplayValue::V47); }
    None
}
pub fn icon_special_class_with_ext_ext_3(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"svg".as_slice() { return Some(DisplayValue::V47); }
    if raw == b"webp".as_slice() { return Some(DisplayValue::V47); }
    if raw == b"ico".as_slice() { return Some(DisplayValue::V47); }
    if raw == b"tiff".as_slice() { return Some(DisplayValue::V47); }
    if raw == b"tif".as_slice() { return Some(DisplayValue::V47); }
    if raw == b"heic".as_slice() { return Some(DisplayValue::V47); }
    None
}
pub fn icon_special_class_with_ext_ext_4(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"heif".as_slice() { return Some(DisplayValue::V47); }
    if raw == b"avif".as_slice() { return Some(DisplayValue::V47); }
    if raw == b"mp4".as_slice() { return Some(DisplayValue::V53); }
    if raw == b"avi".as_slice() { return Some(DisplayValue::V53); }
    if raw == b"mkv".as_slice() { return Some(DisplayValue::V53); }
    if raw == b"mov".as_slice() { return Some(DisplayValue::V53); }
    None
}
pub fn icon_special_class_with_ext_ext_5(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"wmv".as_slice() { return Some(DisplayValue::V53); }
    if raw == b"flv".as_slice() { return Some(DisplayValue::V53); }
    if raw == b"webm".as_slice() { return Some(DisplayValue::V53); }
    if raw == b"m4v".as_slice() { return Some(DisplayValue::V53); }
    if raw == b"mp3".as_slice() { return Some(DisplayValue::V14); }
    if raw == b"wav".as_slice() { return Some(DisplayValue::V14); }
    None
}
pub fn icon_special_class_with_ext_ext_6(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"ogg".as_slice() { return Some(DisplayValue::V14); }
    if raw == b"flac".as_slice() { return Some(DisplayValue::V14); }
    if raw == b"aac".as_slice() { return Some(DisplayValue::V14); }
    if raw == b"wma".as_slice() { return Some(DisplayValue::V14); }
    if raw == b"m4a".as_slice() { return Some(DisplayValue::V14); }
    if raw == b"opus".as_slice() { return Some(DisplayValue::V14); }
    None
}
pub fn icon_special_class_with_ext_ext_7(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"zip".as_slice() { return Some(DisplayValue::V13); }
    if raw == b"rar".as_slice() { return Some(DisplayValue::V13); }
    if raw == b"7z".as_slice() { return Some(DisplayValue::V13); }
    if raw == b"tar".as_slice() { return Some(DisplayValue::V13); }
    if raw == b"gz".as_slice() { return Some(DisplayValue::V13); }
    if raw == b"bz2".as_slice() { return Some(DisplayValue::V13); }
    None
}
pub fn icon_special_class_with_ext_ext_8(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"xz".as_slice() { return Some(DisplayValue::V13); }
    if raw == b"zst".as_slice() { return Some(DisplayValue::V13); }
    if raw == b"lz4".as_slice() { return Some(DisplayValue::V13); }
    if raw == b"exe".as_slice() { return Some(DisplayValue::V48); }
    if raw == b"msi".as_slice() { return Some(DisplayValue::V48); }
    if raw == b"dmg".as_slice() { return Some(DisplayValue::V48); }
    None
}
pub fn icon_special_class_with_ext_ext_9(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"deb".as_slice() { return Some(DisplayValue::V48); }
    if raw == b"rpm".as_slice() { return Some(DisplayValue::V48); }
    if raw == b"appimage".as_slice() { return Some(DisplayValue::V48); }
    if raw == b"pkg".as_slice() { return Some(DisplayValue::V48); }
    if raw == b"snap".as_slice() { return Some(DisplayValue::V48); }
    if raw == b"flatpak".as_slice() { return Some(DisplayValue::V48); }
    None
}
pub fn icon_special_class_with_ext_ext_10(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"py".as_slice() { return Some(DisplayValue::V27); }
    if raw == b"pyw".as_slice() { return Some(DisplayValue::V27); }
    if raw == b"rs".as_slice() { return Some(DisplayValue::V29); }
    if raw == b"go".as_slice() { return Some(DisplayValue::V20); }
    if raw == b"java".as_slice() { return Some(DisplayValue::V22); }
    if raw == b"kt".as_slice() { return Some(DisplayValue::V22); }
    None
}
pub fn icon_special_class_with_ext_ext_11(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"kts".as_slice() { return Some(DisplayValue::V22); }
    if raw == b"scala".as_slice() { return Some(DisplayValue::V22); }
    if raw == b"js".as_slice() { return Some(DisplayValue::V23); }
    if raw == b"jsx".as_slice() { return Some(DisplayValue::V23); }
    if raw == b"mjs".as_slice() { return Some(DisplayValue::V23); }
    if raw == b"cjs".as_slice() { return Some(DisplayValue::V23); }
    None
}
pub fn icon_special_class_with_ext_ext_12(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"ts".as_slice() { return Some(DisplayValue::V32); }
    if raw == b"tsx".as_slice() { return Some(DisplayValue::V32); }
    if raw == b"c".as_slice() { return Some(DisplayValue::V16); }
    if raw == b"h".as_slice() { return Some(DisplayValue::V16); }
    if raw == b"cpp".as_slice() { return Some(DisplayValue::V16); }
    if raw == b"hpp".as_slice() { return Some(DisplayValue::V16); }
    None
}
pub fn icon_special_class_with_ext_ext_13(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"cc".as_slice() { return Some(DisplayValue::V16); }
    if raw == b"cxx".as_slice() { return Some(DisplayValue::V16); }
    if raw == b"cs".as_slice() { return Some(DisplayValue::V18); }
    if raw == b"rb".as_slice() { return Some(DisplayValue::V28); }
    if raw == b"php".as_slice() { return Some(DisplayValue::V26); }
    if raw == b"swift".as_slice() { return Some(DisplayValue::V31); }
    None
}
pub fn icon_special_class_with_ext_ext_14(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"r".as_slice() { return Some(DisplayValue::V15); }
    if raw == b"lua".as_slice() { return Some(DisplayValue::V15); }
    if raw == b"pl".as_slice() { return Some(DisplayValue::V15); }
    if raw == b"pm".as_slice() { return Some(DisplayValue::V15); }
    if raw == b"html".as_slice() { return Some(DisplayValue::V21); }
    if raw == b"htm".as_slice() { return Some(DisplayValue::V21); }
    None
}
pub fn icon_special_class_with_ext_ext_15(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"css".as_slice() { return Some(DisplayValue::V19); }
    if raw == b"scss".as_slice() { return Some(DisplayValue::V19); }
    if raw == b"sass".as_slice() { return Some(DisplayValue::V19); }
    if raw == b"less".as_slice() { return Some(DisplayValue::V19); }
    if raw == b"json".as_slice() { return Some(DisplayValue::V24); }
    if raw == b"xml".as_slice() { return Some(DisplayValue::V21); }
    None
}
pub fn icon_special_class_with_ext_ext_16(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"yaml".as_slice() { return Some(DisplayValue::V17); }
    if raw == b"yml".as_slice() { return Some(DisplayValue::V17); }
    if raw == b"toml".as_slice() { return Some(DisplayValue::V17); }
    if raw == b"ini".as_slice() { return Some(DisplayValue::V17); }
    if raw == b"cfg".as_slice() { return Some(DisplayValue::V17); }
    if raw == b"conf".as_slice() { return Some(DisplayValue::V17); }
    None
}
pub fn icon_special_class_with_ext_ext_17(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"sql".as_slice() { return Some(DisplayValue::V30); }
    if raw == b"graphql".as_slice() { return Some(DisplayValue::V30); }
    if raw == b"proto".as_slice() { return Some(DisplayValue::V30); }
    if raw == b"vue".as_slice() { return Some(DisplayValue::V23); }
    if raw == b"svelte".as_slice() { return Some(DisplayValue::V23); }
    if raw == b"sh".as_slice() { return Some(DisplayValue::V51); }
    None
}
pub fn icon_special_class_with_ext_ext_18(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"bash".as_slice() { return Some(DisplayValue::V51); }
    if raw == b"zsh".as_slice() { return Some(DisplayValue::V51); }
    if raw == b"fish".as_slice() { return Some(DisplayValue::V51); }
    if raw == b"ps1".as_slice() { return Some(DisplayValue::V51); }
    if raw == b"bat".as_slice() { return Some(DisplayValue::V51); }
    if raw == b"cmd".as_slice() { return Some(DisplayValue::V51); }
    None
}
pub fn icon_special_class_with_ext_ext_19(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"md".as_slice() { return Some(DisplayValue::V25); }
    if raw == b"markdown".as_slice() { return Some(DisplayValue::V25); }
    if raw == b"rst".as_slice() { return Some(DisplayValue::V25); }
    if raw == b"txt".as_slice() { return Some(DisplayValue::V33); }
    None
}
pub fn icon_special_class_with_ext(mime: &[u8], ext: Option<&[u8]>) -> DisplayValue {
    if let Some(v) = icon_special_class_with_ext_exact_0(mime) { return v; }
    if let Some(v) = icon_special_class_with_ext_exact_1(mime) { return v; }
    if let Some(v) = icon_special_class_with_ext_exact_2(mime) { return v; }
    if let Some(v) = icon_special_class_with_ext_exact_3(mime) { return v; }
    if let Some(v) = icon_special_class_with_ext_exact_4(mime) { return v; }
    if let Some(v) = icon_special_class_with_ext_exact_5(mime) { return v; }
    if let Some(v) = icon_special_class_with_ext_exact_6(mime) { return v; }
    if let Some(v) = icon_special_class_with_ext_mime_0(mime) { return v; }
    if let Some(v) = icon_special_class_with_ext_mime_1(mime) { return v; }
    if let Some(v) = icon_special_class_with_ext_mime_2(mime) { return v; }
    if let Some(ext) = ext {
        if let Some(v) = icon_special_class_with_ext_ext_0(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_1(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_2(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_3(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_4(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_5(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_6(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_7(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_8(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_9(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_10(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_11(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_12(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_13(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_14(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_15(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_16(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_17(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_18(ext) { return v; }
        if let Some(v) = icon_special_class_with_ext_ext_19(ext) { return v; }
    }
    DisplayValue::V0
}
pub fn category_with_ext_exact_0(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/pdf".as_slice() { return Some(DisplayValue::V8); }
    if raw == b"application/msword".as_slice() { return Some(DisplayValue::V4); }
    if raw == b"application/vnd.openxmlformats-officedocument.wordprocessingml.document".as_slice() { return Some(DisplayValue::V4); }
    if raw == b"application/vnd.oasis.opendocument.text".as_slice() { return Some(DisplayValue::V4); }
    if raw == b"application/vnd.ms-excel".as_slice() { return Some(DisplayValue::V10); }
    if raw == b"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".as_slice() { return Some(DisplayValue::V10); }
    None
}
pub fn category_with_ext_exact_1(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/vnd.oasis.opendocument.spreadsheet".as_slice() { return Some(DisplayValue::V10); }
    if raw == b"text/csv".as_slice() { return Some(DisplayValue::V10); }
    if raw == b"application/vnd.ms-powerpoint".as_slice() { return Some(DisplayValue::V9); }
    if raw == b"application/vnd.openxmlformats-officedocument.presentationml.presentation".as_slice() { return Some(DisplayValue::V9); }
    if raw == b"application/vnd.oasis.opendocument.presentation".as_slice() { return Some(DisplayValue::V9); }
    if raw == b"application/zip".as_slice() { return Some(DisplayValue::V1); }
    None
}
pub fn category_with_ext_exact_2(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/x-rar-compressed".as_slice() { return Some(DisplayValue::V1); }
    if raw == b"application/vnd.rar".as_slice() { return Some(DisplayValue::V1); }
    if raw == b"application/x-7z-compressed".as_slice() { return Some(DisplayValue::V1); }
    if raw == b"application/gzip".as_slice() { return Some(DisplayValue::V1); }
    if raw == b"application/x-tar".as_slice() { return Some(DisplayValue::V1); }
    if raw == b"application/json".as_slice() { return Some(DisplayValue::V3); }
    None
}
pub fn category_with_ext_exact_3(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/javascript".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"application/typescript".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"application/xml".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"application/sql".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"application/x-sh".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"application/x-shellscript".as_slice() { return Some(DisplayValue::V3); }
    None
}
pub fn category_with_ext_exact_4(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"application/x-apple-diskimage".as_slice() { return Some(DisplayValue::V6); }
    if raw == b"application/x-ms-dos-executable".as_slice() { return Some(DisplayValue::V6); }
    if raw == b"application/x-msdownload".as_slice() { return Some(DisplayValue::V6); }
    if raw == b"application/x-msi".as_slice() { return Some(DisplayValue::V6); }
    None
}
pub fn category_with_ext_mime_0(raw: &[u8]) -> Option<DisplayValue> {
    if prefix(raw, b"image/") { return Some(DisplayValue::V5); }
    if prefix(raw, b"video/") { return Some(DisplayValue::V12); }
    if prefix(raw, b"audio/") { return Some(DisplayValue::V2); }
    if prefix(raw, b"text/x-") { return Some(DisplayValue::V3); }
    if contains(raw, b"script") { return Some(DisplayValue::V3); }
    if contains(raw, b"javascript") { return Some(DisplayValue::V3); }
    None
}
pub fn category_with_ext_mime_1(raw: &[u8]) -> Option<DisplayValue> {
    if prefix(raw, b"text/markdown") { return Some(DisplayValue::V7); }
    if prefix(raw, b"text/html") { return Some(DisplayValue::V3); }
    if prefix(raw, b"text/css") { return Some(DisplayValue::V3); }
    if prefix(raw, b"text/") { return Some(DisplayValue::V11); }
    None
}
pub fn category_with_ext_ext_0(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"pdf".as_slice() { return Some(DisplayValue::V8); }
    if raw == b"doc".as_slice() { return Some(DisplayValue::V4); }
    if raw == b"docx".as_slice() { return Some(DisplayValue::V4); }
    if raw == b"odt".as_slice() { return Some(DisplayValue::V4); }
    if raw == b"rtf".as_slice() { return Some(DisplayValue::V4); }
    if raw == b"txt".as_slice() { return Some(DisplayValue::V4); }
    None
}
pub fn category_with_ext_ext_1(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"xls".as_slice() { return Some(DisplayValue::V10); }
    if raw == b"xlsx".as_slice() { return Some(DisplayValue::V10); }
    if raw == b"ods".as_slice() { return Some(DisplayValue::V10); }
    if raw == b"csv".as_slice() { return Some(DisplayValue::V10); }
    if raw == b"ppt".as_slice() { return Some(DisplayValue::V9); }
    if raw == b"pptx".as_slice() { return Some(DisplayValue::V9); }
    None
}
pub fn category_with_ext_ext_2(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"odp".as_slice() { return Some(DisplayValue::V9); }
    if raw == b"key".as_slice() { return Some(DisplayValue::V9); }
    if raw == b"jpg".as_slice() { return Some(DisplayValue::V5); }
    if raw == b"jpeg".as_slice() { return Some(DisplayValue::V5); }
    if raw == b"png".as_slice() { return Some(DisplayValue::V5); }
    if raw == b"gif".as_slice() { return Some(DisplayValue::V5); }
    None
}
pub fn category_with_ext_ext_3(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"bmp".as_slice() { return Some(DisplayValue::V5); }
    if raw == b"svg".as_slice() { return Some(DisplayValue::V5); }
    if raw == b"webp".as_slice() { return Some(DisplayValue::V5); }
    if raw == b"ico".as_slice() { return Some(DisplayValue::V5); }
    if raw == b"tiff".as_slice() { return Some(DisplayValue::V5); }
    if raw == b"heic".as_slice() { return Some(DisplayValue::V5); }
    None
}
pub fn category_with_ext_ext_4(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"avif".as_slice() { return Some(DisplayValue::V5); }
    if raw == b"mp4".as_slice() { return Some(DisplayValue::V12); }
    if raw == b"avi".as_slice() { return Some(DisplayValue::V12); }
    if raw == b"mkv".as_slice() { return Some(DisplayValue::V12); }
    if raw == b"mov".as_slice() { return Some(DisplayValue::V12); }
    if raw == b"wmv".as_slice() { return Some(DisplayValue::V12); }
    None
}
pub fn category_with_ext_ext_5(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"flv".as_slice() { return Some(DisplayValue::V12); }
    if raw == b"webm".as_slice() { return Some(DisplayValue::V12); }
    if raw == b"m4v".as_slice() { return Some(DisplayValue::V12); }
    if raw == b"mp3".as_slice() { return Some(DisplayValue::V2); }
    if raw == b"wav".as_slice() { return Some(DisplayValue::V2); }
    if raw == b"ogg".as_slice() { return Some(DisplayValue::V2); }
    None
}
pub fn category_with_ext_ext_6(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"flac".as_slice() { return Some(DisplayValue::V2); }
    if raw == b"aac".as_slice() { return Some(DisplayValue::V2); }
    if raw == b"wma".as_slice() { return Some(DisplayValue::V2); }
    if raw == b"m4a".as_slice() { return Some(DisplayValue::V2); }
    if raw == b"opus".as_slice() { return Some(DisplayValue::V2); }
    if raw == b"zip".as_slice() { return Some(DisplayValue::V1); }
    None
}
pub fn category_with_ext_ext_7(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"rar".as_slice() { return Some(DisplayValue::V1); }
    if raw == b"7z".as_slice() { return Some(DisplayValue::V1); }
    if raw == b"tar".as_slice() { return Some(DisplayValue::V1); }
    if raw == b"gz".as_slice() { return Some(DisplayValue::V1); }
    if raw == b"bz2".as_slice() { return Some(DisplayValue::V1); }
    if raw == b"xz".as_slice() { return Some(DisplayValue::V1); }
    None
}
pub fn category_with_ext_ext_8(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"exe".as_slice() { return Some(DisplayValue::V6); }
    if raw == b"msi".as_slice() { return Some(DisplayValue::V6); }
    if raw == b"dmg".as_slice() { return Some(DisplayValue::V6); }
    if raw == b"deb".as_slice() { return Some(DisplayValue::V6); }
    if raw == b"rpm".as_slice() { return Some(DisplayValue::V6); }
    if raw == b"appimage".as_slice() { return Some(DisplayValue::V6); }
    None
}
pub fn category_with_ext_ext_9(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"js".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"jsx".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"ts".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"tsx".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"py".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"rs".as_slice() { return Some(DisplayValue::V3); }
    None
}
pub fn category_with_ext_ext_10(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"go".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"java".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"c".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"cpp".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"cs".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"rb".as_slice() { return Some(DisplayValue::V3); }
    None
}
pub fn category_with_ext_ext_11(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"php".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"swift".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"kt".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"scala".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"r".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"lua".as_slice() { return Some(DisplayValue::V3); }
    None
}
pub fn category_with_ext_ext_12(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"pl".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"html".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"htm".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"css".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"scss".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"json".as_slice() { return Some(DisplayValue::V3); }
    None
}
pub fn category_with_ext_ext_13(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"xml".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"yaml".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"yml".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"toml".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"sql".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"sh".as_slice() { return Some(DisplayValue::V3); }
    None
}
pub fn category_with_ext_ext_14(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"bash".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"bat".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"ps1".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"vue".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"svelte".as_slice() { return Some(DisplayValue::V3); }
    if raw == b"md".as_slice() { return Some(DisplayValue::V7); }
    None
}
pub fn category_with_ext_ext_15(raw: &[u8]) -> Option<DisplayValue> {
    if raw == b"markdown".as_slice() { return Some(DisplayValue::V7); }
    if raw == b"rst".as_slice() { return Some(DisplayValue::V7); }
    None
}
pub fn category_with_ext(mime: &[u8], ext: Option<&[u8]>) -> DisplayValue {
    if let Some(v) = category_with_ext_exact_0(mime) { return v; }
    if let Some(v) = category_with_ext_exact_1(mime) { return v; }
    if let Some(v) = category_with_ext_exact_2(mime) { return v; }
    if let Some(v) = category_with_ext_exact_3(mime) { return v; }
    if let Some(v) = category_with_ext_exact_4(mime) { return v; }
    if let Some(v) = category_with_ext_mime_0(mime) { return v; }
    if let Some(v) = category_with_ext_mime_1(mime) { return v; }
    if let Some(ext) = ext {
        if let Some(v) = category_with_ext_ext_0(ext) { return v; }
        if let Some(v) = category_with_ext_ext_1(ext) { return v; }
        if let Some(v) = category_with_ext_ext_2(ext) { return v; }
        if let Some(v) = category_with_ext_ext_3(ext) { return v; }
        if let Some(v) = category_with_ext_ext_4(ext) { return v; }
        if let Some(v) = category_with_ext_ext_5(ext) { return v; }
        if let Some(v) = category_with_ext_ext_6(ext) { return v; }
        if let Some(v) = category_with_ext_ext_7(ext) { return v; }
        if let Some(v) = category_with_ext_ext_8(ext) { return v; }
        if let Some(v) = category_with_ext_ext_9(ext) { return v; }
        if let Some(v) = category_with_ext_ext_10(ext) { return v; }
        if let Some(v) = category_with_ext_ext_11(ext) { return v; }
        if let Some(v) = category_with_ext_ext_12(ext) { return v; }
        if let Some(v) = category_with_ext_ext_13(ext) { return v; }
        if let Some(v) = category_with_ext_ext_14(ext) { return v; }
        if let Some(v) = category_with_ext_ext_15(ext) { return v; }
    }
    DisplayValue::V4
}
