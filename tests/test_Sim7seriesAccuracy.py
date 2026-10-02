"""Directed and seeded functional traces, optionally compared with installed UNISIM.

Set BASIL_UNISIM_DIR to Vivado's data/verilog/src/unisims directory. Vendor
sources are compiled separately and are never copied into the repository.
"""

from pathlib import Path

import pytest
from sim_7series import run_primitive_bench as compare_models


@pytest.mark.parametrize("output", [0, 1])
@pytest.mark.parametrize(
    "mode,pipe", [("FIXED", "FALSE"), ("VARIABLE", "FALSE"), ("VAR_LOAD", "FALSE"), ("VAR_LOAD_PIPE", "TRUE")]
)
@pytest.mark.parametrize("frequency,invert,source", [(200, 0, 0), (300, 1, 1), (400, 0, 1)])
def test_delay_traces(tmp_path, output, mode, pipe, frequency, invert, source):
    compare_models(
        tmp_path,
        Path(__file__).with_name("test_Sim7seriesDelays.v"),
        ["IDELAYE2", "ODELAYE2"],
        [
            ("OutputDelay", output),
            ("DelayType", f'"{mode}"'),
            ("PipeSelect", f'"{pipe}"'),
            ("Frequency", frequency),
            ("Invert", invert),
            ("SourceSelect", source),
        ],
    )


def test_gte_receiver_trace(tmp_path):
    compare_models(tmp_path, Path(__file__).with_name("test_SimGteReceiver.v"), ["IBUFDS_GTE2"])


@pytest.mark.parametrize("stopped_level", [0, 1])
def test_delayctrl_trace(tmp_path, stopped_level):
    compare_models(
        tmp_path,
        Path(__file__).with_name("test_SimDelayControl.v"),
        ["IDELAYCTRL"],
        [("StoppedLevel", stopped_level)],
    )


@pytest.mark.parametrize("edge", ["OPPOSITE_EDGE", "SAME_EDGE", "SAME_EDGE_PIPELINED"])
@pytest.mark.parametrize("reset_type,invert", [("SYNC", 0), ("ASYNC", 1)])
def test_ddr_seeded_trace(tmp_path, edge, reset_type, invert):
    compare_models(
        tmp_path,
        Path(__file__).with_name("test_SimDdrTrace.v"),
        ["IDDR", "ODDR"],
        [("EdgeMode", f'"{edge}"'), ("ResetType", f'"{reset_type}"'), ("Invert", invert)],
    )


@pytest.mark.parametrize("use_base", [0, 1])
def test_pll_output_metrics(tmp_path, use_base):
    compare_models(
        tmp_path,
        Path(__file__).with_name("test_Sim7seriesPllAccuracy.v"),
        ["PLLE2_BASE", "PLLE2_ADV", "pll", "dyn_reconf", "period_count", "period_check", "freq_gen", "phase_shift"],
        [("UseBase", use_base)],
    )


@pytest.mark.parametrize(
    "rate,width",
    [
        ("BUF", 1),
        ("SDR", 1),
        ("DDR", 4),
    ],
)
@pytest.mark.parametrize("invert", [0, 1])
def test_serializer_attributes(tmp_path, rate, width, invert):
    bench = Path(__file__).with_name("test_Sim7seriesSerializerAttributes.v")
    parameters = [("TristateRate", f'"{rate}"'), ("TristateWidth", width), ("Invert", invert)]
    compare_models(tmp_path, bench, ["OSERDESE2"], parameters)
