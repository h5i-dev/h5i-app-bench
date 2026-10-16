# Pinned upstream

- Tag: `v1.47.0`
- Commit: `24b5ad6cc9bde497b5d1b1e86aed5a2fb7d25c2f`
- Image: `sissbruecker/linkding:1.47.0`
- Published: 2026-09-13

`fetch.sh` clones that tag. The conformance suite was checked against the
image, not against a rebuilt tree.

The image starts uWSGI from `uwsgi.ini` (`processes = 2`, `threads = 2`) via
`bootstrap.sh`. The benchmark runs that process as shipped. `LD_SERVER_HOST`
is set to `127.0.0.1` because the default IPv6 bind is not available here.
`LD_DISABLE_BACKGROUND_TASKS=True` is set for the benchmark so favicon,
preview, and snapshot tasks do not run during the measurement.
