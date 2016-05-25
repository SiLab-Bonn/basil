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
  - name      : PULSE_GEN
    type      : pulse_gen
    interface : intf
    base_addr : 0x0000

  - name      : SEQ_GEN
    type      : seq_gen
    interface : intf
    mem_size  : 8192
    base_addr : 0x1000

  - name      : FADC
    type      : fadc_rx
    interface : intf
    base_addr : 0x3000

  - name      : fifo
    type      : sram_fifo
    interface : intf
    base_addr : 0x8000
    base_data_addr: 0x80000000

  - name      : SPI_FADC
    type      : spi
    interface : intf
    base_addr : 0x5000

  - name      : fadc_conf
    type      : FadcConf
    hw_driver : SPI_FADC
"""


class TestSimAdcRx(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), 'test_SimAdcRx.v')])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    def test_io(self):
        pattern = [1, 0, 1, 1, 1, 2, 1, 3, 1, 4, 1, 5, 1, 6, 1, 7]
        self.chip['SEQ_GEN'].set_data(pattern)

        self.chip['PULSE_GEN'].set_delay(1)
        self.chip['PULSE_GEN'].set_width(1)

        self.chip['SEQ_GEN'].set_en_ext_start(True)
        self.chip['SEQ_GEN'].set_size(8)
        self.chip['SEQ_GEN'].set_repeat(1)

        # this is to have something in memory and not X
        self.chip['PULSE_GEN'].start()
        self.chip['SEQ_GEN'].is_done()
        self.chip['SEQ_GEN'].is_done()

        while(not self.chip['SEQ_GEN'].is_done()):
            pass

        # take some data
        self.chip['FADC'].set_align_to_sync(True)
        self.chip['FADC'].set_data_count(16)
        self.chip['FADC'].set_single_data(True)
        self.chip['FADC'].start()

        self.chip['PULSE_GEN'].start()
        self.chip['SEQ_GEN'].is_done()
        self.chip['SEQ_GEN'].is_done()

        while(not self.chip['FADC'].is_done()):
            pass

        ret = self.chip['fifo'].get_data()

        self.assertEqual(len(ret), 16)
        self.assertEqual(ret[2:2 + 8].tolist(), [0x0100, 0x0101, 0x0102, 0x0103, 0x0104, 0x0105, 0x0106, 0x0107])

        # 2times
        self.chip['FADC'].start()

        self.chip['PULSE_GEN'].start()
        self.chip['SEQ_GEN'].is_done()

        while(not self.chip['FADC'].is_done()):
            pass

        self.chip['FADC'].start()

        self.chip['PULSE_GEN'].start()
        self.chip['SEQ_GEN'].is_done()

        while(not self.chip['FADC'].is_done()):
            pass

        ret = self.chip['fifo'].get_data()
        self.assertEqual(len(ret), 32)
        self.assertEqual(ret[2:2 + 8].tolist(), [0x0100, 0x0101, 0x0102, 0x0103, 0x0104, 0x0105, 0x0106, 0x0107])

        self.chip['FADC'].set_align_to_sync(False)
        self.chip['FADC'].start()
        self.chip['FADC'].start()

        while(not self.chip['FADC'].is_done()):
            pass

        ret = self.chip['fifo'].get_data()
        self.assertEqual(len(ret), 16)

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()

if __name__ == '__main__':
    unittest.main()
