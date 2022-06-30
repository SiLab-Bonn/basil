#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

''' Example how to use the Arduino as NTC readout.
'''

import time

from basil.dut import Dut

dut = Dut('arduino_ntc_readout.yaml')
dut.init()

time.sleep(2)

print(f"Communication delay after command to Arduino is {dut['NTCReadout'].communication_delay} ms")
dut['NTCReadout'].communication_delay = 5  # Set delay between two commands to 5 milli seconds
print(f"Communication delay after command to Arduino is {dut['NTCReadout'].communication_delay} ms")


print(f"Number of samples to average NTC measurement is {dut['NTCReadout'].n_samples}")
dut['NTCReadout'].n_samples = 10  # Set amount of NTC measurements to average
print(f"Number of samples to average NTC measurement is {dut['NTCReadout'].n_samples}")

for _ in range(10):
    print(dut['NTCReadout'].get_temp(list(range(4))))
