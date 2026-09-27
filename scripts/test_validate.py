import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import validate


class LibraryBoundaryTest(unittest.TestCase):
    def test_deployment_root_is_rejected_before_terraform_runs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "ci").mkdir()
            (root / "ci/main.tf").write_text('terraform { backend "azurerm" {} }\n')
            with patch.object(validate, "__file__", str(root / "scripts/validate.py")), \
                 patch("sys.argv", ["validate.py"]), \
                 patch("validate.subprocess.run") as run:
                self.assertEqual(validate.main(), 1)
                run.assert_not_called()
