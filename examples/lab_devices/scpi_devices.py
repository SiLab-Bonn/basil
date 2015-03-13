#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' Example how to use different laboratory devices (multimeter, pulsers, etc.) that understand SCPI.
    The language (SCPI) is independent of the interface (TCP, RS232, GPIB, USB, etc.). The interfaces
    can be choosen by an appropriate transportation layer (TL). This ca be a VISA TL and
    a Serial TL at the moment. VISA TL is recommendet since it gives you access to almost 
    all laboratory devices (>> 90%) over TCP, RS232, USB, GPIB (Windows only).
    '''

from basil.dut import Dut

# Talk to a Keithley device via serial port using pySerial
dut = Dut('keithley2400_pyserial.yaml')
dut.init()
dut['Multimeter'].reset()
print dut['Multimeter'].get_name()

# Talk to a Keithley device via serial port using VISA with Serial interface
dut = Dut('keithley2400_pyvisa.yaml')
dut.init()
print dut['Multimeter'].get_name()
print dut['Multimeter'].get_voltage()
dut['Multimeter'].off()
dut['Multimeter'].set_voltage(3.14159)
dut['Multimeter'].set_current_limit(.9265)
