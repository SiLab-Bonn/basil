"""Read shared HDL configuration from pyproject.toml."""

import argparse
import sys
from pathlib import Path

try:
    import tomllib
except ModuleNotFoundError:
    import tomli as tomllib

ROOT = Path(__file__).resolve().parents[1]
with (ROOT / "pyproject.toml").open("rb") as stream:
    PROJECT = tomllib.load(stream)
CONFIG = PROJECT["sources"]["hdl"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["requirements", "download", "version"])
    parser.add_argument("tool", nargs="?", choices=["verible", "oss-cad-suite"])
    options = parser.parse_args()
    if options.command == "requirements":
        print("\n".join(PROJECT["project"]["optional-dependencies"]["hdl-lint"]))
    else:
        if options.tool is None:
            parser.error(options.command + " requires a tool")
        install = PROJECT["tool"][options.tool]["install"]
        if options.command == "version":
            print(install["version"])
        else:
            print(install["url"].format(version=install["version"], date=install["version"].replace("-", "")))
            print(install["sha256"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
