"""Resolve a reviewed, immutable Function package without shell interpolation."""

import json
import os
from pathlib import Path, PurePosixPath
import re


def source(config, application):
    app = config["function_apps"][application]
    if app["source"].get("format") != "zip":
        raise ValueError("Flex Consumption requires a ZIP package; custom images are unsupported")
    result = {"name": app["name"], **app["source"]}
    if not re.fullmatch(r"[a-z0-9-]+", result["name"]):
        raise ValueError("Invalid Function name")
    if not re.fullmatch(r"ai-platform-portfolio/[A-Za-z0-9_.-]+", result["repository"]):
        raise ValueError("Function source must belong to the portfolio")
    if not re.fullmatch(r"[0-9a-f]{40}", result["revision"]):
        raise ValueError("Function source must use a full commit SHA")
    path = PurePosixPath(result["path"])
    if path.is_absolute() or ".." in path.parts or not re.fullmatch(r"[A-Za-z0-9_./-]+", str(path)):
        raise ValueError("Invalid Function source path")
    return result


if __name__ == "__main__":
    config = json.loads(Path("ci/functions.auto.tfvars.json").read_text())
    resolved = source(config, os.environ["APPLICATION"])
    with Path(os.environ["GITHUB_OUTPUT"]).open("a") as output:
        output.write("".join(f"{key}={value}\n" for key, value in resolved.items()))
