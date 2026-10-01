"""Regression checks for simulation output isolation and concurrent-run protection."""

import os
import subprocess
import sys
from pathlib import Path

import pytest

from basil.utils.sim.utils import _simulation_directory


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
