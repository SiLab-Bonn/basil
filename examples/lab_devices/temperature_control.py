#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

'''
    This script shows how to set temperature using a Binder MK 53 climate chamber.
    For the communication with the Binder MK 53 also  a serial TL has to be used (http://www.binder-world.com).
    The newer Weiss Labevent climatechamber uses a direct TCP/IP connection.
'''


from basil.dut import Dut

# Binder MK 53 control
dut = Dut('binderMK53_pyserial.yaml')
dut.init()
print(dut['Climatechamber'].get_temperature())
print(dut['Climatechamber'].get_door_open())
print(dut['Climatechamber'].get_mode())
temperature_target = dut['Climatechamber'].get_temperature_target()
dut['Climatechamber'].set_temperature(temperature_target)

# New Weiss Labevent control
dut = Dut('WeissLabEvent_socket.yaml')
dut.init()
dut['Climatechamber'].start_manual_mode()
dut['Climatechamber'].set_temperature(20)
dut['Climatechamber'].set_air_dryer(True)   # Make sure the air dryer is turned on
print(dut['Climatechamber'].get_temperature())
