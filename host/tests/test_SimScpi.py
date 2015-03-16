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
        cfg = yaml.load(cnfg_yaml)
        self.device = Dut(cfg)
        self.device.init()

    def test_read(self):
        self.assertEqual(self.device['Pulser'].get_frequency(), u'100.00')

    def test_write(self):
        self.device['Pulser'].set_on()
        self.assertEqual(self.device['Pulser'].get_on(), u'0')

    def test_exception(self):
        with self.assertRaises(ValueError):
            self.device['Pulser'].unknown_function()

    def tearDown(self):
        self.device.close()

if __name__ == '__main__':
    unittest.main()
