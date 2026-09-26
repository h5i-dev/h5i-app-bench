import Engine.Trace
/-! `lake exe tracecheck FILE...`: check engine traces (JSON lines) against the model. -/
open Engine.Trace

def main (args : List String) : IO UInt32 := do
  let mut recs : Array Rec := #[]
  for f in args do
    let lines := (← IO.FS.lines f).filter (· ≠ "")
    for l in lines do
      match parseLine recs.size l with
      | .ok r => recs := recs.push r
      | .error e => IO.eprintln s!"{f}: {e}"; return 1
  let tenants := (recs.toList.map (·.tenant)).eraseDups
  let mut bad := 0
  let mut events := 0
  for t in tenants do
    let rs := recs.toList.filter (·.tenant == t)
    match checkTenant rs with
    | .ok r =>
      events := events + r.events
      IO.println s!"tenant {t}: ok, {r.events} events, {r.requests} requests, {r.commits} commits, {r.states} final states"
    | .error e =>
      bad := bad + 1
      IO.println s!"tenant {t}: FAIL: {e}"
  IO.println s!"{tenants.length - bad}/{tenants.length} tenants ok, {events} events checked"
  return if bad == 0 then 0 else 1
