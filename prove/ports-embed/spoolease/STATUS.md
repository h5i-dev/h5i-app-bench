# SpoolEase embedded port — STATUS

Upstream: bberrevoets/SpoolEase @ 3532f8d (picoserve 0.15.1, ESP32-S3 / Embassy).
Kernel: the on-SD-card inventory allocator (core/src/csvdb.rs insert/delete) and
NFC-tag index (core/src/store.rs add_spool/edit_spool_from_web/delete_spool).

Status: WIP. Proofs build (no sorry). Loop specs + place properties + read-only done.
Next: transition_total, inv_reachable (non-aliasing/bounds/id/tag), no_clobber, fresh_id.
