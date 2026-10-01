//! The kernel against `rustfs-policy` itself: random identity and bucket
//! policies, built as JSON for upstream and as kernel values from the same
//! draws, evaluated on random requests.
use std::collections::HashMap;

use rustfs_kernel::acts::{Action as KAction, Family};
use rustfs_kernel::awsvars::ClaimStrings;
use rustfs_kernel::condfuncs::{Cond, Condition, Env, Functions, IpAddr as KIp, Key, NumOp, StrOp};
use rustfs_kernel::policies::{bucket_policy_is_allowed, policy_is_allowed};
use rustfs_kernel::rsrc::Resource;
use rustfs_kernel::stmts::{Args as KArgs, BPStatement, BucketPolicyArgs as KBArgs, Effect, Principal, Statement};
use rustfs_policy::policy::action::Action as UAction;
use rustfs_policy::policy::{Args, BucketPolicy, BucketPolicyArgs, Policy};
use serde_json::{json, Map, Value};

/// xorshift64*.
pub struct Rng(pub u64);
impl Rng {
    pub fn next(&mut self) -> u64 {
        self.0 ^= self.0 >> 12;
        self.0 ^= self.0 << 25;
        self.0 ^= self.0 >> 27;
        self.0.wrapping_mul(0x2545F4914F6CDD1D)
    }
    pub fn below(&mut self, n: u64) -> u64 {
        self.next() % n
    }
    pub fn chance(&mut self, pct: u64) -> bool {
        self.below(100) < pct
    }
    pub fn pick<'a, T>(&mut self, xs: &'a [T]) -> &'a T {
        &xs[self.below(xs.len() as u64) as usize]
    }
}

pub const ACTIONS: &[&str] = &["s3:*", "s3:GetObject", "s3:GetObjectVersion", "s3:PutObject", "s3:ListBucket",
    "s3:ListBucketVersions", "s3:DeleteObject", "s3:ForceDeleteBucket", "s3:ForceDeleteObject", "admin:*",
    "admin:GetTable", "admin:ServerInfo", "sts:AssumeRole", "kms:*", "kms:Backup", "kms:DescribeKey"];
const S3_RESOURCES: &[&str] = &["*", "bucket/*", "bucket", "bucket/", "bucket/a/*", "bucket/${aws:username}/*",
    "b?cket/*", "bucket/${s3:s3:versionid}", "bucket/a/../b", "bucket/*/x", "other/*", "bucket/${aws:userid}",
    "bucket/${aws:PrincipalType}/*", "bucket/${${aws:username}}", "bucket/${aws:nosuch}/*", "${aws:AccountId}/*",
    "bucket/x/z", "bucket/c", "bucket/../a", "bucket/a/b"];
const KMS_RESOURCES: &[&str] = &["key/k1", "*", "alias/x", "key/k*"];
const BUCKETS: &[&str] = &["bucket", "other", "bucket2"];
const OBJECTS: &[&str] = &["", "a/b", "/a", "x", "alice/notes", "a/../b", "./a", "k1", "a//b", "1", "x/y/../z",
    "../a", "a/b/../../c", "User/x", "ServiceAccount/x", "AssumedRole/x"];
const USERS: &[&str] = &["alice", "bob", "svc-1"];
/// Condition keys, with `KeyName::name()`.
const STR_KEYS: &[(&str, &str)] = &[("aws:username", "username"), ("s3:prefix", "prefix"),
    ("s3:x-amz-acl", "x-amz-acl"), ("jwt:groups", "groups"), ("s3:delimiter", "delimiter")];
const STR_VALUES: &[&str] = &["alice", "Alice", "a*", "public-read", "x", "${aws:username}", "${s3:s3:versionid}", "", "dev", "a?"];
const REQ_VALUES: &[&str] = &["alice", "ALICE", "public-read", "x", "abc", "dev", "", "a"];
const OPS: &[(&str, StrOp)] = &[("StringEquals", StrOp::StringEquals), ("StringNotEquals", StrOp::StringNotEquals),
    ("StringEqualsIgnoreCase", StrOp::StringEqualsIgnoreCase), ("StringNotEqualsIgnoreCase", StrOp::StringNotEqualsIgnoreCase),
    ("StringLike", StrOp::StringLike), ("StringNotLike", StrOp::StringNotLike), ("ArnLike", StrOp::ArnLike),
    ("ArnNotLike", StrOp::ArnNotLike), ("ArnEquals", StrOp::ArnEquals), ("ArnNotEquals", StrOp::ArnNotEquals)];
const NUM_OPS: &[(&str, NumOp, bool)] = &[("NumericEquals", NumOp::Eq, false), ("NumericNotEquals", NumOp::Ne, false),
    ("NumericLessThan", NumOp::Lt, false), ("NumericLessThanEquals", NumOp::Le, false),
    ("NumericGreaterThan", NumOp::Gt, false), ("NumericGreaterThanEquals", NumOp::Ge, false),
    ("NumericGreaterThanIfExists", NumOp::Ge, true)];
const CIDRS: &[&str] = &["10.0.0.0/8", "192.168.1.5", "2001:db8::/32", "::1", "0.0.0.0/0", "10.1.2.3/32"];
const REQ_IPS: &[&str] = &["10.1.2.3", "192.168.1.5", "::1", "2001:db8::7", "bogus", "8.8.8.8"];

pub fn b(s: &str) -> Vec<u8> {
    s.as_bytes().to_vec()
}

pub fn kaction(a: &UAction) -> KAction {
    let family = match a {
        UAction::S3Action(_) => Family::S3,
        UAction::AdminAction(_) => Family::Admin,
        UAction::StsAction(_) => Family::Sts,
        UAction::KmsAction(_) => Family::Kms,
        UAction::None => Family::None,
    };
    KAction { family, name: b(<&str>::from(a)) }
}

fn action_of(name: &str) -> UAction {
    UAction::try_from(name).unwrap()
}

fn key(full: &str, name: &str) -> Key {
    Key { key_name: b(full), name: b(name), variable: None }
}

/// One condition operator: its JSON key, its value object and the kernel form.
fn condition(r: &mut Rng) -> (String, Value, Condition) {
    let if_exists = r.chance(15);
    let kind = r.below(10);
    let (op, val, cond) = if kind < 6 {
        let (name, op) = *r.pick(OPS);
        let mut obj = Map::new();
        let mut funcs = Vec::new();
        for _ in 0..1 + r.below(2) {
            let (full, n) = *r.pick(STR_KEYS);
            if obj.contains_key(full) {
                continue;
            }
            let mut vals: Vec<String> = (0..1 + r.below(3)).map(|_| r.pick(STR_VALUES).to_string()).collect();
            vals.sort();
            vals.dedup();
            obj.insert(full.into(), json!(vals));
            funcs.push((key(full, n), vals.iter().map(|v| b(v)).collect()));
        }
        (name.to_string(), Value::Object(obj), Cond::Str(op, funcs))
    } else if kind == 6 {
        let negate = r.chance(50);
        let mut obj = Map::new();
        let mut funcs = Vec::new();
        // JSON objects keep keys sorted, so upstream sees them in name order.
        for (full, n) in [("aws:Referer", "Referer"), ("aws:SourceIp", "SourceIp")] {
            if full == "aws:Referer" && !r.chance(30) {
                continue;
            }
            let nets: Vec<&str> = (0..1 + r.below(2)).map(|_| *r.pick(CIDRS)).collect();
            obj.insert(full.into(), json!(nets));
            let knets = nets.iter().map(|c| {
                let (a, p) = c.split_once('/').map(|(a, p)| (a, p.parse::<u8>().unwrap())).unwrap_or((c, 32));
                (kip(a.parse().unwrap()), p)
            }).collect();
            funcs.push((key(full, n), knets));
        }
        let op = if negate { "NotIpAddress" } else { "IpAddress" };
        (op.to_string(), Value::Object(obj), Cond::Ip(negate, funcs))
    } else if kind == 7 {
        let null = r.chance(50);
        let v = r.chance(50);
        let (full, n) = *r.pick(&[("aws:SecureTransport", "SecureTransport"), ("s3:x-amz-acl", "x-amz-acl")]);
        let mut obj = Map::new();
        obj.insert(full.into(), if r.chance(50) { json!(v) } else { json!(v.to_string()) });
        let funcs = vec![(key(full, n), v)];
        if null { ("Null".into(), Value::Object(obj), Cond::Null(funcs)) } else { ("Bool".into(), Value::Object(obj), Cond::Bool(funcs)) }
    } else {
        let (name, op, ie) = *r.pick(NUM_OPS);
        let n: i64 = *r.pick(&[0, 5, 10, -3, i64::MAX]);
        let mut obj = Map::new();
        obj.insert("s3:max-keys".into(), if r.chance(50) { json!(n) } else { json!(n.to_string()) });
        (name.to_string(), Value::Object(obj), Cond::Num(op, ie, vec![(key("s3:max-keys", "max-keys"), n)]))
    };
    // Upstream parses `NumericGreaterThanIfExists` as its own operator (>=,
    // missing key passes), not as `IfExists(NumericGreaterThan)`.
    if if_exists && op == "NumericGreaterThan" {
        if let Cond::Num(_, _, f) = cond {
            return ("NumericGreaterThanIfExists".into(), val, Condition { if_exists: false, cond: Cond::Num(NumOp::Ge, true, f) });
        }
    }
    let op = if if_exists { format!("{op}IfExists") } else { op };
    (op, val, Condition { if_exists, cond })
}

fn kip(ip: std::net::IpAddr) -> KIp {
    match ip {
        std::net::IpAddr::V4(a) => KIp::V4(u32::from(a)),
        std::net::IpAddr::V6(a) => KIp::V6(u128::from(a)),
    }
}

/// The `Condition` block, keyed by qualified operator.
fn conditions(r: &mut Rng) -> (Value, Functions) {
    let mut obj = Map::new();
    let mut f = Functions { for_any_value: vec![], for_all_values: vec![], for_normal: vec![] };
    for _ in 0..r.below(3) {
        let (op, val, c) = condition(r);
        let q = r.below(4);
        let key = match q {
            0 => format!("ForAnyValue:{op}"),
            1 => format!("ForAllValues:{op}"),
            _ => op,
        };
        if obj.contains_key(&key) {
            continue;
        }
        obj.insert(key, val);
        match q {
            0 => f.for_any_value.push(c),
            1 => f.for_all_values.push(c),
            _ => f.for_normal.push(c),
        }
    }
    (Value::Object(obj), f)
}

/// Statement fields shared by both statement kinds.
fn body(r: &mut Rng, obj: &mut Map<String, Value>) -> (Effect, Vec<KAction>, Vec<KAction>, Vec<Resource>, Vec<Resource>, Functions) {
    let effect = if r.chance(35) { Effect::Deny } else { Effect::Allow };
    obj.insert("Effect".into(), json!(if effect == Effect::Deny { "Deny" } else { "Allow" }));
    let pick_actions = |r: &mut Rng| -> Vec<&'static str> {
        let mut v: Vec<&str> = (0..1 + r.below(3)).map(|_| *r.pick(ACTIONS)).collect();
        v.sort();
        v.dedup();
        v
    };
    let (mut actions, mut not_actions) = (vec![], vec![]);
    if r.chance(80) {
        let v = pick_actions(r);
        obj.insert("Action".into(), json!(v));
        actions = v.iter().map(|a| kaction(&action_of(a))).collect();
    } else {
        let v = pick_actions(r);
        obj.insert("NotAction".into(), json!(v));
        not_actions = v.iter().map(|a| kaction(&action_of(a))).collect();
    }
    let pick_res = |r: &mut Rng| -> Vec<(String, Resource)> {
        let mut v: Vec<(String, Resource)> = (0..1 + r.below(3)).map(|_| {
            if r.chance(15) {
                let p = *r.pick(KMS_RESOURCES);
                (format!("arn:aws:kms:::{p}"), Resource::Kms(b(p)))
            } else {
                let p = *r.pick(S3_RESOURCES);
                (format!("arn:aws:s3:::{p}"), Resource::S3(b(p)))
            }
        }).collect();
        v.sort_by(|a, b| a.0.cmp(&b.0));
        v.dedup_by(|a, b| a.0 == b.0);
        v
    };
    let (mut resources, mut not_resources) = (vec![], vec![]);
    match r.below(10) {
        0 => {}
        1 | 2 => {
            let v = pick_res(r);
            obj.insert("NotResource".into(), json!(v.iter().map(|x| &x.0).collect::<Vec<_>>()));
            not_resources = v.into_iter().map(|x| x.1).collect();
        }
        _ => {
            let v = pick_res(r);
            obj.insert("Resource".into(), json!(v.iter().map(|x| &x.0).collect::<Vec<_>>()));
            resources = v.into_iter().map(|x| x.1).collect();
        }
    }
    let (cv, f) = conditions(r);
    if !cv.as_object().unwrap().is_empty() {
        obj.insert("Condition".into(), cv);
    }
    (effect, actions, not_actions, resources, not_resources, f)
}

pub fn identity_policy(r: &mut Rng) -> (Policy, Vec<Statement>) {
    let mut sts = vec![];
    let mut js = vec![];
    for _ in 0..1 + r.below(4) {
        let mut obj = Map::new();
        let (effect, actions, not_actions, resources, not_resources, conditions) = body(r, &mut obj);
        js.push(Value::Object(obj));
        sts.push(Statement { effect, actions, not_actions, resources, not_resources, conditions });
    }
    let p: Policy = serde_json::from_str(&json!({"Version": "2012-10-17", "Statement": js}).to_string()).unwrap();
    (p, sts)
}

pub fn bucket_policy(r: &mut Rng) -> (BucketPolicy, Vec<BPStatement>) {
    let mut sts = vec![];
    let mut js = vec![];
    for _ in 0..1 + r.below(4) {
        let mut obj = Map::new();
        let (effect, actions, not_actions, mut resources, not_resources, conditions) = body(r, &mut obj);
        // Bucket policies need a resource and no KMS resources to parse sensibly.
        resources.retain(|x| matches!(x, Resource::S3(_)));
        if let Some(Value::Array(a)) = obj.get_mut("Resource") {
            a.retain(|v| v.as_str().unwrap().starts_with("arn:aws:s3"));
        }
        let (pv, principal) = match r.below(4) {
            0 => (json!("*"), Principal { aws: vec![b("*")], service: vec![] }),
            1 => {
                let v: Vec<&str> = vec![*r.pick(&["alice", "b?b", "svc-*", "*", "bob?", "alice??", "svc-1?"])];
                (json!({"AWS": v}), Principal { aws: v.iter().map(|x| b(x)).collect(), service: vec![] })
            }
            2 => (json!({"Service": "svc-1"}), Principal { aws: vec![], service: vec![b("svc-1")] }),
            _ => (json!({"AWS": ["alice", "bob"]}), Principal { aws: vec![b("alice"), b("bob")], service: vec![] }),
        };
        obj.insert("Principal".into(), pv);
        js.push(Value::Object(obj));
        sts.push(BPStatement { effect, principal, actions, not_actions, resources, not_resources, conditions });
    }
    let p: BucketPolicy = serde_json::from_str(&json!({"Version": "2012-10-17", "Statement": js}).to_string()).unwrap();
    (p, sts)
}

/// A request: upstream's maps and the kernel's lists.
pub struct Req {
    pub account: String,
    pub action: UAction,
    pub bucket: String,
    pub object: String,
    pub conds: HashMap<String, Vec<String>>,
    pub claims: HashMap<String, Value>,
    pub is_owner: bool,
    pub deny_only: bool,
}

pub fn request(r: &mut Rng) -> Req {
    let mut conds = HashMap::new();
    for (_, n) in STR_KEYS {
        if r.chance(40) {
            conds.insert(n.to_string(), (0..r.below(3)).map(|_| r.pick(REQ_VALUES).to_string()).collect());
        }
    }
    if r.chance(30) {
        conds.insert("Referer".into(), (0..1 + r.below(2)).map(|_| r.pick(REQ_IPS).to_string()).collect());
    }
    if r.chance(50) {
        conds.insert("SourceIp".into(), (0..1 + r.below(2)).map(|_| r.pick(REQ_IPS).to_string()).collect());
    }
    if r.chance(40) {
        conds.insert("SecureTransport".into(), vec![r.pick(&["true", "false", "yes"]).to_string()]);
    }
    if r.chance(40) {
        conds.insert("max-keys".into(), vec![r.pick(&["5", "10", "-3", "+7", "abc", "9223372036854775807", ""]).to_string()]);
    }
    if r.chance(30) {
        conds.insert("versionid".into(), vec![r.pick(&["v1", "", "a"]).to_string()]);
    }
    let mut claims = HashMap::new();
    if r.chance(40) {
        claims.insert("parent".into(), match r.below(3) { 0 => json!("alice"), 1 => json!(7), _ => json!(["p1", "p2"]) });
    }
    if r.chance(40) {
        claims.insert("sub".into(), match r.below(3) { 0 => json!("sub-1"), 1 => json!(["s1", 2, true, {"x": 1}]), _ => json!(null) });
    }
    if r.chance(15) {
        claims.insert("roleArn".into(), json!("arn:role"));
    }
    if r.chance(20) {
        claims.insert("sa-policy".into(), json!("x"));
    }
    let names: Vec<&str> = ACTIONS.iter().copied().filter(|a| !a.ends_with('*')).collect();
    Req {
        account: r.pick(USERS).to_string(),
        action: action_of(r.pick(&names)),
        bucket: r.pick(BUCKETS).to_string(),
        object: r.pick(OBJECTS).to_string(),
        conds, claims,
        is_owner: r.chance(15),
        deny_only: r.chance(15),
    }
}

/// `get_claim_as_strings` over the JSON claims, the trusted decoding step.
fn claim_strings(v: Option<&Value>) -> Option<Vec<Vec<u8>>> {
    match v? {
        Value::String(s) => Some(vec![b(s)]),
        Value::Array(a) => Some(a.iter().filter_map(|x| match x {
            Value::String(s) => Some(b(s)),
            Value::Number(n) => Some(b(&n.to_string())),
            Value::Bool(x) => Some(b(&x.to_string())),
            _ => None,
        }).collect()),
        Value::Number(n) => Some(vec![b(&n.to_string())]),
        Value::Bool(x) => Some(vec![b(&x.to_string())]),
        _ => None,
    }
}

pub fn kconds(m: &HashMap<String, Vec<String>>) -> Vec<(Vec<u8>, Vec<Vec<u8>>)> {
    m.iter().map(|(k, v)| (b(k), v.iter().map(|x| b(x)).collect())).collect()
}

pub fn env(m: &HashMap<String, Vec<String>>) -> Env {
    let ips = m.values().flatten().map(|s| (b(s), s.parse::<std::net::IpAddr>().ok().map(kip))).collect();
    Env { ips, now_rfc3339: b("2026-09-30T00:00:00Z"), now_epoch: b("1790000000") }
}

pub fn kargs(q: &Req) -> KArgs {
    KArgs {
        account: b(&q.account), action: kaction(&q.action), bucket: b(&q.bucket), conditions: kconds(&q.conds),
        is_owner: q.is_owner, object: b(&q.object),
        claims: ClaimStrings {
            sub: claim_strings(q.claims.get("sub")),
            parent: claim_strings(q.claims.get("parent")),
            parent_str: q.claims.get("parent").and_then(|v| v.as_str()).map(b),
            has_parent: q.claims.contains_key("parent"),
            has_role_arn: q.claims.contains_key("roleArn"),
            has_sa_policy: q.claims.contains_key("sa-policy"),
        },
        deny_only: q.deny_only,
    }
}

pub fn upstream_identity(p: &Policy, q: &Req) -> bool {
    let groups = None;
    let args = Args { account: &q.account, groups: &groups, action: q.action, bucket: &q.bucket,
        conditions: &q.conds, is_owner: q.is_owner, object: &q.object, claims: &q.claims, deny_only: q.deny_only };
    pollster::block_on(p.is_allowed(&args))
}

pub fn upstream_bucket(p: &BucketPolicy, q: &Req) -> bool {
    let groups = None;
    let args = BucketPolicyArgs { account: &q.account, groups: &groups, action: q.action, bucket: &q.bucket,
        conditions: &q.conds, is_owner: q.is_owner, object: &q.object };
    pollster::block_on(p.is_allowed(&args))
}

#[test]
fn identity_policies_agree() {
    let mut r = Rng(0x1D3A_77F0_0C0F_FEE1);
    let mut allowed = 0;
    let n = 400_000;
    for i in 0..n {
        let (p, sts) = identity_policy(&mut r);
        let q = request(&mut r);
        let want = upstream_identity(&p, &q);
        let got = policy_is_allowed(&sts, &kargs(&q), &env(&q.conds));
        assert_eq!(got, want, "case {i}: {}\n{:?} {} {}/{} {:?} {:?}", serde_json::to_string(&p).unwrap(),
            q.action, q.account, q.bucket, q.object, q.conds, q.claims);
        allowed += want as usize;
    }
    assert!(allowed > n / 20 && allowed < n - n / 20, "{allowed}");
}

#[test]
fn bucket_policies_agree() {
    let mut r = Rng(0xB0C4_E7A1_1C1E_5);
    let mut allowed = 0;
    let n = 400_000;
    for i in 0..n {
        let (p, sts) = bucket_policy(&mut r);
        let q = request(&mut r);
        let want = upstream_bucket(&p, &q);
        let kb = KBArgs { account: b(&q.account), action: kaction(&q.action), bucket: b(&q.bucket),
            conditions: kconds(&q.conds), is_owner: q.is_owner, object: b(&q.object) };
        let got = bucket_policy_is_allowed(&sts, &kb, &env(&q.conds));
        if got != want {
            for (k, st) in sts.iter().enumerate() {
                let ua = { let groups = None; let a = BucketPolicyArgs { account: &q.account, groups: &groups, action: q.action, bucket: &q.bucket,
                    conditions: &q.conds, is_owner: q.is_owner, object: &q.object };
                    pollster::block_on(p.statements[k].is_allowed(&a)) };
                eprintln!("stmt {k}: upstream {ua} kernel {} {:?}", rustfs_kernel::stmts::bp_statement_is_allowed(st, &kb, &env(&q.conds)), st);
            }
        }
        assert_eq!(got, want, "case {i}: {}\n{:?} {} {}/{} {:?}", serde_json::to_string(&p).unwrap(),
            q.action, q.account, q.bucket, q.object, q.conds);
        allowed += want as usize;
    }
    assert!(allowed > n / 20 && allowed < n - n / 20, "{allowed}");
}
