//! Kernel row structs as tenant-scoped tables.
//!
//! One struct is one table with primary key `(tenant_id, <key fields>)`.
//! The only SQL is a tenant-filtered SELECT, an upsert, and a delete by key.

use crate::DbError;
use bytes::BytesMut;
use i5h::TenantId;
use i5h_sql::{Stmt, Val, Write as SqlWrite};
use tokio_postgres::types::{to_sql_checked, IsNull, ToSql, Type};
use crate::Tx;
use tokio_postgres::{Row, Transaction};

/// A column value.
#[derive(Clone, Debug, PartialEq)]
pub enum Value {
    Int(i64),
    Bool(bool),
    Text(String),
    Bytes(Vec<u8>),
    Null,
}

impl ToSql for Value {
    fn to_sql(
        &self,
        ty: &Type,
        out: &mut BytesMut,
    ) -> Result<IsNull, Box<dyn std::error::Error + Sync + Send>> {
        match self {
            Value::Int(v) => v.to_sql(ty, out),
            Value::Bool(v) => v.to_sql(ty, out),
            Value::Text(v) => v.to_sql(ty, out),
            Value::Bytes(v) => v.to_sql(ty, out),
            Value::Null => Ok(IsNull::Yes),
        }
    }

    fn accepts(ty: &Type) -> bool {
        matches!(*ty, Type::INT8 | Type::BOOL | Type::TEXT | Type::BYTEA)
    }

    to_sql_checked!();
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Kind {
    Int,
    Bool,
    Text,
    Bytes,
}

impl Kind {
    fn sql(self) -> &'static str {
        match self {
            Kind::Int => "BIGINT",
            Kind::Bool => "BOOLEAN",
            Kind::Text => "TEXT",
            Kind::Bytes => "BYTEA",
        }
    }
}

#[derive(Clone, Debug)]
pub struct ColumnDef {
    pub name: &'static str,
    pub kind: Kind,
    pub nullable: bool,
}

/// How a field is stored. `A` is the app marker type, so apps can implement
/// this for kernel enums without hitting the orphan rule.
pub trait PgField<A>: Sized {
    const KIND: Kind;
    const NULLABLE: bool = false;
    fn to_value(&self) -> Result<Value, DbError>;
    fn from_value(v: &Value) -> Result<Self, DbError>;
}

fn bad(what: &str, v: &Value) -> DbError {
    DbError::Decode(format!("expected {what}, found {v:?}"))
}

macro_rules! int_field {
    ($($t:ty),*) => {$(
        impl<A> PgField<A> for $t {
            const KIND: Kind = Kind::Int;
            fn to_value(&self) -> Result<Value, DbError> {
                i64::try_from(*self)
                    .map(Value::Int)
                    .map_err(|_| DbError::Decode(format!("{} does not fit in BIGINT", self)))
            }
            fn from_value(v: &Value) -> Result<Self, DbError> {
                match v {
                    Value::Int(i) => <$t>::try_from(*i).map_err(|_| bad(stringify!($t), v)),
                    _ => Err(bad(stringify!($t), v)),
                }
            }
        }
    )*};
}
int_field!(u8, u16, u32, u64, i64);

impl<A> PgField<A> for bool {
    const KIND: Kind = Kind::Bool;
    fn to_value(&self) -> Result<Value, DbError> {
        Ok(Value::Bool(*self))
    }
    fn from_value(v: &Value) -> Result<Self, DbError> {
        match v {
            Value::Bool(b) => Ok(*b),
            _ => Err(bad("bool", v)),
        }
    }
}

impl<A> PgField<A> for String {
    const KIND: Kind = Kind::Text;
    fn to_value(&self) -> Result<Value, DbError> {
        Ok(Value::Text(self.clone()))
    }
    fn from_value(v: &Value) -> Result<Self, DbError> {
        match v {
            Value::Text(s) => Ok(s.clone()),
            _ => Err(bad("text", v)),
        }
    }
}

impl<A> PgField<A> for Vec<u8> {
    const KIND: Kind = Kind::Bytes;
    fn to_value(&self) -> Result<Value, DbError> {
        Ok(Value::Bytes(self.clone()))
    }
    fn from_value(v: &Value) -> Result<Self, DbError> {
        match v {
            Value::Bytes(b) => Ok(b.clone()),
            _ => Err(bad("bytes", v)),
        }
    }
}

impl<A, T: PgField<A>> PgField<A> for Option<T> {
    const KIND: Kind = T::KIND;
    const NULLABLE: bool = true;
    fn to_value(&self) -> Result<Value, DbError> {
        match self {
            Some(t) => t.to_value(),
            None => Ok(Value::Null),
        }
    }
    fn from_value(v: &Value) -> Result<Self, DbError> {
        match v {
            Value::Null => Ok(None),
            _ => T::from_value(v).map(Some),
        }
    }
}

/// Column type inferred from a field projection. Used by `table!`.
pub fn column_of<A, R, T: PgField<A>>(name: &'static str, _field: fn(&R) -> &T) -> ColumnDef {
    ColumnDef { name, kind: T::KIND, nullable: T::NULLABLE }
}

/// Implement with [`table!`](crate::table).
pub trait Table<A>: Sized + Send + Sync {
    const NAME: &'static str;
    /// Leading columns that form the key, after `tenant_id`.
    const KEY_LEN: usize;
    fn columns() -> Vec<ColumnDef>;
    fn to_values(&self) -> Result<Vec<Value>, DbError>;
    fn from_values(v: &[Value]) -> Result<Self, DbError>;
}

/// Declares how a kernel row struct maps to a table.
///
/// ```ignore
/// i5h_pg::table!(DocsApp, kernel::Member => "members" { key: [project, user], cols: [role] });
/// ```
///
/// Every field must be listed, or the generated constructor does not compile.
#[macro_export]
macro_rules! table {
    ($app:ty, $row:path => $name:literal { key: [$($k:ident),*], cols: [$($c:ident),* $(,)?] $(,)? }) => {
        impl $crate::Table<$app> for $row {
            const NAME: &'static str = $name;
            const KEY_LEN: usize = 0 $(+ { let _ = stringify!($k); 1 })*;
            fn columns() -> Vec<$crate::ColumnDef> {
                vec![
                    $($crate::column_of::<$app, Self, _>(stringify!($k), |r: &Self| &r.$k),)*
                    $($crate::column_of::<$app, Self, _>(stringify!($c), |r: &Self| &r.$c),)*
                ]
            }
            fn to_values(&self) -> Result<Vec<$crate::Value>, $crate::DbError> {
                Ok(vec![
                    $(<_ as $crate::PgField<$app>>::to_value(&self.$k)?,)*
                    $(<_ as $crate::PgField<$app>>::to_value(&self.$c)?,)*
                ])
            }
            fn from_values(v: &[$crate::Value]) -> Result<Self, $crate::DbError> {
                let mut it = v.iter();
                let mut next = || it.next().ok_or_else(|| $crate::DbError::Decode("short row".into()));
                Ok(Self {
                    $($k: <_ as $crate::PgField<$app>>::from_value(next()?)?,)*
                    $($c: <_ as $crate::PgField<$app>>::from_value(next()?)?,)*
                })
            }
        }
    };
}

/// `CREATE TABLE` statement for `T`.
/// Quoted SQL identifier, so field names like `user` are safe.
fn q(name: &str) -> String {
    format!("\"{}\"", name.replace('"', "\"\""))
}

pub fn ddl<A, T: Table<A>>() -> String {
    let cols = T::columns();
    let mut defs = vec!["tenant_id BIGINT NOT NULL".to_string()];
    for c in &cols {
        let null = if c.nullable { "" } else { " NOT NULL" };
        defs.push(format!("{} {}{}", q(c.name), c.kind.sql(), null));
    }
    let mut key = vec!["tenant_id".to_string()];
    key.extend(cols[..T::KEY_LEN].iter().map(|c| q(c.name)));
    defs.push(format!("PRIMARY KEY ({})", key.join(", ")));
    format!("CREATE TABLE IF NOT EXISTS {} (\n  {}\n)", q(T::NAME), defs.join(",\n  "))
}

fn read_row(cols: &[ColumnDef], row: &Row) -> Result<Vec<Value>, DbError> {
    let mut out = Vec::with_capacity(cols.len());
    for (i, c) in cols.iter().enumerate() {
        let v = match c.kind {
            Kind::Int => row.try_get::<_, Option<i64>>(i)?.map(Value::Int),
            Kind::Bool => row.try_get::<_, Option<bool>>(i)?.map(Value::Bool),
            Kind::Text => row.try_get::<_, Option<String>>(i)?.map(Value::Text),
            Kind::Bytes => row.try_get::<_, Option<Vec<u8>>>(i)?.map(Value::Bytes),
        };
        out.push(v.unwrap_or(Value::Null));
    }
    Ok(out)
}

/// All of the tenant's rows of `T`, in key order.
pub async fn load<A, T: Table<A>>(tx: &Tx<'_>, tenant: TenantId) -> Result<Vec<T>, DbError> {
    let cols = T::columns();
    let names: Vec<_> = cols.iter().map(|c| q(c.name)).collect();
    let order = &names[..T::KEY_LEN];
    let order = if order.is_empty() { String::new() } else { format!(" ORDER BY {}", order.join(", ")) };
    let sql = format!("SELECT {} FROM {} WHERE tenant_id = $1{}", names.join(", "), q(T::NAME), order);
    let tid = tenant_param(tenant)?;
    let rows = tx.0.query(&sql, &[&tid]).await?;
    rows.iter().map(|r| read_row(&cols, r).and_then(|v| T::from_values(&v))).collect()
}

/// The tenant's rows of `T` whose `column` equals `value`, in key order.
/// `column` must be one of `T`'s columns.
pub async fn load_where<A, T: Table<A>>(tx: &Tx<'_>, tenant: TenantId, column: &str, value: Value) -> Result<Vec<T>, DbError> {
    let cols = T::columns();
    if !cols.iter().any(|c| c.name == column) {
        return Err(DbError::Decode(format!("{} has no column {column}", T::NAME)));
    }
    let names: Vec<_> = cols.iter().map(|c| q(c.name)).collect();
    let order = &names[..T::KEY_LEN];
    let order = if order.is_empty() { String::new() } else { format!(" ORDER BY {}", order.join(", ")) };
    let sql = format!(
        "SELECT {} FROM {} WHERE tenant_id = $1 AND {} = $2{}",
        names.join(", "),
        q(T::NAME),
        q(column),
        order
    );
    let tid = tenant_param(tenant)?;
    let rows = tx.0.query(&sql, &[&tid, &value]).await?;
    rows.iter().map(|r| read_row(&cols, r).and_then(|v| T::from_values(&v))).collect()
}

/// Insert or overwrite the tenant's row with `row`'s key.
pub async fn upsert<A, T: Table<A>>(tx: &Tx<'_>, tenant: TenantId, row: &T) -> Result<(), DbError> {
    let vals: Vec<Val> = row.to_values()?.iter().map(to_val).collect();
    let w = SqlWrite::Put { table: 0, key_len: T::KEY_LEN as u32, row: vals };
    run_stmt::<A, T>(tx.0, tenant, planned(w)).await
}

/// Delete the tenant's row of `T` whose key columns equal `key`.
pub async fn delete<A, T: Table<A>>(tx: &Tx<'_>, tenant: TenantId, key: &[Value]) -> Result<(), DbError> {
    let w = SqlWrite::Del { table: 0, key: key.iter().map(to_val).collect() };
    run_stmt::<A, T>(tx.0, tenant, planned(w)).await
}

/// The statement `i5h_sql::plan` (proven in Lean) gives for one write.
fn planned(w: SqlWrite) -> Stmt {
    let mut stmts = i5h_sql::plan(&vec![w]);
    stmts.pop().expect("plan gives one statement per write")
}

// Trusted part of A4: the SQL text for a planned statement. An upsert stores
// `key ++ rest` at `key`; a delete removes the row at `key`. Both are scoped
// to the tenant, whose id is part of every primary key.
async fn run_stmt<A, T: Table<A>>(tx: &Transaction<'_>, tenant: TenantId, stmt: Stmt) -> Result<(), DbError> {
    let cols = T::columns();
    let names: Vec<_> = cols.iter().map(|c| q(c.name)).collect();
    let tid = Value::Int(tenant_param(tenant)?);
    match stmt {
        Stmt::Upsert { key, rest, .. } => {
            if key.len() != T::KEY_LEN || key.len() + rest.len() != cols.len() {
                return Err(DbError::Decode(format!("{}: row does not match its columns", T::NAME)));
            }
            let placeholders: Vec<_> = (2..=cols.len() + 1).map(|i| format!("${i}")).collect();
            let mut conflict = vec!["tenant_id".to_string()];
            conflict.extend(names[..T::KEY_LEN].iter().cloned());
            let rest_names = &names[T::KEY_LEN..];
            // With no non-key columns the stored row equals its key, so keeping it is replacing it.
            let action = if rest_names.is_empty() {
                "DO NOTHING".to_string()
            } else {
                let sets: Vec<_> = rest_names.iter().map(|n| format!("{n} = EXCLUDED.{n}")).collect();
                format!("DO UPDATE SET {}", sets.join(", "))
            };
            let sql = format!(
                "INSERT INTO {} (tenant_id, {}) VALUES ($1, {}) ON CONFLICT ({}) {}",
                q(T::NAME),
                names.join(", "),
                placeholders.join(", "),
                conflict.join(", "),
                action
            );
            let vals = key.iter().chain(rest.iter()).map(from_val).collect::<Result<Vec<_>, _>>()?;
            let mut params: Vec<&(dyn ToSql + Sync)> = vec![&tid];
            params.extend(vals.iter().map(|v| v as &(dyn ToSql + Sync)));
            tx.execute(&sql, &params).await?;
        }
        Stmt::Delete { key, .. } => {
            if key.len() != T::KEY_LEN {
                return Err(DbError::Decode(format!("{}: key has {} values, expected {}", T::NAME, key.len(), T::KEY_LEN)));
            }
            let conds: Vec<_> = names[..T::KEY_LEN].iter().enumerate().map(|(i, n)| format!(" AND {} = ${}", n, i + 2)).collect();
            let sql = format!("DELETE FROM {} WHERE tenant_id = $1{}", q(T::NAME), conds.concat());
            let vals = key.iter().map(from_val).collect::<Result<Vec<_>, _>>()?;
            let mut params: Vec<&(dyn ToSql + Sync)> = vec![&tid];
            params.extend(vals.iter().map(|v| v as &(dyn ToSql + Sync)));
            tx.execute(&sql, &params).await?;
        }
    }
    Ok(())
}

fn to_val(v: &Value) -> Val {
    match v {
        Value::Int(i) => Val::Int(*i),
        Value::Bool(b) => Val::Bool(*b),
        Value::Text(s) => Val::Text(s.clone().into_bytes()),
        Value::Bytes(b) => Val::Bytes(b.clone()),
        Value::Null => Val::Null,
    }
}

fn from_val(v: &Val) -> Result<Value, DbError> {
    Ok(match v {
        Val::Int(i) => Value::Int(*i),
        Val::Bool(b) => Value::Bool(*b),
        Val::Text(b) => Value::Text(String::from_utf8(b.clone()).map_err(|e| DbError::Decode(e.to_string()))?),
        Val::Bytes(b) => Value::Bytes(b.clone()),
        Val::Null => Value::Null,
    })
}

/// Convert a key field for [`delete`].
pub fn key<A, T: PgField<A>>(v: &T) -> Result<Value, DbError> {
    v.to_value()
}

pub(crate) fn tenant_param(t: TenantId) -> Result<i64, DbError> {
    i64::try_from(t.0).map_err(|_| DbError::Decode(format!("tenant id {} out of range", t.0)))
}
