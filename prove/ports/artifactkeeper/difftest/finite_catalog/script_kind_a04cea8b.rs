#![allow(dead_code,unused_imports)]
#[derive(Clone,Copy,Debug,PartialEq,Eq)]
pub enum ScriptKind {PostLink,PreLink,PreUnlink,PreInstall,Install,PostInstall,Prepare,RpmPre,RpmPost,RpmPreUn,RpmPostUn,DebPreInst,DebPostInst,DebPreRm,DebPostRm,ApkPreInstall,ApkPostInstall,PythonSetupPy}
impl ScriptKind {
    /// Stable lowercase wire form, used for the `kind` column and the API.
    pub fn as_str(self) -> &'static str {
        match self {
            ScriptKind::PostLink => "post-link",
            ScriptKind::PreLink => "pre-link",
            ScriptKind::PreUnlink => "pre-unlink",
            ScriptKind::PreInstall => "preinstall",
            ScriptKind::Install => "install",
            ScriptKind::PostInstall => "postinstall",
            ScriptKind::Prepare => "prepare",
            ScriptKind::RpmPre => "rpm-pre",
            ScriptKind::RpmPost => "rpm-post",
            ScriptKind::RpmPreUn => "rpm-preun",
            ScriptKind::RpmPostUn => "rpm-postun",
            ScriptKind::DebPreInst => "deb-preinst",
            ScriptKind::DebPostInst => "deb-postinst",
            ScriptKind::DebPreRm => "deb-prerm",
            ScriptKind::DebPostRm => "deb-postrm",
            ScriptKind::ApkPreInstall => "apk-pre-install",
            ScriptKind::ApkPostInstall => "apk-post-install",
            ScriptKind::PythonSetupPy => "python-setup-py",
        }
    }
    /// True when this hook executes with elevated privilege on a normal
    /// install. RPM scriptlets and Debian maintainer scripts run as root;
    /// npm, conda and Python hooks run as the invoking user. Callers can use
    /// this to weight findings, because the same rule hit is a materially
    /// worse outcome as root.
    pub fn runs_as_root(self) -> bool {
        matches!(
            self,
            ScriptKind::RpmPre
                | ScriptKind::RpmPost
                | ScriptKind::RpmPreUn
                | ScriptKind::RpmPostUn
                | ScriptKind::DebPreInst
                | ScriptKind::DebPostInst
                | ScriptKind::DebPreRm
                | ScriptKind::DebPostRm
                | ScriptKind::ApkPreInstall
                | ScriptKind::ApkPostInstall
        )
    }
}
fn main(){
println!("as_str/PostLink\t{:?}",ScriptKind::PostLink.as_str().as_bytes());
println!("as_str/PreLink\t{:?}",ScriptKind::PreLink.as_str().as_bytes());
println!("as_str/PreUnlink\t{:?}",ScriptKind::PreUnlink.as_str().as_bytes());
println!("as_str/PreInstall\t{:?}",ScriptKind::PreInstall.as_str().as_bytes());
println!("as_str/Install\t{:?}",ScriptKind::Install.as_str().as_bytes());
println!("as_str/PostInstall\t{:?}",ScriptKind::PostInstall.as_str().as_bytes());
println!("as_str/Prepare\t{:?}",ScriptKind::Prepare.as_str().as_bytes());
println!("as_str/RpmPre\t{:?}",ScriptKind::RpmPre.as_str().as_bytes());
println!("as_str/RpmPost\t{:?}",ScriptKind::RpmPost.as_str().as_bytes());
println!("as_str/RpmPreUn\t{:?}",ScriptKind::RpmPreUn.as_str().as_bytes());
println!("as_str/RpmPostUn\t{:?}",ScriptKind::RpmPostUn.as_str().as_bytes());
println!("as_str/DebPreInst\t{:?}",ScriptKind::DebPreInst.as_str().as_bytes());
println!("as_str/DebPostInst\t{:?}",ScriptKind::DebPostInst.as_str().as_bytes());
println!("as_str/DebPreRm\t{:?}",ScriptKind::DebPreRm.as_str().as_bytes());
println!("as_str/DebPostRm\t{:?}",ScriptKind::DebPostRm.as_str().as_bytes());
println!("as_str/ApkPreInstall\t{:?}",ScriptKind::ApkPreInstall.as_str().as_bytes());
println!("as_str/ApkPostInstall\t{:?}",ScriptKind::ApkPostInstall.as_str().as_bytes());
println!("as_str/PythonSetupPy\t{:?}",ScriptKind::PythonSetupPy.as_str().as_bytes());
println!("runs_as_root/PostLink\t{:?}",ScriptKind::PostLink.runs_as_root());
println!("runs_as_root/PreLink\t{:?}",ScriptKind::PreLink.runs_as_root());
println!("runs_as_root/PreUnlink\t{:?}",ScriptKind::PreUnlink.runs_as_root());
println!("runs_as_root/PreInstall\t{:?}",ScriptKind::PreInstall.runs_as_root());
println!("runs_as_root/Install\t{:?}",ScriptKind::Install.runs_as_root());
println!("runs_as_root/PostInstall\t{:?}",ScriptKind::PostInstall.runs_as_root());
println!("runs_as_root/Prepare\t{:?}",ScriptKind::Prepare.runs_as_root());
println!("runs_as_root/RpmPre\t{:?}",ScriptKind::RpmPre.runs_as_root());
println!("runs_as_root/RpmPost\t{:?}",ScriptKind::RpmPost.runs_as_root());
println!("runs_as_root/RpmPreUn\t{:?}",ScriptKind::RpmPreUn.runs_as_root());
println!("runs_as_root/RpmPostUn\t{:?}",ScriptKind::RpmPostUn.runs_as_root());
println!("runs_as_root/DebPreInst\t{:?}",ScriptKind::DebPreInst.runs_as_root());
println!("runs_as_root/DebPostInst\t{:?}",ScriptKind::DebPostInst.runs_as_root());
println!("runs_as_root/DebPreRm\t{:?}",ScriptKind::DebPreRm.runs_as_root());
println!("runs_as_root/DebPostRm\t{:?}",ScriptKind::DebPostRm.runs_as_root());
println!("runs_as_root/ApkPreInstall\t{:?}",ScriptKind::ApkPreInstall.runs_as_root());
println!("runs_as_root/ApkPostInstall\t{:?}",ScriptKind::ApkPostInstall.runs_as_root());
println!("runs_as_root/PythonSetupPy\t{:?}",ScriptKind::PythonSetupPy.runs_as_root());
}

#[test]
fn all_variants_match_pinned_methods(){
assert_eq!(ScriptKind::PostLink.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::PostLink.as_str(),"script_kind_a04cea8b/as_str/PostLink");
assert_eq!(ScriptKind::PreLink.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::PreLink.as_str(),"script_kind_a04cea8b/as_str/PreLink");
assert_eq!(ScriptKind::PreUnlink.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::PreUnlink.as_str(),"script_kind_a04cea8b/as_str/PreUnlink");
assert_eq!(ScriptKind::PreInstall.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::PreInstall.as_str(),"script_kind_a04cea8b/as_str/PreInstall");
assert_eq!(ScriptKind::Install.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::Install.as_str(),"script_kind_a04cea8b/as_str/Install");
assert_eq!(ScriptKind::PostInstall.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::PostInstall.as_str(),"script_kind_a04cea8b/as_str/PostInstall");
assert_eq!(ScriptKind::Prepare.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::Prepare.as_str(),"script_kind_a04cea8b/as_str/Prepare");
assert_eq!(ScriptKind::RpmPre.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::RpmPre.as_str(),"script_kind_a04cea8b/as_str/RpmPre");
assert_eq!(ScriptKind::RpmPost.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::RpmPost.as_str(),"script_kind_a04cea8b/as_str/RpmPost");
assert_eq!(ScriptKind::RpmPreUn.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::RpmPreUn.as_str(),"script_kind_a04cea8b/as_str/RpmPreUn");
assert_eq!(ScriptKind::RpmPostUn.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::RpmPostUn.as_str(),"script_kind_a04cea8b/as_str/RpmPostUn");
assert_eq!(ScriptKind::DebPreInst.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::DebPreInst.as_str(),"script_kind_a04cea8b/as_str/DebPreInst");
assert_eq!(ScriptKind::DebPostInst.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::DebPostInst.as_str(),"script_kind_a04cea8b/as_str/DebPostInst");
assert_eq!(ScriptKind::DebPreRm.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::DebPreRm.as_str(),"script_kind_a04cea8b/as_str/DebPreRm");
assert_eq!(ScriptKind::DebPostRm.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::DebPostRm.as_str(),"script_kind_a04cea8b/as_str/DebPostRm");
assert_eq!(ScriptKind::ApkPreInstall.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::ApkPreInstall.as_str(),"script_kind_a04cea8b/as_str/ApkPreInstall");
assert_eq!(ScriptKind::ApkPostInstall.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::ApkPostInstall.as_str(),"script_kind_a04cea8b/as_str/ApkPostInstall");
assert_eq!(ScriptKind::PythonSetupPy.as_str().as_bytes(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::PythonSetupPy.as_str(),"script_kind_a04cea8b/as_str/PythonSetupPy");
assert_eq!(ScriptKind::PostLink.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::PostLink.runs_as_root(),"script_kind_a04cea8b/runs_as_root/PostLink");
assert_eq!(ScriptKind::PreLink.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::PreLink.runs_as_root(),"script_kind_a04cea8b/runs_as_root/PreLink");
assert_eq!(ScriptKind::PreUnlink.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::PreUnlink.runs_as_root(),"script_kind_a04cea8b/runs_as_root/PreUnlink");
assert_eq!(ScriptKind::PreInstall.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::PreInstall.runs_as_root(),"script_kind_a04cea8b/runs_as_root/PreInstall");
assert_eq!(ScriptKind::Install.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::Install.runs_as_root(),"script_kind_a04cea8b/runs_as_root/Install");
assert_eq!(ScriptKind::PostInstall.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::PostInstall.runs_as_root(),"script_kind_a04cea8b/runs_as_root/PostInstall");
assert_eq!(ScriptKind::Prepare.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::Prepare.runs_as_root(),"script_kind_a04cea8b/runs_as_root/Prepare");
assert_eq!(ScriptKind::RpmPre.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::RpmPre.runs_as_root(),"script_kind_a04cea8b/runs_as_root/RpmPre");
assert_eq!(ScriptKind::RpmPost.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::RpmPost.runs_as_root(),"script_kind_a04cea8b/runs_as_root/RpmPost");
assert_eq!(ScriptKind::RpmPreUn.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::RpmPreUn.runs_as_root(),"script_kind_a04cea8b/runs_as_root/RpmPreUn");
assert_eq!(ScriptKind::RpmPostUn.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::RpmPostUn.runs_as_root(),"script_kind_a04cea8b/runs_as_root/RpmPostUn");
assert_eq!(ScriptKind::DebPreInst.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::DebPreInst.runs_as_root(),"script_kind_a04cea8b/runs_as_root/DebPreInst");
assert_eq!(ScriptKind::DebPostInst.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::DebPostInst.runs_as_root(),"script_kind_a04cea8b/runs_as_root/DebPostInst");
assert_eq!(ScriptKind::DebPreRm.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::DebPreRm.runs_as_root(),"script_kind_a04cea8b/runs_as_root/DebPreRm");
assert_eq!(ScriptKind::DebPostRm.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::DebPostRm.runs_as_root(),"script_kind_a04cea8b/runs_as_root/DebPostRm");
assert_eq!(ScriptKind::ApkPreInstall.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::ApkPreInstall.runs_as_root(),"script_kind_a04cea8b/runs_as_root/ApkPreInstall");
assert_eq!(ScriptKind::ApkPostInstall.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::ApkPostInstall.runs_as_root(),"script_kind_a04cea8b/runs_as_root/ApkPostInstall");
assert_eq!(ScriptKind::PythonSetupPy.runs_as_root(),artifactkeeper_kernel::finite_catalog::script_kind_a04cea8b::ScriptKind::PythonSetupPy.runs_as_root(),"script_kind_a04cea8b/runs_as_root/PythonSetupPy");
}
