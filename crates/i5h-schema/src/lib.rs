//! One declaration for a kernel's row types.
//!
//! ```ignore
//! i5h_schema::schema! {
//!     mapping docs_tables for docs_kernel;
//!
//!     #[derive(Clone, Debug, PartialEq, Eq)]
//!     pub struct Member in "members" {
//!         key { project: u64, user: u64 }
//!         role: Role,
//!     }
//! }
//! ```
//!
//! This defines `Member` with its key fields first, exactly as written, so the
//! kernel stays plain Rust for Aeneas, and gives it `TABLE`, `KEY_LEN` and
//! `to_row` (via `i5h_sql::Column`; the kernel depends on `i5h-sql`). It also defines a macro `docs_tables!`
//! for the server crate: `docs_kernel::docs_tables!(DocsApp);` expands to an
//! `i5h_pg::table!` mapping per row type, plus `schema_ddl()`,
//! `schema_tables()` and `schema_write()`, which stores the kernel's encoded
//! table writes. Keys and columns are listed once, here.

#![no_std]

#[macro_export]
macro_rules! schema {
    (
        mapping $mapping:ident for $krate:ident;
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
        $crate::__rows! { [0] $( $name [$($k)*] [$($c)*] )* }
        $crate::__mapping! { ($) $mapping $krate; $( $name $table [$($k)*] [$($c)*] )* }
    };
}

/// Per row type: its table number (declaration order), key length, and
/// encoding as SQL values, key first. Plain Rust, so Aeneas extracts it.
#[doc(hidden)]
#[macro_export]
macro_rules! __rows {
    ([$($i:tt)*]) => {};
    ([$($i:tt)*] $name:ident [$($k:ident)*] [$($c:ident)*] $($rest:tt)*) => {
        impl $name {
            pub const TABLE: u32 = $($i)*;
            pub const KEY_LEN: u32 = 0 $(+ $crate::__one!($k))*;

            pub fn to_row(&self) -> Vec<::i5h_sql::Val> {
                let mut out = Vec::new();
                $(out.push(::i5h_sql::Column::to_val(&self.$k));)*
                $(out.push(::i5h_sql::Column::to_val(&self.$c));)*
                out
            }
        }
        $crate::__rows! { [$($i)* + 1] $($rest)* }
    };
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
    (($d:tt) $mapping:ident $krate:ident; $( $name:ident $table:literal [$($k:ident)*] [$($c:ident)*] )*) => {
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
            };
        }
    };
}
