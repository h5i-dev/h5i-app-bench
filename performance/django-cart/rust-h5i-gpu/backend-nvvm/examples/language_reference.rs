//! Compact commands and reusable pinned staging, with encoding inside timing.
use cust::prelude::*;
use cust::memory::{LockedBuffer, AsyncCopyDestination};
use django_cart_gpu_nvvm::{Failure, Nvvm};
use django_cart_pricing::{pricing::{finish, ERROR}, wide::{at, width}};
use rayon::prelude::*;
use std::{hint::black_box, time::Instant};

const WARMUP:usize=8;
const ITERATIONS:usize=50;

fn initial(cap:usize,population:usize)->Vec<u64> {
    let w=width(cap); let mut rows=vec![0;population*w];
    for i in 0..population {
        let off=i*w; rows[off]=cap as u64;
        for j in 0..cap {
            rows[off+1+j]=((i*7919+j*104729)%100000) as u64;
            rows[off+1+cap+j]=((i+j)%9+1) as u64;
        }
        rows[off+w-2]=(i%3) as u64;
        rows[off+w-1]=if i%3==1 {[0,1,1250,3333,9999,10000,15000][i%7]} else {(i%100000) as u64};
    }
    rows
}
fn subtotals(rows:&[u64],cap:usize)->Vec<u64> {
    rows.chunks_exact(width(cap)).map(|r|(0..r[0] as usize).map(|j|r[1+j]*r[1+cap+j]).sum()).collect()
}
fn totals(rows:&[u64],sums:&[u64],cap:usize)->Vec<u64> {
    rows.chunks_exact(width(cap)).zip(sums).map(|(r,&s)|finish(s,r[width(cap)-2],r[width(cap)-1])).collect()
}
fn apply(rows:&mut [u64],cmd:&[u64],queries:usize,cap:usize) {
    for p in cmd[queries..].chunks_exact(4) {
        let off=p[0] as usize*width(cap);let slot=p[1] as usize;
        rows[off+1+slot]=p[2];rows[off+1+cap+slot]=p[3];
    }
}
struct Step {commands:Vec<u64>,expected:Vec<u64>}
fn trace(base:&[u64],cap:usize,n:usize,updates:usize,population:usize)->Vec<Step> {
    assert!(cap.is_power_of_two() && updates.div_ceil(n)<=cap);
    let mut rows=base.to_vec();
    (0..WARMUP+ITERATIONS).map(|round| {
        let mut commands:Vec<u64>=(0..n).map(|j|(((round*n+j)*7919)%population) as u64).collect();
        let mut seen=vec![false;population];
        for &id in &commands {assert!(!seen[id as usize]);seen[id as usize]=true;}
        for k in 0..updates {
            let cart=commands[k%n];let slot=(round*17+k/n*13)%cap;
            // Periodic bound values exercise updates, rounding and stale caches.
            let price=if (round+k)%31==0 {99_999_999} else {((round*997+k*7919+7)%100000) as u64};
            let qty=if (round+k)%37==0 {1000} else {((round+k)%9+1) as u64};
            commands.extend([cart,slot as u64,price,qty]);
        }
        apply(&mut rows,&commands,n,cap);
        let expected=commands[..n].iter().map(|&i|at(&rows[i as usize*width(cap)..(i as usize+1)*width(cap)],cap)).collect();
        Step{commands,expected}
    }).collect()
}
struct Cpu {rows:Vec<u64>,sums:Vec<u64>,totals:Vec<u64>,delta:bool}
impl Cpu {
    fn new(base:&[u64],cap:usize,delta:bool)->Self {
        let rows=base.to_vec();let sums=if delta {subtotals(&rows,cap)} else {vec![]};
        let totals=if delta {totals(&rows,&sums,cap)} else {vec![]};
        Self{rows,sums,totals,delta}
    }
    fn run(&mut self,cmd:&[u64],n:usize,cap:usize,pool:Option<&rayon::ThreadPool>)->Vec<u64> {
        let cmd=black_box(cmd);
        if self.delta {
            for p in cmd[n..].chunks_exact(4) {
                let cart=p[0] as usize;let off=cart*width(cap);let slot=p[1] as usize;
                self.sums[cart]-=self.rows[off+1+slot]*self.rows[off+1+cap+slot];
                self.sums[cart]+=p[2]*p[3];
                self.rows[off+1+slot]=p[2];self.rows[off+1+cap+slot]=p[3];
            }
            for &i in &cmd[..n.min((cmd.len()-n)/4)] {
                let i=i as usize;let off=i*width(cap);
                self.totals[i]=finish(self.sums[i],self.rows[off+width(cap)-2],self.rows[off+width(cap)-1]);
            }
            cmd[..n].iter().map(|&i|self.totals[i as usize]).collect()
        } else {
            apply(&mut self.rows,cmd,n,cap);
            let total=|&i:&u64|at(&self.rows[i as usize*width(cap)..(i as usize+1)*width(cap)],cap);
            if let Some(pool)=pool {pool.install(||cmd[..n].par_iter().map(total).collect())}
            else {cmd[..n].iter().map(total).collect()}
        }
    }
}
// Queries are distinct, and every patch belongs to commands[k % n].
// Each worker therefore owns all mutations of a cart and its caches. No two
// calls touch the same row/sum/total; base Vecs stay allocated until join.
#[derive(Clone, Copy)]
struct DeltaPointers { rows:usize, sums:usize, totals:usize }
impl DeltaPointers {
    fn cart(&self,cmd:&[u64],n:usize,i:usize,cap:usize)->u64 {
        let cart=cmd[i] as usize; let off=cart*width(cap);let updates=(cmd.len()-n)/4;
        unsafe {
            let rows=self.rows as *mut u64;let sums=self.sums as *mut u64;let totals=self.totals as *mut u64;
            let mut sum=*sums.add(cart);let mut k=i;
            while k<updates {
                let p=n+4*k;let slot=cmd[p+1] as usize;
                sum-=*rows.add(off+1+slot) * *rows.add(off+1+cap+slot);
                sum+=cmd[p+2]*cmd[p+3];
                *rows.add(off+1+slot)=cmd[p+2];*rows.add(off+1+cap+slot)=cmd[p+3];k+=n;
            }
            if i<updates {
                *sums.add(cart)=sum;
                *totals.add(cart)=finish(sum,*rows.add(off+width(cap)-2),*rows.add(off+width(cap)-1));
            }
            *totals.add(cart)
        }
    }
}
fn grouped(cpu:&mut Cpu,cmd:&[u64],n:usize,cap:usize,pool:Option<&rayon::ThreadPool>)->Vec<u64> {
    let pointers=DeltaPointers{rows:cpu.rows.as_mut_ptr() as usize,sums:cpu.sums.as_mut_ptr() as usize,totals:cpu.totals.as_mut_ptr() as usize};
    let cmd=black_box(cmd);let mut out=vec![0;n];
    if let Some(pool)=pool {pool.install(||out.par_iter_mut().enumerate().for_each(|(i,v)|*v=pointers.cart(cmd,n,i,cap)));}
    else {for (i,v) in out.iter_mut().enumerate() {*v=pointers.cart(cmd,n,i,cap);}}
    out
}
struct Gpu {rows:DeviceBuffer<u64>,sums:DeviceBuffer<u64>,totals:DeviceBuffer<u64>,commands:DeviceBuffer<u64>,out:DeviceBuffer<u64>,delta:bool}
impl Gpu {
    fn new(base:&[u64],cap:usize,n:usize,updates:usize,delta:bool)->Result<Self,Failure> {
        let sums=if delta {subtotals(base,cap)} else {vec![0]};
        let totals=if delta {totals(base,&sums,cap)} else {vec![0]};
        Ok(Self{rows:DeviceBuffer::from_slice(base)?,sums:DeviceBuffer::from_slice(&sums)?,totals:DeviceBuffer::from_slice(&totals)?,commands:DeviceBuffer::from_slice(&vec![0;n+updates*4])?,out:DeviceBuffer::from_slice(&vec![0;n])?,delta})
    }
    fn run(&mut self,nvvm:&Nvvm,cmd:&[u64],n:usize,cap:usize)->Result<Vec<u64>,Failure> {
        self.commands.copy_from(cmd)?;
        let stream=nvvm.stream();let updates=(cmd.len()-n)/4;
        if self.delta {
            let f=nvvm.module().get_function("resident_delta")?;
            unsafe {cust::launch!(f<<<(n as u32).div_ceil(128),128,0,stream>>>(self.rows.as_device_ptr(),self.sums.as_device_ptr(),self.totals.as_device_ptr(),self.commands.as_device_ptr(),self.commands.len(),self.out.as_device_ptr(),n,updates,cap))?;}
        } else {
            if updates>0 {
                let f=nvvm.module().get_function("resident_apply")?;
                unsafe {cust::launch!(f<<<(updates as u32).div_ceil(128),128,0,stream>>>(self.rows.as_device_ptr(),self.commands.as_device_ptr(),self.commands.len(),n,updates,cap))?;}
            }
            let f=nvvm.module().get_function("resident_scan")?;
            unsafe {cust::launch!(f<<<n as u32,32,0,stream>>>(self.rows.as_device_ptr(),self.rows.len(),self.commands.as_device_ptr(),self.commands.len(),self.out.as_device_ptr(),n,cap))?;}
        }
        stream.synchronize()?;let mut out=vec![0;n];self.out.copy_to(&mut out)?;
        if out.contains(&ERROR) {return Err("invalid resident GPU result".into());} Ok(out)
    }
}

// Assumes the same already-validated round-robin, distinct-slot trace as CPU4.
// Packing and staging below remain inside the timed call.
fn pack(cmd:&[u64],n:usize,out:&mut [u64]) {
    out[..n].copy_from_slice(&cmd[..n]);
    for (p,dst) in cmd[n..].chunks_exact(4).zip(&mut out[n..]) {
        *dst=p[1] | (p[2]<<11) | (p[3]<<38);
    }
}
fn pack_parallel(cmd:&[u64],n:usize,out:&mut [u64],pool:&rayon::ThreadPool) {
    out[..n].copy_from_slice(&cmd[..n]);
    pool.install(||out[n..].par_iter_mut().enumerate().for_each(|(k,dst)| {
        let p=n+4*k;*dst=cmd[p+1] | (cmd[p+2]<<11) | (cmd[p+3]<<38);
    }));
}
fn validate_trace(cmd:&[u64],n:usize,cap:usize) {
    assert_eq!((cmd.len()-n)%4,0);
    for (k,p) in cmd[n..].chunks_exact(4).enumerate() {
        assert_eq!(p[0],cmd[k%n]);assert!(p[1]<cap as u64 && p[1]<2048);
        assert!(p[2]<=99_999_999 && (1..=1000).contains(&p[3]));
        let bits=p[1] | (p[2]<<11) | (p[3]<<38);
        assert_eq!([bits&2047,(bits>>11)&134217727,(bits>>38)&1023],[p[1],p[2],p[3]]);
    }
}
struct Transport {
    gpu:Gpu,compact:bool,pinned:bool,page:Vec<u64>,
    locked_in:Option<LockedBuffer<u64>>,locked_out:Option<LockedBuffer<u64>>,
}
impl Transport {
    fn new(base:&[u64],cap:usize,n:usize,updates:usize,delta:bool,compact:bool,pinned:bool)->Result<Self,Failure> {
        let len=n+updates*if compact {1}else{4};
        let sums=if delta {subtotals(base,cap)}else{vec![0]};
        let totals=if delta {totals(base,&sums,cap)}else{vec![0]};
        let gpu=Gpu{rows:DeviceBuffer::from_slice(base)?,sums:DeviceBuffer::from_slice(&sums)?,
            totals:DeviceBuffer::from_slice(&totals)?,commands:DeviceBuffer::from_slice(&vec![0;len])?,
            out:DeviceBuffer::from_slice(&vec![0;n])?,delta};
        Ok(Self{gpu,compact,pinned,page:if pinned {vec![]}else{vec![0;len]},
            locked_in:if pinned {Some(LockedBuffer::new(&0,len)?)}else{None},
            locked_out:if pinned {Some(LockedBuffer::new(&0,n)?)}else{None}})
    }
    fn run(&mut self,nvvm:&Nvvm,cmd:&[u64],n:usize,cap:usize,events:bool,marks:&[Event],pool:Option<&rayon::ThreadPool>)->Result<(Vec<u64>,[f64;6]),Failure> {
        let start=Instant::now();
        let staging:&mut [u64]=if self.pinned {self.locked_in.as_mut().unwrap()}else{&mut self.page};
        if self.compact {if let Some(pool)=pool {pack_parallel(cmd,n,staging,pool);}else{pack(cmd,n,staging);}}else{staging.copy_from_slice(cmd);}
        let prepared=Instant::now();
        let stream=nvvm.stream();let updates=(cmd.len()-n)/4;
        // Always join even on submission failure, before buffers can be dropped.
        let submitted=(||->Result<(),Failure> {
            if events {marks[0].record(stream)?;}
            if self.pinned {
                // Staging allocations stay alive and immutable until the join below.
                unsafe {self.gpu.commands.async_copy_from(&self.locked_in.as_ref().unwrap()[..],stream)?;}
            } else {self.gpu.commands.copy_from(&self.page)?;}
            if events {marks[1].record(stream)?;}
            if self.gpu.delta {
                let f=nvvm.module().get_function(if self.compact {"compact_delta"}else{"resident_delta"})?;
                unsafe {cust::launch!(f<<<(n as u32).div_ceil(128),128,0,stream>>>(self.gpu.rows.as_device_ptr(),self.gpu.sums.as_device_ptr(),self.gpu.totals.as_device_ptr(),self.gpu.commands.as_device_ptr(),self.gpu.commands.len(),self.gpu.out.as_device_ptr(),n,updates,cap))?;}
            } else {
                if updates>0 {
                    let f=nvvm.module().get_function(if self.compact {"compact_apply"}else{"resident_apply"})?;
                    unsafe {cust::launch!(f<<<(updates as u32).div_ceil(128),128,0,stream>>>(self.gpu.rows.as_device_ptr(),self.gpu.commands.as_device_ptr(),self.gpu.commands.len(),n,updates,cap))?;}
                }
                let f=nvvm.module().get_function(if self.compact {"compact_scan"}else{"resident_scan"})?;
                unsafe {cust::launch!(f<<<n as u32,32,0,stream>>>(self.gpu.rows.as_device_ptr(),self.gpu.rows.len(),self.gpu.commands.as_device_ptr(),self.gpu.commands.len(),self.gpu.out.as_device_ptr(),n,cap))?;}
            }
            if events {marks[2].record(stream)?;}
            if self.pinned {
                unsafe {self.gpu.out.async_copy_to(&mut self.locked_out.as_mut().unwrap()[..],stream)?;}
                if events {marks[3].record(stream)?;}
            }
            Ok(())
        })();
        let joined=stream.synchronize();submitted?;joined?;
        let out=if self.pinned {self.locked_out.as_ref().unwrap().to_vec()} else {
            let mut out=vec![0;n];self.gpu.out.copy_to(&mut out)?;out
        };
        if out.contains(&ERROR) {return Err("invalid transport GPU result".into());}
        let done=Instant::now();
        // For pageable HtoD, upload interval also contains any device idle time
        // waiting for the synchronous driver call; it is not a DMA-only timer.
        let elapsed=|i:usize,j:usize|->Result<f64,Failure>{Ok(marks[j].elapsed_time_f32(&marks[i])? as f64*1000.)};
        let metrics=[done.duration_since(start).as_secs_f64()*1e6,prepared.duration_since(start).as_secs_f64()*1e6,
            if events {elapsed(0,1)?}else{0.},if events {elapsed(1,2)?}else{0.},
            if events && self.pinned {elapsed(2,3)?}else{0.},0.];
        Ok((out,metrics))
    }
}
fn read_words(path:std::path::PathBuf)->Vec<u64>{let bytes=std::fs::read(path).unwrap();assert_eq!(bytes.len()%8,0);bytes.chunks_exact(8).map(|b|u64::from_le_bytes(b.try_into().unwrap())).collect()}
fn main()->Result<(),Failure>{let args:Vec<String>=std::env::args().collect();let dir=std::path::Path::new(&args[1]);let name=&args[2];let rep:usize=args[3].parse()?;
 let meta:serde_json::Value=serde_json::from_str(&std::fs::read_to_string(dir.join("manifest.json"))?)?;let n=meta["carts"].as_u64().unwrap() as usize;let cap=meta["lines"].as_u64().unwrap() as usize;let rounds=meta["rounds"].as_u64().unwrap() as usize;let words=meta["command_words"].as_u64().unwrap() as usize;
 let base=read_words(dir.join("base.bin"));let commands=read_words(dir.join("commands.bin"));let expected=read_words(dir.join("expected.bin"));assert_eq!(commands.len(),words*rounds);assert_eq!(expected.len(),n*rounds);
 for cmd in commands.chunks_exact(words){validate_trace(cmd,n,cap);}
 let pool=rayon::ThreadPoolBuilder::new().num_threads(4).build()?;let ptx=std::fs::read_to_string(&args[4])?;let nvvm=Nvvm::new(&ptx)?;
 let start=Instant::now();let mut cpu=if name.starts_with("rust"){Some(Cpu::new(&base,cap,true))}else{None};let mut transport=if name.contains("compact"){Some(Transport::new(&base,cap,n,(words-n)/4,name.contains("delta"),true,true)?)}else{None};let mut gpu=if name.starts_with("gpu")&&!name.contains("compact"){Some(Gpu::new(&base,cap,n,(words-n)/4,name.contains("delta"))?)}else{None};let init=start.elapsed().as_secs_f64()*1000.;
 for r in 0..rounds{let cmd=&commands[r*words..(r+1)*words];let start=Instant::now();let out=if let Some(c)=&mut cpu{grouped(c,cmd,n,cap,if name=="rust-4"{Some(&pool)}else{None})}else if let Some(t)=&mut transport{t.run(&nvvm,cmd,n,cap,false,&[],Some(&pool))?.0}else{gpu.as_mut().unwrap().run(&nvvm,cmd,n,cap)?};let us=start.elapsed().as_secs_f64()*1e6;
 assert_eq!(out,&expected[r*n..(r+1)*n],"{name} round={r}");let checksum=out.iter().fold(0u64,|a,&b|a.wrapping_add(b));println!("{name},{rep},{r},{us:.6},{init:.6},{n},{checksum}");}Ok(())}
