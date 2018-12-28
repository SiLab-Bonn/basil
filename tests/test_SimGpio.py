#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest
import os

from basil.dut import Dut
from basil.utils.sim.utils import cocotb_compile_and_run, cocotb_compile_clean


cnfg_yaml = """
transfer_layer:
  - name  : INTF
    type  : SiSim
    init:
        host : localhost
        port  : 12345

hw_drivers:
  - name      : GPIO
    type      : gpio
    interface : INTF
    base_addr : 0x0000
    size      : 24
    
  - name      : GPIO2
    type      : gpio
    interface : INTF
    base_addr : 0x0010
    size      : 16
    
registers:
  - name        : GPIO
    type        : StdRegister
    hw_driver   : GPIO
    size        : 24
    fields:
      - name    : OUT
        size    : 8
        offset  : 7
      - name    : IN
        size    : 8
        offset  : 15
      - name    : TRI_IN
        size    : 4
        offset  : 19
      - name    : TRI_OUT
        size    : 4
        offset  : 23
"""


class TestSimGpio(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), 'test_SimGpio.v')])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    def test_io(self):
        self.chip['GPIO'].set_output_en([0xff, 0, 0])  # to remove 'z in simulation

        ret = self.chip['GPIO'].get_data()
        self.assertEqual([0, 0, 0], ret)

        self.chip['GPIO'].set_output_en([0x0f, 0, 0])
        self.chip['GPIO'].set_data([0xe3, 0xfa, 0x5a])
        ret = self.chip['GPIO'].get_data()
        self.assertEqual([0x33, 0x5a, 0x5a], ret)
        ret = self.chip['GPIO2'].get_data()
        self.assertEqual([0xa5, 0xcd], ret)

    def test_io_register(self):

        self.chip['GPIO'].set_output_en([0xff, 0, 0])  # to remove 'z in simulation

        self.chip['GPIO']['OUT'] = 0xa5

        self.chip['GPIO'].write()
        ret = self.chip['GPIO'].get_data()
        self.assertEqual([0, 0xa5, 0xa5], ret)
        # TODO: Add register readback and comparison

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()

if __name__ == '__main__':
    unittest.main()
