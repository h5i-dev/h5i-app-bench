The ACP, schema, group and entry catalogs compile unchanged bodies from Kanidm
`f608c4fe14dfd8d5df8edeed470bf1fb92060abd`. See `../DEVIATIONS.md` for every
representation and the narrower scope of migration record selection.

To regenerate one catalog from the repository root (replace `schema` with `acp`,
`group`, or `entry`):

```sh
python3 prove/ports/kanidm/difftest/schema_catalog/extract_upstream.py
rustc --edition=2021 prove/ports/kanidm/difftest/schema_catalog/main.rs -o /tmp/schema-records
/tmp/schema-records > /tmp/schema-records.jsonl
python3 prove/ports/kanidm/difftest/schema_catalog/port.py /tmp/schema-records.jsonl
```

After regenerating schema and ACP catalogs, regenerate full ordered selections:

```sh
python3 prove/ports/kanidm/difftest/migration_catalog/port.py
```

The saved metadata records each immutable source span, its hash and the exact
symbol dictionaries. `plan.json` records all aliases of each complete record.
Lean expected values are explicit and independent of the extracted definitions.
The shared constructors retain distinct records whenever any field differs.

The pinned differential tests compare every represented field of every original
initializer, including aliases, and the complete ordered outputs of all twenty
selection functions:

```sh
cargo test --locked --manifest-path prove/ports/kanidm/kernel/Cargo.toml \
  --test acp_catalog --test schema_catalog --test group_catalog \
  --test entry_catalog --test migration_catalog
```

These empirical comparisons use minimal carriers. They are not proofs of the
upstream crate, entry conversion, schema validation, or database migrations.
The standard project gate and exact extraction check remain mandatory.
