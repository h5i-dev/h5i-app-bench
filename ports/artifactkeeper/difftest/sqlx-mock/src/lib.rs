//! A stand-in for sqlx, so the copied upstream code compiles unchanged. A
//! statement goes, with its binds, to the `Backend` inside the `PgPool`; the
//! difftest's backend evaluates each statement by hand over a snapshot.
use std::fmt;
use std::marker::PhantomData;
use std::sync::Arc;
use uuid::Uuid;

#[derive(Debug, Clone, PartialEq)]
pub enum Value {
    Null,
    Bool(bool),
    Text(String),
    Uuid(Uuid),
    I32(i32),
    I64(i64),
}

#[derive(Debug, Clone, Default)]
pub struct PgRow {
    pub cols: Vec<(&'static str, Value)>,
}

#[derive(Debug)]
pub enum Error {
    PoolTimedOut,
    RowNotFound,
    Decode(String),
    Other(String),
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::PoolTimedOut => write!(f, "pool timed out while waiting for an open connection"),
            Error::RowNotFound => write!(f, "no rows returned by a query that expected to return at least one row"),
            Error::Decode(m) => write!(f, "error occurred while decoding: {m}"),
            Error::Other(m) => write!(f, "{m}"),
        }
    }
}

impl std::error::Error for Error {}

pub type Result<T, E = Error> = std::result::Result<T, E>;

pub trait Backend: Send + Sync {
    fn run(&self, sql: &str, binds: &[Value]) -> Result<Vec<PgRow>>;
    /// Side effects that are not SQL (the audit log).
    fn log(&self, kind: &str, fields: Vec<Value>);
}

#[derive(Clone)]
pub struct PgPool {
    pub backend: Arc<dyn Backend>,
}

impl fmt::Debug for PgPool {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "PgPool")
    }
}

pub struct Postgres;

pub trait Executor<'c> {
    type Database;
    fn pool(&self) -> &PgPool;
}

impl<'c> Executor<'c> for &'c PgPool {
    type Database = Postgres;
    fn pool(&self) -> &PgPool {
        self
    }
}

pub struct AssertSqlSafe<T>(pub T);

pub trait SqlStr {
    fn text(&self) -> String;
}
impl SqlStr for &str {
    fn text(&self) -> String {
        self.to_string()
    }
}
impl SqlStr for AssertSqlSafe<&str> {
    fn text(&self) -> String {
        self.0.to_string()
    }
}
impl SqlStr for AssertSqlSafe<String> {
    fn text(&self) -> String {
        self.0.clone()
    }
}

pub trait Encode {
    fn value(self) -> Value;
}
impl Encode for &str {
    fn value(self) -> Value {
        Value::Text(self.to_string())
    }
}
impl Encode for String {
    fn value(self) -> Value {
        Value::Text(self)
    }
}
impl Encode for &String {
    fn value(self) -> Value {
        Value::Text(self.clone())
    }
}
impl Encode for Uuid {
    fn value(self) -> Value {
        Value::Uuid(self)
    }
}
impl Encode for Option<String> {
    fn value(self) -> Value {
        match self {
            Some(s) => Value::Text(s),
            None => Value::Null,
        }
    }
}
impl Encode for bool {
    fn value(self) -> Value {
        Value::Bool(self)
    }
}

pub trait Decode: Sized {
    fn decode(v: &Value) -> Result<Self>;
}
impl Decode for bool {
    fn decode(v: &Value) -> Result<Self> {
        match v {
            Value::Bool(b) => Ok(*b),
            _ => Err(Error::Decode(format!("bool from {v:?}"))),
        }
    }
}
impl Decode for String {
    fn decode(v: &Value) -> Result<Self> {
        match v {
            Value::Text(s) => Ok(s.clone()),
            _ => Err(Error::Decode(format!("text from {v:?}"))),
        }
    }
}
impl Decode for Uuid {
    fn decode(v: &Value) -> Result<Self> {
        match v {
            Value::Uuid(u) => Ok(*u),
            _ => Err(Error::Decode(format!("uuid from {v:?}"))),
        }
    }
}
impl Decode for i32 {
    fn decode(v: &Value) -> Result<Self> {
        match v {
            Value::I32(i) => Ok(*i),
            _ => Err(Error::Decode(format!("int4 from {v:?}"))),
        }
    }
}
impl Decode for i64 {
    fn decode(v: &Value) -> Result<Self> {
        match v {
            Value::I64(i) => Ok(*i),
            _ => Err(Error::Decode(format!("int8 from {v:?}"))),
        }
    }
}
impl<T: Decode> Decode for Option<T> {
    fn decode(v: &Value) -> Result<Self> {
        match v {
            Value::Null => Ok(None),
            _ => T::decode(v).map(Some),
        }
    }
}

pub trait ColumnIndex {
    fn find<'r>(&self, row: &'r PgRow) -> Result<&'r Value>;
}
impl ColumnIndex for &str {
    fn find<'r>(&self, row: &'r PgRow) -> Result<&'r Value> {
        row.cols
            .iter()
            .find(|(n, _)| n == self)
            .map(|(_, v)| v)
            .ok_or_else(|| Error::Other(format!("no column {self}")))
    }
}
impl ColumnIndex for usize {
    fn find<'r>(&self, row: &'r PgRow) -> Result<&'r Value> {
        row.cols.get(*self).map(|(_, v)| v).ok_or_else(|| Error::Other(format!("no column {self}")))
    }
}

pub trait Row {
    fn get<T: Decode, I: ColumnIndex>(&self, index: I) -> T;
    fn try_get<T: Decode, I: ColumnIndex>(&self, index: I) -> Result<T>;
}
impl Row for PgRow {
    fn get<T: Decode, I: ColumnIndex>(&self, index: I) -> T {
        self.try_get(index).expect("column decodes")
    }
    fn try_get<T: Decode, I: ColumnIndex>(&self, index: I) -> Result<T> {
        T::decode(index.find(self)?)
    }
}

pub trait FromRow: Sized {
    fn from_row(row: &PgRow) -> Result<Self>;
}
impl<A: Decode> FromRow for (A,) {
    fn from_row(row: &PgRow) -> Result<Self> {
        Ok((row.try_get(0usize)?,))
    }
}
impl<A: Decode, B: Decode, C: Decode> FromRow for (A, B, C) {
    fn from_row(row: &PgRow) -> Result<Self> {
        Ok((row.try_get(0usize)?, row.try_get(1usize)?, row.try_get(2usize)?))
    }
}

pub struct Query {
    sql: String,
    binds: Vec<Value>,
}

pub fn query(sql: impl SqlStr) -> Query {
    Query { sql: sql.text(), binds: Vec::new() }
}

impl Query {
    pub fn bind<T: Encode>(mut self, v: T) -> Self {
        self.binds.push(v.value());
        self
    }
    fn run<'c, E: Executor<'c>>(&self, e: E) -> Result<Vec<PgRow>> {
        e.pool().backend.run(&self.sql, &self.binds)
    }
    pub async fn fetch_optional<'c, E: Executor<'c>>(self, e: E) -> Result<Option<PgRow>> {
        Ok(self.run(e)?.into_iter().next())
    }
    pub async fn fetch_one<'c, E: Executor<'c>>(self, e: E) -> Result<PgRow> {
        self.run(e)?.into_iter().next().ok_or(Error::RowNotFound)
    }
    pub async fn fetch_all<'c, E: Executor<'c>>(self, e: E) -> Result<Vec<PgRow>> {
        self.run(e)
    }
}

pub struct QueryScalar<DB, O> {
    q: Query,
    _t: PhantomData<(DB, O)>,
}

pub fn query_scalar<DB, O>(sql: impl SqlStr) -> QueryScalar<DB, O> {
    QueryScalar { q: query(sql), _t: PhantomData }
}

impl<DB, O: Decode> QueryScalar<DB, O> {
    pub fn bind<T: Encode>(mut self, v: T) -> Self {
        self.q = self.q.bind(v);
        self
    }
    pub async fn fetch_one<'c, E: Executor<'c, Database = DB>>(self, e: E) -> Result<O> {
        let row = self.q.run(e)?.into_iter().next().ok_or(Error::RowNotFound)?;
        row.try_get(0usize)
    }
    pub async fn fetch_optional<'c, E: Executor<'c, Database = DB>>(self, e: E) -> Result<Option<O>> {
        match self.q.run(e)?.into_iter().next() {
            Some(row) => Ok(Some(row.try_get(0usize)?)),
            None => Ok(None),
        }
    }
}

pub struct QueryAs<DB, O> {
    q: Query,
    _t: PhantomData<(DB, O)>,
}

pub fn query_as<DB, O>(sql: impl SqlStr) -> QueryAs<DB, O> {
    QueryAs { q: query(sql), _t: PhantomData }
}

impl<DB, O: FromRow> QueryAs<DB, O> {
    pub fn bind<T: Encode>(mut self, v: T) -> Self {
        self.q = self.q.bind(v);
        self
    }
    pub async fn fetch_one<'c, E: Executor<'c, Database = DB>>(self, e: E) -> Result<O> {
        let row = self.q.run(e)?.into_iter().next().ok_or(Error::RowNotFound)?;
        O::from_row(&row)
    }
    pub async fn fetch_optional<'c, E: Executor<'c, Database = DB>>(self, e: E) -> Result<Option<O>> {
        match self.q.run(e)?.into_iter().next() {
            Some(row) => Ok(Some(O::from_row(&row)?)),
            None => Ok(None),
        }
    }
    pub async fn fetch_all<'c, E: Executor<'c, Database = DB>>(self, e: E) -> Result<Vec<O>> {
        self.q.run(e)?.iter().map(O::from_row).collect()
    }
}
