
// Test seam appended by extract_upstream.py: seed and read the private state.
impl AuthFailureTracker {
    pub fn seed(&self, ip: IpAddr, failures: u32, last_failure: Instant) {
        self.entries.lock().insert(ip, (failures, last_failure));
    }
    pub fn entries_now(&self) -> Vec<(IpAddr, u32, Instant)> {
        let mut v: Vec<_> = self.entries.lock().iter().map(|(ip, (n, t))| (*ip, *n, *t)).collect();
        v.sort_by_key(|e| e.0);
        v
    }
}
