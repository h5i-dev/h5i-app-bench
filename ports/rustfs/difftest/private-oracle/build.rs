use std::{env, fs, path::{Path, PathBuf}};
fn render(source: &Path, source_root: &Path, output: &Path) -> PathBuf {
    let target = output.join(source.strip_prefix(source_root).unwrap());
    fs::create_dir_all(target.parent().unwrap()).unwrap();
    let mut code = String::new();
    for line in fs::read_to_string(source).unwrap().lines() {
        let text = line.trim();
        let module = text.strip_prefix("pub mod ").or_else(|| text.strip_prefix("pub(crate) mod ")).or_else(|| text.strip_prefix("mod ")).and_then(|t| t.strip_suffix(';'));
        if let Some(module) = module.filter(|m| m.chars().all(|c| c.is_alphanumeric() || c == '_')) {
            let dir = if source.file_name().unwrap() == "mod.rs" { source.parent().unwrap().to_owned() } else { source.with_extension("") };
            let child = render(&dir.join(format!("{module}.rs")), source_root, output);
            code.push_str(&format!("#[path = {:?}]\npub mod {module};\n", child.to_str().unwrap()));
        } else { code.push_str(line); code.push('\n'); }
    }
    if source.ends_with("policy/statement.rs") {
        code.push_str(r#"
pub fn classify_actions(names: Vec<Option<String>>) -> (bool, bool, Option<u8>) {
    let actions = names.into_iter().map(|name| name.map(|n| Action::try_from(n.as_str()).unwrap()).unwrap_or(Action::None)).collect();
    let st = Statement { actions: ActionSet(actions), ..Default::default() };
    let family = st.action_family().map(|f| match f { ActionFamily::S3 => 0, ActionFamily::Admin => 1, ActionFamily::Sts => 2, ActionFamily::Kms => 3, ActionFamily::Mixed => 4 });
    (st.is_admin(), st.is_sts(), family)
}
"#);
    }
    if source.ends_with("policy/function.rs") {
        code.push_str(r#"
pub fn normal_conditions(f: Functions) -> Vec<Condition> { f.for_normal }
pub fn with_conditions(conditions: Vec<Condition>, qualifier: u8) -> Functions {
    let mut f = Functions::default();
    match qualifier { 0 => f.for_normal = conditions, 1 => f.for_any_value = conditions, _ => f.for_all_values = conditions }
    f
}
"#);
    }
    if source.ends_with("policy/function/binary.rs") {
        code.push_str(r#"
pub fn from_encoded_test(values: Vec<String>) -> Result<BinaryFuncValue, BinaryFuncValueError> { BinaryFuncValue::from_encoded_values(values) }
"#);
    }
    if source.ends_with("policy/policy.rs") {
        code.push_str(r#"
impl Policy { pub fn dedup_for_test(&mut self) { self.drop_duplicate_statements(); } }
"#);
    }
    if source.ends_with("policy/function.rs") {
        code.push_str(r#"
pub fn with_all_conditions(normal:Vec<Condition>,any:Vec<Condition>,all:Vec<Condition>)->Functions {
    Functions { for_normal:normal,for_any_value:any,for_all_values:all }
}
"#);
    }
    if source.ends_with("policy/function/func.rs") {
        code.push_str(r#"
pub fn rename_keys_for_test<T>(f:&mut InnerFunc<T>,key:&Key){for e in &mut f.0{e.key=key.clone();}}
"#);
    }
    fs::write(&target, code).unwrap();
    println!("cargo:rerun-if-changed={}", source.display());
    target
}
fn main() {
    let manifest = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap());
    let source = manifest.join("../../upstream-src/crates/policy/src");
    let output = PathBuf::from(env::var("OUT_DIR").unwrap());
    let policy = render(&source.join("policy.rs"), &source, &output);
    let error = render(&source.join("error.rs"), &source, &output);
    let serde_datetime = render(&source.join("serde_datetime.rs"), &source, &output);
    let lib = format!("#[path = {:?}] pub mod policy;\n#[path = {:?}] pub mod error;\n#[path = {:?}] pub mod serde_datetime;\n", policy.to_str().unwrap(), error.to_str().unwrap(), serde_datetime.to_str().unwrap());
    fs::write(output.join("oracle.rs"), lib).unwrap();
}
