"""Freeze the functional Vivado 2025.2 interfaces checked against UG953 2026.1.

The fixture records declarations, including positional order, from
Vivado/data/verilog/src/unisims and retarget/IBUFG{,DS}.v with XIL_TIMING off.
Electrical/timing attributes are accepted by the ideal digital models.
"""

import json
import re
from pathlib import Path

import pytest

UTILS = Path(__file__).resolve().parents[1] / "basil/firmware/modules/utils"
INTERFACES = json.loads(Path(__file__).with_name("data").joinpath("xilinx_7series_interfaces.json").read_text())


def numeric_or_literal(value):
    try:
        return float(value)
    except ValueError:
        return value


@pytest.mark.parametrize("primitive", INTERFACES)
def test_functional_interface(primitive):
    expected = INTERFACES[primitive]
    source = (UTILS / (primitive + ".v")).read_text()
    source = re.sub(r"/\*.*?\*/|//[^\n]*", "", source, flags=re.DOTALL)
    header = source[source.index("module ") : source.index(";", source.index("module "))]
    params = dict(
        re.findall(
            r"\bparameter\s+(?:(?:integer|real)\s+)?(?:\[[^\]]+\]\s*)?(\w+)\s*=\s*([^,\n]+)",
            header,
        )
    )
    assert list(params) == list(expected["parameters"])
    for name, default in expected["parameters"].items():
        assert numeric_or_literal(params[name].strip()) == numeric_or_literal(default), name
    ports = {}
    port_list = header.rsplit(") (", 1)[-1] if "#(" in header else header.split("(", 1)[1]
    for direction, msb, lsb, name in re.findall(
        r"\b(input|output|inout)\s+(?:wire|reg)\s*(?:\[\s*(\d+)\s*:\s*(\d+)\s*\])?\s*(\w+)",
        port_list,
    ):
        ports[name] = [direction, abs(int(msb) - int(lsb)) + 1 if msb else 1]
    assert ports == expected["ports"]
    assert list(ports) == list(expected["ports"])


def test_buffer_behavior(tmp_path):
    import os
    import shutil
    import subprocess

    iverilog, vvp = shutil.which("iverilog"), shutil.which("vvp")
    if not iverilog or not vvp:
        pytest.skip("Icarus Verilog is not installed")
    primitives = ["BUFG", "IBUF", "IBUFG", "OBUF", "OBUFDS", "IOBUF", "IBUFDS", "IBUFGDS"]
    libraries = [[UTILS / (p + ".v") for p in primitives]]
    if os.environ.get("BASIL_UNISIM_DIR"):
        vendor = Path(os.environ["BASIL_UNISIM_DIR"])
        libraries.append(
            [(vendor.parent / "retarget" if p in {"IBUFG", "IBUFGDS"} else vendor) / (p + ".v") for p in primitives]
        )
    globals_source = tmp_path / "glbl.v"
    globals_source.write_text("module glbl; wire GSR = 1'b0; wire GTS = 1'b0; endmodule\n")
    for sources in libraries:
        executable = tmp_path / "buffers.vvp"
        subprocess.run(
            [
                iverilog,
                "-g2005",
                "-s",
                "test_SimXilinxBuffers",
                "-s",
                "glbl",
                "-o",
                str(executable),
                str(Path(__file__).with_name("test_SimXilinxBuffers.v")),
                str(globals_source),
                *map(str, sources),
            ],
            check=True,
            capture_output=True,
            text=True,
            timeout=30,
        )
        result = subprocess.run([vvp, str(executable)], check=True, capture_output=True, text=True, timeout=30)
        assert "PASS: Xilinx buffers" in result.stdout, result.stdout
        assert "FAIL:" not in result.stdout, result.stdout
