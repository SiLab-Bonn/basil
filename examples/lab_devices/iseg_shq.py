#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' Example how to use the Arduino as NTC readout.
'''

from basil.dut import Dut

dut = Dut('iseg_shq.yaml')
dut.init()

# Set PSU channel
dut['SHQ'].channel = 1

# Set voltage ramp speed in V/s
dut['SHQ'].ramp_speed = 10

# Set autostart to True in order to automatically start voltage change when new voltage is set
dut['SHQ'].autostart = True

# Set voltage to 30 volts
dut['SHQ'].voltage = 30

# Read back the voltage that is measured at the output
print(dut['SHQ'].voltage)

# Read back the voltage that is set to be the output
print(dut['SHQ'].voltage_target)

# Print the module description
print(dut['SHQ'].module_description)

# Print the module description
print(dut['SHQ'].identifier)
