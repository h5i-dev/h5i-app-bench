//! HTTP read API with bounded cross-request SQL coalescing, CPU/GPU ablation.
use axum::{extract::{Path, State}, http::StatusCode, response::{IntoResponse, Response}, routing::get, Json, Router};
use django_cart_gpu_nvvm::{Nvvm, WideResident};
use django_cart_pricing::{pricing::{finish,ERROR}, wide::{at, width}};
use serde_json::{json,Value};
use sqlx::{postgres::PgPoolOptions, Connection, PgConnection, PgPool, Row};
use std::{collections::HashMap, sync::{Arc,atomic::{AtomicU64,Ordering},mpsc}, time::{Duration,Instant}};
use tokio::sync::oneshot;
const RAW: &str = "SELECT c.id,c.discount_kind,c.discount_value,i.slot,i.price,i.quantity FROM cart_bench_cart c LEFT JOIN cart_bench_item i ON i.cart_id=c.id WHERE c.id=ANY($1::bigint[]) ORDER BY c.id,i.slot";
const AGGREGATE: &str = "SELECT c.id,c.discount_kind,c.discount_value,COALESCE(SUM(i.price*i.quantity),0)::bigint FROM cart_bench_cart c LEFT JOIN cart_bench_item i ON i.cart_id=c.id WHERE c.id=$1 GROUP BY c.id";
#[derive(Default)]
struct Metrics { requests:AtomicU64, batches:AtomicU64, sql:AtomicU64, rows:AtomicU64, kernels:AtomicU64, max:AtomicU64, wait:AtomicU64,fetch:AtomicU64,pack:AtomicU64,compute:AtomicU64 }
impl Metrics {
 fn json(&self)->Value {json!({"requests":self.requests.load(Ordering::Relaxed),"batches":self.batches.load(Ordering::Relaxed),"sql_queries":self.sql.load(Ordering::Relaxed),"cart_rows":self.rows.load(Ordering::Relaxed),"gpu_launches":self.kernels.load(Ordering::Relaxed),"max_batch":self.max.load(Ordering::Relaxed),"queue_wait_ns":self.wait.load(Ordering::Relaxed),"sql_fetch_ns":self.fetch.load(Ordering::Relaxed),"pack_ns":self.pack.load(Ordering::Relaxed),"compute_ns":self.compute.load(Ordering::Relaxed)})}
}
struct Request {id:i64, arrived:Instant, reply:oneshot::Sender<Result<Option<u64>,String>>}
#[derive(Clone)]
struct App { sql:bool, pool:PgPool, tx:mpsc::SyncSender<Request>, metrics:Arc<Metrics> }
fn number(key:&str, default:u64)->u64 { std::env::var(key).map(|v|v.parse().expect(key)).unwrap_or(default) }
async fn worker_query(conn:&mut PgConnection, ids:&[i64],cap:usize,stats:&Metrics)->Result<(Vec<i64>,Vec<u64>),sqlx::Error> {
 let width=width(cap);
 let began=Instant::now();
 let records=sqlx::query(RAW).bind(ids).fetch_all(conn).await?;
 stats.fetch.fetch_add(began.elapsed().as_nanos() as u64,Ordering::Relaxed);let began=Instant::now();
 let mut ids=Vec::new();let mut rows=Vec::new();
 for r in records {let id:i64=r.get(0);if ids.last()!=Some(&id) {ids.push(id);rows.resize(ids.len()*width,0);let off=(ids.len()-1)*width;rows[off+width-2]=r.get::<i32,_>(1) as u64;rows[off+width-1]=r.get::<i64,_>(2) as u64;}
  if let Some(slot)=r.get::<Option<i32>,_>(3) {if !(0..cap as i32).contains(&slot) {return Err(sqlx::Error::Protocol("invalid item slot".into()));}let off=(ids.len()-1)*width;let j=rows[off] as usize;if j>=cap{return Err(sqlx::Error::Protocol("too many lines".into()));}rows[off]+=1;rows[off+1+j]=r.get::<i64,_>(4) as u64;rows[off+1+cap+j]=r.get::<i32,_>(5) as u64;}
 }
 stats.pack.fetch_add(began.elapsed().as_nanos() as u64,Ordering::Relaxed);
 Ok((ids,rows))
}
async fn total(State(app):State<App>,Path(id):Path<String>)->Response {
 let Ok(id)=id.parse::<i64>() else {return StatusCode::BAD_REQUEST.into_response()};if id<1 {return StatusCode::BAD_REQUEST.into_response()}
 app.metrics.requests.fetch_add(1,Ordering::Relaxed);
 let result=if app.sql {
  app.metrics.batches.fetch_add(1,Ordering::Relaxed);app.metrics.sql.fetch_add(1,Ordering::Relaxed);app.metrics.max.store(1,Ordering::Relaxed);
  match sqlx::query(AGGREGATE).bind(id).fetch_optional(&app.pool).await {
   Ok(Some(r))=>{app.metrics.rows.fetch_add(1,Ordering::Relaxed);Ok(Some(finish(r.get::<i64,_>(3) as u64,r.get::<i32,_>(1) as u64,r.get::<i64,_>(2) as u64)))},Ok(None)=>Ok(None),Err(e)=>Err(e.to_string())}
 }else {
  let (reply,rx)=oneshot::channel();
  if app.tx.try_send(Request{id,arrived:Instant::now(),reply}).is_err(){return StatusCode::SERVICE_UNAVAILABLE.into_response()}
  rx.await.unwrap_or_else(|_|Err("worker closed".into()))
 };
 match result {Ok(Some(v))=>Json(json!({"id":id,"total_cents":v})).into_response(),Ok(None)=>StatusCode::NOT_FOUND.into_response(),Err(e)=>{eprintln!("total error: {e}");StatusCode::INTERNAL_SERVER_ERROR.into_response()}}
}
#[tokio::main(flavor="multi_thread", worker_threads=4)]
async fn main()->Result<(),Box<dyn std::error::Error>> {
 let url=std::env::var("DATABASE_URL")?;let mode=std::env::var("MODE").unwrap_or("batch".into());let max=number("BATCH_MAX",256) as usize;assert!((1..=4096).contains(&max));let delay=Duration::from_micros(number("BATCH_WAIT_US",1000));
 let cap=number("CART_LINES",32) as usize;assert!((1..=2048).contains(&cap));
 let pool=PgPoolOptions::new().max_connections(16).connect_lazy(&url)?;
 let metrics=Arc::new(Metrics::default());let (tx,rx)=mpsc::sync_channel::<Request>(4096);
 if mode!="sql" {
  let gpu=mode=="gpu"||mode=="gpu-cooperative";let cooperative=mode=="gpu-cooperative";let parallel=mode=="parallel";let stats=metrics.clone();let (ready_tx,ready_rx)=oneshot::channel();
  std::thread::spawn(move || {
   let runtime=tokio::runtime::Builder::new_current_thread().enable_all().build().unwrap();
   let mut conn=match runtime.block_on(PgConnection::connect(&url)){Ok(v)=>v,Err(e)=>{let _=ready_tx.send(Err(e.to_string()));return}};
   let nvvm=if gpu {match std::env::var("PTX").map_err(|e|e.to_string()).and_then(|p|std::fs::read_to_string(p).map_err(|e|e.to_string())).and_then(|p|Nvvm::new(&p).map_err(|e|e.to_string())){Ok(v)=>Some(v),Err(e)=>{let _=ready_tx.send(Err(e));return}}}else{None};
   let cpu_pool=rayon::ThreadPoolBuilder::new().num_threads(4).build().unwrap();
   let _=ready_tx.send(Ok(()));
   while let Ok(first)=rx.recv() {
    let deadline=first.arrived+delay;let mut batch=vec![first];
    while batch.len()<max {if let Ok(q)=rx.try_recv(){batch.push(q);continue;}let Some(wait)=deadline.checked_duration_since(Instant::now()) else{break};match rx.recv_timeout(wait){Ok(q)=>batch.push(q),Err(_)=>break}}
    let start=Instant::now();for q in &batch {stats.wait.fetch_add(start.duration_since(q.arrived).as_nanos() as u64,Ordering::Relaxed);}
    stats.batches.fetch_add(1,Ordering::Relaxed);stats.sql.fetch_add(1,Ordering::Relaxed);stats.max.fetch_max(batch.len() as u64,Ordering::Relaxed);
    let ids:Vec<_>=batch.iter().map(|q|q.id).collect();
    let result=runtime.block_on(worker_query(&mut conn,&ids,cap,&stats)).map_err(|e|e.to_string()).and_then(|(ids,rows)|{
     stats.rows.fetch_add(ids.len() as u64,Ordering::Relaxed);
     let began=Instant::now();
     let totals=if let Some(nvvm)=&nvvm {if !ids.is_empty(){stats.kernels.fetch_add(1,Ordering::Relaxed);}WideResident::upload(&rows,cap,cooperative).and_then(|r|r.run(nvvm)).map_err(|e|e.to_string())?}else{{use rayon::prelude::*;if parallel {cpu_pool.install(||rows.par_chunks_exact(width(cap)).map(|r|at(r,cap)).collect())}else{rows.chunks_exact(width(cap)).map(|r|at(r,cap)).collect()}}};
     stats.compute.fetch_add(began.elapsed().as_nanos() as u64,Ordering::Relaxed);
     if totals.contains(&ERROR){return Err("pricing rejected a database row".into())}
     Ok(ids.into_iter().zip(totals).collect::<HashMap<_,_>>())
    });
    for q in batch {let reply=match &result{Ok(values)=>Ok(values.get(&q.id).copied()),Err(e)=>Err(e.clone())};let _=q.reply.send(reply);}
   }
  });
  ready_rx.await??;
 }
 let app=App{sql:mode=="sql",pool,tx,metrics};
 let router=Router::new().route("/health",get(||async{"ok"})).route("/metrics",get(|State(app):State<App>|async move{Json(app.metrics.json())})).route("/carts/:id/total",get(total)).with_state(app);
 let listener=tokio::net::TcpListener::bind(format!("127.0.0.1:{}",number("PORT",8780))).await?;eprintln!("rust mode={mode} max={max} wait={delay:?}");axum::serve(listener,router).await?;Ok(())
}
