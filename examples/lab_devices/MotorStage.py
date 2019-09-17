#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' This script shows how to use a Motor Stage
'''


from basil.dut import Dut

dut = Dut('mercury_pyserial.yaml')
dut.init()
print(dut["MotorStage"].get_position())
# dut["MotorStage"].set_position(100000)
