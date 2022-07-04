#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' Example how to use the SerialToI2C Arduino interface.
'''

import time

from basil.dut import Dut

dut = Dut('arduino_serial_to_i2c.yaml')
dut.init()

time.sleep(2)  # Allow tranfer layer to initialize / arduino to boot

print(f"Communication delay after command to Arduino is {dut['SerialToI2C'].communication_delay} ms")
dut['SerialToI2C'].communication_delay = 5  # Set delay between two commands to 5 milli seconds
print(f"Communication delay after command to Arduino is {dut['SerialToI2C'].communication_delay} ms")

print(f"I2C bus address to write to is {dut['SerialToI2C'].i2c_address}")
dut['SerialToI2C'].i2c_address = 0x20  # Set I2C address
print(f"I2C bus address to write to is {dut['SerialToI2C'].i2c_address}")

dut['SerialToI2C'].check_i2c_connection()  # Check if connection is established on I2C bus with given address
dut['SerialToI2C'].read_register(reg=0x00)  # Read register 0x00 at adress dut['SerialToI2C'].i2c_address
dut['SerialToI2C'].write_register(reg=0x00, data=0x00)  # Write 0 to register 0x00 at adress dut['SerialToI2C'].i2c_address
