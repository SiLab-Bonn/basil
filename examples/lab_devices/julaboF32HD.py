#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' Example how to use the tiller.
'''

import time

from basil.dut import Dut

dut = Dut('julaboF32HD.yaml')
dev.init()
print "ID",dev["tiller"].get_identifier()
print "status",dev["tiller"].get_status()

### start
### set menu->confiuration->setpoint->rs232 
dev["tiller"].start_thermostat()
dev["tiller"].get_status()

