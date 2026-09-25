mod common;

use common::*;
use docs_kernel as k;
use docs_server::{principal, DocsApp};
use i5h::{MemoryEngine, TenantId};
use i5h_pg::{DbError, EngineConfig};
use std::sync::Arc;

macro_rules! engine_or_skip {
    ($cfg:expr) => {
        match engine($cfg).await {
            Some(e) => e,
            None => {
                eprintln!("I5H_TEST_DATABASE_URL not set; skipping");
                return;
            }
        }
    };
}

/// The Postgres store must commit exactly what the kernel's `apply` says.
#[tokio::test]
async fn postgres_matches_memory_engine() {
    let pg = engine_or_skip!(EngineConfig::default());
    for seed in 0..20 {
        let tenant = fresh_tenant();
        let mem = MemoryEngine::<DocsApp>::default();
        let mut rng = Rng(seed);
        for step in 0..60 {
            let actor = principal(tenant, 1 + rng.next(4));
            let cmd = random_command(&mut rng);
            let want = mem.execute(&actor, &cmd);
            let got = pg.execute(&actor, &cmd).await.expect("db");
            assert_eq!(got, want, "seed {seed} step {step}: {cmd:?}");
            let a = normalize(mem.snapshot(TenantId(tenant)));
            let b = normalize(pg.snapshot(TenantId(tenant)).await.unwrap());
            assert_eq!(a, b, "seed {seed} step {step}: {cmd:?}");
        }
    }
}

#[tokio::test]
async fn tenants_do_not_see_each_other() {
    let pg = engine_or_skip!(EngineConfig::default());
    let (a, b) = (fresh_tenant(), fresh_tenant());
    let alice = principal(a, 1);
    let mallory = principal(b, 1); // same user id, other org
    let k::Reply::Created(p) = pg.execute(&alice, &k::Command::CreateProject { name: b"a".to_vec() }).await.unwrap().unwrap() else {
        panic!()
    };
    let doc = k::Command::CreateDocument { project: p, title: b"t".to_vec(), body: b"secret".to_vec() };
    let k::Reply::Created(d) = pg.execute(&alice, &doc).await.unwrap().unwrap() else { panic!() };

    let before = pg.snapshot(TenantId(a)).await.unwrap();
    assert_eq!(pg.execute(&mallory, &k::Command::GetDocument { doc: d }).await.unwrap(), Err(k::Error::NotFound));
    let del = k::Command::DeleteDocument { doc: d };
    assert_eq!(pg.execute(&mallory, &del).await.unwrap(), Err(k::Error::NotFound));
    // Mallory creating ids that collide with Alice's must not touch Alice's rows.
    pg.execute(&mallory, &k::Command::CreateProject { name: b"m".to_vec() }).await.unwrap().unwrap();
    assert_eq!(pg.snapshot(TenantId(a)).await.unwrap(), before);
}

/// Two owners each try to remove the other at the same time. Without the
/// tenant lock this relies on SERIALIZABLE + retry to keep one owner.
#[tokio::test]
async fn concurrent_owner_removal_keeps_an_owner() {
    let pg = Arc::new(engine_or_skip!(EngineConfig { tenant_lock: false, max_attempts: 50 }));
    for _ in 0..20 {
        let t = fresh_tenant();
        let (u1, u2) = (principal(t, 1), principal(t, 2));
        let k::Reply::Created(p) = pg.execute(&u1, &k::Command::CreateProject { name: vec![] }).await.unwrap().unwrap() else {
            panic!()
        };
        let set = k::Command::SetMember { project: p, user: 2, role: k::Role::Owner };
        pg.execute(&u1, &set).await.unwrap().unwrap();

        let (e1, e2) = (pg.clone(), pg.clone());
        let r1 = tokio::spawn(async move { e1.execute(&u1, &k::Command::RemoveMember { project: p, user: 2 }).await });
        let r2 = tokio::spawn(async move { e2.execute(&u2, &k::Command::RemoveMember { project: p, user: 1 }).await });
        let (r1, r2) = (r1.await.unwrap().unwrap(), r2.await.unwrap().unwrap());
        assert!(r1.is_ok() != r2.is_ok(), "exactly one removal wins: {r1:?} {r2:?}");

        let snap = pg.snapshot(TenantId(t)).await.unwrap();
        assert_eq!(k::count_owners(&snap.members, p), 1);
    }
    eprintln!("stats: {:?}", pg.stats);
}

#[tokio::test]
async fn idempotency_key_runs_once() {
    let pg = engine_or_skip!(EngineConfig::default());
    let t = fresh_tenant();
    let u = principal(t, 1);
    let cmd = k::Command::CreateProject { name: b"once".to_vec() };
    let r1 = pg.execute_idempotent(&u, "req-1", &cmd).await.unwrap();
    let r2 = pg.execute_idempotent(&u, "req-1", &cmd).await.unwrap();
    assert_eq!(r1, r2);
    assert_eq!(pg.snapshot(TenantId(t)).await.unwrap().projects.len(), 1);

    let other = k::Command::CreateProject { name: b"different".to_vec() };
    assert!(matches!(pg.execute_idempotent(&u, "req-1", &other).await, Err(DbError::IdempotencyConflict)));
}

#[tokio::test]
async fn concurrent_idempotent_retries_run_once() {
    let pg = Arc::new(engine_or_skip!(EngineConfig { tenant_lock: false, max_attempts: 50 }));
    let t = fresh_tenant();
    let mut tasks = vec![];
    for _ in 0..8 {
        let pg = pg.clone();
        tasks.push(tokio::spawn(async move {
            let cmd = k::Command::CreateProject { name: b"x".to_vec() };
            pg.execute_idempotent(&principal(t, 1), "k", &cmd).await.unwrap().unwrap()
        }));
    }
    let mut replies = vec![];
    for task in tasks {
        replies.push(task.await.unwrap());
    }
    assert!(replies.windows(2).all(|w| w[0] == w[1]));
    assert_eq!(pg.snapshot(TenantId(t)).await.unwrap().projects.len(), 1);
}
