#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' This script shows how to use a Motor Stage
'''

import time
from basil.dut import Dut

dut = Dut('mercury_pyserial.yaml')
dut.init()

# setup (for c-862)
# needed if mercury is connected the first time after power up
# MN Motor=on
# LL: switch logic active low (hardware)

dut["MotorStage"].motor_on(address=1)
time.sleep(0.1)
dut["MotorStage"].LL(address=1)
time.sleep(0.1)

# move to absolute position 10000:
# dut["MotorStage"].set_position(10000, address=1)

# get position:
# print(dut["MotorStage"].get_position(address=1))

# move relative 10000:
dut["MotorStage"].move_relative(10000, address=1, wait=False)

# finding edge example:
# dut["MotorStage"].find_edge(1,address=1)  # 0 or 1 indicates direction of movement

# abort any movement abruptly:
# dut["MotorStage"].abort(address=1)
