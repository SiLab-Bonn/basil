======================================
Arduino Firmware for I2C over Serial
======================================

Arduino Nano firmware to write and read an I2C bus over the Arduinos serial interface.
The lines reqired by I2C are GND, VCC(3v3 or 5V), SDA (A4) and SCL (A5).
The firmware receives read/write commands over serial, accesses the I2C bus and answers the
results over serial.
