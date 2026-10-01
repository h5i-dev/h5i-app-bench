
// ---- Test seam (not upstream): build a profile; name and uuid are labels. ----

impl AccessControlProfile {
    pub fn difftest_new(receiver: AccessControlReceiver, target: AccessControlTarget) -> Self {
        AccessControlProfile {
            name: String::new(),
            uuid: Uuid::nil(),
            receiver,
            target,
        }
    }
}
