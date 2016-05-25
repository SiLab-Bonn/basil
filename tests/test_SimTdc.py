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
  - name      : SEQ_GEN
    type      : seq_gen
    interface : intf
    mem_size  : 65535
    base_addr : 0x0000

  - name      : TDC
    type      : tdc_s3
    interface : intf
    base_addr : 0x8000

  - name      : SRAM
    type      : sram_fifo
    interface : intf
    base_addr : 0x8100
    base_data_addr : 0x80000000

registers:
  - name        : SEQ
    type        : TrackRegister
    hw_driver   : SEQ_GEN
    seq_width   : 8
    seq_size    : 65535
    tracks  :
      - name     : TDC_TRIGGER_IN
        position : 0
      - name     : TDC_IN
        position : 1
      - name     : TDC_ARM
        position : 2
      - name     : TDC_EXT_EN
        position : 3
      - name     : S4
        position : 4
      - name     : S5
        position : 5
      - name     : S6
        position : 6
      - name     : S7
        position : 7
"""


class TestSimTlu(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), 'test_SimTdc.v')])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    def test_tdc(self):
        self.chip['TDC'].ENABLE = 1
        self.chip['SEQ'].REPEAT = 1

        for index, i in enumerate(range(0, 10)):
            length = i + 1
            self.chip['SEQ'].SIZE = length + 1
            self.chip['SEQ']['TDC_IN'][0:length] = True
            self.chip['SEQ'].write(length)
            self.chip['SEQ'].START
            while(not self.chip['SEQ'].is_done()):
                pass
            self.assertEqual(self.chip['SRAM'].get_fifo_int_size(), 1)

            data = self.chip['SRAM'].get_data()
            self.assertEqual(data[0], (index << 12) + length)

    def test_tdc_overflow(self):
        self.chip['TDC'].ENABLE = 1
        self.chip['SEQ'].REPEAT = 1

        for index, i in enumerate(range(4094, 4097)):
            length = i + 1
            self.chip['SEQ_GEN'].SIZE = length + 1
            self.chip['SEQ']['TDC_IN'][0:length] = True
            self.chip['SEQ'].write(length)
            self.chip['SEQ'].START
            while(not self.chip['SEQ_GEN'].is_done()):
                pass
            self.assertEqual(self.chip['SRAM'].get_fifo_int_size(), 1)

            data = self.chip['SRAM'].get_data()
            self.assertEqual(data[0], (index << 12) + min(length, 4095))  # overflow 12bit

#     def test_tdc_delay(self):
#         pass
#
#     def test_tdc_delay_overflow(self):
#         pass
#
#     def test_tdc_delay_late_trigger(self):
#         pass
#
#     def test_tdc_arm(self):
#         pass

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()

if __name__ == '__main__':
    unittest.main()
