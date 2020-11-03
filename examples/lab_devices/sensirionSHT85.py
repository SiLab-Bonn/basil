#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.dut import Dut

import time

dut = Dut('examples/lab_devices/sensirionSHT85.yaml')
dut.init()
dut['Thermohygrometer'].printInformation()
print(dut['Thermohygrometer'].get_temperature_and_humidity())
print(dut['Thermohygrometer'].get_dew_point())
dut['Thermohygrometer'].enable_heater()
for _ in range(10):
    time.sleep(.5)
    print(dut['Thermohygrometer'].get_temperature_and_humidity())
    print(dut['Thermohygrometer'].get_dew_point())
dut['Thermohygrometer'].disable_heater()
for _ in range(10):
    time.sleep(.5)
    print(dut['Thermohygrometer'].get_temperature_and_humidity())
    print(dut['Thermohygrometer'].get_dew_point())

with dut['Thermohygrometer'].asynchronous(1) as a:
    for _ in range(10):
        time.sleep(.8)
        print(a.read())

dut['Thermohygrometer'].power_off()
