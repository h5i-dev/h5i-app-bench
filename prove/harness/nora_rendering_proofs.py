"""Generate complete output models; hand-written byte/loop proofs live in template."""
import json
from pathlib import Path
from nora_rendering import PORT, ROOT, leanlit
plan=json.loads((PORT/'difftest/rendering/plan.json').read_text())
s=(ROOT/'harness/templates/nora-rendering-primitives.lean').read_text()
s+='\nset_option maxHeartbeats 10000000\n'
# Preserve separate literals so the model does not rely on the extracted body.
for r in plan['records']:
    name=r['name']
    if 'pieces' not in r:continue
    sig={
        'render_activity_row':'(timestamp action artifact registry source : List U8)',
        'render_activity_log':'(rows : List U8) (t : rendering.Translations)',
        'registry_search_bar':'(registry placeholder : List U8)',
        'render_polling_script':'',
        'header_dark':'(lang : rendering.Lang)',
    }[name]
    prefix=''
    if name=='render_activity_row':
        prefix='\n  let action_color := action_color_model action'
    if name=='header_dark':
        a=leanlit('text-white font-semibold');b=leanlit('text-slate-400 hover:text-slate-200')
        prefix=f'\n  let (en_class,ru_class,zh_class) := match lang with | .En => ({a},{b},{b}) | .Ru => ({b},{a},{b}) | .Zh => ({b},{b},{a})'
    parts=[]
    for dynamic,part in r['pieces']:
        if dynamic:
            if part.startswith('&t.'):part=part[1:]+'.val'
            if part.startswith('html_escape('):part='('+part.replace('html_escape(','html_model ').removesuffix(')')+')'
            parts.append(part)
        else:
            # Same segmentation as the kernel, without changing the raw output.
            parts.extend(leanlit(part[start:start+96]) for start in range(0,len(part),96))
    s+=f'\ndef {name}_model {sig} : List U8 :='+prefix+'\n  '+ ' ++ '.join(parts)+'\n'
    args={
        'render_activity_row': ('(timestamp action artifact registry source : Slice U8)','timestamp action artifact registry source','timestamp.val action.val artifact.val registry.val source.val'),
        'render_activity_log': ('(rows : Slice U8) (t : rendering.Translations)','rows t','rows.val t'),
        'registry_search_bar': ('(registry placeholder : Slice U8)','registry placeholder','registry.val placeholder.val'),
        'render_polling_script': ('','',''),
        'header_dark': ('(lang : rendering.Lang)','lang','lang'),
    }[name]
    decl,call,model=args
    cases='  cases lang\n' if name=='header_dark' else ''
    if name == 'header_dark':
        chunk_plan = r['header_chunks']
        for index, piece in enumerate(chunk_plan['chunks']):
            # Explicit scalar constructors avoid per-byte numeral elaboration.
            literal = '[' + ', '.join(f'(UScalar.mk (BitVec.ofNat 8 {b}) : U8)' for b in piece.encode()) + ']'
            s += f'''\ndef header_piece_{index}_model : List U8 := {literal}
private theorem header_piece_{index}_length : header_piece_{index}_model.length = {len(piece.encode())} := by rfl
@[step] theorem header_piece_{index}_complete :
    rendering.header_piece_{index} ⦃r => r.val = header_piece_{index}_model⦄ := by
  unfold rendering.header_piece_{index}
  step* (grind := false) (threadGrindState := false)
  all_goals simp only [Array.to_slice, Array.make_val, Slice.from_val] at *
  all_goals simp_all only [header_piece_{index}_model, Slice.from_val]
  all_goals rfl
'''
        s += '\ndef header_dark_chunks_model (lang : rendering.Lang) : List U8 := match lang with\n'
        for variant, indices in chunk_plan['variants']:
            s += f'  | .{variant} => ' + ' ++ '.join(f'header_piece_{index}_model' for index in indices) + '\n'
        s += '''\nprivate theorem header_dark_chunks_exact (lang : rendering.Lang) :
    header_dark_chunks_model lang = header_dark_model lang := by
  cases lang <;> rfl

private theorem header_dark_chunks_complete (lang : rendering.Lang) :
    rendering.header_dark lang ⦃r => r.val = header_dark_chunks_model lang⦄ := by
  cases lang
  all_goals unfold rendering.header_dark
  all_goals step* (grind := false) (threadGrindState := false) (assumTac := false) (inferGhostVars := false)
  all_goals simp_all only [header_dark_chunks_model, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.Vec.deref, Slice.from_val, List.length_append, List.length_nil, List.nil_append, List.append_assoc'''
        for index in range(len(chunk_plan['chunks'])):
            s += f', header_piece_{index}_length'
        s += ''']
  all_goals scalar_tac

@[step] theorem header_dark_complete (lang : rendering.Lang)
    (hbound : (header_dark_model lang).length ≤ Usize.max) :
    rendering.header_dark lang ⦃r => r.val = header_dark_model lang⦄ := by
  apply WP.spec_mono (header_dark_chunks_complete lang)
  intro r hr
  exact hr.trans (header_dark_chunks_exact lang)
'''
        continue
    s+=f'''\n@[step] theorem {name}_complete {decl}
    (hbound : ({name}_model {model}).length ≤ Usize.max) :
    rendering.{name} {call} ⦃r => r.val = {name}_model {model}⦄ := by
{cases}  all_goals unfold rendering.{name}
  all_goals step* (grind := false) (threadGrindState := false)
  all_goals unfold {name}_model at *
  all_goals simp_all [Array.make, Slice.eq_iff, alloc.vec.Vec.new, alloc.vec.Vec.from, alloc.vec.Vec.val, alloc.vec.Vec.deref, Slice.from_val, List.append_assoc]
  all_goals omega
'''
s+='\nend nora_kernel.Verified.Rendering\n'
(PORT/'proofs/Verified/Rendering.lean').write_text('\n'.join(line.rstrip() for line in s.splitlines())+'\n')
