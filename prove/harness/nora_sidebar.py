"""Reproduce the complete pinned Nora sidebar, with explicit output fragments.

The caller adapter maps active_page.unwrap_or("") to UTF-8 bytes, and the
optional registry set to its sixteen membership bits (None means all true).
The build version is an explicit byte input. Only the complete sidebar root
is eligible for source mapping; static fragments and carriers add no credit.
"""
import argparse
import gzip
import hashlib
import json
import os
import re
import string
import subprocess
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = 'nora-registry/src/ui/components.rs'
REGISTRY = 'nora-registry/src/registry_type.rs'
NAME = 'sidebar_dark_with_registries'
STRINGS = re.compile(r'r(#+)"(.*?)"\1|"(?:\\.|[^"\\])*"', re.S)


def upstream(rev, file):
    return subprocess.check_output(['git', f'--git-dir={ROOT}/results/upstream/nora.git',
                                    'show', f'{rev}:{file}'], text=True)


def fields(template):
    parts = list(string.Formatter().parse(template))
    assert all(not fmt and conv is None and field in (None, '')
               for _, field, fmt, conv in parts)
    return parts


def fold(template, args):
    """Fold only static substitutions; retain arbitrary caller insertions."""
    result = []
    index = 0
    def add(value):
        if isinstance(value, str):
            if not value:
                return
            if result and result[-1]['kind'] == 'constant':
                result[-1]['value'] += value
            else:
                result.append({'kind': 'constant', 'value': value})
        else:
            result.append(value)
    for constant, field, _, _ in fields(template):
        add(constant)
        if field is not None:
            add(args[index]); index += 1
    assert index == len(args)
    return result


def prepare(port):
    mapping = json.loads((ROOT / 'harness/source-mappings/nora.json').read_text())
    rev = mapping['upstream_revision']
    source = upstream(rev, SOURCE)
    rows = [json.loads(line) for line in gzip.open(ROOT / 'results/source-coverage/kernel-ceiling-items.jsonl.gz', 'rt')]
    row, = [r for r in rows if r['app'] == 'nora' and r['file'] == SOURCE and r['kind'] == 'fn' and r['name'] == NAME]
    body = '\n'.join(source.splitlines()[row['start'] - 1:row['end']])
    meta = {k: row[k] for k in ('file', 'kind', 'name', 'self_ty', 'start', 'end')}
    meta['sha256'] = hashlib.sha256(body.encode()).hexdigest()
    start = source.index('pub mod icons {'); end = source.index('\n}', start) + 2
    icons = source[start:end]
    icon_pattern = re.compile(r'pub const (\w+): &str = r(#+)"(.*?)"\2;', re.S)
    icon_values = {name: value for name, _, value in icon_pattern.findall(icons)}
    assert len(icon_values) == 16 and re.sub(r'\s', '', icon_pattern.sub('', icons)) == 'pubmodicons{}'
    registry_source = upstream(rev, REGISTRY)
    macro = registry_source.split('registry_types! {', 1)[1].split('\n}', 1)[0]
    variants = re.findall(r'^\s*(\w+)\s*=>', macro, re.M)
    assert len(variants) == 16
    cargo_source = upstream(rev, 'Cargo.toml')
    version = tomllib.loads(cargo_source)['workspace']['package']['version']
    strings = []
    def intern(match):
        value = match[2] if match[1] else json.loads(match[0])
        strings.append(value)
        return f'STRING_{len(strings)-1}'
    tokens = STRINGS.sub(intern, body)
    tokens = re.sub(r'//[^\n]*', '', tokens)
    def value(token):
        token = token.strip()
        if token.startswith('STRING_'):
            return strings[int(token.removeprefix('STRING_'))]
        if token.startswith('icons::'):
            return icon_values[token.removeprefix('icons::')]
        if token in bindings:
            return bindings[token]
        raise ValueError(token)
    bindings = {name: strings[int(index)] for name, index in re.findall(r'let (\w+_icon) = STRING_(\d+);', tokens)}
    bindings['dashboard_label'] = {'kind': 'input', 'name': 'label'}
    nav = tokens.split('= vec![', 1)[1].split('];', 1)[0]
    pattern = re.compile(r'\(\s*(None|Some\(RegistryType::(\w+)\))\s*,\s*(\w+)\s*,\s*(\w+)\s*,\s*(\w+)\s*,\s*([\w:]+)\s*,\s*(true|false)\s*,\s*\)')
    items = []
    for match in pattern.finditer(nav):
        _, variant, ident, href, label, icon, stroke = match.groups()
        items.append({'variant': variant, 'id': value(ident), 'href': value(href),
                      'label': value(label), 'icon': value(icon), 'stroke': stroke == 'true'})
    assert not pattern.sub('', nav).replace(',', '').strip()
    assert len(items) == 17 and items[0]['id'] == 'dashboard'
    assert set(i['variant'] for i in items[1:]) == set(variants)
    fmts = re.findall(r'format!\(\s*STRING_(\d+)\s*,(.*?)\)', tokens, re.S)
    expected = [['href', 'active_class', 'fill_attr', 'stroke_attr', 'icon_path', 'label'],
                ['t.nav_registries', 'registries_html'], ['tokens_active', 't.nav_tokens'],
                ['dashboard_html', 'registries_section', 'admin_section', 'VERSION']]
    assert len(fmts) == len(expected)
    templates = {}
    for tag, (index, args), wanted in zip(('nav', 'registries', 'admin', 'outer'), fmts, expected):
        assert [a.strip() for a in args.strip().rstrip(',').split(',')] == wanted
        templates[tag] = strings[int(index)]
    # Guard the complete branch skeleton: no new conditions may silently enter.
    assert re.findall(r'\bif\s+([^\{]+)\{', tokens) == [
        'is_active ', 'is_stroke ', 'registries_html.trim().is_empty() ',
        'auth_enabled ', 'active == STRING_' + str(strings.index('tokens')) + ' ']
    assert tokens.count('set.contains(rt)') == 1 and 'active_page.unwrap_or(STRING_' in tokens
    assert re.findall(r'\bt\.(\w+)', tokens) == ['nav_dashboard', 'nav_registries', 'nav_tokens']
    plan = {'revision': rev, 'record': {'meta': meta, 'source': body}, 'items': items,
            'templates': templates, 'variants': variants, 'version': version,
            'dependencies': [{'file': SOURCE, 'source': icons, 'sha256': hashlib.sha256(icons.encode()).hexdigest()},
                             {'file': REGISTRY, 'source': macro, 'sha256': hashlib.sha256(macro.encode()).hexdigest()},
                             {'file': 'Cargo.toml', 'source': cargo_source, 'sha256': hashlib.sha256(cargo_source.encode()).hexdigest()}],
            'representation': 'Ordered fixed arrays of complete byte fragments. UTF-8 text is unchanged; extra invalid byte inputs are admitted. Active None maps to empty bytes; absent registry filter maps to sixteen true bits. Build version is explicit.'}
    folder = port / 'difftest/sidebar'; folder.mkdir(parents=True, exist_ok=True)
    (folder / 'plan.json').write_text(json.dumps(plan, indent=2) + '\n')
    preamble = 'pub mod registry_type { #[derive(Clone,Copy,Hash,Eq,PartialEq)] pub enum RegistryType { ' + ','.join(variants) + ' } }\n'
    preamble += "pub struct Translations<'a> { pub nav_dashboard: &'a str, pub nav_registries: &'a str, pub nav_tokens: &'a str }\n"
    preamble += 'const VERSION: &str = env!("CARGO_PKG_VERSION");\n'
    (folder / 'reference.rs').write_text(preamble + icons + '\n' + body + '\n')
    return plan


def field_name(ident):
    return "pub_dart" if ident == "pub" else ident


def generate(port):
    plan = prepare(port)
    templates = plan['templates']; items = plan['items']
    groups = []
    def group(name, parts, tag, item=None):
        groups.append({'name': name, 'parts': parts, 'tag': tag, 'item': item})
    outer = fields(templates['outer']); assert len(outer) == 5
    for i, (constant, _, _, _) in enumerate(outer):
        group(f'frame_{i}', [{'kind': 'constant', 'value': constant}], 'frame', i)
    for i, item in enumerate(items):
        group('row_' + str(i), fold(templates['nav'], [item['href'], {'kind': 'class'},
              'none' if item['stroke'] else 'currentColor',
              ' stroke="currentColor"' if item['stroke'] else '', item['icon'], item['label']]), 'row', i)
    reg = fields(templates['registries']); assert len(reg) == 3
    group('registry_heading', [{'kind': 'constant', 'value': reg[0][0]}, {'kind': 'input', 'name': 'label'},
                               {'kind': 'constant', 'value': reg[1][0]}], 'heading')
    group('registry_tail', [{'kind': 'constant', 'value': reg[2][0]}], 'tail')
    group('admin', fold(templates['admin'], [{'kind': 'class'}, {'kind': 'input', 'name': 'label'}]), 'admin')
    pieces = []
    for g in groups:
        chunks = []
        for part in g['parts']:
            if part['kind'] != 'constant':
                chunks.append(part); continue
            bs = part['value'].encode()
            for offset in range(0, len(bs), 128):
                piece = bs[offset:offset + 128]
                if piece not in pieces:
                    pieces.append(piece)
                chunks.append({'kind': 'piece', 'index': pieces.index(piece)})
        g['chunks'] = chunks
        g['active'] = any(p['kind'] == 'class' for p in chunks)
        g['input'] = any(p['kind'] == 'input' for p in chunks)
    flags = [field_name(item['id']) for item in items[1:]]
    rust = '#![allow(unused_variables)]\n//! Complete sidebar byte fragments; see DEVIATIONS.md.\n'
    rust += 'pub struct Enabled { ' + ', '.join(f'pub {f}: bool' for f in flags) + ' }\n'
    rust += 'pub struct Translations { pub nav_dashboard: Vec<u8>, pub nav_registries: Vec<u8>, pub nav_tokens: Vec<u8> }\n'
    def array_literal(bs): return '[' + ', '.join(f'{b}u8' for b in bs) + ']'
    def bytes_expr(text): return array_literal(text.encode()) + '.as_slice()'
    rust += 'pub fn input(keep: bool, s: &[u8]) -> Vec<u8> { if keep { s.to_vec() } else { Vec::new() } }\n'
    rust += 'pub fn is_active(active: &[u8], id: &[u8]) -> bool { active == id }\n'
    rust += 'pub fn has_registries(e: &Enabled) -> bool { ' + ' || '.join('e.' + f for f in flags) + ' }\n'
    rust += 'pub fn active_class(keep: bool, active: bool) -> Vec<u8> { if !keep { Vec::new() } else if active { '
    rust += array_literal(b'bg-slate-700 text-white') + '.to_vec() } else { '
    rust += array_literal(b'text-slate-300 hover:bg-slate-700 hover:text-white') + '.to_vec() } }\n'
    for i, piece in enumerate(pieces):
        rust += f'pub fn piece_{i}(keep: bool) -> Vec<u8> {{ if keep {{ {array_literal(piece)}.to_vec() }} else {{ Vec::new() }} }}\n'
    for g in groups:
        args = 'keep: bool' + (', active: bool' if g['active'] else '') + (', label: &[u8]' if g['input'] else '')
        calls = []
        for part in g['chunks']:
            calls.append(f'piece_{part["index"]}(keep)' if part['kind'] == 'piece' else
                         'active_class(keep, active)' if part['kind'] == 'class' else 'input(keep, label)')
        rust += f'pub fn {g["name"]}({args}) -> [Vec<u8>; {len(calls)}] {{ [' + ', '.join(calls) + '] }\n'
    rust += 'pub struct Output {\n' + ''.join(f'pub {g["name"]}: [Vec<u8>; {len(g["chunks"])}],\n' for g in groups) + 'pub version: Vec<u8>,\n}\n'
    order = ['frame_0', 'row_0', 'frame_1', 'registry_heading'] + [f'row_{i}' for i in range(1, 17)] + ['registry_tail', 'frame_2', 'admin', 'frame_3', 'version', 'frame_4']
    root_calls = {}
    for g in groups:
        tag = g['tag']; name = g['name']
        keep = 'true' if tag == 'frame' or (tag == 'row' and g['item'] == 0) else 'auth' if tag == 'admin' else 'show_registries' if tag in ('heading', 'tail') else 'e.' + field_name(items[g['item']]['id'])
        args = [keep]
        if g['active']:
            ident = 'tokens' if tag == 'admin' else items[g['item']]['id']
            args.append('is_active(active, ' + bytes_expr(ident) + ')')
        if g['input']:
            field = 'nav_dashboard' if tag == 'row' else 'nav_registries' if tag == 'heading' else 'nav_tokens'
            args.append('&t.' + field)
        root_calls[name] = name + '(' + ', '.join(args) + ')'
    rust += 'pub fn sidebar(active: &[u8], t: &Translations, auth: bool, e: &Enabled, version: &[u8]) -> Output {\nlet show_registries = has_registries(e);\nOutput {\n'
    rust += ''.join(f'{g["name"]}: {root_calls[g["name"]]},\n' for g in groups) + 'version: input(true, version),\n}\n}\n'
    (port / 'kernel/src').mkdir(parents=True, exist_ok=True)
    (port / 'kernel/src/sidebar.rs').write_text(rust)
    from nora_sidebar_proofs import build
    (port / 'proofs/Verified').mkdir(parents=True, exist_ok=True)
    (port / 'proofs/Verified/Sidebar.lean').write_text(build(plan, groups, pieces, order))
    generate_tests(port, plan, groups, order)
    print(f'Generated complete sidebar with {len(groups)} groups and {len(pieces)} shared fragments in {port}.')


def generate_tests(port, plan, groups, order):
    folder = port / 'difftest/sidebar'
    test = '#![allow(dead_code)]\n#[path="../../kernel/src/sidebar.rs"] mod kernel;\ninclude!("reference.rs");\n'
    test += 'fn decode(out: kernel::Output) -> Vec<u8> { let mut bytes=Vec::new();\n'
    for name in order:
        test += 'bytes.extend(out.version);\n' if name == 'version' else f'for piece in out.{name} {{ bytes.extend(piece); }}\n'
    test += 'bytes }\n'
    variants = plan['variants']
    test += 'fn compare(active: Option<&str>, auth: bool, mask: Option<u32>, labels: [&str;3]) {\n'
    test += 'use registry_type::RegistryType::*; let variants=[' + ','.join(variants) + '];\n'
    test += 'let set:std::collections::HashSet<_>=variants.into_iter().enumerate().filter_map(|(i,v)| if mask.unwrap_or(65535)&(1<<i)!=0 {Some(v)} else {None}).collect();\n'
    test += 'let t=Translations{nav_dashboard:labels[0],nav_registries:labels[1],nav_tokens:labels[2]};\n'
    test += 'let expected=sidebar_dark_with_registries(active,&t,auth,mask.map(|_| &set));\n'
    test += 'let kt=kernel::Translations{nav_dashboard:labels[0].as_bytes().to_vec(),nav_registries:labels[1].as_bytes().to_vec(),nav_tokens:labels[2].as_bytes().to_vec()};\n'
    test += 'let e=kernel::Enabled{'+','.join(f'{field_name(item["id"])}:set.contains(&{item["variant"]})' for item in plan['items'][1:])+'};\n'
    test += 'assert_eq!(decode(kernel::sidebar(active.unwrap_or("").as_bytes(),&kt,auth,&e,VERSION.as_bytes())),expected.as_bytes(),"active={active:?} auth={auth} mask={mask:?}");\n}\n'
    ids = [None] + [item['id'] for item in plan['items']] + ['tokens', '', 'unknown', 'DOCKER']
    test += '#[test] fn complete_outputs_all_registry_subsets() { let ids=[' + ','.join('None' if s is None else 'Some('+json.dumps(s)+')' for s in ids) + '];\n'
    test += 'for mask in 0..65536 { for auth in [false,true] { compare(ids[(mask as usize)%ids.len()],auth,Some(mask),["Dashboard","Registries","Tokens"]); } }\n'
    test += r'''for id in ids { for auth in [false,true] { compare(id,auth,None,["","\u{0}<&>","日本語 🦀"]); compare(id,auth,Some(0),[" ","\t\r\n","{}"]); } }
}
'''
    test += r'''fn text(mut n:u64) -> String { let chars=['\0','<','>','&','"','\'','{','}',' ', '\n','é','界','🦀']; let mut s=String::new(); for _ in 0..((n%29)+1) { n=n.wrapping_mul(6364136223846793005).wrapping_add(1); s.push(chars[(n as usize)%chars.len()]); } s }
#[test] fn complete_arbitrary_text_fields() { for n in 0..4000u64 { let active=text(n+17); let d=text(n*3+11); let r=text(n*7+101); let t=text(n*11+1001); compare(Some(&active),n%2==0,Some((n.wrapping_mul(17973)&65535) as u32),[&d,&r,&t]); } }
'''
    # Raw Python spelling above retains exactly Rust escape syntax.
    (folder / 'tests.rs').write_text(test)


def audit(port):
    files = [port / p for p in ('kernel/src/sidebar.rs', 'proofs/Verified/Sidebar.lean',
                                'difftest/sidebar/plan.json', 'difftest/sidebar/reference.rs', 'difftest/sidebar/tests.rs')]
    before = {p: p.read_bytes() for p in files}
    plan = generate(port)
    assert all(p.read_bytes() == value for p, value in before.items()), 'non-reproducible sidebar'
    plan = json.loads((port / 'difftest/sidebar/plan.json').read_text())
    binary = port / 'difftest/sidebar/compare'
    subprocess.run(['rustc', '--edition=2021', '--test', '-O', str(port / 'difftest/sidebar/tests.rs'), '-o', str(binary)],
                   check=True, env={**os.environ, 'CARGO_PKG_VERSION': plan['version']})
    subprocess.run([str(binary)], check=True)
    print('Pinned source, exact complete outputs, and deterministic sidebar generation audited.')


def integrate(port):
    """Install the generated root and its one canonical source mapping."""
    generate(port)
    path = port / 'kernel/src/lib.rs'
    text = path.read_text()
    if 'pub mod sidebar;' not in text:
        path.write_text(text + '\npub mod sidebar;\n')
    path = port / 'h5i-app.toml'
    text = path.read_text()
    if '"sidebar::sidebar"' not in text:
        start = text.index('start-from = [')
        end = text.index(']', start)
        text = text[:end] + ', "sidebar::sidebar"' + text[end:]
    name = 'nora_kernel.Properties.sidebar_complete'
    if '"' + name + '"' not in text:
        start = text.index('theorems = [')
        end = text.index(']', start)
        text = text[:end] + '  "' + name + '",\n' + text[end:]
    path.write_text(text)
    path = port / 'proofs/Properties.lean'
    text = path.read_text()
    if 'import Verified.Sidebar\n' not in text:
        text = 'import Verified.Sidebar\n' + text
    if 'theorem sidebar_complete ' not in text:
        text += '''
namespace nora_kernel.Properties

theorem sidebar_complete (active : Slice U8) (t : sidebar.Translations)
    (auth : Bool) (e : sidebar.Enabled) (version : Slice U8) :
    sidebar.sidebar active t auth e version ⦃r =>
      Verified.Sidebar.decode r = Verified.Sidebar.sidebar_model active.val t auth e version.val⦄ :=
  Verified.Sidebar.sidebar_complete active t auth e version

end nora_kernel.Properties
'''
    path.write_text(text)
    plan = json.loads((port / 'difftest/sidebar/plan.json').read_text())
    path = ROOT / 'harness/source-mappings/nora.json'
    mapping = json.loads(path.read_text())
    assert mapping['upstream_revision'] == plan['revision']
    mapping['declarations']['sidebar.sidebar'] = [plan['record']['meta']]
    path.write_text(json.dumps(mapping, indent=2) + '\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('generate', 'audit', 'integrate'), nargs='?', default='generate')
    parser.add_argument('--port', type=Path, required=True)
    args = parser.parse_args()
    {'generate': generate, 'audit': audit, 'integrate': integrate}[args.action](args.port.resolve())
