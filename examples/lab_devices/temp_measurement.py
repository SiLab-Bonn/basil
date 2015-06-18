#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' Sensition sensors are read using the Sensirion EK-H4 multiplexer box from the evaluation kit. A serial TL has to be used.
(http://www.sensirion.com/fileadmin/user_upload/customers/sensirion/Dokumente/Humidity/Sensirion_Humidity_EK-H4_Datasheet_V3.pdf)
'''

from basil.dut import Dut

dut = Dut('sensirionEKH4_pyserial.yaml')
dut.init()

print dut['Thermohygrometer'].get_temperature()
print dut['Thermohygrometer'].get_humidity()
print dut['Thermohygrometer'].get_dew_point()
