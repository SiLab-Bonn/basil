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

dut = Dut('arduino_relay_board.yaml')
dut.init()

time.sleep(2)  # Wait for Arduino to reset

dut['RelayBoard'].set_output(channel=13, value=1)
dut['RelayBoard'].set_output(channel='ALL', value='OFF')
