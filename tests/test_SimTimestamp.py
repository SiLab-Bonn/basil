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
  - name      : gpio
    type      : gpio
    interface : intf
    base_addr : 0x0000
    size      : 64

  - name      : timestamp
    type      : timestamp
    interface : intf
    base_addr : 0x1000


  - name      : PULSE_GEN
    type      : pulse_gen
    interface : intf
    base_addr : 0x3000

  - name      : fifo
    type      : sram_fifo
    interface : intf
    base_addr : 0x8000
    base_data_addr: 0x80000000

registers:
  - name        : timestamp_value
    type        : StdRegister
    hw_driver   : gpio
    size        : 64
    fields:
      - name    : OUT3
        size    : 16
        offset  : 63
      - name    : OUT2
        size    : 24
        offset  : 47
      - name    : OUT1
        size    : 24
        offset  : 23
"""


class TestSimTimestamp(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), 'test_SimTimestamp.v')])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    def test_io(self):
        self.chip['timestamp'].reset()
        self.chip['timestamp']["ENABLE"] = 1
        self.chip['gpio'].reset()

        self.chip['fifo'].reset()
        ret = self.chip['fifo'].get_fifo_size()
        self.assertEqual(ret, 0)

        # trigger timestamp
        self.chip['PULSE_GEN'].set_delay(0x105)
        self.chip['PULSE_GEN'].set_width(10)
        self.chip['PULSE_GEN'].set_repeat(1)
        self.assertEqual(self.chip['PULSE_GEN'].get_delay(), 0x105)
        self.assertEqual(self.chip['PULSE_GEN'].get_width(), 10)
        self.assertEqual(self.chip['PULSE_GEN'].get_repeat(), 1)

        self.chip['PULSE_GEN'].start()
        while not self.chip['PULSE_GEN'].is_done():
            pass

        # get data from fifo
        ret = self.chip['fifo'].get_fifo_size()
        self.assertEqual(ret, 3 * 4)

        ret = self.chip['fifo'].get_data()
        self.assertEqual(len(ret), 3)

        # check with gpio
        ret2 = self.chip['gpio'].get_data()
        self.assertEqual(len(ret2), 8)

        for i, r in enumerate(ret):
            self.assertEqual(r & 0xF0000000, 0x50000000)
            self.assertEqual(r & 0xF000000, 0x1000000 * (3 - i))

        self.assertEqual(ret[2] & 0xFFFFFF, 0x10000 *
                         ret2[5] + 0x100 * ret2[6] + ret2[7])
        self.assertEqual(ret[1] & 0xFFFFFF, 0x10000 *
                         ret2[2] + 0x100 * ret2[3] + ret2[4])
        self.assertEqual(ret[1] & 0xFFFFFF, 0x100 * ret2[0] + ret2[1])

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()


if __name__ == '__main__':
    unittest.main()
