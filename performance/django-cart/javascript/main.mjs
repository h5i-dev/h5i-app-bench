#!/usr/bin/env node
import fs from 'node:fs';
import {fileURLToPath} from 'node:url';
import {performance} from 'node:perf_hooks';
const WIDTH=67, MAX=99999999, INVALID=-1;
function total(rows, off) {
 const n=rows[off], kind=rows[off+65], value=rows[off+66];
 if(n>32 || kind>2 || value>MAX) return INVALID;
 let subtotal=0;
 for(let j=0;j<n;j++) {const p=rows[off+1+j],q=rows[off+33+j];if(p>MAX || q<1 || q>1000) return INVALID;subtotal+=p*q;}
 return finish(subtotal,kind,value);
}
function finish(subtotal,kind,value) {
 if(kind===2) return Math.max(subtotal-value,0);
 if(kind===0) return subtotal;
 // Exact cents without unsafe scaled subtotals (>2**53) or BigInt overhead.
 // Each product below is <= 3.2e12; the remainder product is < 1e8.
 const factor=10000-Math.min(value,10000);
 return Math.floor(subtotal/10000)*factor+Math.floor(((subtotal%10000)*factor+5000)/10000);
}
function calculate(rows) {
 const out=new Float64Array(rows.length/WIDTH);
 for(let i=0;i<out.length;i++) out[i]=total(rows,i*WIDTH);
 return out;
}
function fixture(n,lines) {
 const rows=new Float64Array(n*WIDTH), discounts=[0,1,1250,3333,9999,10000,15000];
 for(let i=0;i<n;i++) {const off=i*WIDTH;rows[off]=lines;for(let j=0;j<lines;j++) {rows[off+1+j]=(i*7919+j*104729)%100000;rows[off+33+j]=(i+j)%9+1;}rows[off+65]=i%3;rows[off+66]=i%3===1?discounts[i%7]:i%100000;}
 return rows;
}
function equal(a,b) {if(a.length!==b.length) throw Error('length mismatch');for(let i=0;i<a.length;i++) if(a[i]!==b[i]) throw Error(`total mismatch ${i}`);}
export {total, finish};
if(process.argv[1] === fileURLToPath(import.meta.url)) {
let sink;
if(process.argv[2]==='check') {
 const b=fs.readFileSync(0);if(b.length%(WIDTH*8)) throw Error('invalid input');
 const rows=new Float64Array(b.length/8);for(let i=0;i<rows.length;i++) rows[i]=Number(b.readBigUInt64LE(i*8));
 const out=calculate(rows), result=Buffer.alloc(out.length*8);
 for(let i=0;i<out.length;i++) result.writeBigUInt64LE(out[i]===INVALID?0xffffffffffffffffn:BigInt(out[i]),i*8);
 fs.writeFileSync(1,result);
} else {
 console.log('carts,lines,repeat,iterations,ms,checksum');
 for(const lines of [1,8,32]) for(const n of [1,16,256,4096,65536,262144,1048576]) {
  const rows=fixture(n,lines), expected=calculate(rows);
  for(let warm=0;warm<8;warm++) sink=calculate(rows);
  const iterations=n<4096?100:10;
  const checksum=expected.reduce((s,v)=>s+v,0);
  if(!Number.isSafeInteger(checksum)) throw Error("unsafe checksum");
  for(let rep=0;rep<3;rep++) {
   const start=performance.now();for(let k=0;k<iterations;k++) sink=calculate(rows);
   const ms=(performance.now()-start)/iterations;equal(sink,expected);
   console.log(`${n},${lines},${rep},${iterations},${ms.toFixed(9)},${checksum}`);
  }
 }
}

}
