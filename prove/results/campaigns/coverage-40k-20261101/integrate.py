from pathlib import Path
import json,re,tomllib
root=Path(__file__).resolve().parents[4];port=root/'prove/ports/kanidm';cats=['acp','schema','group','entry','migration'];prefixes=[x+'_catalog'for x in cats];imports=[];wrappers=[];roots=[];names=[];m=json.loads((root/'prove/harness/source-mappings/kanidm.json').read_text());m['declarations']={k:v for k,v in m['declarations'].items()if not any(k.startswith(p+'.')for p in prefixes)}
for c in cats:
 p=json.loads((port/f'difftest/{c}_catalog/plan.json').read_text());module=c.title()+'Catalog';prefix=c+'_catalog';m['declarations'].update(p['declarations'])
 for i,n in enumerate(p['names']):
  imports.append(f'import Verified.{module}{i}');roots.append(prefix+'::'+n);names.append('kanidm_kernel.Properties.'+prefix+'_'+n+'_complete')
  if c=='migration':wrappers.append(p['wrappers'][i]);continue
  view='view'if c=='acp'else'view'+p['kinds'][n]
  wrappers.append(f'theorem {prefix}_{n}_complete : {prefix}.{n} ⦃r => Verified.{module}.{view} r = Verified.{module}.expected_{n}⦄ := Verified.{module}.{n}_complete')
prop=port/'proofs/Properties.lean';s=prop.read_text();s=re.sub(r'/-- Complete pinned catalog records and ordered selections; see DEVIATIONS.md. -/.*?(?=end kanidm_kernel.Properties)', '', s, flags=re.S);s='\n'.join(l for l in s.splitlines()if not any(l.startswith('import Verified.'+c.title()+'Catalog')or l.startswith('theorem '+c+'_catalog_')for c in cats))+'\n';s=re.sub(r'/-- Exact complete pinned built-in.*?-/', '',s);s='\n'.join(imports)+'\n'+s.lstrip('\n');s=s.replace('end kanidm_kernel.Properties','/-- Complete pinned catalog records and ordered selections; see DEVIATIONS.md. -/\n'+'\n\n'.join(wrappers)+'\n\nend kanidm_kernel.Properties');prop.write_text(s)
manifest=port/'h5i-app.toml';s=manifest.read_text();t=tomllib.loads(s);oldroots=[r for r in t['extract']['start-from']if not any(r.startswith(p+'::')for p in prefixes)];oldnames=[n for n in t['check']['theorems']if not any('.'+p+'_'in n for p in prefixes)];s=re.sub(r'^start-from = \[.*?\]', 'start-from = '+json.dumps(oldroots+roots),s,flags=re.M|re.S);s=re.sub(r'^theorems = \[.*?\]', 'theorems = [\n'+''.join('  '+json.dumps(n)+',\n'for n in oldnames+names)+']',s,flags=re.M|re.S);manifest.write_text(s)
lib=port/'kernel/src/lib.rs';s=lib.read_text()
for p in prefixes:
 if 'pub mod '+p+';'not in s:s+='\npub mod '+p+';\n'
lib.write_text(s);(root/'prove/harness/source-mappings/kanidm.json').write_text(json.dumps(m,indent=2)+'\n');print(len(roots),'new catalog roots /',len(oldnames+names),'total kanidm properties')
