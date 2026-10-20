//! Changing resident update phase diagnostics; copied workload from resident_scale.rs.
use cust::prelude::*;
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

impl Gpu {
    fn profiled(&mut self,nvvm:&Nvvm,cmd:&[u64],n:usize,cap:usize,events:bool, marks:&[Event])->Result<(Vec<u64>,[f64;10]),Failure> {
        let start=Instant::now();
        self.commands.copy_from(cmd)?;
        let uploaded=Instant::now();
        let stream=nvvm.stream();let updates=(cmd.len()-n)/4;
        if events {marks[0].record(stream)?;}
        if self.delta {
            let f=nvvm.module().get_function("resident_delta")?;
            unsafe {cust::launch!(f<<<(n as u32).div_ceil(128),128,0,stream>>>(self.rows.as_device_ptr(),self.sums.as_device_ptr(),self.totals.as_device_ptr(),self.commands.as_device_ptr(),self.commands.len(),self.out.as_device_ptr(),n,updates,cap))?;}
            if events {marks[1].record(stream)?;}
        } else {
            if updates>0 {
                let f=nvvm.module().get_function("resident_apply")?;
                unsafe {cust::launch!(f<<<(updates as u32).div_ceil(128),128,0,stream>>>(self.rows.as_device_ptr(),self.commands.as_device_ptr(),self.commands.len(),n,updates,cap))?;}
            }
            if events {marks[1].record(stream)?;}
            let f=nvvm.module().get_function("resident_scan")?;
            unsafe {cust::launch!(f<<<n as u32,32,0,stream>>>(self.rows.as_device_ptr(),self.rows.len(),self.commands.as_device_ptr(),self.commands.len(),self.out.as_device_ptr(),n,cap))?;}
            if events {marks[2].record(stream)?;}
        }
        let enqueued=Instant::now();
        stream.synchronize()?;
        let synced=Instant::now();
        let mut out=vec![0;n];
        let allocated=Instant::now();
        self.out.copy_to(&mut out)?;
        let downloaded=Instant::now();
        if out.contains(&ERROR) {return Err("invalid resident GPU result".into());}
        let done=Instant::now();
        let us=|a:Instant,b:Instant|b.duration_since(a).as_secs_f64()*1e6;
        let device_a=if events {marks[1].elapsed_time_f32(&marks[0])? as f64*1000.} else {0.};
        let device_b=if events && !self.delta {marks[2].elapsed_time_f32(&marks[1])? as f64*1000.} else {0.};
        Ok((out,[us(start,done),us(start,uploaded),us(uploaded,enqueued),us(enqueued,synced),us(synced,allocated),us(allocated,downloaded),us(downloaded,done),device_a,device_b,0.]))
    }
}
fn main()->Result<(),Failure> {
    let args:Vec<String>=std::env::args().collect();
    let ptx=std::fs::read_to_string(args.get(1).expect("PTX path"))?;
    let nvvm=Nvvm::new(&ptx)?;let pool=rayon::ThreadPoolBuilder::new().num_threads(4).build()?;
    let oracle:serde_json::Value=serde_json::from_str(&std::fs::read_to_string(args.get(2).expect("Django oracle path"))?)?;
    let mut gates=serde_json::Map::new();
    for cap in [32,128,512,2048] {
        let cases=oracle[cap.to_string()]["cases"].as_array().unwrap();let n=cases.len();
        let mut rows=vec![0;n*width(cap)];let mut expected=Vec::new();
        for (i,case) in cases.iter().enumerate() {
            let prices=case["prices"].as_array().unwrap();let quantities=case["quantities"].as_array().unwrap();
            assert_eq!(prices.len(),quantities.len());assert!(prices.len()<=cap);
            let off=i*width(cap);rows[off]=prices.len() as u64;
            for j in 0..prices.len() {rows[off+1+j]=prices[j].as_u64().unwrap();rows[off+1+cap+j]=quantities[j].as_u64().unwrap();}
            rows[off+width(cap)-2]=case["kind"].as_u64().unwrap();rows[off+width(cap)-1]=case["value"].as_u64().unwrap();
            expected.push(case["total_cents"].as_u64().unwrap());
        }
        let commands:Vec<u64>=(0..n as u64).collect();
        for (delta,parallel) in [(false,false),(false,true),(true,false)] {
            assert_eq!(Cpu::new(&rows,cap,delta).run(&commands,n,cap,if parallel {Some(&pool)} else {None}),expected);
        }
        for parallel in [false,true] {assert_eq!(grouped(&mut Cpu::new(&rows,cap,true),&commands,n,cap,if parallel {Some(&pool)} else {None}),expected);}
        for delta in [false,true] {assert_eq!(Gpu::new(&rows,cap,n,0,delta)?.run(&nvvm,&commands,n,cap)?,expected);}
        gates.insert(cap.to_string(),serde_json::json!({"decimal_cases":n,"variants":7}));
    }
    std::fs::write(args.get(3).expect("conformance output path"),serde_json::to_string_pretty(&gates)?+"\n")?;

    println!("lines,carts,updates,repeat,variant,mode,round,warmup,checked_totals,command_bytes,result_bytes,checksum,total_us,upload_us,enqueue_us,sync_us,alloc_us,download_us,validate_us,device_update_or_fused_us,device_scan_us,timer_tail_us");
    let smoke=args.iter().any(|x|x=="--smoke");
    for (population,cap,factor) in if smoke {vec![(64,32,1),(64,32,16)]} else {vec![(4096,512,16),(65536,2048,1),(65536,2048,16),(65536,2048,64)]} {
        let n=population;let updates=n*factor;let base=initial(cap,n);
        let trace=trace(&base,cap,n,updates,n);
        for rep in 0..3 {
            let mut order=vec![("cpu-delta-4","plain"),("gpu-scan","plain"),("gpu-scan","host"),("gpu-scan","events"),("gpu-delta","plain"),("gpu-delta","host"),("gpu-delta","events")];
            order.rotate_left(rep*2);if rep%2==1 {order.reverse();}
            for (name,mode) in order {
                eprintln!("phase shape={n}x{cap} updates/cart={factor} rep={rep} {name}/{mode}");
                let marks:Vec<Event>=(0..3).map(|_|Event::new(EventFlags::DEFAULT)).collect::<Result<_,_>>()?;
                let mut cpu=if name.starts_with("cpu") {Some(Cpu::new(&base,cap,true))} else {None};
                let mut gpu=if name.starts_with("gpu") {Some(Gpu::new(&base,cap,n,updates,name=="gpu-delta")?)} else {None};
                for (i,step) in trace.iter().enumerate() {
                    let start=Instant::now();
                    let (out,mut phases)=if let Some(cpu)=&mut cpu {(grouped(cpu,&step.commands,n,cap,Some(&pool)),[0.;10])}
                        else if mode=="plain" {(gpu.as_mut().unwrap().run(&nvvm,&step.commands,n,cap)?,[0.;10])}
                        else {gpu.as_mut().unwrap().profiled(&nvvm,&step.commands,n,cap,mode=="events",&marks)?};
                    let elapsed=start.elapsed().as_secs_f64()*1e6;
                    if mode=="plain" {phases[0]=elapsed;} else {phases[9]=elapsed-phases[0];}
                    assert_eq!(out,step.expected,"{name}/{mode} cap={cap} n={n} round={i}");
                    let checksum=black_box(out).iter().sum::<u64>();
                    print!("{cap},{n},{updates},{rep},{name},{mode},{i},{},{n},{},{},{checksum}",i<WARMUP,(n+updates*4)*8,n*8);
                    for value in phases {print!(",{value:.6}");}println!();
                }
            }
        }
    }
    Ok(())
}
