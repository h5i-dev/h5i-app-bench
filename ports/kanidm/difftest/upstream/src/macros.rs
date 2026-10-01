// Stub: logging is not modelled; the copied macro `btreeset!` follows.
macro_rules! trace { ($($t:tt)*) => {}; }
macro_rules! debug { ($($t:tt)*) => {}; }
macro_rules! info { ($($t:tt)*) => {}; }
macro_rules! warn { ($($t:tt)*) => {}; }
macro_rules! error { ($($t:tt)*) => {}; }
macro_rules! admin_error { ($($t:tt)*) => {}; }
macro_rules! security_debug { ($($t:tt)*) => {}; }
macro_rules! security_access { ($($t:tt)*) => {}; }
macro_rules! security_error { ($($t:tt)*) => {}; }
macro_rules! security_critical { ($($t:tt)*) => {}; }


// Copied from kanidm/kanidm @ f608c4f by extract_upstream.py. Do not edit.
#[allow(unused_macros)]
#[macro_export]
macro_rules! btreeset {
    () => (
        compile_error!("BTreeSet needs at least 1 element")
    );
    ($e:expr) => ({
        use std::collections::BTreeSet;
        let mut x: BTreeSet<_> = BTreeSet::new();
        assert!(x.insert($e));
        x
    });
    ($e:expr,) => ({
        btreeset!($e)
    });
    ($e:expr, $($item:expr),*) => ({
        use std::collections::BTreeSet;
        let mut x: BTreeSet<_> = BTreeSet::new();
        assert!(x.insert($e));
        $(assert!(x.insert($item));)*
        x
    });
}
