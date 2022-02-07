import unittest
import yaml
import os
from basil.dut import Dut

k2410def_yaml = os.path.join(os.path.dirname(__file__), "formatting.yaml")

cnfg_yaml = f'''
transfer_layer:
  - name     : Visa
    type     : Visa
    init     :
        resource_name : ASRL1::INSTR
        read_termination : "\\n"
        write_termination : "\\r\\n"
        backend : "{k2410def_yaml}@sim"

hw_drivers:
  - name      : Sourcemeter
    type      : scpi
    interface : Visa
    init      :
        device : Keithley 2410
'''


class TestSimScpi(unittest.TestCase):

    def setUp(self):
        self.cfg = yaml.safe_load(cnfg_yaml)
        self.device = Dut(self.cfg)
        self.device.init()

    def tearDown(self):
        self.device.close()

    def test_read_voltage(self):
        voltage = self.device['Sourcemeter'].get_voltage().split(',')[0]
        self.assertEqual(voltage, '-5.124E-05')

    def test_read_voltage_formatted(self):
        # Check that formatting is present
        self.assertTrue(self.device['Sourcemeter'].has_formatting)
        # Enable formatting
        self.device['Sourcemeter'].enable_formatting()
        voltage = self.device['Sourcemeter'].get_voltage()
        # Disable formatting
        self.device['Sourcemeter'].disable_formatting()
        self.assertEqual(voltage, '-5.124E-05')
    

if __name__ == '__main__':
    unittest.main()
