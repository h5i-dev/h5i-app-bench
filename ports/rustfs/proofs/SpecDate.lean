import SpecOperators
open Aeneas Aeneas.Std
namespace rustfs_kernel.Spec
/-- Decimal interpretation rejects every non-digit, including bytes outside ASCII. -/
def DecimalAcc : List Nat → Int → Option Int
  | [], n => some n
  | b::bs, n => if 48≤b ∧ b≤57 then DecimalAcc bs (10*n + (b: Int)-48) else none
def DateDigits (s : List Nat) (start count : Nat) : Option Int :=
  if start+count≤s.length then DecimalAcc ((s.drop start).take count) 0 else none
/-- Gregorian month lengths, with the century and four-century leap rules. -/
def MonthDays (year month : Int) : Int :=
  if month=2 then if year.tmod 4=0 ∧ (year.tmod 100≠0 ∨ year.tmod 400=0) then 29 else 28
  else if month∈[4,6,9,11] then 30 else 31
/-- Days from the Unix epoch, using proleptic Gregorian dates. -/
def CivilDays (year month day : Int) : Int :=
  let y := if month≤2 then year-1 else year
  let era := (if 0≤y then y else y-399).tdiv 400
  let yoe := y-era*400
  let m := if 2<month then month-3 else month+9
  era*146097 + yoe*365 + yoe.tdiv 4 - yoe.tdiv 100 +
    (153*m+2).tdiv 5 + day-1-719468
/-- UTC nanoseconds of an instant. -/
def InstantNanos (utc nano : Int) : Int := utc*1000000000+nano
/-- Calendar fields use Gregorian month lengths. -/
def DateCalendar (s : List Nat) : Option (Int × Int × Int) := do
  let y ← DateDigits s 0 4
  let m ← DateDigits s 5 2
  let d ← DateDigits s 8 2
  if 1≤m ∧ m≤12 ∧ 1≤d ∧ d≤MonthDays y m then some (y,m,d) else none
def DateTimeFields (s : List Nat) : Option (Int × Int × Int) := do
  let h ← DateDigits s 11 2
  let m ← DateDigits s 14 2
  let sec ← DateDigits s 17 2
  if h≤23 ∧ m≤59 ∧ sec≤60 then some (h,m,sec) else none
/-- Fractional digits beyond the ninth are consumed with zero weight. -/
def FractionAcc : List Nat → Int → Int → Int × Nat
  | [], n, _ => (n,0)
  | b::bs, n, weight =>
    if 48≤b ∧ b≤57 then
      let r := FractionAcc bs (n+((b:Int)-48)*weight) (weight.tdiv 10)
      (r.1,r.2+1)
    else (n,0)
def DateFraction (s : List Nat) : Option (Int × Nat) :=
  if s[19]?=some 46 then
    let r := FractionAcc (s.drop 20) 0 100000000
    if r.2=0 then none else some (r.1,20+r.2)
  else some (0,19)
def DateOffset (s : List Nat) (i : Nat) : Option Int := do
  let b ← s[i]?
  if b=90 ∨ b=122 then if i+1=s.length then some 0 else none
  else if i+6=s.length ∧ (b=43 ∨ b=45) ∧ s[i+3]?=some 58 then
    let h ← DateDigits s (i+1) 2
    let m ← DateDigits s (i+4) 2
    if h≤23 ∧ m≤59 then some (if b=45 then -(h*3600+m*60) else h*3600+m*60) else none
  else none
def LeapSecondValid (utc localDay year month day : Int) : Prop :=
  let rem := (utc.tmod 86400+86400).tmod 86400
  let utcDay := (utc-rem).tdiv 86400
  rem=86399 ∧ ((utcDay=localDay ∧ day=MonthDays year month) ∨
    (utcDay=localDay-1 ∧ day=1) ∨ (utcDay=localDay+1 ∧ day=MonthDays year month-1))
instance (utc localDay year month day : Int) : Decidable (LeapSecondValid utc localDay year month day) := by
  unfold LeapSecondValid
  infer_instance
/-- Date input checks separators at 4, 7, 13, and 16; position 10 is unrestricted.
The second 60 selects the last nanosecond of an accepted month-boundary second. -/
def ParseInstant (s : List Nat) : Option Int := do
  if s.length<20 ∨ s[4]?≠some 45 ∨ s[7]?≠some 45 ∨ s[13]?≠some 58 ∨ s[16]?≠some 58 then none
  else
    let (y,m,d) ← DateCalendar s
    let (h,min,sec) ← DateTimeFields s
    let (nano,i) ← DateFraction s
    let off ← DateOffset s i
    let day := CivilDays y m d
    let utc := day*86400+h*3600+min*60+(if sec=60 then 59 else sec)-off
    if sec=60 then
      if LeapSecondValid utc day y m d then some (InstantNanos utc 999999999) else none
    else some (InstantNanos utc nano)
/-- Every date entry compares its expected instant with the parsed first request
value. Missing, empty, and unparseable request values fail that entry. -/
def DateConditionsHold (entries : List (condfuncs.Key × Int)) (op : conddata.Op)
    (values : List (List U8 × List (List U8))) : Prop :=
  ∀ e ∈ entries, ∃ text instant, FirstConditionValue values e.1=some text ∧
    ParseInstant (nats text)=some instant ∧ DateComparison op instant e.2
end rustfs_kernel.Spec
