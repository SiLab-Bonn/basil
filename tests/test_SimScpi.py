#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest
import yaml

from basil.dut import Dut

cnfg_yaml = r"""
transfer_layer:
  - name     : Visa
    type     : Visa
    init     :
        resource_name : ASRL1::INSTR
        read_termination : "\n"
        write_termination : "\r\n"
        backend : "@sim"

hw_drivers:
  - name      : Pulser
    type      : scpi
    interface : Visa
    init      :
        device : scpi sim device
"""


class TestSimScpi(unittest.TestCase):

    def setUp(self):
        self.cfg = yaml.load(cnfg_yaml)

    def test_read(self):
        device = Dut(self.cfg)
        device.init()
        self.assertEqual(device['Pulser'].get_frequency(), u'100.00')
        device.close()
 
    def test_write(self):
        device = Dut(self.cfg)
        device.init()
        device['Pulser'].set_on(1)
        self.assertEqual(device['Pulser'].get_on(), u'OK')
        device.close()

    def test_invalid_parameter(self):
        device = Dut(self.cfg)
        device.init()
        with self.assertRaises(ValueError):
            device['Pulser'].set_on(1, 2)
        device.close()
 
    def test_exception(self):
        device = Dut(self.cfg)
        device.init()
        with self.assertRaises(ValueError):
            device['Pulser'].unknown_function()
        device.close()

if __name__ == '__main__':
    unittest.main()
