======================================
Arduino Firmware for Environment Readout (temperature, humidity/pressure)
======================================

Arduino Nano firmware to read out NTCs via the 8 analog input pins A0 to A7 and the internal (multiplexed) ADC.

NTC inputs require a voltage divider configuration, supplied with the 3.3 V Arduino rail.The voltage drop over the NTC is the input to the analog pin.
The conversion from ADC value to degree Celsius can take place in the firmware.

Additionally, a pure analog read out is possible for processing of humidity and pressure sensors.
