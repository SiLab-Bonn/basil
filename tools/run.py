"""Check Basil HDL formatting, style and independent designs without vendor trees."""

import argparse
import difflib
import os
import shlex
import subprocess
import sys
from pathlib import Path

from sources import CONFIG, PROJECT, ROOT


def main():
    # Step 1: Select the HDL check.
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("tool", choices=["verible-format", "verible-lint", "verilator-lint", "slang-lint"])
    tool = parser.parse_args().tool

    # Step 2: Mirror the check's output to its build log.
    if os.environ.get("BASIL_HDL_LOGGED") != "1":
        log = ROOT / "build/log" / (tool + ".log")
        log.parent.mkdir(parents=True, exist_ok=True)
        with log.open("w") as stream:
            process = subprocess.Popen(
                [sys.executable, "-u", str(Path(__file__).resolve()), tool],
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

    # Step 3: Collect existing HDL sources, excluding vendor directories.
    names = (
        subprocess.check_output(["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=ROOT)
        .decode()
        .split("\0")
    )
    files = sorted(
        {
            name
            for name in names
            if name.endswith(tuple(CONFIG["source-suffixes"]))
            and (ROOT / name).is_file()
            and not any(part.lower() in CONFIG["vendor-directories"] for part in Path(name).parts)
        }
    )

    # Step 4: Prepare the shared include and library search paths.
    shared_args = ["+incdir+" + directory for directory in CONFIG["include-directories"]]
    for directory in CONFIG["library-directories"]:
        shared_args += ["-y", directory]

    # Step 5: Run the selected check on each source.
    failed = []
    for source in files:
        print(f"Checking {source}", flush=True)
        if tool == "verible-lint":
            result = subprocess.run(
                ["verible-verilog-lint", "--rules=" + ",".join(PROJECT["tool"][tool]["rules"]), source],
                cwd=ROOT,
                check=False,
            ).returncode
        elif tool == "verible-format":
            original = (ROOT / source).read_bytes()
            result = subprocess.run(
                ["verible-verilog-format", *PROJECT["tool"][tool]["args"], "--inplace", source],
                cwd=ROOT,
                check=False,
            ).returncode
            if not result:
                formatted = (ROOT / source).read_bytes()
                if original != formatted:
                    sys.stdout.writelines(
                        difflib.unified_diff(
                            original.decode().splitlines(keepends=True),
                            formatted.decode().splitlines(keepends=True),
                            fromfile=source,
                            tofile=source + " (formatted)",
                        )
                    )
                    # Apply formatting locally and fail CI until it is committed.
                    result = 1
        else:
            path = Path(source)
            args = [*shared_args, "-y", str(path.parent)]
            if path.parts[0] == "examples":
                project = Path(*path.parts[:2])
                args += ["-I" + str(project)]
                directories = sorted({Path(name).parent for name in files if Path(name).is_relative_to(project)})
                for directory in directories:
                    args += ["-y", str(directory)]
            standard = CONFIG["systemverilog-standard" if path.suffix == ".sv" else "verilog-standard"]
            if tool == "verilator-lint":
                result = subprocess.run(
                    ["verilator", *PROJECT["tool"]["verilator"]["args"], "--language", standard, *args, source],
                    cwd=ROOT,
                    check=False,
                ).returncode
            else:
                from pyslang.driver import Driver

                driver = Driver()
                driver.addStandardArgs()
                command = shlex.join(["slang", "--std=" + standard, *PROJECT["tool"]["slang"]["args"], *args, source])
                success = driver.parseCommandLine(command) and driver.processOptions() and driver.parseAllSources()
                if success:
                    success = driver.runFullCompilation()
                result = 0 if success else 1
        if result:
            failed.append(source)

    # Step 6: Report failures and return the check's exit status.
    print(f"{tool}: {len(files) - len(failed)}/{len(files)} files passed", flush=True)
    for source in failed:
        print(f"FAILED: {source}")
    return bool(failed)


if __name__ == "__main__":
    sys.exit(main())
