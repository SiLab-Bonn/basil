#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import atexit
import os
import signal
import subprocess
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
    # make may have exited while its simulator is still running.
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


def cocotb_makefile(
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
):
    basil_dir = get_basil_dir()
    include_dirs += (basil_dir + "/firmware/modules", basil_dir + "/firmware/modules/includes")
    include_dirs = tuple(os.path.abspath(str(directory)) for directory in include_dirs)

    mkfile = "SIMULATION_HOST?=%s\nSIMULATION_PORT?=%d\nSIMULATION_BUS?=%s\n" % (sim_host, sim_port, sim_bus)

    if end_on_disconnect:
        mkfile += "SIMULATION_END_ON_DISCONNECT?=1\n"

    mkfile += "\n"

    mkfile += "VERILOG_SOURCES = %s\n\n" % (" ".join(os.path.abspath(str(e)) for e in sim_files))

    mkfile += "TOPLEVEL = %s\nMODULE = %s\n\n" % (top_level, test_module)

    mkfile += "ICARUS_INCLUDE_DIRS = %s\n" % (" ".join("-I" + str(e) for e in include_dirs))
    mkfile += "ICARUS_DEFINES += %s\n\n" % (" ".join("-D" + str(e) for e in extra_defines))

    mkfile += "NOT_ICARUS_DEFINES = %s\n" % (" ".join("+define+" + str(e) for e in extra_defines))
    mkfile += "NOT_ICARUS_INCLUDE_DIRS=+incdir+./ %s\n" % (
        " ".join("+incdir+" + str(e) for e in include_dirs)
    )  # this is for modelsim better full path?

    mkfile += "COMPILE_ARGS_DEFINES = %s\n" % (
        " ".join(str(e) for e in compile_args)
    )  # extra compiler args, e.g., for adding Xilinx's glbl.v to Icarus use "-s glbl"
    mkfile += "BUILD_ARGS_DEFINES = %s\n" % (
        " ".join(str(e) for e in build_args)
    )  # extra build args passed to build stage in supported simulators

    mkfile += "\n"
    mkfile += extra
    mkfile += "\n"

    try:
        if os.environ["SIM"] == "verilator":
            mkfile += "EXTRA_ARGS += -DVERILATOR_SIM\n"
            mkfile += "EXTRA_ARGS += -Wno-WIDTH -Wno-TIMESCALEMOD -Wwarn-ASSIGNDLY\n"
    except KeyError:
        pass

    mkfile += """
export SIMULATION_HOST
export SIMULATION_PORT
export SIMULATION_BUS
export SIMULATION_END_ON_DISCONNECT

export COCOTB=$(shell cocotb-config --share)
#export COCOTB=$(shell SPHINX_BUILD=1 python -c "import cocotb; import os; print(os.path.dirname(os.path.dirname(os.path.abspath(cocotb.__file__))))")
#export PYTHONPATH=$(shell python -c "from distutils import sysconfig; print(sysconfig.get_python_lib())"):$(COCOTB)
#export LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:$(PYTHONLIBS)
#export PYTHONHOME=$(shell python -c "from distutils.sysconfig import get_config_var; print(get_config_var('prefix'))")

ifeq ($(SIM),questa)
    EXTRA_ARGS += $(NOT_ICARUS_DEFINES)
    EXTRA_ARGS += $(NOT_ICARUS_INCLUDE_DIRS)
else ifeq ($(SIM),ius)
    EXTRA_ARGS += $(NOT_ICARUS_DEFINES)
    EXTRA_ARGS += $(NOT_ICARUS_INCLUDE_DIRS)
else
    COMPILE_ARGS += $(ICARUS_DEFINES)
    COMPILE_ARGS += $(ICARUS_INCLUDE_DIRS)
endif

COMPILE_ARGS += $(COMPILE_ARGS_DEFINES)
ifeq ($(SIM), verilator)
    BUILD_ARGS += $(BUILD_ARGS_DEFINES)
endif

TOPLEVEL_LANG?=verilog
export TOPLEVEL_LANG

include $(shell cocotb-config --makefiles)/Makefile.sim

    """

    return mkfile


def cocotb_compile_and_run(*args, sim_dir=None, **kw):
    # run simulator in background
    _lock_simulations()
    directory = _simulation_directory(sim_dir)
    if directory in _simulations:
        _stop_simulation(_simulations.pop(directory))
    directory.mkdir(parents=True, exist_ok=True)
    with (directory / "Makefile").open("w") as f:
        f.write(cocotb_makefile(*args, **kw))
    environment = os.environ.copy()
    environment["PYTHONPATH"] = os.pathsep.join(filter(None, (str(Path.cwd()), environment.get("PYTHONPATH"))))
    log = Path.cwd() / "build/log" / (directory.name + "-simulation.log")
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("w") as stream:
        process = subprocess.Popen(
            ["make"],
            cwd=directory,
            env=environment,
            stdout=stream,
            stderr=subprocess.STDOUT,
            start_new_session=os.name == "posix",
        )
    _simulations[directory] = process
    return process


def cocotb_compile_clean(sim_dir=None):
    directory = _simulation_directory(sim_dir)
    if directory in _simulations:
        _stop_simulation(_simulations.pop(directory))
    if (directory / "Makefile").is_file():
        log = Path.cwd() / "build/log" / (directory.name + "-simulation.log")
        log.parent.mkdir(parents=True, exist_ok=True)
        with log.open("a") as stream:
            subprocess.call(["make", "clean"], cwd=directory, stdout=stream, stderr=subprocess.STDOUT)
        (directory / "Makefile").unlink()
