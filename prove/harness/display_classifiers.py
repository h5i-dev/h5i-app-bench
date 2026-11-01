"""Reproduce the pinned OxiCloud display decision trees over byte strings.

Output enums intern exact static output strings. Rules are ordered; exact MIME
rules precede MIME prefix/substring rules, which precede extension fallback.
No filename parsing, lowercasing, Unicode normalization or effects are modeled.
"""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'harness'))
from finite_catalog import clean

FILE = 'src/application/dtos/display_helpers.rs'
NAMES = ['icon_class_with_ext', 'icon_special_class_with_ext', 'category_with_ext']


def generate():
    port = ROOT / 'ports/oxicloud'
    mapping = json.loads((ROOT / 'harness/source-mappings/oxicloud.json').read_text())
    rev = mapping['upstream_revision']
    source = subprocess.check_output(['git', f'--git-dir={ROOT}/results/upstream/oxicloud.git', 'show', rev + ':' + FILE], text=True)
    records = []
    for name in NAMES:
        start = source.index('fn ' + name + '(')
        opening = source.index('{', start)
        depth = 1
        end = opening + 1
        while depth:
            depth += (source[end] == '{') - (source[end] == '}')
            end += 1
        raw = source[start:end]
        text = clean(raw)
        exact, rest = text.split('match mime {', 1)[1].split('_ => {}', 1)
        first = []
        for m in re.finditer(r'((?:"[^"]*"\s*\|?\s*)+)\s*=>\s*(?:\{\s*)?return\s+"([^"]*)"\s*[;,]', exact):
            first += [('eq', s, m[2]) for s in re.findall(r'"([^"]*)"', m[1])]
        # Reject anything the parser did not consume, including unknown syntax.
        consumed = re.sub(r'((?:"[^"]*"\s*\|?\s*)+)\s*=>\s*(?:\{\s*)?return\s+"([^"]*)"\s*[;,]\s*\}?\s*,?', '', exact)
        assert not consumed.strip(), consumed
        mid, last = rest.split('if let Some(ext) = ext {', 1)
        middle = []
        for m in re.finditer(r'if\s+(.*?)\s*\{\s*return\s+"([^"]*)";\s*\}', mid, re.S):
            cond = m[1]
            predicates = re.findall(r'mime\.(starts_with|contains)\("([^"]*)"\)', cond)
            assert re.sub(r'mime\.(?:starts_with|contains)\("[^"]*"\)|\|\||\s', '', cond) == ''
            middle += [('prefix' if op == 'starts_with' else 'contains', s, m[2]) for op, s in predicates]
        unconsumed = re.sub(r'if\s+.*?\s*\{\s*return\s+"[^"]*";\s*\}', '', mid, flags=re.S)
        assert not re.sub(r'\belse\b|[\s}]', '', unconsumed), unconsumed
        ext_text, tail = last.split('return match ext {', 1)[1].split('_ =>', 1)
        extension = []
        for m in re.finditer(r'((?:"[^"]*"\s*\|?\s*)+)\s*=>\s*(?:\{\s*)?"([^"]*)"\s*(?:\}\s*,?|,)', ext_text):
            extension += [('eq', s, m[2]) for s in re.findall(r'"([^"]*)"', m[1])]
        consumed = re.sub(r'((?:"[^"]*"\s*\|?\s*)+)\s*=>\s*(?:\{\s*)?"([^"]*)"\s*(?:\}\s*,?|,)', '', ext_text)
        assert not consumed.strip(), consumed
        fallback = re.findall(r'"([^"]*)"', tail)
        assert len(fallback) == 2 and fallback[0] == fallback[1]
        records.append(dict(name=name, source=raw, exact=first, mime=middle, ext=extension, default=fallback[0],
                            meta=dict(file=FILE, kind='fn', name=name, self_ty='', start=source[:start].count('\n')+1,
                                      end=source[:end].count('\n')+1, sha256=hashlib.sha256(raw.encode()).hexdigest())))
    outputs = sorted({r[2] for rec in records for k in ['exact','mime','ext'] for r in rec[k]} | {r['default'] for r in records})
    def label(s): return 'V' + str(outputs.index(s))
    rust = '//! Ordered display classifiers; output enum variants intern exact UTF-8 strings.\n#[derive(Clone,Copy,Debug,PartialEq,Eq)]\npub enum DisplayValue { ' + ','.join(label(s) for s in outputs) + ' }\n'
    rust += '''
pub fn starts_at(hay: &[u8], needle: &[u8], at: usize) -> bool {
    if at > hay.len() { return false; }
    if needle.len() > hay.len() - at { return false; }
    &hay[at..at + needle.len()] == needle
}
pub fn prefix(hay: &[u8], needle: &[u8]) -> bool { starts_at(hay, needle, 0) }
pub fn contains(hay: &[u8], needle: &[u8]) -> bool {
    if needle.len() > hay.len() { return false; }
    let last = hay.len() - needle.len();
    let mut i = 0;
    loop {
        if starts_at(hay, needle, i) { return true; }
        if i == last { return false; }
        i += 1;
    }
}
'''
    chunks = []
    for rec in records:
        for stage in ['exact','mime','ext']:
            rules = rec[stage]
            stage_chunks = []
            for i in range(0, len(rules), 6):
                name = f'{rec["name"]}_{stage}_{i//6}'
                selected = rules[i:i+6]
                rust += f'pub fn {name}(raw: &[u8]) -> Option<DisplayValue> {{\n'
                for op, key, val in selected:
                    lit = 'b' + json.dumps(key)
                    cond = f'raw == {lit}.as_slice()' if op == 'eq' else f'{op}(raw, {lit})'
                    rust += f'    if {cond} {{ return Some(DisplayValue::{label(val)}); }}\n'
                rust += '    None\n}\n'
                chunks.append(dict(name=name, rules=selected))
                stage_chunks.append(name)
            rec[stage + '_chunks'] = stage_chunks
        rust += f'pub fn {rec["name"]}(mime: &[u8], ext: Option<&[u8]>) -> DisplayValue {{\n'
        for name in rec['exact_chunks'] + rec['mime_chunks']:
            rust += f'    if let Some(v) = {name}(mime) {{ return v; }}\n'
        rust += '    if let Some(ext) = ext {\n'
        for name in rec['ext_chunks']:
            rust += f'        if let Some(v) = {name}(ext) {{ return v; }}\n'
        rust += f'    }}\n    DisplayValue::{label(rec["default"])}\n}}\n'
    folder = port / 'difftest/display_classifiers'
    folder.mkdir(parents=True, exist_ok=True)
    (port / 'kernel/src/display_classifiers.rs').write_text(rust)
    (folder / 'reference.rs').write_text('\n\n'.join(r['source'] for r in records) + '\n')
    plan = dict(revision=rev, file=FILE, records=records, outputs=outputs, chunks=chunks)
    (folder / 'plan.json').write_text(json.dumps(plan, indent=2) + '\n')
    print('Generated', len(records), 'classifiers;', len(chunks), 'proof chunks;', len(outputs), 'exact output strings')


def integrate():
    port = ROOT / 'ports/oxicloud'
    plan = json.loads((port / 'difftest/display_classifiers/plan.json').read_text())
    path = port / 'proofs/Properties.lean'
    text = path.read_text()
    imp = 'import Verified.DisplayClassifiers\n'
    if imp not in text:
        text = imp + text
    marker = '-- Complete arbitrary-byte display decisions.\n'
    if marker in text:
        text = text.split(marker)[0] + 'end oxicloud_kernel.Properties\n'
    additions = marker
    for rec in plan['records']:
        name = rec['name']
        additions += f'''theorem display_{name}_complete (mime : Slice U8) (ext : Option (Slice U8)) :
    display_classifiers.{name} mime ext ⦃r => r = Verified.DisplayClassifiers.{name}_model mime.val (ext.map Slice.val)⦄ :=
  Verified.DisplayClassifiers.{name}_complete mime ext

'''
    text = text.removesuffix('end oxicloud_kernel.Properties\n') + additions + 'end oxicloud_kernel.Properties\n'
    path.write_text(text)
    path = port / 'h5i-app.toml'
    text = path.read_text()
    for rec in plan['records']:
        name = f'oxicloud_kernel.Properties.display_{rec["name"]}_complete'
        if '"' + name + '"' not in text:
            i = text.rfind(']')
            text = text[:i] + f'  "{name}",\n' + text[i:]
    path.write_text(text)
    path = ROOT / 'harness/source-mappings/oxicloud.json'
    mapping = json.loads(path.read_text())
    for rec in plan['records']:
        mapping['declarations']['display_classifiers.' + rec['name']] = [rec['meta']]
    path.write_text(json.dumps(mapping, indent=2) + '\n')


def audit():
    port = ROOT / 'ports/oxicloud'
    folder = port / 'difftest/display_classifiers'
    plan = json.loads((folder / 'plan.json').read_text())
    reference = (folder / 'reference.rs').read_text()
    original = subprocess.check_output(['git', f'--git-dir={ROOT}/results/upstream/oxicloud.git', 'show', plan['revision'] + ':' + FILE], text=True).splitlines()
    assert len(set(plan['outputs'])) == len(plan['outputs']) == 54
    for rec in plan['records']:
        meta = rec['meta']
        retained = '\n'.join(original[meta['start'] - 1:meta['end']])
        assert retained == rec['source']
        assert hashlib.sha256(retained.encode()).hexdigest() == meta['sha256']
        assert retained in reference
    artifacts = [port / 'kernel/src/display_classifiers.rs', folder / 'reference.rs', folder / 'plan.json',
                 port / 'kernel/tests/display_classifiers.rs', port / 'proofs/Verified/DisplayClassifiers.lean',
                 port / 'proofs/Properties.lean', port / 'h5i-app.toml', ROOT / 'harness/source-mappings/oxicloud.json']
    before = {str(p): p.read_bytes() for p in artifacts}
    generate()
    import runpy
    for component in ['tests', 'proofs']:
        runpy.run_path(str(ROOT / f'harness/display_classifiers_{component}.py'))
    integrate()
    assert all(p.read_bytes() == before[str(p)] for p in artifacts), 'non-reproducible artifact'
    print('Pinned sources, unique complete strings and deterministic artifacts audited.')


if __name__ == '__main__':
    if sys.argv[1:] == ['audit']:
        audit()
        raise SystemExit(0)
    generate()
    import runpy
    for component in ['tests', 'proofs']:
        runpy.run_path(str(ROOT / f'harness/display_classifiers_{component}.py'))
    integrate()
