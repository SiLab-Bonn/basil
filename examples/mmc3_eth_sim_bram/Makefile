SIMULATION_HOST?=localhost
SIMULATION_PORT?=12345
SIMULATION_BUS?=basil.utils.sim.BasilBusDriver
SIMULATION_END_ON_DISCONNECT?=1

VERILOG_SOURCES = /faust/user/mvogt/git/basil_fork-marco_dev/examples/mmc3_eth_sim_bram/mmc3_eth_tb.v

TOPLEVEL = tb
MODULE   = basil.utils.sim.Test

COMPILE_ARGS = -D COCOTB_SIM=1 -I/faust/user/mvogt/git/basil_dev/firmware/modules -I/faust/user/mvogt/git/basil_dev/firmware/modules/includes 
COMPILE_ARGS +=  

NOT_ICARUS_DEFINES= +define+COCOTB_SIM=1  
NOT_ICARUS_INCLUDE_DIRS=+incdir+./ +incdir+/faust/user/mvogt/git/basil_dev/firmware/modules +incdir+/faust/user/mvogt/git/basil_dev/firmware/modules/includes 



export SIMULATION_HOST
export SIMULATION_PORT
export SIMULATION_BUS
export SIMULATION_END_ON_DISCONNECT

#export COCOTB=$(shell cocotb-path)
export COCOTB=$(shell SPHINX_BUILD=1 python -c "import cocotb; import os; print(os.path.dirname(os.path.dirname(os.path.abspath(cocotb.__file__))))")
export PYTHONPATH=$(shell python -c "from distutils import sysconfig; print(sysconfig.get_python_lib())"):$(COCOTB)
export LD_LIBRARY_PATH=/lib/x86_64-linux-gnu:$(PYTHONLIBS)
export PYTHONPATH=$(shell python -c "from distutils import sysconfig; print(sysconfig.get_python_lib())"):$(COCOTB)
export PYTHONHOME=$(shell python -c "from distutils.sysconfig import get_config_var; print(get_config_var('prefix'))")

ifeq ($(SIM),questa)
    EXTRA_ARGS += $(NOT_ICARUS_DEFINES)
    EXTRA_ARGS +=$(NOT_ICARUS_INCLUDE_DIRS)
else ifeq ($(SIM),ius)
    EXTRA_ARGS +=$(NOT_ICARUS_DEFINES)
    EXTRA_ARGS +=$(NOT_ICARUS_INCLUDE_DIRS)
else ifeq ($(SIM),icarus)
    EXTRA_ARGS +=-g2012
else
    EXTRA_ARGS +=-g2012
endif

SIM_ARGS +=-fst

TOPLEVEL_LANG?=verilog
export TOPLEVEL_LANG

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim

    