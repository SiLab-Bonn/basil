#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' This script shows how to use a Suss Probe station.

BTW:
For the PA-200 it is not forseen to be able to communicate with the prober bench software
when running on the host PC without using the propriatary and not documented network interface dll.

A work around is to use the Suss RS232 interface that is in place to connect to another
client PC. To be able to use the Probe station directly with BASIL on the host PC via RS232 a virtual
comport has to be created connecting the real comport (that is set in the RS232 Interface
application, pbrs232.exe) to a virtual one.
This virtual one is then used to steer the probe station within BASIL.
'''

from basil.dut import Dut

dut = Dut('suss_pa_200.yaml')
dut.init()
print dut['SussProber'].get_position()
print dut['SussProber'].get_die()
