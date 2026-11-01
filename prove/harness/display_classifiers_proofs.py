"""Generate decision specifications independently of extracted Result code."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=ROOT/'prove/ports/oxicloud'
plan=json.loads((p/'difftest/display_classifiers/plan.json').read_text())
base=(ROOT/'prove/harness/templates/display-classifiers-primitives.lean').read_text()
base=base.removesuffix('end oxicloud_kernel.Verified.DisplayClassifiers\n')
text=base+'-- Generated ordered decision specifications.\n'
def lit(s): return '['+', '.join(str(b)+'#u8' for b in s.encode())+']'
def model(rules):
 s='none'
 for op,key,out in reversed(rules):
  cond={'eq':f'decide (raw = {lit(key)})','prefix':f'window raw {lit(key)} 0','contains':f'contains_model raw {lit(key)}'}[op]
  s=f'if {cond} then some .V{plan["outputs"].index(out)} else ({s})'
 return s
for c in plan['chunks']:
 name=c['name']
 text+=f'''def {name}_model (raw : List U8) : Option display_classifiers.DisplayValue :=
  {model(c['rules'])}
@[step] theorem {name}_complete (raw : Slice U8) :
    display_classifiers.{name} raw ⦃r => r = {name}_model raw.val⦄ := by
  unfold display_classifiers.{name}
  h5i_steps
  all_goals simp_all [{name}_model, Slice.eq_iff, Array.to_slice, Array.make]
'''
for rec in plan['records']:
 name=rec['name']
 default=f'.V{plan["outputs"].index(rec["default"])}'
 ext=default
 for c in reversed(rec['ext_chunks']):
  ext=f'match {c}_model ext with | some v => v | none => ({ext})'
 body=f'match ext with | none => {default} | some ext => ({ext})'
 for c in reversed(rec['exact_chunks']+rec['mime_chunks']):
  body=f'match {c}_model mime with | some v => v | none => ({body})'
 def prove_chunks(cs, indent, tail):
  if not cs: return tail(indent)
  return indent+'step as ⟨o, ho⟩\n'+indent+'cases o with\n'+indent+'| some v => simp [← ho]\n'+indent+'| none =>\n'+indent+'  simp only [← ho]\n'+prove_chunks(cs[1:],indent+'  ',tail)
 def final(indent): return indent+'simp\n'
 def extcase(indent):
  return indent+'cases ext with\n'+indent+'| none => simp\n'+indent+'| some ext =>\n'+indent+'  simp only [Option.map_some]\n'+prove_chunks(rec['ext_chunks'],indent+'  ',final)
 proof=prove_chunks(rec['exact_chunks']+rec['mime_chunks'],'  ',extcase)
 text+=f'''def {name}_model (mime : List U8) (ext : Option (List U8)) : display_classifiers.DisplayValue :=
  {body}
@[step] theorem {name}_complete (mime : Slice U8) (ext : Option (Slice U8)) :
    display_classifiers.{name} mime ext ⦃r => r = {name}_model mime.val (ext.map Slice.val)⦄ := by
  unfold display_classifiers.{name}
  unfold {name}_model
{proof}
'''
text+='end oxicloud_kernel.Verified.DisplayClassifiers\n'
(p/'proofs/Verified/DisplayClassifiers.lean').write_text(text)
