"""Checks the expression boundary used to admit source for record proofs."""
import unittest
import json
import tempfile
from pathlib import Path
from unittest.mock import patch
import closed_records
from closed_records import admitted_type, expression, fields


class ClosedGrammarTests(unittest.TestCase):
    def test_effects_and_unresolved_calls_are_rejected(self):
        for expr, ty in [('env::var("SECRET").unwrap()', 'String'),
                         ('Uuid::new_v4().to_string()', 'String'),
                         ('clock()', 'u64'), ('Other::default()', 'u64'),
                         ('1 + danger()', 'usize'), ('vec![read()]', 'Vec<u8>')]:
            with self.subTest(expr=expr), self.assertRaises(ValueError):
                expression(expr, ty, {})

    def test_unmodeled_type_or_field_is_rejected(self):
        for ty in ['f32', 'f64', 'Duration', 'Option<Instant>', 'Vec<Unknown>']:
            self.assertFalse(admitted_type(ty, {}))
        with self.assertRaises(ValueError):
            fields('pub struct T { pub x: u8, pub y: [u8; 3], }', 'T')
        with self.assertRaises(ValueError):
            fields('pub struct T(u8);', 'T')

    def test_regeneration_preserves_later_canonical_properties(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            port = root / 'ports/demo'
            for directory in ['kernel/src', 'proofs', 'difftest/closed_records']:
                (port / directory).mkdir(parents=True)
            (root / 'harness/source-mappings').mkdir(parents=True)
            (root / 'harness/source-mappings/demo.json').write_text(json.dumps({'declarations': {}}))
            (port / 'kernel/src/lib.rs').write_text('')
            (port / 'h5i-app.toml').write_text('[extract]\nstart-from=[]\n[check]\ntheorems=[]\n')
            (port / 'proofs/Properties.lean').write_text('-- existing canonical properties\n')
            record = {'id': 'one', 'fields': [['enabled', 'bool']],
                      'values': {'enabled': False}, 'meta': {'file': 'source.rs'}}
            (port / 'difftest/closed_records/plan.json').write_text(json.dumps({'records': [record]}))
            with patch.object(closed_records, 'ROOT', root):
                closed_records.integrate('demo', port)
                path = port / 'proofs/Properties.lean'
                later = '\n-- Later canonical theorem block must survive regeneration.\n'
                path.write_text(path.read_text() + later)
                before = path.read_bytes()
                closed_records.integrate('demo', port)
                self.assertEqual(path.read_bytes(), before)

    def test_utf8_and_punctuation_survive_translation(self):
        value = expression('"a,é\\n".to_string()', 'String', {})
        self.assertEqual(value, 'b"a,\\xc3\\xa9\\x0a".to_vec()')
        self.assertEqual(fields('pub struct T { // retained type\n pub x: Option<String>, }', 'T'), [('x','Option<String>')])


if __name__ == '__main__':
    unittest.main()
