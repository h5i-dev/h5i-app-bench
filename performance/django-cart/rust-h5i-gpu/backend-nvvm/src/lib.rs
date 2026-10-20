use cust::prelude::*;
use django_cart_pricing::{WIDTH, pricing::ERROR};
pub use h5i_app_gpu_backend_nvvm::{Failure, Nvvm};

/// Variable-capacity HTTP snapshots; allocations, transpose and copies are timed.
pub struct WideResident { rows:DeviceBuffer<u64>,out:DeviceBuffer<u64>,n:usize,cap:usize,cooperative:bool }
impl WideResident {
    pub fn upload(rows:&[u64],cap:usize,cooperative:bool)->Result<Self,Failure> {
        if !(1..=2048).contains(&cap) {return Err("invalid line cap".into());}
        let width=2*cap+3;
        if rows.len()%width!=0 {return Err("invalid wide snapshot".into());}
        let n=rows.len()/width;
        let mut packed=Vec::new();
        if !cooperative && n>0 {
            packed.resize(rows.len(),0);
            for base in (0..n).step_by(128) {for col in 0..width {for i in base..(base+128).min(n) {packed[col*n+i]=rows[i*width+col];}}}
        }
        let input=if !cooperative && n>0 {&packed[..]}else{rows};
        Ok(Self{rows:DeviceBuffer::from_slice(if input.is_empty(){&[0]}else{input})?,out:DeviceBuffer::from_slice(&vec![0;n.max(1)])?,n,cap,cooperative})
    }
    pub fn run(&self,nvvm:&Nvvm)->Result<Vec<u64>,Failure> {
        if self.n==0 {return Ok(vec![]);}
        let f=nvvm.module().get_function(if self.cooperative {"cart_wide_cooperative"}else{"cart_wide_soa"})?;
        let stream=nvvm.stream();
        let blocks=if self.cooperative {self.n as u32}else{(self.n as u32).div_ceil(128)};
        let threads=if self.cooperative {32}else{128};
        unsafe {cust::launch!(f<<<blocks,threads,0,stream>>>(self.rows.as_device_ptr(),self.rows.len(),self.out.as_device_ptr(),self.n,self.cap))?;}
        stream.synchronize()?;
        let mut out=vec![0;self.n];self.out.copy_to(&mut out)?;
        if out.contains(&ERROR) {return Err("GPU rejected a wide cart".into());}
        Ok(out)
    }
}

/// Context/module/stream are provided by h5i. This benchmark owns the snapshots.
pub struct Resident {
    rows: DeviceBuffer<u64>,
    out: DeviceBuffer<u64>,
    n: usize,
    transposed: bool,
}
impl Resident {
    pub fn upload(rows: &[u64]) -> Result<Self, Failure> {
        Self::upload_layout(rows, false)
    }
    pub fn upload_layout(rows: &[u64], transposed: bool) -> Result<Self, Failure> {
        if rows.len() % WIDTH != 0 || rows.len() / WIDTH > 1_048_576 {
            return Err("invalid or oversized batch".into());
        }
        let n = rows.len() / WIDTH;
        // Blocked host transpose is part of upload-each wall time.
        let mut packed = Vec::new();
        if transposed && n > 0 {
            packed.resize(rows.len(), 0);
            for base in (0..n).step_by(128) {
                for col in 0..WIDTH {
                    for i in base..(base + 128).min(n) {
                        packed[col * n + i] = rows[i * WIDTH + col];
                    }
                }
            }
        }
        let input = if transposed && n > 0 { &packed[..] } else { rows };
        Ok(Self {
            rows: DeviceBuffer::from_slice(if input.is_empty() { &[0] } else { input })?,
            out: DeviceBuffer::from_slice(&vec![0; n.max(1)])?,
            n,
            transposed,
        })
    }
    /// Synchronous wall time includes launch, wait and full result download.
    pub fn run_raw(&self, nvvm: &Nvvm) -> Result<Vec<u64>, Failure> {
        if self.n == 0 {
            return Ok(vec![]);
        }
        let f = nvvm.module().get_function(if self.transposed { "cart_batch_soa" } else { "cart_batch" })?;
        let stream = nvvm.stream();
        unsafe {
            cust::launch!(f<<<(self.n as u32).div_ceil(128),128,0,stream>>>(
                self.rows.as_device_ptr(),self.rows.len(),self.out.as_device_ptr(),self.n))?;
        }
        stream.synchronize()?;
        let mut out = vec![0; self.n];
        self.out.copy_to(&mut out)?;
        Ok(out)
    }
    pub fn run(&self, nvvm: &Nvvm) -> Result<Vec<u64>, Failure> {
        let out = self.run_raw(nvvm)?;
        if out.contains(&ERROR) {
            return Err("GPU rejected a cart snapshot".into());
        }
        Ok(out)
    }
}
