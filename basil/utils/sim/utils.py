#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import subprocess
import basil
import os


def get_basil_dir():
    return str(os.path.dirname(os.path.dirname(basil.__file__)))


def cocotb_makefile(sim_files, top_level='tb', test_module='basil.utils.sim.Test', sim_host='localhost', sim_port=12345, sim_bus='basil.utils.sim.BasilBusDriver',
                    end_on_disconnect=True, include_dirs=(), extra_defines=(), extra=''):

    basil_dir = get_basil_dir()
    include_dirs += (basil_dir + "/firmware/modules", basil_dir + "/firmware/modules/includes")

    mkfile = "SIMULATION_HOST?=%s\nSIMULATION_PORT?=%d\nSIMULATION_BUS?=%s\n" % (sim_host, sim_port, sim_bus)

    if(end_on_disconnect):
        mkfile += "SIMULATION_END_ON_DISCONNECT?=1\n"

    mkfile += "\n"

    mkfile += "VERILOG_SOURCES = %s\n\n" % (" ".join(str(e) for e in sim_files))

    mkfile += "TOPLEVEL = %s\nMODULE   = %s\n\n" % (top_level, test_module)

    mkfile += "COMPILE_ARGS = -D COCOTB_SIM=1 %s \n" % (" ".join('-I' + str(e) for e in include_dirs))
    mkfile += "COMPILE_ARGS += %s \n\n" % (" ".join('-D' + str(e) for e in extra_defines))

    mkfile += "NOT_ICARUS_DEFINES= +define+COCOTB_SIM=1 %s \n" % (" ".join('+define+' + str(e) for e in extra_defines))
    mkfile += "NOT_ICARUS_INCLUDE_DIRS=+incdir+./ %s \n" % (" ".join('+incdir+' + str(e) for e in include_dirs))  # this is for modelsim better full path?

    mkfile += "\n"
    mkfile += extra
    mkfile += "\n"

    mkfile += """
export SIMULATION_HOST
export SIMULATION_PORT
export SIMULATION_BUS
export SIMULATION_END_ON_DISCONNECT

PYTHONLIBS=$(shell python -c 'from distutils import sysconfig; print(sysconfig.get_config_var("LIBDIR"))')
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

    """

    return mkfile


def cocotb_compile_and_run(*args, **kw):
    # run simulator in background
    with open('Makefile', 'w') as f:
        f.write(cocotb_makefile(*args, **kw))
    subprocess.Popen(['make'])


def cocotb_compile_clean():
    subprocess.call('make clean', shell=True)
    subprocess.call('rm -f Makefile', shell=True)
