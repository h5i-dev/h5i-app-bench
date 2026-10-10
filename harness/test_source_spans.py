import unittest

from source_spans import NoWritePath, locate


class SourceSpanTests(unittest.TestCase):
    def test_extractor_direct_writes_are_inert(self):
        target = NoWritePath() / "crate" / "src/file.rs"
        self.assertIsNone(target.parent.mkdir(parents=True, exist_ok=True))
        self.assertIsNone(target.write_text("must not reach disk"))

    def test_line_end_does_not_include_next_line(self):
        self.assertEqual(locate("before\nfn x {\n}\nafter\n", "fn x {\n}\n"), (2, 3))

    def test_scope_selects_repeated_method(self):
        text = "first\nfn x {}\nsecond\nfn x {}\n"
        self.assertEqual(locate(text, "fn x {}", text.index("second")), (4, 4))

    def test_nonverbatim_fragment_rejected(self):
        with self.assertRaises(ValueError):
            locate("fn x {}", "fn y {}")


if __name__ == "__main__":
    unittest.main()
