#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

'''
    This script shows how to read temperature/humidity with Sensirion sensors.
    Some Sensirion sensors are read using the Sensirion EK-H4 multiplexer box from the evaluation kit. A serial TL has to be used
    (http://www.sensirion.com/fileadmin/user_upload/customers/sensirion/Dokumente/Humidity/Sensirion_Humidity_EK-H4_Datasheet_V3.pdf).
    The Sensirion SHT85 sensor is read using the Sensirion Sensor Bridge.
'''


import time
from basil.dut import Dut

# Sensirion EK-H4 sensor readout
dut = Dut('sensirionEKH4_pyserial.yaml')
dut.init()
print(dut['Thermohygrometer'].get_temperature())
print(dut['Thermohygrometer'].get_humidity())
print(dut['Thermohygrometer'].get_dew_point())

# Sensirion SHT85 sensor readout
dut = Dut('sensirionSHT85.yaml')
dut.init()
sensor = dut['Thermohygrometer']
sensor.printInformation()
for action in sensor.enable_heater, sensor.disable_heater:
    action()
    for _ in range(10):
        time.sleep(1)
        print(sensor.get_temperature_and_humidity(), sensor.get_dew_point())
with sensor.asynchronous(measurments_per_second=1) as a:
    for _ in range(10):
        time.sleep(.8)
        T, RH = a.read()
        if T is not None:
            print(T, RH, sensor.to_dew_point(T, RH))
        else:
            print("No data available")
sensor.power_off()
