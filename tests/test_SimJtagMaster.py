#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest
import os
import yaml
import numpy as np

from basil.dut import Dut
from basil.utils.sim.utils import cocotb_compile_and_run, cocotb_compile_clean
from basil.utils.BitLogic import BitLogic
from basil.RL.StdRegister import StdRegister

cnfg_yaml = """
transfer_layer:
  - name  : INTF
    type  : SiSim
    init:
        host : localhost
        port  : 12345

hw_drivers:
  - name      : JTAG
    type      : JtagMaster
    interface : INTF
    base_addr : 0x0000

  - name      : GPIO_DEV2
    type      : gpio
    interface : INTF
    base_addr : 0x1000
    size      : 32

  - name      : GPIO_DEV1
    type      : gpio
    interface : INTF
    base_addr : 0x2000
    size      : 32

  - name      : fifo1
    type      : sram_fifo
    interface : INTF
    base_addr : 0x8000
    base_data_addr: 0x80000000

  - name      : fifo2
    type      : sram_fifo
    interface : INTF
    base_addr : 0xa000
    base_data_addr: 0xa0000000

registers:
  - name        : DEV1
    type        : StdRegister
    size        : 32
    driver      : None
    init        :
        F3      : 0x2
        F4      : 0
    fields:
      - name    : F1
        size    : 1
        offset  : 0
      - name    : F2
        size    : 6
        offset  : 6
      - name    : F3
        size    : 4
        offset  : 10
      - name    : F4
        size    : 21
        offset  : 31

  - name        : DEV2
    type        : StdRegister
    size        : 32
    driver      : None
    fields:
      - name    : F1
        size    : 1
        offset  : 0
      - name    : F2
        size    : 6
        offset  : 6
      - name    : F3
        size    : 4
        offset  : 10
      - name    : F4
        size    : 21
        offset  : 31

  - name        : DEV
    type        : StdRegister
    size        : 64
    driver      : None
    fields:
        - name   : NX
          offset : 63
          size   : 32
          repeat : 2
          fields :
            - name    : F1
              size    : 1
              offset  : 0
            - name    : F2
              size    : 6
              offset  : 6
            - name    : F3
              size    : 4
              offset  : 10
            - name    : F4
              size    : 21
              offset  : 31
"""

gpio_yaml = """
name        : GPIO
type        : StdRegister
size        : 32
driver      : None
fields:
  - name    : F1
    size    : 1
    offset  : 0
  - name    : F2
    size    : 6
    offset  : 6
  - name    : F3
    size    : 4
    offset  : 10
  - name    : F4
    size    : 21
    offset  : 31
"""

init_yaml = """
DEV1:
    F1 : 0x1
    F2 : 0x2f
    #F3 : 0x2
    F4 : 0x17cf4
DEV2:
    F1 : 0x0
    F2 : 0x1a
    F3 : 0x0
    F4 : 0x1aa55
DEV:
    NX :
      - F1 : 0x0
        F2 : 0x1a
        F3 : 0x0
        F4 : 0x1aa55
      - F1 : 0x1
        F2 : 0x2f
        F3 : 0x2
        F4 : 0x17cf4
"""


class TestSimJtagMaster(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), "jtag_tap.v"), os.path.join(os.path.dirname(__file__), "test_SimJtagMaster.v")])

        self.chip = Dut(cnfg_yaml)
        self.chip.init(init_yaml)

    def test_sequence(self):
        self.jtag_master_FSM_tests()
        self.jtag_tests()

    def jtag_master_FSM_tests(self):
        # Make sure register are set to default values
        self.chip["JTAG"].reset()

        size = self.chip["JTAG"].SIZE
        self.assertEqual(size, 2000 * 8)

        byte_size = self.chip["JTAG"].MEM_BYTES
        self.assertEqual(byte_size, 2000)

        word_cnt = self.chip["JTAG"].WORD_COUNT
        self.assertEqual(word_cnt, 1)

        op = self.chip["JTAG"].get_command()
        self.assertEqual(op, "INSTRUCTION")

        wait = self.chip["JTAG"].WAIT
        self.assertEqual(wait, 0)

        # Test reset
        self.chip["JTAG"].reset()

        # Write 1 word test
        self.chip["JTAG"].set_data([0xFF] + list(range(15)))
        ret = self.chip["JTAG"].get_data(size=16, addr=0)  # to read back what was written
        self.assertEqual(ret.tolist(), [0xFF] + list(range(15)))

        self.chip["JTAG"].SIZE = 16
        self.chip["JTAG"].start()
        while not self.chip["JTAG"].READY:
            pass

        # Write 2 word test
        self.chip["JTAG"].WORD_COUNT = 2
        word_cnt = self.chip["JTAG"].WORD_COUNT
        self.assertEqual(word_cnt, 2)

        self.chip["JTAG"].start()
        while not self.chip["JTAG"].READY:
            pass

        # Write 5 word test
        self.chip["JTAG"].WORD_COUNT = 5
        word_cnt = self.chip["JTAG"].WORD_COUNT
        self.assertEqual(word_cnt, 5)

        self.chip["JTAG"].start()
        while not self.chip["JTAG"].READY:
            pass

    def jtag_tests(self):

        ID_CODE = BitLogic("0010")
        BYPASS = BitLogic("1111")
        DEBUG = BitLogic("1000")
        ret_ir = BitLogic("0101")

        # TEST REG INIT
        dev1ret = StdRegister(driver=None, conf=yaml.safe_load(gpio_yaml))
        dev1ret.init()
        dev1ret["F1"] = 0x1
        dev1ret["F2"] = 0x2F
        dev1ret["F3"] = 0x2
        dev1ret["F4"] = 0x17CF4
        self.assertEqual(dev1ret[:], self.chip["DEV1"][:])

        self.chip["DEV1"]["F2"] = 0
        self.assertFalse(dev1ret[:] == self.chip["DEV1"][:])

        self.chip.set_configuration(init_yaml)
        self.assertEqual(dev1ret[:], self.chip["DEV1"][:])

        self.chip["JTAG"].reset()

        # IR CODE
        ret = self.chip["JTAG"].scan_ir([ID_CODE] * 2)
        self.assertEqual(ret, [ret_ir] * 2)

        # ID CODE
        id_code = BitLogic.from_value(0x149B51C3, fmt="I")
        ret = self.chip["JTAG"].scan_dr(["0" * 32] * 2)
        self.assertEqual(ret, [id_code] * 2)

        # BYPASS + ID CODE
        bypass_code = BitLogic("0")
        ret = self.chip["JTAG"].scan_ir([ID_CODE, BYPASS])
        self.assertEqual(ret, [ret_ir] * 2)
        ret = self.chip["JTAG"].scan_dr(["0" * 32, "1"])
        self.assertEqual(ret, [id_code, bypass_code])

        ret = self.chip["JTAG"].scan_ir([BYPASS, ID_CODE])
        self.assertEqual(ret, [ret_ir] * 2)
        ret = self.chip["JTAG"].scan_dr(["1", "0" * 32])
        self.assertEqual(ret, [bypass_code, id_code])

        # DEBUG
        ret = self.chip["JTAG"].scan_ir([DEBUG, DEBUG])
        self.assertEqual(ret, [ret_ir] * 2)

        self.chip["JTAG"].scan_dr(["1" * 32, "0" * 1 + "1" * 30 + "0" * 1])
        ret = self.chip["JTAG"].scan_dr(["0" * 32, "1" * 32])
        self.assertEqual(ret, [BitLogic("1" * 32), BitLogic("0" * 1 + "1" * 30 + "0" * 1)])
        ret = self.chip["JTAG"].scan_dr(["0" * 32, "0" * 32])
        self.assertEqual(ret, [BitLogic("0" * 32), BitLogic("1" * 32)])

        # SHIT IN DEV REG/DEBUG
        self.chip["JTAG"].scan_dr([self.chip["DEV1"][:], self.chip["DEV2"][:]])

        # GPIO RETURN
        dev1ret.frombytes(self.chip["GPIO_DEV1"].get_data())
        self.assertEqual(dev1ret[:], self.chip["DEV1"][:])

        self.assertFalse(dev1ret[:] == self.chip["DEV2"][:])
        dev1ret.frombytes(self.chip["GPIO_DEV2"].get_data())
        self.assertEqual(dev1ret[:], self.chip["DEV2"][:])

        # JTAG RETURN
        ret = self.chip["JTAG"].scan_dr(["0" * 32, "0" * 32])
        dev1ret.set(ret[0])
        self.assertEqual(dev1ret[:], self.chip["DEV1"][:])

        dev1ret.set(ret[1])
        self.assertEqual(dev1ret[:], self.chip["DEV2"][:])

        # REPEATING REGISTER
        self.chip["JTAG"].scan_dr([self.chip["DEV"][:]], words=2)
        ret1 = self.chip["JTAG"].scan_dr([self.chip["DEV"][:]], words=2)
        self.chip["JTAG"].scan_dr([self.chip["DEV1"][:], self.chip["DEV2"][:]])
        ret2 = self.chip["JTAG"].scan_dr([self.chip["DEV1"][:] + self.chip["DEV2"][:]], words=2)
        ret3 = self.chip["JTAG"].scan_dr([self.chip["DEV1"][:] + self.chip["DEV2"][:]], words=2)
        self.assertEqual(ret1[:], ret2[:])
        self.assertEqual(ret2[:], ret3[:])

        # REPEATING SETTING
        self.chip["JTAG"].scan_dr(["1" * 32 + "0" * 32])
        ret = self.chip["JTAG"].scan_dr(["0" * 32 + "0" * 32])

        self.chip["DEV"].set(ret[0])
        self.assertEqual(self.chip["DEV"][:], BitLogic("1" * 32 + "0" * 32))

        self.chip["JTAG"].scan_dr([self.chip["DEV1"][:] + self.chip["DEV2"][:]], words=2)
        ret = self.chip["JTAG"].scan_dr([self.chip["DEV1"][:] + self.chip["DEV2"][:]], words=2)

        self.chip["DEV"].set(ret[0])
        self.assertEqual(self.chip["DEV"][:], self.chip["DEV1"][:] + self.chip["DEV2"][:])

        # BYPASS AND DEBUG REGISTER
        self.chip["fifo1"].reset()
        self.chip["fifo2"].reset()
        fifo_size = self.chip["fifo1"].get_fifo_size()
        self.assertEqual(fifo_size, 0)

        # Generate some data
        data_string = []
        data = np.power(range(20), 6)
        for i in range(len(data)):
            s = str(bin(data[i]))[2:]
            data_string.append("0" * (32 - len(s)) + s)

        # Bypass first device, put data in the debug register of the second device
        self.chip["JTAG"].scan_ir([DEBUG, BYPASS])
        for i in range(len(data_string)):
            self.chip["JTAG"].scan_dr([data_string[i], "1"])

        fifo_size = self.chip["fifo1"].get_fifo_size()
        self.assertEqual(fifo_size, len(data_string) * 4)
        fifo_tap1_content = self.chip["fifo1"].get_data()
        fifo_tap2_content = self.chip["fifo2"].get_data()
        self.assertListEqual(list(data), list(fifo_tap1_content))
        self.assertNotEqual(list(data), list(fifo_tap2_content))

        # empty fifos
        fifo_tap1_content = self.chip["fifo1"].get_data()
        fifo_tap2_content = self.chip["fifo2"].get_data()

        # Bypass second device, put data in the debug register of the first device
        self.chip["JTAG"].scan_ir([BYPASS, DEBUG])
        for i in range(len(data_string)):
            self.chip["JTAG"].scan_dr(["1", data_string[i]])

        fifo_size = self.chip["fifo1"].get_fifo_size()
        self.assertEqual(fifo_size, len(data_string) * 4)
        fifo_tap1_content = self.chip["fifo1"].get_data()
        fifo_tap2_content = self.chip["fifo2"].get_data()
        self.assertNotEqual(list(data), list(fifo_tap1_content))
        self.assertListEqual(list(data), list(fifo_tap2_content))

        # TEST OF SENDING MULTIPLE WORDS WITH SCAN_DR FUNCTION
        self.chip["JTAG"].scan_ir([DEBUG, DEBUG])
        self.chip["JTAG"].set_data([0x00] * 100)
        self.chip["JTAG"].set_command("DATA")
        self.chip["JTAG"].SIZE = 100 * 8
        self.chip["JTAG"].start()
        while not self.chip["JTAG"].READY:
            pass

        # empty fifos
        fifo_tap1_content = self.chip["fifo1"].get_data()
        fifo_tap2_content = self.chip["fifo2"].get_data()

        self.chip["JTAG"].scan_ir([DEBUG, BYPASS])
        self.chip["JTAG"].scan_dr([BitLogic("0" * 24 + "10101101"), BitLogic("1")] * 15, words=15)

        fifo_tap1_content = self.chip["fifo1"].get_data()
        fifo_tap2_content = self.chip["fifo2"].get_data()
        self.assertListEqual([int("0" * 24 + "10101101", 2)] * 15, list(fifo_tap1_content))
        self.assertNotEqual([int("0" * 24 + "10101101", 2)] * 15, list(fifo_tap2_content))

        # change value of debug registers
        self.chip["JTAG"].scan_ir([DEBUG, DEBUG])
        self.chip["JTAG"].scan_dr(["0" * 32, "0" * 32])

        # empty fifos
        fifo_tap1_content = self.chip["fifo1"].get_data()
        fifo_tap2_content = self.chip["fifo2"].get_data()

        self.chip["JTAG"].scan_ir([BYPASS, DEBUG])
        self.chip["JTAG"].scan_dr([BitLogic("1"), BitLogic("0" * 24 + "10101101")] * 15, words=15)

        fifo_tap1_content = self.chip["fifo1"].get_data()
        fifo_tap2_content = self.chip["fifo2"].get_data()

        self.assertNotEqual([int("0" * 24 + "10101101", 2)] * 15, list(fifo_tap1_content))
        self.assertListEqual([int("0" * 24 + "10101101", 2)] * 15, list(fifo_tap2_content))

        # TEST OF SENDING MULTIPLE WORDS BY WRITING DIRECTLY IN JTAG MODULE MEMORY

        # The ring register (DEBUG register) is 32 bits long, so the data have to be arranged like this :
        # [WORD1(dev1) WORD1(dev2) WORD2(dev1) WORD2(dev2) ...]
        data = np.byte(
            [
                0x01, 0x02, 0x03, 0x04,
                0x02, 0x04, 0x06, 0x08,
                0x11, 0x12, 0x13, 0x14,
                0x12, 0x14, 0x16, 0x18,
                0x21, 0x22, 0x23, 0x24,
                0x22, 0x24, 0x26, 0x28,
                0x31, 0x32, 0x33, 0x34,
                0x32, 0x34, 0x36, 0x38,
                0x41, 0x42, 0x43, 0x44,
                0x42, 0x44, 0x46, 0x48,
            ]
        )

        device_number = 2
        word_size_bit = 32
        word_count = 5

        self.chip["JTAG"].scan_ir([DEBUG, DEBUG])

        # empty fifo
        self.chip["fifo1"].get_data()
        self.chip["fifo2"].get_data()

        self.chip["JTAG"].set_data(data)
        self.chip["JTAG"].SIZE = word_size_bit * device_number
        self.chip["JTAG"].set_command("DATA")
        self.chip["JTAG"].WORD_COUNT = word_count

        self.chip["JTAG"].start()
        while not self.chip["JTAG"].READY:
            pass

        fifo_tap1_content = self.chip["fifo1"].get_data()
        fifo_tap2_content = self.chip["fifo2"].get_data()

        expected_result_tap1 = [int("0x01020304", 16), int("0x11121314", 16), int("0x21222324", 16), int("0x31323334", 16), int("41424344", 16)]
        expected_result_tap2 = [int("0x02040608", 16), int("0x12141618", 16), int("0x22242628", 16), int("0x32343638", 16), int("42444648", 16)]
        self.assertListEqual(expected_result_tap1, list(fifo_tap1_content))
        self.assertListEqual(expected_result_tap2, list(fifo_tap2_content))

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()


if __name__ == "__main__":
    unittest.main()
