"""Regression checks for simulation output isolation and concurrent-run protection."""

import os
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

from basil.utils.sim.utils import _simulation_directory, _simulations, cocotb_compile_and_run, cocotb_compile_clean


@pytest.mark.parametrize("simulator,directory", [("icarus", "iverilog"), ("verilator", "verilator")])
def test_simulation_directory(monkeypatch, tmp_path, simulator, directory):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setenv("SIM", simulator)
    assert _simulation_directory(None) == tmp_path / "build/sim" / directory
    assert _simulation_directory("custom") == tmp_path / "custom"


@pytest.mark.skipif(os.name != "posix", reason="The local socket-test lock uses POSIX flock")
def test_overlapping_simulation_runs(tmp_path):
    project = Path(__file__).resolve().parents[1]
    environment = {**os.environ, "PYTHONPATH": str(project)}
    acquire = "from basil.utils.sim.utils import _lock_simulations; _lock_simulations()"
    first = subprocess.Popen(
        [sys.executable, "-u", "-c", acquire + "; print('locked'); import time; time.sleep(30)"],
        cwd=tmp_path,
        env=environment,
        stdout=subprocess.PIPE,
        text=True,
    )
    try:
        assert first.stdout.readline().strip() == "locked"
        second = subprocess.run(
            [sys.executable, "-c", acquire],
            cwd=tmp_path,
            env=environment,
            capture_output=True,
            text=True,
            timeout=10,
            check=False,
        )
        assert second.returncode != 0
        assert "run the suites sequentially" in second.stderr
    finally:
        first.terminate()
        first.wait(timeout=10)
        first.stdout.close()
    # Exiting a runner releases the OS lock; the lock file need not be deleted.
    subprocess.run([sys.executable, "-c", acquire], cwd=tmp_path, env=environment, timeout=10, check=True)


@pytest.mark.skipif(not shutil.which("iverilog"), reason="Icarus Verilog is not installed")
def test_compile_failure_is_reported(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setenv("SIM", "icarus")
    source = tmp_path / "broken.v"
    source.write_text("module broken; this is not Verilog; endmodule\n")
    with pytest.raises(RuntimeError, match="return code"):
        cocotb_compile_and_run([source], top_level="broken")
    directory = _simulation_directory(None)
    assert directory not in _simulations
    assert not (directory / "runner.json").exists()


@pytest.mark.skipif(not shutil.which("iverilog"), reason="Icarus Verilog is not installed")
def test_simulation_failure_is_reported(monkeypatch, tmp_path):
    monkeypatch.chdir(tmp_path)
    monkeypatch.setenv("SIM", "icarus")
    directory = _simulation_directory(None)
    source = tmp_path / "tb.v"
    source.write_text("module tb; endmodule\n")
    (tmp_path / "failing_test.py").write_text(
        "import cocotb\n@cocotb.test()\nasync def failing(dut):\n"
        "    assert False, 'expected Cocotb assertion failure'\n"
    )
    cocotb_compile_and_run([source], test_module="failing_test")
    with pytest.raises(RuntimeError, match="Simulation failed with exit code 1"):
        cocotb_compile_clean()
    assert directory not in _simulations
    assert (directory / "sim.vvp").is_file()
    assert (directory / "results.xml").is_file()
    assert not (directory / "sim_build").exists()
    log = tmp_path / "build/log/iverilog-simulation.log"
    assert "expected Cocotb assertion failure" in log.read_text()
