"""Run one functional testbench with identical assertions for each library.

BASIL_UNISIM_DIR enables the external Vivado reference. OSERDESE2 requires
Vivado's simulator because its vendor wrapper uses secureip; other models
run with Icarus. Backend selection changes compilation, never expectations.
"""

import os
import shutil
import subprocess
from pathlib import Path

import pytest

UTILS = Path(__file__).resolve().parents[1] / "basil/firmware/modules/utils"


def run_primitive_bench(tmp_path, bench, primitives, parameters=()):
    if not shutil.which("iverilog") or not shutil.which("vvp"):
        pytest.skip("Icarus Verilog is not installed")
    if isinstance(bench, str):
        source = tmp_path / "tb.v"
        source.write_text("`timescale 1ps/1ps\n" + bench)
    else:
        source = bench
    top = source.stem
    globals_source = tmp_path / "glbl.v"
    globals_source.write_text(
        "`timescale 1ps/1ps\nmodule glbl; reg GSR = 1'b1; wire GTS = 1'b0; "
        "wire PLL_LOCKG = 1'b1; initial #1000 GSR = 1'b0; endmodule\n"
    )
    libraries = [("basil", UTILS)]
    if os.environ.get("BASIL_UNISIM_DIR"):
        libraries.append(("unisim", Path(os.environ["BASIL_UNISIM_DIR"])))
    traces = []
    for label, library in libraries:
        work = tmp_path / label
        work.mkdir()

        def command(args, work=work, label=label):
            result = subprocess.run(args, cwd=work, capture_output=True, text=True, timeout=120, check=False)
            with (work / "run.log").open("a") as log:
                log.write("$ " + " ".join(map(str, args)) + "\n" + result.stdout + result.stderr)
            assert result.returncode == 0, (label, result.stdout, result.stderr)
            return result.stdout

        if label == "unisim" and "OSERDESE2" in primitives:
            for tool in ("xvlog", "xelab", "xsim"):
                assert shutil.which(tool), f"UNISIM serializer comparisons require {tool} on PATH"
            command(["xvlog", str(source.resolve()), str(globals_source.resolve())])
            command(
                [
                    "xelab",
                    top,
                    "glbl",
                    "-L",
                    "unisims_ver",
                    "-L",
                    "secureip",
                    "-s",
                    "model",
                    *[arg for name, value in parameters for arg in ("-generic_top", f"{name}={value}")],
                ]
            )
            output = command(["xsim", "model", "-runall"])
        else:
            sources = []
            for name in primitives:
                directory = (
                    library.parent / "retarget" if label == "unisim" and name in {"IBUFG", "IBUFGDS"} else library
                )
                model = directory / (name + ".v")
                if model.exists():
                    sources.append(str(model))
            command(
                [
                    "iverilog",
                    "-g2005",
                    "-s",
                    top,
                    "-s",
                    "glbl",
                    "-o",
                    "model.vvp",
                    *[f"-P{top}.{name}={value}" for name, value in parameters],
                    str(source.resolve()),
                    str(globals_source.resolve()),
                    *sources,
                ]
            )
            output = command(["vvp", "model.vvp"])
        assert "PASS:" in output and "FAIL:" not in output and "ERROR:" not in output, (label, output)
        traces.append([line for line in output.splitlines() if line.startswith("TRACE")])
    if len(traces) == 2:
        assert traces[0] == traces[1]
