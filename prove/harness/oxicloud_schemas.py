"""Reproduce complete closed AsyncAPI schema values from pinned OxiCloud Rust.

Only zero-argument, environment-independent roots receive source mappings.
Parameterized dependencies are retained for reference evaluation, with no
separate claim about their full input domains.
"""
import argparse
import gzip
import hashlib
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = 'src/bin/generate-asyncapi.rs'
CONSTANTS = 'src/application/ports/message_bus_ports.rs'
EXCLUDED = {'main', 'build_asyncapi'}
HELPERS = {'close_object_schema_shallow', 'ref_schema', 'rpc_request_schema',
           'rpc_typed_response_schema'}


def upstream(revision, file):
    return subprocess.check_output(['git', f'--git-dir={ROOT}/results/upstream/oxicloud.git',
                                    'show', f'{revision}:{file}'], text=True)


def literal(bs):
    return '[' + ', '.join(f'(UScalar.mk (BitVec.ofNat 8 {b}) : U8)' for b in bs) + ']'


def prepare(port):
    mapping = json.loads((ROOT / 'harness/source-mappings/oxicloud.json').read_text())
    revision = mapping['upstream_revision']
    source = upstream(revision, SOURCE).splitlines()
    records = []
    with gzip.open(ROOT / 'results/source-coverage/kernel-ceiling-items.jsonl.gz', 'rt') as stream:
        for line in stream:
            row = json.loads(line)
            if row['app'] != 'oxicloud' or row['file'] != SOURCE or row['kind'] != 'fn' or row['name'] in EXCLUDED:
                continue
            body = '\n'.join(source[row['start'] - 1:row['end']])
            closed = bool(re.search(r'fn\s+\w+\s*\(\s*\)\s*->\s*Value', body))
            assert closed or row['name'] in HELPERS, row['name']
            meta = {k: row[k] for k in ('file', 'kind', 'name', 'self_ty', 'start', 'end')}
            meta['sha256'] = hashlib.sha256(body.encode()).hexdigest()
            records.append({'name': row['name'], 'source': body, 'meta': meta, 'closed': closed})
    records.sort(key=lambda r: r['meta']['start'])
    assert len(records) == 37 and sum(r['closed'] for r in records) == 33
    constants_file = upstream(revision, CONSTANTS)
    begin = constants_file.index('pub mod error_code {')
    end = constants_file.index('\n}', begin) + 2
    constants = constants_file[begin:end]
    constants_code = re.sub(r'//[^\n]*', '', constants)
    assert constants_code.count('{') == constants_code.count('}') == 1
    folder = port / 'difftest/asyncapi'
    (folder / 'src').mkdir(parents=True, exist_ok=True)
    reference = '#![allow(dead_code)]\nuse serde_json::{Value, json};\n' + constants + '\n'
    reference += '\n'.join(r['source'] for r in records)
    roots = [r['name'] for r in records if r['closed']]
    reference += "\npub fn all_values() -> Vec<(&'static str, Value)> { vec![\n"
    reference += ''.join(f'    ("{name}", {name}()),\n' for name in roots) + '] }\n'
    (folder / 'src/lib.rs').write_text(reference)
    (folder / 'src/main.rs').write_text('fn main() {\n    let values: std::collections::BTreeMap<_, _> = asyncapi_reference::all_values().into_iter().collect();\n    println!("{}", serde_json::to_string(&values).unwrap());\n}\n')
    (folder / 'Cargo.toml').write_text('[package]\nname="asyncapi-reference"\nversion="0.1.0"\nedition="2024"\npublish=false\n[dependencies]\nserde_json="=1.0.154"\n[workspace]\n')
    values = json.loads(subprocess.check_output(['cargo', 'run', '--offline', '--quiet', '--manifest-path',
                                                str(folder / 'Cargo.toml')], text=True))
    assert set(values) == set(roots)
    plan = {'revision': revision, 'records': records,
            'constants': {'file': CONSTANTS, 'source': constants,
                          'sha256': hashlib.sha256(constants.encode()).hexdigest()},
            'representation': 'serde_json 1.0.154 compact UTF-8 JSON, sorted object keys; complete returned values',
            'values': values}
    (folder / 'plan.json').write_text(json.dumps(plan, indent=2, ensure_ascii=False) + '\n')
    return plan


def generate(port):
    plan = prepare(port)
    pieces = []
    roots = []
    for record in plan['records']:
        if not record['closed']:
            continue
        name = record['name']
        bs = json.dumps(plan['values'][name], ensure_ascii=False, separators=(',', ':'), sort_keys=True).encode()
        indices = []
        for offset in range(0, len(bs), 128):
            piece = bs[offset:offset + 128]
            if piece not in pieces:
                pieces.append(piece)
            indices.append(pieces.index(piece))
        roots.append((name, bs, indices))
    kernel = '//! Complete compact JSON bytes of the pinned, closed AsyncAPI schema builders.\n'
    proof = '''import OxicloudKernel
import H5iAppLib
open Aeneas Aeneas.Std Result H5iAppLib oxicloud_kernel
namespace oxicloud_kernel.Verified.Asyncapi
set_option maxRecDepth 65536
set_option maxHeartbeats 10000000
@[step] theorem schema_bytes_to_vec (s : Slice U8) :
    alloc.slice.Slice.to_vec core.clone.CloneU8 s ⦃r => r.val = s.val⦄ := by
  apply WP.spec_mono (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 s (by intros; rfl))
  intro r hr
  exact (congrArg Slice.val hr).symm
private theorem flatten_map (xs : List (alloc.vec.Vec U8)) :
    xs.flatMap alloc.vec.Vec.val = (xs.map alloc.vec.Vec.val).flatten := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp only [List.flatMap_cons, List.map_cons, List.flatten_cons, ih]
'''
    for index, bs in enumerate(pieces):
        kernel += f'pub fn piece_{index}() -> Vec<u8> {{ [' + ', '.join(f'{b}u8' for b in bs) + '].to_vec() }\n'
        proof += f'''
def piece_{index}_model : List U8 := {literal(bs)}
@[step] theorem piece_{index}_complete :
    asyncapi.piece_{index} ⦃r => r.val = piece_{index}_model⦄ := by
  unfold asyncapi.piece_{index}
  step* (grind := false) (threadGrindState := false)
  all_goals simp only [Array.to_slice, Array.make_val, Slice.from_val] at *
  all_goals simp_all only [piece_{index}_model, Slice.from_val]
  all_goals rfl
'''
    for name, bs, indices in roots:
        kernel += f'pub fn {name}() -> [Vec<u8>; {len(indices)}] {{ [' + ', '.join(f'piece_{i}()' for i in indices) + '] }\n'
        # The reference model uses different boundaries from the executable.
        parts = []
        for i, offset in enumerate(range(0, len(bs), 96)):
            part = f'{name}_reference_{i}'
            parts.append(part)
            proof += f'\ndef {part} : List U8 := {literal(bs[offset:offset + 96])}\n'
        proof += f'\ndef {name}_model : List U8 := [' + ', '.join(parts) + '].flatten\n'
        proof += f'def {name}_chunks : List (List U8) := [' + ', '.join(f'piece_{i}_model' for i in indices) + ']\n'
        proof += f'private theorem {name}_chunks_exact : {name}_chunks.flatten = {name}_model := by rfl\n'
    proof += '\nattribute [local irreducible] ' + ' '.join(f'piece_{i}_model' for i in range(len(pieces))) + '\n'
    for name, bs, indices in roots:
        proof += f'''
private theorem {name}_chunks_complete :
    asyncapi.{name} ⦃r => r.val.map alloc.vec.Vec.val = {name}_chunks⦄ := by
  unfold asyncapi.{name}
  step* (grind := false) (threadGrindState := false) (assumTac := false) (inferGhostVars := false)
  all_goals simp_all only [{name}_chunks, Array.make_val, List.map_cons, List.map_nil]
@[step] theorem {name}_complete :
    asyncapi.{name} ⦃r => r.val.flatMap alloc.vec.Vec.val = {name}_model⦄ := by
  apply WP.spec_mono {name}_chunks_complete
  intro r hr
  rw [flatten_map, hr]
  exact {name}_chunks_exact
'''
    proof += '\nend oxicloud_kernel.Verified.Asyncapi\n'
    (port / 'kernel/src').mkdir(parents=True, exist_ok=True)
    (port / 'kernel/src/asyncapi.rs').write_text(kernel)
    (port / 'proofs/Verified').mkdir(parents=True, exist_ok=True)
    (port / 'proofs/Verified/Asyncapi.lean').write_text(proof)
    tests = '''#[path="../../../kernel/src/asyncapi.rs"]
mod kernel;
#[test]
fn complete_closed_schema_values() {
    let values: std::collections::BTreeMap<_, _> = asyncapi_reference::all_values().into_iter().collect();
'''
    for name, _, _ in roots:
        tests += f'    assert_eq!(kernel::{name}().into_iter().flatten().collect::<Vec<u8>>(), serde_json::to_vec(&values["{name}"]).unwrap(), "{name}");\n'
    tests += '    assert_eq!(values.len(), 33);\n}\n'
    folder = port / 'difftest/asyncapi/tests'
    folder.mkdir(exist_ok=True)
    (folder / 'complete.rs').write_text(tests)
    print(f'Generated {len(roots)} closed schema roots and {len(pieces)} shared fragments in {port}.')


def integrate(port):
    assert port == ROOT / 'ports/oxicloud', 'Integration requires the production port.'
    plan = json.loads((port / 'difftest/asyncapi/plan.json').read_text())
    roots = [r for r in plan['records'] if r['closed']]
    path = port / 'kernel/src/lib.rs'
    source = path.read_text()
    if 'pub mod asyncapi;' not in source:
        path.write_text(source.rstrip() + '\n\npub mod asyncapi;\n')
    path = port / 'proofs/Properties.lean'
    source = path.read_text()
    if 'import Verified.Asyncapi\n' not in source:
        source = 'import Verified.Asyncapi\n' + source
    marker = '-- Complete closed pinned AsyncAPI schema values.\n'
    source = source.split(marker)[0]
    source += marker + 'namespace oxicloud_kernel.Properties\nopen Verified.Asyncapi\n\n'
    for row in roots:
        name = row['name']
        source += f'''theorem asyncapi_{name}_complete :
    asyncapi.{name} ⦃r => r.val.flatMap alloc.vec.Vec.val = {name}_model⦄ :=
  Verified.Asyncapi.{name}_complete

'''
    source += 'end oxicloud_kernel.Properties\n'
    path.write_text(source)
    path = port / 'h5i-app.toml'
    source = path.read_text()
    def extend_starts(match):
        content = match.group(2)
        for row in roots:
            item = f'"asyncapi::{row["name"]}"'
            if item not in content:
                content = content.rstrip().rstrip(',') + ', ' + item
        return match.group(1) + content + match.group(3)
    source, count = re.subn(r'(start-from\s*=\s*\[)(.*?)(\])', extend_starts, source, count=1, flags=re.S)
    assert count == 1
    for row in roots:
        theorem = f'"oxicloud_kernel.Properties.asyncapi_{row["name"]}_complete"'
        if theorem not in source:
            end = source.rfind(']')
            source = source[:end] + f'  {theorem},\n' + source[end:]
    path.write_text(source)
    path = ROOT / 'harness/source-mappings/oxicloud.json'
    mapping = json.loads(path.read_text())
    for row in roots:
        mapping['declarations']['asyncapi.' + row['name']] = [row['meta']]
    path.write_text(json.dumps(mapping, indent=2) + '\n')


def audit(port):
    folder = port / 'difftest/asyncapi'
    files = [folder / p for p in ('plan.json', 'Cargo.toml', 'Cargo.lock',
                                  'src/lib.rs', 'src/main.rs', 'tests/complete.rs')]
    files += [port / 'kernel/src/asyncapi.rs', port / 'proofs/Verified/Asyncapi.lean']
    production = port == ROOT / 'ports/oxicloud'
    if production:
        files += [port / 'kernel/src/lib.rs', port / 'h5i-app.toml',
                  port / 'proofs/Properties.lean', ROOT / 'harness/source-mappings/oxicloud.json']
    before = {p: p.read_bytes() for p in files}
    generate(port)
    if production:
        integrate(port)
    assert all(p.read_bytes() == content for p, content in before.items()), 'non-reproducible artifact'
    subprocess.run(['cargo', 'test', '--offline', '--manifest-path', str(folder / 'Cargo.toml')], check=True)
    print('All retained pinned sources, complete closed values and generated artifacts audited.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('generate', 'integrate', 'audit'), nargs='?', default='generate')
    parser.add_argument('--port', type=Path, required=True, help='Explicit output directory; production integration is separate.')
    args = parser.parse_args()
    {'generate': generate, 'integrate': integrate, 'audit': audit}[args.action](args.port.resolve())
