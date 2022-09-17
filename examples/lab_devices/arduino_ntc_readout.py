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

print(f"Beta coefficient is {dut['NTCReadout'].beta_coefficient} Kelvin")
dut['NTCReadout'].beta_coefficient = 3450  # Set beta in K
print(f"Beta coefficient is {dut['NTCReadout'].beta_coefficient} Kelvin")

print(f"Nominal NTC resistance is {dut['NTCReadout'].nominal_resistance} Ohm")
dut['NTCReadout'].nominal_resistance = 20e3  # Set nom. res. in Ohm
print(f"Nominal NTC resistance is {dut['NTCReadout'].nominal_resistance} Ohm")

print(f"Nominal NTC temperature is {dut['NTCReadout'].nominal_temperature} °C")
dut['NTCReadout'].nominal_temperature = 30  # Set nom. res. in Ohm
print(f"Nominal NTC temperature is {dut['NTCReadout'].nominal_temperature} °C")

print(f"Resistor value is {dut['NTCReadout'].resistance} Ohm")
dut['NTCReadout'].resistance = 15e3  # Set res. in Ohm
print(f"Resistor value is {dut['NTCReadout'].resistance} Ohm")

print("Restore defaults")
dut['NTCReadout'].restore_defaults()

print(f"Communication delay after command to Arduino is {dut['NTCReadout'].communication_delay} ms")
print(f"Number of samples to average NTC measurement is {dut['NTCReadout'].n_samples}")
print(f"Beta coefficient is {dut['NTCReadout'].beta_coefficient} Kelvin")
print(f"Nominal NTC resistance is {dut['NTCReadout'].nominal_resistance} Ohm")
print(f"Nominal NTC temperature is {dut['NTCReadout'].nominal_temperature} °C")
print(f"Resistor value is {dut['NTCReadout'].resistance} Ohm")

# Read temperature in degree C and resistanc ein Ohm for the first 4 inputs
print(dut['NTCReadout'].get_temp(list(range(4))))
print(dut['NTCReadout'].get_res(list(range(4))))

print(f"Voltage is measured over NTC in divider config: {dut['NTCReadout'].measure_v_drop_over_ntc}")
print(f"Resistance is: {dut['NTCReadout'].get_res(1)}")
dut['NTCReadout'].measure_v_drop_over_ntc = True
print(f"Voltage is measured over NTC in divider config: {dut['NTCReadout'].measure_v_drop_over_ntc}")
print(f"Resistance is: {dut['NTCReadout'].get_res(1)}")
