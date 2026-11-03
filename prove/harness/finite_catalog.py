"""Port exhaustively enumerable, dependency-closed unit-enum queries.

Candidate inventory is heuristic. Compile unchanged pinned method bodies before
accepting any candidate. Enumerate their entire input domain to independently
state complete Lean output models. Full project gates remain required.
"""
import argparse
import gzip
import hashlib
import io
import json
import re
import subprocess
import tarfile
import tempfile
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCALARS = {'bool': 'Bool', **{t: t.upper() if not t.endswith('size') else t.title()
                           for t in ['u8','u16','u32','u64','usize','i8','i16','i32','i64']}}
TOKEN = re.compile(r'"(?:\\.|[^"\\])*"|//[^\n]*|/\*.*?\*/', re.S)


def clean(source):
    return TOKEN.sub(lambda m: m[0] if m[0].startswith('"') else '', source)


def string_bytes(literal):
    # Rust line continuations trim all subsequent whitespace.
    literal = re.sub(r'\\\n\s*', '', literal)
    return list(json.loads(literal).encode('utf-8'))


def span(meta, source):
    return {**{k: meta[k] for k in ('file','kind','name','self_ty','start','end')},
            'sha256': hashlib.sha256(source.encode()).hexdigest()}


def generate(app):
    port = ROOT / 'ports' / app
    folder = port / 'difftest/finite_catalog'
    folder.mkdir(parents=True, exist_ok=True)
    (port / 'kernel/tests').mkdir(parents=True, exist_ok=True)
    mapping = json.loads((ROOT / f'harness/source-mappings/{app}.json').read_text())
    revision = mapping['upstream_revision']
    repo = ROOT / f'results/upstream/{app}.git'
    rows = [json.loads(s) for s in gzip.open(ROOT / 'results/source-coverage/kernel-ceiling-items.jsonl.gz', 'rt')]
    files = sorted({r['file'] for r in rows if r['app']==app and r['kind']=='enum' and not r['reasons']})
    archive = subprocess.check_output(['git', f'--git-dir={repo}', 'archive', revision, *files])
    sources = {}
    with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
        for member in tar:
            if member.isfile(): sources[member.name] = tar.extractfile(member).read().decode().splitlines()
    candidates=[]
    for en in rows:
        if en['app']!=app or en['kind']!='enum' or en['file'] not in sources: continue
        source='\n'.join(sources[en['file']][en['start']-1:en['end']])
        if '#[cfg' in source: continue
        plain=re.sub(r'#\[[^\]]*\]', '', clean(source))
        variants=[v.strip() for v in plain[plain.find('{')+1:plain.rfind('}')].split(',') if v.strip()]
        if not variants or not all(re.fullmatch(r'\w+(?:\s*=\s*(?:\d+|0x[0-9a-fA-F]+))?',v) for v in variants): continue
        methods=[]
        for r in rows:
            if r['app']!=app or r['file']!=en['file'] or r['kind']!='method' or r['self_ty']!=en['name'] or r['reasons']: continue
            raw='\n'.join(sources[r['file']][r['start']-1:r['end']])
            text=clean(raw)
            if '#[cfg' in text: continue
            sig=text[:text.find('{')]
            match=re.search(r'fn\s+\w+\s*\(\s*(?:&\s*)?self\s*\)\s*->\s*(&\s*(?:\x27static\s*)?str|bool|u8|u16|u32|u64|usize|i8|i16|i32|i64)\s*$',sig)
            if not match: continue
            ty=match[1];ty='bytes' if ty.startswith('&') else ty
            methods.append({'meta':span(r,raw),'source':raw,'type':ty})
        if methods: candidates.append({'enum':span(en,source),'variants':variants,'source':source,'methods':methods})
    accepted=[];rejected=[]
    crate=app+'_kernel'
    with tempfile.TemporaryDirectory(prefix='finite-catalog-') as tmp:
        tmp=Path(tmp)
        for en in candidates:
            ty=en['enum']['name'];variants=en['variants']
            # Exact unit variants/discriminants; derive implementations are carriers.
            carrier=f'#[derive(Clone,Copy,Debug,PartialEq,Eq)]\npub enum {ty} {{'+','.join(variants)+'}\n'
            methods=en['methods']
            def program(ms):
                text='#![allow(dead_code,unused_imports)]\n'+carrier+f'impl {ty} {{\n'+'\n'.join(m['source'] for m in ms)+'\n}\nfn main(){\n'
                for m in ms:
                    name=m['meta']['name']
                    for variant in variants:
                        v=variant.split('=')[0].strip();expr=f'{ty}::{v}.{name}()'+('.as_bytes()' if m['type']=='bytes' else '')
                        text+=f'println!("{name}/{v}\\t{{:?}}",{expr});\n'
                return text+'}\n'
            # Resolve closure as a group; remove candidates that cannot compile
            # alone with any already successful methods, retaining diagnostics.
            (tmp/'main.rs').write_text(program(methods))
            result=subprocess.run(['rustc','--edition=2021',str(tmp/'main.rs'),'-o',str(tmp/'run')],capture_output=True,text=True)
            if result.returncode:
                passing=[]
                for method in methods:
                    (tmp/'main.rs').write_text(program(passing+[method]))
                    result=subprocess.run(['rustc','--edition=2021',str(tmp/'main.rs'),'-o',str(tmp/'run')],capture_output=True,text=True)
                    if result.returncode: rejected.append({'enum':en['enum'],'method':method['meta'],'reason':result.stderr.replace(str(tmp), '<scratch>')})
                    else: passing.append(method)
                methods=passing
            if not methods: continue
            # Recompile exactly the accepted dependency closure and retain source.
            reference=program(methods)
            (tmp/'main.rs').write_text(reference)
            subprocess.run(['rustc','--edition=2021',str(tmp/'main.rs'),'-o',str(tmp/'run')],check=True,capture_output=True)
            outputs={k:json.loads(v) for k,v in (l.split('\t') for l in subprocess.check_output([str(tmp/'run')],text=True).splitlines())}
            module=re.sub(r'(?<!^)(?=[A-Z])','_',ty).lower()+'_'+hashlib.sha256(en['enum']['file'].encode()).hexdigest()[:8]
            kernel=carrier+f'impl {ty} {{\n'
            supported=[]
            for m in methods:
                try:
                    text=clean(m['source'])
                    text=re.sub(r'pub(?:\([^)]*\))?\s+fn', 'pub fn', text)
                    text=re.sub(r'(?<!pub )\bfn ', 'pub fn ', text)
                    if m['type']=='bytes':
                        text=re.sub(r'->\s*&\s*(?:\x27static\s*)?str','-> Vec<u8>',text)
                        text=TOKEN.sub(lambda match: 'Vec::from(['+', '.join(f'{n}u8' for n in string_bytes(match[0]))+'])', text)
                    kernel+=text+'\n';supported.append(m)
                except (ValueError,KeyError) as e:
                    raise RuntimeError(f'Unsupported Rust literal in {app}/{ty}/{m["meta"]["name"]}') from e
            kernel+='}\n'
            en.update(module=module,methods=supported,outputs=outputs)
            (folder/f'{module}.rs').write_text(reference)
            en['kernel']=kernel
            accepted.append(en)
    rust='//! Exhaustive finite enum decisions; see DEVIATIONS.md.\n'
    test='// Compare every variant against unchanged pinned method bodies.\nuse '+crate+'::finite_catalog;\n'
    testcases=0;declarations={};properties=[];roots=[];lean_sections=[]
    for en in accepted:
        module=en['module'];ty=en['enum']['name'];variants=[v.split('=')[0].strip() for v in en['variants']]
        rust+=f'pub mod {module} {{\n'+en.pop('kernel')+'}\n'
        test+=f'#[path="../../difftest/finite_catalog/{module}.rs"]\nmod {module};\n'
        # Parent tests cannot call private methods inside included submodules:
        # append a same-module exhaustive comparison function to the reference.
        ref=folder/f'{module}.rs'
        text=ref.read_text()+'\n#[test]\nfn all_variants_match_pinned_methods(){\n'
        for m in en['methods']:
            name=m['meta']['name'];path=f'finite_catalog.{module}.{ty}.{name}';styp=m['type'];modelty='List U8' if styp=='bytes' else SCALARS[styp]
            modelname=module+'_'+name
            spec='match v with\n'
            for v in variants:
                value=en['outputs'][name+'/'+v]
                lit='['+', '.join(f'{n}#u8' for n in value)+']' if styp=='bytes' else str(value).lower() if styp=='bool' else f'{value}#{styp}'
                spec+=f'  | .{v} => {lit}\n'
                lhs=f'{ty}::{v}.{name}()'+('.as_bytes()' if styp=='bytes' else '')
                rhs=f'{crate}::finite_catalog::{module}::{ty}::{v}.{name}()'
                text+=f'assert_eq!({lhs},{rhs},"{module}/{name}/{v}");\n';testcases+=1
            pidx=len(properties)
            # Existing generated module spelling uses Artifactkeeper, not ArtifactKeeper.
            lean=f'import {app.title()}Kernel\nimport H5iAppLib\nopen Aeneas Aeneas.Std Result H5iAppLib {crate}\nnamespace {crate}.Verified.FiniteCatalog\nset_option maxRecDepth 16384\nset_option maxHeartbeats 12000000\n'
            lean+=f'def {modelname}_model (v : finite_catalog.{module}.{ty}) : {modelty} :=\n  '+spec
            result='r.val' if styp=='bytes' else 'r'
            theorem=f'{modelname}_complete'
            statement=f'(v : finite_catalog.{module}.{ty}) :\n    {path} v ⦃r => {result} = {modelname}_model v⦄'
            # Unfold callees as needed; compilation/Lean detects unsupported ones.
            unfolds=', '.join(f'finite_catalog.{module}.{ty}.{x["meta"]["name"]}' for x in en['methods'])
            if any(re.search(r'\bself\s+as\b', x['source']) for x in en['methods']):
                unfolds += f', finite_catalog.{module}.{ty}.read_discriminant'
            lean+=f'theorem {theorem} {statement} := by\n  cases v <;> simp only [{modelname}_model]\n  all_goals simp only [{unfolds}]\n  all_goals h5i_steps\n  all_goals simp_all [Array.to_slice, Array.make, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.FromVecArray.from, Std.Array.empty]\n  all_goals scalar_tac\nend {crate}.Verified.FiniteCatalog\n'
            lean_sections.append('\n'.join(line for line in lean.splitlines()
                                           if not line.startswith('import ')))
            properties.append({'name':theorem,'statement':statement,'index':pidx})
            declarations[path]=[m['meta']];roots.append(f'finite_catalog::{module}::_::{name}')
        ref.write_text(text+'}\n')
        en['reference_sha256']=hashlib.sha256(ref.read_bytes()).hexdigest()
    (port/'kernel/src/finite_catalog.rs').write_text(rust)
    (port/'kernel/tests/finite_catalog.rs').write_text(test)
    (port/'proofs/Verified/FiniteCatalog.lean').write_text(
        f'import {app.title()}Kernel\nimport H5iAppLib\n' + '\n'.join(lean_sections) + '\n')
    (folder/'plan.json').write_text(json.dumps({'revision':revision,'accepted':accepted,'rejected':rejected,'properties':properties,'declarations':declarations,'roots':roots,'comparisons':testcases},indent=2)+'\n')
    print(app,len(accepted),'enums',len(properties),'methods',testcases,'exhaustive comparisons;',len(rejected),'unresolved candidates excluded')


def integrate(app):
    port=ROOT/'ports'/app;folder=port/'difftest/finite_catalog'
    p=json.loads((folder/'plan.json').read_text());crate=app+'_kernel'
    lib=port/'kernel/src/lib.rs';text=lib.read_text()
    if 'pub mod finite_catalog;' not in text:lib.write_text(text+'\npub mod finite_catalog;\n')
    prop=port/'proofs/Properties.lean';text=prop.read_text()
    assert 'Verified.FiniteCatalog' not in text, 'Already integrated'
    imports='import Verified.FiniteCatalog\n'
    wrappers=f'\nnamespace {crate}.Properties\nopen Verified.FiniteCatalog\n'
    for x in p['properties']:
        wrappers+=f'theorem finite_{x["name"]} {x["statement"]} := Verified.FiniteCatalog.{x["name"]} v\n\n'
    prop.write_text(imports+text+wrappers+f'end {crate}.Properties\n')
    manifest=port/'h5i-app.toml';text=manifest.read_text();m=tomllib.loads(text)
    text=re.sub(r'^start-from = \[.*?\]', 'start-from = '+json.dumps(m['extract']['start-from']+p['roots']),text,flags=re.M|re.S)
    names=m['check']['theorems']+[crate+'.Properties.finite_'+x['name']for x in p['properties']]
    text=re.sub(r'^theorems = \[.*?\]', 'theorems = [\n'+''.join('  '+json.dumps(n)+',\n'for n in names)+']',text,flags=re.M|re.S);manifest.write_text(text)
    mp=ROOT/f'harness/source-mappings/{app}.json';m=json.loads(mp.read_text());m['declarations'].update(p['declarations']);mp.write_text(json.dumps(m,indent=2)+'\n')


def audit(app):
    """Check retained references against the immutable upstream revision."""
    folder = ROOT / 'ports' / app / 'difftest/finite_catalog'
    plan = json.loads((folder / 'plan.json').read_text())
    repo = ROOT / 'results/upstream' / (app + '.git')
    files = {}
    comparisons = 0
    for entry in plan['accepted']:
        reference = (folder / (entry['module'] + '.rs')).read_bytes()
        assert hashlib.sha256(reference).hexdigest() == entry['reference_sha256'], entry['module']
        for meta, retained in [(entry['enum'], entry['source'])] + [
                (method['meta'], method['source']) for method in entry['methods']]:
            path = meta['file']
            if path not in files:
                files[path] = subprocess.check_output([
                    'git', f'--git-dir={repo}', 'show', plan['revision'] + ':' + path
                ]).decode().splitlines()
            original = '\n'.join(files[path][meta['start'] - 1:meta['end']])
            assert original == retained, (path, meta['name'])
            assert hashlib.sha256(original.encode()).hexdigest() == meta['sha256']
        for method in entry['methods']:
            assert method['source'].encode() in reference, method['meta']
        comparisons += len(entry['methods']) * len(entry['variants'])
    assert comparisons == plan['comparisons']
    print(app, 'pinned reference audit passed;', comparisons, 'comparisons')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action',choices=['generate','integrate','audit'])
    parser.add_argument('--app',required=True, choices=['nora','artifactkeeper','kanidm','rustfs','tuwunel','oxicloud'])
    args=parser.parse_args()
    {'generate': generate, 'integrate': integrate, 'audit': audit}[args.action](args.app)
