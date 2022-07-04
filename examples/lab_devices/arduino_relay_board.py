#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' Example how to use the digital IO of the Arduino board.
'''

import time

from basil.dut import Dut

dut = Dut('arduino_relay_board.yaml')
dut.init()

time.sleep(2)  # Wait for Arduino to reset

print(f"Communication delay after command to Arduino is {dut['RelayBoard'].communication_delay} ms")
dut['RelayBoard'].communication_delay = 5  # Set delay between two commands to 5 milli seconds
print(f"Communication delay after command to Arduino is {dut['RelayBoard'].communication_delay} ms")

print(f"State of RelayBoard is: {dut['RelayBoard'].get_state()}")

for i in range(2, 12):
    print(f"Switching on channel {i}")
    dut['RelayBoard'].set_output(channel=i, value='ON')
    print(f"State of RelayBoard is: {dut['RelayBoard'].get_state()}")

print("Switching off all channels")
dut['RelayBoard'].set_output(channel='ALL', value='OFF')
print(f"State of RelayBoard is: {dut['RelayBoard'].get_state()}")
