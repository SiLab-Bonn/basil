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
CONFIG = PROJECT["tool"]["basil-hdl"]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["requirements", "download"])
    parser.add_argument("tool", nargs="?", choices=["verible", "verilator"])
    options = parser.parse_args()
    if options.command == "requirements":
        print("\n".join(PROJECT["project"]["optional-dependencies"]["hdl-lint"]))
    else:
        if options.tool is None:
            parser.error("download requires a tool")
        install = CONFIG["install"][options.tool]
        print(install["url"].format(version=install["version"]))
        print(install["sha256"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
