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

# TODO: Add tests for size 1/2/4/16/32

cnfg_yaml = """
transfer_layer:
  - name  : INTF
    type  : SiSim
    init:
        host : localhost
        port  : 12345

hw_drivers:
  - name      : PULSE_GEN
    type      : pulse_gen
    interface : INTF
    base_addr : 0x0000

  - name      : SEQ_GEN
    type      : seq_gen
    interface : INTF
    base_addr : 0x10000000

  - name      : SEQ_REC
    type      : seq_rec
    interface : INTF
    base_addr : 0x20000000

registers:
  - name        : SEQ
    type        : TrackRegister
    hw_driver   : SEQ_GEN
    seq_width   : 8
    seq_size    : 8192
    tracks  :
      - name     : S0
        position : 0
      - name     : S1
        position : 1
      - name     : S2
        position : 2
      - name     : S3
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


class TestSimSeq(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), 'test_SimSeq.v')])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    def test_io(self):
        MEM_KB = 1

        self.assertEqual(self.chip['SEQ_GEN'].get_mem_size(), MEM_KB * 1024)
        self.assertEqual(self.chip['SEQ_REC'].get_mem_size(), MEM_KB * 1024)

        mem_in = (list(range(256)) * 4) * MEM_KB

        self.chip["SEQ_GEN"].set_data(mem_in)
        ret = self.chip['SEQ_GEN'].get_data()
        self.assertEqual(ret.tolist(), mem_in)

        self.chip['SEQ_GEN'].set_EN_EXT_START(True)
        self.chip['SEQ_REC'].set_EN_EXT_START(True)

        self.chip['PULSE_GEN'].set_DELAY(1)
        self.chip['PULSE_GEN'].set_WIDTH(1)
        self.chip['PULSE_GEN'].START

        while not self.chip['SEQ_GEN'].is_ready:
            pass

        # 2nd time
        self.chip['PULSE_GEN'].START

        while not self.chip['SEQ_GEN'].is_ready:
            pass

        ret = self.chip['SEQ_REC'].get_data()
        self.assertEqual(ret.tolist()[2:], mem_in[:-2])

        self.chip['SEQ']['S0'][0] = 1
        self.chip['SEQ']['S1'][1] = 1
        self.chip['SEQ']['S2'][2] = 1
        self.chip['SEQ']['S3'][3] = 1

        self.chip['SEQ']['S4'][12] = 1
        self.chip['SEQ']['S5'][13] = 1
        self.chip['SEQ']['S6'][14] = 1
        self.chip['SEQ']['S7'][15] = 1

        pattern = [0x01, 0x02, 0x04, 0x08, 0, 0, 0, 0, 0, 0, 0, 0, 0x10, 0x20, 0x40, 0x80]

        self.chip['SEQ'].write(16)

        ret = self.chip['SEQ'].get_data(size=16)
        self.assertEqual(ret.tolist(), pattern)

        rec_size = 16 * 4 + 8
        self.chip['SEQ_REC'].set_EN_EXT_START(True)
        self.chip['SEQ_REC'].set_size(rec_size)

        self.chip['PULSE_GEN'].set_DELAY(1)
        self.chip['PULSE_GEN'].set_WIDTH(1)

        self.assertEqual(self.chip['PULSE_GEN'].get_DELAY(), 1)
        self.assertEqual(self.chip['PULSE_GEN'].get_WIDTH(), 1)

        self.chip['SEQ'].set_REPEAT(4)
        self.chip['SEQ'].set_EN_EXT_START(True)
        self.chip['SEQ'].set_size(16)
        # self.chip['SEQ'].START

        self.chip['PULSE_GEN'].START

        while not self.chip['SEQ'].is_ready:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        self.assertEqual(ret.tolist()[2:], pattern * 4 + [0x80] * 6)  # 2 clk delay + pattern x4 + 6 x last pattern

        #
        self.chip['SEQ'].set_REPEAT_START(12)
        self.chip['PULSE_GEN'].START

        while not self.chip['SEQ'].is_ready:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        self.assertEqual(ret.tolist(), [0x80] * 2 + pattern + pattern[12:] * 3 + [0x80] * 3 * 12 + [0x80] * 6)  # 2 clk delay 0x80 > from last pattern + ...

        self.chip['SEQ'].set_wait(4)
        self.chip['PULSE_GEN'].START

        while not self.chip['SEQ'].is_ready:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        lpat = pattern[12:] + [0x80] * 4
        self.assertEqual(ret.tolist(), [0x80] * 2 + pattern + [0x80] * 4 + lpat * 3 + [0x80] * (3 * 12 - 4 * 4) + [0x80] * 6)

        #
        rec_size = rec_size * 3
        self.chip['SEQ_REC'].set_size(rec_size)
        self.chip['SEQ'].set_clk_divide(3)
        self.chip['SEQ'].set_wait(3)
        self.chip['PULSE_GEN'].START

        while not self.chip['SEQ'].is_ready:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        lpat = pattern[12:] + [0x80] * 3
        mu_pat = pattern + [0x80] * 3 + lpat * 3
        fm = []
        for i in mu_pat:
            fm += [i, i, i]
        self.assertEqual(ret.tolist(), [0x80] * 2 + fm + [0x80] * 94)

        #
        self.chip['SEQ'].set_wait(0)
        self.chip['PULSE_GEN'].START

        while not self.chip['SEQ'].is_ready:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        lpat = pattern[12:]
        mu_pat = pattern + lpat * 3
        fm = []
        for i in mu_pat:
            fm += [i, i, i]
        self.assertEqual(ret.tolist(), [0x80] * 2 + fm + [0x80] * (94 + 4 * 3 * 3))

        # nested loop test
        pattern = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
        self.chip['SEQ'].set_data(pattern)
        self.chip['SEQ'].set_REPEAT(4)
        self.chip['SEQ'].set_REPEAT_START(2)
        self.chip['SEQ'].set_NESTED_START(8)
        self.chip['SEQ'].set_NESTED_STOP(12)
        self.chip['SEQ'].set_NESTED_REPEAT(3)
        self.chip['SEQ'].set_CLK_DIV(1)
        self.chip['PULSE_GEN'].START

        while not self.chip['SEQ'].is_ready:
            pass

        exp_pattern = [0x10, 0x10]
        exp_pattern += pattern[0:2]
        rep = pattern[2:8]
        rep += pattern[8:12] * 3
        rep += pattern[12:16]
        exp_pattern += rep * 4
        exp_pattern += [16] * 124

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        self.assertEqual(ret.tolist(), exp_pattern)

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()


class TestSimSeq4bit(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), 'test_SimSeq.v')], extra_defines=["BITS=4"])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    def test_seq_4bit(self):
        MEM_KB = 1

        mem_in = (list(range(256)) * 4) * MEM_KB

        self.chip["SEQ_GEN"].set_data(mem_in)
        ret = self.chip['SEQ_GEN'].get_data()
        self.assertEqual(ret.tolist(), mem_in)

        self.chip['SEQ_GEN'].set_EN_EXT_START(True)
        self.chip['SEQ_REC'].set_EN_EXT_START(True)

        self.chip['PULSE_GEN'].set_DELAY(1)
        self.chip['PULSE_GEN'].set_WIDTH(1)
        self.chip['PULSE_GEN'].START

        while not self.chip['SEQ_GEN'].is_ready:
            pass

        ret = self.chip['SEQ_REC'].get_data()
        self.assertEqual(ret.tolist()[1:], mem_in[:-1])

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()


class TestSimSeq16bit(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), 'test_SimSeq.v')], extra_defines=["BITS=16"])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    def test_seq_16bit(self):
        MEM_KB = 1

        mem_in = (list(range(256)) * 4) * MEM_KB

        self.chip["SEQ_GEN"].set_data(mem_in)
        ret = self.chip['SEQ_GEN'].get_data()
        self.assertEqual(ret.tolist(), mem_in)

        self.chip['SEQ_GEN'].set_EN_EXT_START(True)
        self.chip['SEQ_REC'].set_EN_EXT_START(True)

        self.chip['PULSE_GEN'].set_DELAY(1)
        self.chip['PULSE_GEN'].set_WIDTH(1)
        self.chip['PULSE_GEN'].START

        while not self.chip['SEQ_GEN'].is_ready:
            pass

        ret = self.chip['SEQ_REC'].get_data()
        self.assertEqual(ret.tolist()[4:], mem_in[:-4])

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()


if __name__ == '__main__':
    unittest.main()
