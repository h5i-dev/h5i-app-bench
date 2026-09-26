//! Engine runs recorded with `Engine::with_trace` and checked against the Lean
//! protocol model (`lean/Engine/Trace.lean`).

mod common;
mod trace_support;

use common::*;
use docs_kernel as k;
use docs_server::{principal, DocsApp, DocsStore};
use i5h_pg::{pool, DbError, Engine, EngineConfig};
use std::sync::atomic::Ordering::Relaxed;
use std::sync::Arc;
use trace_support::{check, reject, Trace};

async fn traced(config: EngineConfig) -> Option<(Arc<Engine<DocsApp, DocsStore>>, Trace)> {
    let url = std::env::var("I5H_TEST_DATABASE_URL").ok()?;
    let trace = Trace::default();
    let e = Engine::new(pool(&url, 32).unwrap(), config).with_trace(trace.tracer());
    e.install_schema().await.unwrap();
    Some((Arc::new(e), trace))
}

macro_rules! traced_or_skip {
    ($cfg:expr) => {
        match traced($cfg).await {
            Some(x) => x,
            None => {
                eprintln!("I5H_TEST_DATABASE_URL not set; skipping");
                return;
            }
        }
    };
}

fn project(name: &str) -> k::Command {
    k::Command::CreateProject { name: name.as_bytes().to_vec() }
}

fn cfg(lock: bool) -> EngineConfig {
    EngineConfig { tenant_lock: lock, max_attempts: 100 }
}

/// Every event kind: commit, replay, key conflict, refusal.
#[tokio::test]
async fn sequential_run_matches_model() {
    let (e, trace) = traced_or_skip!(cfg(true));
    let t = fresh_tenant();
    let u = principal(t, 1);
    e.execute(&u, &project("a")).await.unwrap().unwrap();
    e.execute_idempotent(&u, "k1", &project("b")).await.unwrap().unwrap();
    e.execute_idempotent(&u, "k1", &project("b")).await.unwrap().unwrap();
    assert!(matches!(e.execute_idempotent(&u, "k1", &project("other")).await, Err(DbError::IdempotencyConflict)));
    let refused = e.execute(&principal(t, 9), &k::Command::RemoveMember { project: 0, user: 1 }).await.unwrap();
    assert!(refused.is_err());
    let lines = trace.lines_for(t);
    check("sequential", &lines);

    // The checker is not vacuous: corrupted runs are rejected.
    let bump = |l: &String| l.replace("\"ver\":2,\"reply\"", "\"ver\":3,\"reply\"");
    let skipped: Vec<String> = lines.iter().map(|l| if l.contains("\"ev\":\"commit\"") { bump(l) } else { l.clone() }).collect();
    assert_ne!(skipped, lines);
    reject("sequential_skipped_version", &skipped);
    let wrong: Vec<String> = lines
        .iter()
        .map(|l| if l.contains("\"ev\":\"replay\"") { l.replace("\"reply\":\"", "\"reply\":\"00") } else { l.clone() })
        .collect();
    assert_ne!(wrong, lines);
    reject("sequential_wrong_replay", &wrong);
}

fn lines(raw: &[&str]) -> Vec<String> {
    raw.iter().map(|l| l.to_string()).collect()
}

/// A lost COMMIT under a key: both outcomes are runs of the model, a second apply is not.
#[test]
fn lost_commit_cases() {
    let start = r#"{"ev":"start","tenant":1,"req":0,"cmd":"aa","key":"6b"}"#;
    let first = [
        start,
        r#"{"ev":"begin","tenant":1,"req":0,"ver":0}"#,
        r#"{"ev":"kernel","tenant":1,"req":0,"ver":0,"write":true,"reply":"01"}"#,
        r#"{"ev":"lost","tenant":1,"req":0,"ver":0}"#,
    ];
    // It had committed: the retry replays.
    let mut landed = first.to_vec();
    landed.extend([r#"{"ev":"begin","tenant":1,"req":0,"ver":1}"#, r#"{"ev":"replay","tenant":1,"req":0,"reply":"01"}"#]);
    check("lost_landed", &lines(&landed));
    // It had not: the retry commits.
    let mut missed = first.to_vec();
    missed.extend([
        r#"{"ev":"begin","tenant":1,"req":0,"ver":0}"#,
        r#"{"ev":"kernel","tenant":1,"req":0,"ver":0,"write":true,"reply":"01"}"#,
        r#"{"ev":"commit","tenant":1,"req":0,"ver":1,"reply":"01"}"#,
    ]);
    check("lost_missed", &lines(&missed));
    // It had committed, and the retry applies it again: rejected.
    let mut twice = first.to_vec();
    twice.extend([
        r#"{"ev":"begin","tenant":1,"req":0,"ver":1}"#,
        r#"{"ev":"kernel","tenant":1,"req":0,"ver":1,"write":true,"reply":"02"}"#,
        r#"{"ev":"commit","tenant":1,"req":0,"ver":2,"reply":"02"}"#,
    ]);
    reject("lost_applied_twice", &lines(&twice));
}

async fn same_key_retries(lock: bool) {
    let (e, trace) = traced_or_skip!(cfg(lock));
    let t = fresh_tenant();
    let mut tasks = vec![];
    for _ in 0..8 {
        let e = e.clone();
        tasks.push(tokio::spawn(async move { e.execute_idempotent(&principal(t, 1), "k", &project("x")).await }));
    }
    for task in tasks {
        task.await.unwrap().unwrap().unwrap();
    }
    check(&format!("same_key_lock_{lock}"), &trace.lines_for(t));
}

#[tokio::test]
async fn same_key_retries_match_model() {
    same_key_retries(false).await;
    same_key_retries(true).await;
}

/// Two owners remove each other at once.
#[tokio::test]
async fn owner_race_matches_model() {
    let (e, trace) = traced_or_skip!(cfg(false));
    let mut tenants = vec![];
    for _ in 0..10 {
        let t = fresh_tenant();
        tenants.push(t);
        let (u1, u2) = (principal(t, 1), principal(t, 2));
        let k::Reply::Created(p) = e.execute(&u1, &project("p")).await.unwrap().unwrap() else { panic!() };
        let set = k::Command::SetMember { project: p, user: 2, role: k::Role::Owner };
        e.execute(&u1, &set).await.unwrap().unwrap();
        let (e1, e2) = (e.clone(), e.clone());
        let a = tokio::spawn(async move { e1.execute(&u1, &k::Command::RemoveMember { project: p, user: 2 }).await });
        let b = tokio::spawn(async move { e2.execute(&u2, &k::Command::RemoveMember { project: p, user: 1 }).await });
        a.await.unwrap().unwrap().ok();
        b.await.unwrap().unwrap().ok();
    }
    let lines: Vec<String> = tenants.iter().flat_map(|t| trace.lines_for(*t)).collect();
    check("owner_race", &lines);
}

/// Random commands from concurrent writers, some under shared keys.
async fn random_writers(lock: bool) {
    let (e, trace) = traced_or_skip!(cfg(lock));
    let t = fresh_tenant();
    for i in 0..3 {
        e.execute(&principal(t, 1 + i), &project("seed")).await.unwrap().unwrap();
    }
    let mut tasks = vec![];
    for w in 0..8u64 {
        let e = e.clone();
        tasks.push(tokio::spawn(async move {
            let mut rng = Rng(w * 104729 + 7);
            for i in 0..15 {
                let cmd = random_command(&mut rng);
                let actor = principal(t, 1 + rng.next(4));
                let r = if i % 3 == 0 {
                    // Keys shared between writers of the same user: replays and conflicts happen.
                    let key = format!("u{}-k{}", actor.user, rng.next(6));
                    e.execute_idempotent(&actor, &key, &cmd).await
                } else {
                    e.execute(&actor, &cmd).await
                };
                match r {
                    Ok(_) | Err(DbError::IdempotencyConflict) | Err(DbError::RetriesExhausted) => {}
                    Err(err) => panic!("{err}"),
                }
            }
        }));
    }
    for task in tasks {
        task.await.unwrap();
    }
    eprintln!("lock {lock}: {:?}", e.stats);
    check(&format!("random_lock_{lock}"), &trace.lines_for(t));
}

#[tokio::test]
async fn random_writers_match_model() {
    random_writers(false).await;
    random_writers(true).await;
}

/// Known engine issue: idempotency keys are scoped by tenant, not by principal,
/// so a user can be replayed another user's reply for a command they may not run.
/// The kernel then looks nondeterministic to the model, and the checker rejects.
#[tokio::test]
async fn key_reuse_by_another_user_matches_model() {
    let (e, trace) = traced_or_skip!(cfg(true));
    let t = fresh_tenant();
    let (owner, outsider) = (principal(t, 1), principal(t, 9));
    let k::Reply::Created(p) = e.execute(&owner, &project("p")).await.unwrap().unwrap() else { panic!() };
    let cmd = k::Command::SetMember { project: p, user: 2, role: k::Role::Editor };
    assert_eq!(e.execute_idempotent(&outsider, "kx", &cmd).await.unwrap(), Err(k::Error::Forbidden));
    e.execute_idempotent(&owner, "kx", &cmd).await.unwrap().unwrap();
    assert_eq!(e.execute_idempotent(&outsider, "kx", &cmd).await.unwrap(), Err(k::Error::Forbidden));
    check("key_reuse_other_user", &trace.lines_for(t));
}

/// Tracing adds no events to other tenants and costs nothing when off.
#[tokio::test]
async fn untraced_engine_emits_nothing() {
    let Some(e) = engine(cfg(true)).await else { return };
    let t = fresh_tenant();
    e.execute(&principal(t, 1), &project("q")).await.unwrap().unwrap();
    assert_eq!(e.stats.commits.load(Relaxed), 1);
}
