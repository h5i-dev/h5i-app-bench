# Design

## Tasks

A task is `(application, property)`. `dataset/tasks.toml` lists them. Each
task names the port directory, the spec files the model is given, and the
theorem in the reference proofs whose statement the model must prove.

`harness/bench.py build` turns an entry into `tasks/<id>/workspace`, which is
what the model sees:

- `kernel/src/lib.rs`, the ported Rust, for reading;
- `proofs/generated/`, the Lean that Aeneas extracted from it;
- the given spec files;
- `proofs/Solution.lean`, holding the statement with `sorry` in place of the
  proof;
- `TASK.md`, the instructions.

The reference proofs, other theorems of the same port and every other port
stay outside the container. The build also grades the reference proof with
the same checker, so a task whose statement does not match the reference, or
whose reference is not accepted, is not built. It records the reference proof
size: the lines of every hand-written declaration the reference theorem
depends on, found by walking the constants its proof uses.

## Ports

A port lives in `ports/<app>/`:

- `kernel/`, the upstream logic in the Aeneas subset of Rust;
- `proofs/`, the extracted Lean, the spec and the reference proofs;
- `difftest/`, which copies the upstream functions verbatim from the pinned
  commit (`extract_upstream.py`) and runs them and the kernel on the same
  random inputs;
- `DEVIATIONS.md`, every place the kernel differs in form from upstream and
  why.

The kernel follows upstream function by function. It changes the code only
where Aeneas requires it (strings become byte slices, iterator adapters
become loops, a loop inside a recursive function becomes recursion, a missing
library function is written out) or where the code is not logic (metrics and
logs). The differential test is how these changes are shown not to change
behavior, and a mutated kernel must fail it.

Signature checks and parsing that happen before the ported logic are the
trusted boundary: the kernel starts from their output.

## Grading

`bench.py grade` copies the untouched workspace, puts in the model's
`Solution.lean` and adds `Check.lean`, which

- declares the task's statement as an axiom and checks with `isDefEq` that the
  model's theorem has that type,
- prints the theorem's axioms.

The solution passes if the build succeeds, the statement matches and the
axioms are among `propext`, `Classical.choice` and `Quot.sound`. The source is
also rejected if it uses `axiom`, `unsafe`, `extern`, `implemented_by`,
`run_cmd`-style commands or imports outside the spec, the generated code,
H5iAppLib, Aeneas and Mathlib. The build runs in the same container image with
no network.

## Sandbox

`harness/run.py` runs one agent on one task in rootless Docker with `--network
none`. The container mounts the task workspace (writable), the Lean toolchain,
the Lake packages and H5iAppLib (read-only), and the agent's own config directory
with the h5i-app skill. The agent never sees the reference proofs. The agent
reaches the model through `socat` to a unix socket served by
`harness/proxy.py` on the host (from `harness/proxy.example.py`), which adds
the API key, removes provider-hosted tools (web search and the like) from
requests, and logs usage.

OpenAI models run under Codex over the Responses API. Anthropic models run
under Claude Code over the Messages API. Gemini models run under Codex or
gemini-cli.

## Measurements

Per run, `results/runs/<stamp>-<task>-<model>/result.json` records the grade,
wall time, cost (list prices times the logged usage), tokens, the
number of Lean builds (`lake build`, `lake env lean`), how many failed to
compile, and which build was the first to pass with no `sorry`. The proof size
is the solution's lines minus the template's.
