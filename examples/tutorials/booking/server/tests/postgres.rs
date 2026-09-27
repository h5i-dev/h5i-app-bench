//! The PostgreSQL store agrees with the kernel's `apply`: random commands run
//! through the real engine and through `MemoryEngine` give the same replies
//! and the same final state, and the outbox holds exactly the notifications
//! of the committed commands. Needs I5H_TEST_DATABASE_URL; skips otherwise.

use booking_kernel as k;
use booking_server::{effect_payload, BookingApp, BookingStore};
use i5h::{MemoryEngine, TenantId};
use i5h_pg::{pool, Engine, EngineConfig};
use tokio_postgres::NoTls;

fn rng(state: &mut u64, n: u64) -> u64 {
    *state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
    (*state >> 33) % n
}

fn sorted(mut s: k::Snapshot) -> k::Snapshot {
    s.admins.sort_by_key(|a| a.user);
    s.rooms.sort_by_key(|r| r.id);
    s.bookings.sort_by_key(|b| b.id);
    s
}

#[tokio::test]
async fn store_agrees_with_apply() {
    let Ok(url) = std::env::var("I5H_TEST_DATABASE_URL") else {
        eprintln!("I5H_TEST_DATABASE_URL not set; skipping");
        return;
    };
    let pg = Engine::<BookingApp, BookingStore>::new(pool(&url, 4).unwrap(), EngineConfig::default());
    pg.install_schema().await.unwrap();
    let mem = MemoryEngine::<BookingApp>::default();
    let org = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_nanos() as u64 % (1 << 50);

    let mut s = 5;
    let mut expected = Vec::new();
    for i in 0..500u64 {
        // The clock moves forward as the test runs.
        let now = i / 4;
        let actor = k::Principal { org, user: 1 + rng(&mut s, 4), now };
        let cmd = match rng(&mut s, 8) {
            0 => k::Command::AddAdmin { user: 1 + rng(&mut s, 4) },
            1 => k::Command::CreateRoom { dest: 7 + rng(&mut s, 2) },
            2..=4 => {
                let start_at = (now + rng(&mut s, 40)).saturating_sub(5);
                k::Command::Book { room: rng(&mut s, 4), start_at, end_at: start_at + rng(&mut s, 6) }
            }
            5 | 6 => k::Command::Cancel { id: rng(&mut s, 40) },
            _ => k::Command::List,
        };
        // The notifications this command commits, if it succeeds.
        if let Ok((ws, _)) = k::transition(&actor, &mem.snapshot(TenantId(org)), &cmd) {
            for w in &ws {
                if let k::Write::Emit(e) = w {
                    expected.push((e.dest as i64, effect_payload(e)));
                }
            }
        }
        let got = pg.execute(&actor, &cmd).await.unwrap();
        let want = mem.execute(&actor, &cmd);
        match (&got, &want) {
            // Row order in a listing is not meaningful.
            (Ok(k::Reply::Bookings(a)), Ok(k::Reply::Bookings(b))) => {
                let (mut a, mut b) = (a.clone(), b.clone());
                a.sort_by_key(|x| x.id);
                b.sort_by_key(|x| x.id);
                assert_eq!(a, b, "{cmd:?}");
            }
            _ => assert_eq!(got, want, "{cmd:?}"),
        }
    }
    let a = sorted(pg.snapshot(TenantId(org)).await.unwrap());
    let b = sorted(mem.snapshot(TenantId(org)));
    assert_eq!(a, b);
    assert!(expected.len() > 20, "the run books and cancels");

    let (c, conn) = tokio_postgres::connect(&url, NoTls).await.unwrap();
    tokio::spawn(conn);
    let rows: Vec<(i64, Vec<u8>)> = c
        .query("SELECT dest, payload FROM i5h_outbox WHERE tenant_id = $1 ORDER BY id", &[&(org as i64)])
        .await
        .unwrap()
        .iter()
        .map(|r| (r.get(0), r.get(1)))
        .collect();
    assert_eq!(rows, expected);
}
