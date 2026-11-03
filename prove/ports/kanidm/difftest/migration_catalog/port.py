"""Port complete ordered initializer selections; entry conversion is separate."""
from pathlib import Path
import json,gzip,re,subprocess,hashlib,tempfile
folder=Path(__file__).resolve().parent;port=folder.parents[1];root=folder.parents[4];pin='f608c4fe14dfd8d5df8edeed470bf1fb92060abd';repo=root/'prove/results/upstream/kanidm.git'
rows=[json.loads(l)for l in gzip.open(root/'prove/results/source-coverage/kernel-ceiling-items.jsonl.gz','rt')]
plans={k:json.loads((port/f'difftest/{k}_catalog/plan.json').read_text())for k in ['schema','acp']}
snapshots={}
for k in plans:
 with tempfile.TemporaryDirectory(prefix='migration-catalog-') as work:
  exe=Path(work)/'dump'
  subprocess.run(['rustc','--edition=2021','-Awarnings',str(port/f'difftest/{k}_catalog/main.rs'),'-o',str(exe)],check=True)
  raw=subprocess.check_output([str(exe)],text=True)
 snapshots[k]=dict(l.split('\t',1)for l in raw.splitlines())
lookup={k:{a:(n,i)for i,n in enumerate(p['names'])for a in p['aliases'][n]}for k,p in plans.items()}
configs=[('system','attributes','schema','Attribute'),('system','classes','schema','Class')]+[(v,fn,k,ty)for v in ['dl11','dl12','dl13','dl14','dl15','dl_1_12']for fn,k,ty in [('phase_1_schema_attrs','schema','Attribute'),('phase_2_schema_classes','schema','Class'),('phase_7_builtin_access_control_profiles','acp','')]]
rust='//! Exact ordered complete source-record selections; no entry conversion.\n';ref='#![allow(dead_code,non_upper_case_globals)]\n#[derive(Clone,Copy)]struct Source(&\'static str);\ntype EntryInitNew=Source;type SchemaAttribute=Source;type SchemaClass=Source;\n';tests='#[path="../../difftest/migration_catalog/reference.rs"]\nmod reference;\nuse kanidm_kernel::{migration_catalog};\n';names=[];decl={};wrappers=[]
for i,(v,fn,k,ty)in enumerate(configs):
 path=f'server/lib/src/migration_data/{v}/mod.rs';text=subprocess.check_output(['git','-C',str(repo),'show',pin+':'+path],text=True).splitlines();row=next(r for r in rows if r['app']=='kanidm'and r['file']==path and r['name']==fn);frag='\n'.join(text[row['start']-1:row['end']]);symbols=re.findall(r'\b((?:SCHEMA_|IDM_ACP_)\w+)\s*\.clone\(\)',frag);assert symbols
 calls=[lookup[k][v+'/'+s]for s in symbols];n=v+'_'+fn;names.append(n);mod=k.title()+'Catalog';rtype=k+'_catalog::'+(ty+'Record'if k=='schema'else'Profile');view='view'+ty if k=='schema'else'view';model=ty+'Model'if k=='schema'else'Model'
 rust+=f'pub fn {n}()->Vec<{rtype}>{{Vec::from([\n'+',\n'.join(f'{k}_catalog::{name}()'for name,_ in calls)+'])}\n'
 rust=rust.replace('//! Exact ordered complete source-record selections; no entry conversion.\n','//! Exact ordered complete source-record selections; no entry conversion.\nuse crate::{schema_catalog,acp_catalog};\n')if i==0 else rust
 pf=''.join(f'import Verified.{mod}{idx}\n'for idx in sorted({idx for _,idx in calls}))+'open Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec\nopen H5iAppLib hiding lit\nnamespace kanidm_kernel.Verified.MigrationCatalog\nset_option maxRecDepth 32768\nset_option maxHeartbeats 16000000\n'
 pf+=f'def expected_{n} : List {mod}.{model} := ['+',\n'.join(f'{mod}.expected_{name}'for name,_ in calls)+']\n'
 pf+=f'@[step] theorem {n}_complete : migration_catalog.{n} ⦃r => r.val.map {mod}.{view} = expected_{n}⦄ := by\n  unfold migration_catalog.{n}\n  h5i_steps\n  all_goals simp_all [expected_{n}, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]\n  all_goals scalar_tac\nend kanidm_kernel.Verified.MigrationCatalog\n';(port/f'proofs/Verified/MigrationCatalog{i}.lean').write_text(pf)
 wrappers.append(f'theorem migration_catalog_{n}_complete : migration_catalog.{n} ⦃r => r.val.map Verified.{mod}.{view} = Verified.MigrationCatalog.expected_{n}⦄ := Verified.MigrationCatalog.{n}_complete')
 decl['migration_catalog.'+n]=[{**{x:row[x]for x in ['file','self_ty','name','kind','start','end']},'sha256':hashlib.sha256(frag.encode()).hexdigest()}]
 # Compile verbatim original list body against lossless full-record carriers.
 ref+=f'mod {n}{{use super::*;\n'+''.join(f'const {s}:Source=Source({json.dumps(snapshots[k][v+"/"+s])});\n'for s in sorted(set(symbols)))+frag+'}\n'
 ref+=f'pub fn {n}()->Vec<&\'static str>{{{n}::{fn}().into_iter().map(|s|s.0).collect()}}\n'
 # Render every selected field, in the same explicit JSON order as independent dump.
 sample=json.loads(snapshots[k][v+'/'+symbols[0]]);fmt='{{'+','.join('\\"'+f+'\\":'+('{}'if isinstance(x,(bool,int))else'{:?}')for f,x in sample.items())+'}}';args=','.join('r.'+f for f in sample)
 tests+=f'#[test]fn {n}_all_records_and_order(){{let actual=migration_catalog::{n}();let expected=reference::{n}();let rendered:Vec<String>=actual.iter().map(|r|format!("{fmt}",{args})).collect();assert_eq!(rendered,expected,"all selected fields and order: {n}");}}\n'
(port/'kernel/src/migration_catalog.rs').write_text(rust);(folder/'reference.rs').write_text(ref);(port/'kernel/tests/migration_catalog.rs').write_text(tests);(folder/'plan.json').write_text(json.dumps({'names':names,'declarations':decl,'wrappers':wrappers},indent=2)+'\n');print(len(names),'complete ordered selection functions')
