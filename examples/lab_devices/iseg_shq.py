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
dut['SHQ'].set_current_channel(1)

# Set voltage ramp speed in V/s
dut['SHQ'].set_ramp_speed(2)

# Set autostart to True in order to automatically start voltage change when new voltage is set
dut['SHQ'].set_autostart(True)

# Set voltage to +-30 volts; requires hardware polarity change
polarity = dut['SHQ'].get_polarity()

dut['SHQ'].set_high_voltage(15 * polarity)  # Set high voltage; hv_on() / hv_off()
dut['SHQ'].set_voltage_limit(20 * polarity)  # Set software-side voltage limit
dut['SHQ'].set_voltage(10 * polarity)  # Set voltage

dut['SHQ'].set_current_trip(10)  # Set current trip in mA
dut['SHQ'].set_current_trip(10000, resolution="muA")  # Set current trip in µA

# Disable autostart
dut['SHQ'].set_autostart(False)

# Read back the voltage that is measured at the output
print(dut['SHQ'].get_voltage())

# Read back the current that is measured at the output
print(dut['SHQ'].get_current())

# Read back the software-side voltage limit
print(dut['SHQ'].get_voltage_limit())

# Read back the hardware-side voltage-limit
print(dut['SHQ'].get_hardware_voltage_limit())

# Read back the voltage that is set to be the output
print(dut['SHQ'].get_source_voltage())

# Read back the current trip (default is mA range)
print(dut['SHQ'].get_current_trip())

# Read back the current trip in mA
print(dut['SHQ'].get_current_trip(resolution="mA"))

# Read back the current trip in µA
print(dut['SHQ'].get_current_trip("muA"))

# Print the module description
print(dut['SHQ'].get_module_description())

# Print the module description
print(dut['SHQ'].get_identifier())
