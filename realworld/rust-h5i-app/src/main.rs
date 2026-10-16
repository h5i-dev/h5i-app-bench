//! The cookbook's Conduit server, configured by the environment: `PORT`,
//! `DATABASE_URL`, `JWT_SECRET`, `DB_POOL` and `WEB_CONCURRENCY` (tokio
//! worker threads). See `conduit_server::serve_from_env`.

fn main() -> Result<(), Box<dyn std::error::Error>> {
    conduit_server::main_from_env()
}
