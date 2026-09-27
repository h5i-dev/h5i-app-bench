use cratesio_server::{parse_teams, router, CratesAuth, CratesStore, Cratesio};
use i5h_pg::{pool, Engine, EngineConfig};
use std::collections::HashMap;
use std::sync::Arc;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt().with_env_filter(tracing_subscriber::EnvFilter::from_default_env()).init();
    let secret = std::env::var("I5H_SECRET")?;
    let addr = std::env::var("LISTEN").unwrap_or_else(|_| "127.0.0.1:8080".into());
    // I5H_TEAMS=2:7,8 says user 2 is in GitHub teams 7 and 8.
    let teams = parse_teams(&std::env::var("I5H_TEAMS").unwrap_or_default())?;
    // I5H_DOWNLOADS=10:2500 says crate 10 has 2500 downloads.
    let downloads = parse_teams(&std::env::var("I5H_DOWNLOADS").unwrap_or_default())?
        .into_iter()
        .map(|(k, v)| (k, v.first().copied().unwrap_or(0)))
        .collect::<HashMap<_, _>>();
    let registry = std::env::var("I5H_REGISTRY").map(|r| r.parse()).unwrap_or(Ok(1))?;
    let auth = Arc::new(CratesAuth::new(&secret, registry, teams));

    if let Ok(spec) = std::env::var("I5H_ISSUE") {
        // I5H_ISSUE=github:<user> prints what the OAuth callback would hand
        // over for that user; I5H_ISSUE=operator prints an operator token.
        match spec.split_once(':') {
            Some(("github", user)) => println!("{}", auth.github_login(user.parse()?)),
            _ if spec == "operator" => println!("{}", auth.operator()),
            _ => return Err("I5H_ISSUE=github:<user> or I5H_ISSUE=operator".into()),
        }
        return Ok(());
    }

    let url = std::env::var("DATABASE_URL")?;
    let engine = Arc::new(Engine::<Cratesio, CratesStore>::new(pool(&url, 8)?, EngineConfig::default()));
    engine.install_schema().await?;
    let app = router(engine, auth, Arc::new(downloads)).route("/healthz", axum::routing::get(|| async { "ok" }));

    let listener = tokio::net::TcpListener::bind(&addr).await?;
    tracing::info!(%addr, "listening");
    axum::serve(listener, app).await?;
    Ok(())
}
