import json,re,subprocess,tomllib,hashlib,os
from pathlib import Path
base=Path(__file__).resolve().parents[3];stage=Path('/tmp/h5i-sidebar-probe');stage.mkdir(exist_ok=True)
m=json.loads((base/'harness/source-mappings/nora.json').read_text());rev=m['upstream_revision']
def upstream(file):return subprocess.check_output(['git',f'--git-dir={base}/results/upstream/nora.git','show',rev+':'+file],text=True)
file='nora-registry/src/ui/components.rs';text=upstream(file);lines=text.splitlines();body='\n'.join(lines[126:417]);assert 'pub fn sidebar_dark_with_registries(' in body
start=text.index('pub mod icons {');end=text.index('\n}',start)+2;icons=text[start:end]
registry_file='nora-registry/src/registry_type.rs';registry_source=upstream(registry_file);macro=registry_source.split('registry_types! {',1)[1].split('\n}',1)[0];variants=re.findall(r'^\s*(\w+)\s*=>',macro,re.M);assert len(variants)==16
version=tomllib.loads(upstream('Cargo.toml'))['workspace']['package']['version']
program='#![allow(dead_code)]\nmod registry_type { #[derive(Clone,Copy,Hash,PartialEq,Eq)] pub enum RegistryType { '+','.join(variants)+' } }\nstruct Translations<\'a> { nav_dashboard:&\'a str, nav_registries:&\'a str, nav_tokens:&\'a str }\nconst VERSION: &str = env!("CARGO_PKG_VERSION");\n'+icons+'\n'+body+'\n'
program+='fn main() { use registry_type::RegistryType::*; let variants=['+','.join(variants)+']; let ids=["dashboard","docker","maven","npm","cargo","pypi","raw","go","gems","terraform","ansible","nuget","pub","conan","rpm","deb","cpan","tokens",""]; let t=Translations{nav_dashboard:"@DASHBOARD@",nav_registries:"@REGISTRIES@",nav_tokens:"@TOKENS@"}; for (i,id) in ids.iter().enumerate() { for auth in [false,true] { for mode in 0..18 { let set:std::collections::HashSet<_>=if mode<16 {[variants[mode]].into_iter().collect()} else {std::collections::HashSet::new()}; let enabled=if mode==17 {None} else {Some(&set)}; let out=sidebar_dark_with_registries(Some(id),&t,auth,enabled); std::fs::write(format!("/tmp/h5i-sidebar-probe/{i}-{auth}-{mode}.html"),out).unwrap(); } } } }'
(stage/'reference.rs').write_text(program)
plan={'accepted':False,'revision':rev,'version':version,'variants':variants,'source_file':file,'start':127,'end':417,'source':body,'sha256':hashlib.sha256(body.encode()).hexdigest(),'icons_file':file,'icons_sha256':hashlib.sha256(icons.encode()).hexdigest(),'registry_file':registry_file,'registry_macro_source':macro,'meaning':'Preparation only. No source mapping or complete proof exists yet. VERSION resolves to pinned workspace version; caller-provided text must retain all three translation fields.'}
(stage/'plan.json').write_text(json.dumps(plan,indent=2)+'\n')
subprocess.run(['rustc','--edition=2021',str(stage/'reference.rs'),'-o',str(stage/'run')],env={**os.environ,'CARGO_PKG_VERSION':version},check=True,capture_output=True)
subprocess.run([str(stage/'run')],check=True)
print('Compiled unchanged sidebar body and icon constants; evaluated',len(list(stage.glob('*.html'))),'complete output probes. No accepted coverage.')
