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
//! kernel stays plain Rust for Aeneas. It also defines a macro `docs_tables!`
//! for the server crate: `docs_kernel::docs_tables!(DocsApp);` expands to an
//! `i5h_pg::table!` mapping per row type, plus `schema_ddl()` and
//! `schema_tables()`. Keys and columns are listed once, here.

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
        $crate::__mapping! { ($) $mapping $krate; $( $name $table [$($k)*] [$($c)*] )* }
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

                /// Table names for every row type in the schema.
                fn schema_tables() -> ::std::vec::Vec<&'static str> {
                    ::std::vec![ $( <$krate::$name as ::i5h_pg::Table<$d app>>::NAME ),* ]
                }
            };
        }
    };
}
