#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' Example how to use different laboratory devices (Sourcemeter, pulsers, etc.) that understand SCPI.
    The language (SCPI) is independent of the interface (TCP, RS232, GPIB, USB, etc.). The interfaces
    can be choosen by an appropriate transportation layer (TL). This can be a VISA TL and
    a Serial TL at the moment. VISA TL is recommendet since it gives you access to almost
    all laboratory devices (> 90%) over TCP, RS232, USB, GPIB (Windows only so far).
    '''

from basil.dut import Dut

# Talk to a Keithley device via serial port using pySerial
dut = Dut('keithley2410_pyvisa.yaml')
dut.init()
print dut['Sourcemeter'].get_name()