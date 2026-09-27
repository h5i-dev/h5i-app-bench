//! The ledger's shell: it connects the kernel to PostgreSQL and JSON and
//! makes no decisions of its own.

use axum::http::StatusCode;
use i5h::{Kernel, TenantId};
use i5h_json::Value as Out;
use i5h_pg::{load, upsert, DbError, ReplyCodec, Store, Tx};
use ledger_kernel as k;
use serde::{Deserialize, Serialize};

/// Marker type the framework's traits hang off.
pub struct Ledger;

impl Kernel for Ledger {
    type Principal = k::Principal;
    type Snapshot = k::Snapshot;
    type Command = k::Command;
    type WriteSet = Vec<k::Write>;
    type Reply = k::Reply;
    type Error = k::Error;

    fn tenant(actor: &k::Principal) -> TenantId {
        TenantId(actor.org)
    }

    fn transition(actor: &k::Principal, snap: &k::Snapshot, cmd: &k::Command) -> Result<(Vec<k::Write>, k::Reply), k::Error> {
        k::transition(actor, snap, cmd)
    }

    fn apply(snap: &k::Snapshot, ws: &Vec<k::Write>) -> k::Snapshot {
        k::apply(snap, ws)
    }
}

pub fn principal(org: u64, user: u64) -> k::Principal {
    k::Principal { org, user }
}

// The `accounts` and `ledger` tables, from the kernel's `schema!`.
ledger_kernel::ledger_tables!(Ledger);

pub struct LedgerStore;

impl Store<Ledger> for LedgerStore {
    fn ddl() -> Vec<String> {
        schema_ddl()
    }

    fn tables() -> Vec<&'static str> {
        schema_tables()
    }

    async fn load(tx: &Tx<'_>, t: TenantId) -> Result<k::Snapshot, DbError> {
        Ok(k::Snapshot {
            ledger: load::<Ledger, k::Ledger>(tx, t).await?.pop().unwrap_or_default(),
            accounts: load::<Ledger, _>(tx, t).await?,
        })
    }

    async fn write(tx: &Tx<'_>, t: TenantId, ws: &Vec<k::Write>) -> Result<(), DbError> {
        for w in ws {
            match w {
                k::Write::PutAccount(a) => upsert::<Ledger, _>(tx, t, a).await?,
                k::Write::SetLedger(l) => upsert::<Ledger, _>(tx, t, l).await?,
            }
        }
        Ok(())
    }
}

/// The JSON a client sends, e.g. `{"cmd":"deposit","account":0,"amount":100}`.
#[derive(Deserialize)]
#[serde(tag = "cmd", rename_all = "snake_case", deny_unknown_fields)]
enum CommandJson {
    Open,
    Deposit { account: u64, amount: u64 },
    Withdraw { account: u64, amount: u64 },
    Transfer { from: u64, to: u64, amount: u64 },
    List,
}

impl From<CommandJson> for k::Command {
    fn from(c: CommandJson) -> Self {
        match c {
            CommandJson::Open => k::Command::Open,
            CommandJson::Deposit { account, amount } => k::Command::Deposit { account, amount },
            CommandJson::Withdraw { account, amount } => k::Command::Withdraw { account, amount },
            CommandJson::Transfer { from, to, amount } => k::Command::Transfer { src: from, dst: to, amount },
            CommandJson::List => k::Command::List,
        }
    }
}

fn account_json(a: &k::Account) -> Out {
    Out::obj([("id", a.id.into()), ("owner", a.owner.into()), ("balance", a.balance.into())])
}

impl i5h_http::Api<Ledger> for LedgerStore {
    fn decode_command(body: serde_json::Value) -> Result<k::Command, String> {
        serde_json::from_value::<CommandJson>(body).map(Into::into).map_err(|e| e.to_string())
    }

    fn encode_reply(r: &k::Reply) -> Out {
        match r {
            k::Reply::Created(id) => Out::obj([("id", (*id).into())]),
            k::Reply::Balance(b) => Out::obj([("balance", (*b).into())]),
            k::Reply::Accounts(accs) => Out::Arr(accs.iter().map(account_json).collect()),
        }
    }

    fn encode_error(e: &k::Error) -> (StatusCode, Out) {
        let (status, code) = match e {
            k::Error::NotFound => (StatusCode::NOT_FOUND, "not_found"),
            k::Error::Forbidden => (StatusCode::FORBIDDEN, "forbidden"),
            k::Error::Insufficient => (StatusCode::CONFLICT, "insufficient_funds"),
            k::Error::SameAccount => (StatusCode::UNPROCESSABLE_ENTITY, "same_account"),
            k::Error::Overflow => (StatusCode::UNPROCESSABLE_ENTITY, "overflow"),
        };
        (status, i5h_http::error_body(code))
    }
}

/// Stored replies for idempotent retries.
#[derive(Serialize, Deserialize)]
enum StoredReply {
    Created(u64),
    Balance(u64),
    Accounts(Vec<(u64, u64, u64)>),
}

impl ReplyCodec<Ledger> for LedgerStore {
    fn fingerprint(cmd: &k::Command) -> Vec<u8> {
        format!("{cmd:?}").into_bytes()
    }

    fn scope(actor: &k::Principal) -> String {
        format!("u{}", actor.user)
    }

    fn encode(r: &k::Reply) -> Vec<u8> {
        let stored = match r {
            k::Reply::Created(id) => StoredReply::Created(*id),
            k::Reply::Balance(b) => StoredReply::Balance(*b),
            k::Reply::Accounts(accs) => StoredReply::Accounts(accs.iter().map(|a| (a.id, a.owner, a.balance)).collect()),
        };
        serde_json::to_vec(&stored).expect("stored replies serialize")
    }

    fn decode(b: &[u8]) -> Result<k::Reply, String> {
        Ok(match serde_json::from_slice(b).map_err(|e| e.to_string())? {
            StoredReply::Created(id) => k::Reply::Created(id),
            StoredReply::Balance(b) => k::Reply::Balance(b),
            StoredReply::Accounts(accs) => {
                k::Reply::Accounts(accs.into_iter().map(|(id, owner, balance)| k::Account { id, owner, balance }).collect())
            }
        })
    }
}
