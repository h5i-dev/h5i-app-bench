//! CUDA objects stay on one worker thread. Buffers are reused for up to 128 policies.
use cust::prelude::*;
use h5i_app_gpu::batch::Output;
use h5i_app_gpu_backend_nvvm::{Failure, Nvvm};
pub struct Policy {
    nvvm: Nvvm,
    rows: DeviceBuffer<u64>,
    values: DeviceBuffer<u32>,
    errors: DeviceBuffer<u32>,
}
impl Policy {
    pub fn new(ptx: &str) -> Result<Self, Failure> {
        let nvvm = Nvvm::new(ptx)?;
        Ok(Self {
            nvvm,
            rows: DeviceBuffer::from_slice(&[0; 1024])?,
            values: DeviceBuffer::from_slice(&[0; 128])?,
            errors: DeviceBuffer::from_slice(&[0; 128])?,
        })
    }
    pub fn run(&mut self, rows: &[[u64; 8]]) -> Result<Vec<u32>, Failure> {
        if rows.len() > 128 {
            return Err("policy batch exceeds 128".into());
        }
        if rows.is_empty() {
            return Ok(vec![]);
        }
        let mut host = [0; 1024];
        for (i, row) in rows.iter().enumerate() {
            host[i * 8..(i + 1) * 8].copy_from_slice(row);
        }
        self.rows.copy_from(&host)?;
        let f = self.nvvm.module().get_function("conduit_policy")?;
        let stream = self.nvvm.stream();
        let n = rows.len();
        unsafe {
            cust::launch!(f<<<1,128,0,stream>>>(self.rows.as_device_ptr(),host.len(),
            self.values.as_device_ptr(),self.errors.as_device_ptr(),n))?;
        }
        stream.synchronize()?;
        let mut values = [0; 128];
        let mut errors = [0; 128];
        self.values.copy_to(&mut values)?;
        self.errors.copy_to(&mut errors)?;
        // Validate every slot before interpreting any application decision.
        let output = Output {
            values: values[..n].to_vec(),
            errors: errors[..n].to_vec(),
        };
        output.validate(n)?;
        if output
            .values
            .iter()
            .any(|v| conduit_gpu::decode(*v).is_none())
        {
            return Err("invalid GPU policy output".into());
        }
        Ok(output.values)
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    #[ignore = "requires NVIDIA GPU and CONDUIT_GPU_PTX"]
    fn device_matches_shared_predicate_at_batch_boundaries() {
        let ptx = std::fs::read_to_string(std::env::var("CONDUIT_GPU_PTX").unwrap()).unwrap();
        let mut gpu = Policy::new(&ptx).unwrap();
        for n in [0, 1, 127, 128] {
            let rows: Vec<_> = (0..n)
                .map(|i| {
                    [
                        (i % 8) as u64,
                        (i % 3) as u64,
                        ((i >> 1) & 1) as u64,
                        1,
                        ((i >> 2) & 1) as u64,
                        2,
                        ((i >> 3) & 1) as u64,
                        ((i >> 4) & 1) as u64,
                    ]
                })
                .collect();
            assert_eq!(
                gpu.run(&rows).unwrap(),
                rows.iter()
                    .map(|r| conduit_gpu::predicate::evaluate(r))
                    .collect::<Vec<_>>()
            );
        }
        assert!(gpu.run(&[[0; 8]; 129]).is_err());
        assert!(gpu.run(&[[8; 8]]).is_err());
    }
}

impl h5i_app_gpu::batch::Backend<[[u64; 8]], (), Vec<u32>> for Policy {
    type Error = Failure;
    fn run(&mut self, _: (), rows: &[[u64; 8]]) -> Result<Vec<u32>, Failure> {
        Policy::run(self, rows)
    }
}
