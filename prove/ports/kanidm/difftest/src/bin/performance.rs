//! Paired access-control computation; input representation conversion is outside timing.
use kanidm_difftest::generate::*;
use kanidm_kernel::access;
use kanidmd_lib::server::access::AccessControlsTransaction;
use std::hint::black_box;
use std::time::Instant;

fn measure<T>(rounds: usize, cases: usize, mut run: impl FnMut(usize) -> T) -> u128 {
    let start = Instant::now();
    for _ in 0..rounds {
        for i in 0..cases {
            black_box(run(i));
        }
    }
    start.elapsed().as_nanos()
}

fn main() {
    let rounds: usize = std::env::args()
        .nth(1)
        .unwrap_or("100".into())
        .parse()
        .unwrap();
    let mut rng = Rng(0x6b61_6e69_646d_0011);
    let cases: Vec<_> = (0..128)
        .map(|_| {
            let ctl = acls(&mut rng);
            let who = identity(&mut rng);
            let filter = filter(&mut rng, 3);
            let entries: Vec<_> = ENTRIES
                .iter()
                .take(4)
                .map(|&id| entry(&mut rng, id, false))
                .collect();
            (ctl, who, filter, entries)
        })
        .collect();
    let upstream: Vec<_> = cases
        .iter()
        .map(|(c, i, f, e)| {
            (
                controls(c),
                ident(i),
                filt(f),
                e.iter().map(sealed).collect::<Vec<_>>(),
            )
        })
        .collect();
    let mut nonempty = 0;
    for ((c, i, f, e), (uc, ui, uf, ue)) in cases.iter().zip(&upstream) {
        let k = access::filter_entries(c, i, f, e).unwrap();
        let u = uc.filter_entries(ui, uf, ue.clone()).unwrap();
        assert_eq!(
            k.iter().map(|e| e.uuid).collect::<Vec<_>>(),
            u.iter().map(|e| e.get_uuid().as_u128()).collect::<Vec<_>>()
        );
        nonempty += usize::from(!k.is_empty());
    }
    let k = |j: usize| {
        let (c, i, f, e) = &cases[j];
        access::filter_entries(c, i, f, e)
    };
    let u = |j: usize| {
        let (c, i, f, e) = &upstream[j];
        c.filter_entries(i, f, e.clone())
    };
    black_box(measure(1, cases.len(), k));
    black_box(measure(1, cases.len(), u));
    let (mut ks, mut us) = (Vec::new(), Vec::new());
    for sample in 0..11 {
        if sample % 2 == 0 {
            us.push(measure(rounds, cases.len(), u));
            ks.push(measure(rounds, cases.len(), k));
        } else {
            ks.push(measure(rounds, cases.len(), k));
            us.push(measure(rounds, cases.len(), u));
        }
    }
    let mut ratios: Vec<_> = ks.iter().zip(&us).map(|(k, u)| *k as f64 / *u as f64).collect();
    ratios.sort_by(f64::total_cmp);
    println!(
        "{}",
        serde_json::json!({"benchmark":"filter_entries", "cases":cases.len(),
        "nonempty_cases":nonempty,"seed":"0x6b616e69646d0011","rounds":rounds,"samples":11,
        "entries_per_case":4,"scope":"copied pinned upstream access module with test identity/entry adapters; representation conversion excluded; upstream input Vec<Arc<Entry>> clone included as required by its consuming API; not a server benchmark",
        "upstream_ns":us,"kernel_ns":ks,"kernel_over_upstream":ratios[5]})
    );
}
