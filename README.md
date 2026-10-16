# h5i-app-bench

Benchmarks for [h5i-app](https://github.com/h5i-dev/h5i), a Rust framework
whose kernel is extracted to Lean 4 and proved there. Results are published at
<https://benchmark.h5i.dev>.

| Benchmark | Question | Source | Results |
| --- | --- | --- | --- |
| Verification | How much real-world Rust can h5i-app prove? | [`prove/`](prove) | [benchmark.h5i.dev/prove](https://benchmark.h5i.dev/prove/) |
| Web performance | Is an h5i-app server as fast as Go, TypeScript or Python? | [`performance/`](performance) | [benchmark.h5i.dev/performance](https://benchmark.h5i.dev/performance/) |

```
prove/          ports, servers, harness, results, agent benchmark
performance/    realworld/, linkding/: implementations, conformance tests, load benchmark
docs/           benchmark.h5i.dev: landing page, prove/, performance/
```

## License

Apache-2.0. Ported code keeps its upstream license (nora: MIT).
