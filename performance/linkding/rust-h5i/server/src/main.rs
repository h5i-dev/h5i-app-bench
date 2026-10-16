fn main() {
    if let Err(err) = linkding_server::main_from_env() {
        eprintln!("{err}");
        std::process::exit(1);
    }
}
