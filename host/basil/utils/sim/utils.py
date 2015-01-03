#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import subprocess
import time
import os

def cocotb_makefile(sim_files, top_level = 'tb', test_module='basil.utils.sim.Test' ,sim_host='localhost', sim_port=12345, sim_bus='basil.utils.sim.BasilBusDriver', 
                    end_on_disconnect=True, include_dirs=['../../../device/modules', '../../../device/modules/includes'] ):
    
    mkfile = "SIMULATION_HOST?=%s\nSIMULATION_PORT?=%d\nSIMULATION_BUS?=%s\n" % (sim_host, sim_port, sim_bus)
    
    if(end_on_disconnect):
        mkfile += "SIMULATION_END_ON_DISCONNECT?=1\n"
    
    mkfile += "\n"
      
    mkfile += "VERILOG_SOURCES = %s\n\n" % (" ".join(str(e) for e in sim_files))

    mkfile += "TOPLEVEL = %s\nMODULE   = %s\n\n" % (top_level, test_module)

    mkfile += "EXTRA_ARGS = -D_IVERILOG_ %s \n\n" % (" ".join( '-I'+str(e) for e in include_dirs))

    mkfile += """
export SIMULATION_HOST
export SIMULATION_PORT
export SIMULATION_BUS
export SIMULATION_END_ON_DISCONNECT

TOPLEVEL_LANG?=verilog
export TOPLEVEL_LANG

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim
    """
    
    return mkfile

def cocotb_compile_and_run(verilog_sources):
    #thiscompile files but will not run simulation -> explicit error
    file = open('Makefile','w')
    file.write(cocotb_makefile(verilog_sources, top_level='none'))
    file.close()
    FNULL = open(os.devnull, 'w')
    subprocess.call("make", shell=True, stdout=FNULL, stderr=subprocess.STDOUT) 
    
    #run simulator in background
    file = open('Makefile','w')
    file.write(cocotb_makefile(verilog_sources))
    file.close()
    subprocess.Popen(['make']) 
    time.sleep(2)
    
    