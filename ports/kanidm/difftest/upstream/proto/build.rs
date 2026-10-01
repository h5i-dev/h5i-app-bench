// Stub of proto/build.rs (kanidm's build profiles): sets the one variable
// constants.rs reads.
fn main() {
    println!("cargo:rustc-env=KANIDM_CLIENT_CONFIG_PATH=/etc/kanidm/config");
}
