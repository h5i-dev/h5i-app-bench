#[path="../../../kernel/src/closed_records.rs"]
mod kernel;
#[test]
fn signing_config_default_942b3541_complete() {let r=kernel::signing_config_default_942b3541::make();
assert_eq!(r.enabled,true);
assert_eq!(r.key_path,&[]);
}
#[test]
fn env_provider_new_23e18cff_complete() {let r=kernel::env_provider_new_23e18cff::make();
assert_eq!(r.clear_after_read,false);
}
