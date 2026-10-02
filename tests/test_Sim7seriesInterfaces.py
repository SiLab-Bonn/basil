"""Freeze the functional Vivado 2025.2 interfaces checked against UG953 2026.1.

The fixture records declarations, including positional order, from
Vivado/data/verilog/src/unisims and retarget/IBUFG{,DS}.v with XIL_TIMING off.
Electrical/timing attributes are accepted by the ideal digital models.
"""

import json
import os
import re
import shutil
import subprocess
from pathlib import Path

import pytest
from sim_7series import run_primitive_bench

UTILS = Path(__file__).resolve().parents[1] / "basil/firmware/modules/utils"
INTERFACES = json.loads(Path(__file__).with_name("data").joinpath("models_7series_interfaces.json").read_text())


PARAMETER_TYPES = json.loads(
    Path(__file__).with_name("data").joinpath("models_7series_parameter_types.json").read_text()
)


def numeric_or_literal(value):
    try:
        return float(value)
    except ValueError:
        return value


def functional_interface(source, primitive, tmp_path):
    """Normalize ANSI/non-ANSI declarations with timing-only attributes disabled."""
    if not shutil.which("iverilog"):
        pytest.skip("Icarus Verilog is not installed")
    preprocessed = tmp_path / "interface.v"
    subprocess.run(
        ["iverilog", "-g2005", "-E", "-o", str(preprocessed), str(source)],
        check=True,
        capture_output=True,
        text=True,
        timeout=30,
    )
    text = re.sub(r"/\*.*?\*/|//[^\n]*", "", preprocessed.read_text(), flags=re.DOTALL)
    body = re.search(r"\bmodule\s+" + primitive + r"\b(.*?)\bendmodule", text, re.DOTALL).group(1)
    header, declarations = body.split(";", 1)
    port_header = header.rsplit("(", 1)[1].rsplit(")", 1)[0]
    order = [port.strip().split()[-1] for port in port_header.split(",")]
    ports = {}
    for direction, msb, lsb, names in re.findall(
        r"\b(input|output|inout)\s+(?:(?:wire|reg)\s+)?(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*)?([^;]+);",
        declarations,
    ):
        for name in names.split(","):
            ports[name.strip()] = [direction, abs(int(msb) - int(lsb)) + 1 if msb else 1]
    for direction, msb, lsb, name in re.findall(
        r"\b(input|output|inout)\s+(?:(?:wire|reg)\s+)?(?:\[\s*(\d+)\s*:\s*(\d+)\s*\]\s*)?(\w+)",
        port_header,
    ):
        ports[name] = [direction, abs(int(msb) - int(lsb)) + 1 if msb else 1]
    parameters, types = {}, {}
    for declaration, name, default in re.findall(
        r"\bparameter\s+((?:(?:integer|real)\s+)?(?:\[[^\]]+\]\s*)?)(\w+)\s*=\s*([^;,\n]+)", body
    ):
        parameters[name] = numeric_or_literal(default.strip())
        types[name] = declaration.strip()
    return {name: ports[name] for name in order}, parameters, types


@pytest.mark.parametrize("primitive", INTERFACES)
def test_functional_interface(tmp_path, primitive):
    expected = INTERFACES[primitive]
    sources = [UTILS / (primitive + ".v")]
    if os.environ.get("BASIL_UNISIM_DIR"):
        vendor = Path(os.environ["BASIL_UNISIM_DIR"])
        directory = vendor.parent / "retarget" if primitive in {"IBUFG", "IBUFGDS"} else vendor
        sources.append(directory / (primitive + ".v"))
    for source in sources:
        ports, parameters, types = functional_interface(source, primitive, tmp_path)
        assert ports == expected["ports"], source
        assert list(ports) == list(expected["ports"]), source
        assert parameters == {name: numeric_or_literal(value) for name, value in expected["parameters"].items()}, source
        assert list(parameters) == list(expected["parameters"]), source
        assert types == PARAMETER_TYPES[primitive], source


def test_buffer_behavior(tmp_path):
    run_primitive_bench(
        tmp_path,
        Path(__file__).with_name("test_Sim7seriesBuffers.v"),
        ["BUFG", "IBUF", "IBUFG", "OBUF", "OBUFDS", "IOBUF", "IBUFDS", "IBUFGDS"],
    )
