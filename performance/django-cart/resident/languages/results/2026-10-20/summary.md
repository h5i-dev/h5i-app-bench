# Resident language comparison with earlier GPU references

CPU timings are new. GPU timings are earlier uncontended measurements, not rerun concurrently: all four GPUs were occupied by external vLLM jobs. Ratios are references, not contemporary speedups. rounds/checked_totals count the new CPU run only.

CPU: mean ± sample SD of three repetition means, eight changing warmups and 50 timed rounds each. All update work and full fresh owned results included. GPU input/output costs are included in the earlier run too.

| Carts | Lines | Updates/cart | Implementation | Total µs ± SD | CPU / prior GPU (reference) |
| ---: | ---: | ---: | --- | ---: | ---: |
| 4096 | 512 | 16 | rust-1 | 1262.531 ± 6.789 | 5.28× |
| 4096 | 512 | 16 | rust-4 | 541.468 ± 31.608 | 2.26× |
| 4096 | 512 | 16 | go-1 | 1869.965 ± 90.774 | 7.82× |
| 4096 | 512 | 16 | go-4 | 711.456 ± 4.679 | 2.97× |
| 4096 | 512 | 16 | javascript-1 | 2191.621 ± 10.835 | 9.16× |
| 4096 | 512 | 16 | javascript-4 | 1412.597 ± 49.459 | 5.91× |
| 4096 | 512 | 16 | python-1 | 53963.858 ± 397.339 | 225.63× |
| 4096 | 512 | 16 | python-4 | 15879.687 ± 451.363 | 66.39× |
| 4096 | 512 | 16 | python-numpy | 7247.273 ± 113.684 | 30.30× |
| 4096 | 512 | 16 | gpu-scan-pageable (prior run) | 272.943 ± 0.744 | — |
| 4096 | 512 | 16 | gpu-delta-pageable (prior run) | 328.483 ± 1.603 | — |
| 4096 | 512 | 16 | gpu-scan-compact-pinned-encode4 (prior run) | 239.171 ± 3.958 | — |
| 4096 | 512 | 16 | gpu-delta-compact-pinned-encode4 (prior run) | 286.738 ± 3.136 | — |
| 65536 | 2048 | 1 | rust-1 | 7096.439 ± 55.051 | 19.65× |
| 65536 | 2048 | 1 | rust-4 | 2521.974 ± 64.307 | 6.98× |
| 65536 | 2048 | 1 | go-1 | 6599.564 ± 146.683 | 18.27× |
| 65536 | 2048 | 1 | go-4 | 2678.276 ± 284.737 | 7.41× |
| 65536 | 2048 | 1 | javascript-1 | 14016.746 ± 2444.223 | 38.80× |
| 65536 | 2048 | 1 | javascript-4 | 6568.328 ± 346.360 | 18.18× |
| 65536 | 2048 | 1 | python-1 | 132052.356 ± 252.584 | 365.58× |
| 65536 | 2048 | 1 | python-4 | 36071.982 ± 178.826 | 99.86× |
| 65536 | 2048 | 1 | python-numpy | 15206.538 ± 323.403 | 42.10× |
| 65536 | 2048 | 1 | gpu-scan-pageable (prior run) | 3126.760 ± 419.251 | — |
| 65536 | 2048 | 1 | gpu-delta-pageable (prior run) | 380.069 ± 1.070 | — |
| 65536 | 2048 | 1 | gpu-scan-compact-pinned-encode4 (prior run) | 2832.964 ± 4.289 | — |
| 65536 | 2048 | 1 | gpu-delta-compact-pinned-encode4 (prior run) | 361.218 ± 1.646 | — |
| 65536 | 2048 | 16 | rust-1 | 34768.290 ± 1270.958 | 12.15× |
| 65536 | 2048 | 16 | rust-4 | 11707.322 ± 261.625 | 4.09× |
| 65536 | 2048 | 16 | go-1 | 41939.928 ± 3001.454 | 14.66× |
| 65536 | 2048 | 16 | go-4 | 15366.631 ± 431.001 | 5.37× |
| 65536 | 2048 | 16 | javascript-1 | 48795.103 ± 763.129 | 17.06× |
| 65536 | 2048 | 16 | javascript-4 | 19757.861 ± 1032.095 | 6.91× |
| 65536 | 2048 | 16 | python-1 | 899958.946 ± 24085.720 | 314.56× |
| 65536 | 2048 | 16 | python-4 | 230525.276 ± 1486.976 | 80.58× |
| 65536 | 2048 | 16 | python-numpy | 146101.570 ± 9931.365 | 51.07× |
| 65536 | 2048 | 16 | gpu-scan-pageable (prior run) | 5744.002 ± 23.863 | — |
| 65536 | 2048 | 16 | gpu-delta-pageable (prior run) | 3591.773 ± 31.691 | — |
| 65536 | 2048 | 16 | gpu-scan-compact-pinned-encode4 (prior run) | 5050.351 ± 19.421 | — |
| 65536 | 2048 | 16 | gpu-delta-compact-pinned-encode4 (prior run) | 2860.982 ± 14.890 | — |
| 65536 | 2048 | 64 | rust-1 | 113124.932 ± 23902.095 | 10.42× |
| 65536 | 2048 | 64 | rust-4 | 50339.633 ± 612.091 | 4.64× |
| 65536 | 2048 | 64 | go-1 | 173473.818 ± 13939.068 | 15.97× |
| 65536 | 2048 | 64 | go-4 | 70101.689 ± 4296.387 | 6.46× |
| 65536 | 2048 | 64 | javascript-1 | 152638.094 ± 3818.564 | 14.06× |
| 65536 | 2048 | 64 | javascript-4 | 57787.644 ± 2468.527 | 5.32× |
| 65536 | 2048 | 64 | python-1 | 3403158.628 ± 206884.904 | 313.39× |
| 65536 | 2048 | 64 | python-4 | 871037.881 ± 17823.734 | 80.21× |
| 65536 | 2048 | 64 | python-numpy | 579361.758 ± 44851.617 | 53.35× |
| 65536 | 2048 | 64 | gpu-scan-pageable (prior run) | 14700.763 ± 29.383 | — |
| 65536 | 2048 | 64 | gpu-delta-pageable (prior run) | 13717.546 ± 45.082 | — |
| 65536 | 2048 | 64 | gpu-scan-compact-pinned-encode4 (prior run) | 11785.325 ± 38.893 | — |
| 65536 | 2048 | 64 | gpu-delta-compact-pinned-encode4 (prior run) | 10859.331 ± 69.031 | — |

New CPU run: 6,264 checked rounds, 314,302,464 exact totals; 808 upstream cases × 9 CPU implementations.
The four reused GPU paths cover 2,784 earlier rounds and 139,689,984 exact totals; every round checksum agrees with the new trace fixtures. The complete earlier transport experiment has additional paths and diagnostics.
