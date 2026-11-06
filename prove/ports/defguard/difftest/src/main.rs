//! Usage: defguard-difftest [--seed N] [--steps N]
fn main() {
    let args: Vec<String> = std::env::args().collect();
    let get = |flag: &str, default: u64| {
        args.iter().position(|a| a == flag).and_then(|i| args.get(i + 1)).map(|v| v.parse().unwrap()).unwrap_or(default)
    };
    let seed = get("--seed", 1);
    let steps = get("--steps", 100_000) as usize;
    let (n, blocked) = defguard_difftest::diff::lockout(seed, steps);
    println!("lockout seed {seed}: {n} operations agree ({blocked} refused)");
    let n = defguard_difftest::diff::tokens(seed, steps);
    println!("tokens seed {seed}: {n} cases agree");
    let (exact, by_set, overlapping) = defguard_difftest::diff::ranges(seed, steps / 10);
    println!("merge_ranges seed {seed}: {exact} exact, {by_set} equal as sets (range ending at 65535); upstream output overlapping in {overlapping}");
}
