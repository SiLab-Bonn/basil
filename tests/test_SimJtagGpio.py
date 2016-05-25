#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest
import os
import yaml

from basil.dut import Dut
from basil.utils.sim.utils import cocotb_compile_and_run, cocotb_compile_clean
from basil.utils.BitLogic import BitLogic
from basil.RL.StdRegister import StdRegister

cnfg_yaml = """
transfer_layer:
  - name  : intf
    type  : SiSim
    init:
        host : localhost
        port  : 12345

hw_drivers:
  - name      : gpio_jtag
    type      : gpio
    interface : intf
    base_addr : 0x0000
    size      : 8

  - name      : jtag
    type      : JtagGpio
    hw_driver : gpio_jtag
    base_addr : 0x0000
    size      : 8

  - name      : gpio_dev2
    type      : gpio
    interface : intf
    base_addr : 0x1000
    size      : 32

  - name      : gpio_dev1
    type      : gpio
    interface : intf
    base_addr : 0x2000
    size      : 32

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


class TestSimJtagGpio(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([
            os.path.join(os.path.dirname(__file__), 'jtag_tap.v'),
            os.path.join(os.path.dirname(__file__), 'test_SimJtagGpio.v')]
        )

        self.chip = Dut(cnfg_yaml)
        self.chip.init(init_yaml)

    def test_gpio(self):

        ID_CODE = BitLogic('0010')
        BYPASS = BitLogic('1111')
        DEBUG = BitLogic('1000')

        ret_ir = BitLogic('0101')

        # TEST REG INIT
        dev1ret = StdRegister(driver=None, conf=yaml.load(gpio_yaml))
        dev1ret.init()
        dev1ret['F1'] = 0x1
        dev1ret['F2'] = 0x2f
        dev1ret['F3'] = 0x2
        dev1ret['F4'] = 0x17cf4
        self.assertEqual(dev1ret[:], self.chip['DEV1'][:])

        self.chip['DEV1']['F2'] = 0
        self.assertFalse(dev1ret[:] == self.chip['DEV1'][:])

        self.chip.set_configuration(init_yaml)
        self.assertEqual(dev1ret[:], self.chip['DEV1'][:])

        self.chip['jtag'].reset()

        # IR CODE
        ret = self.chip['jtag'].scan_ir([ID_CODE] * 2)
        self.assertEqual(ret, [ret_ir] * 2)

        # ID CODE
        id_code = BitLogic.from_value(0x149B51C3, fmt='I')
        ret = self.chip['jtag'].scan_dr(['0' * 32] * 2)
        self.assertEqual(ret, [id_code] * 2)

        # BYPASS + ID CODE
        bypass_code = BitLogic('0')
        ret = self.chip['jtag'].scan_ir([ID_CODE, BYPASS])
        self.assertEqual(ret, [ret_ir] * 2)
        ret = self.chip['jtag'].scan_dr(['0' * 32, '1'])
        self.assertEqual(ret, [id_code, bypass_code])

        ret = self.chip['jtag'].scan_ir([BYPASS, ID_CODE])
        self.assertEqual(ret, [ret_ir] * 2)
        ret = self.chip['jtag'].scan_dr(['1', '0' * 32])
        self.assertEqual(ret, [bypass_code, id_code])

        # DEBUG
        ret = self.chip['jtag'].scan_ir([DEBUG, DEBUG])
        self.assertEqual(ret, [ret_ir] * 2)

        self.chip['jtag'].scan_dr(['1' * 32, '0' * 1 + '1' * 30 + '0' * 1])
        ret = self.chip['jtag'].scan_dr(['0' * 32, '1' * 32])
        self.assertEqual(ret, [BitLogic('1' * 32), BitLogic('0' * 1 + '1' * 30 + '0' * 1)])
        ret = self.chip['jtag'].scan_dr(['0' * 32, '0' * 32])
        self.assertEqual(ret, [BitLogic('0' * 32), BitLogic('1' * 32)])

        # SHIT IN DEV REG/DEBUG
        self.chip['jtag'].scan_dr([self.chip['DEV1'][:], self.chip['DEV2'][:]])

        # GPIO RETURN
        dev1ret.frombytes(self.chip['gpio_dev1'].get_data())
        self.assertEqual(dev1ret[:], self.chip['DEV1'][:])

        self.assertFalse(dev1ret[:] == self.chip['DEV2'][:])
        dev1ret.frombytes(self.chip['gpio_dev2'].get_data())
        self.assertEqual(dev1ret[:], self.chip['DEV2'][:])

        # JTAG RETURN
        ret = self.chip['jtag'].scan_dr(['0' * 32, '0' * 32])
        dev1ret.set(ret[0])
        self.assertEqual(dev1ret[:], self.chip['DEV1'][:])

        dev1ret.set(ret[1])
        self.assertEqual(dev1ret[:], self.chip['DEV2'][:])

        # REPEATING REGISTER
        self.chip['jtag'].scan_dr([self.chip['DEV'][:]])
        ret1 = self.chip['jtag'].scan_dr([self.chip['DEV'][:]])
        self.chip['jtag'].scan_dr([self.chip['DEV1'][:], self.chip['DEV2'][:]])
        ret2 = self.chip['jtag'].scan_dr([self.chip['DEV1'][:] + self.chip['DEV2'][:]])
        ret3 = self.chip['jtag'].scan_dr([self.chip['DEV1'][:] + self.chip['DEV2'][:]])
        self.assertEqual(ret1[:], ret2[:])
        self.assertEqual(ret2[:], ret3[:])

        # REPEATING SETTING
        self.chip['jtag'].scan_dr(['1' * 32 + '0' * 32])
        ret = self.chip['jtag'].scan_dr(['0' * 32 + '0' * 32])

        self.chip['DEV'].set(ret[0])
        self.assertEqual(self.chip['DEV'][:], BitLogic('0' * 32 + '1' * 32))

        self.chip['jtag'].scan_dr([self.chip['DEV1'][:] + self.chip['DEV2'][:]])
        ret = self.chip['jtag'].scan_dr([self.chip['DEV1'][:] + self.chip['DEV2'][:]])

        self.chip['DEV'].set(ret[0])
        self.assertEqual(self.chip['DEV'][:], self.chip['DEV1'][:] + self.chip['DEV2'][:])

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()

if __name__ == '__main__':
    unittest.main()
