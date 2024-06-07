#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' This script shows how to use EFLOW
'''

from basil.dut import Dut

dut = Dut('bronkhorstELFLOW_pyserial.yaml')
dut.init()

# setting set point
dut["hot_n2"].set_mode(0)
dut["hot_n2"].set_setpoint(10000)
dut["hot_n2"].set_mode(0)
print("setpoint", dut["hot_n2"].get_setpoint())

# controlling valve
dut["hot_n2"].set_mode(20)

# measuring flow rate
# print("Flow",dut["hot_n2"].get_flow())

# Measuring of valve opening in %
valve = dut["hot_n2"].get_valve_output()
print("Valve opened in %", valve)
