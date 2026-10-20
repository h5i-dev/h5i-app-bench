// Exact integer cents in Float64Array; intermediates use quotient/remainder.
import fs from 'node:fs';
import path from 'node:path';
import {once} from 'node:events';
import {Worker,isMainThread,parentPort,workerData} from 'node:worker_threads';
function finish(s,k,v){if(k===1){v=Math.min(v,10000);const q=Math.floor(s/10000),r=s-q*10000;return q*(10000-v)+Math.floor((r*(10000-v)+5000)/10000);}return k===2?Math.max(0,s-v):s;}
function work(rows,sums,totals,cmd,out,n,cap,lo,hi){const w=2*cap+3,updates=(cmd.length/2-n)/4;for(let i=lo;i<hi;i++){const id=cmd[i*2],off=id*w;let sum=sums[id];for(let k=i;k<updates;k+=n){const p=2*(n+4*k),slot=cmd[p+2];sum-=rows[off+1+slot]*rows[off+1+cap+slot];sum+=cmd[p+4]*cmd[p+6];rows[off+1+slot]=cmd[p+4];rows[off+1+cap+slot]=cmd[p+6];}if(i<updates){sums[id]=sum;totals[id]=finish(sum,rows[off+w-2],rows[off+w-1]);}out[i]=totals[id];}}
if(!isMainThread){const d=workerData,rows=new Float64Array(d.rows),sums=new Float64Array(d.sums),totals=new Float64Array(d.totals),commands=new Uint32Array(d.commands),out=new Float64Array(d.out);parentPort.on('message',r=>{work(rows,sums,totals,commands.subarray(r*d.words*2,(r+1)*d.words*2),out,d.n,d.cap,d.lo,d.hi);parentPort.postMessage(r);});parentPort.postMessage('ready');}
else{
const [dir,name,rep]=process.argv.slice(2),m=JSON.parse(fs.readFileSync(path.join(dir,'manifest.json'))),n=m.carts,cap=m.lines,w=2*cap+3;
function read(file,shared=false){const fd=fs.openSync(path.join(dir,file),'r');try{const size=fs.fstatSync(fd).size,a=shared?new SharedArrayBuffer(size):new ArrayBuffer(size);for(let pos=0;pos<size;){const view=Buffer.from(a,pos,Math.min(16*1024*1024,size-pos));const count=fs.readSync(fd,view,0,view.length,pos);if(!count)throw Error('short fixture read');pos+=count;}return a;}finally{fs.closeSync(fd);}}
const base=read('base.bin'),commandsBuffer=read('commands.bin',true),commands=new Uint32Array(commandsBuffer),expected=new BigUint64Array(read('expected.bin'));
if(base.byteLength!==n*w*8||commands.length!==m.rounds*m.command_words*2||expected.length!==m.rounds*n)throw Error('bad fixture');
// Canonical u64 commands: use low u32 without per-read BigInt conversion; high words must be zero.
for(let i=1;i<commands.length;i+=2)if(commands[i]!==0)throw Error('command outside u32 domain');
for(let r=0;r<m.rounds;r++){const cmd=commands.subarray(r*m.command_words*2,(r+1)*m.command_words*2),seen=new Uint8Array(n);for(let i=0;i<n;i++){const id=cmd[i*2];if(id>=n||seen[id])throw Error('bad query');seen[id]=1;}for(let k=0;k<(m.command_words-n)/4;k++){const p=2*(n+k*4);if(cmd[p]!==cmd[(k%n)*2]||cmd[p+2]>=cap||cmd[p+4]>99999999||cmd[p+6]<1||cmd[p+6]>1000)throw Error('bad patch');}}
const start=performance.now(),rows=new Float64Array(new SharedArrayBuffer(base.byteLength)),baseWords=new Uint32Array(base);for(let i=0;i<rows.length;i++){if(baseWords[2*i+1]!==0)throw Error('base outside u32 domain');rows[i]=baseWords[i*2];}
const sums=new Float64Array(new SharedArrayBuffer(n*8)),totals=new Float64Array(new SharedArrayBuffer(n*8));for(let id=0;id<n;id++){const off=id*w;let s=0;for(let j=0;j<rows[off];j++)s+=rows[off+1+j]*rows[off+1+cap+j];sums[id]=s;totals[id]=finish(s,rows[off+w-2],rows[off+w-1]);}
const sharedOut=new Float64Array(new SharedArrayBuffer(n*8)),workers=[];if(name==='javascript-4'){for(let t=0;t<4;t++){const worker=new Worker(new URL(import.meta.url),{workerData:{rows:rows.buffer,sums:sums.buffer,totals:totals.buffer,commands:commandsBuffer,out:sharedOut.buffer,words:m.command_words,n,cap,lo:Math.floor(t*n/4),hi:Math.floor((t+1)*n/4)}});workers.push(worker);await once(worker,'message');}}
const init=performance.now()-start;
for(let r=0;r<m.rounds;r++){const cmd=commands.subarray(r*m.command_words*2,(r+1)*m.command_words*2),start=performance.now();let out;if(workers.length){await Promise.all(workers.map(worker=>(()=>{const done=once(worker,'message');worker.postMessage(r);return done;})()));out=new Float64Array(sharedOut);}else{out=new Float64Array(n);work(rows,sums,totals,cmd,out,n,cap,0,n);}const us=(performance.now()-start)*1000;let checksum=0n;for(let i=0;i<n;i++){if(!Number.isSafeInteger(out[i])||BigInt(out[i])!==expected[r*n+i])throw Error(`wrong result round=${r} i=${i}`);checksum+=BigInt(out[i]);}console.log(`${name},${rep},${r},${us.toFixed(6)},${init.toFixed(6)},${n},${BigInt.asUintN(64,checksum)}`);}
await Promise.all(workers.map(w=>w.terminate()));
}
