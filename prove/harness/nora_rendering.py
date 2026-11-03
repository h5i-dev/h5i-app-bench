"""Reproduce byte-exact Nora UI kernels from the immutable upstream revision."""
import gzip
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PORT = ROOT / 'ports/nora'
FILES = {'components': 'nora-registry/src/ui/components.rs', 'templates': 'nora-registry/src/ui/templates.rs'}
SELECT = {'components': ['html_escape', 'render_activity_row', 'render_activity_log', 'render_polling_script', 'header_dark'],
          'templates': ['encode_uri_component', 'registry_search_bar']}

def lit(s):
    return 'b"' + ''.join(chr(b) if 32 <= b < 127 and b not in (34,92) else f'\\x{b:02x}' for b in s.encode()) + '"'

def leanlit(s):
    return '[' + ', '.join(f'{b}#u8' for b in s.encode()) + ']'

def generate():
    mapping = json.loads((ROOT / 'harness/source-mappings/nora.json').read_text())
    rev = mapping['upstream_revision']
    rows = [json.loads(l) for l in gzip.open(ROOT / 'results/source-coverage/kernel-ceiling-items.jsonl.gz','rt')]
    records = []
    for group,names in SELECT.items():
        file = FILES[group]
        src = subprocess.check_output(['git',f'--git-dir={ROOT}/results/upstream/nora.git','show',f'{rev}:{file}'],text=True).splitlines()
        for name in names:
            row, = [r for r in rows if r['app']=='nora' and r['file']==file and r['name']==name and r['kind']=='fn']
            text = '\n'.join(src[row['start']-1:row['end']])
            meta = {k:row[k] for k in ('file','kind','name','self_ty','start','end')}
            meta['sha256'] = hashlib.sha256(text.encode()).hexdigest()
            records.append({'name':name,'source':text,'meta':meta})
    folder = PORT / 'difftest/rendering'
    folder.mkdir(parents=True,exist_ok=True)
    (folder/'plan.json').write_text(json.dumps({'revision':rev,'records':records},indent=2)+'\n')
    preamble = '''#![allow(dead_code)]
use std::fmt::Write;
#[derive(Clone,Copy)]
pub enum Lang { En, Ru, Zh }
pub struct Translations<'a> { pub recent_activity: &'a str, pub last_n_events: &'a str, pub time: &'a str, pub action: &'a str, pub artifact: &'a str, pub registry: &'a str, pub source: &'a str }
'''
    reference = preamble + '\n'.join(r['source'] for r in records)
    # Expose private upstream functions only through wrappers outside the retained bodies.
    reference += '\npub fn search(r:&str,p:&str)->String { registry_search_bar(r,p) }\npub fn header(l:Lang)->String { header_dark(l) }\n'
    (folder/'reference.rs').write_text(reference)
    kernel = '''//! Complete byte output of pinned Nora escaping and UI fragments.
//! UTF-8 inputs retain their original representation. Extra invalid byte inputs
//! are admitted by the proof domain; no UTF-8 normalization occurs.
#[derive(Clone,Copy)]
pub enum Lang { En, Ru, Zh }
pub struct Translations { pub recent_activity: Vec<u8>, pub last_n_events: Vec<u8>, pub time: Vec<u8>, pub action: Vec<u8>, pub artifact: Vec<u8>, pub registry: Vec<u8>, pub source: Vec<u8> }

pub fn append(out: &mut Vec<u8>, bytes: &[u8]) { out.extend_from_slice(bytes); }
pub fn language_index(lang: Lang) -> u8 { match lang { Lang::En => 0, Lang::Ru => 1, Lang::Zh => 2 } }
pub fn header_class(lang: Lang, which: u8) -> Vec<u8> {
    if which == language_index(lang) { b"text-white font-semibold".to_vec() } else { b"text-slate-400 hover:text-slate-200".to_vec() }
}

pub fn action_color(action: &[u8]) -> Vec<u8> {
    if action == b"PULL".as_slice() { b"text-blue-400".to_vec() }
    else if action == b"PUSH".as_slice() { b"text-green-400".to_vec() }
    else if action == b"CACHE".as_slice() { b"text-yellow-400".to_vec() }
    else if action == b"PROXY".as_slice() { b"text-purple-400".to_vec() }
    else { b"text-slate-400".to_vec() }
}


pub fn html_byte(b: u8) -> Vec<u8> {
    match b { b'&' => b"&amp;".to_vec(), b'<' => b"&lt;".to_vec(), b'>' => b"&gt;".to_vec(), b'"' => b"&quot;".to_vec(), b'\\'' => b"&#39;".to_vec(), _ => [b].to_vec() }
}
pub fn uri_allowed(b: u8) -> bool {
    (b >= b'a' && b <= b'z') || (b >= b'A' && b <= b'Z') || (b >= b'0' && b <= b'9') || b == b'-' || b == b'_' || b == b'.' || b == b'~'
}
pub fn uri_byte(b: u8) -> Vec<u8> {
    if uri_allowed(b) { [b].to_vec() } else {
        let digits = b"0123456789ABCDEF";
        [b'%', digits[(b / 16) as usize], digits[(b % 16) as usize]].to_vec()
    }
}
'''
    for name,byte in [('html_escape','html_byte'),('encode_uri_component','uri_byte')]:
        kernel += f'''pub fn {name}(s: &[u8]) -> Vec<u8> {{
    let mut out = Vec::new();
    let mut i = 0;
    while i < s.len() {{
        let piece = {byte}(s[i]);
        append(&mut out, &piece);
        i += 1;
    }}
    out
}}
'''
    # Only these renderer forms are supported; do not silently generalize parsing.
    arguments = {
        'render_activity_row': ('timestamp: &[u8], action: &[u8], artifact: &[u8], registry: &[u8], source: &[u8]', ['html_escape(timestamp)','action_color','html_escape(action)','html_escape(artifact)','html_escape(registry)','html_escape(source)']),
        'render_activity_log': ('rows: &[u8], t: &Translations', ['&t.recent_activity','&t.last_n_events','&t.time','&t.action','&t.artifact','&t.registry','&t.source','rows']),
        'registry_search_bar': ('registry: &[u8], placeholder: &[u8]', None),
        'header_dark': ('lang: Lang', ['en_class','ru_class','zh_class']),
        'render_polling_script': ('', []),
    }
    for r in records:
        name = r['name']
        if name not in arguments:continue
        sig,args = arguments[name]
        source=r['source']
        match, = re.findall(r'r(#+)"(.*?)"\1',source,re.S)
        raw=match[1]
        is_format = 'format!(' in source
        if not is_format: pieces=[(False,raw)]
        else:
            import string
            pieces=[]
            count=0
            for constant,field,spec,conversion in string.Formatter().parse(raw):
                assert not spec and not conversion
                if constant:pieces.append((False,constant))
                if field is not None:
                    if field=='':field=args[count];count+=1
                    pieces.append((True,field))
            if args is not None:assert count==len(args)
        r['pieces']=pieces
        if name == 'header_dark':
            # Exhaust the closed three-value domain. Retain and test the original
            # formatting body; fold only its literal substitutions here.
            choices = re.findall(r'Lang::(En|Ru|Zh)\s*=>\s*\((.*?)\)', source, re.S)
            assert [variant for variant, _ in choices] == ['En', 'Ru', 'Zh']
            chunks = []
            variants = []
            for variant, fields in choices:
                classes = [json.loads(value) for value in re.findall(r'"(?:\\.|[^"\\])*"', fields)]
                assert len(classes) == 3
                substitutions = dict(zip(['en_class', 'ru_class', 'zh_class'], classes))
                output = ''.join(substitutions[part] if dynamic else part for dynamic, part in pieces)
                indices = []
                for start in range(0, len(output), 256):
                    piece = output[start:start+256]
                    if piece not in chunks:
                        chunks.append(piece)
                    indices.append(chunks.index(piece))
                variants.append((variant, indices))
            r['header_chunks'] = {'chunks': chunks, 'variants': variants}
            for index, piece in enumerate(chunks):
                kernel += f'\npub fn header_piece_{index}() -> Vec<u8> {{ {lit(piece)}.to_vec() }}\n'
            kernel += f'\npub fn {name}({sig}) -> Vec<u8> {{\n    match lang {{\n'
            for variant, indices in variants:
                kernel += f'        Lang::{variant} => {{\n            let mut out = Vec::new();\n'
                for index in indices:
                    kernel += f'            let piece = header_piece_{index}();\n            append(&mut out, &piece);\n'
                kernel += '            out\n        },\n'
            kernel += '    }\n}\n'
            continue
        kernel+=f'\npub fn {name}({sig}) -> Vec<u8> {{\n'
        if name=='render_activity_row':
            kernel+='    let action_color = action_color(action);\n'

        kernel+='    let mut out = Vec::new();\n'
        for dynamic,part in pieces:
            expr = part if dynamic else lit(part)
            if expr.startswith('html_escape(') or expr in ('action_color','en_class','ru_class','zh_class'):expr='&'+expr
            if not dynamic:
                # Bound extracted constant arrays; large arrays are expensive for Aeneas.
                for start in range(0,len(part),96):
                    kernel+=f'    append(&mut out, {lit(part[start:start+96])});\n'
            else:
                kernel+=f'    append(&mut out, {expr});\n'
        kernel+='    out\n}\n'
    (folder/'plan.json').write_text(json.dumps({'revision':rev,'records':records},indent=2)+'\n')
    (PORT/'kernel/src/rendering.rs').write_text(kernel)
    p=PORT/'kernel/src/lib.rs';s=p.read_text()
    if 'pub mod rendering;' not in s:p.write_text(s+'\npub mod rendering;\n')
    p=PORT/'h5i-app.toml';s=p.read_text();i=s.index(']',s.index('start-from ='))
    roots=[f'rendering::{r["name"]}' for r in records]
    missing=[x for x in roots if '"'+x+'"' not in s]
    if missing:s=s[:i]+', '+', '.join('"'+x+'"' for x in missing)+s[i:]
    p.write_text(s)
    print(f'Generated {len(records)} retained functions and complete byte kernels.')

def integrate():
    plan = json.loads((PORT / 'difftest/rendering/plan.json').read_text())
    path = PORT / 'proofs/Properties.lean'
    text = path.read_text()
    imp = 'import Verified.Rendering\n'
    if imp not in text:
        text = imp + text
    marker = '-- Complete pinned Nora rendering outputs.\n'
    if marker in text:
        text = text.split(marker)[0]
    additions = marker + 'namespace nora_kernel.Properties\nopen Verified.Rendering\n\n'
    args = {
        'render_activity_row': ('(timestamp action artifact registry source : Slice U8)', 'timestamp action artifact registry source', 'timestamp.val action.val artifact.val registry.val source.val'),
        'render_activity_log': ('(rows : Slice U8) (t : rendering.Translations)', 'rows t', 'rows.val t'),
        'registry_search_bar': ('(registry placeholder : Slice U8)', 'registry placeholder', 'registry.val placeholder.val'),
        'render_polling_script': ('', '', ''),
        'header_dark': ('(lang : rendering.Lang)', 'lang', 'lang'),
        'html_escape': ('(s : Slice U8)', 's', 's.val'),
        'encode_uri_component': ('(s : Slice U8)', 's', 's.val'),
    }
    for rec in plan['records']:
        name = rec['name']
        decl, call, modelargs = args[name]
        model = {'html_escape': 'replacements_model', 'encode_uri_component': 'uri_model'}.get(name, name + '_model')
        proof = f'Verified.Rendering.{name}_complete {call} hbound'
        if name == 'html_escape':
            proof = '''by
  have hb : (html_model s.val).length ≤ Usize.max := by
    simpa only [html_model_replacements] using hbound
  apply WP.spec_mono (Verified.Rendering.html_escape_complete s hb)
  intro r hr
  exact hr.trans (html_model_replacements s.val)'''
        additions += f'''theorem rendering_{name}_complete {decl}
    (hbound : ({model} {modelargs}).length ≤ Usize.max) :
    rendering.{name} {call} ⦃r => r.val = {model} {modelargs}⦄ :=
  {proof}

'''
    additions = '\n'.join(line.rstrip() for line in additions.splitlines()) + '\n'
    path.write_text(text + additions + 'end nora_kernel.Properties\n')
    path = PORT / 'h5i-app.toml'
    text = path.read_text()
    for rec in plan['records']:
        theorem = f'nora_kernel.Properties.rendering_{rec["name"]}_complete'
        if '"' + theorem + '"' not in text:
            i = text.rfind(']')
            text = text[:i] + f'  "{theorem}",\n' + text[i:]
    path.write_text(text)
    path = ROOT / 'harness/source-mappings/nora.json'
    mapping = json.loads(path.read_text())
    for rec in plan['records']:
        mapping['declarations']['rendering.' + rec['name']] = [rec['meta']]
    path.write_text(json.dumps(mapping, indent=2) + '\n')


def audit():
    folder = PORT / 'difftest/rendering'
    plan = json.loads((folder / 'plan.json').read_text())
    mapping = json.loads((ROOT / 'harness/source-mappings/nora.json').read_text())
    assert plan['revision'] == mapping['upstream_revision']
    assert sorted(r['name'] for r in plan['records']) == sorted(n for names in SELECT.values() for n in names)
    i18n = subprocess.check_output(['git', f'--git-dir={ROOT}/results/upstream/nora.git',
                                   'show', plan['revision'] + ':nora-registry/src/ui/i18n.rs'], text=True)
    lang = re.search(r'pub enum Lang\s*\{(.*?)\}', i18n, re.S).group(1)
    lang = re.sub(r'#\[.*?\]', '', lang)
    assert [variant.strip() for variant in lang.split(',') if variant.strip()] == ['En', 'Ru', 'Zh']
    for field in ['recent_activity', 'last_n_events', 'time', 'action', 'artifact', 'registry', 'source']:
        assert re.search(r'pub\s+' + field + r":\s*&'static\s+str", i18n), field
    reference = (folder / 'reference.rs').read_text()
    for record in plan['records']:
        meta = record['meta']
        original = subprocess.check_output(['git', f'--git-dir={ROOT}/results/upstream/nora.git', 'show', plan['revision'] + ':' + meta['file']], text=True).splitlines()
        retained = '\n'.join(original[meta['start'] - 1:meta['end']])
        assert record['source'] == retained
        assert hashlib.sha256(retained.encode()).hexdigest() == meta['sha256']
        assert retained in reference
    artifacts = [folder / 'plan.json', folder / 'reference.rs', PORT / 'kernel/src/rendering.rs',
                 PORT / 'kernel/src/lib.rs', PORT / 'h5i-app.toml', PORT / 'kernel/tests/rendering.rs',
                 PORT / 'proofs/Verified/Rendering.lean', PORT / 'proofs/Properties.lean',
                 ROOT / 'harness/source-mappings/nora.json']
    before = {p: p.read_bytes() for p in artifacts}
    generate()
    import runpy
    runpy.run_path(str(ROOT / 'harness/nora_rendering_proofs.py'))
    integrate()
    assert all(p.read_bytes() == content for p, content in before.items()), 'non-reproducible artifact'
    print('Seven complete pinned functions and deterministic rendering kernels audited.')


if __name__ == '__main__':
    if sys.argv[1:] == ['audit']:
        audit()
    elif sys.argv[1:] == ['integrate']:
        integrate()
    else:
        generate()
