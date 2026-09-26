//! Plans the statements a write set runs, independent of SQL text.
//!
//! Extracted to Lean (see `proofs/`). Aeneas subset: no `?`, no `String`,
//! no iterator adapters; loops are `while` over indices.

/// A column value. Text is kept as UTF-8 bytes.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Val {
    Int(i64),
    Bool(bool),
    Text(Vec<u8>),
    Bytes(Vec<u8>),
    Null,
}

/// How a kernel field is stored. Integers keep their bits: a `u64` above
/// `i64::MAX` is stored as a negative `BIGINT`.
pub trait Column {
    fn to_val(&self) -> Val;
}

impl Column for u64 {
    fn to_val(&self) -> Val {
        Val::Int(*self as i64)
    }
}

impl Column for u32 {
    fn to_val(&self) -> Val {
        Val::Int(*self as i64)
    }
}

impl Column for bool {
    fn to_val(&self) -> Val {
        Val::Bool(*self)
    }
}

impl Column for Vec<u8> {
    fn to_val(&self) -> Val {
        Val::Bytes(self.clone())
    }
}

impl<T: Column> Column for Option<T> {
    fn to_val(&self) -> Val {
        match self {
            Some(x) => x.to_val(),
            None => Val::Null,
        }
    }
}

/// One row-level write on a tenant's table.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Write {
    /// Insert or replace the row whose first `key_len` columns are its key.
    Put { table: u32, key_len: u32, row: Vec<Val> },
    /// Remove the row with this key, if any.
    Del { table: u32, key: Vec<Val> },
}

/// A keyed statement. `Upsert` stores `key ++ rest` at `key`.
#[derive(Clone, Debug, PartialEq, Eq)]
pub enum Stmt {
    Upsert { table: u32, key: Vec<Val>, rest: Vec<Val> },
    Delete { table: u32, key: Vec<Val> },
}

/// The first `n` values of `row` (all of them if the row is shorter).
pub fn prefix(row: &Vec<Val>, n: usize) -> Vec<Val> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < row.len() && i < n {
        out.push(row[i].clone());
        i += 1;
    }
    out
}

/// The values of `row` after the first `n`.
pub fn suffix(row: &Vec<Val>, n: usize) -> Vec<Val> {
    let mut out = Vec::new();
    let mut i = n;
    while i < row.len() {
        out.push(row[i].clone());
        i += 1;
    }
    out
}

pub fn plan_one(w: &Write) -> Stmt {
    match w {
        Write::Put { table, key_len, row } => {
            let n = *key_len as usize;
            Stmt::Upsert { table: *table, key: prefix(row, n), rest: suffix(row, n) }
        }
        Write::Del { table, key } => Stmt::Delete { table: *table, key: key.clone() },
    }
}

/// One statement per write, in order.
pub fn plan(ws: &Vec<Write>) -> Vec<Stmt> {
    let mut out = Vec::new();
    let mut i = 0;
    while i < ws.len() {
        out.push(plan_one(&ws[i]));
        i += 1;
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn splits_key_from_rest() {
        let row = vec![Val::Int(1), Val::Int(2), Val::Text(b"x".to_vec())];
        let ws = vec![Write::Put { table: 3, key_len: 2, row }, Write::Del { table: 3, key: vec![Val::Int(1)] }];
        assert_eq!(
            plan(&ws),
            vec![
                Stmt::Upsert { table: 3, key: vec![Val::Int(1), Val::Int(2)], rest: vec![Val::Text(b"x".to_vec())] },
                Stmt::Delete { table: 3, key: vec![Val::Int(1)] },
            ]
        );
    }
}
