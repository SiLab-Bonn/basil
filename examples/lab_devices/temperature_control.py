#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' This script shows how to read temperature/humidity with Sensition sensors and how to set temperature using a Binder MK 53 climate chamber.
The Sensition sensors are read using the Sensirion EK-H4 multiplexer box from the evaluation kit. A serial TL has to be used
(http://www.sensirion.com/fileadmin/user_upload/customers/sensirion/Dokumente/Humidity/Sensirion_Humidity_EK-H4_Datasheet_V3.pdf).
For the communication with the Binder MK 53 also  a serial TL has to be used (http://www.binder-world.com).
'''

from basil.dut import Dut

# Sensirion sensor readout
dut = Dut('sensirionEKH4_pyserial.yaml')
dut.init()
print dut['Thermohygrometer'].get_temperature()
print dut['Thermohygrometer'].get_humidity()
print dut['Thermohygrometer'].get_dew_point()

# Binder MK 53 control
dut = Dut('binderMK53_pyserial.yaml')
dut.init()
print dut['Climatechamber'].get_temperature()
print dut['Climatechamber'].get_door_open()
print dut['Climatechamber'].get_mode()
temperature_target = dut['Climatechamber'].get_temperature_target()
dut['Climatechamber'].set_temperature(temperature_target)

# Weiss SB 22 control
dut = Dut('WeissSB22_pyserial.yaml')
dut.init()
print dut['Climatechamber'].get_temperature()
print dut['Climatechamber'].get_digital_ch()
temperature_target = dut['Climatechamber'].get_temperature_target()
dut['Climatechamber'].set_temperature(temperature_target)
