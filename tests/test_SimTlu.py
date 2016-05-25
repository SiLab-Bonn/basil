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
  - name      : gpio
    type      : gpio
    interface : intf
    base_addr : 0x0000
    size      : 8

  - name      : tlu
    type      : tlu
    interface : intf
    base_addr : 0x8200

  - name      : sram
    type      : sram_fifo
    interface : intf
    base_addr : 0x8100
    base_data_addr : 0x80000000

registers:
  - name        : CONTROL
    type        : StdRegister
    hw_driver   : gpio
    size        : 8
    fields:
      - name    : ENABLE
        size    : 1
        offset  : 0
"""


class TestSimTlu(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), 'test_SimTlu.v')])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    def test_simple_trigger_veto(self):
        self.chip['tlu'].TRIGGER_COUNTER = 0
        self.chip['tlu'].TRIGGER_MODE = 0
        self.chip['tlu'].TRIGGER_SELECT = 2
        self.chip['tlu'].TRIGGER_VETO_SELECT = 2
#         self.chip['CONTROL']['ENABLE'] = 1
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

        self.chip['gpio'].set_data([0x07])  # trigger + veto
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

        self.chip['gpio'].set_data([0x03])  # trigger
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

#         self.chip['CONTROL']['ENABLE'] = 0
        self.chip['gpio'].set_data([0x00])

        self.assertEqual(self.chip['sram'].get_fifo_int_size(), 1)
        self.assertEqual(self.chip['tlu'].TRIGGER_COUNTER, 1)

        data = self.chip['sram'].get_data()
        self.assertEqual(data[0], 0x80000000 + 0)

    def test_simple_trigger_veto_disabled(self):
        self.chip['tlu'].TRIGGER_COUNTER = 0
        self.chip['tlu'].TRIGGER_MODE = 0
        self.chip['tlu'].TRIGGER_SELECT = 2
        self.chip['tlu'].TRIGGER_VETO_SELECT = 252
#         self.chip['CONTROL']['ENABLE'] = 1
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU
        self.chip['gpio'].set_data([0x01])  # issue a second time, wait for reset

        self.chip['gpio'].set_data([0x07])  # trigger + veto
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

        self.chip['gpio'].set_data([0x03])  # trigger
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

#         self.chip['CONTROL']['ENABLE'] = 0
        self.chip['gpio'].set_data([0x00])

        self.assertEqual(self.chip['sram'].get_fifo_int_size(), 2)
        self.assertEqual(self.chip['tlu'].TRIGGER_COUNTER, 2)

        data = self.chip['sram'].get_data()
        self.assertEqual(data[0], 0x80000000 + 0)
        self.assertEqual(data[1], 0x80000000 + 1)

    def test_simple_trigger_threshold(self):
        self.chip['tlu'].TRIGGER_COUNTER = 0
        self.chip['tlu'].TRIGGER_MODE = 0
        self.chip['tlu'].TRIGGER_SELECT = 4  # select single pulse trigger
        self.chip['tlu'].TRIGGER_THRESHOLD = 1  # at least two clock cycles
#         self.chip['CONTROL']['ENABLE'] = 1
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU
        self.chip['gpio'].set_data([0x01])  # issue a second time, wait for reset

        self.chip['gpio'].set_data([0x03])  # trigger
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

        self.chip['gpio'].set_data([0x03])  # trigger
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

#         self.chip['CONTROL']['ENABLE'] = 0
        self.chip['gpio'].set_data([0x00])

        self.assertEqual(self.chip['sram'].get_fifo_int_size(), 2)
        self.assertEqual(self.chip['tlu'].TRIGGER_COUNTER, 2)

        data = self.chip['sram'].get_data()
        self.assertEqual(data[0], 0x80000000 + 0)
        self.assertEqual(data[1], 0x80000000 + 1)

        self.chip['tlu'].TRIGGER_COUNTER = 0
        self.chip['tlu'].TRIGGER_THRESHOLD = 2  # at least two clock cycles

        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

        self.chip['gpio'].set_data([0x03])  # trigger
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

        self.chip['gpio'].set_data([0x03])  # trigger
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

#         self.chip['CONTROL']['ENABLE'] = 0
        self.chip['gpio'].set_data([0x00])

        self.assertEqual(self.chip['sram'].get_fifo_int_size(), 0)
        self.assertEqual(self.chip['tlu'].TRIGGER_COUNTER, 0)

    def test_simple_trigger_max_triggers(self):
        self.chip['tlu'].TRIGGER_COUNTER = 0
        self.chip['tlu'].MAX_TRIGGERS = 2
        self.chip['tlu'].TRIGGER_MODE = 0
        self.chip['tlu'].TRIGGER_SELECT = 2
        self.chip['tlu'].TRIGGER_VETO_SELECT = 252
#         self.chip['CONTROL']['ENABLE'] = 1
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

        self.chip['gpio'].set_data([0x03])  # trigger
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

        self.chip['gpio'].set_data([0x03])  # trigger
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

        self.chip['gpio'].set_data([0x03])  # trigger
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

        self.chip['gpio'].set_data([0x03])  # trigger
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

#         self.chip['CONTROL']['ENABLE'] = 0
        self.chip['gpio'].set_data([0x00])

        self.assertEqual(self.chip['sram'].get_fifo_int_size(), 2)
        self.assertEqual(self.chip['tlu'].TRIGGER_COUNTER, 2)

        data = self.chip['sram'].get_data()
        self.assertEqual(data[0], 0x80000000 + 0)
        self.assertEqual(data[1], 0x80000000 + 1)

    def test_simple_trigger(self):
        self.chip['tlu'].TRIGGER_COUNTER = 10
        self.chip['tlu'].TRIGGER_MODE = 0
        self.chip['tlu'].TRIGGER_SELECT = 1
        self.chip['tlu'].TRIGGER_VETO_SELECT = 0
#         self.chip['CONTROL']['ENABLE'] = 1
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

        readings = 0
        while(self.chip['sram'].get_fifo_int_size() < 4 and readings < 1000):
            readings += 1

#         self.chip['CONTROL']['ENABLE'] = 0
        self.chip['gpio'].set_data([0x00])

        self.assertGreaterEqual(self.chip['sram'].get_fifo_int_size(), 4)
        self.assertGreaterEqual(self.chip['tlu'].TRIGGER_COUNTER, 14)

        data = self.chip['sram'].get_data()
        self.assertEqual(data[0], 0x80000000 + 10)
        self.assertEqual(data[1], 0x80000000 + 11)
        self.assertEqual(data[2], 0x80000000 + 12)
        self.assertEqual(data[3], 0x80000000 + 13)

    def test_tlu_trigger_handshake(self):
        self.chip['tlu'].TRIGGER_COUNTER = 0
        self.chip['tlu'].TRIGGER_MODE = 3
        self.chip['tlu'].TRIGGER_VETO_SELECT = 255
        self.chip['tlu'].EN_TLU_VETO = 0
#         self.chip['tlu'].DATA_FORMAT = 2
#         self.chip['tlu'].TRIGGER_LOW_TIMEOUT = 5
#         self.chip['tlu'].TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES = 0
#         self.chip['tlu'].HANDSHAKE_BUSY_VETO_WAIT_CYCLES = 0
#         self.chip['CONTROL']['ENABLE'] = 1
        self.chip['gpio'].set_data([0x01])

        readings = 0
        while(self.chip['sram'].get_fifo_int_size() < 4 and readings < 1000):
            readings += 1

#         self.chip['CONTROL']['ENABLE'] = 0
        self.chip['gpio'].set_data([0x00])

        self.assertGreaterEqual(self.chip['sram'].get_fifo_int_size(), 4)
        self.assertGreaterEqual(self.chip['tlu'].TRIGGER_COUNTER, 4)
        self.assertGreaterEqual(self.chip['tlu'].CURRENT_TLU_TRIGGER_NUMBER, 3)

        data = self.chip['sram'].get_data()
        self.assertEqual(data[0], 0x80000000)
        self.assertEqual(data[1], 0x80000001)
        self.assertEqual(data[2], 0x80000002)
        self.assertEqual(data[3], 0x80000003)

    def test_tlu_trigger_handshake_veto(self):
        self.chip['tlu'].TRIGGER_COUNTER = 0
        self.chip['tlu'].TRIGGER_MODE = 3
        self.chip['tlu'].TRIGGER_VETO_SELECT = 1
        self.chip['tlu'].EN_TLU_VETO = 1
#         self.chip['CONTROL']['ENABLE'] = 1
        self.chip['gpio'].set_data([0x01])  # ext enable trigger/TLU

        readings = 0
        while(self.chip['sram'].get_fifo_int_size() == 0 and readings < 1000):
            readings += 1

        self.assertEqual(self.chip['sram'].get_fifo_int_size(), 0)
        self.assertEqual(self.chip['tlu'].TRIGGER_COUNTER, 0)
        self.assertEqual(self.chip['tlu'].CURRENT_TLU_TRIGGER_NUMBER, 0)

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()

if __name__ == '__main__':
    unittest.main()
