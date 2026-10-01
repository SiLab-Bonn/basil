"""Functional clock checks shared with the external AMD reference."""

from pathlib import Path

import pytest
from xilinx_sim import run_primitive_bench


@pytest.mark.parametrize("use_base,inversions", [(0, n) for n in range(8)] + [(1, 0)])
def test_xilinx_clock_primitive_models(tmp_path, use_base, inversions):
    run_primitive_bench(
        tmp_path,
        Path(__file__).with_suffix(".v"),
        [
            "IBUFDS_GTE2",
            "PLLE2_ADV",
            "PLLE2_BASE",
            "pll",
            "dyn_reconf",
            "period_count",
            "period_check",
            "freq_gen",
            "phase_shift",
        ],
        [("UseBase", use_base), ("InvertControls", inversions)],
    )
