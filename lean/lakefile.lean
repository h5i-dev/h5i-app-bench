import Lake
open Lake DSL

package i5h_engine

-- Model of the i5h-pg engine protocol. No dependencies beyond Lean core.
@[default_target] lean_lib Engine where
  roots := #[`Engine.Model, `Engine.Proofs, `Engine.Clock, `Engine.Scopes, `Engine.Lock, `Engine.Outbox, `Engine.Check, `Engine.Trace]

-- Checks traces recorded by `Engine::with_trace` against the model.
lean_exe tracecheck where
  root := `TraceCheck
