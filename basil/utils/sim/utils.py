#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import atexit
import json
import os
import signal
import subprocess
import sys
from pathlib import Path

import basil

_simulation_lock = None
_simulations = {}


def _simulation_directory(sim_dir):
    simulator = os.environ.get("SIM", "icarus")
    simulator = "iverilog" if simulator == "icarus" else simulator
    return Path(sim_dir or Path.cwd() / "build/sim" / simulator).resolve()


def _lock_simulations():
    global _simulation_lock
    if _simulation_lock is not None or os.name != "posix":
        return
    import fcntl

    # Keep the lock for this Python process: all socket tests share port 12345.
    path = Path.cwd() / "build/sim/.socket-tests.lock"
    path.parent.mkdir(parents=True, exist_ok=True)
    stream = path.open("a")
    try:
        fcntl.flock(stream, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        stream.close()
        raise RuntimeError(
            "Another Basil simulation test run is active in this checkout; run the suites sequentially."
        ) from None
    _simulation_lock = stream


def _stop_simulation(process):
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        pass
    # The runner may have exited while its simulator is still running.
    if os.name == "posix":
        try:
            os.killpg(process.pid, signal.SIGTERM)
        except ProcessLookupError:
            pass
    elif process.poll() is None:
        process.terminate()
    try:
        process.wait(timeout=5)
    except subprocess.TimeoutExpired:
        if os.name == "posix":
            os.killpg(process.pid, signal.SIGKILL)
        else:
            process.kill()
        process.wait()


@atexit.register
def _cleanup_simulations():
    for process in _simulations.values():
        _stop_simulation(process)
    if _simulation_lock is not None:
        _simulation_lock.close()


def get_basil_dir():
    return str(os.path.dirname(basil.__file__))


def cocotb_compile_and_run(
    sim_files,
    top_level="tb",
    test_module="basil.utils.sim.Test",
    sim_host="localhost",
    sim_port=12345,
    sim_bus="basil.utils.sim.BasilBusDriver",
    end_on_disconnect=True,
    include_dirs=(),
    extra_defines=(),
    compile_args=(),
    build_args=(),
    extra="",
    *,
    sim_dir=None,
):
    """Build HDL synchronously, then run the socket server in the background."""
    from cocotb_tools.runner import get_runner

    if extra:
        raise ValueError(
            "Makefile fragments are no longer supported; use include_dirs, extra_defines and compile_args."
        )
    _lock_simulations()
    directory = _simulation_directory(sim_dir)
    if directory in _simulations:
        _stop_simulation(_simulations.pop(directory))
    directory.mkdir(parents=True, exist_ok=True)
    simulator = os.environ.get("SIM", "icarus")
    simulator = "xcelium" if simulator == "ius" else simulator
    runner = get_runner(simulator)
    defines = {}
    for definition in extra_defines:
        name, separator, value = str(definition).partition("=")
        defines[name] = value if separator else "1"
    arguments = list(compile_args) + list(build_args)
    if simulator == "icarus":
        arguments += ["-g2005"]
    elif simulator == "verilator":
        defines["VERILATOR_SIM"] = "1"
        arguments += ["--language", "1364-2005", "-Wno-WIDTH", "-Wno-TIMESCALEMOD", "-Wwarn-ASSIGNDLY"]
    basil_dir = Path(get_basil_dir())
    log = Path.cwd() / "build/log" / (directory.name + "-simulation.log")
    log.parent.mkdir(parents=True, exist_ok=True)
    runner.build(
        sources=[Path(source).resolve() for source in sim_files],
        includes=[Path(path).resolve() for path in include_dirs]
        + [basil_dir / "firmware/modules", basil_dir / "firmware/modules/includes"],
        defines=defines,
        build_args=arguments,
        hdl_toplevel=top_level,
        build_dir=directory,
        always=True,
        clean=True,
        log_file=log,
    )
    environment = os.environ.copy()
    # The worker validates Cocotb results itself rather than pytest's runner path.
    environment.pop("PYTEST_CURRENT_TEST", None)
    environment["PYTHONPATH"] = os.pathsep.join(filter(None, (str(Path.cwd()), environment.get("PYTHONPATH"))))
    settings = {
        "simulator": simulator,
        "top_level": top_level,
        "test_module": test_module,
        "directory": str(directory),
        "extra_env": {
            "SIMULATION_HOST": environment.get("SIMULATION_HOST", str(sim_host)),
            "SIMULATION_PORT": environment.get("SIMULATION_PORT", str(sim_port)),
            "SIMULATION_BUS": environment.get("SIMULATION_BUS", sim_bus),
            "SIMULATION_END_ON_DISCONNECT": environment.get(
                "SIMULATION_END_ON_DISCONNECT", "1" if end_on_disconnect else ""
            ),
        },
    }
    settings_file = directory / "runner.json"
    settings_file.write_text(json.dumps(settings))
    with log.open("a") as stream:
        process = subprocess.Popen(
            [sys.executable, "-m", "basil.utils.sim.utils", str(settings_file)],
            cwd=directory,
            env=environment,
            stdout=stream,
            stderr=subprocess.STDOUT,
            start_new_session=os.name == "posix",
        )
    _simulations[directory] = process
    return process


def cocotb_compile_clean(sim_dir=None):
    """Stop and reap the simulation, retaining build outputs for inspection."""
    directory = _simulation_directory(sim_dir)
    if directory in _simulations:
        process = _simulations.pop(directory)
        _stop_simulation(process)
        if process.returncode not in (0, -signal.SIGTERM):
            log = Path.cwd() / "build/log" / (directory.name + "-simulation.log")
            raise RuntimeError(f"Simulation failed with exit code {process.returncode}; see {log}")


def _run_simulation(settings_file):
    from cocotb_tools.check_results import get_results
    from cocotb_tools.runner import get_runner

    settings = json.loads(Path(settings_file).read_text())
    directory = Path(settings["directory"])
    runner = get_runner(settings["simulator"])
    results = runner.test(
        hdl_toplevel=settings["top_level"],
        hdl_toplevel_lang="verilog",
        test_module=settings["test_module"],
        build_dir=directory,
        test_dir=directory,
        extra_env=settings["extra_env"],
        results_xml=str(directory / "results.xml"),
    )
    count, failures = get_results(results)
    if not count or failures:
        raise RuntimeError(f"Cocotb reported {failures} failures in {count} tests; see {results}")


if __name__ == "__main__":
    _run_simulation(sys.argv[1])
