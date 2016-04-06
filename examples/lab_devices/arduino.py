#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' Example how to use the digital IO of the Arduino board.
'''

from basil.dut import Dut

dut = Dut('arduino.yaml')
dut.init()
dut['Arduino'].set_output(channel=0, 1)
dut['Arduino'].set_output(channel=0, 'OFF')

