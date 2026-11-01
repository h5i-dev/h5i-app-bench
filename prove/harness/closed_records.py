"""Port complete, syntactically closed record constructors from pinned Rust.

Only complete literal record initializers over scalars, UTF-8 strings, empty
vectors, None and unit enums are admitted. No calls other than String/Vec::new
and literal string ownership conversions are allowed. This is deliberately a
closed expression grammar, not a purity inference. Carrier records retain every
upstream field and its scalar type; only String becomes Vec<u8> in the kernel.
"""
import argparse
import gzip
import hashlib
import io
import json
import re
import subprocess
import tarfile
from pathlib import Path
from finite_catalog import clean

ROOT = Path(__file__).resolve().parents[1]
SCALARS = {'bool', 'u8', 'u16', 'u32', 'u64', 'usize'}
STRING = r'"(?:\\.|[^"\\])*"'


def snake(name):
    return re.sub(r'(?<!^)(?=[A-Z])', '_', name).lower()


def fields(source, name):
    text = re.sub(r'#\[[^\]]*\]', '', clean(source))
    match = re.fullmatch(r'\s*(?:pub\s+)?struct\s+' + name + r'\s*\{(.*)\}\s*', text, re.S)
    if not match:
        raise ValueError('non-simple carrier')
    body = match[1]
    pattern = re.compile(r'\s*(?:pub\s+)?(\w+)\s*:\s*([\w<> ]+)\s*,')
    result = pattern.findall(body)
    if pattern.sub('', body).strip() or not result:
        raise ValueError('non-simple fields')
    return [(n, t.replace(' ', '')) for n, t in result]


def admitted_type(ty, enums):
    if ty in SCALARS or ty == 'String' or ty in enums:
        return True
    m = re.fullmatch(r'(?:Option|Vec)<(.*)>', ty)
    return bool(m and admitted_type(m[1], enums))


def expression(expr, ty, enums):
    """Validate before translating. Reject unknown syntax and hidden calls."""
    if ty == 'bool' and expr in ('true', 'false'):
        return expr
    if ty in SCALARS - {'bool'} and re.fullmatch(r'[0-9][0-9_]*(?:\s*\*\s*[0-9][0-9_]*)*', expr):
        return expr
    if ty == 'String':
        if expr == 'String::new()':
            return 'Vec::new()'
        m = re.fullmatch('(' + STRING + r')\.(?:to_string|to_owned)\(\)', expr)
        if m:
            value = json.loads(m[1]).encode()
            return 'b"' + ''.join(chr(b) if 32 <= b < 127 and b not in (34, 92) else f'\\x{b:02x}' for b in value) + '".to_vec()'
    if ty.startswith('Option<') and expr == 'None':
        return expr
    if ty.startswith('Vec<') and expr == 'Vec::new()':
        return expr
    if ty in enums and expr in [ty + '::' + v for v in enums[ty]]:
        return expr
    raise ValueError(f'non-closed expression {expr!r} : {ty}')


def kernel_type(ty):
    return re.sub(r'\bString\b', 'Vec<u8>', ty)


def prepare(app, port):
    mapping = json.loads((ROOT / f'harness/source-mappings/{app}.json').read_text())
    revision = mapping['upstream_revision']
    rows = [json.loads(line) for line in gzip.open(ROOT / 'results/source-coverage/kernel-ceiling-items.jsonl.gz', 'rt')]
    candidates = [r for r in rows if r['app'] == app and r['kind'] == 'method' and r['name'] in ('default', 'new', 'empty')]
    files = sorted({r['file'] for r in candidates})
    if not files:
        raise ValueError('no candidate files')
    archive = subprocess.check_output(['git', f'--git-dir={ROOT}/results/upstream/{app}.git', 'archive', revision, *files])
    sources = {}
    with tarfile.open(fileobj=io.BytesIO(archive)) as tar:
        for member in tar:
            if member.isfile() and member.name in files:
                sources[member.name] = tar.extractfile(member).read().decode().splitlines()
    def body(row):
        return '\n'.join(sources[row['file']][row['start']-1:row['end']])
    records, rejected = [], []
    covered = [s for key, spans in mapping['declarations'].items() if not key.startswith('closed_records.') for s in spans]
    for row in candidates:
        if any(s['file'] == row['file'] and s['start'] <= row['start'] and s['end'] >= row['end'] for s in covered):
            continue
        name = row['self_ty']
        try:
            if not re.fullmatch(r'\w+', name):
                raise ValueError('generic carrier')
            carrier, = [r for r in rows if r['app'] == app and r['file'] == row['file'] and r['kind'] == 'struct' and r['name'] == name]
            fs = fields(body(carrier), name)
            enums = {}
            for en in rows:
                if en['app'] != app or en['file'] != row['file'] or en['kind'] != 'enum':
                    continue
                raw = body(en)
                if '#[cfg' in raw:
                    continue
                en_text = re.sub(r'#\[[^\]]*\]', '', clean(raw))
                match = re.search(r'enum\s+' + en['name'] + r'\s*\{\s*((?:\w+\s*,\s*)*\w*\s*)\}', en_text)
                if match:
                    enums[en['name']] = [v.strip() for v in match[1].split(',') if v.strip()]
            if not all(admitted_type(t, enums) for _, t in fs):
                raise ValueError('unsupported field type')
            raw = body(row)
            if '#[cfg' in raw or '#[cfg' in body(carrier):
                raise ValueError('conditional definition')
            text = re.sub(r'#\[[^\]]*\]', '', clean(raw))
            match = re.fullmatch(r'\s*(?:pub(?:\([^)]*\))?\s+)?fn\s+' + row['name'] + r'\s*\(\s*\)\s*->\s*Self\s*\{\s*Self\s*\{(.*?)\}\s*\}\s*', text, re.S)
            if not match:
                raise ValueError('non-literal default body')
            # String literals may contain commas: tokenize them before splitting.
            strings = []
            def intern(m):
                strings.append(m[0]); return f'__STRING_{len(strings)-1}__'
            assignments = re.sub(STRING, intern, match[1])
            initializers = []
            for item in assignments.split(','):
                if not item.strip():
                    continue
                key, sep, expr = item.partition(':')
                if not sep:
                    raise ValueError('non-explicit field')
                expr = re.sub(r'__STRING_(\d+)__', lambda m: strings[int(m[1])], expr.strip())
                initializers.append((key.strip(), expr))
            if [k for k, _ in initializers] != [k for k, _ in fs]:
                raise ValueError('fields/order mismatch')
            translated = [(k, expression(expr, ty, enums)) for (k, expr), (_, ty) in zip(initializers, fs)]
            used = {en for en in enums if any(re.search(r'\b' + en + r'\b', t) for _,t in fs)}
            enums = {k: enums[k] for k in sorted(used)}
            meta = {k: row[k] for k in ('file', 'kind', 'name', 'self_ty', 'start', 'end')}
            meta['sha256'] = hashlib.sha256(raw.encode()).hexdigest()
            record = {'name': name, 'id': snake(name) + '_' + row['name'] + '_' + hashlib.sha256(row['file'].encode()).hexdigest()[:8],
                      'source': raw, 'meta': meta, 'carrier_source': body(carrier), 'fields': fs,
                      'enums': enums, 'initializers': translated}
            records.append(record)
        except (ValueError, KeyError) as error:
            rejected.append({'file': row['file'], 'type': name, 'reason': str(error)})
    assert records, 'no admitted records'
    folder = port / 'difftest/closed_records'
    folder.mkdir(parents=True, exist_ok=True)
    # Compile unchanged pinned constructors. Wire encodes string UTF-8 bytes,
    # not Debug strings; enum variants retain their exact names.
    reference = '''#![allow(dead_code)]
trait Wire { fn wire(&self) -> String; }
macro_rules! scalar { ($($t:ty),*) => {$(impl Wire for $t {fn wire(&self)->String{self.to_string()}})*}; }
scalar!(bool,u8,u16,u32,u64,usize);
impl Wire for String { fn wire(&self)->String {format!("{:?}",self.as_bytes())} }
impl<T:Wire> Wire for Vec<T> { fn wire(&self)->String {format!("[{}]",self.iter().map(Wire::wire).collect::<Vec<_>>().join(","))} }
impl<T:Wire> Wire for Option<T> {fn wire(&self)->String {match self {None=>"null".into(),Some(x)=>x.wire()}}}
'''
    for r in records:
        reference += f'mod {r["id"]} {{\nuse super::Wire;\n'
        for ty, vs in r['enums'].items():
            reference += f'pub enum {ty} {{' + ','.join(vs) + '}\n'
            reference += f'impl Wire for {ty} {{fn wire(&self)->String {{match self {{' + ','.join(f'Self::{v}=>"\\\"{v}\\\"".into()' for v in vs) + '}}}\n'
        reference += 'pub struct ' + r['name'] + '{' + ','.join(f'pub {k}:{t}' for k,t in r['fields']) + '}\n'
        reference += (f'impl Default for {r["name"]}' if r['meta']['name'] == 'default' else f'impl {r["name"]}') + ' {\n' + r['source'] + '\n}\n'
        reference += f'pub fn emit() {{let x = {r["name"]}::{r['meta']['name']}();\n'
        reference += ''.join(f'println!("{r["id"]}.{k}\\t{{}}",x.{k}.wire());\n' for k,_ in r['fields']) + '}\n}\n'
    reference += 'fn main(){' + ''.join(r['id'] + '::emit();' for r in records) + '}\n'
    (folder / 'reference.rs').write_text(reference)
    subprocess.run(['rustc', '--edition=2021', str(folder / 'reference.rs'), '-o', str(folder / 'reference')], check=True)
    outputs = dict(line.split('\t',1) for line in subprocess.check_output([str(folder / 'reference')], text=True).splitlines())
    for r in records:
        r['values'] = {k: json.loads(outputs[r['id'] + '.' + k]) for k,_ in r['fields']}
    plan = {'app': app, 'revision': revision, 'records': records, 'rejected': rejected}
    (folder / 'plan.json').write_text(json.dumps(plan, indent=2) + '\n')
    return plan


def predicate(expr, ty, value):
    if ty == 'String' or ty.startswith('Vec<'):
        assert isinstance(value, list)
        return expr + '.val = [' + ', '.join(f'{b}#u8' for b in value) + ']'
    if ty.startswith('Option<'):
        assert value is None
        return expr + ' = none'
    if ty == 'bool':
        return expr + ' = ' + str(value).lower()
    if ty in SCALARS:
        return expr + '.val = ' + str(value)
    return expr + ' = .' + value


def generate(app, port):
    plan = prepare(app, port)
    kernel = '//! Complete closed defaults; String fields preserve their UTF-8 bytes.\n'
    proof = f'''import {app.title()}Kernel
import H5iAppLib
open Aeneas Aeneas.Std Result H5iAppLib {app}_kernel
namespace {app}_kernel.Verified.ClosedRecords
set_option maxHeartbeats 1000000
@[step] theorem bytes_to_vec (s : Slice U8) :
    alloc.slice.Slice.to_vec core.clone.CloneU8 s ⦃r => r.val = s.val⦄ := by
  apply WP.spec_mono (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 s (by intros; rfl))
  intro r hr
  exact (congrArg Slice.val hr).symm
'''
    tests = '#[path="../../../kernel/src/closed_records.rs"]\nmod kernel;\n'
    for r in plan['records']:
        ident, name = r['id'], r['name']
        kernel += f'pub mod {ident} {{\n'
        for ty, vs in r['enums'].items():
            kernel += f'pub enum {ty} {{' + ','.join(vs) + '}\n'
        kernel += 'pub struct ' + name + '{' + ','.join(f'pub {k}:{kernel_type(t)}' for k,t in r['fields']) + '}\n'
        kernel += f'pub fn make() -> {name} {{ {name} {{' + ','.join(f'{k}: {expr}' for k,expr in r['initializers']) + '} }\n}\n'
        prop = ' ∧\n      '.join(predicate('r.'+k,t,r['values'][k]) for k,t in r['fields'])
        proof += f'''\n@[step] theorem {ident}_complete :
    closed_records.{ident}.make ⦃r => {prop}⦄ := by
  unfold closed_records.{ident}.make
  h5i_steps
  all_goals simp_all only [Array.to_slice, Array.make_val, Slice.from_val]
  all_goals scalar_tac
'''
        tests += f'#[test]\nfn {ident}_complete() {{let r=kernel::{ident}::make();\n'
        for k,t in r['fields']:
            value = r['values'][k]
            if t in SCALARS:
                expected = str(value).lower()
            elif t == 'String':
                expected = '&[' + ','.join(str(b)+'u8' for b in value) + ']'
            elif t.startswith('Option<'):
                tests += f'assert!(r.{k}.is_none());\n'; continue
            elif t.startswith('Vec<'):
                assert value == []
                tests += f'assert!(r.{k}.is_empty());\n'; continue
            else:
                tests += f'assert!(matches!(r.{k},kernel::{ident}::{t}::{value}));\n'; continue
            tests += f'assert_eq!(r.{k},{expected});\n'
        tests += '}\n'
    proof += f'\nend {app}_kernel.Verified.ClosedRecords\n'
    (port / 'kernel/src').mkdir(parents=True, exist_ok=True)
    (port / 'proofs/Verified').mkdir(parents=True, exist_ok=True)
    (port / 'kernel/src/closed_records.rs').write_text(kernel)
    (port / 'proofs/Verified/ClosedRecords.lean').write_text(proof)
    folder = port / 'difftest/closed_records'
    (folder / 'tests').mkdir(exist_ok=True)
    (folder / 'tests/complete.rs').write_text(tests)
    (folder / 'Cargo.toml').write_text('[package]\nname="closed-records-reference"\nversion="0.1.0"\nedition="2021"\npublish=false\n[workspace]\n')
    (folder / 'src').mkdir(exist_ok=True)
    (folder / 'src/lib.rs').write_text('// Independent retained constructor reference: ../reference.rs\n')
    (folder / '.gitignore').write_text('/reference\n/target/\n')
    print(f'{app}: generated {len(plan["records"])} complete closed record constructors; {len(plan["rejected"])} rejected.')


def integrate(app, port):
    assert port == ROOT / 'ports' / app, 'Integration requires the production port.'
    plan = json.loads((port / 'difftest/closed_records/plan.json').read_text())
    path = port / 'kernel/src/lib.rs'
    source = path.read_text()
    if 'pub mod closed_records;' not in source:
        path.write_text(source.rstrip() + '\n\npub mod closed_records;\n')
    path = port / 'proofs/Properties.lean'
    source = path.read_text()
    if 'import Verified.ClosedRecords\n' not in source:
        source = 'import Verified.ClosedRecords\n' + source
    marker = '-- Complete pinned closed record constructors.\n'
    suffix = ''
    if marker in source:
        start = source.index(marker)
        ending = f'end {app}_kernel.Properties\n'
        stop = source.index(ending, start) + len(ending)
        suffix = source[stop:]
        source = source[:start]
    source += marker + f'namespace {app}_kernel.Properties\n\n'
    for record in plan['records']:
        ident = record['id']
        prop = ' ∧\n      '.join(predicate('r.' + k, t, record['values'][k]) for k,t in record['fields'])
        source += f"theorem closed_records_{ident}_complete :\n    closed_records.{ident}.make ⦃r => {prop}⦄ :=\n  Verified.ClosedRecords.{ident}_complete\n\n"
    source += f'end {app}_kernel.Properties\n' + suffix
    path.write_text(source)
    path = port / 'h5i-app.toml'
    source = path.read_text()
    def extend(match):
        content = match[2]
        if '"closed_records"' not in content:
            content = content.rstrip().rstrip(',') + ', "closed_records"'
        return match[1] + content + match[3]
    source, count = re.subn(r'(start-from\s*=\s*\[)(.*?)(\])', extend, source, count=1, flags=re.S)
    assert count == 1
    for record in plan['records']:
        name = f'"{app}_kernel.Properties.closed_records_{record["id"]}_complete"'
        if name not in source:
            end = source.rfind(']')
            source = source[:end] + f'  {name},\n' + source[end:]
    path.write_text(source)
    path = ROOT / f'harness/source-mappings/{app}.json'
    mapping = json.loads(path.read_text())
    for record in plan['records']:
        mapping['declarations']['closed_records.' + record['id'] + '.make'] = [record['meta']]
    path.write_text(json.dumps(mapping, indent=2) + '\n')


def audit(app, port):
    folder = port / 'difftest/closed_records'
    files = [folder / p for p in ('reference.rs','plan.json','Cargo.toml','Cargo.lock','src/lib.rs','tests/complete.rs','.gitignore')]
    files += [port / 'kernel/src/closed_records.rs', port / 'proofs/Verified/ClosedRecords.lean']
    production = port == ROOT / 'ports' / app
    if production:
        files += [port / 'kernel/src/lib.rs', port / 'proofs/Properties.lean', port / 'h5i-app.toml', ROOT / f'harness/source-mappings/{app}.json']
    before = {p: p.read_bytes() for p in files}
    generate(app, port)
    if production:
        integrate(app, port)
    assert all(p.read_bytes() == content for p,content in before.items()), 'non-reproducible generated artifact'
    subprocess.run(['cargo','test','--offline','--manifest-path', str(folder/'Cargo.toml')], check=True)
    print(f'{app}: unchanged pinned constructors, all fields and generated artifacts audited.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('generate','integrate','audit'), nargs='?', default='generate')
    parser.add_argument('--app', required=True)
    parser.add_argument('--port', type=Path, required=True)
    args = parser.parse_args()
    {'generate': generate, 'integrate': integrate, 'audit': audit}[args.action](args.app, args.port.resolve())
