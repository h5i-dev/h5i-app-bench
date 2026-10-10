The requested theorem is false for the extracted kernel.

Use `username = "$$"`, `account = "{aws:username}{aws:AccountId}"`,
empty timestamp values, and absent `sub` and `parent` claims. Every substituted
value satisfies `NoVarRef`, so `PlainValues` holds.

For the pattern `$${aws:AccountId}`, successful scans alternate between:

```
$${aws:AccountId}
${aws:username}{aws:AccountId}
$${aws:AccountId}
```

Both scans set `modified = true`. `pass_from` consequently repeats at index
zero forever. The ten-iteration bound in `fixpoint` is never reached because
its first call to `resolve_single_pass` diverges.

`proofs/Counterexample.lean` contains kernel-checked proofs of `PlainValues`,
both scan equations, resolver divergence, and the negation of the requested
universally quantified theorem. It can be checked with:

```
cd proofs
lake env lean Counterexample.lean
```

The issue is that reference-free substituted values can create `${` across
concatenation boundaries. Proving termination requires a stronger hypothesis
or a change to the kernel that bounds substitutions within each pass.
`Solution.lean` is unchanged; the original proof obligation remains unsolved.
