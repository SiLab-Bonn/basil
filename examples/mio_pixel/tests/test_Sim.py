# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import sys
import unittest
import os
import yaml
import numpy as np

from bitarray import bitarray

from basil.dut import Dut
from basil.utils.sim.utils import cocotb_compile_and_run, cocotb_compile_clean, get_basil_dir

sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))  # ../
import pixel


class TestPixel(unittest.TestCase):
    def setUp(self):

        fw_path = get_basil_dir() + '/firmware/modules'
        cocotb_compile_and_run(
            [fw_path + '/gpio/gpio.v',
            fw_path + '/utils/reset_gen.v',
            fw_path + '/utils/bus_to_ip.v',
            fw_path + '/rrp_arbiter/rrp_arbiter.v',
            fw_path + '/utils/ODDR_sim.v',
            fw_path + '/utils/generic_fifo.v',
            fw_path + '/utils/cdc_pulse_sync.v',
            fw_path + '/utils/fx2_to_bus.v',
            fw_path + '/utils/BUFG_sim.v',
            fw_path + '/utils/cdc_syncfifo.v',
            fw_path + '/utils/ddr_des.v',
            fw_path + '/utils/IDDR_sim.v',
            fw_path + '/utils/DCM_sim.v',
            fw_path + '/utils/clock_divider.v',
            fw_path + '/utils/clock_multiplier.v',
            fw_path + '/utils/flag_domain_crossing.v',
            fw_path + '/utils/3_stage_synchronizer.v',
            fw_path + '/fast_spi_rx/fast_spi_rx.v', fw_path + '/fast_spi_rx/fast_spi_rx_core.v',
            fw_path + '/seq_gen/seq_gen.v', fw_path + '/seq_gen/seq_gen_core.v',
            fw_path + '/tdc_s3/tdc_s3.v', fw_path + '/tdc_s3/tdc_s3_core.v',
            fw_path + '/sram_fifo/sram_fifo_core.v', fw_path + '/sram_fifo/sram_fifo.v',
            os.path.dirname(__file__) + '/../firmware/src/clk_gen.v',
            os.path.dirname(__file__) + '/../firmware/src/pixel.v',
            os.path.dirname(__file__) + '/../tests/tb.v'],
            top_level='tb',
            sim_bus='basil.utils.sim.SiLibUsbBusDriver'
            )

        with open(os.path.dirname(__file__) + '/../pixel.yaml', 'r') as f:
            cnfg = yaml.load(f)

        # change to simulation interface
        cnfg['transfer_layer'][0]['type'] = 'SiSim'

        self.chip = pixel.Pixel(cnfg)
        self.chip.init()

    def test_simple(self):
        input_arr = bitarray('10' * 64)

        self.chip['PIXEL_REG'][:] = input_arr
        self.chip['PIXEL_REG'][0] = 0
        self.chip.program_pixel_reg()

        ret = self.chip['DATA'].get_data()

        data0 = ret.astype(np.uint8)
        data1 = np.right_shift(ret, 8).astype(np.uint8)
        data = np.reshape(np.vstack((data1, data0)), -1, order='F')
        bdata = np.unpackbits(data)

        input_arr[0] = 0

        self.assertEqual(input_arr.tolist(), bdata.tolist())

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()

if __name__ == '__main__':
    unittest.main()
