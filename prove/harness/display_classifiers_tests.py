"""Deterministic differential corpus against unchanged pinned classifier bodies."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
p=ROOT/'prove/ports/oxicloud'
plan=json.loads((p/'difftest/display_classifiers/plan.json').read_text())
t='''#![allow(dead_code)]
use oxicloud_kernel::display_classifiers as kernel;
#[path="../../difftest/display_classifiers/reference.rs"]
mod reference;
fn spelling(v:kernel::DisplayValue) -> &'static str { match v {\n'''
for i,s in enumerate(plan['outputs']): t+=f'kernel::DisplayValue::V{i} => {json.dumps(s)},\n'
t+='}}\n'
# private original functions are tested by code in their own module.
ref='\n\n'.join(r['source'] for r in plan['records'])+'\n'
ref+='pub fn all(mime:&str, ext:Option<&str>) -> [&\'static str;3] { ['+','.join(r['name']+'(mime,ext)' for r in plan['records'])+'] }\n'
(p/'difftest/display_classifiers/reference.rs').write_text(ref)
t+='''fn check(mime:&str,ext:Option<&str>) {
 let expected=reference::all(mime,ext);
 let actual=[kernel::icon_class_with_ext(mime.as_bytes(),ext.map(str::as_bytes)),
             kernel::icon_special_class_with_ext(mime.as_bytes(),ext.map(str::as_bytes)),
             kernel::category_with_ext(mime.as_bytes(),ext.map(str::as_bytes))];
 for i in 0..3 { assert_eq!(expected[i],spelling(actual[i]),"classifier {i}: {mime:?}/{ext:?}"); }
}
#[test]
fn pinned_classifiers_match_full_literal_cross_product_and_adversarial_strings() {
 let mimes:&[&str]=&[\n'''
keys=sorted({r[1] for rec in plan['records'] for stage in ['exact','mime'] for r in rec[stage]})
exts=sorted({r[1] for rec in plan['records'] for r in rec['ext']})
mimes=sorted(set(keys+['','unknown','IMAGE/PNG','application/octet-stream','☃','text/','image/','xjavascriptx','xtypescriptx','text/markdown;script','text/plain\x00','application/pdf; charset=utf8']+[k+suf for k in keys for suf in ['/extra',';script','☃','\x00']]+['prefix'+k for k in keys]))
for s in mimes:t+=json.dumps(s,ensure_ascii=False).replace('\\u0000','\\0')+',\n'
t+='];\nlet extensions:&[&str]=&[\n'
for s in exts+['','unknown','PDF','a.pdf','☃','pdf\x00','jpeg/extra']:t+=json.dumps(s,ensure_ascii=False).replace('\\u0000','\\0')+',\n'
t+=''' ];
 for mime in mimes { check(mime,None); for ext in extensions { check(mime,Some(ext)); } }
 // Random bytes become valid UTF-8 via replacement, including non-ASCII inputs.
 let mut seed=0x998afd06a3u64;
 for _ in 0..20000 {
  let mut m=Vec::new(); let mut e=Vec::new();
  for i in 0..40 { seed^=seed<<13;seed^=seed>>7;seed^=seed<<17;
   if i < (seed as usize % 40) { m.push(seed as u8); }
   if i < (seed as usize % 18) { e.push((seed>>8) as u8); }
  }
  check(&String::from_utf8_lossy(&m),Some(&String::from_utf8_lossy(&e)));
 }
 println!("{} MIME inputs x ({} extensions + absent), plus 20000 randomized UTF-8 inputs; all three complete strings matched",mimes.len(),extensions.len());
}
#[test]
fn byte_predicates_match_standard_operations_at_boundaries() {
 let values:&[&[u8]]=&[b"",b"a",b"aa",b"abab",b"abc",b"javascript",b"xscriptx",&[0,255,128,0]];
 for hay in values { for needle in values {
  assert_eq!(kernel::prefix(hay,needle),hay.starts_with(needle));
  assert_eq!(kernel::contains(hay,needle),needle.is_empty() || hay.windows(needle.len()).any(|w|w==*needle));
  for at in 0..hay.len()+2 {
   assert_eq!(kernel::starts_at(hay,needle,at),at<=hay.len() && hay[at..].starts_with(needle));
  }
 } }
}
'''
(p/'kernel/tests/display_classifiers.rs').write_text(t)
print(len(mimes),'MIME inputs;',len(exts)+7,'extensions plus absence; 20000 randomized pairs')
