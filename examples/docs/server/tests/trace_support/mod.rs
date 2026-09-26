//! Records engine events and checks them with `lean/`'s `tracecheck`.
#![allow(dead_code)]
use i5h_pg::Event;
use std::path::PathBuf;
use std::process::Command;
use std::sync::{Arc, Mutex};

#[derive(Clone, Default)]
pub struct Trace(Arc<Mutex<Vec<String>>>);

impl Trace {
    pub fn tracer(&self) -> impl Fn(Event) + Send + Sync + 'static {
        let t = self.0.clone();
        move |e| t.lock().unwrap().push(e.json())
    }

    pub fn len(&self) -> usize {
        self.0.lock().unwrap().len()
    }

    /// Lines for one tenant (other tests may share the engine).
    pub fn lines_for(&self, tenant: u64) -> Vec<String> {
        let tag = format!("\"tenant\":{tenant},");
        self.0.lock().unwrap().iter().filter(|l| l.contains(&tag)).cloned().collect()
    }
}

fn lake() -> Option<PathBuf> {
    let home = std::env::var("HOME").ok()?;
    let elan = PathBuf::from(home).join(".elan/bin/lake");
    if elan.exists() {
        return Some(elan);
    }
    Command::new("lake").arg("--version").output().ok().map(|_| PathBuf::from("lake"))
}

/// Runs the checker on `lines`. `None` if Lean is missing.
pub fn verdict(name: &str, lines: &[String]) -> Option<(bool, String)> {
    let dir = PathBuf::from(env!("CARGO_TARGET_TMPDIR")).join("traces");
    std::fs::create_dir_all(&dir).unwrap();
    let file = dir.join(format!("{name}.jsonl"));
    std::fs::write(&file, lines.join("\n") + "\n").unwrap();
    let Some(lake) = lake() else {
        eprintln!("lake not found; trace {} not checked", file.display());
        return None;
    };
    let lean = PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("../../../lean");
    let out = Command::new(lake).args(["exe", "tracecheck"]).arg(&file).current_dir(lean).output().unwrap();
    Some((out.status.success(), String::from_utf8_lossy(&out.stdout).into_owned()))
}

/// The checker must accept `lines`.
pub fn check(name: &str, lines: &[String]) {
    if let Some((ok, out)) = verdict(name, lines) {
        eprintln!("{name}: {}", out.lines().last().unwrap_or(""));
        assert!(ok, "trace {name} rejected:\n{out}");
    }
}

/// The checker must reject `lines`.
pub fn reject(name: &str, lines: &[String]) {
    if let Some((ok, out)) = verdict(name, lines) {
        eprintln!("{name}: {}", out.lines().next().unwrap_or(""));
        assert!(!ok, "trace {name} accepted:\n{out}");
    }
}
