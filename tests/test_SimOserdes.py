"""Behavioral serializer words, independent tristate modes and explicit limits."""

import shutil
import subprocess
from pathlib import Path

import pytest


def run_model(tmp_path, top, source, parameters=()):
    iverilog = shutil.which("iverilog")
    vvp = shutil.which("vvp")
    if not iverilog or not vvp:
        pytest.skip("Icarus Verilog is not installed")
    model = Path(__file__).resolve().parents[1] / "basil/firmware/modules/utils/OSERDESE2.v"
    executable = tmp_path / "serializer.vvp"
    subprocess.run(
        [iverilog, "-g2005", "-s", top, *parameters, "-o", str(executable), str(source), str(model)],
        check=True,
        capture_output=True,
        text=True,
        timeout=30,
    )
    return subprocess.run(
        [vvp, str(executable)],
        check=True,
        capture_output=True,
        text=True,
        timeout=30,
    ).stdout


@pytest.mark.parametrize("rate,width", [("DDR", n) for n in (4, 6, 8, 10)] + [("SDR", n) for n in range(2, 9)])
@pytest.mark.parametrize("invert,phase", [(0, 0), (1, 2)])
def test_serializer_words(tmp_path, rate, width, invert, phase):
    parameters = [
        f'-Ptest_SimOserdes.DataRate="{rate}"',
        f"-Ptest_SimOserdes.DataWidth={width}",
        f"-Ptest_SimOserdes.Invert={invert}",
        f"-Ptest_SimOserdes.DivPhase={phase}",
    ]
    result = run_model(tmp_path, "test_SimOserdes", Path(__file__).with_suffix(".v"), parameters)
    assert "PASS: OSERDESE2 words" in result, result
    assert "FAIL:" not in result and "ERROR:" not in result, result


@pytest.mark.parametrize(
    "data_rate,tristate_rate,width",
    [
        ("SDR", "DDR", 4),
        ("SDR", "DDR", 1),
        ("DDR", "SDR", 1),
        ("DDR", "BUF", 1),
    ],
)
def test_tristate_modes(tmp_path, data_rate, tristate_rate, width):
    top = "test_SimOserdesTristate"
    source = Path(__file__).with_name(top + ".v")
    parameters = [
        f'-P{top}.DataRate="{data_rate}"',
        f'-P{top}.TristateRate="{tristate_rate}"',
        f"-P{top}.TristateWidth={width}",
    ]
    result = run_model(tmp_path, top, source, parameters)
    assert "PASS: OSERDESE2 tristate" in result, result
    assert "FAIL:" not in result and "ERROR:" not in result, result


@pytest.mark.parametrize(
    "attribute,value",
    [
        ("DataRate", '"INVALID"'),
        ("DataWidth", "14"),
        ("TristateRate", '"INVALID"'),
        ("TristateRate", '"SDR"'),
        ("TristateWidth", "2"),
        ("SerdesMode", '"INVALID"'),
        ("SerdesMode", '"SLAVE"'),
        ("ByteControl", '"TRUE"'),
        ("ByteSource", '"TRUE"'),
    ],
)
def test_unsupported_modes_stop_simulation(tmp_path, attribute, value):
    top = "test_SimOserdesTristate"
    source = Path(__file__).with_name(top + ".v")
    attributes = {"DataRate": '"DDR"', attribute: value}
    result = run_model(tmp_path, top, source, [f"-P{top}.{key}={val}" for key, val in attributes.items()])
    assert "ERROR: OSERDESE2" in result, result
    assert "PASS:" not in result, result
