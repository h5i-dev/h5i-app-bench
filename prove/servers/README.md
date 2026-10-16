# Servers

Each port's kernel, running in place of the code it covers inside the real
application. `servers/<app>/<app>.patch` changes the upstream application at
the commit its port pins so that the covered functions convert their inputs,
call the kernel and turn its answer back into the application's types; the
rest of the application is unchanged. The upstream test suites then run
against the kernel-backed build, and the servers boot and serve requests.

```sh
SRC=../nora servers/build.sh nora                  # worktree, patch, upstream tests, build
servers/nora/smoke.sh <worktree target>/debug/nora  # boot it and send requests
```

`build.sh` checks out the pinned commit in a new worktree next to `SRC`,
links the kernel at `h5i/<app>-kernel` and applies the patch. The kernels
depend on nothing; the patches add `h5i-app` from crates.io for its `Kernel`
contract.

## What runs on the kernel

| Application | Spliced in | Upstream tests on the kernel-backed build |
|---|---|---|
| [nora](nora) | the auth middleware, API-token verification and revocation, the brute-force tracker, trusted proxies, OIDC claim checks and namespace scopes, the validators | 1,949 of 1,949 (`cargo test`); `smoke.sh` boots the registry and checks Basic, token, read-only, admin and lockout paths |
| [rustfs](rustfs) | `Policy::is_allowed`, `BucketPolicy::is_allowed` and the statement checks under them | 1,013 of 1,013 in `rustfs-policy` and `rustfs-iam`; 6,298 of 6,299 with the server crate (below); `smoke.sh` checks bucket-policy decisions over S3 |
| [OxiCloud](oxicloud) | the ACL engine's `check` (drive roles, grants, nested groups, folder inheritance, read-only modes) | 1,102 of 1,102 unit tests, 1,162 of 1,162 with the PostgreSQL integration tests, and the whole HTTP API suite against the running server: 90 of 90 Hurl files, the refcount scenario and the four shell checks |
| [artifact-keeper](artifactkeeper) | the auth, optional-auth, admin, repository-visibility and guest-access middlewares, download tickets, token scopes, client-IP resolution, the permission-rule gates | 18,057 of 18,057 unit tests; against the running server and PostgreSQL, 92 of 123 integration tests, the same 92 that unmodified upstream passes here |
| [kanidm](kanidm) | the access-control decisions: search filtering and attribute reduction, modify, batch modify, create, delete, effective permissions | 568 of 568 in `kanidmd_lib`, and 69 of 69 in the testkit, each test starting a server and talking to it over HTTP |
| [tuwunel](tuwunel) | who may see what in a room: `user_can_see_event`, `user_can_see_state_events`, `user_can_see_room`, `server_can_see_event` | 1,333 of 1,333 (`cargo test`; its tests need a few GB free in a local `TMPDIR`); `smoke.sh` boots the homeserver and checks event, state and room visibility as members join and leave and the history visibility changes |

The one rustfs failure, `local_runtime_profile_cancellation_waits_for_lease_release`,
waits for a CPU-profiler lease; it fails the same way when run alone and
does not touch the policy code. Eight more
diagnostics tests time out when the whole suite runs at once and pass on
their own. The 31 artifact-keeper integration tests that fail do so on the
unmodified server too.

In every app, a mutated kernel makes tests fail: for example, dropping the
admin gate for API tokens fails three nora tests, removing Update from
OxiCloud's Editor role fails three WebDAV scenarios of its API suite, and
keeping kanidm entries regardless of the attributes a search may read fails
five access and LDAP tests. tuwunel's own tests do not exercise history
visibility (its Complement results cover it, but Complement needs Go and
Docker images); there, letting any current member read `joined`-visibility
history fails two checks of `smoke.sh`.

## What stays upstream

The parts each port leaves out (see its `DEVIATIONS.md`) stay as they were:
cryptography, JWT signatures, parsing, storage, caches, logs and metrics.
Within the spliced functions, the code falls back to upstream's evaluation
only for inputs the kernel has no form for: rustfs policies with `Date*` or
`BinaryEquals` conditions, kanidm profiles that compare a value of a syntax
the kernel does not port, and tuwunel rooms with more than 999 members from
one server. None of these occurs in the upstream test suites.

Some decisions the ports cover are not yet routed through the kernel:
OxiCloud's grant endpoints (the kernel's `grantapi`), artifact-keeper's
`PermissionService` methods when handlers call them outside the middleware,
and the tuwunel client endpoints the kernel ports (`/messages`, `/context`,
`/relations` and the rest), which stay upstream's and call the spliced
visibility checks.
