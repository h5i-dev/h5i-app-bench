#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum LockFormat {PixiLock,CondaLock,NpmPackageLock,CargoLock,PoetryLock,UvLock}
impl LockFormat {
    /// Canonical lower-case identifier, suitable for storage and API output.
    pub fn as_str(self) -> &'static str {
        match self {
            LockFormat::PixiLock => "pixi.lock",
            LockFormat::CondaLock => "conda-lock",
            LockFormat::NpmPackageLock => "package-lock.json",
            LockFormat::CargoLock => "Cargo.lock",
            LockFormat::PoetryLock => "poetry.lock",
            LockFormat::UvLock => "uv.lock",
        }
    }
    /// Whether the format expresses a separate graph per platform. `false`
    /// means every [`Scope`] this format produces has `platform: None` — not
    /// that the environment is portable.
    pub fn is_per_platform(self) -> bool {
        matches!(self, LockFormat::PixiLock | LockFormat::CondaLock)
    }
}
fn main(){
println!("as_str/PixiLock\t{:?}",LockFormat::PixiLock.as_str().as_bytes());
println!("as_str/CondaLock\t{:?}",LockFormat::CondaLock.as_str().as_bytes());
println!("as_str/NpmPackageLock\t{:?}",LockFormat::NpmPackageLock.as_str().as_bytes());
println!("as_str/CargoLock\t{:?}",LockFormat::CargoLock.as_str().as_bytes());
println!("as_str/PoetryLock\t{:?}",LockFormat::PoetryLock.as_str().as_bytes());
println!("as_str/UvLock\t{:?}",LockFormat::UvLock.as_str().as_bytes());
println!("is_per_platform/PixiLock\t{:?}",LockFormat::PixiLock.is_per_platform());
println!("is_per_platform/CondaLock\t{:?}",LockFormat::CondaLock.is_per_platform());
println!("is_per_platform/NpmPackageLock\t{:?}",LockFormat::NpmPackageLock.is_per_platform());
println!("is_per_platform/CargoLock\t{:?}",LockFormat::CargoLock.is_per_platform());
println!("is_per_platform/PoetryLock\t{:?}",LockFormat::PoetryLock.is_per_platform());
println!("is_per_platform/UvLock\t{:?}",LockFormat::UvLock.is_per_platform());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(LockFormat::PixiLock.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::lock_format_99735155::LockFormat::PixiLock.as_str(),"lock_format_99735155/as_str/PixiLock");
assert_eq!(LockFormat::CondaLock.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::lock_format_99735155::LockFormat::CondaLock.as_str(),"lock_format_99735155/as_str/CondaLock");
assert_eq!(LockFormat::NpmPackageLock.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::lock_format_99735155::LockFormat::NpmPackageLock.as_str(),"lock_format_99735155/as_str/NpmPackageLock");
assert_eq!(LockFormat::CargoLock.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::lock_format_99735155::LockFormat::CargoLock.as_str(),"lock_format_99735155/as_str/CargoLock");
assert_eq!(LockFormat::PoetryLock.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::lock_format_99735155::LockFormat::PoetryLock.as_str(),"lock_format_99735155/as_str/PoetryLock");
assert_eq!(LockFormat::UvLock.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::lock_format_99735155::LockFormat::UvLock.as_str(),"lock_format_99735155/as_str/UvLock");
assert_eq!(LockFormat::PixiLock.is_per_platform(),artifactkeeper_kernel::finite_catalog::lock_format_99735155::LockFormat::PixiLock.is_per_platform(),"lock_format_99735155/is_per_platform/PixiLock");
assert_eq!(LockFormat::CondaLock.is_per_platform(),artifactkeeper_kernel::finite_catalog::lock_format_99735155::LockFormat::CondaLock.is_per_platform(),"lock_format_99735155/is_per_platform/CondaLock");
assert_eq!(LockFormat::NpmPackageLock.is_per_platform(),artifactkeeper_kernel::finite_catalog::lock_format_99735155::LockFormat::NpmPackageLock.is_per_platform(),"lock_format_99735155/is_per_platform/NpmPackageLock");
assert_eq!(LockFormat::CargoLock.is_per_platform(),artifactkeeper_kernel::finite_catalog::lock_format_99735155::LockFormat::CargoLock.is_per_platform(),"lock_format_99735155/is_per_platform/CargoLock");
assert_eq!(LockFormat::PoetryLock.is_per_platform(),artifactkeeper_kernel::finite_catalog::lock_format_99735155::LockFormat::PoetryLock.is_per_platform(),"lock_format_99735155/is_per_platform/PoetryLock");
assert_eq!(LockFormat::UvLock.is_per_platform(),artifactkeeper_kernel::finite_catalog::lock_format_99735155::LockFormat::UvLock.is_per_platform(),"lock_format_99735155/is_per_platform/UvLock");
}
