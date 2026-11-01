#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum PackageManager {Apt,Dnf,Microdnf,Yum,Apk,Pip,Conda}
impl PackageManager {
    pub fn as_str(self) -> &'static str {
        match self {
            PackageManager::Apt => "apt",
            PackageManager::Dnf => "dnf",
            PackageManager::Microdnf => "microdnf",
            PackageManager::Yum => "yum",
            PackageManager::Apk => "apk",
            PackageManager::Pip => "pip",
            PackageManager::Conda => "conda",
        }
    }
    /// Distribution package managers: root, final stage, cleanup after.
    pub fn is_system(self) -> bool {
        matches!(
            self,
            PackageManager::Apt
                | PackageManager::Dnf
                | PackageManager::Microdnf
                | PackageManager::Yum
                | PackageManager::Apk
        )
    }
}
fn main(){
println!("as_str/Apt\t{:?}",PackageManager::Apt.as_str().as_bytes());
println!("as_str/Dnf\t{:?}",PackageManager::Dnf.as_str().as_bytes());
println!("as_str/Microdnf\t{:?}",PackageManager::Microdnf.as_str().as_bytes());
println!("as_str/Yum\t{:?}",PackageManager::Yum.as_str().as_bytes());
println!("as_str/Apk\t{:?}",PackageManager::Apk.as_str().as_bytes());
println!("as_str/Pip\t{:?}",PackageManager::Pip.as_str().as_bytes());
println!("as_str/Conda\t{:?}",PackageManager::Conda.as_str().as_bytes());
println!("is_system/Apt\t{:?}",PackageManager::Apt.is_system());
println!("is_system/Dnf\t{:?}",PackageManager::Dnf.is_system());
println!("is_system/Microdnf\t{:?}",PackageManager::Microdnf.is_system());
println!("is_system/Yum\t{:?}",PackageManager::Yum.is_system());
println!("is_system/Apk\t{:?}",PackageManager::Apk.is_system());
println!("is_system/Pip\t{:?}",PackageManager::Pip.is_system());
println!("is_system/Conda\t{:?}",PackageManager::Conda.is_system());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(PackageManager::Apt.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::package_manager_7f965e35::PackageManager::Apt.as_str(),"package_manager_7f965e35/as_str/Apt");
assert_eq!(PackageManager::Dnf.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::package_manager_7f965e35::PackageManager::Dnf.as_str(),"package_manager_7f965e35/as_str/Dnf");
assert_eq!(PackageManager::Microdnf.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::package_manager_7f965e35::PackageManager::Microdnf.as_str(),"package_manager_7f965e35/as_str/Microdnf");
assert_eq!(PackageManager::Yum.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::package_manager_7f965e35::PackageManager::Yum.as_str(),"package_manager_7f965e35/as_str/Yum");
assert_eq!(PackageManager::Apk.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::package_manager_7f965e35::PackageManager::Apk.as_str(),"package_manager_7f965e35/as_str/Apk");
assert_eq!(PackageManager::Pip.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::package_manager_7f965e35::PackageManager::Pip.as_str(),"package_manager_7f965e35/as_str/Pip");
assert_eq!(PackageManager::Conda.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::package_manager_7f965e35::PackageManager::Conda.as_str(),"package_manager_7f965e35/as_str/Conda");
assert_eq!(PackageManager::Apt.is_system(),artifactkeeper_kernel::finite_catalog::package_manager_7f965e35::PackageManager::Apt.is_system(),"package_manager_7f965e35/is_system/Apt");
assert_eq!(PackageManager::Dnf.is_system(),artifactkeeper_kernel::finite_catalog::package_manager_7f965e35::PackageManager::Dnf.is_system(),"package_manager_7f965e35/is_system/Dnf");
assert_eq!(PackageManager::Microdnf.is_system(),artifactkeeper_kernel::finite_catalog::package_manager_7f965e35::PackageManager::Microdnf.is_system(),"package_manager_7f965e35/is_system/Microdnf");
assert_eq!(PackageManager::Yum.is_system(),artifactkeeper_kernel::finite_catalog::package_manager_7f965e35::PackageManager::Yum.is_system(),"package_manager_7f965e35/is_system/Yum");
assert_eq!(PackageManager::Apk.is_system(),artifactkeeper_kernel::finite_catalog::package_manager_7f965e35::PackageManager::Apk.is_system(),"package_manager_7f965e35/is_system/Apk");
assert_eq!(PackageManager::Pip.is_system(),artifactkeeper_kernel::finite_catalog::package_manager_7f965e35::PackageManager::Pip.is_system(),"package_manager_7f965e35/is_system/Pip");
assert_eq!(PackageManager::Conda.is_system(),artifactkeeper_kernel::finite_catalog::package_manager_7f965e35::PackageManager::Conda.is_system(),"package_manager_7f965e35/is_system/Conda");
}
