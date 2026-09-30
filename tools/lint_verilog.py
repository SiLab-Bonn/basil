"""Check Basil HDL formatting, style and independent designs without vendor trees."""

import argparse
import difflib
import os
import shlex
import subprocess
import sys
import tempfile
from pathlib import Path

from hdl_config import CONFIG, ROOT


def is_vendor(source):
    return any(part.lower() in CONFIG["vendor-directories"] for part in Path(source).parts)


def check_verible(tool, source, fix):
    if tool == "verible-lint":
        return subprocess.run(
            ["verible-verilog-lint", "--rules=" + ",".join(CONFIG[tool]["rules"]), source], cwd=ROOT, check=False
        ).returncode
    command = ["verible-verilog-format", *CONFIG[tool]["args"]]
    if fix:
        return subprocess.run([*command, "--inplace", source], cwd=ROOT, check=False).returncode
    result = subprocess.run([*command, source], cwd=ROOT, capture_output=True, check=False)
    sys.stderr.buffer.write(result.stderr)
    if result.returncode:
        return result.returncode
    original = (ROOT / source).read_bytes()
    if original == result.stdout:
        return 0
    sys.stdout.writelines(
        difflib.unified_diff(
            original.decode().splitlines(keepends=True),
            result.stdout.decode().splitlines(keepends=True),
            fromfile=source,
            tofile=source + " (formatted)",
        )
    )
    return 1


def check(tool, source):
    path = Path(source)
    args = ["+incdir+" + directory for directory in CONFIG["include-directories"]]
    for directory in CONFIG["library-directories"]:
        args += ["-y", directory]
    args += ["-y", str(path.parent)]
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
    args += CONFIG["extra-args"].get(source, [])
    with tempfile.TemporaryDirectory(prefix="basil-lint-") as temporary:
        target = source
        if source in CONFIG["wrappers"]:
            wrapper = Path(temporary) / ("lint_top" + path.suffix)
            wrapper.write_text(CONFIG["wrappers"][source].replace("{source}", str(ROOT / source)))
            target = str(wrapper)
        standard = CONFIG["systemverilog-standard" if path.suffix == ".sv" else "verilog-standard"]
        if tool == "verilator":
            command = ["verilator", *CONFIG[tool]["args"], "--language", standard, *args, target]
            return subprocess.run(command, cwd=ROOT, check=False).returncode
        from pyslang.driver import Driver

        driver = Driver()
        driver.addStandardArgs()
        command = shlex.join(["slang", "--std=" + standard, *CONFIG[tool]["args"], *args, target])
        success = driver.parseCommandLine(command) and driver.processOptions() and driver.parseAllSources()
        if success:
            success = driver.runFullCompilation()
        return 0 if success else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tool", choices=["verible-format", "verible-lint", "verilator", "slang"])
    parser.add_argument("--fix", action="store_true", help="Apply formatting instead of checking it")
    parser.add_argument("files", nargs="*")
    options = parser.parse_intermixed_args()
    if options.fix and options.tool != "verible-format":
        parser.error("--fix is only supported for verible-format")
    os.chdir(ROOT)
    files = options.files
    if not files:
        names = (
            subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=ROOT)
            .decode()
            .split("\0")
        )
        files = sorted({p for p in names if p.endswith(tuple(CONFIG["source-suffixes"])) and not is_vendor(p)})
    failed = []
    for source in files:
        if is_vendor(source):
            continue
        print(f"Checking {source}", flush=True)
        result = (
            check_verible(options.tool, source, options.fix)
            if options.tool.startswith("verible-")
            else check(options.tool, source)
        )
        if result:
            failed.append(source)
    print(f"{options.tool}: {len(files) - len(failed)}/{len(files)} files passed", flush=True)
    for source in failed:
        print(f"FAILED: {source}")
    return bool(failed)


if __name__ == "__main__":
    sys.exit(main())
