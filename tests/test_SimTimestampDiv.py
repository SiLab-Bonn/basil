#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest
import os
import time

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

  - name      : timestamp_div
    type      : timestamp_div
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


class TestSimTimestampDiv(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), 'test_SimTimestampDiv.v')])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    def test_io(self):
        self.chip['timestamp_div'].reset()
        self.chip['timestamp_div']["ENABLE"] = 1
        self.chip['gpio'].reset()

        self.chip['fifo'].reset()
        ret = self.chip['fifo'].get_fifo_size()
        self.assertEqual(ret, 0)

        # trigger timestamp
        repeat = 16
        width = 0x18
        self.chip['PULSE_GEN'].set_delay(0x20 + 0x7)
        self.chip['PULSE_GEN'].set_width(width)
        self.chip['PULSE_GEN'].set_repeat(repeat)

        self.chip['PULSE_GEN'].start()
        while(not self.chip['PULSE_GEN'].is_done()):
            pass

        # get data from fifo
        ret = self.chip['fifo'].get_fifo_size()
        self.assertEqual(ret, 3 * 4 * repeat)

        ret = self.chip['fifo'].get_data()
        self.assertEqual(len(ret), 3 * repeat)
        for i, r in enumerate(ret):
            self.assertEqual(r & 0xF0000000, 0x50000000)
            self.assertEqual(r & 0xF000000, 0x1000000 * (3 - i % 3))

        self.chip['timestamp_div']["ENABLE_TOT"] = 1
        self.chip['PULSE_GEN'].start()
        while(not self.chip['PULSE_GEN'].is_done()):
            pass

        ret = self.chip['fifo'].get_fifo_size()
        self.assertEqual(ret, 3 * 4 * repeat)

        ret = self.chip['fifo'].get_data()
        self.assertEqual(len(ret), 3 * repeat)
        for i, r in enumerate(ret):
            self.assertEqual(r & 0xF0000000, 0x50000000)
            self.assertEqual(r & 0xF000000, 0x1000000 * (3 - i % 3))
            if i % 3 == 0:
                self.assertEqual(r & 0xFFFF00, 0x100 * width)  # ToT value

    def tearDown(self):
        time.sleep(2)
        self.chip.close()  # let it close connection and stop simulator
        time.sleep(2)
        cocotb_compile_clean()
        time.sleep(2)


if __name__ == '__main__':
    unittest.main()
