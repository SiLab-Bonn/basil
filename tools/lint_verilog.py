"""Check independent Basil designs without loading external vendor trees."""

import argparse
import json
import os
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FRAGMENTS = {
    "basil/firmware/modules/includes/log2func.v",
    "examples/MMC3/mmc3.srcs/sources_1/mmc3_constants.v",
}


def is_vendor(source):
    return any(part.lower() == "sitcp" for part in Path(source).parts)


def check(tool, source):
    path = Path(source)
    args = ["-y", str(path.parent)]
    if path.parts[0] == "examples":
        project = Path(*path.parts[:2])
        args += ["-I" + str(project)]
        names = (
            subprocess.check_output(
                ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z", str(project)], cwd=ROOT
            )
            .decode()
            .split("\0")
        )
        for directory in sorted({Path(p).parent for p in names if p.endswith(".v") and not is_vendor(p)}):
            args += ["-y", str(directory)]
    if source == "examples/test_eth/firmware_test_eth/src/test_eth.v":
        args += ["-v", "basil/firmware/modules/utils/3_stage_synchronizer.v"]
    with tempfile.TemporaryDirectory(prefix="basil-lint-") as temporary:
        target = source
        if source in FRAGMENTS or source == "basil/firmware/modules/tb/silbusb.sv":
            wrapper = Path(temporary) / ("lint_top" + path.suffix)
            if source in FRAGMENTS:
                wrapper.write_text(f'module lint_top;\n`include "{ROOT / source}"\nendmodule\n')
            else:
                wrapper.write_text(
                    f'`include "{ROOT / source}"\nmodule lint_top(input clk);\nSiLibUSB bus(clk);\nendmodule\n'
                )
            target = str(wrapper)
        if tool == "verilator":
            command = ["verilator", "-f", "verilator.f", *args, target]
            if path.suffix == ".sv":
                command += ["--language", "1800-2017"]
            return subprocess.run(command, cwd=ROOT, check=False).returncode
        from pyslang.driver import Driver

        flags = json.loads((ROOT / ".slang/server.json").read_text())["flags"]
        if path.suffix == ".sv":
            flags = flags.replace("1364-2005", "1800-2017")
        driver = Driver()
        driver.addStandardArgs()
        command = "slang " + flags + " " + shlex.join([*args, target])
        success = driver.parseCommandLine(command) and driver.processOptions() and driver.parseAllSources()
        if success:
            success = driver.runFullCompilation()
        return 0 if success else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tool", choices=["verilator", "slang"])
    parser.add_argument("files", nargs="*")
    options = parser.parse_args()
    os.chdir(ROOT)
    files = options.files
    if not files:
        names = (
            subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=ROOT)
            .decode()
            .split("\0")
        )
        files = sorted({p for p in names if p.endswith((".v", ".sv")) and not is_vendor(p)})
    failed = []
    for source in files:
        if is_vendor(source):
            continue
        print(f"Checking {source}", flush=True)
        if check(options.tool, source):
            failed.append(source)
    print(f"{options.tool}: {len(files) - len(failed)}/{len(files)} files passed", flush=True)
    for source in failed:
        print(f"FAILED: {source}")
    return bool(failed)


if __name__ == "__main__":
    sys.exit(main())
