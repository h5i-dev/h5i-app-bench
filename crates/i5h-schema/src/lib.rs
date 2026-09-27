//! One declaration for a kernel's snapshot and row types.
//!
//! ```ignore
//! i5h_schema::schema! {
//!     mapping board_tables for board_kernel, writes Write, lean "../proofs/generated/Schema.lean";
//!
//!     #[derive(Clone, Debug, Default, PartialEq, Eq)]
//!     pub struct Snapshot {
//!         counter: Counter,
//!         posts: Vec<Post>,
//!     }
//!
//!     #[derive(Clone, Debug, PartialEq, Eq)]
//!     pub struct Post in "posts" {
//!         key { id: u64 }
//!         author: u64,
//!         text: Text,
//!     }
//!
//!     #[derive(Clone, Copy, Debug, PartialEq, Eq, Default)]
//!     pub struct Counter in "counters" {
//!         key {}
//!         next_id: u64,
//!     }
//! }
//! ```
//!
//! Each row struct is defined with its key fields first, exactly as written,
//! so the kernel stays plain Rust for Aeneas. It gets `TABLE` (its number, in
//! declaration order), `KEY_LEN`, its SQL encoding `to_row`/`from_row` (via
//! `i5h_sql::Column`), and `sql_put`, the table write that stores it. A row
//! with key fields also gets the table operations a kernel's `apply_write` is
//! made of: `put` (insert, or replace the row with the same key), `del` (by
//! key), `del_where` (by the encoded value of one column), and their table
//! writes `sql_del` and `sql_del_where`. A row without key fields is a
//! singleton: the snapshot holds one, and a fresh tenant's is all zeros.
//!
//! The optional snapshot struct lists one field per row type: `Vec<Row>`, or
//! the row itself for a singleton. It gets `Rows` (a tenant's stored rows per
//! table) and `decode`, which turns them back into a snapshot. With
//! `writes Write`, the kernel defines `apply_write(&mut Snapshot, Write)` and
//! `sql_write(&Write, &mut Vec<i5h_sql::Write>)`, and `schema!` defines
//! `apply` and `sql_writes`, which run them over a write set in order.
//!
//! `lean "path"` keeps that Lean file current: the row encodings and a lemma
//! for every generated function, which the app's `Apply.lean` and
//! `Storage.lean` use. A generated test checks it; `I5H_BLESS=1` rewrites it.
//!
//! The server crate gets a macro: `board_kernel::board_tables!(Board);`
//! expands to an `i5h_pg::table!` mapping per row type, `schema_ddl()`,
//! `schema_tables()`, `schema_write()` (run table writes), and with a
//! snapshot `schema_load()` (load and `decode`), and with writes
//! `schema_store()` (store a write set's `sql_writes`).

#[doc(hidden)]
pub mod lean;

#[macro_export]
macro_rules! schema {
    (
        mapping $mapping:ident for $krate:ident $(, writes $w:ident)? $(, lean $lean:literal)?;
        $(#[$sattr:meta])*
        $svis:vis struct $snap:ident { $($sfields:tt)* }
        $($rows:tt)*
    ) => {
        $crate::__snapshot! {
            @parse [$mapping $krate [$($w)?] [$($lean)?]] [$(#[$sattr])*] [$svis] $snap [] [$($sfields)*] [$($rows)*]
        }
    };
    (
        mapping $mapping:ident for $krate:ident $(, writes $w:ident)? $(, lean $lean:literal)?;
        $($rows:tt)*
    ) => {
        $crate::__schema! { [$mapping $krate [$($w)?] [$($lean)?]] [] $($rows)* }
    };
}

/// Reads the snapshot's fields, `name: Vec<Row>` or `name: Row`, into
/// `[name Row]` pairs.
#[doc(hidden)]
#[macro_export]
macro_rules! __snapshot {
    (@parse $hdr:tt $sattr:tt $svis:tt $snap:ident [$($acc:tt)*] [] [$($rows:tt)*]) => {
        $crate::__schema! { $hdr [$sattr $svis $snap [$($acc)*]] $($rows)* }
    };
    (@parse $hdr:tt $sattr:tt $svis:tt $snap:ident [$($acc:tt)*]
        [$(#[$fa:meta])* $fv:vis $f:ident : Vec<$t:ident> $(, $($more:tt)*)?] $rows:tt) => {
        $crate::__snapshot! { @parse $hdr $sattr $svis $snap [$($acc)* [[$(#[$fa])*] $f $t [Vec<$t>]]] [$($($more)*)?] $rows }
    };
    (@parse $hdr:tt $sattr:tt $svis:tt $snap:ident [$($acc:tt)*]
        [$(#[$fa:meta])* $fv:vis $f:ident : $t:ident $(, $($more:tt)*)?] $rows:tt) => {
        $crate::__snapshot! { @parse $hdr $sattr $svis $snap [$($acc)* [[$(#[$fa])*] $f $t [$t]]] [$($($more)*)?] $rows }
    };
}

#[doc(hidden)]
#[macro_export]
macro_rules! __schema {
    (
        [$mapping:ident $krate:ident [$($w:ident)?] [$($lean:literal)?]] $snap:tt
        $(
            $(#[$attr:meta])*
            $vis:vis struct $name:ident in $table:literal {
                key { $($(#[$kattr:meta])* $k:ident : $kt:ty),* $(,)? }
                $($(#[$cattr:meta])* $c:ident : $ct:ty),* $(,)?
            }
        )*
    ) => {
        $(
            $(#[$attr])*
            $vis struct $name {
                $($(#[$kattr])* pub $k: $kt,)*
                $($(#[$cattr])* pub $c: $ct,)*
            }
        )*
        $crate::__rows! { [] $( $name [$($k)*] [$($c)*] )* }
        $( $crate::__keyed! { $name [$($k : $kt),*] [$($c)*] } )*
        $crate::__snap_items! { [$($w)?] $snap }
        $crate::__lean! { [$($lean)?] $krate [$($w)?] $snap; $( $name $table [$($k : $kt),*] [$($c : $ct),*] )* }
        $crate::__mapping! { ($) $mapping $krate [$($w)?] $snap; $( $name $table [$($k)*] [$($c)*] )* }
    };
}

/// Per row type: its table number (declaration order), key length, and
/// encoding as SQL values (key first) with its inverse. Plain Rust, so Aeneas extracts it.
#[doc(hidden)]
#[macro_export]
macro_rules! __rows {
    ([$($i:tt)*]) => {};
    ([$($i:tt)*] $name:ident [$($k:ident)*] [$($c:ident)*] $($rest:tt)*) => {
        impl $name {
            pub const TABLE: u32 = $crate::__count!($($i)*);
            pub const KEY_LEN: u32 = $crate::__count!($($k)*);

            pub fn to_row(&self) -> Vec<::i5h_sql::Val> {
                let mut out = Vec::new();
                $(out.push(::i5h_sql::Column::to_val(&self.$k));)*
                $(out.push(::i5h_sql::Column::to_val(&self.$c));)*
                out
            }

            /// Inverse of `to_row`; `None` if the row has the wrong shape.
            pub fn from_row(row: &Vec<::i5h_sql::Val>) -> Option<Self> {
                if row.len() != 0 $(+ $crate::__one!($k))* $(+ $crate::__one!($c))* {
                    return None;
                }
                let mut i: usize = 0;
                $(
                    let $k = match ::i5h_sql::Column::from_val(&row[i]) {
                        Some(x) => x,
                        None => return None,
                    };
                    i += 1;
                )*
                $(
                    let $c = match ::i5h_sql::Column::from_val(&row[i]) {
                        Some(x) => x,
                        None => return None,
                    };
                    i += 1;
                )*
                let _ = i;
                Some($name { $($k,)* $($c,)* })
            }

            /// Every row decoded, in order; `None` if any row fails.
            pub fn from_rows(rows: &Vec<Vec<::i5h_sql::Val>>) -> Option<Vec<Self>> {
                let mut out = Vec::new();
                let mut ok = true;
                let mut i = 0;
                while i < rows.len() {
                    match Self::from_row(&rows[i]) {
                        Some(x) => out.push(x),
                        None => ok = false,
                    }
                    i += 1;
                }
                if ok {
                    Some(out)
                } else {
                    None
                }
            }

            /// The table write that stores this row.
            pub fn sql_put(&self) -> ::i5h_sql::Write {
                ::i5h_sql::Write::Put { table: Self::TABLE, key_len: Self::KEY_LEN, row: self.to_row() }
            }
        }
        $crate::__rows! { [$($i)* $name] $($rest)* }
    };
}

/// Table operations. A row with key fields gets `put`, `del` and
/// `del_where` and their table writes; a singleton gets `from_one`, which
/// reads its table's one row, or all zeros for a fresh tenant.
#[doc(hidden)]
#[macro_export]
macro_rules! __keyed {
    ($name:ident [] [$($c:ident)*]) => {
        impl $name {
            /// The table's row; a fresh tenant has none, which reads as zeros.
            pub fn from_one(rows: &Vec<Vec<::i5h_sql::Val>>) -> Option<Self> {
                if rows.len() == 0 {
                    Some($name { $($c: ::i5h_sql::Zero::zero(),)* })
                } else if rows.len() == 1 {
                    Self::from_row(&rows[0])
                } else {
                    None
                }
            }
        }
    };
    ($name:ident [$($k:ident : $kt:ty),+] [$($c:ident)*]) => {
        impl $name {
            /// Insert `x`, or replace the row with its key.
            pub fn put(v: &mut Vec<Self>, x: Self) {
                let mut i = 0;
                while i < v.len() {
                    if $(v[i].$k == x.$k)&&+ {
                        v[i] = x;
                        return;
                    }
                    i += 1;
                }
                v.push(x);
            }

            /// The rows without this key.
            pub fn del(v: &Vec<Self>, $($k: $kt),+) -> Vec<Self> {
                let mut out = Vec::new();
                let mut i = 0;
                while i < v.len() {
                    if !($(v[i].$k == $k)&&+) {
                        out.push(v[i].clone());
                    }
                    i += 1;
                }
                out
            }

            /// The rows whose column `col` (in `to_row` order) does not hold `val`.
            pub fn del_where(v: &Vec<Self>, col: u32, val: &::i5h_sql::Val) -> Vec<Self> {
                let mut out = Vec::new();
                let mut i = 0;
                while i < v.len() {
                    if !::i5h_sql::has_col(&v[i].to_row(), col, val) {
                        out.push(v[i].clone());
                    }
                    i += 1;
                }
                out
            }

            /// The table write that deletes the row with this key.
            pub fn sql_del($($k: $kt),+) -> ::i5h_sql::Write {
                let mut key = Vec::new();
                $(key.push(::i5h_sql::Column::to_val(&$k));)+
                ::i5h_sql::Write::Del { table: Self::TABLE, key }
            }

            /// The table write that deletes the rows whose column `col` holds `val`.
            pub fn sql_del_where(col: u32, val: ::i5h_sql::Val) -> ::i5h_sql::Write {
                ::i5h_sql::Write::DelWhere { table: Self::TABLE, col, val }
            }
        }
    };
}

/// The snapshot struct, its stored rows and `decode`; with writes, `apply`
/// and `sql_writes`.
#[doc(hidden)]
#[macro_export]
macro_rules! __snap_items {
    ([$($w:ident)?] []) => {};
    ([] [[$(#[$sattr:meta])*] [$svis:vis] $snap:ident [$([[$(#[$fa:meta])*] $f:ident $t:ident [$($ty:tt)*]])*]]) => {
        $(#[$sattr])*
        $svis struct $snap {
            $($(#[$fa])* pub $f: $($ty)*,)*
        }

        /// A tenant's stored rows, table by table, in the order the database
        /// returned them.
        #[derive(Clone, Debug, Default, PartialEq, Eq)]
        pub struct Rows {
            $(pub $f: Vec<Vec<::i5h_sql::Val>>,)*
        }

        /// The snapshot stored rows stand for; `None` if a row does not decode.
        pub fn decode(r: &Rows) -> Option<$snap> {
            $(
                let $f = match $crate::__from_table!($t [$($ty)*] &r.$f) {
                    Some(x) => x,
                    None => return None,
                };
            )*
            Some($snap { $($f,)* })
        }
    };
    ([$w:ident] [[$(#[$sattr:meta])*] [$svis:vis] $snap:ident $fields:tt]) => {
        $crate::__snap_items! { [] [[$(#[$sattr])*] [$svis] $snap $fields] }

        /// What committing a write set means: `apply_write` on each write, in
        /// order. The PostgreSQL store must agree.
        pub fn apply(snap: &$snap, ws: &Vec<$w>) -> $snap {
            let mut s = snap.clone();
            let mut i = 0;
            while i < ws.len() {
                apply_write(&mut s, ws[i].clone());
                i += 1;
            }
            s
        }

        /// The table writes of a write set: `sql_write` on each write, in
        /// order. The server runs exactly these.
        pub fn sql_writes(ws: &Vec<$w>) -> Vec<::i5h_sql::Write> {
            let mut out = Vec::new();
            let mut i = 0;
            while i < ws.len() {
                sql_write(&ws[i], &mut out);
                i += 1;
            }
            out
        }
    };
}

#[doc(hidden)]
#[macro_export]
macro_rules! __from_table {
    ($t:ident [Vec<$t2:ident>] $e:expr) => {
        $t::from_rows($e)
    };
    ($t:ident [$t2:ident] $e:expr) => {
        $t::from_one($e)
    };
}

/// With `lean "path"`: a function rendering the Lean side of the schema, and
/// a test that the file at `path` (relative to the kernel crate) is current.
#[doc(hidden)]
#[macro_export]
macro_rules! __lean {
    ([] $($rest:tt)*) => {};
    ([$lean:literal] $krate:ident [$($w:ident)?] $snap:tt; $( $name:ident $table:literal [$($k:ident : $kt:ty),*] [$($c:ident : $ct:ty),*] )*) => {
        #[doc(hidden)]
        pub fn __i5h_lean_schema() -> ::std::string::String {
            let rows: ::std::vec::Vec<$crate::lean::RowDecl> = ::std::vec![
                $( (
                    stringify!($name),
                    $table,
                    ::std::vec![
                        $((stringify!($k), ::std::any::type_name::<$kt>()),)*
                        $((stringify!($c), ::std::any::type_name::<$ct>()),)*
                    ],
                    0 $(+ $crate::__one!($k))*,
                ), )*
            ];
            let snap: ::std::option::Option<(&str, ::std::vec::Vec<(&str, &str)>)> = $crate::__lean_snap!($snap);
            let writes: ::std::option::Option<&str> = $crate::__lean_opt!($($w)?);
            $crate::lean::render(stringify!($krate), &rows, snap.as_ref(), writes)
        }

        #[cfg(test)]
        #[test]
        fn i5h_lean_schema_is_current() {
            $crate::lean::check(concat!(env!("CARGO_MANIFEST_DIR"), "/", $lean), &__i5h_lean_schema());
        }
    };
}

#[doc(hidden)]
#[macro_export]
macro_rules! __lean_snap {
    ([]) => {
        ::std::option::Option::None
    };
    ([$sattr:tt $svis:tt $snap:ident [$([$fa:tt $f:ident $t:ident $ty:tt])*]]) => {
        ::std::option::Option::Some((stringify!($snap), ::std::vec![$((stringify!($f), stringify!($t)),)*]))
    };
}

#[doc(hidden)]
#[macro_export]
macro_rules! __lean_opt {
    () => {
        ::std::option::Option::None
    };
    ($w:ident) => {
        ::std::option::Option::Some(stringify!($w))
    };
}

/// The number of tokens, as a literal, so Aeneas sees a plain constant.
#[doc(hidden)]
#[macro_export]
#[rustfmt::skip]
macro_rules! __count {
    () => { 0 };
    ($x0:tt) => { 1 };
    ($x0:tt $x1:tt) => { 2 };
    ($x0:tt $x1:tt $x2:tt) => { 3 };
    ($x0:tt $x1:tt $x2:tt $x3:tt) => { 4 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt) => { 5 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt) => { 6 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt) => { 7 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt) => { 8 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt) => { 9 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt) => { 10 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt) => { 11 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt) => { 12 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt) => { 13 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt) => { 14 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt) => { 15 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt) => { 16 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt) => { 17 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt) => { 18 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt) => { 19 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt) => { 20 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt) => { 21 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt) => { 22 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt) => { 23 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt) => { 24 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt $x24:tt) => { 25 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt $x24:tt $x25:tt) => { 26 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt $x24:tt $x25:tt $x26:tt) => { 27 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt $x24:tt $x25:tt $x26:tt $x27:tt) => { 28 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt $x24:tt $x25:tt $x26:tt $x27:tt $x28:tt) => { 29 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt $x24:tt $x25:tt $x26:tt $x27:tt $x28:tt $x29:tt) => { 30 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt $x24:tt $x25:tt $x26:tt $x27:tt $x28:tt $x29:tt $x30:tt) => { 31 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt $x24:tt $x25:tt $x26:tt $x27:tt $x28:tt $x29:tt $x30:tt $x31:tt) => { 32 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt $x24:tt $x25:tt $x26:tt $x27:tt $x28:tt $x29:tt $x30:tt $x31:tt $x32:tt) => { 33 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt $x24:tt $x25:tt $x26:tt $x27:tt $x28:tt $x29:tt $x30:tt $x31:tt $x32:tt $x33:tt) => { 34 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt $x24:tt $x25:tt $x26:tt $x27:tt $x28:tt $x29:tt $x30:tt $x31:tt $x32:tt $x33:tt $x34:tt) => { 35 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt $x24:tt $x25:tt $x26:tt $x27:tt $x28:tt $x29:tt $x30:tt $x31:tt $x32:tt $x33:tt $x34:tt $x35:tt) => { 36 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt $x24:tt $x25:tt $x26:tt $x27:tt $x28:tt $x29:tt $x30:tt $x31:tt $x32:tt $x33:tt $x34:tt $x35:tt $x36:tt) => { 37 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt $x24:tt $x25:tt $x26:tt $x27:tt $x28:tt $x29:tt $x30:tt $x31:tt $x32:tt $x33:tt $x34:tt $x35:tt $x36:tt $x37:tt) => { 38 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt $x24:tt $x25:tt $x26:tt $x27:tt $x28:tt $x29:tt $x30:tt $x31:tt $x32:tt $x33:tt $x34:tt $x35:tt $x36:tt $x37:tt $x38:tt) => { 39 };
    ($x0:tt $x1:tt $x2:tt $x3:tt $x4:tt $x5:tt $x6:tt $x7:tt $x8:tt $x9:tt $x10:tt $x11:tt $x12:tt $x13:tt $x14:tt $x15:tt $x16:tt $x17:tt $x18:tt $x19:tt $x20:tt $x21:tt $x22:tt $x23:tt $x24:tt $x25:tt $x26:tt $x27:tt $x28:tt $x29:tt $x30:tt $x31:tt $x32:tt $x33:tt $x34:tt $x35:tt $x36:tt $x37:tt $x38:tt $x39:tt) => { 40 };
}

#[doc(hidden)]
#[macro_export]
macro_rules! __one {
    ($x:ident) => {
        1
    };
}

/// Defines the mapping macro. The `$` token is passed in so the generated
/// macro can have its own `$app` parameter.
#[doc(hidden)]
#[macro_export]
macro_rules! __mapping {
    (($d:tt) $mapping:ident $krate:ident [$($w:ident)?] $snap:tt; $( $name:ident $table:literal [$($k:ident)*] [$($c:ident)*] )*) => {
        #[macro_export]
        macro_rules! $mapping {
            ($d app:ty) => {
                $( ::i5h_pg::table!($d app, $krate::$name => $table { key: [$($k),*], cols: [$($c),*] }); )*

                /// `CREATE TABLE` statements for every row type in the schema.
                fn schema_ddl() -> ::std::vec::Vec<::std::string::String> {
                    ::std::vec![ $( ::i5h_pg::ddl::<$d app, $krate::$name>() ),* ]
                }

                /// Store table writes encoded by the kernel (`to_row`): plan
                /// them with `i5h_sql::plan` and run each statement on the
                /// table its number names, in order.
                #[allow(dead_code)]
                async fn schema_write(
                    tx: &::i5h_pg::Tx<'_>,
                    tenant: ::i5h::TenantId,
                    ws: &::std::vec::Vec<::i5h_pg::sql::Write>,
                ) -> ::std::result::Result<(), ::i5h_pg::DbError> {
                    for stmt in ::i5h_pg::sql::plan(ws) {
                        let table = match &stmt {
                            ::i5h_pg::sql::Stmt::Upsert { table, .. } => *table,
                            ::i5h_pg::sql::Stmt::Delete { table, .. } => *table,
                            ::i5h_pg::sql::Stmt::DeleteWhere { table, .. } => *table,
                        };
                        let mut n: u32 = 0;
                        let mut run = false;
                        $(
                            if !run && table == n {
                                ::i5h_pg::run_planned::<$d app, $krate::$name>(tx, tenant, stmt.clone()).await?;
                                run = true;
                            }
                            n += 1;
                        )*
                        let _ = n;
                        if !run {
                            return Err(::i5h_pg::DbError::Decode(::std::format!("no table number {table}")));
                        }
                    }
                    Ok(())
                }

                /// Table names for every row type in the schema.
                fn schema_tables() -> ::std::vec::Vec<&'static str> {
                    ::std::vec![ $( <$krate::$name as ::i5h_pg::Table<$d app>>::NAME ),* ]
                }

                $crate::__mapping_snap! { [$d app] $krate [$($w)?] $snap }
            };
        }
    };
}

/// The server's load and store for a schema with a snapshot.
#[doc(hidden)]
#[macro_export]
macro_rules! __mapping_snap {
    ([$app:ty] $krate:ident [$($w:ident)?] []) => {};
    ([$app:ty] $krate:ident [$($w:ident)?] [$sattr:tt $svis:tt $snap:ident [$([$fa:tt $f:ident $t:ident $ty:tt])*]]) => {
        /// A tenant's rows, every table, in whatever order the database
        /// returns them, decoded by the kernel's `decode`.
        #[allow(dead_code)]
        async fn schema_load(
            tx: &::i5h_pg::Tx<'_>,
            tenant: ::i5h::TenantId,
        ) -> ::std::result::Result<$krate::$snap, ::i5h_pg::DbError> {
            let rows = $krate::Rows { $($f: ::i5h_pg::load_rows::<$app, $krate::$t>(tx, tenant).await?,)* };
            $krate::decode(&rows).ok_or_else(|| ::i5h_pg::DbError::Decode("stored rows do not decode".into()))
        }

        $crate::__mapping_store! { $krate [$($w)?] }
    };
}

#[doc(hidden)]
#[macro_export]
macro_rules! __mapping_store {
    ($krate:ident []) => {};
    ($krate:ident [$w:ident]) => {
        /// Store a write set: the table writes of the kernel's `sql_writes`,
        /// planned and run in order.
        #[allow(dead_code)]
        async fn schema_store(
            tx: &::i5h_pg::Tx<'_>,
            tenant: ::i5h::TenantId,
            ws: &::std::vec::Vec<$krate::$w>,
        ) -> ::std::result::Result<(), ::i5h_pg::DbError> {
            schema_write(tx, tenant, &$krate::sql_writes(ws)).await
        }
    };
}
