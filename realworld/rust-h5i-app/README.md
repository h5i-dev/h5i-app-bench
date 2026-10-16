# rust-h5i-app

The [Conduit entry of the h5i-app cookbook](https://github.com/h5i-dev/h5i-app-cookbook/tree/main/conduit)
as the benchmark's fifth server: `src/main.rs` calls
`conduit_server::main_from_env`, and `Cargo.toml` pins the cookbook by git
revision (it depends on the h5i crates by git in turn; `Cargo.lock` pins
both). The kernel, the server, the Lean proofs and their gate are in the
cookbook at that revision:

```sh
git clone https://github.com/h5i-dev/h5i-app-cookbook && cd h5i-app-cookbook/conduit
git checkout <rev from rust-h5i-app/Cargo.toml>
h5i app extract --check . && h5i app check .
```

`run.sh` builds into `/var/tmp/rw-target-h5i-app` (`H5I_APP_TARGET_DIR`)
and serves on 127.0.0.1:8005 with the same environment as the others
(`DATABASE_URL`, `JWT_SECRET`, `DB_POOL`, `WEB_CONCURRENCY`). The server
creates its tables in the schema `conduit` of the database at start; the
benchmark seeds them with `bench/seed_h5i_app.sql` (see `bench/README.md`).

To move to a newer cookbook commit, change `rev` and run
`cargo update -p conduit-server`.
