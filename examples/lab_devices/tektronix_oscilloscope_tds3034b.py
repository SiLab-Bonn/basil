#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# INFO: You might be able to ping the oscilloscope at the displayed IP. This does for some reason not
# mean, that you will be able to run this script without errors like:
# pyvisa.errors.VisaIOError: VI_ERROR_RSRC_NFOUND (-1073807343): Insufficient location information or the requested device or resource is not present in the system.
#
# If such an error occures, reboot the oscilloscope
#

from basil.dut import Dut
import numpy as np
import matplotlib.pyplot as plt

dut = Dut('tektronix_tds_3034b.yaml')
dut.init()

# Control settings of the oscilloscope
dut['Oscilloscope'].set_vertical_scale('5.0E-2', channel=1)
dut['Oscilloscope'].set_vertical_position('0', channel=1)
dut['Oscilloscope'].set_vertical_offset('0.0E0', channel=1)
dut['Oscilloscope'].set_trigger_source(channel=1)
dut['Oscilloscope'].set_trigger_level(1e-2)
dut['Oscilloscope'].set_trigger_mode('AUTO')

# Taking a measurement
meas_waveform = dut['Oscilloscope'].get_waveform(channel=1)
CH_id = meas_waveform[0]
CH_data = meas_waveform[1]
CH_xscale = meas_waveform[2]
CH_yscale = meas_waveform[3]
CH_time = np.linspace(0, CH_xscale[0] * len(CH_data), len(CH_data))

# Plot the data
plt.figure(figsize=(16, 9))
plt.scatter(CH_time, CH_data, label='CH' + str(CH_id))
plt.ylim(-4 * CH_yscale[0], 4 * CH_yscale[0])
plt.xlabel('Time $t$ / s')
plt.ylabel('Voltage U / V')
plt.grid()
plt.legend()
plt.show()
