import copy
import unittest

from function_source import source


class FunctionSourceTest(unittest.TestCase):
    def test_unreviewed_sources_and_output_injection_are_rejected(self):
        config = {"function_apps": {"profile": {
            "name": "fixture-function",
            "source": {"repository": "ai-platform-portfolio/ops-shared", "revision": "a" * 40, "path": "functions/profile_sync"},
        }}}
        self.assertEqual(source(config, "profile")["path"], "functions/profile_sync")
        for field, value in [("repository", "untrusted/repo"), ("revision", "main"),
                             ("path", "../outside"), ("path", "/absolute"), ("path", "valid\nname=injected")]:
            with self.subTest(field=field, value=value):
                changed = copy.deepcopy(config)
                changed["function_apps"]["profile"]["source"][field] = value
                with self.assertRaises(ValueError):
                    source(changed, "profile")


if __name__ == "__main__":
    unittest.main()
