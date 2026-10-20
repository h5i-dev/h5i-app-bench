import http from 'k6/http';
import {check} from 'k6';
import {SharedArray} from 'k6/data';
export const options={vus:Number(__ENV.CLIENTS||16),duration:__ENV.DURATION||'5s',thresholds:{http_req_failed:['rate==0'],checks:['rate==1']},summaryTrendStats:['avg','p(50)','p(90)','p(99)']};
const carts=Number(__ENV.CARTS),lines=Number(__ENV.LINES||32),base=__ENV.BASE_URL;
function calculateExpected(i) {
 let subtotal=0;for(let j=0;j<lines;j++) subtotal+=((i*7919+j*104729)%100000)*((i+j)%9+1);
 const kind=i%3, value=kind===1?[0,1,1250,3333,9999,10000,15000][i%7]:i%100000;
 if(kind===0)return subtotal;if(kind===2)return Math.max(0,subtotal-value);
 const factor=10000-Math.min(value,10000);return Math.floor(subtotal/10000)*factor+Math.floor(((subtotal%10000)*factor+5000)/10000);
}
// Precompute once per k6 process, shared by VUs. Large line counts must not
// turn the load generator's oracle into the throughput bottleneck.
const expected=new SharedArray('cart-totals',()=>Array.from({length:carts},(_,i)=>calculateExpected(i)));
export default function() {
 // Deterministic rotating IDs, same sequence for each implementation/point.
 const i=((__VU-1)*7919+__ITER*104729)%carts,id=i+1;
 const r=http.get(`${base}/carts/${id}/total`);
 check(r,{'status 200':r=>r.status===200,'exact id and cents':r=>{try{const j=r.json();return j.id===id&&j.total_cents===expected[i];}catch(_){return false;}}});
}
