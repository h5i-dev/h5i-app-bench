#!/usr/bin/env python3
"""Apply timing-only probes to disposable h5i / benchmark worktrees.

No extracted Rust, generated Lean, SQL, isolation settings or decision logic
is changed. Build both applications with the patched local crates (see README).
"""
import argparse
from pathlib import Path

p = argparse.ArgumentParser(description=__doc__)
p.add_argument('h5i', type=Path)
p.add_argument('bench', type=Path)
p.add_argument('--read-sql-modes', action='store_true', help='Linkding SQL-mode hook and per-read/count timers; needs the mode-enabled engine')
a = p.parse_args()
pg = a.h5i / 'crates/h5i-app-pg/src'

stages = 'http engine pool lock unlock begin clock load kernel write commit rollback backoff sql_compile sql_query pg_decode snapshot_decode read_plan sql_prepare'.split()
if a.read_sql_modes:
    if 'pub fn compile_read_with_mode' not in (a.h5i / 'crates/h5i-app-pgsql/src/read.rs').read_text():
        p.error('--read-sql-modes requires the mode-enabled engine sources')
    stages += ['count_query'] + [f'read_table_{i}' for i in range(8)]
module = '''//! Benchmark-only aggregate probes; not part of the extracted logic.
use std::{future::Future, sync::{OnceLock, atomic::{AtomicU64, Ordering}}, time::Instant};
static ENABLED: OnceLock<bool> = OnceLock::new();
const NAMES: &[&str] = &NAMES_PLACEHOLDER;
struct Stat { count: AtomicU64, ns: AtomicU64, units: AtomicU64 }
static STATS: [Stat; NAMES.len()] = [const { Stat { count: AtomicU64::new(0), ns: AtomicU64::new(0), units: AtomicU64::new(0) } }; NAMES.len()];
pub struct Timer(Option<(usize, Instant)>);
pub fn start(name: &str) -> Timer {
    Timer(if *ENABLED.get_or_init(|| std::env::var("H5I_ENGINE_PROFILE").as_deref() == Ok("1")) {
        Some((NAMES.iter().position(|n| *n == name).unwrap(), Instant::now()))
    } else { None })
}
impl Timer { pub fn units(&self, n: usize) { if let Some((i, _)) = self.0 { STATS[i].units.fetch_add(n as u64, Ordering::Relaxed); } } }
impl Drop for Timer { fn drop(&mut self) { if let Some((i, t)) = self.0 {
    STATS[i].ns.fetch_add(t.elapsed().as_nanos() as u64, Ordering::Relaxed);
    STATS[i].count.fetch_add(1, Ordering::Relaxed);
} } }
pub async fn measure<T>(name: &str, f: impl Future<Output=T>) -> T { let _t = start(name); f.await }
pub fn report() -> String {
    let mut out = String::from("stage,count,ns,units\\n");
    for (name, s) in NAMES.iter().zip(&STATS) { out.push_str(&format!("{},{},{},{}\\n", name, s.count.load(Ordering::Relaxed), s.ns.load(Ordering::Relaxed), s.units.load(Ordering::Relaxed))); }
    out
}
'''.replace('NAMES_PLACEHOLDER', '[' + ', '.join('"'+s+'"' for s in stages) + ']')
(pg / 'profile.rs').write_text(module)
f = pg / 'lib.rs'
s = f.read_text()
assert 'pub mod profile;' not in s
s = s.replace('pub mod migrate;', 'pub mod profile;\npub mod migrate;')
s = s.replace('        // With a key the reply is stored, which is a write.', '        let _engine_timer = profile::start("engine");\n        // With a key the reply is stored, which is a write.')
s = s.replace('self.pool.0.get().await', 'profile::measure("pool", self.pool.0.get()).await')
s = s.replace('self.lock(&client, tenant, &lock).await', 'profile::measure("lock", self.lock(&client, tenant, &lock)).await')
s = s.replace('self.unlock(&client, &lock).await', 'profile::measure("unlock", self.unlock(&client, &lock)).await')
s = s.replace('tokio::time::sleep(backoff(attempt)).await', 'profile::measure("backoff", tokio::time::sleep(backoff(attempt))).await')
s = s.replace('let tx = client\n            .build_transaction()', 'let begin_timer = profile::start("begin");\n        let tx = client\n            .build_transaction()')
s = s.replace('let tx = client.build_transaction().isolation_level(IsolationLevel::Serializable).start().await?;', 'let begin_timer = profile::start("begin");\n        let tx = client.build_transaction().isolation_level(IsolationLevel::Serializable).start().await?;')
s = s.replace('        let now = self.read_clock(&tx, tid).await?;', '        drop(begin_timer);\n        let now = profile::measure("clock", self.read_clock(&tx, tid)).await?;')
s = s.replace('S::load_for(&Tx(&tx, &self.pool.1), tenant, actor, cmd).await?', 'profile::measure("load", S::load_for(&Tx(&tx, &self.pool.1), tenant, actor, cmd)).await?')
s = s.replace('K::transition(&actor, &snap, cmd)', '{ let _t = profile::start("kernel"); K::transition(&actor, &snap, cmd) }')
s = s.replace('S::write(&Tx(&tx, &self.pool.1), tenant, &ws).await?', 'profile::measure("write", S::write(&Tx(&tx, &self.pool.1), tenant, &ws)).await?')
s = s.replace('tx.commit().await', 'profile::measure("commit", tx.commit()).await')
s = s.replace('tx.rollback().await', 'profile::measure("rollback", tx.rollback()).await')
f.write_text(s)
f = pg / 'table.rs'
s = f.read_text()
s = s.replace('let st = prepare(tx, sql).await?;', 'let st = crate::profile::measure("sql_prepare", prepare(tx, sql)).await?;')
s = s.replace('Ok(tx.0.query(&st, &refs(vals)).await?)', 'Ok(crate::profile::measure("sql_query", tx.0.query(&st, &refs(vals))).await?)')
s = s.replace('let (sql, vals, kinds) = compiled_read(schema, tenant, q, false)?;', 'let (sql, vals, kinds) = { let _t = crate::profile::start("sql_compile"); compiled_read(schema, tenant, q, false)? };')
s = s.replace('let (sql, vals, _) = compiled_read(schema, tenant, q, true)?;', 'let (sql, vals, _) = { let _t = crate::profile::start("sql_compile"); compiled_read(schema, tenant, q, true)? };')
# The mode-enabled engine passes the transaction into compiled_read.
for count, binding in [('false', 'kinds'), ('true', '_')]:
    old = f'let (sql, vals, {binding}) = compiled_read(tx, schema, tenant, q, {count})?;'
    new = f'let (sql, vals, {binding}) = {{ let _t = crate::profile::start("sql_compile"); compiled_read(tx, schema, tenant, q, {count})? }};'
    s = s.replace(old, new)
if a.read_sql_modes:
    s = s.replace('    let rows = query(tx, &sql, &vals).await?;', '    let stage = format!("read_table_{}", q.table);\n    let rows = crate::profile::measure(&stage, query(tx, &sql, &vals)).await?;')
    # load_table uses a Query, whose table id is the function parameter.
    start = s.index('pub async fn load_table(')
    end = s.index('pub async fn load_tables(', start)
    s = s[:start] + s[start:end].replace('q.table', 'table') + s[end:]
    start = s.index('pub async fn count_read(')
    s = s[:start] + s[start:].replace('    let stage = format!("read_table_{}", q.table);\n    let rows = crate::profile::measure(&stage, query(tx, &sql, &vals)).await?;', '    let rows = crate::profile::measure("count_query", query(tx, &sql, &vals)).await?;', 1)
s = s.replace('    rows.iter().map(|r| read_row(&kinds, r)).collect()', '    let timer = crate::profile::start("pg_decode");\n    timer.units(rows.len());\n    rows.iter().map(|r| read_row(&kinds, r)).collect()')
f.write_text(s)
f = a.h5i / 'crates/h5i-app-schema/src/lib.rs'
s = f.read_text().replace('            $krate::decode(&rows).ok_or_else', '            let _timer = ::h5i_app_pg::profile::start("snapshot_decode");\n            $krate::decode(&rows).ok_or_else')
f.write_text(s)
for app in ['linkding', 'realworld']:
    root = a.bench / 'performance' / app / 'rust-h5i'
    f = root / 'Cargo.toml'
    with f.open('a') as out:
        out.write('\n[patch."https://github.com/h5i-dev/h5i"]\n')
        for crate in ['h5i-app-core', 'h5i-app-pg', 'h5i-app-schema', 'h5i-app-sql', 'h5i-app-pgsql', 'h5i-app-http', 'h5i-app-json']:
            out.write(f'{crate} = {{ path = "{a.h5i / "crates" / crate}" }}\n')
    f = root / 'server/src/lib.rs'
    s = f.read_text().replace('    let listener = tokio::net::TcpListener', '    let router = router.route("/__engine_profile", axum::routing::get(|| async { h5i_app_pg::profile::report() }));\n    let listener = tokio::net::TcpListener')
    if a.read_sql_modes and app == 'linkding':
        anchor = '    let pool = h5i_app_pg::pool(&h5i_app_pg::with_schema(&url, "h5iapp")?, pool_size)?;'
        assert anchor in s
        hook = """
    match std::env::var("H5I_READ_SQL_MODE").as_deref() {
        Ok("scalar") => pool.set_read_sql_mode(h5i_app_pg::ReadSqlMode::ScalarWhenUnique),
        Ok("membership") | Err(_) => {},
        Ok(other) => panic!("invalid H5I_READ_SQL_MODE: {other}"),
    }
"""
        s = s.replace(anchor, anchor + hook)
    # Time application plan construction separately, retaining its evaluation order.
    count_fn = 'list_count' if app == 'linkding' else 'article_count'
    s = s.replace(f'        let count = k::{count_fn}', f'        let read_plan_timer = h5i_app_pg::profile::start("read_plan");\n        let count = k::{count_fn}')
    s = s.replace('        match (k::reads(actor, cmd), count) {', '        let plan = k::reads(actor, cmd);\n        drop(read_plan_timer);\n        match (plan, count) {')
    s = s.replace('    let listener = tokio::net::TcpListener', '    let router = router.layer(axum::middleware::from_fn(|req: axum::extract::Request, next: axum::middleware::Next| async move {\n        let _timer = req.uri().path().starts_with("/api/").then(|| h5i_app_pg::profile::start("http"));\n        next.run(req).await\n    }));\n    let listener = tokio::net::TcpListener')
    f.write_text(s)
print('Timing-only probes applied. Keep these worktrees disposable.')
