"""DDR event traces from UG953, optionally also executed against AMD UNISIM.

Set BASIL_UNISIM_DIR to Vivado's data/verilog/src/unisims directory to check
these same expected traces with the vendor models. No vendor source is copied.
"""

import os
import shutil
import subprocess
from pathlib import Path

import pytest

UTILS = Path(__file__).resolve().parents[1] / "basil/firmware/modules/utils"
TESTBENCH = Path(__file__).with_suffix(".v")


def run_ddr(tmp_path, primitive, parameters):
    iverilog, vvp = shutil.which("iverilog"), shutil.which("vvp")
    if not iverilog or not vvp:
        pytest.skip("Icarus Verilog is not installed")
    top = "test_Sim" + primitive.title()
    sources = [("basil", UTILS / (primitive + ".v"))]
    if os.environ.get("BASIL_UNISIM_DIR"):
        sources.append(("unisim", Path(os.environ["BASIL_UNISIM_DIR"]) / (primitive + ".v")))
    global_signals = tmp_path / "glbl.v"
    global_signals.write_text(
        "`timescale 1ns/1ps\nmodule glbl; reg GSR; wire GTS = 1'b0; initial begin GSR = 1'b1; #0.1 GSR = 1'b0; end endmodule\n"
    )
    for label, model in sources:
        simulation = tmp_path / (label + ".vvp")
        command = [iverilog, "-g2005", "-s", top, "-s", "glbl", "-o", str(simulation)]
        command += [f"-P{top}.{key}={value}" for key, value in parameters.items()]
        subprocess.run(
            [*command, str(TESTBENCH), str(model), str(global_signals)],
            cwd=tmp_path,
            check=True,
            capture_output=True,
            text=True,
            timeout=30,
        )
        result = subprocess.run(
            [vvp, str(simulation)], cwd=tmp_path, check=True, capture_output=True, text=True, timeout=30
        )
        assert f"PASS: {primitive} behavior" in result.stdout, (label, result.stdout)
        assert "FAIL:" not in result.stdout and "ERROR:" not in result.stdout, (label, result.stdout)


@pytest.mark.parametrize("mode", ["OPPOSITE_EDGE", "SAME_EDGE", "SAME_EDGE_PIPELINED"])
@pytest.mark.parametrize("reset_type", ["SYNC", "ASYNC"])
@pytest.mark.parametrize("init1,init2", [(0, 0), (0, 1), (1, 0), (1, 1)])
@pytest.mark.parametrize("invert_clock,invert_data", [(0, 0), (0, 1), (1, 0), (1, 1)])
def test_iddr_modes(tmp_path, mode, reset_type, init1, init2, invert_clock, invert_data):
    run_ddr(
        tmp_path,
        "IDDR",
        {
            "EdgeMode": f'"{mode}"',
            "ResetType": f'"{reset_type}"',
            "Init1": init1,
            "Init2": init2,
            "InvertClock": invert_clock,
            "InvertData": invert_data,
        },
    )


@pytest.mark.parametrize("mode", ["OPPOSITE_EDGE", "SAME_EDGE"])
@pytest.mark.parametrize("reset_type", ["SYNC", "ASYNC"])
@pytest.mark.parametrize("init", [0, 1])
@pytest.mark.parametrize("inversions", range(8))
def test_oddr_modes(tmp_path, mode, reset_type, init, inversions):
    run_ddr(
        tmp_path,
        "ODDR",
        {
            "EdgeMode": f'"{mode}"',
            "ResetType": f'"{reset_type}"',
            "Init": init,
            "InvertClock": inversions & 1,
            "InvertData1": (inversions >> 1) & 1,
            "InvertData2": (inversions >> 2) & 1,
        },
    )


@pytest.mark.parametrize(
    "primitive,attribute,value",
    [
        ("IDDR", "DDR_CLK_EDGE", '"INVALID"'),
        ("IDDR", "DDR_CLK_EDGE", '"INVALID_SAME_EDGE_PIPELINED"'),
        ("IDDR", "SRTYPE", '"INVALID_ASYNC"'),
        ("IDDR", "INIT_Q1", "2"),
        ("IDDR", "INIT_Q2", "1'bx"),
        ("ODDR", "DDR_CLK_EDGE", '"SAME_EDGE_PIPELINED"'),
        ("ODDR", "SRTYPE", '"INVALID_ASYNC"'),
        ("ODDR", "INIT", "2"),
    ],
)
def test_invalid_ddr_parameters(tmp_path, primitive, attribute, value):
    iverilog, vvp = shutil.which("iverilog"), shutil.which("vvp")
    if not iverilog or not vvp:
        pytest.skip("Icarus Verilog is not installed")
    inputs = "C,CE,D,R,S" if primitive == "IDDR" else "C,CE,D1,D2,R,S"
    ports = ",".join(f".{p}(1'b0)" for p in inputs.split(","))
    bench = tmp_path / "invalid.v"
    bench.write_text(
        f"module tb; {primitive} #(.{attribute}({value})) dut ({ports}); "
        'initial begin #1; $display("FAIL: invalid parameter accepted"); $finish; end endmodule\n'
    )
    executable = tmp_path / "invalid.vvp"
    subprocess.run(
        [iverilog, "-g2005", "-s", "tb", "-o", str(executable), str(bench), str(UTILS / (primitive + ".v"))],
        cwd=tmp_path,
        check=True,
        capture_output=True,
        text=True,
        timeout=30,
    )
    result = subprocess.run(
        [vvp, str(executable)], cwd=tmp_path, check=True, capture_output=True, text=True, timeout=30
    )
    assert f"ERROR: {primitive}" in result.stdout
    assert "FAIL:" not in result.stdout
