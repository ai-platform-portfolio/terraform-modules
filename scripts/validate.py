import argparse
from pathlib import Path
import subprocess


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--test", action="store_true")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    subprocess.run(["terraform", "fmt", "-check", "-recursive"], cwd=root, check=True)
    directories = sorted(
        path
        for parent in ("modules", "examples")
        for path in (root / parent).iterdir()
        if path.is_dir()
    )
    directories.append(root / "ci")
    failures = []
    for directory in directories:
        try:
            subprocess.run(
                ["terraform", "init", "-backend=false", "-input=false", "-no-color"],
                cwd=directory,
                check=True,
            )
            subprocess.run(["terraform", "validate", "-no-color"], cwd=directory, check=True)
            if args.test and (directory / "tests").exists():
                subprocess.run(["terraform", "test", "-no-color"], cwd=directory, check=True)
        except subprocess.CalledProcessError:
            failures.append(str(directory.relative_to(root)))
    if failures:
        print("Failed: " + ", ".join(failures))
    return int(bool(failures))


if __name__ == "__main__":
    raise SystemExit(main())
