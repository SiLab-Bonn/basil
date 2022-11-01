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
dut['SHQ'].ramp_speed = 2

# Set autostart to True in order to automatically start voltage change when new voltage is set
dut['SHQ'].autostart = True

# Set voltage to +-30 volts; requires hardware polarity change
polarity = dut['SHQ'].polarity

dut['SHQ'].high_voltage = 15 * polarity  # Set high voltage; hv_on() / hv_off()
dut['SHQ'].v_lim = 20 * polarity  # Set software-side voltage limit
dut['SHQ'].voltage = 10 * polarity  # Set voltage

# Disable autostart
dut['SHQ'].autostart = False

# Read back the voltage that is measured at the output
print(dut['SHQ'].voltage)

# Read back the software-side voltage limit
print(dut['SHQ'].v_lim)

# Read back the voltage that is set to be the output
print(dut['SHQ'].voltage_target)

# Print the module description
print(dut['SHQ'].module_description)

# Print the module description
print(dut['SHQ'].identifier)
