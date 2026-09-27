import copy
import json
from pathlib import Path
import unittest

from function_source import source


class FunctionSourceTest(unittest.TestCase):
    def test_unreviewed_sources_and_output_injection_are_rejected(self):
        config = {"function_apps": {"profile": {
            "name": "fixture-function",
            "source": {"repository": "ai-platform-portfolio/ops-shared", "revision": "a" * 40, "path": "functions/profile_sync", "format": "zip"},
        }}}
        self.assertEqual(source(config, "profile")["path"], "functions/profile_sync")
        for field, value in [("repository", "untrusted/repo"), ("revision", "main"),
                             ("path", "../outside"), ("path", "/absolute"), ("path", "valid\nname=injected"),
                             ("format", "docker"), ("format", "")]:
            with self.subTest(field=field, value=value):
                changed = copy.deepcopy(config)
                changed["function_apps"]["profile"]["source"][field] = value
                with self.assertRaises(ValueError):
                    source(changed, "profile")

    def test_reviewed_applications_match_the_deployment_workflow(self):
        config = json.loads((Path(__file__).resolve().parents[1] / "ci/functions.auto.tfvars.json").read_text())
        for application in config["function_apps"]:
            with self.subTest(application=application):
                source(config, application)


if __name__ == "__main__":
    unittest.main()
