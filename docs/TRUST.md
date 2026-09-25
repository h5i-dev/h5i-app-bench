# What i5h proves, and what it assumes

## Proven in Lean (about the extracted kernel)

The kernel's `transition` and `apply` are translated from Rust to Lean by
Charon and Aeneas. For the example app, the spec is
`examples/docs/proofs/Spec.lean` and the theorems are in `Theorems.lean` next to it.

## Enforced by structure (no proof needed)

| Property | How |
|---|---|
| Handlers go through the kernel | App code gets `I5h::respond` / `Engine::execute`, never a DB handle. A handler that opens its own connection bypasses this; deploy so only the engine has the DB credentials. |
| Tenant isolation | The engine loads and writes only rows with `tenant_id = K::tenant(actor)`. Kernel rows carry no tenant id, so the kernel cannot name another tenant. A Lean theorem about this would be trivial, so it is not claimed as proven. |
| Every column is persisted | `table!` must list every field or it does not compile. |

## Assumed (trusted, not verified)

| Component | Assumption | Mitigation |
|---|---|---|
| `Authenticator` | Returns the principal that sent the request. | Small HMAC implementation; tests for forged and missing tokens. |
| JSON codec | Decodes the body into the command the client meant. | `deny_unknown_fields`; tagged enum. |
| `i5h-pg` table mapping | After commit, `load` returns `apply(before, ws)`. | Differential test against `MemoryEngine` on random command sequences. |
| PostgreSQL | SERIALIZABLE commits are equivalent to some serial order. | Documented PostgreSQL guarantee. Retries restart from the snapshot read. |
| Charon / Aeneas / Lean | The translation is faithful and the checker is sound. | Upstream tools. |
| axum, hyper, tokio | Deliver requests and responses intact. | Widely used. |

## Consequence

If the assumptions hold, every committed state of a tenant is reachable from
the empty state by a sequence of kernel transitions. So every invariant proven
to be preserved by `transition` + `apply` holds in the database.

## Not covered yet

- Reads are whole-tenant snapshots. Narrower reads need a proof that the
  transition only depends on the part that was loaded.
- Refusals are not stored under idempotency keys. A retried refused command
  is evaluated again against the new state.
- Schema migrations: an invariant proven for the old kernel says nothing about
  data written by the old kernel and read by a new one.
- Side effects outside the database (payments, email) need an outbox.
