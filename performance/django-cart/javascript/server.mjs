import http from 'node:http';
import postgres from 'postgres';
import {performance} from 'node:perf_hooks';
import {total,finish} from './main.mjs';
const sql=postgres(process.env.DATABASE_URL,{max:16,prepare:true});
const mode=process.env.MODE||'batch',limit=Number(process.env.BATCH_MAX||256),delay=Number(process.env.BATCH_WAIT_US||1000)/1000;
if(!Number.isInteger(limit)||limit<1||delay<0) throw Error('invalid batch configuration');
const stats={requests:0,batches:0,sql_queries:0,cart_rows:0,gpu_launches:0,max_batch:0,queue_wait_ns:0};
const pending=[];let timer=null,busy=false;
const reply=(res,code,id,value)=>{res.writeHead(code,{'content-type':'application/json'});res.end(code===200?JSON.stringify({id,total_cents:value}):'{}');};
function schedule() {
 if(busy || !pending.length) return;
 if(timer) {clearTimeout(timer);timer=null;}
 if(pending.length>=limit || delay===0) {void flush();return;}
 const remaining=delay-(performance.now()-pending[0].arrived);
 // Node timers have a 1 ms floor, recorded as part of end-to-end latency.
 if(remaining<=0) void flush(); else timer=setTimeout(()=>{timer=null;void flush();},remaining);
}
async function flush() {
 if(busy||!pending.length) return;busy=true;
 const batch=pending.splice(0,limit),start=performance.now();
 stats.batches++;stats.sql_queries++;stats.max_batch=Math.max(stats.max_batch,batch.length);
 for(const q of batch) stats.queue_wait_ns+=Math.round((start-q.arrived)*1e6);
 try {
  const ids=batch.map(q=>q.id);
  const rows=await sql`SELECT c.id,c.discount_kind,c.discount_value,i.slot,i.price,i.quantity FROM cart_bench_cart c LEFT JOIN cart_bench_item i ON i.cart_id=c.id WHERE c.id=ANY(${'{'+ids.join(',')+'}'}::bigint[]) ORDER BY c.id,i.slot`;
  const packed=new Map();
  for(const row of rows) {const id=Number(row.id);let r=packed.get(id);if(!r) {r=new Float64Array(67);r[65]=row.discount_kind;r[66]=Number(row.discount_value);packed.set(id,r);}if(row.slot!==null){if(row.slot<0||row.slot>=32) throw Error('bad slot');const j=r[0]++;r[1+j]=Number(row.price);r[33+j]=row.quantity;}}
  stats.cart_rows+=packed.size;
  for(const q of batch) {const r=packed.get(q.id);if(!r) reply(q.res,404,q.id);else {const v=total(r,0);reply(q.res,v<0?500:200,q.id,v);}}
 } catch(e) {console.error(e);for(const q of batch) reply(q.res,500,q.id);}
 finally {busy=false;schedule();}
}
http.createServer(async(req,res)=>{
 if(req.url==='/health') {res.end('ok');return;}
 if(req.url==='/metrics') {res.setHeader('content-type','application/json');res.end(JSON.stringify(stats));return;}
 if(req.method!=='GET') {reply(res,405,0);return;}
 const match=/^\/carts\/([^/]+)\/total$/.exec(req.url);
 if(!match) {reply(res,404,0);return;}
 const id=Number(match[1]);if(!/^[0-9]+$/.test(match[1])||!Number.isSafeInteger(id)||id<1) {reply(res,400,0);return;}
 stats.requests++;
 if(mode==='sql') {
  stats.batches++;stats.sql_queries++;stats.max_batch=1;
  try {const rows=await sql`SELECT c.id,c.discount_kind,c.discount_value,COALESCE(SUM(i.price*i.quantity),0)::bigint AS subtotal FROM cart_bench_cart c LEFT JOIN cart_bench_item i ON i.cart_id=c.id WHERE c.id=${id} GROUP BY c.id`;
   if(!rows.length) reply(res,404,id);else {const r=rows[0];stats.cart_rows++;reply(res,200,id,finish(Number(r.subtotal),r.discount_kind,Number(r.discount_value)));}
  }catch(e){console.error(e);reply(res,500,id);}
 } else if(pending.length>=4096) reply(res,503,id);else {pending.push({id,res,arrived:performance.now()});schedule();}
}).listen(Number(process.env.PORT||8780),'127.0.0.1',()=>console.error(`node mode=${mode} batch=${limit} wait_ms=${delay}`));
