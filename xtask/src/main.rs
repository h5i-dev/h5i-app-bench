//! `cargo i5h-verify`: run every check that CI runs, locally.
//!
//! Steps: Rust tests, cargo-deny, re-extraction drift, Lean builds with the
//! sorry/axiom gates, and with `--full` the mutation suite, the Rust-vs-Lean
//! differential test. Missing tools are reported as skipped, never as passed.

use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode, Stdio};
use std::time::Instant;

/// Proof projects: directory, extraction script, generated file.
const PROJECTS: &[(&str, Option<&str>, Option<&str>)] = &[
    ("examples/docs/proofs", Some("scripts/extract.sh"), Some("examples/docs/proofs/generated/DocsKernel.lean")),
    ("examples/kellnr/proofs", Some("scripts/extract-kellnr.sh"), Some("examples/kellnr/proofs/generated/KellnrKernel.lean")),
    ("examples/atuin/proofs", Some("scripts/extract-atuin.sh"), Some("examples/atuin/proofs/generated/AtuinKernel.lean")),
    ("crates/i5h-sql/proofs", Some("scripts/extract-sql.sh"), Some("crates/i5h-sql/proofs/generated/I5hSql.lean")),
    ("crates/i5h-pgsql/proofs", Some("scripts/extract-pgsql.sh"), Some("crates/i5h-pgsql/proofs/generated/I5hPgsql.lean")),
    ("crates/i5h-token/proofs", Some("scripts/extract-token.sh"), Some("crates/i5h-token/proofs/generated/I5hToken.lean")),
    ("crates/i5h-json/proofs", Some("scripts/extract-json.sh"), Some("crates/i5h-json/proofs/generated/I5hJson.lean")),
    ("examples/tutorials/calculator/proofs", Some("scripts/extract-calculator.sh"), Some("examples/tutorials/calculator/proofs/generated/CalculatorKernel.lean")),
    ("examples/tutorials/board/proofs", Some("scripts/extract-board.sh"), Some("examples/tutorials/board/proofs/generated/BoardKernel.lean")),
    ("examples/wastebin/proofs", Some("scripts/extract-wastebin.sh"), Some("examples/wastebin/proofs/generated/WastebinKernel.lean")),
    ("examples/conduit/proofs", Some("scripts/extract-conduit.sh"), Some("examples/conduit/proofs/generated/ConduitKernel.lean")),
    ("examples/cratesio/proofs", Some("scripts/extract-cratesio.sh"), Some("examples/cratesio/proofs/generated/CratesioKernel.lean")),
    ("examples/tutorials/ledger/proofs", Some("scripts/extract-ledger.sh"), Some("examples/tutorials/ledger/proofs/generated/LedgerKernel.lean")),
    ("examples/tutorials/inbox/proofs", Some("scripts/extract-inbox.sh"), Some("examples/tutorials/inbox/proofs/generated/InboxKernel.lean")),
    ("examples/tutorials/booking/proofs", Some("scripts/extract-booking.sh"), Some("examples/tutorials/booking/proofs/generated/BookingKernel.lean")),
    ("crates/i5h/proofs", None, None),
];

#[derive(PartialEq)]
enum Outcome {
    Pass,
    Fail(String),
    Skip(String),
}

struct Ctx {
    root: PathBuf,
    results: Vec<(String, Outcome, f32)>,
}

impl Ctx {
    fn step(&mut self, name: &str, f: impl FnOnce(&Path) -> Outcome) {
        eprint!("{name:<44} ");
        let t = Instant::now();
        let out = f(&self.root);
        let secs = t.elapsed().as_secs_f32();
        match &out {
            Outcome::Pass => eprintln!("ok      {secs:>6.1}s"),
            Outcome::Skip(why) => eprintln!("skipped ({why})"),
            Outcome::Fail(log) => eprintln!("FAILED  {secs:>6.1}s\n{log}"),
        }
        self.results.push((name.to_string(), out, secs));
    }
}

/// Run a command; on failure return the last lines of its output.
fn run(dir: &Path, prog: &str, args: &[&str]) -> Outcome {
    match Command::new(prog).args(args).current_dir(dir).stdin(Stdio::null()).output() {
        Err(e) => Outcome::Fail(format!("cannot run {prog}: {e}")),
        Ok(o) if o.status.success() => Outcome::Pass,
        Ok(o) => {
            let text = format!("{}{}", String::from_utf8_lossy(&o.stdout), String::from_utf8_lossy(&o.stderr));
            let tail: Vec<&str> = text.lines().rev().take(30).collect();
            Outcome::Fail(tail.into_iter().rev().collect::<Vec<_>>().join("\n"))
        }
    }
}

/// True if `prog` is an executable on PATH (charon and aeneas have no `--version`).
fn have(prog: &str) -> bool {
    std::env::var_os("PATH").is_some_and(|paths| std::env::split_paths(&paths).any(|d| d.join(prog).is_file()))
}

fn have_cargo_sub(sub: &str) -> bool {
    Command::new("cargo").args([sub, "--version"]).stdout(Stdio::null()).stderr(Stdio::null()).status().is_ok_and(|s| s.success())
}

/// Hand-written Lean files must not use sorry or native_decide; no file may declare an axiom.
fn lean_scan(dir: &Path) -> Outcome {
    let mut bad = Vec::new();
    let Ok(entries) = std::fs::read_dir(dir) else { return Outcome::Fail(format!("{} missing", dir.display())) };
    let mut files: Vec<PathBuf> = entries.flatten().map(|e| e.path()).filter(|p| p.extension().is_some_and(|x| x == "lean")).collect();
    for sub in ["Engine", "I5hLib", "generated"] {
        if let Ok(e) = std::fs::read_dir(dir.join(sub)) {
            files.extend(e.flatten().map(|e| e.path()).filter(|p| p.extension().is_some_and(|x| x == "lean")));
        }
    }
    for f in files {
        let text = std::fs::read_to_string(&f).unwrap_or_default();
        // Generated Lean (extracted kernels, schema! output) lives in generated/.
        let is_generated = f.parent().is_some_and(|p| p.ends_with("generated"));
        for (i, line) in text.lines().enumerate() {
            let code = line.split("--").next().unwrap_or("");
            let words = |w: &str| code.split(|c: char| !c.is_alphanumeric() && c != '_').any(|t| t == w);
            if line.starts_with("axiom ") || (!is_generated && (words("sorry") || words("native_decide"))) {
                bad.push(format!("{}:{}: {}", f.display(), i + 1, line.trim()));
            }
        }
    }
    if bad.is_empty() { Outcome::Pass } else { Outcome::Fail(bad.join("\n")) }
}

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();
    if args.first().map(String::as_str) != Some("verify") {
        eprintln!("usage: cargo i5h-verify [--full] [--no-extract]");
        return ExitCode::from(2);
    }
    let full = args.iter().any(|a| a == "--full");
    let extract = !args.iter().any(|a| a == "--no-extract");
    let root = PathBuf::from(env!("CARGO_MANIFEST_DIR")).parent().unwrap().to_path_buf();
    let mut cx = Ctx { root, results: Vec::new() };
    let db = std::env::var("I5H_TEST_DATABASE_URL").is_ok();

    cx.step("rust tests", |r| {
        if !db {
            return Outcome::Skip("I5H_TEST_DATABASE_URL unset".into());
        }
        run(r, "cargo", &["test", "--workspace", "--locked", "-q"])
    });
    cx.step("cargo deny (bans)", |r| {
        if !have_cargo_sub("deny") {
            return Outcome::Skip("cargo-deny not installed".into());
        }
        run(r, "cargo", &["deny", "check", "bans"])
    });
    if extract {
        let tools = have("charon") && have("aeneas");
        for (_, script, generated) in PROJECTS {
            let (Some(script), Some(generated)) = (script, generated) else { continue };
            cx.step(&format!("extract {generated}"), |r| {
                if !tools {
                    return Outcome::Skip("charon/aeneas not on PATH".into());
                }
                match run(r, "bash", &[script]) {
                    Outcome::Pass => run(r, "git", &["diff", "--exit-code", "--", generated]),
                    other => other,
                }
            });
        }
    }
    let lake = have("lake");
    for (dir, _, _) in PROJECTS {
        cx.step(&format!("lean {dir}"), |r| {
            if !lake {
                return Outcome::Skip("lake not on PATH".into());
            }
            match run(&r.join(dir), "lake", &["build"]) {
                Outcome::Pass => lean_scan(&r.join(dir)),
                other => other,
            }
        });
    }
    cx.step("axioms of the docs theorems", |r| {
        if !lake {
            return Outcome::Skip("lake not on PATH".into());
        }
        run(r, "bash", &["scripts/ci-lean-gate.sh"])
    });
    cx.step("axioms of the database theorems", |r| {
        if !lake {
            return Outcome::Skip("lake not on PATH".into());
        }
        run(r, "bash", &["scripts/ci-db-axioms.sh"])
    });
    if full {
        cx.step("mutation suite", |r| run(r, "python3", &["scripts/mutants.py"]));
        cx.step("app mutation suite", |r| run(r, "python3", &["scripts/mutants-apps.py"]));
        cx.step("rust vs lean differential test", |r| run(r, "bash", &["scripts/difftest.sh"]));
    }

    let failed = cx.results.iter().filter(|(_, o, _)| matches!(o, Outcome::Fail(_))).count();
    let skipped = cx.results.iter().filter(|(_, o, _)| matches!(o, Outcome::Skip(_))).count();
    eprintln!("\n{} passed, {failed} failed, {skipped} skipped", cx.results.len() - failed - skipped);
    if failed > 0 { ExitCode::FAILURE } else { ExitCode::SUCCESS }
}
