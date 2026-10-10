import unittest

from integrate import integrate_theorem, shared_derivations


class IntegrationTests(unittest.TestCase):
    def test_shared_derivations_do_not_duplicate_global_helpers(self):
        self.assertEqual(shared_derivations([
            "h5i_derive_all", "h5i_derive_all",
            "h5i_derive_clone model.Folder model.Folder.clone",
            "deriving instance DecidableEq for model.Subject",
        ]), ["h5i_derive_all", "deriving instance DecidableEq for model.Subject"])
        self.assertEqual(shared_derivations([
            "h5i_derive_eq stmts.Effect stmts.Effect.eq",
            "deriving instance DecidableEq for stmts.Effect",
            "deriving instance DecidableEq for acts.Family",
        ]), ["h5i_derive_eq stmts.Effect stmts.Effect.eq",
             "deriving instance DecidableEq for acts.Family"])

    def test_preserves_other_statements_and_is_idempotent(self):
        source = "theorem one (n : Nat) : n = n := by\n  sorry\n\ntheorem two : True := by\n  sorry\n\nend Example\n"
        result = integrate_theorem(source, "one", "Example.Verified")
        self.assertIn("theorem one (n : Nat) : n = n := by", result)
        self.assertTrue(result.endswith(source[source.index("theorem two"):]))
        self.assertEqual(integrate_theorem(result, "one", "Example.Verified"), result)

    def test_does_not_cross_already_proved_theorem(self):
        source = "theorem one : True := by\n  trivial\n\ntheorem two : True := by\n  sorry\n"
        with self.assertRaises(ValueError):
            integrate_theorem(source, "one", "Example.Verified")

    def test_rejects_missing_theorem(self):
        with self.assertRaises(ValueError):
            integrate_theorem("theorem two : True := by\n  sorry\n", "one", "Example.Verified")


if __name__ == "__main__":
    unittest.main()
