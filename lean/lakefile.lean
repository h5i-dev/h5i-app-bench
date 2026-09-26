import Lake
open Lake DSL

package i5h_engine

-- Model of the i5h-pg engine protocol. No dependencies beyond Lean core.
@[default_target] lean_lib Engine where
  roots := #[`Engine.Model, `Engine.Proofs, `Engine.Check]
