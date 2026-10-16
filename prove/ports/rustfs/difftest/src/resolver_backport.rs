//! The kernel's resolver carries rustfs 03e77594 (after the pinned e870a6d).
//! These are upstream's regression tests for that commit. Cases run on a thread
//! with a timeout so a regression fails instead of blocking the test run.
use rustfs_kernel::awsvars::{resolve_aws_variables, resolve_single_pass, ClaimStrings, VarContext};
use std::sync::mpsc;
use std::time::Duration;

fn b(s: &str) -> Vec<u8> {
    s.as_bytes().to_vec()
}

fn ctx(username: &str, account: &str) -> VarContext {
    VarContext {
        username: b(username), account: b(account),
        claims: ClaimStrings { sub: None, parent: None, parent_str: None, has_parent: false, has_role_arn: false,
            has_sa_policy: false },
        now_rfc3339: b(""), now_epoch: b(""),
    }
}

fn within<T: Send + 'static>(f: impl FnOnce() -> T + Send + 'static) -> T {
    let (tx, rx) = mpsc::channel();
    std::thread::spawn(move || tx.send(f()).unwrap());
    rx.recv_timeout(Duration::from_secs(20)).expect("resolution did not terminate")
}

/// Upstream `generated_policy_variable_cycles_are_bounded`.
#[test]
fn generated_cycles_are_bounded() {
    let out = within(|| resolve_aws_variables(&ctx("{aws:AccountId}{aws:username}", "$$"), b"${aws:AccountId}{aws:username}"));
    assert_eq!(out, vec![b("${aws:AccountId}{aws:username}")]);
}

/// Upstream `a_single_pass_resolves_all_original_variables`.
#[test]
fn single_pass_resolves_all_original_variables() {
    let pattern = "${aws:username}".repeat(20);
    let out = within(move || resolve_single_pass(&ctx("alice", "acct"), pattern.as_bytes(), 0));
    assert_eq!(out, vec![b(&"alice".repeat(20))]);
}

/// Upstream `nested_policy_variables_have_a_depth_limit`.
#[test]
fn nested_variables_have_a_depth_limit() {
    let pattern = format!("{}aws:username{}", "${".repeat(100), "}".repeat(100));
    let out = within(move || resolve_aws_variables(&ctx("{aws:AccountId}{aws:username}", "$$"), pattern.as_bytes()));
    assert_eq!(out.len(), 1);
    assert!(out[0].windows(2).any(|w| w == b"${"));
}
