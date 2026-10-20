use django_cart_gpu_nvvm::{Failure, Nvvm, Resident};
use django_cart_pricing::{WIDTH, at, fixture};
use rayon::prelude::*;
use std::{hint::black_box, time::Instant};
fn cpu(rows: &[u64]) -> Vec<u64> {
    rows.chunks_exact(WIDTH).map(at).collect()
}
fn timed(mut f: impl FnMut() -> Vec<u64>, iterations: usize) -> (f64, Vec<u64>) {
    let start = Instant::now();
    let mut last = vec![];
    for _ in 0..iterations {
        last = black_box(f());
    }
    (
        start.elapsed().as_secs_f64() * 1000. / iterations as f64,
        last,
    )
}
fn main() -> Result<(), Failure> {
    let args: Vec<_> = std::env::args().collect();
    let ptx = std::fs::read_to_string(args.get(1).expect("PTX path"))?;
    let transposed = std::env::var("CART_LAYOUT").unwrap_or_default() == "soa";
    eprintln!("GPU transposed layout: {transposed}");
    let upload = |rows: &[u64]| Resident::upload_layout(rows, transposed);
    let nvvm = Nvvm::new(&ptx)?;
    let pool = rayon::ThreadPoolBuilder::new().num_threads(16).build()?;
    // The same Python-generated upstream fixture corpus can be checked on device.
    if let Some(path) = args.get(2) {
        let bytes = std::fs::read(path)?;
        if bytes.len() % (WIDTH * 8) != 0 {
            return Err("truncated oracle fixtures".into());
        }
        let rows: Vec<_> = bytes
            .chunks_exact(8)
            .map(|b| u64::from_le_bytes(b.try_into().unwrap()))
            .collect();
        assert_eq!(upload(&rows)?.run_raw(&nvvm)?, cpu(&rows));
        eprintln!(
            "upstream fixture corpus: CPU/GPU match ({} rows)",
            rows.len() / WIDTH
        );
    }
    for n in [0, 1, 127, 128, 129, 257] {
        let rows: Vec<_> = (0..n).flat_map(|i| fixture(i, i % 33)).collect();
        assert_eq!(upload(&rows)?.run(&nvvm)?, cpu(&rows));
    }
    let mut bad = fixture(0, 1);
    bad[0] = 33;
    assert!(upload(&bad)?.run(&nvvm).is_err());
    assert!(upload(&[0; WIDTH - 1]).is_err());
    eprintln!("GPU batch boundaries and rejection checks passed");
    println!("carts,lines,repeat,iterations,upload_ms,cpu1_ms,cpu16_ms,resident_ms,upload_each_ms,checksum");
    for lines in [1, 8, 32] {
        for n in [1, 16, 256, 4096, 65536, 262144, 1048576] {
            let rows: Vec<_> = (0..n).flat_map(|i| fixture(i, lines)).collect();
            let expected = cpu(&rows);
            let checksum: u64 = expected.iter().sum();
            let start = Instant::now();
            let resident = upload(&rows)?;
            let initial_upload = start.elapsed().as_secs_f64() * 1000.;
            assert_eq!(resident.run(&nvvm)?, expected);
            for _ in 0..8 {
                black_box(cpu(&rows));
                black_box(pool.install(|| rows.par_chunks_exact(WIDTH).map(at).collect::<Vec<_>>()));
                black_box(resident.run(&nvvm)?);
            }
            let iterations = if n < 4096 { 100 } else { 10 };
            for rep in 0..3 {
                let (c1, out) = timed(|| cpu(&rows), iterations);
                assert_eq!(out, expected);
                // Persistent workers. Scheduling, result allocation and collection
                // are included, just as launch and result download are for GPU.
                let (c16, out) = timed(
                    || pool.install(|| rows.par_chunks_exact(WIDTH).map(at).collect()),
                    iterations,
                );
                assert_eq!(out, expected);
                let (gpu, out) = timed(|| resident.run(&nvvm).unwrap(), iterations);
                assert_eq!(out, expected);
                let (each, out) = timed(
                    || upload(&rows).unwrap().run(&nvvm).unwrap(),
                    iterations,
                );
                assert_eq!(out, expected);
                println!(
                    "{n},{lines},{rep},{iterations},{initial_upload:.6},{c1:.6},{c16:.6},{gpu:.6},{each:.6},{checksum}"
                );
            }
        }
    }
    Ok(())
}
