"""Check Basil HDL formatting, style and independent designs without vendor trees."""

import argparse
import difflib
import os
import shlex
import subprocess
import sys
from pathlib import Path

from sources import CONFIG, PROJECT, ROOT


def is_vendor(source):
    return any(part.lower() in CONFIG["vendor-directories"] for part in Path(source).parts)


def check_verible(tool, source):
    if tool == "verible-lint":
        return subprocess.run(
            ["verible-verilog-lint", "--rules=" + ",".join(PROJECT["tool"][tool]["rules"]), source],
            cwd=ROOT,
            check=False,
        ).returncode
    command = ["verible-verilog-format", *PROJECT["tool"][tool]["args"]]
    original = (ROOT / source).read_bytes()
    result = subprocess.run([*command, "--inplace", source], cwd=ROOT, check=False)
    if result.returncode:
        return result.returncode
    formatted = (ROOT / source).read_bytes()
    if original == formatted:
        return 0
    sys.stdout.writelines(
        difflib.unified_diff(
            original.decode().splitlines(keepends=True),
            formatted.decode().splitlines(keepends=True),
            fromfile=source,
            tofile=source + " (formatted)",
        )
    )
    # Apply the formatting locally and fail the CI check until it is committed.
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
    standard = CONFIG["systemverilog-standard" if path.suffix == ".sv" else "verilog-standard"]
    if tool == "verilator-lint":
        command = ["verilator", *PROJECT["tool"]["verilator"]["args"], "--language", standard, *args, source]
        return subprocess.run(command, cwd=ROOT, check=False).returncode
    from pyslang.driver import Driver

    driver = Driver()
    driver.addStandardArgs()
    command = shlex.join(["slang", "--std=" + standard, *PROJECT["tool"]["slang"]["args"], *args, source])
    success = driver.parseCommandLine(command) and driver.processOptions() and driver.parseAllSources()
    if success:
        success = driver.runFullCompilation()
    return 0 if success else 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tool", choices=["verible-format", "verible-lint", "verilator-lint", "slang-lint"])
    options = parser.parse_args()
    if os.environ.get("BASIL_HDL_LOGGED") != "1":
        log = ROOT / "build/log" / (options.tool + ".log")
        log.parent.mkdir(parents=True, exist_ok=True)
        with log.open("w") as stream:
            process = subprocess.Popen(
                [sys.executable, "-u", str(Path(__file__).resolve()), options.tool],
                env={**os.environ, "BASIL_HDL_LOGGED": "1"},
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                errors="replace",
            )
            for line in process.stdout:
                sys.stdout.write(line)
                stream.write(line)
            return process.wait()
    os.chdir(ROOT)
    names = (
        subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=ROOT)
        .decode()
        .split("\0")
    )
    files = sorted(
        {p for p in names if p.endswith(tuple(CONFIG["source-suffixes"])) and (ROOT / p).is_file() and not is_vendor(p)}
    )
    failed = []
    for source in files:
        if is_vendor(source):
            continue
        print(f"Checking {source}", flush=True)
        result = (
            check_verible(options.tool, source) if options.tool.startswith("verible-") else check(options.tool, source)
        )
        if result:
            failed.append(source)
    print(f"{options.tool}: {len(files) - len(failed)}/{len(files)} files passed", flush=True)
    for source in failed:
        print(f"FAILED: {source}")
    return bool(failed)


if __name__ == "__main__":
    sys.exit(main())
