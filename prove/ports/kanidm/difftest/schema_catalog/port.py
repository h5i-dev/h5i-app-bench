"""Build exact owned schema records and full-field Lean specifications.

Input is output from separately compiled pinned initializers (main.rs).
"""
from pathlib import Path
import json,collections,sys
folder=Path(__file__).resolve().parent;port=folder.parents[1]
meta=json.loads((folder/'metadata.json').read_text())
records=[(l.split('\t')[0],json.loads(l.split('\t')[1]))for l in Path(sys.argv[1]).read_text().splitlines()]
g=collections.OrderedDict()
for key,r in records:
 kind='Attribute'if key.split('/')[1].startswith('SCHEMA_ATTR_')else'Class'
 g.setdefault((kind,json.dumps(r,sort_keys=True)),[]).append(key)
def ltype(ty):return 'List '+ty[4:-1].upper()if ty.startswith('Vec')else'Bool'if ty=='bool'else ty.upper()
def literal(v,ty,lean=False):
 if ty=='bool':return str(v).lower()
 if ty.startswith('Vec'):return ('['if lean else'Vec::from([')+', '.join(literal(x,ty[4:-1],lean)for x in v)+(']'if lean else'])')
 return str(v)+('#'if lean else'')+ty
rust='//! Exact full pinned migration schema records. See DEVIATIONS.md.\n'
lean='import Spec\nopen Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec\nopen H5iAppLib hiding lit\nnamespace kanidm_kernel.Verified.SchemaCatalog\n'
for kind,fields in meta['fields'].items():
 rust+='#[derive(Debug,PartialEq,Eq)]\npub struct '+kind+'Record {\n'+''.join(f'pub {f}:{ty},\n'for f,ty in fields.items())+'}\n'
 lean+='structure '+kind+'Model where\n'+''.join('  '+('«'+f+'»')+' : '+ltype(ty)+'\n'for f,ty in fields.items())+'  deriving DecidableEq\n'
 lean+=f'def view{kind} (r : schema_catalog.{kind}Record) : {kind}Model :=\n  ⟨'+', '.join('r.«'+f+'»'+('.val'if ty.startswith('Vec')else'')for f,ty in fields.items())+'⟩\n'
lean+='end kanidm_kernel.Verified.SchemaCatalog\n';(port/'proofs/Verified/SchemaCatalogData.lean').write_text(lean)
names=[];decl={};aliases={};kinds={}
for idx,((kind,key),ns)in enumerate(g.items()):
 r=json.loads(key);fields=meta['fields'][kind];n=ns[0].replace('/SCHEMA_','_').lower();names.append(n);aliases[n]=ns;kinds[n]=kind
 rust+=f'\n/// Exact complete record for {", ".join(ns)}.\npub fn {n}()->{kind}Record{{\n {kind}Record{{\n'+''.join(f'{f}: '+literal(r[f],ty)+',\n'for f,ty in fields.items())+'}\n}\n'
 spec='⟨'+',\n'.join(literal(r[f],ty,True)for f,ty in fields.items())+'⟩'
 pf=f'import Verified.SchemaCatalogData\nopen Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec\nopen H5iAppLib hiding lit\nnamespace kanidm_kernel.Verified.SchemaCatalog\nset_option maxRecDepth 16384\nset_option maxHeartbeats 12000000\ndef expected_{n} : {kind}Model := {spec}\n\n@[step] theorem {n}_complete : schema_catalog.{n} ⦃r => view{kind} r = expected_{n}⦄ := by\n  unfold schema_catalog.{n}\n  h5i_steps\n  all_goals simp_all [view{kind}, expected_{n}, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]\n  all_goals scalar_tac\nend kanidm_kernel.Verified.SchemaCatalog\n'
 (port/f'proofs/Verified/SchemaCatalog{idx}.lean').write_text(pf)
 decl['schema_catalog.'+n]=[{k:meta['records'][x][k]for k in ['file','self_ty','name','kind','start','end','sha256']}for x in ns]
(port/'kernel/src/schema_catalog.rs').write_text(rust)
plan={'names':names,'declarations':decl,'aliases':aliases,'kinds':kinds};(folder/'plan.json').write_text(json.dumps(plan,indent=2)+'\n')
t='#[path = "../../difftest/schema_catalog/reference.rs"]\nmod reference;\nuse kanidm_kernel::schema_catalog;\n'
for kind in meta['fields']:
 count=sum(len(aliases[n])for n in names if kinds[n]==kind)
 t+='#[test]\nfn '+kind.lower()+'_records_match_every_field(){\nlet upstream=reference::'+kind.lower()+'_records();\nassert_eq!(upstream.len(),'+str(count)+');\nfor (name,expected) in upstream {\nlet actual=match name{\n'
 for n in names:
  if kinds[n]==kind:t+=' | '.join(json.dumps(x)for x in aliases[n])+f'=>schema_catalog::{n}(),\n'
 t+='_=>panic!("unexpected schema record: {name}"),\n};\nassert_eq!(actual,expected,"complete schema {name}");\n}\nprintln!("'+str(count)+' pinned '+kind+' records matched every field");\n}\n'
(port/'kernel/tests/schema_catalog.rs').write_text(t)
print(len(records),'initializers /',len(names),'distinct full records')
