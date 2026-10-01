"""DDR event traces from UG953, optionally also executed against AMD UNISIM.

Set BASIL_UNISIM_DIR to Vivado's data/verilog/src/unisims directory to check
these same expected traces with the vendor models. No vendor source is copied.
"""

from pathlib import Path

import pytest
from xilinx_sim import run_primitive_bench


def run_ddr(tmp_path, primitive, parameters):
    # Both top modules live in this testbench; select the requested one by name.
    source = tmp_path / ("test_Sim" + primitive.title() + ".v")
    source.write_text(Path(__file__).with_suffix(".v").read_text())
    run_primitive_bench(tmp_path, source, [primitive], parameters.items())


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
