"""Reproduce audited Rust tag dispatch; Lean specifications are independently authored."""
import pathlib,json,re,subprocess,sys
here=pathlib.Path(__file__).parent;root=here.parents[1];meta=json.loads((here/'tags.json').read_text())
src=subprocess.check_output(['git','--git-dir='+sys.argv[1],'show',meta['pin']+':server/lib/src/schema.rs']).decode()
variants=meta['syntaxes']
text='''//! Schema syntax/tag discrimination from Kanidm f608c4f.
//! Complex payload validity and ValueSet validity are supplied by the caller;
//! these functions prove the schema dispatch, not those validators.
#[derive(Clone, Copy, Debug)]
pub enum Syntax {
'''+''.join('    '+n+',\n' for n,_ in variants)+'}\n'
for method,typename,key in [('validate_partialvalue','PartialValue','partial_tags'),('validate_value','Value','value_tags')]:
 start=src.index('    pub fn '+method+'(');end=src.index('\n    pub fn ',start+5)
 body=src[start:end];a=body.index('match self.syntax {');b=a+re.search(r'\n\s*};',body[a:]).start()
 dispatch=body[a:b]+'\n    }'
 ids={n:i for i,n in enumerate(meta[key])}
 dispatch=dispatch.replace('self.syntax','syntax').replace('SyntaxType::','Syntax::')
 dispatch=re.sub(r'matches!\(v, '+typename+r'::(\w+)(?:\([^)]*\)| \{ \.\. \})?\)',lambda m:'tag == '+str(ids[m[1]]),dispatch)
 assert 'matches!' not in dispatch
 fn='partial_accepts' if typename=='PartialValue' else 'value_accepts'
 text+='pub fn '+fn+'(syntax: Syntax, tag: u16'+(', valid: bool' if typename=='Value' else '')+') -> bool {\n    '+('valid && ' if typename=='Value' else '')+dispatch+'\n}\n'
text+='''pub fn ava_accepts(multivalue: bool, count: usize, expected_syntax: u16, actual_syntax: u16, valid: bool) -> bool {
    if !multivalue && count > 1 { return false; }
    expected_syntax == actual_syntax && valid
}
'''
(root/'kernel/src/schema_tags.rs').write_text(text)
# Specifications and proofs are independently maintained in Verified/SchemaTags.lean.
