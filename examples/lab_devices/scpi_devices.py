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
dut = Dut('keithley2400_pyserial.yaml')
dut.init()
print dut['Sourcemeter'].get_name()

# Talk to a Keithley device via serial port using VISA with Serial interface
dut = Dut('keithley2400_pyvisa.yaml')
dut.init()
print dut['Sourcemeter'].get_name()
# Some additional implemented methods for this device
print dut['Sourcemeter'].get_voltage()
dut['Sourcemeter'].off()
dut['Sourcemeter'].set_voltage(3.14159)
dut['Sourcemeter'].set_current_limit(.9265)

# Example of a SCPI device implementing more specialized functions (e.g. unit conversion) via extra class definitions
dut = Dut('agilent33250a_pyserial.yaml')
dut.init()
print dut['Pulser'].get_info()
# Some additional implemented methods for this device
dut['Pulser'].set_voltage(0., 1., unit='V')
print dut['Pulser'].get_voltage(0, unit='mV'), 'mV'

# Example for device with multiple channels
dut = Dut('ttiql335tp_pyvisa.yaml')
dut.init()
dut['PowerSupply'].get_name()
dut['PowerSupply'].get_voltage(channel=1)

# Talk to a Keithley device via GPIB using NI VISA
dut = Dut('keithley2000_pyvisa.yaml')
dut.init()
print dut['Multimeter'].get_name()

# Talk to a Tektronix mixed signal oscilloscope via TCPIP, USB
dut = Dut('tektronixMSO4104B_pyvisa.yaml')
dut.init()
print dut['Oscilloscope'].get_name()
print dut['Oscilloscope'].get_data(channel=1)
