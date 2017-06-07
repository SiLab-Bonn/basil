#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' Example how to use the digital IO of the Arduino board.
'''

import time

from basil.dut import Dut

dut = Dut('arduino.yaml')
dut.init()

time.sleep(1)  # Wait for Arduino to reset

dut['Arduino'].set_output(channel=13, 1)
dut['Arduino'].set_output(channel='ALL', 'OFF')
