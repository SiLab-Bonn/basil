======================================
Arduino Firmware for NTC Readout
======================================

Arduino Nano firmware to read out NTCs via the 8 analog input pins A0 to A7 and the internal (multiplexed) ADC.
The REF and 3V3 need to be connected on the Arduino.
Each input requires a voltage divider configuration, supplied with the 3.3 V Arduino rail.
The voltage drop over the NTC is the input to the analog pin.
The conversion from ADC value to degree Celsius takes place in the firmware.
