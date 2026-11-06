//! The table decisions: the kernel's `store` against wastebin_core's own
//! `Database` (SQLite through the upstream handler thread, real zstd, real
//! argon2 + XChaCha20-Poly1305) on random tables and operation sequences.
//!
//! The test inserts pastes through `Database::insert`, then sets `expires`
//! and `uid` with a second SQLite connection to reach states the HTTP API
//! only reaches over time. Expiry times are at least ten minutes away from
//! the clock, so the run cannot cross a boundary.

use std::num::NonZeroU32;
use std::time::{SystemTime, UNIX_EPOCH};

use wastebin_core::crypto::Password;
use wastebin_core::db::{self, Database, Open, read, write};
use wastebin_core::id::Id;
use wastebin_kernel::store::{self, DbError, Row};

use crate::Rng;

const PASSWORDS: [&str; 3] = ["correct horse", "battery", "staple"];

fn now() -> i64 {
    SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() as i64
}

fn kernel_err(e: &db::Error) -> DbError {
    match e {
        db::Error::NotFound => DbError::NotFound,
        db::Error::NoPassword => DbError::NoPassword,
        db::Error::Delete => DbError::Delete,
        db::Error::Crypto(_) => DbError::Crypto,
        other => panic!("unexpected upstream error {other:?}"),
    }
}

fn text_of(n: u64) -> String {
    format!("paste-{n}")
}
fn data_of(text: &str) -> u64 {
    text.strip_prefix("paste-").unwrap().parse().unwrap()
}
fn title_of(n: u64) -> String {
    format!("title-{n}")
}
fn title_num(t: &Option<String>) -> Option<u64> {
    t.as_ref().map(|t| t.strip_prefix("title-").unwrap().parse().unwrap())
}

fn check_metadata(m: &read::Metadata, k: &store::Metadata, t: i64, what: &str) {
    assert_eq!(m.uid, k.uid, "{what}: uid");
    assert_eq!(title_num(&m.title), k.title, "{what}: title");
    assert_eq!(m.must_be_deleted, k.must_be_deleted, "{what}: must_be_deleted");
    // Upstream shows the remaining time if positive; the kernel keeps the raw column.
    assert_eq!(m.expiration.is_some(), k.expires.is_some_and(|e| e > t), "{what}: expiration");
}

fn check_entry(up: &read::Entry, k: &store::Entry, t: i64, what: &str) {
    let (ud, kd) = match (up, k) {
        (read::Entry::Regular(u), store::Entry::Regular(k)) => (u, k),
        (read::Entry::Burned(u), store::Entry::Burned(k)) => (u, k),
        (read::Entry::Encrypted(u), store::Entry::Encrypted(k)) => (u, k),
        _ => panic!("{what}: upstream {up:?}, kernel {k:?}"),
    };
    assert_eq!(data_of(&ud.text), kd.data, "{what}: data");
    check_metadata(&ud.metadata, &kd.metadata, t, what);
}

struct Fixture {
    db: Database,
    side: rusqlite::Connection,
    rows: Vec<Row>,
    _dir: tempfile::TempDir,
}

impl Fixture {
    fn table_ids(&self) -> Vec<i64> {
        let mut st = self.side.prepare("SELECT id FROM entries ORDER BY id").unwrap();
        st.query_map([], |r| r.get(0)).unwrap().collect::<Result<_, _>>().unwrap()
    }
    fn check_table(&self, what: &str) {
        let mut k: Vec<i64> = self.rows.iter().map(|r| r.id).collect();
        k.sort();
        assert_eq!(self.table_ids(), k, "{what}: table");
    }
}

async fn fixture(r: &mut Rng, n: usize, encrypted_budget: &mut usize) -> Fixture {
    let dir = tempfile::tempdir().unwrap();
    let path = dir.path().join("db.sqlite");
    let (db, handler) = Database::new(Open::Path(path.clone())).unwrap();
    tokio::spawn(handler);
    let side = rusqlite::Connection::open(&path).unwrap();
    side.busy_timeout(std::time::Duration::from_secs(10)).unwrap();
    let t = now();
    let mut rows = Vec::new();
    for i in 0..n as u64 {
        let password = if *encrypted_budget > 0 && r.chance(1, 6) {
            *encrypted_budget -= 1;
            Some(r.below(3))
        } else {
            None
        };
        let burn = *r.pick(&[None, Some(false), Some(true), Some(true)]);
        let title = if r.chance(1, 2) { Some(i) } else { None };
        let entry = write::Entry {
            text: text_of(i),
            extension: None,
            expires: if r.chance(1, 3) { NonZeroU32::new(3600) } else { None },
            burn_after_reading: burn,
            uid: None,
            password: password.map(|p| PASSWORDS[p as usize].to_string()),
            title: title.map(title_of),
        };
        let (id, _) = db.insert(entry).await.unwrap();
        // Owner: none, or one of three uids.
        let uid = *r.pick(&[None, Some(1i64), Some(2), Some(3)]);
        side.execute("UPDATE entries SET uid = ?1 WHERE id = ?2", rusqlite::params![uid, id.to_i64()])
            .unwrap();
        // Expiry: none, or well in the past or the future.
        let expires = *r.pick(&[None, None, Some(-86_400i64), Some(-900), Some(900), Some(86_400)]);
        let expires = expires.map(|d| t + d);
        side.execute(
            "UPDATE entries SET expires = CASE WHEN ?1 IS NULL THEN NULL ELSE datetime(?1, 'unixepoch') END WHERE id = ?2",
            rusqlite::params![expires, id.to_i64()],
        )
        .unwrap();
        rows.push(Row {
            id: id.to_i64(),
            uid,
            burn,
            secret: password,
            expires,
            data: i,
            title,
        });
    }
    Fixture { db, side, rows, _dir: dir }
}

fn pick_id(r: &mut Rng, f: &Fixture) -> Id {
    if f.rows.is_empty() || r.chance(1, 8) {
        Id::from(r.next() as i64)
    } else {
        Id::from(r.pick(&f.rows).id)
    }
}

#[tokio::test(flavor = "multi_thread", worker_threads = 2)]
async fn database_agrees() {
    let mut r = Rng(0x5eed_0101);
    let mut encrypted_budget = 18;
    let mut decrypt_budget = 40usize;
    let mut counts = [0usize; 8];
    for round in 0..4 {
        let mut f = fixture(&mut r, 40, &mut encrypted_budget).await;
        f.check_table("initial");
        for step in 0..300 {
            let what = format!("round {round} step {step}");
            let t = now();
            match r.below(10) {
                0..=4 => {
                    let id = pick_id(&mut r, &f);
                    let row = store::find_row(&f.rows, id.to_i64());
                    let mut pw = if r.chance(1, 2) { Some(r.below(3)) } else { None };
                    // Each decryption costs a full argon2 hash; keep their number bounded.
                    if pw.is_some() && row.is_some_and(|x| x.secret.is_some()) {
                        if decrypt_budget == 0 {
                            pw = None;
                        } else {
                            decrypt_budget -= 1;
                        }
                    }
                    let up = f
                        .db
                        .get(id, pw.map(|p| Password::from(PASSWORDS[p as usize].as_bytes().to_vec())))
                        .await;
                    let (after, k) = store::get(&f.rows, id.to_i64(), t, pw);
                    match (&up, &k) {
                        (Ok(u), Ok(k)) => {
                            counts[0] += 1;
                            check_entry(u, k, t, &what)
                        }
                        (Err(e), Err(k)) => {
                            counts[1] += 1;
                            if *k == DbError::Crypto {
                                counts[2] += 1;
                            }
                            assert_eq!(kernel_err(e), *k, "{what}: get error")
                        }
                        _ => panic!("{what}: get upstream {up:?} kernel {k:?}"),
                    }
                    f.rows = after;
                }
                5..=6 => {
                    let id = pick_id(&mut r, &f);
                    let up = f.db.get_metadata(id).await;
                    let k = store::get_metadata(&f.rows, id.to_i64());
                    match (&up, &k) {
                        (Ok(u), Ok(k)) => check_metadata(u, k, t, &what),
                        (Err(e), Err(k)) => assert_eq!(kernel_err(e), *k, "{what}: metadata error"),
                        _ => panic!("{what}: metadata upstream {up:?} kernel {k:?}"),
                    }
                    counts[3] += 1;
                }
                7..=8 => {
                    let id = pick_id(&mut r, &f);
                    let uids: Vec<i64> = (0..r.below(3)).map(|_| 1 + r.below(4) as i64).collect();
                    let up = f.db.delete_for(id, &uids).await;
                    let k = store::delete_for(&f.rows, id.to_i64(), &uids);
                    match (&up, k) {
                        (Ok(()), Ok(after)) => {
                            counts[4] += 1;
                            f.rows = after
                        }
                        (Err(e), Err(k)) => {
                            counts[5] += 1;
                            assert_eq!(kernel_err(e), k, "{what}: delete_for error")
                        }
                        (up, k) => panic!("{what}: delete_for upstream {up:?} kernel {k:?}"),
                    }
                }
                _ => {
                    if r.chance(1, 4) {
                        let mut up: Vec<i64> = f.db.purge().await.unwrap().iter().map(|i| i.to_i64()).collect();
                        up.sort();
                        let after = store::purge(&f.rows, t);
                        let mut gone: Vec<i64> =
                            f.rows.iter().filter(|x| !after.contains(x)).map(|x| x.id).collect();
                        gone.sort();
                        assert_eq!(up, gone, "{what}: purge");
                        f.rows = after;
                        counts[6] += 1;
                    }
                }
            }
            f.check_table(&what);
        }
    }
    eprintln!("counts {counts:?}, encrypted left {encrypted_budget}, decrypt left {decrypt_budget}");
    assert!(counts[0] > 100 && counts[1] > 100 && counts[2] > 0 && counts[4] > 10 && counts[5] > 50);
}
