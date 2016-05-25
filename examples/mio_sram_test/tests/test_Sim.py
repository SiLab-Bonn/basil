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
from basil.utils.sim.utils import cocotb_compile_and_run, cocotb_compile_clean, get_basil_dir


class TestSram(unittest.TestCase):
    def setUp(self):

        fw_path = os.path.join(get_basil_dir(), 'firmware/modules')
        cocotb_compile_and_run([
            os.path.join(fw_path, 'gpio/gpio.v'),
            os.path.join(fw_path, 'utils/reset_gen.v'),
            os.path.join(fw_path, 'utils/bus_to_ip.v'),
            os.path.join(fw_path, 'rrp_arbiter/rrp_arbiter.v'),
            os.path.join(fw_path, 'utils/ODDR_sim.v'),
            os.path.join(fw_path, 'utils/generic_fifo.v'),
            os.path.join(fw_path, 'utils/cdc_pulse_sync.v'),
            os.path.join(fw_path, 'utils/fx2_to_bus.v'),
            os.path.join(fw_path, 'pulse_gen/pulse_gen.v'),
            os.path.join(fw_path, 'pulse_gen/pulse_gen_core.v'),
            os.path.join(fw_path, 'sram_fifo/sram_fifo_core.v'),
            os.path.join(fw_path, 'sram_fifo/sram_fifo.v'),
            os.path.join(os.path.dirname(__file__), '../firmware/src/sram_test.v'),
            os.path.join(os.path.dirname(__file__), '../tests/tb.v')],
            top_level='tb',
            sim_bus='basil.utils.sim.SiLibUsbBusDriver'
        )

        with open(os.path.join(os.path.dirname(__file__), '../sram_test.yaml'), 'r') as f:
            cnfg = yaml.load(f)

        # change to simulation interface
        cnfg['transfer_layer'][0]['type'] = 'SiSim'

        self.chip = Dut(cnfg)
        self.chip.init()

    def test_simple(self):
        self.chip['CONTROL']['COUNTER_EN'] = 1
        self.chip['CONTROL'].write()
        self.chip['CONTROL'].write()
        self.chip['CONTROL']['COUNTER_EN'] = 0
        self.chip['CONTROL'].write()
        for _ in range(10):
            self.chip['CONTROL'].write()

        ret = self.chip['fifo'].get_data()

        self.chip['CONTROL']['COUNTER_EN'] = 1
        self.chip['CONTROL'].write()
        self.chip['CONTROL'].write()
        self.chip['CONTROL'].write()
        self.chip['CONTROL']['COUNTER_EN'] = 0
        for _ in range(10):
            self.chip['CONTROL'].write()

        ret = np.hstack((ret, self.chip['fifo'].get_data()))

        x = np.arange(175 * 4, dtype=np.uint8)
        x.dtype = np.uint32

        self.assertTrue(np.alltrue(ret == x))

        self.chip['fifo'].reset()

        self.chip['CONTROL']['COUNTER_EN'] = 1
        self.chip['CONTROL'].write()
        self.chip['CONTROL'].write()

        self.chip['CONTROL']['COUNTER_EN'] = 0
        self.chip['CONTROL'].write()
        self.chip['CONTROL'].write()
        self.chip['CONTROL'].write()

        ret = np.hstack((ret, self.chip['fifo'].get_data()))

        x = np.arange(245 * 4, dtype=np.uint8)
        x.dtype = np.uint32

        self.assertEqual(ret.tolist(), x.tolist())

    def test_full(self):
        self.chip['CONTROL']['COUNTER_EN'] = 1
        self.chip['CONTROL'].write()

        for _ in range(2):
            self.chip['fifo'].get_fifo_size()

        self.chip['CONTROL']['COUNTER_EN'] = 0
        self.chip['CONTROL'].write()

        for _ in range(10):
            self.chip['CONTROL'].write()

        size = self.chip['fifo'].get_fifo_size()
        self.assertEqual(size, 512)

        ret = self.chip['fifo'].get_data()
        ret = np.hstack((ret, self.chip['fifo'].get_data()))

        x = np.arange(203 * 4, dtype=np.uint8)
        x.dtype = np.uint32

        self.assertTrue(np.alltrue(ret == x))

    def test_overflow(self):
        self.chip['CONTROL']['COUNTER_EN'] = 1
        self.chip['CONTROL'].write()

        for _ in range(20):
            self.chip['fifo'].get_fifo_size()

        self.chip['CONTROL']['COUNTER_EN'] = 0
        self.chip['CONTROL'].write()

        for _ in range(10):
            self.chip['CONTROL'].write()

        ret = self.chip['fifo'].get_data()
        while(self.chip['fifo'].get_fifo_size()):
            ret = np.hstack((ret, self.chip['fifo'].get_data()))

        x = np.arange((128 + 1023) * 4, dtype=np.uint8)
        x.dtype = np.uint32

        self.assertTrue(np.alltrue(ret == x))

        self.chip['pulse'].set_delay(1)
        self.chip['pulse'].set_width(1)
        self.chip['pulse'].start()

        ret = self.chip['fifo'].get_data()
        x = np.arange((128 + 1023) * 4, (128 + 1023 + 1) * 4, dtype=np.uint8)
        x.dtype = np.uint32

        self.assertEqual(ret, x)

    def test_single(self):

        self.chip['pulse'].set_delay(1)
        self.chip['pulse'].set_width(1)
        self.chip['pulse'].start()

        self.assertEqual(self.chip['fifo'].get_data().tolist(), [0x03020100])

        self.chip['pulse'].start()

        self.assertEqual(self.chip['fifo'].get_data().tolist(), [0x07060504])

    def test_pattern(self):
        self.chip['PATTERN'] = 0xaa5555aa
        self.chip['PATTERN'].write()

        self.chip['CONTROL']['PATTERN_EN'] = 1
        self.chip['CONTROL'].write()
        self.chip['CONTROL']['PATTERN_EN'] = 0
        self.chip['CONTROL'].write()
        for _ in range(5):
            self.chip['CONTROL'].write()

        self.assertEqual(self.chip['fifo'].get_data().tolist(), [0xaa5555aa] * 35)

    def test_direct(self):
        self.chip['CONTROL']['COUNTER_DIRECT'] = 1
        self.chip['CONTROL'].write()

        size = 648
        base_data_addr = self.chip['fifo']._conf['base_data_addr']

        ret = self.chip['intf'].read(base_data_addr, size=size)
        ret = np.hstack((ret, self.chip['intf'].read(base_data_addr, size=size)))

        x = np.arange(size * 2, dtype=np.uint8)
        self.assertEqual(ret.tolist(), x.tolist())

    def test_continouse(self):
        self.chip['pulse'].set_delay(35)
        self.chip['pulse'].set_width(3)
        self.chip['pulse'].set_repeat(0)
        self.chip['pulse'].start()

        i = 0
        error = False
        for _ in range(100):
            ret = self.chip['fifo'].get_data()

            x = np.arange(i * 4, (i + ret.shape[0]) * 4, dtype=np.uint8)
            x.dtype = np.uint32

            i += ret.shape[0]

            ok = np.alltrue(ret == x)
            # print 'OK?', ok, ret.shape[0], i, k
            if not ok:
                error = True
                break

        self.assertFalse(error)

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()

if __name__ == '__main__':
    unittest.main()
