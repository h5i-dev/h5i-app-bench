//! Bounded asynchronous bridge; CUDA context/stream/buffers live on one thread.
use conduit_kernel::{Command, Error, Reply, View};
use std::sync::{
    Arc,
    atomic::{AtomicU64, Ordering},
    mpsc,
};
use tokio::sync::oneshot;
type Request = ([u64; 8], oneshot::Sender<Option<u32>>);
#[derive(Clone)]
pub struct Dispatcher {
    queue: mpsc::SyncSender<Request>,
    fallbacks: Arc<AtomicU64>,
}
impl Dispatcher {
    pub fn start() -> Result<Self, std::io::Error> {
        let path = std::env::var("CONDUIT_GPU_PTX").map_err(std::io::Error::other)?;
        let ptx = std::fs::read_to_string(path)?;
        let (queue, rx) = mpsc::sync_channel::<Request>(128);
        let (ready_tx, ready_rx) = mpsc::sync_channel(1);
        std::thread::Builder::new()
            .name("conduit-gpu".into())
            .spawn(move || {
                let mut gpu = match conduit_gpu_nvvm::Policy::new(&ptx) {
                    Ok(gpu) => {
                        let _ = ready_tx.send(Ok(()));
                        gpu
                    }
                    Err(e) => {
                        let _ = ready_tx.send(Err(e.to_string()));
                        return;
                    }
                };
                let mut launched = false;
                while let Ok(first) = rx.recv() {
                    let mut batch = vec![first];
                    // Coalesce already queued requests, without an artificial batching delay.
                    while batch.len() < 128 {
                        match rx.try_recv() {
                            Ok(next) => batch.push(next),
                            Err(_) => break,
                        }
                    }
                    let rows: Vec<_> = batch.iter().map(|(row, _)| *row).collect();
                    match gpu.run(&rows) {
                        Ok(values) => {
                            if !launched {
                                eprintln!("conduit GPU policy: first successful device batch");
                                launched = true;
                            }
                            for ((_, reply), value) in batch.into_iter().zip(values) {
                                let _ = reply.send(Some(value));
                            }
                        }
                        Err(e) => {
                            eprintln!("conduit GPU policy device failure: {e}");
                            for (_, reply) in batch {
                                let _ = reply.send(None);
                            }
                        }
                    }
                }
            })?;
        ready_rx
            .recv()
            .map_err(std::io::Error::other)?
            .map_err(std::io::Error::other)?;
        eprintln!("conduit GPU policy ready: queue=128, batch<=128, reusable device buffers");
        Ok(Self {
            queue,
            fallbacks: Arc::new(AtomicU64::new(0)),
        })
    }
    pub async fn run(&self, view: &View, cmd: &Command) -> Option<Result<Reply, Error>> {
        let row = conduit_gpu::pack(view, cmd)?;
        let (tx, rx) = oneshot::channel();
        let result = if self.queue.try_send((row, tx)).is_ok() {
            rx.await.ok().flatten().and_then(conduit_gpu::decode)
        } else {
            None
        };
        if result.is_none() {
            let n = self.fallbacks.fetch_add(1, Ordering::Relaxed) + 1;
            if n.is_power_of_two() {
                eprintln!("conduit GPU policy CPU fallback count={n}");
            }
        }
        result
    }
}
