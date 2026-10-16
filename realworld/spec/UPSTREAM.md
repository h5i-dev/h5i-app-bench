# Pinned RealWorld API spec

Upstream: https://github.com/realworld-apps/realworld

Commit: `ebbcdeb8d55b42a3a613c787560498b8ef10003f` (see `UPSTREAM_COMMIT`)

`api/` is a copy of `specs/api` at that commit: the OpenAPI document and the
Hurl suite. The Hurl files are the source of truth for these backends.
`fetch.sh` replaces `api/` with a fresh checkout of the pinned commit.
