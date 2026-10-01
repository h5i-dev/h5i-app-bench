
// ---- Test seam (not upstream): build a modify list. ----

impl ModifyList<ModifyValid> {
    pub fn difftest_new(mods: Vec<Modify>) -> Self {
        ModifyList { valid: ModifyValid, mods }
    }
}
