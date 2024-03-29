SIMULATION_HOST?=localhost
SIMULATION_PORT?=12345
SIMULATION_BUS?=basil.utils.sim.BasilBusDriver
SIMULATION_END_ON_DISCONNECT?=1

VERILOG_SOURCES = /users/rleiser/work/basil_branch/tests/test_SimTimestamp.v

TOPLEVEL = tb
MODULE = basil.utils.sim.Test

ICARUS_INCLUDE_DIRS = -I/users/rleiser/work/basil_branch/basil/firmware/modules -I/users/rleiser/work/basil_branch/basil/firmware/modules/includes
ICARUS_DEFINES += 

NOT_ICARUS_DEFINES = 
NOT_ICARUS_INCLUDE_DIRS=+incdir+./ +incdir+/users/rleiser/work/basil_branch/basil/firmware/modules +incdir+/users/rleiser/work/basil_branch/basil/firmware/modules/includes
COMPILE_ARGS_DEFINES = 
BUILD_ARGS_DEFINES = 



export SIMULATION_HOST
export SIMULATION_PORT
export SIMULATION_BUS
export SIMULATION_END_ON_DISCONNECT

export COCOTB=$(shell cocotb-config --share)
#export COCOTB=$(shell SPHINX_BUILD=1 python -c "import cocotb; import os; print(os.path.dirname(os.path.dirname(os.path.abspath(cocotb.__file__))))")
#export PYTHONPATH=$(shell python -c "from distutils import sysconfig; print(sysconfig.get_python_lib())"):$(COCOTB)
#export LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:$(PYTHONLIBS)
export PYTHONHOME=$(shell python -c "from distutils.sysconfig import get_config_var; print(get_config_var('prefix'))")

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

    