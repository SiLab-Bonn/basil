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
  - name      : SEQ_GEN
    type      : seq_gen
    interface : INTF
    base_addr : 0x0000

  - name      : TDC0
    type      : tdc_s3
    interface : INTF
    base_addr : 0x8000

  - name      : TDC1
    type      : tdc_s3
    interface : INTF
    base_addr : 0x8100

  - name      : TDC2
    type      : tdc_s3
    interface : INTF
    base_addr : 0x8200

  - name      : FIFO0
    type      : bram_fifo
    interface : INTF
    base_addr : 0x8300
    base_data_addr : 0x60000000

  - name      : FIFO1
    type      : bram_fifo
    interface : INTF
    base_addr : 0x8400
    base_data_addr : 0x70000000

  - name      : FIFO2
    type      : bram_fifo
    interface : INTF
    base_addr : 0x8500
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


class TestSimTdc(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), 'test_SimTdc.v')])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    def test_tdc(self):
        self.chip['TDC0'].ENABLE = 1
        self.chip['SEQ'].REPEAT = 1

        for index, i in enumerate(range(0, 10)):
            length = i + 1
            self.chip['SEQ'].SIZE = length + 1
            self.chip['SEQ']['TDC_IN'][0:length] = True
            self.chip['SEQ'].write(length)
            self.chip['SEQ'].START
            while not self.chip['SEQ'].is_ready:
                pass
            self.assertEqual(self.chip['FIFO0'].get_FIFO_INT_SIZE(), 1)

            data = self.chip['FIFO0'].get_data()
            self.assertEqual(data[0], (index << 12) + length)

    def test_tdc_overflow(self):
        self.chip['TDC0'].ENABLE = 1
        self.chip['SEQ'].REPEAT = 1

        for index, i in enumerate(range(4094, 4097)):
            length = i + 1
            self.chip['SEQ_GEN'].SIZE = length + 1
            self.chip['SEQ']['TDC_IN'][0:length] = True
            self.chip['SEQ'].write(length)
            self.chip['SEQ'].START
            while not self.chip['SEQ_GEN'].is_ready:
                pass
            self.assertEqual(self.chip['FIFO0'].get_FIFO_INT_SIZE(), 1)

            data = self.chip['FIFO0'].get_data()
            self.assertEqual(data[0], (index << 12) + min(length, 4095))  # overflow 12bit

    def test_broadcasting(self):
        self.chip['TDC0'].ENABLE = 1
        self.chip['TDC1'].ENABLE = 1
        self.chip['TDC2'].ENABLE = 1
        self.chip['TDC0'].EN_TRIGGER_DIST = 1
        self.chip['TDC1'].EN_TRIGGER_DIST = 1
        self.chip['TDC2'].EN_TRIGGER_DIST = 1
        self.chip['SEQ'].REPEAT = 1
        TDC_TRIG_DIST_MASK = 0x0FF00000
        TDC_VALUE_MASK = 0x00000FFF

        for _, i in enumerate([1045, 1046, 1047]):
            offset = 50   # trigger distance
            length = i + 1 + offset
            self.chip['SEQ_GEN'].SIZE = length + 1
            self.chip['SEQ']['TDC_IN'][offset:length + offset] = True
            self.chip['SEQ']['TDC_TRIGGER_IN'][0:10] = True
            self.chip['SEQ'].write(length)
            self.chip['SEQ'].START
            while not self.chip['SEQ_GEN'].is_ready:
                pass
            self.assertEqual(self.chip['FIFO0'].get_FIFO_INT_SIZE(), 1)
            self.assertEqual(self.chip['FIFO1'].get_FIFO_INT_SIZE(), 1)
            self.assertEqual(self.chip['FIFO2'].get_FIFO_INT_SIZE(), 1)

            data0 = self.chip['FIFO0'].get_data()
            data1 = self.chip['FIFO1'].get_data()
            data2 = self.chip['FIFO2'].get_data()

            # Check data from first TDC module
            self.assertEqual(data0[0] & TDC_VALUE_MASK, i + 1)  # TDC value
            self.assertEqual((TDC_TRIG_DIST_MASK & data0[0]) >> 20, offset)  # TDC trigger distance
            # Check if all TDC gave same data
            self.assertEqual(data0[0], data1[0])  # Compare TDC0 with TDC1
            self.assertEqual(data0[0], data2[0])  # Compare TDC0 with TDC2

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
