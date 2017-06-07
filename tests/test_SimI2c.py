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
  - name  : intf
    type  : SiSim
    init:
        host : localhost
        port  : 12345

hw_drivers:

  - name      : i2c
    type      : i2c
    interface : intf
    base_addr : 0x1000

registers:

  - name        : CONTROL
    type        : StdRegister
    hw_driver   : i2c
    size        : 8
    fields:
      - name    : OUT
        size    : 8
        offset  : 7
"""


class TestSimS2C(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), 'test_SimI2c.v')])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    def test_i2c(self):
        data = [0x85, 0x81, 0xa5, 0x91]
        self.chip['i2c'].write(0x92, data)

        ret = self.chip['i2c'].get_data(4)
        self.assertEqual(ret.tolist(), data)

        self.chip['i2c'].write(0x92, data[0:1])

        self.chip['i2c'].set_data([0, 1, 2, 3])

        ret = self.chip['i2c'].read(0x92, 3)
        self.assertEqual(ret.tolist(), data[1:])

        self.chip['i2c'].write(0x92, range(16))
        self.chip['i2c'].write(0x92, [0])
        ret = self.chip['i2c'].read(0x92, 15)
        self.assertEqual(ret.tolist(), range(16)[1:])

        # no ack/no such device
        exept = False
        try:
            self.chip['i2c'].write(0x55, data)
        except IOError:
            exept = True

        self.assertEqual(exept, True)

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()

if __name__ == '__main__':
    unittest.main()
