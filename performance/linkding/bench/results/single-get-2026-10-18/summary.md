# Optimized single-bookmark HTTP retrieval

| Clients | Before req/s | After req/s | After / before | Go req/s | Before p99 ms | After p99 ms | Go p99 ms |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 331.60 | 399.48 | 1.20x | 402.78 | 9.90 | 8.71 | 8.58 |
| 64 | 2866.83 | 3676.61 | 1.28x | 6450.85 | 40.07 | 32.59 | 23.29 |

636,179 measured requests, zero failures. [Method, validation and limitations](../../single-get-2026-10-18.md).
