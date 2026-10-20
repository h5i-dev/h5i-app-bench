# GPU rerun under external contention

Diagnostic with external vLLM processes active on GPU 0. Not an isolated CPU/GPU speedup. Fixed prior best GPU path per shape; same canonical fixture and full owned output, eight changing warmups and 50 timed changing rounds, three resets/repetitions. No competing processes stopped or modified. No official timings replaced.

| Carts × lines | Updates/cart | Current GPU µs ± SD | Prior GPU µs | Current / prior |
| --- | ---: | ---: | ---: | ---: |
| 4,096 × 512 | 16 | 2324.853 ± 40.055 | 239.171 | 9.72× |
| 65,536 × 2,048 | 1 | 2314.577 ± 11.576 | 361.218 | 6.41× |
| 65,536 × 2,048 | 16 | 3168.363 ± 53.131 | 2860.982 | 1.11× |
| 65,536 × 2,048 | 64 | 14238.615 ± 68.014 | 10859.331 | 1.31× |

696 rounds, 34,922,496 exact totals; 808 upstream cases for each of two GPU paths.
