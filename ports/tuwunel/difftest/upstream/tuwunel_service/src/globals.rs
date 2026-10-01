pub struct Service {
    pub count: u64,
}

impl Service {
    pub fn current_count(&self) -> u64 {
        self.count
    }
}
