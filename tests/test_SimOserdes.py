"""Behavioral serializer words, independent tristate modes."""

from pathlib import Path

import pytest
from sim_7series import run_primitive_bench


@pytest.mark.parametrize("rate,width", [("DDR", n) for n in (4, 6, 8, 10)] + [("SDR", n) for n in range(2, 9)])
@pytest.mark.parametrize("invert,phase", [(0, 0), (1, 2)])
def test_serializer_words(tmp_path, rate, width, invert, phase):
    parameters = [
        ("DataRate", f'"{rate}"'),
        ("DataWidth", width),
        ("Invert", invert),
        ("DivPhase", phase),
    ]
    run_primitive_bench(tmp_path, Path(__file__).with_suffix(".v"), ["OSERDESE2"], parameters)


@pytest.mark.parametrize(
    "data_rate,tristate_rate,width",
    [
        ("DDR", "DDR", 4),
        ("SDR", "SDR", 1),
        ("DDR", "SDR", 1),
        ("DDR", "BUF", 1),
    ],
)
def test_tristate_modes(tmp_path, data_rate, tristate_rate, width):
    top = "test_SimOserdesTristate"
    source = Path(__file__).with_name(top + ".v")
    parameters = [
        ("DataRate", f'"{data_rate}"'),
        ("TristateRate", f'"{tristate_rate}"'),
        ("TristateWidth", width),
    ]
    run_primitive_bench(tmp_path, source, ["OSERDESE2"], parameters)
