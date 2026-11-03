"""Rebuild the complete owned ACP port and its explicit record specifications.

Run extract_upstream.py, compile main.rs, and pass the tab-separated output here.
Original initializer bodies are compiled independently by kernel/tests/acp_catalog.rs.
"""
from pathlib import Path
import json,collections,sys
folder=Path(__file__).resolve().parent
port=folder.parents[1]
meta=json.loads((folder/'metadata.json').read_text())
records=[(l.split('\t')[0],json.loads(l.split('\t')[1])) for l in Path(sys.argv[1]).read_text().splitlines()]
g=collections.OrderedDict()
for n,s in records:g.setdefault(json.dumps(s,sort_keys=True),[]).append(n)
fields=list(records[0][1]);ty={f:('u128'if f=='uuid'else'u8'if f=='receiver'else'Vec<'+('u128'if f=='groups'else'u8'if f in ['name','description','target']else'u16')+'>')for f in fields}
rust='//! Complete remaining pinned built-in ACP records. See DEVIATIONS.md.\n#[derive(Debug,PartialEq,Eq)]\npub struct Profile {\n'+''.join(f' pub {f}:{ty[f]},\n'for f in fields)+'}\n'
lean='import Spec\nopen Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec\nopen H5iAppLib hiding lit\nnamespace kanidm_kernel.Verified.AcpCatalog\nstructure Model where\n'+''.join(f'  '+('«name»'if f=='name'else f)+' : '+('U128'if f=='uuid'else'U8'if f=='receiver'else'List '+('U128'if f=='groups'else'U8'if f in ['name','description','target']else'U16'))+'\n'for f in fields)+'  deriving DecidableEq\ndef view (r : acp_catalog.Profile) : Model :=\n  ⟨'+', '.join('r.'+f+(''if f in ['uuid','receiver']else'.val')for f in fields)+'⟩\nend kanidm_kernel.Verified.AcpCatalog\n'
(port/'proofs/Verified/AcpCatalogData.lean').write_text(lean)
names=[];decl={};aliases={}
for idx,(key,ns)in enumerate(g.items()):
 s=json.loads(key);n=ns[0].replace('/IDM_ACP_','_').lower();names.append(n);aliases[n]=ns
 rust+=f'\n/// Exact complete record for {", ".join(ns)}.\npub fn {n}()->Profile {{\n Profile {{\n'
 for f in fields:rust+=f'  {f}: '+(str(s[f])+ty[f] if f in ['uuid','receiver'] else 'Vec::from(['+', '.join(str(x)+ty[f][4:-1]for x in s[f])+'])')+',\n'
 rust+=' }\n}\n'
 spec='⟨'+',\n'.join(str(s[f])+('#u128'if f=='uuid'else'#u8')if f in ['uuid','receiver']else'['+', '.join(str(x)+('#u128'if f=='groups'else'#u8'if f in ['name','description','target']else'#u16')for x in s[f])+']'for f in fields)+'⟩'
 pf=f'import Verified.AcpCatalogData\nopen Aeneas Aeneas.Std Result kanidm_kernel kanidm_kernel.Spec\nopen H5iAppLib hiding lit\nnamespace kanidm_kernel.Verified.AcpCatalog\nset_option maxRecDepth 16384\nset_option maxHeartbeats 12000000\ndef expected_{n} : Model := {spec}\n\n@[step] theorem {n}_complete : acp_catalog.{n} ⦃r => view r = expected_{n}⦄ := by\n  unfold acp_catalog.{n}\n  h5i_steps\n  all_goals simp_all [view, expected_{n}, Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]\n  all_goals scalar_tac\nend kanidm_kernel.Verified.AcpCatalog\n'
 (port/f'proofs/Verified/AcpCatalog{idx}.lean').write_text(pf)
 decl['acp_catalog.'+n]=[{k:meta['records'][x][k]for k in ['file','self_ty','name','kind','start','end','sha256']}for x in ns]
(port/'kernel/src/acp_catalog.rs').write_text(rust)
(folder/'plan.json').write_text(json.dumps({'names':names,'declarations':decl,'aliases':aliases,'fields':fields},indent=2)+'\n')
t='#[path = "../../difftest/acp_catalog/reference.rs"]\nmod reference;\nuse kanidm_kernel::acp_catalog;\n#[test]\nfn remaining_pinned_profiles_match_every_field(){\n let upstream=reference::profiles();\n assert_eq!(upstream.len(),'+str(len(records))+');\n for (name,expected) in upstream {\n let actual = match name {\n'
for n,ns in aliases.items():t+='  '+' | '.join(json.dumps(x)for x in ns)+f' => acp_catalog::{n}(),\n'
t+=' _=>panic!("unexpected upstream profile: {name}"),\n };\n assert_eq!(actual,expected,"complete profile {name}");\n assert!(!actual.name.is_empty()); assert!(!actual.target.is_empty()); assert!(actual.receiver==1 || actual.receiver==2);\n }\n println!("'+str(len(records))+' pinned built-in profiles / all 15 fields / '+str(len(names))+' distinct records matched");\n}\n'
(port/'kernel/tests/acp_catalog.rs').write_text(t)
print('Built',len(records),'originals /',len(names),'distinct full records')
