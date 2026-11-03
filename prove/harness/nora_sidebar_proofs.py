"""Independent template models and modular complete-output sidebar proofs."""
import string


def literal(bs):
    return '[' + ', '.join(f'(UScalar.mk (BitVec.ofNat 8 {b}) : U8)' for b in bs) + ']'


def field_name(ident):
    return "pub_dart" if ident == "pub" else ident


def build(plan, groups, pieces, order):
    out = '''import NoraKernel
import H5iAppLib
open Aeneas Aeneas.Std Result H5iAppLib nora_kernel
namespace nora_kernel.Verified.Sidebar
set_option maxRecDepth 65536
set_option maxHeartbeats 10000000
@[step] theorem sidebar_bytes_to_vec (s : Slice U8) :
    alloc.slice.Slice.to_vec core.clone.CloneU8 s ⦃r => r.val = s.val⦄ := by
  apply WP.spec_mono (alloc.slice.Slice.to_vec_spec core.clone.CloneU8 s (by intros; rfl))
  intro r hr
  exact (congrArg Slice.val hr).symm
private theorem flatten_map (xs : List (alloc.vec.Vec U8)) :
    xs.flatMap alloc.vec.Vec.val = (xs.map alloc.vec.Vec.val).flatten := by
  induction xs with
  | nil => rfl
  | cons x xs ih => simp only [List.flatMap_cons, List.map_cons, List.flatten_cons, ih]
@[step] theorem input_complete (keep : Bool) (s : Slice U8) :
    sidebar.input keep s ⦃r => r.val = if keep then s.val else []⦄ := by
  cases keep <;> unfold sidebar.input
  all_goals step* (grind := false) (threadGrindState := false)
  all_goals simp_all [alloc.vec.Vec.new, alloc.vec.Vec.val]
@[step] theorem is_active_complete (active id : Slice U8) :
    sidebar.is_active active id ⦃r => r = decide (active.val = id.val)⦄ := by
  unfold sidebar.is_active
  step*
  all_goals simp_all [Slice.eq_iff]
'''
    refs = []
    def reference(name, text):
        bs = text.encode()
        parts = []
        for i, offset in enumerate(range(0, len(bs), 96)):
            part = f'{name}_reference_{i}'; parts.append(part)
            refs.append(f'def {part} : List U8 := {literal(bs[offset:offset+96])}\n')
        refs.append(f'def {name} : List U8 := [' + ', '.join(parts) + '].flatten\n')
        return name
    def template_model(template, args, prefix):
        expr = []; index = 0
        for i, (constant, field, fmt, conv) in enumerate(string.Formatter().parse(template)):
            assert not fmt and conv is None
            if constant: expr.append(reference(f'{prefix}_literal_{i}', constant))
            if field is not None:
                expr.append(args[index]); index += 1
        assert index == len(args)
        return ' ++ '.join(expr) if expr else '[]'
    active_class = reference('active_class_bytes', 'bg-slate-700 text-white')
    inactive_class = reference('inactive_class_bytes', 'text-slate-300 hover:bg-slate-700 hover:text-white')
    none_fill = reference('none_fill_bytes', 'none')
    color_fill = reference('color_fill_bytes', 'currentColor')
    stroke = reference('stroke_bytes', ' stroke="currentColor"')
    class_model = f'def class_model (active : Bool) : List U8 := if active then {active_class} else {inactive_class}\n'
    nav_expr = template_model(plan['templates']['nav'], ['href', 'class_model active',
                f'(if is_stroke then {none_fill} else {color_fill})', f'(if is_stroke then {stroke} else [])', 'icon', 'label'], 'nav')
    common_models = class_model + f'def nav_item_model (href label icon : List U8) (is_stroke active : Bool) : List U8 :=\n  {nav_expr}\n'
    group_models = []
    chunks = []
    bridges = []
    for g in groups:
        name = g['name']; params = '(keep : Bool)' + (' (active : Bool)' if g['active'] else '') + (' (label : List U8)' if g['input'] else '')
        args = 'keep' + (' active' if g['active'] else '') + (' label' if g['input'] else '')
        g['model_params'] = params; g['model_args'] = args
        tag = g['tag']
        if tag == 'row':
            item = plan['items'][g['item']]
            href = reference(f'{name}_href', item['href'])
            icon = reference(f'{name}_icon', item['icon'])
            label = 'label' if isinstance(item['label'], dict) else reference(f'{name}_label', item['label'])
            expr = f'nav_item_model {href} {label} {icon} {str(item["stroke"]).lower()} active'
        elif tag == 'admin':
            expr = template_model(plan['templates']['admin'], ['class_model active', 'label'], 'admin')
        else:
            # These strings come directly from the outer/registry templates.
            terms = []
            for i, part in enumerate(g['parts']):
                terms.append('label' if part['kind'] == 'input' else reference(f'{name}_literal_{i}', part['value']))
            expr = ' ++ '.join(terms) if terms else '[]'
        group_models.append(f'def {name}_model {params} : List U8 :=\n  if keep then {expr} else []\n')
        values = []
        for part in g['chunks']:
            value = f'piece_{part["index"]}_model' if part['kind'] == 'piece' else 'class_model active' if part['kind'] == 'class' else 'label'
            values.append(f'(if keep then {value} else [])')
        chunks.append(f'def {name}_chunks {params} : List (List U8) := [' + ', '.join(values) + ']\n')
        cases = 'cases keep' + (' <;> cases active' if g['active'] else '')
        bridges.append(f'private theorem {name}_chunks_exact {params} :\n    ({name}_chunks {args}).flatten = {name}_model {args} := by\n  {cases} <;> rfl\n')
    flags = [field_name(item['id']) for item in plan['items'][1:]]
    any_expr = ' || '.join('e.' + f for f in flags)
    common_models += f'def any_enabled (e : sidebar.Enabled) : Bool := {any_expr}\n'
    # Explicit root identifiers are independent UTF-8 source data.
    ids = {item['id']: reference('id_' + item['id'], item['id']) for item in plan['items']}
    ids['tokens'] = reference('id_tokens', 'tokens')
    # Registry section is modeled as one complete source format invocation.
    rows_expr = ' ++ '.join(f'row_{i}_model e.{field_name(item["id"])} (decide (active = {ids[item["id"]]}))' for i, item in enumerate(plan['items'][1:], 1))
    registry_rows = f'def registry_rows_model (active : List U8) (e : sidebar.Enabled) : List U8 :=\n  {rows_expr}\n'
    # Reuse the same untouched format literals as the heading/tail models.
    registry_section = '''def registry_section_model (active label : List U8) (e : sidebar.Enabled) : List U8 :=
  if any_enabled e then
    registry_heading_literal_0 ++ label ++ registry_heading_literal_2 ++ registry_rows_model active e ++ registry_tail_literal_0
  else []
'''
    out += '\n' + ''.join(refs) + common_models
    out += '''@[step] theorem active_class_complete (keep active : Bool) :
    sidebar.active_class keep active ⦃r => r.val = if keep then class_model active else []⦄ := by
  cases keep <;> cases active <;> unfold sidebar.active_class
  all_goals step* (grind := false) (threadGrindState := false)
  all_goals simp_all only [class_model, active_class_bytes, inactive_class_bytes,
    active_class_bytes_reference_0, inactive_class_bytes_reference_0,
    Array.to_slice, Array.make_val, Slice.from_val, alloc.vec.Vec.new, alloc.vec.Vec.val]
  all_goals rfl
@[step] theorem has_registries_complete (e : sidebar.Enabled) :
    sidebar.has_registries e ⦃r => r = any_enabled e⦄ := by
  unfold sidebar.has_registries
  step*
  all_goals simp_all [any_enabled]
'''
    for i, piece in enumerate(pieces):
        out += f'''
def piece_{i}_model : List U8 := {literal(piece)}
@[step] theorem piece_{i}_complete (keep : Bool) :
    sidebar.piece_{i} keep ⦃r => r.val = if keep then piece_{i}_model else []⦄ := by
  cases keep <;> unfold sidebar.piece_{i}
  all_goals step* (grind := false) (threadGrindState := false)
  all_goals simp_all only [piece_{i}_model, Array.to_slice, Array.make_val, Slice.from_val, alloc.vec.Vec.new, alloc.vec.Vec.val]
  all_goals rfl
'''
    out += '\n' + ''.join(group_models) + ''.join(chunks) + ''.join(bridges)
    out += '\nattribute [local irreducible] ' + ' '.join(f'piece_{i}_model' for i in range(len(pieces))) + '\n'
    for g in groups:
        name = g['name']; params = g['model_params']; args = g['model_args']
        actual_params = params.replace('(label : List U8)', '(label : Slice U8)')
        actual_args = args.replace(' label', ' label.val')
        out += f'''
private theorem {name}_chunks_complete {actual_params} :
    sidebar.{name} {args} ⦃r => r.val.map alloc.vec.Vec.val = {name}_chunks {actual_args}⦄ := by
  unfold sidebar.{name}
  step* (grind := false) (threadGrindState := false) (assumTac := false) (inferGhostVars := false)
  all_goals simp_all only [{name}_chunks, Array.make_val, List.map_cons, List.map_nil]
@[step] theorem {name}_complete {actual_params} :
    sidebar.{name} {args} ⦃r => r.val.flatMap alloc.vec.Vec.val = {name}_model {actual_args}⦄ := by
  apply WP.spec_mono ({name}_chunks_complete {args})
  intro r hr
  rw [flatten_map, hr]
  exact {name}_chunks_exact {actual_args}
'''
    out += '\n' + registry_rows + registry_section
    out += '''private theorem rows_when_none (active : List U8) (e : sidebar.Enabled)
    (h : any_enabled e = false) : registry_rows_model active e = [] := by
  simp only [any_enabled, Bool.or_eq_false_iff, and_assoc] at h
'''
    out += '  rcases h with ⟨' + ', '.join('h_' + f for f in flags) + '⟩\n'
    out += '  simp only [registry_rows_model, ' + ', '.join(f'row_{i}_model' for i in range(1, 17)) + ', ' + ', '.join('h_' + f for f in flags) + ', Bool.false_eq_true, if_false, List.nil_append]\n'
    out += '''private theorem registry_composition (active label : List U8) (e : sidebar.Enabled) :
    registry_heading_model (any_enabled e) label ++ registry_rows_model active e ++ registry_tail_model (any_enabled e) = registry_section_model active label e := by
  cases h : any_enabled e with
  | false =>
    rw [rows_when_none active e h]
    simp [h, registry_heading_model, registry_tail_model, registry_section_model]
  | true =>
    simp [h, registry_heading_model, registry_tail_model, registry_section_model, List.append_assoc]
'''
    decoded = ' ++ '.join('r.version.val' if name == 'version' else f'(r.{name}.val.flatMap alloc.vec.Vec.val)' for name in order)
    out += f'def decode (r : sidebar.Output) : List U8 :=\n  {decoded}\n'
    root_parts = ['frame_0_model true', f'row_0_model true (decide (active = {ids["dashboard"]})) t.nav_dashboard.val',
                  'frame_1_model true', 'registry_section_model active t.nav_registries.val e', 'frame_2_model true',
                  f'admin_model auth (decide (active = {ids["tokens"]})) t.nav_tokens.val', 'frame_3_model true', 'version', 'frame_4_model true']
    out += 'def sidebar_model (active : List U8) (t : sidebar.Translations) (auth : Bool) (e : sidebar.Enabled) (version : List U8) : List U8 :=\n  ' + ' ++ '.join(root_parts) + '\n'
    out += '\nattribute [local irreducible] ' + ' '.join(g['name'] + '_model' for g in groups) + '\n'
    out += '''@[step] theorem sidebar_complete (active : Slice U8) (t : sidebar.Translations) (auth : Bool)
    (e : sidebar.Enabled) (version : Slice U8) :
    sidebar.sidebar active t auth e version ⦃r => decode r = sidebar_model active.val t auth e version.val⦄ := by
  unfold sidebar.sidebar
  step* (grind := false) (threadGrindState := false) (assumTac := false) (inferGhostVars := false)
  all_goals simp_all only [decode, sidebar_model, Array.to_slice, Array.make_val,
    Slice.from_val, alloc.vec.Vec.deref, if_true]
  all_goals rw [← registry_composition active.val t.nav_registries.val e]
  all_goals simp only [registry_rows_model, List.append_assoc]
  all_goals rfl
end nora_kernel.Verified.Sidebar
'''
    return out
