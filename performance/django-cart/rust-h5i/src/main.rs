//! Actual h5i-app Engine/Store baseline and hand-written-SQL adapter.
//! Cart pricing has differential tests, no application-specific Lean proof.
use axum::{extract::{Path, State}, http::StatusCode, response::{IntoResponse, Response}, routing::get, Json, Router};
use django_cart_pricing::pricing::{finish, total};
use h5i_app_core::{Kernel, TenantId};
use h5i_app_pg::{DbError, Engine, EngineConfig, Store, Tx};
use h5i_app_sql::{Column, Val};
use serde_json::json;
use sqlx::Row;
use std::sync::Arc;

#[derive(Clone)]
struct Cart { kind: u64, value: u64 }
#[derive(Clone)]
struct Item { slot: u64, price: u64, quantity: u64 }
h5i_app_pg::table!(Pricing, Cart => "cart" {key: [], cols: [kind, value]});
h5i_app_pg::table!(Pricing, Item => "item" {key: [slot], cols: [price, quantity]});
#[derive(Clone, Default)]
struct Snapshot { cart: Option<Cart>, items: Vec<Item> }
struct Pricing;
impl Kernel for Pricing {
    // One cart is a complete tenant; load reads its complete state.
    type Principal = u64;
    type Snapshot = Snapshot;
    type Command = ();
    type WriteSet = ();
    type Reply = u64;
    type Error = ();
    fn tenant(id: &u64) -> TenantId { TenantId(*id) }
    fn transition(_: &u64, s: &Snapshot, _: &()) -> Result<((), u64), ()> {
        let c = s.cart.as_ref().ok_or(())?;
        let prices: Vec<_> = s.items.iter().map(|i| i.price).collect();
        let quantities: Vec<_> = s.items.iter().map(|i| i.quantity).collect();
        Ok(((), total(&prices, &quantities, c.kind, c.value)))
    }
    fn apply(s: &Snapshot, _: &()) -> Snapshot { s.clone() }
    // Keep the default transaction path; no unproved read_only/load_for overrides.
}
fn schema() -> Vec<h5i_app_pg::pgsql::Table> {
    vec![h5i_app_pg::spec::<Pricing, Cart>(), h5i_app_pg::spec::<Pricing, Item>()]
}
fn integer(v: &Val) -> Result<u64, DbError> {
    u64::from_val(v).ok_or_else(|| DbError::Decode("expected integer".into()))
}
struct CartStore;
impl Store<Pricing> for CartStore {
    fn ddl() -> Vec<String> { h5i_app_pg::create_tables(&schema()).expect("cart schema") }
    fn tables() -> Vec<&'static str> { vec!["cart", "item"] }
    async fn load(tx: &Tx<'_>, tenant: TenantId) -> Result<Snapshot, DbError> {
        let rows = h5i_app_pg::load_tables(tx, tenant, &schema(), &[0, 1]).await?;
        let cart = rows[0].first().map(|r| Ok::<_, DbError>(Cart {kind: integer(&r[0])?, value: integer(&r[1])?})).transpose()?;
        let items = rows[1].iter().map(|r| Ok(Item {slot: integer(&r[0])?, price: integer(&r[1])?, quantity: integer(&r[2])?})).collect::<Result<_, DbError>>()?;
        Ok(Snapshot {cart, items})
    }
    async fn write(_: &Tx<'_>, _: TenantId, _: &()) -> Result<(), DbError> { Ok(()) }
}
#[derive(Clone)]
enum App { Engine(Arc<Engine<Pricing, CartStore>>), Sql(sqlx::PgPool) }
async fn handler(State(app): State<App>, Path(id): Path<String>) -> Response {
    let Ok(id) = id.parse::<i64>() else { return StatusCode::BAD_REQUEST.into_response() };
    if id < 1 { return StatusCode::BAD_REQUEST.into_response() }
    let result: Result<Option<u64>, String> = match app {
        App::Engine(e) => e.execute(&(id as u64), &()).await.map(|r| r.ok()).map_err(|e| e.to_string()),
        App::Sql(pool) => sqlx::query("SELECT c.discount_kind,c.discount_value,COALESCE(SUM(i.price*i.quantity),0)::bigint FROM cart_bench_cart c LEFT JOIN cart_bench_item i ON i.cart_id=c.id WHERE c.id=$1 GROUP BY c.id")
            .bind(id).fetch_optional(&pool).await
            .map(|r| r.map(|r| finish(r.get::<i64,_>(2) as u64, r.get::<i32,_>(0) as u64, r.get::<i64,_>(1) as u64))).map_err(|e| e.to_string()),
    };
    match result {
        Ok(Some(v)) if v != u64::MAX => Json(json!({"id":id,"total_cents":v})).into_response(),
        Ok(None) => StatusCode::NOT_FOUND.into_response(),
        _ => StatusCode::INTERNAL_SERVER_ERROR.into_response(),
    }
}
#[tokio::main(worker_threads = 4)]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let url = std::env::var("DATABASE_URL")?;
    let app = if std::env::var("MODE").as_deref() == Ok("sql") {
        App::Sql(sqlx::postgres::PgPoolOptions::new().max_connections(32).connect(&url).await?)
    } else {
        let pool = h5i_app_pg::pool(&h5i_app_pg::with_schema(&url, "cart_engine")?, 32)?;
        let e = Arc::new(Engine::<Pricing, CartStore>::new(pool, EngineConfig::default()));
        e.install_schema().await?;
        App::Engine(e)
    };
    let router = Router::new().route("/health", get(|| async {"ok"})).route("/metrics", get(|| async {Json(json!({}))})).route("/carts/{id}/total", get(handler)).with_state(app);
    let listener = tokio::net::TcpListener::bind(format!("127.0.0.1:{}", std::env::var("PORT")?)).await?;
    axum::serve(listener, router).await?;
    Ok(())
}
