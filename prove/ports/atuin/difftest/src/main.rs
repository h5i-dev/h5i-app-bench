//! Differential test: atuin-server @ df152cd (the real router, handlers and
//! SQLite backend, over HTTP) against the kernel's `transition` + `apply`.
//!
//! For each scenario a fresh upstream server runs on 127.0.0.1 with a SQLite
//! database in a temporary directory. A seeded generator sends random
//! requests. After each one the test compares
//!   * the HTTP status and JSON body with the kernel's reply or error, and
//!   * every table (users, sessions, history, store, AUTOINCREMENT counters)
//!     with the kernel's state after `apply`.
//! The kernel's state evolves on its own; it is never re-read from the
//! database, so a divergence in `apply` also shows up.
//!
//! Inputs the handler generates itself are read back from the database
//! after the request: the Argon2 hash of a new password and the new session
//! token. The verification table (`Crypto`) is filled by the real
//! `HashedPassword::verify` on every stored hash and the request's password.
//!
//! Usage: atuin-difftest [--seed N] [--steps N]

use std::collections::{BTreeMap, HashMap};
use std::net::SocketAddr;
use std::time::Duration;

use atuin_kernel as k;
use atuin_server::db::DbSettings;
use atuin_server::db::models::User as UpUser;
use atuin_server::{Settings, launch_with_tcp_listener};
use rand::{Rng, SeedableRng};
use rand_chacha::ChaCha8Rng;
use serde_json::{Value, json};
use sqlx::Row;
use sqlx::sqlite::SqlitePool;
use uuid::Uuid;

const HOSTS: [u128; 3] = [
    0x0190_0000_0000_7000_8000_0000_0000_0001,
    0x0190_0000_0000_7000_8000_0000_0000_0002,
    0xffff_0000_0000_7000_8000_0000_0000_0003,
];
const TAGS: [&str; 5] = ["history", "kv", "packfile", "Other tag", "ünï"];
const VERSIONS: [&str; 3] = ["v0", "v1", "weird version"];
const USERNAMES: [&str; 10] = ["alice", "Alice", "bob", "carol-2", "ALICE", "dave_x", "", "é", "eve-", "0"];
const EMAILS: [&str; 6] = ["a@x.org", "A@X.ORG", "b@x.org", "c@x.org", "", "É@x.org"];
const PASSWORDS: [&str; 4] = ["hunter2", "correct horse", "", "pässwörd"];
const IDXS: [u64; 10] = [0, 1, 2, 3, 4, 5, 0x7fff_ffff_ffff_ffff, 0x8000_0000_0000_0000, u64::MAX, 7];

struct Scenario {
    name: &'static str,
    open_registration: bool,
    max_record_size: u64,
    /// Users created directly in the database before the first request.
    seeded_users: usize,
}

const SCENARIOS: [Scenario; 3] = [
    Scenario { name: "open, 64-byte records", open_registration: true, max_record_size: 64, seeded_users: 0 },
    Scenario { name: "open, unlimited records", open_registration: true, max_record_size: 0, seeded_users: 1 },
    Scenario { name: "closed, seeded users", open_registration: false, max_record_size: 32, seeded_users: 3 },
];

/// What the generator sends: the header bytes on the wire and the route.
#[derive(Debug, Clone)]
enum Op {
    GetUser(String),
    Register { username: String, email: String, password: String },
    Login { username: String, password: String },
    Me,
    DeleteAccount { password: String },
    ChangePassword { current: String, new: String },
    PostRecords(Vec<k::RecordIn>),
    Status,
    Next { host: u128, tag: String, start: Option<u64>, count: u64 },
    DeleteStore,
    /// Not a request: a legacy `history` row for a user, inserted by SQL.
    SeedHistory,
}

struct Harness {
    http: reqwest::Client,
    base: String,
    pool: SqlitePool,
    cfg: k::Config,
    state: k::Snapshot,
    /// (hash, password) -> HashedPassword::verify
    verified: HashMap<(String, String), bool>,
    tokens: Vec<String>,
    rng: ChaCha8Rng,
    history_counter: u64,
    stats: BTreeMap<String, u64>,
}

fn bytes(s: &str) -> Vec<u8> {
    s.as_bytes().to_vec()
}

fn text(b: &[u8]) -> String {
    String::from_utf8(b.to_vec()).expect("kernel text is UTF-8 here")
}

/// hyper drops the optional whitespace around a header value.
fn trim_ows(v: &[u8]) -> Vec<u8> {
    let mut a = 0;
    let mut b = v.len();
    while a < b && (v[a] == b' ' || v[a] == b'\t') {
        a += 1;
    }
    while b > a && (v[b - 1] == b' ' || v[b - 1] == b'\t') {
        b -= 1;
    }
    v[a..b].to_vec()
}

fn error_reply(e: k::Error) -> (u16, Value) {
    let (status, reason) = match e {
        k::Error::MissingAuthorization => (400, "missing authorization header"),
        k::Error::InvalidAuthorization => (400, "invalid authorization header encoding"),
        k::Error::SessionNotFound => (403, "session not found"),
        k::Error::UserNotFound => (404, "user not found"),
        k::Error::RegistrationClosed => (400, "this server is not open for registrations"),
        k::Error::InvalidUsername => (400, "Only alphanumeric and hyphens (-) are allowed in usernames"),
        k::Error::RegisterFailed => (400, "failed to register user"),
        k::Error::WrongPassword => (401, "password is not correct"),
        k::Error::ChangePasswordFailed => (500, "failed to change user password"),
        k::Error::RecordTooLarge => (400, "could not add records; record too large"),
        k::Error::Overflow => panic!("counter overflow is unreachable in the test"),
    };
    (status, json!({ "reason": reason }))
}

fn record_json(r: &k::StoreRow) -> Value {
    json!({
        "id": Uuid::from_u128(r.client_id).to_string(),
        "idx": r.idx,
        "host": { "id": Uuid::from_u128(r.host).to_string(), "name": "" },
        "timestamp": r.timestamp,
        "version": text(&r.version),
        "tag": text(&r.tag),
        "data": { "data": text(&r.data), "content_encryption_key": text(&r.cek) },
    })
}

fn reply_json(r: &k::Reply) -> Value {
    match r {
        k::Reply::Username(u) => json!({ "username": text(u) }),
        k::Reply::Session(t) => json!({ "session": text(t), "auth": "cli" }),
        k::Reply::Empty => json!({}),
        k::Reply::Unit => Value::Null,
        k::Reply::Status(ps) => {
            let mut hosts: BTreeMap<String, BTreeMap<String, u64>> = BTreeMap::new();
            for p in ps {
                hosts.entry(Uuid::from_u128(p.host).to_string()).or_default().insert(text(&p.tag), p.idx);
            }
            json!({ "hosts": hosts })
        }
        k::Reply::Records(rs) => Value::Array(rs.iter().map(record_json).collect()),
    }
}

/// `RecordStatus` serializes `HashMap`s; compare as ordered maps.
fn normalize(v: Value) -> Value {
    match v {
        Value::Object(m) => {
            let sorted: BTreeMap<String, Value> = m.into_iter().map(|(k, v)| (k, normalize(v))).collect();
            serde_json::to_value(sorted).unwrap()
        }
        Value::Array(a) => Value::Array(a.into_iter().map(normalize).collect()),
        other => other,
    }
}

impl Harness {
    fn pick<'a, T>(&mut self, xs: &'a [T]) -> &'a T {
        &xs[self.rng.gen_range(0..xs.len())]
    }

    fn bump(&mut self, key: &str) {
        *self.stats.entry(key.to_owned()).or_default() += 1;
    }

    async fn dump(&self) -> k::Snapshot {
        let users = sqlx::query("SELECT id, username, email, password FROM users ORDER BY rowid")
            .fetch_all(&self.pool)
            .await
            .unwrap()
            .iter()
            .map(|r| k::User {
                id: r.get::<i64, _>(0) as u64,
                username: bytes(&r.get::<String, _>(1)),
                email: bytes(&r.get::<String, _>(2)),
                password: bytes(&r.get::<String, _>(3)),
            })
            .collect();
        let sessions = sqlx::query("SELECT id, user_id, token FROM sessions ORDER BY rowid")
            .fetch_all(&self.pool)
            .await
            .unwrap()
            .iter()
            .map(|r| k::Session {
                id: r.get::<i64, _>(0) as u64,
                user_id: r.get::<i64, _>(1) as u64,
                token: bytes(&r.get::<String, _>(2)),
            })
            .collect();
        let history = sqlx::query("SELECT id, user_id FROM history ORDER BY rowid")
            .fetch_all(&self.pool)
            .await
            .unwrap()
            .iter()
            .map(|r| k::HistoryRow { id: r.get::<i64, _>(0) as u64, user_id: r.get::<i64, _>(1) as u64 })
            .collect();
        let store = sqlx::query(
            "SELECT user_id, client_id, host, idx, timestamp, version, tag, data, cek FROM store ORDER BY rowid",
        )
        .fetch_all(&self.pool)
        .await
        .unwrap()
        .iter()
        .map(|r| k::StoreRow {
            user_id: r.get::<i64, _>(0) as u64,
            client_id: r.get::<Uuid, _>(1).as_u128(),
            host: r.get::<Uuid, _>(2).as_u128(),
            idx: r.get::<i64, _>(3) as u64,
            timestamp: r.get::<i64, _>(4) as u64,
            version: bytes(&r.get::<String, _>(5)),
            tag: bytes(&r.get::<String, _>(6)),
            data: bytes(&r.get::<String, _>(7)),
            cek: bytes(&r.get::<String, _>(8)),
        })
        .collect();
        let seq = |name: &'static str| {
            let pool = self.pool.clone();
            async move {
                sqlx::query("SELECT seq FROM sqlite_sequence WHERE name = ?")
                    .bind(name)
                    .fetch_optional(&pool)
                    .await
                    .unwrap()
                    .map(|r| r.get::<i64, _>(0) as u64)
                    .unwrap_or(0)
                    + 1
            }
        };
        k::Snapshot {
            users,
            sessions,
            history,
            store,
            next_user_id: seq("users").await,
            next_session_id: seq("sessions").await,
        }
    }

    /// The verification table for `password` against every stored hash.
    async fn crypto(&mut self, password: &str) -> k::Crypto {
        let users: Vec<(String, UpUser)> = {
            let rows = sqlx::query("SELECT id, username, email, password FROM users").fetch_all(&self.pool).await.unwrap();
            let typed: Vec<UpUser> = sqlx::query_as("SELECT id, username, email, password FROM users")
                .fetch_all(&self.pool)
                .await
                .unwrap();
            rows.iter().map(|r| r.get::<String, _>(3)).zip(typed).collect()
        };
        let mut verified = Vec::new();
        for (hash, user) in users {
            let key = (hash.clone(), password.to_owned());
            let ok = match self.verified.get(&key) {
                Some(ok) => *ok,
                None => {
                    let ok = user.password.verify(password.into()).await;
                    self.verified.insert(key, ok);
                    ok
                }
            };
            if ok {
                verified.push(k::Verified { hash: bytes(&hash), password: bytes(password) });
            }
        }
        k::Crypto { verified }
    }

    fn gen_header(&mut self) -> Option<Vec<u8>> {
        let tok = if self.tokens.is_empty() || self.rng.gen_bool(0.05) {
            "not-a-session".to_owned()
        } else {
            let i = self.rng.gen_range(0..self.tokens.len());
            self.tokens[i].clone()
        };
        match self.rng.gen_range(0..20) {
            0 => None,
            1 => Some(b"Token".to_vec()),
            2 => Some(format!("Bearer {tok}").into_bytes()),
            3 => Some(format!("token {tok}").into_bytes()),
            4 => Some(format!("Token  {tok}").into_bytes()),
            5 => Some(format!("Token {tok} ").into_bytes()),
            6 => Some(format!("Token {tok}x").into_bytes()),
            7 => Some("Token é".as_bytes().to_vec()),
            8 => Some(format!("Token\t{tok}").into_bytes()),
            9 => Some(format!(" Token {tok}").into_bytes()),
            10 => Some(b"".to_vec()),
            _ => Some(format!("Token {tok}").into_bytes()),
        }
    }

    fn gen_record(&mut self) -> k::RecordIn {
        let len = self.rng.gen_range(0..80);
        let data: String = (0..len).map(|_| (b'a' + self.rng.gen_range(0..26)) as char).collect();
        k::RecordIn {
            client_id: Uuid::from_u128(self.rng.r#gen::<u128>()).as_u128(),
            host: *self.pick(&HOSTS),
            idx: *self.pick(&IDXS),
            timestamp: if self.rng.gen_bool(0.1) { u64::MAX } else { self.rng.gen_range(0..1u64 << 40) },
            version: bytes(self.pick(&VERSIONS)),
            tag: bytes(self.pick(&TAGS)),
            data: bytes(&data),
            cek: bytes(if self.rng.gen_bool(0.5) { "" } else { "{\"wpk\":\"x\"}" }),
        }
    }

    fn gen_op(&mut self) -> Op {
        match self.rng.gen_range(0..100) {
            0..=19 => Op::Register {
                username: self.pick(&USERNAMES).to_string(),
                email: self.pick(&EMAILS).to_string(),
                password: self.pick(&PASSWORDS).to_string(),
            },
            20..=31 => Op::Login {
                username: self.pick(&USERNAMES).to_string(),
                password: self.pick(&PASSWORDS).to_string(),
            },
            // An empty name is not the `/user/{username}` route (it falls through to the 404 fallback).
            32..=35 => Op::GetUser(self.pick(&USERNAMES[..6]).to_string()),
            36..=40 => Op::Me,
            41..=45 => Op::DeleteAccount { password: self.pick(&PASSWORDS).to_string() },
            46..=51 => Op::ChangePassword {
                current: self.pick(&PASSWORDS).to_string(),
                new: self.pick(&PASSWORDS).to_string(),
            },
            52..=71 => {
                let n = self.rng.gen_range(0..5);
                Op::PostRecords((0..n).map(|_| self.gen_record()).collect())
            }
            72..=78 => Op::Status,
            79..=93 => Op::Next {
                host: *self.pick(&HOSTS),
                tag: self.pick(&TAGS).to_string(),
                start: if self.rng.gen_bool(0.3) { None } else { Some(*self.pick(&IDXS)) },
                count: *self.pick(&[0u64, 1, 2, 3, 100, 0x8000_0000_0000_0000, u64::MAX]),
            },
            94..=96 => Op::DeleteStore,
            _ => Op::SeedHistory,
        }
    }

    async fn send(&self, header: &Option<Vec<u8>>, op: &Op) -> (u16, Value) {
        use reqwest::Method;
        let (method, path, body): (Method, String, Option<Value>) = match op {
            Op::GetUser(u) => {
                let mut url = url::Url::parse(&format!("{}/user/x", self.base)).unwrap();
                url.path_segments_mut().unwrap().pop().push(u);
                (Method::GET, url.to_string(), None)
            }
            Op::Register { username, email, password } => (
                Method::POST,
                format!("{}/register", self.base),
                Some(json!({ "username": username, "email": email, "password": password })),
            ),
            Op::Login { username, password } => (
                Method::POST,
                format!("{}/login", self.base),
                Some(json!({ "username": username, "password": password })),
            ),
            Op::Me => (Method::GET, format!("{}/api/v0/me", self.base), None),
            Op::DeleteAccount { password } => {
                (Method::DELETE, format!("{}/account", self.base), Some(json!({ "password": password })))
            }
            Op::ChangePassword { current, new } => (
                Method::PATCH,
                format!("{}/account/password", self.base),
                Some(json!({ "current_password": current, "new_password": new })),
            ),
            Op::PostRecords(rs) => {
                let body: Vec<Value> = rs
                    .iter()
                    .map(|r| {
                        json!({
                            "id": Uuid::from_u128(r.client_id).to_string(),
                            "idx": r.idx,
                            "host": { "id": Uuid::from_u128(r.host).to_string() },
                            "timestamp": r.timestamp,
                            "version": text(&r.version),
                            "tag": text(&r.tag),
                            "data": { "data": text(&r.data), "content_encryption_key": text(&r.cek) },
                        })
                    })
                    .collect();
                (Method::POST, format!("{}/api/v0/record", self.base), Some(Value::Array(body)))
            }
            Op::Status => (Method::GET, format!("{}/api/v0/record", self.base), None),
            Op::Next { host, tag, start, count } => {
                let mut url = url::Url::parse(&format!("{}/api/v0/record/next", self.base)).unwrap();
                {
                    let mut q = url.query_pairs_mut();
                    q.append_pair("host", &Uuid::from_u128(*host).to_string());
                    q.append_pair("tag", tag);
                    if let Some(s) = start {
                        q.append_pair("start", &s.to_string());
                    }
                    q.append_pair("count", &count.to_string());
                }
                (Method::GET, url.to_string(), None)
            }
            Op::DeleteStore => (Method::DELETE, format!("{}/api/v0/store", self.base), None),
            Op::SeedHistory => unreachable!(),
        };
        let mut rb = self.http.request(method, path);
        if let Some(h) = header {
            rb = rb.header("authorization", reqwest::header::HeaderValue::from_bytes(h).unwrap());
        }
        if let Some(b) = body {
            rb = rb.json(&b);
        }
        let resp = rb.send().await.expect("request");
        let status = resp.status().as_u16();
        let text = resp.text().await.unwrap();
        let body = if text.is_empty() { Value::Null } else { serde_json::from_str(&text).unwrap_or(Value::String(text)) };
        (status, normalize(body))
    }

    async fn seed_history(&mut self) {
        if self.state.users.is_empty() {
            return;
        }
        let i = self.rng.gen_range(0..self.state.users.len());
        let uid = self.state.users[i].id;
        self.history_counter += 1;
        sqlx::query("INSERT INTO history (client_id, user_id, hostname, timestamp, data) VALUES (?, ?, 'h', 0, 'd')")
            .bind(format!("h{}", self.history_counter))
            .bind(uid as i64)
            .execute(&self.pool)
            .await
            .unwrap();
        let id: i64 = sqlx::query("SELECT max(id) FROM history").fetch_one(&self.pool).await.unwrap().get(0);
        self.state.history.push(k::HistoryRow { id: id as u64, user_id: uid });
    }

    /// Kernel inputs for what upstream's handler generated, read back afterwards.
    fn generated(&self, before: &k::Snapshot, after: &k::Snapshot, op: &Op, n: u64) -> k::Command {
        match op {
            Op::Register { username, email, .. } => {
                let new_user = after.users.iter().find(|u| !before.users.iter().any(|b| b.id == u.id));
                let new_hash = new_user.map(|u| u.password.clone()).unwrap_or_else(|| format!("$unused${n}").into_bytes());
                let token = new_user
                    .and_then(|u| after.sessions.iter().find(|s| s.user_id == u.id))
                    .map(|s| s.token.clone())
                    .unwrap_or_else(|| format!("unused-token-{n}").into_bytes());
                k::Command::Register { username: bytes(username), email: bytes(email), new_hash, token }
            }
            Op::ChangePassword { current, .. } => {
                let changed = after
                    .users
                    .iter()
                    .find(|u| before.users.iter().any(|b| b.id == u.id && b.password != u.password));
                let new_hash = changed.map(|u| u.password.clone()).unwrap_or_else(|| format!("$unused${n}").into_bytes());
                k::Command::ChangePassword { current_password: bytes(current), new_hash }
            }
            Op::GetUser(u) => k::Command::GetUser { username: bytes(u) },
            Op::Login { username, password } => k::Command::Login { username: bytes(username), password: bytes(password) },
            Op::Me => k::Command::Me,
            Op::DeleteAccount { password } => k::Command::DeleteAccount { password: bytes(password) },
            Op::PostRecords(rs) => k::Command::PostRecords { records: rs.clone() },
            Op::Status => k::Command::Status,
            Op::Next { host, tag, start, count } => {
                k::Command::Next { host: *host, tag: bytes(tag), start: *start, count: *count }
            }
            Op::DeleteStore => k::Command::DeleteStore,
            Op::SeedHistory => unreachable!(),
        }
    }

    async fn step(&mut self, n: u64) {
        let op = self.gen_op();
        if let Op::SeedHistory = op {
            self.seed_history().await;
            self.bump("seed history");
            return;
        }
        let header = self.gen_header();
        let password = match &op {
            Op::Login { password, .. } | Op::DeleteAccount { password } => password.clone(),
            Op::ChangePassword { current, .. } => current.clone(),
            _ => String::new(),
        };
        let crypto = self.crypto(&password).await;
        let before = self.dump().await;
        assert_eq!(before, self.state, "step {n}: state drifted before the request");
        let (status, body) = self.send(&header, &op).await;
        let after = self.dump().await;
        let req = k::Request { authorization: header.as_deref().map(trim_ows), command: self.generated(&before, &after, &op, n) };
        let out = k::transition(&self.cfg, &crypto, &self.state, &req);
        let expected = match &out {
            Ok((_, r)) => (200, normalize(reply_json(r))),
            Err(e) => error_reply(*e),
        };
        assert_eq!(
            (status, &body),
            (expected.0, &expected.1),
            "step {n}: response differs\n op {op:?}\n header {header:?}\n kernel {out:?}"
        );
        if let Ok((ws, _)) = &out {
            self.state = k::apply(&self.state, ws);
        }
        assert_eq!(after, self.state, "step {n}: tables differ after {op:?}\n kernel {out:?}");
        if let Ok((_, k::Reply::Session(t))) = &out {
            let t = text(t);
            if !self.tokens.contains(&t) {
                self.tokens.push(t);
            }
        }
        let kind = format!("{:?}", req.command).split([' ', '{', '(']).next().unwrap().to_owned();
        let outcome = match &out {
            Ok((ws, _)) if ws.is_empty() => "ok".to_owned(),
            Ok((ws, _)) => format!("ok+{}w", ws.len().min(3)),
            Err(e) => format!("{e:?}"),
        };
        self.bump(&format!("{kind} {outcome}"));
    }
}

async fn seed_users(pool: &SqlitePool, n: usize, tokens: &mut Vec<String>) {
    use argon2::password_hash::{PasswordHasher, SaltString};
    for i in 0..n {
        let salt = SaltString::encode_b64(&[i as u8 + 1; 16]).unwrap();
        let hash = argon2::Argon2::default().hash_password(PASSWORDS[i % PASSWORDS.len()].as_bytes(), &salt).unwrap().to_string();
        let name = ["alice", "bob", "carol-2"][i % 3];
        let id: i64 = sqlx::query("INSERT INTO users (username, email, password) VALUES (?, ?, ?) RETURNING id")
            .bind(name)
            .bind(format!("{name}@seed.org"))
            .bind(&hash)
            .fetch_one(pool)
            .await
            .unwrap()
            .get(0);
        let token = format!("seed-token-{i}");
        sqlx::query("INSERT INTO sessions (user_id, token) VALUES (?, ?)").bind(id).bind(&token).execute(pool).await.unwrap();
        tokens.push(token);
    }
}

async fn run(sc: &Scenario, seed: u64, steps: u64) -> BTreeMap<String, u64> {
    let dir = tempfile::tempdir_in(std::env::var("TMPDIR").unwrap_or_else(|_| "/tmp".into())).unwrap();
    let db_path = dir.path().join("atuin.db");
    let db_uri = format!("sqlite://{}", db_path.display());
    let settings = Settings {
        host: "127.0.0.1".to_owned(),
        port: 0,
        path: String::new(),
        open_registration: sc.open_registration,
        max_record_size: atuin_common::units::ByteSize::b(sc.max_record_size),
        register_webhook_url: None,
        register_webhook_username: String::new(),
        db_settings: DbSettings { db_uri: db_uri.parse().unwrap(), db_password_file: None },
        metrics: atuin_server::settings::Metrics::default(),
        trusted_proxies: Vec::new(),
        trusted_proxy_header: Settings::DEFAULT_TRUSTED_PROXY_HEADER,
        fake_version: None,
    };
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let addr: SocketAddr = listener.local_addr().unwrap();
    let (tx, rx) = tokio::sync::oneshot::channel::<()>();
    let server = tokio::spawn(async move {
        launch_with_tcp_listener(settings, listener, async {
            let _ = rx.await;
        })
        .await
        .unwrap();
    });
    let http = reqwest::Client::builder().timeout(Duration::from_secs(60)).build().unwrap();
    let base = format!("http://{addr}");
    // Wait for the server (it runs the migrations first).
    for _ in 0..200 {
        if http.get(format!("{base}/healthz")).send().await.is_ok() {
            break;
        }
        tokio::time::sleep(Duration::from_millis(50)).await;
    }
    let pool = SqlitePool::connect(&db_uri).await.unwrap();
    let mut tokens = Vec::new();
    seed_users(&pool, sc.seeded_users, &mut tokens).await;
    let mut h = Harness {
        http,
        base,
        pool,
        cfg: k::Config { open_registration: sc.open_registration, max_record_size: sc.max_record_size },
        state: k::Snapshot {
            users: vec![],
            sessions: vec![],
            history: vec![],
            store: vec![],
            next_user_id: 1,
            next_session_id: 1,
        },
        verified: HashMap::new(),
        tokens,
        rng: ChaCha8Rng::seed_from_u64(seed),
        history_counter: 0,
        stats: BTreeMap::new(),
    };
    h.state = h.dump().await;
    for n in 0..steps {
        h.step(n).await;
    }
    let _ = tx.send(());
    let _ = server.await;
    h.stats
}

#[tokio::main]
async fn main() {
    let args: Vec<String> = std::env::args().collect();
    let get = |flag: &str, default: u64| {
        args.iter().position(|a| a == flag).and_then(|i| args.get(i + 1)).map(|v| v.parse().unwrap()).unwrap_or(default)
    };
    let seed = get("--seed", 1);
    let steps = get("--steps", 300);
    for (i, sc) in SCENARIOS.iter().enumerate() {
        let stats = run(sc, seed * 1000 + i as u64, steps).await;
        println!("scenario {:?} seed {} steps {}: agree", sc.name, seed * 1000 + i as u64, steps);
        for (k, v) in stats {
            println!("  {v:6}  {k}");
        }
    }
}
