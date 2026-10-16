# h5i-app-bench

Benchmarks for [h5i-app](https://github.com/h5i-dev/h5i), a Rust framework
whose kernel is extracted to Lean 4 and proved there. Results are published at
<https://benchmark.h5i.dev>.

| Benchmark | Question | Source | Results |
| --- | --- | --- | --- |
| Verification | How much of real servers' security logic can be ported to h5i-app and proved, and what does the port cost at runtime? Six open-source Rust servers, 101 Lean 4 specs. | [`prove/`](prove) | [benchmark.h5i.dev/prove](https://benchmark.h5i.dev/prove/) |
| Web performance | Is a web server built on h5i-app slower than the same API in Go, TypeScript or Python? RealWorld and linkding on PostgreSQL, measured with k6. | [`performance/`](performance) | [benchmark.h5i.dev/performance](https://benchmark.h5i.dev/performance/) |

```
prove/          ports, servers, harness, results, agent benchmark
performance/    realworld/, linkding/: implementations, conformance tests, load benchmark
docs/           benchmark.h5i.dev: landing page, prove/, performance/
```

## License

Apache-2.0. Ported code keeps its upstream license (nora: MIT).
