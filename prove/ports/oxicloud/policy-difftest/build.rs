use std::{env, fs, path::PathBuf, process::Command};
fn main() {
    let repo = PathBuf::from(env::var("CARGO_MANIFEST_DIR").unwrap()).join("../../../results/upstream/oxicloud.git");
    let revision = "8c0dd334cf065ad11f60f9be24e2aafd5dda7550";
    let out = Command::new("git").args(["-C"]).arg(&repo)
        .args(["show", &format!("{revision}:src/domain/entities/drive.rs")]).output().unwrap();
    assert!(out.status.success(), "pinned upstream repository must be available");
    // Rust inner module documentation needs a real module file rather than include!.
    let path = PathBuf::from(env::var("OUT_DIR").unwrap()).join("drive.rs");
    fs::write(&path, out.stdout).unwrap();
    let wrapper = format!("#[path = {:?}] pub mod drive;", path);
    fs::write(PathBuf::from(env::var("OUT_DIR").unwrap()).join("entities.rs"), wrapper).unwrap();
    println!("cargo:rerun-if-changed=build.rs");
}
