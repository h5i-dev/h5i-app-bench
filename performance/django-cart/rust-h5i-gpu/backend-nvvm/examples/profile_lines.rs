//! Placement diagnostics for the HTTP kernels; no SQL or HTTP is timed here.
use cust::prelude::*;
use django_cart_gpu_nvvm::{Failure, Nvvm, WideResident};
use django_cart_pricing::{pricing::ERROR, wide::{at, width}};
use rayon::prelude::*;
use std::{hint::black_box, time::Instant};

fn layout(rows: &[u64], cap: usize, cooperative: bool) -> Vec<u64> {
    if cooperative { return rows.to_vec(); }
    let n = rows.len()/width(cap);
    let mut packed = vec![0; rows.len()];
    for base in (0..n).step_by(128) {
        for col in 0..width(cap) {
            for i in base..(base+128).min(n) { packed[col*n+i] = rows[i*width(cap)+col]; }
        }
    }
    packed
}
struct Buffers { input: DeviceBuffer<u64>, output: DeviceBuffer<u64>, n: usize, cap: usize, cooperative: bool }
impl Buffers {
    fn new(rows: &[u64], cap: usize, cooperative: bool) -> Result<Self, Failure> {
        let n = rows.len()/width(cap);
        Ok(Self { input: DeviceBuffer::from_slice(&layout(rows,cap,cooperative))?,
            output: DeviceBuffer::from_slice(&vec![0;n])?, n, cap, cooperative })
    }
    fn upload(&mut self, rows: &[u64]) -> Result<(), Failure> {
        if self.cooperative { self.input.copy_from(rows)?; }
        else { self.input.copy_from(&layout(rows,self.cap,false))?; }
        Ok(())
    }
    fn launch(&self, nvvm: &Nvvm) -> Result<(), Failure> {
        let f = nvvm.module().get_function(if self.cooperative {"cart_wide_cooperative"} else {"cart_wide_soa"})?;
        let stream = nvvm.stream();
        let blocks = if self.cooperative {self.n as u32} else {(self.n as u32).div_ceil(128)};
        let threads = if self.cooperative {32} else {128};
        unsafe { cust::launch!(f<<<blocks,threads,0,stream>>>(self.input.as_device_ptr(),self.input.len(),self.output.as_device_ptr(),self.n,self.cap))?; }
        Ok(())
    }
    fn run(&self, nvvm: &Nvvm) -> Result<Vec<u64>, Failure> {
        self.launch(nvvm)?; nvvm.stream().synchronize()?;
        let mut result = vec![0;self.n]; self.output.copy_to(&mut result)?;
        if result.contains(&ERROR) { return Err("invalid device result".into()); }
        Ok(result)
    }
    fn event_interval(&self, nvvm: &Nvvm, iterations: usize) -> Result<f64, Failure> {
        let start = Event::new(EventFlags::DEFAULT)?;
        let end = Event::new(EventFlags::DEFAULT)?;
        let mut total = 0.;
        for _ in 0..iterations {
            start.record(nvvm.stream())?; self.launch(nvvm)?; end.record(nvvm.stream())?;
            end.synchronize()?; total += end.elapsed_time_f32(&start)? as f64;
        }
        Ok(total/iterations as f64)
    }
}
fn timed(mut f: impl FnMut()->Vec<u64>, iterations: usize, expected: &[u64]) -> f64 {
    let start = Instant::now(); let mut last = Vec::new();
    for _ in 0..iterations { last = black_box(f()); }
    let ms = start.elapsed().as_secs_f64()*1000./iterations as f64;
    assert_eq!(last,expected); ms
}
fn main() -> Result<(), Failure> {
    let ptx = std::fs::read_to_string(std::env::args().nth(1).expect("PTX path"))?;
    let nvvm = Nvvm::new(&ptx)?;
    let pool = rayon::ThreadPoolBuilder::new().num_threads(4).build()?;
    let iterations = 100;
    println!("lines,carts,layout,repeat,iterations,input_bytes,cpu1_ms,cpu4_ms,resident_ms,reuse_upload_ms,fresh_ms,device_event_ms,checksum");
    for cap in [32,128,512,2048] {
        for n in [8,128,256] {
            let mut rows = vec![0;n*width(cap)];
            for i in 0..n {
                let off = i*width(cap); rows[off] = cap as u64;
                for j in 0..cap {
                    rows[off+1+j] = ((i*7919+j*104729)%100000) as u64;
                    rows[off+1+cap+j] = ((i+j)%9+1) as u64;
                }
                rows[off+width(cap)-2] = (i%3) as u64;
                rows[off+width(cap)-1] = if i%3==1 {[0,1,1250,3333,9999,10000,15000][i%7]} else {(i%100000) as u64};
            }
            let cpu = || black_box(&rows).chunks_exact(width(cap)).map(|r|at(r,cap)).collect::<Vec<_>>();
            let parallel = || pool.install(||black_box(&rows).par_chunks_exact(width(cap)).map(|r|at(r,cap)).collect::<Vec<_>>());
            let expected = cpu(); let checksum:u64 = expected.iter().sum();
            for cooperative in [false,true] {
                let resident = WideResident::upload(&rows,cap,cooperative)?;
                let mut reuse = Buffers::new(&rows,cap,cooperative)?;
                for _ in 0..8 {
                    black_box(cpu());black_box(parallel());
                    assert_eq!(resident.run(&nvvm)?,expected);
                    reuse.upload(&rows)?;assert_eq!(reuse.run(&nvvm)?,expected);
                    assert_eq!(WideResident::upload(&rows,cap,cooperative)?.run(&nvvm)?,expected);
                }
                for rep in 0..3 {
                    let c1 = timed(cpu,iterations,&expected);
                    let c4 = timed(parallel,iterations,&expected);
                    let gpu = timed(||resident.run(&nvvm).unwrap(),iterations,&expected);
                    let upload = timed(||{reuse.upload(&rows).unwrap();reuse.run(&nvvm).unwrap()},iterations,&expected);
                    let fresh = timed(||WideResident::upload(&rows,cap,cooperative).unwrap().run(&nvvm).unwrap(),iterations,&expected);
                    let event = reuse.event_interval(&nvvm,iterations)?;
                    assert_eq!(reuse.run(&nvvm)?,expected);
                    println!("{cap},{n},{},{rep},{iterations},{},{c1:.9},{c4:.9},{gpu:.9},{upload:.9},{fresh:.9},{event:.9},{checksum}",if cooperative {"cooperative"} else {"scalar"},rows.len()*8);
                }
            }
        }
    }
    Ok(())
}
