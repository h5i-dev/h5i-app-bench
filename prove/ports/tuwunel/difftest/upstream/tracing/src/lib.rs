pub use tuwunel_macros::instrument;

#[macro_export]
macro_rules! trace { ($($t:tt)*) => {}; }
#[macro_export]
macro_rules! debug { ($($t:tt)*) => {}; }
#[macro_export]
macro_rules! info { ($($t:tt)*) => {}; }
#[macro_export]
macro_rules! warn { ($($t:tt)*) => {}; }
#[macro_export]
macro_rules! error { ($($t:tt)*) => {}; }

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct Level(u8);

impl Level {
    pub const ERROR: Level = Level(1);
    pub const WARN: Level = Level(2);
    pub const INFO: Level = Level(3);
    pub const DEBUG: Level = Level(4);
    pub const TRACE: Level = Level(5);
}
