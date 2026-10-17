//! Resident linkding launch built on the h5i framework's NVVM shell.
//!
//! `Nvvm` (the trusted launch/ABI shell, its CUDA context, module and stream)
//! comes from `h5i-app-gpu-backend-nvvm` in the h5i repo. This crate adds only
//! the linkding-specific part: upload the packed bookmark columns to the device
//! once, then launch the `linkding_batch` kernel for each query against those
//! resident buffers. Built only on a CUDA host; never in CI.
use cust::{
    event::{Event, EventFlags},
    prelude::*,
};
use h5i_app_gpu::batch::Output;
// Re-exported so the server can name `linkding_gpu_nvvm::Nvvm` alongside the
// linkding-specific `ResidentLinkding`/`upload_linkding`/`linkding` below.
pub use h5i_app_gpu_backend_nvvm::{Failure, Nvvm};
use linkding_gpu::pack::{Query, Rows};
use std::time::Instant;

/// Bookmark columns uploaded once and reused across queries.
pub struct ResidentLinkding {
    fields: DeviceBuffer<u8>,
    lengths: DeviceBuffer<u32>,
    tags: DeviceBuffer<u64>,
    meta: DeviceBuffer<u32>,
    values: DeviceBuffer<u32>,
    errors: DeviceBuffer<u32>,
    n: usize,
}

pub fn upload_linkding(_nvvm: &Nvvm, r: &Rows) -> Result<ResidentLinkding, Failure> {
    let n = r.len();
    if n > 1_000_001 {
        return Err("output arena exceeds probe capacity".into());
    }
    Ok(ResidentLinkding {
        fields: DeviceBuffer::from_slice(&r.fields)?,
        lengths: DeviceBuffer::from_slice(&r.lengths)?,
        tags: DeviceBuffer::from_slice(&r.tags)?,
        meta: DeviceBuffer::from_slice(&r.meta)?,
        values: DeviceBuffer::from_slice(&vec![0; n])?,
        errors: DeviceBuffer::from_slice(&vec![0; n])?,
        n,
    })
}

pub fn linkding(nvvm: &mut Nvvm, r: &ResidentLinkding, q: &Query) -> Result<Output, Failure> {
    let start = Instant::now();
    if r.n == 0 {
        return Ok(Output {
            values: vec![],
            errors: vec![],
        });
    }
    let nodes = DeviceBuffer::from_slice(if q.nodes.is_empty() { &[0] } else { &q.nodes })?;
    let text = DeviceBuffer::from_slice(if q.text.is_empty() { &[0] } else { &q.text })?;
    let begin = Event::new(EventFlags::DEFAULT)?;
    let end = Event::new(EventFlags::DEFAULT)?;
    let f = nvvm.module().get_function("linkding_batch")?;
    let stream = nvvm.stream();
    begin.record(stream)?;
    unsafe {
        cust::launch!(f<<<(r.n as u32).div_ceil(128),128,0,stream>>>(r.fields.as_device_ptr(),r.fields.len(),r.lengths.as_device_ptr(),r.lengths.len(),r.tags.as_device_ptr(),r.tags.len(),r.meta.as_device_ptr(),r.meta.len(),nodes.as_device_ptr(),q.nodes.len(),text.as_device_ptr(),q.text.len(),q.root,q.flags,r.values.as_device_ptr(),r.errors.as_device_ptr(),r.n))?;
    }
    end.record(stream)?;
    end.synchronize()?;
    nvvm.kernel_ms = end.elapsed_time_f32(&begin)?;
    let mut out = Output {
        values: vec![0; r.n],
        errors: vec![0; r.n],
    };
    r.values.copy_to(&mut out.values)?;
    r.errors.copy_to(&mut out.errors)?;
    nvvm.total_ms = start.elapsed().as_secs_f64() * 1000.;
    Ok(out)
}
