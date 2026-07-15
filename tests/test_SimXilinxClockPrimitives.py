"""Compile and exercise the functional Xilinx clock primitive models."""

from pathlib import Path
import shutil
import subprocess

import pytest


def test_xilinx_clock_primitive_models(tmp_path):
    iverilog = shutil.which("iverilog")
    vvp = shutil.which("vvp")
    if iverilog is None or vvp is None:
        pytest.skip("Icarus Verilog is not installed")

    basil_root = Path(__file__).resolve().parents[1]
    utils = basil_root / "basil" / "firmware" / "modules" / "utils"
    testbench = Path(__file__).with_suffix(".v")
    simulation = tmp_path / "xilinx_clock_primitives.vvp"
    sources = [
        testbench,
        utils / "IBUFDS_GTE2.v",
        utils / "PLLE2_ADV.v",
        utils / "pll.v",
        utils / "dyn_reconf.v",
        utils / "period_count.v",
        utils / "period_check.v",
        utils / "freq_gen.v",
        utils / "phase_shift.v",
    ]

    subprocess.run(
        [iverilog, "-g2005", "-s", "test_SimXilinxClockPrimitives", "-o", simulation, *sources],
        check=True,
        capture_output=True,
        text=True,
    )
    result = subprocess.run([vvp, simulation], check=True, capture_output=True, text=True)
    assert "PASS: Xilinx clock primitive models" in result.stdout
    assert "FAIL:" not in result.stdout
