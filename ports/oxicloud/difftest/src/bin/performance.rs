//! Warm-engine PostgreSQL authorization versus a preloaded pure snapshot.
use oxicloud::application::ports::authorization_ports::AuthorizationEngine;
use oxicloud_difftest::tests::*;
use oxicloud_kernel::{acl, model::*};
use std::{hint::black_box, sync::Arc, time::Instant};

fn pure_permissions(rounds: usize) {
    use oxicloud::domain::services::authorization::{roles_implying, Role as UpRole};
    let queries: Vec<_> = ROLES
        .into_iter()
        .flat_map(|r| PERMS.map(|p| (r, p)))
        .collect();
    let upstream_queries: Vec<_> = queries
        .iter()
        .map(|&(r, p)| {
            let r = match r {
                Role::Owner => UpRole::Owner,
                Role::Editor => UpRole::Editor,
                Role::Contributor => UpRole::Contributor,
                Role::Commenter => UpRole::Commenter,
                Role::Viewer => UpRole::Viewer,
            };
            (r, uperm(p))
        })
        .collect();
    for (name, inverse) in [("role_grants", false), ("role_implies", true)] {
        for (&(r, p), &(ur, up)) in queries.iter().zip(&upstream_queries) {
            let original = if inverse {
                roles_implying(up).contains(&ur)
            } else {
                ur.expand().contains(&up)
            };
            let rewritten = if inverse {
                acl::role_implies(r, p)
            } else {
                acl::role_grants(r, p)
            };
            assert_eq!(original, rewritten);
        }
        let measure = |kernel: bool, count: usize| {
            let start = Instant::now();
            for _ in 0..count {
                if kernel {
                    for &(r, p) in &queries {
                        black_box(if inverse {
                            acl::role_implies(black_box(r), black_box(p))
                        } else {
                            acl::role_grants(black_box(r), black_box(p))
                        });
                    }
                } else {
                    for &(r, p) in &upstream_queries {
                        black_box(if inverse {
                            roles_implying(black_box(p)).contains(&black_box(r))
                        } else {
                            black_box(r).expand().contains(&black_box(p))
                        });
                    }
                }
            }
            start.elapsed().as_nanos() as f64 / (count * queries.len()) as f64
        };
        measure(false, rounds / 10 + 1);
        measure(true, rounds / 10 + 1);
        let (mut us, mut ks, mut ratios) = (Vec::new(), Vec::new(), Vec::new());
        for sample in 0..11 {
            let (u, k) = if sample % 2 == 0 {
                (measure(false, rounds), measure(true, rounds))
            } else {
                let k = measure(true, rounds);
                (measure(false, rounds), k)
            };
            us.push(u);
            ks.push(k);
            ratios.push(k / u);
        }
        let median = |mut values: Vec<f64>| {
            values.sort_by(f64::total_cmp);
            values[5]
        };
        println!(
            "{}",
            serde_json::json!({"benchmark": name, "cases": queries.len(),
            "rounds": rounds, "samples": 11, "reply_parity": true,
            "upstream_samples_ns": us, "kernel_samples_ns": ks,
            "upstream_ns_per_call": median(us.clone()), "kernel_ns_per_call": median(ks.clone()),
            "kernel_over_upstream": median(ratios),
            "scope": "matched function-only role/permission membership query; pinned upstream static slices versus kernel boolean decision; preconverted enums; no database, async, input conversion or allocation"})
        );
    }
}

#[tokio::main]
async fn main() {
    let rounds: usize = std::env::args()
        .nth(1)
        .unwrap_or("2".into())
        .parse()
        .unwrap();
    assert!(rounds > 0);
    if std::env::args().any(|arg| arg == "--pure-only") {
        pure_permissions(rounds);
        return;
    }
    let pool = Arc::new(disposable_database().await);
    let seed = 0x6f78_6963_6c6f_0011;
    let mut rng = Rng(seed);
    for world_id in 0..4 {
        let db = world(&pool, &mut rng).await;
        let readonly = world_id == 3;
        let eng = engine(&pool, readonly);
        let now = now_secs();
        let queries: Vec<_> = (0..64)
            .map(|_| {
                let (s, r) = if !db.grants.is_empty() && rng.chance(60) {
                    near_grant(&db, &mut rng)
                } else {
                    (random_subject(&mut rng), random_resource(&mut rng))
                };
                (s, r, rng.pick(&PERMS))
            })
            .collect();
        let mut allowed = 0;
        for &(s, r, p) in &queries {
            let u = eng
                .check(usubject(s), uperm(p), uresource(r))
                .await
                .unwrap();
            assert_eq!(
                acl::check(&db, readonly, now, s, p, r),
                u,
                "world {world_id}: {s:?}, {r:?}, {p:?}"
            );
            allowed += usize::from(u);
        }
        let upstream_queries: Vec<_> = queries
            .iter()
            .map(|&(s, r, p)| (usubject(s), uresource(r), uperm(p)))
            .collect();
        let (mut us, mut ks) = (Vec::new(), Vec::new());
        for sample in 0..11 {
            // Alternate sample order, retaining raw elapsed nanoseconds.
            for kernel_first in [sample % 2 == 1, sample % 2 == 0] {
                let start = Instant::now();
                if kernel_first {
                    for _ in 0..rounds {
                        for &(s, r, p) in &queries {
                            black_box(acl::check(&db, readonly, now, s, p, r));
                        }
                    }
                    ks.push(start.elapsed().as_nanos());
                } else {
                    for _ in 0..rounds {
                        for (s, r, p) in &upstream_queries {
                            black_box(eng.check(s.clone(), *p, r.clone()).await.unwrap());
                        }
                    }
                    us.push(start.elapsed().as_nanos());
                }
            }
        }
        let (mut um, mut km) = (us.clone(), ks.clone());
        um.sort();
        km.sort();
        println!(
            "{}",
            serde_json::json!({"benchmark":format!("acl_check_world_{world_id}"),
            "seed":format!("0x{seed:x}"),"cases":queries.len(),"allowed_cases":allowed,
            "readonly":readonly,"rounds":rounds,"samples":11,"snapshot_now":now,
            "upstream_ns":us,"kernel_ns":ks,"kernel_over_upstream":km[5] as f64 / um[5] as f64,
            "scope":"upstream PgAclEngine with warm caches plus PostgreSQL round trips versus preloaded pure kernel snapshot; setup, representation conversion and snapshot loading excluded; expiration boundaries are one day away; not matched I/O, not a whole-application speedup"})
        );
    }
}
