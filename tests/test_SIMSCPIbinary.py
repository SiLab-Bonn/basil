import os
import unittest

import yaml
import numpy as np

from basil.dut import Dut
import visa_SmuSim

k2602def_yaml = os.path.join(os.path.dirname(__file__), 'test_keithley_binary.yaml')

# noinspection compatibility
cnfg_yaml = f'''
transfer_layer:
  - name    :   Visa
    type    :   Visa
    init    :
        resource_name   :   ASRL1::INSTR
        read_termination:   "\\n"
        write_termination:  "\\n"
        backend         :   "{k2602def_yaml}@sim"
hw_driver:
  - name    :   Sourcemeter
    type    :   scpi
    interface:  Visa
    init    :
        device  :   Keithley 2410
        enable_formatting:  true
'''


expected_test_result = [
    7.50743183e-08,
    7.48907354e-08,
    7.51024487e-08,
    7.52273763e-08,
    7.50416547e-08,
    7.52534888e-08,
    7.51035216e-08,
    7.51142508e-08,
    7.50377183e-08,
    7.50383151e-08,
    7.52236815e-08,
    7.51461968e-08,
    7.48099112e-08,
    7.52440670e-08,
    7.48978835e-08,
    7.52257137e-08,
    7.52558691e-08,
    7.50827809e-08,
    7.47307567e-08,
    7.54547145e-08,
    7.50775371e-08,
    7.50997060e-08,
    7.49254241e-08,
    7.50603704e-08,
    7.51198499e-08,
    7.51688489e-08,
    7.49996900e-08,
    7.52538440e-08,
    7.50843299e-08,
    7.52863869e-08,
    7.51728990e-08,
    7.50796758e-08,
    7.51795781e-08,
    7.49799014e-08,
    7.50695435e-08,
    7.52655254e-08,
    7.50175744e-08,
    7.51024487e-08,
    7.48423332e-08,
    7.50621538e-08
]

n = 10

# will only simulate the case that binary readout is enabled!
# no test for switching it off dynamically as the simulation framework pyvisa does not allow for such complex requests.
# but first of all I will need the output of the SMU as it is to be expected!
class TestSimScpiBinary(unittest.TestCase):
    def setUp(self):
        self.cfg = yaml.safe_load(cnfg_yaml)
        self.device = Dut(self.cfg)
        self.device.init()

        # Check that formatting is present
        self.assertTrue(self.device["Sourcemeter"].has_formatting)

        # Check that formatting is enabled after init
        self.assertTrue(self.device["Sourcemeter"].formatting_enabled)

    def tearDown(self):
        self.device.close()

    def test_read_voltage(self):
        voltage = self.device["Sourcemeter"].get_voltage()
        self.assertEqual(voltage, "-5124E-05")

    def test_read_voltage_unformatted(self):
        # Check that formatting is enabled
        self.assertTrue(self.device["Sourcemeter"].formatting_enabled)

        # Disable formatting
        self.device["Sourcemeter"].disable_formatting()
        voltage = self.device["Sourcemeter"].get_voltage().split(",")[0]
        self.assertEqual(voltage, "-5.124E-05")

        # Check that formatting is disabled
        self.assertFalse(self.device["Sourcemeter"].formatting_enabled)

        # Enable formatting
        self.device["Sourcemeter"].enable_formatting()

    def test_read_voltage_binary(self):
        # Check that binary is enabled
        self.assertTrue(self.device["Sourcemeter"].has_binary_command)
        self.assertTrue(self.device["Sourcemeter"].binary_query_enabled)

        # set the device to binary
        self.device["Sourcemeter"].binary_format()

        voltages = self.device["Sourcemeter"].get_multi_current(channel=1, binary_enabled=True)
        if voltages.shape[0] > n:
            offset = int(voltages.shape[0] % n)
            shift = int(voltages.shape[0] // n)
            voltages = voltages[offset::shift]
        self.assertTrue(np.allclose(voltages, expected_test_result))

    def test_measure_voltage_binary(self):
        # Check that binary is enabled
        self.assertTrue(self.device["Sourcemeter"].has_binary_command)
        self.assertTrue(self.device["Sourcemeter"].binary_query_enabled)

        # set the device to binary
        self.device["Sourcemeter"].binary_format()

        voltages = self.device["Sourcemeter"].get_advanced_current(channel=2, binary_enabled=True)
        if voltages.shape[0] > n:
            offset = int(voltages.shape[0] % n)
            shift = int(voltages.shape[0] // n)
            voltages = voltages[offset::shift]
        self.assertTrue(np.allclose(voltages, expected_test_result))

    def test_read_voltage_ascii(self):
        # Check that binary is enabled
        self.assertTrue(self.device["Sourcemeter"].has_binary_command)
        self.device["Sourcemeter"].disable_binary_query()
        self.assertFalse(self.device["Sourcemeter"].binary_query_enabled)

        # set the device to binary
        self.device["Sourcemeter"].text_format()

        voltages = self.device["Sourcemeter"].get_multi_current(channel=1)
        voltages = np.array(voltages.split(','), dtype=np.float64)
        self.assertTrue(np.allclose(voltages, expected_test_result))

    def test_measure_voltage_ascii(self):
        # Check that binary is enabled
        self.assertTrue(self.device["Sourcemeter"].has_binary_command)
        self.assertTrue(self.device["Sourcemeter"].binary_query_enabled)

        # set the device to binary
        self.device["Sourcemeter"].text_format()

        voltages = self.device["Sourcemeter"].get_advanced_current(channel=2)
        voltages = np.array(voltages.split(','), dtype=np.float64)
        self.assertTrue(np.allclose(voltages, expected_test_result))


if __name__ == '__main__':
    unittest.main()
