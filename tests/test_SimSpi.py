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
    size      : 8

  - name      : spi
    type      : spi
    interface : intf
    base_addr : 0x1000

  - name      : spi_rx
    type      : fast_spi_rx
    interface : intf
    base_addr : 0x2000

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
  - name        : CONTROL
    type        : StdRegister
    hw_driver   : gpio
    size        : 8
    fields:
      - name    : OUT
        size    : 8
        offset  : 7
"""


class TestSimSpi(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), 'test_SimSpi.v')])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    def test_io(self):
        size = self.chip['spi'].get_size()
        self.chip['gpio'].reset()
        self.assertEqual(size, 16 * 8)

        self.chip['spi'].set_data(range(16))
        ret = self.chip['spi'].get_data(size=16, addr=0)  # to read back what was written
        self.assertEqual(ret.tolist(), range(16))

        self.chip['spi'].set_data(range(16))
        ret = self.chip['spi'].get_data(addr=0)  # to read back what was written
        self.assertEqual(ret.tolist(), range(16))

        self.chip['spi'].start()
        while(not self.chip['spi'].is_done()):
            pass

        ret = self.chip['spi'].get_data()  # read back what was received (looped)
        self.assertEqual(ret.tolist(), range(16))

        # ext_start
        self.chip['spi'].set_en(1)
        self.assertEqual(self.chip['spi'].get_en(), 1)

        self.chip['PULSE_GEN'].set_delay(1)
        self.chip['PULSE_GEN'].set_width(1 + size)
        self.chip['PULSE_GEN'].set_repeat(1)
        self.assertEqual(self.chip['PULSE_GEN'].get_delay(), 1)
        self.assertEqual(self.chip['PULSE_GEN'].get_width(), 1 + size)
        self.assertEqual(self.chip['PULSE_GEN'].get_repeat(), 1)

        self.chip['PULSE_GEN'].start()
        while(not self.chip['PULSE_GEN'].is_done()):
            pass

        ret = self.chip['spi'].get_data()  # read back what was received (looped)
        self.assertEqual(ret.tolist(), range(16))

        # spi_rx
        ret = self.chip['spi_rx'].get_en()
        self.assertEqual(ret, False)

        self.chip['spi_rx'].set_en(True)
        ret = self.chip['spi_rx'].get_en()
        self.assertEqual(ret, True)

        self.chip['spi'].start()
        while(not self.chip['spi'].is_done()):
            pass

        ret = self.chip['fifo'].get_fifo_size()
        self.assertEqual(ret, 32)

        ret = self.chip['fifo'].get_data()

        data0 = ret.astype(np.uint8)
        data1 = np.right_shift(ret, 8).astype(np.uint8)
        data = np.reshape(np.vstack((data1, data0)), -1, order='F')
        self.assertEqual(data.tolist(), range(16))

    def test_dut_iter(self):
        conf = yaml.safe_load(cnfg_yaml)

        def iter_conf():
            for item in conf['registers']:
                yield item
            for item in conf['hw_drivers']:
                yield item
            for item in conf['transfer_layer']:
                yield item

        for mod, mcnf in zip(self.chip, iter_conf()):
            self.assertEqual(mod.name, mcnf['name'])
            self.assertEqual(mod.__class__.__name__, mcnf['type'])

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()

if __name__ == '__main__':
    unittest.main()
