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
    size      : 8

  - name      : SPI
    type      : spi
    interface : INTF
    base_addr : 0x1000

  - name      : SPI_RX
    type      : fast_spi_rx
    interface : INTF
    base_addr : 0x2000

  - name      : PULSE_GEN
    type      : pulse_gen
    interface : INTF
    base_addr : 0x3000

  - name      : FIFO
    type      : bram_fifo
    interface : INTF
    base_addr : 0x8000
    base_data_addr: 0x80000000

registers:
  - name        : CONTROL
    type        : StdRegister
    hw_driver   : GPIO
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
        size = self.chip['SPI'].get_SIZE()
        self.chip['GPIO'].reset()
        self.assertEqual(size, 16 * 8)

        self.chip['SPI'].set_data(range(16))
        ret = self.chip['SPI'].get_data(size=16, addr=0)  # to read back what was written
        self.assertEqual(ret.tolist(), list(range(16)))

        self.chip['SPI'].set_data(range(16))
        ret = self.chip['SPI'].get_data(addr=0)  # to read back what was written
        self.assertEqual(ret.tolist(), list(range(16)))

        self.chip['SPI'].start()
        while(not self.chip['SPI'].is_ready):
            pass

        ret = self.chip['SPI'].get_data()  # read back what was received (looped)
        self.assertEqual(ret.tolist(), list(range(16)))

        # ext_start
        self.chip['SPI'].set_en(1)
        self.assertEqual(self.chip['SPI'].get_en(), 1)

        self.chip['PULSE_GEN'].set_DELAY(1)
        self.chip['PULSE_GEN'].set_WIDTH(1 + size)
        self.chip['PULSE_GEN'].set_REPEAT(1)
        self.assertEqual(self.chip['PULSE_GEN'].get_DELAY(), 1)
        self.assertEqual(self.chip['PULSE_GEN'].get_WIDTH(), 1 + size)
        self.assertEqual(self.chip['PULSE_GEN'].get_REPEAT(), 1)

        self.chip['PULSE_GEN'].start()
        while(not self.chip['PULSE_GEN'].is_ready):
            pass

        ret = self.chip['SPI'].get_data()  # read back what was received (looped)
        self.assertEqual(ret.tolist(), list(range(16)))

        # SPI_RX
        ret = self.chip['SPI_RX'].get_en()
        self.assertEqual(ret, False)

        self.chip['SPI_RX'].set_en(True)
        ret = self.chip['SPI_RX'].get_en()
        self.assertEqual(ret, True)

        self.chip['SPI'].start()
        while(not self.chip['SPI'].is_ready):
            pass

        ret = self.chip['FIFO'].get_FIFO_SIZE()
        self.assertEqual(ret, 32)

        ret = self.chip['FIFO'].get_data()

        data0 = ret.astype(np.uint8)
        data1 = np.right_shift(ret, 8).astype(np.uint8)
        data = np.reshape(np.vstack((data1, data0)), -1, order='F')
        self.assertEqual(data.tolist(), list(range(16)))

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
