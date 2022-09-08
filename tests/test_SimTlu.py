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
  - name      : GPIO
    type      : gpio
    interface : INTF
    base_addr : 0x0000
    size      : 8

  - name      : TLU
    type      : tlu
    interface : INTF
    base_addr : 0x8200

  - name      : FIFO
    type      : bram_fifo
    interface : INTF
    base_addr : 0x8100
    base_data_addr : 0x80000000

registers:
  - name        : CONTROL
    type        : StdRegister
    hw_driver   : GPIO
    size        : 8
    fields:
      - name    : ENABLE
        size    : 1
        offset  : 0
"""


class TestSimTlu(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run(
            [os.path.join(os.path.dirname(__file__), 'test_SimTlu.v')])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    def test_simple_trigger_veto(self):
        self.chip['TLU'].TRIGGER_COUNTER = 0
        self.chip['TLU'].TRIGGER_MODE = 0
        self.chip['TLU'].TRIGGER_SELECT = 2
        self.chip['TLU'].TRIGGER_VETO_SELECT = 2
        self.chip['TLU'].TRIGGER_ENABLE = True

        self.chip['GPIO'].set_data([0x06])  # assert trigger and veto signal
        self.chip['GPIO'].set_data([0x00])  # de-assert trigger and veto signal

        self.chip['GPIO'].set_data([0x02])  # assert trigger signal
        self.chip['GPIO'].set_data([0x00])  # de-assert trigger signal

        self.chip['TLU'].TRIGGER_ENABLE = False

        self.assertEqual(self.chip['FIFO'].get_FIFO_INT_SIZE(), 1)
        self.assertEqual(self.chip['TLU'].TRIGGER_COUNTER, 1)

        data = self.chip['FIFO'].get_data()
        self.assertEqual(data[0], 0x80000000 + 0)

    def test_simple_trigger_veto_disabled(self):
        self.chip['TLU'].TRIGGER_COUNTER = 0
        self.chip['TLU'].TRIGGER_MODE = 0
        self.chip['TLU'].TRIGGER_SELECT = 2
        self.chip['TLU'].TRIGGER_VETO_SELECT = 252
        self.chip['TLU'].TRIGGER_ENABLE = True

        self.chip['GPIO'].set_data([0x06])  # assert trigger and veto signal
        self.chip['GPIO'].set_data([0x00])  # de-assert trigger and veto signal

        self.chip['GPIO'].set_data([0x02])  # assert trigger signal
        self.chip['GPIO'].set_data([0x00])  # de-assert trigger signal

        self.chip['TLU'].TRIGGER_ENABLE = False

        self.assertEqual(self.chip['FIFO'].get_FIFO_INT_SIZE(), 2)
        self.assertEqual(self.chip['TLU'].TRIGGER_COUNTER, 2)

        data = self.chip['FIFO'].get_data()
        self.assertEqual(data[0], 0x80000000 + 0)
        self.assertEqual(data[1], 0x80000000 + 1)

    def test_simple_trigger_threshold(self):
        self.chip['TLU'].TRIGGER_COUNTER = 0
        self.chip['TLU'].TRIGGER_MODE = 0
        # select short trigger (one clock cycle)
        self.chip['TLU'].TRIGGER_SELECT = 4
        self.chip['TLU'].TRIGGER_THRESHOLD = 1  # at least one clock cycle
        self.chip['TLU'].TRIGGER_ENABLE = True

        self.chip['GPIO'].set_data([0x02])  # assert trigger signal
        self.chip['GPIO'].set_data([0x00])  # de-assert trigger signal

        self.chip['GPIO'].set_data([0x02])  # assert trigger signal
        self.chip['GPIO'].set_data([0x00])  # de-assert trigger signal

        self.chip['TLU'].TRIGGER_ENABLE = False

        self.assertEqual(self.chip['FIFO'].get_FIFO_INT_SIZE(), 2)
        self.assertEqual(self.chip['TLU'].TRIGGER_COUNTER, 2)

        data = self.chip['FIFO'].get_data()
        self.assertEqual(data[0], 0x80000000 + 0)
        self.assertEqual(data[1], 0x80000000 + 1)

        self.chip['TLU'].TRIGGER_COUNTER = 0
        self.chip['TLU'].TRIGGER_THRESHOLD = 2  # at least two clock cycles
        self.chip['TLU'].TRIGGER_ENABLE = True

        self.chip['GPIO'].set_data([0x02])  # assert trigger signal
        self.chip['GPIO'].set_data([0x00])  # de-assert trigger signal

        self.chip['GPIO'].set_data([0x02])  # assert trigger signal
        self.chip['GPIO'].set_data([0x00])  # de-assert trigger signal

        self.chip['TLU'].TRIGGER_ENABLE = False

        self.assertEqual(self.chip['FIFO'].get_FIFO_INT_SIZE(), 0)
        self.assertEqual(self.chip['TLU'].TRIGGER_COUNTER, 0)

    def test_simple_trigger_max_triggers(self):
        self.chip['TLU'].TRIGGER_COUNTER = 0
        self.chip['TLU'].MAX_TRIGGERS = 2  # max. 2 triggers
        self.chip['TLU'].TRIGGER_MODE = 0
        self.chip['TLU'].TRIGGER_SELECT = 2
        self.chip['TLU'].TRIGGER_VETO_SELECT = 252
        self.chip['TLU'].TRIGGER_ENABLE = True

        self.chip['GPIO'].set_data([0x02])  # assert trigger signal
        self.chip['GPIO'].set_data([0x00])  # de-assert trigger signal

        self.chip['GPIO'].set_data([0x02])  # assert trigger signal
        self.chip['GPIO'].set_data([0x00])  # de-assert trigger signal

        self.chip['GPIO'].set_data([0x02])  # assert trigger signal
        self.chip['GPIO'].set_data([0x00])  # de-assert trigger signal

        self.chip['GPIO'].set_data([0x02])  # assert trigger signal
        self.chip['GPIO'].set_data([0x00])  # de-assert trigger signal

        self.chip['TLU'].TRIGGER_ENABLE = False

        self.assertEqual(self.chip['FIFO'].get_FIFO_INT_SIZE(), 2)
        self.assertEqual(self.chip['TLU'].TRIGGER_COUNTER, 2)

        data = self.chip['FIFO'].get_data()
        self.assertEqual(data[0], 0x80000000 + 0)
        self.assertEqual(data[1], 0x80000000 + 1)

    def test_simple_trigger(self):
        self.chip['TLU'].TRIGGER_COUNTER = 10
        self.chip['TLU'].TRIGGER_MODE = 0
        self.chip['TLU'].TRIGGER_SELECT = 1
        self.chip['TLU'].TRIGGER_VETO_SELECT = 0
        self.chip['TLU'].TRIGGER_ENABLE = True
        self.chip['GPIO'].set_data([0x01])  # enable trigger/TLU FSM

        readings = 0
        while (self.chip['FIFO'].get_FIFO_INT_SIZE() < 4 and readings < 10000):
            readings += 1

        self.chip['GPIO'].set_data([0x00])  # disable trigger/TLU FSM
        self.chip['TLU'].TRIGGER_ENABLE = False

        self.assertGreaterEqual(self.chip['FIFO'].get_FIFO_INT_SIZE(), 4)
        self.assertGreaterEqual(self.chip['TLU'].TRIGGER_COUNTER, 14)

        data = self.chip['FIFO'].get_data()
        self.assertEqual(data[0], 0x80000000 + 10)
        self.assertEqual(data[1], 0x80000000 + 11)
        self.assertEqual(data[2], 0x80000000 + 12)
        self.assertEqual(data[3], 0x80000000 + 13)

    def test_manual_soft_trigger(self):
        self.chip['TLU'].TRIGGER_COUNTER = 10
        self.chip['TLU'].TRIGGER_MODE = 0
        self.chip['TLU'].TRIGGER_SELECT = 0
        self.chip['TLU'].TRIGGER_VETO_SELECT = 0
        self.chip['TLU'].TRIGGER_ENABLE = True

        for i in range(4):
            self.chip['TLU'].SOFT_TRIGGER = 1

            readings = 0
            while (self.chip['FIFO'].get_FIFO_INT_SIZE() <= i and readings < 10000):
                readings += 1

        self.chip['TLU'].TRIGGER_ENABLE = False
        self.assertGreaterEqual(self.chip['FIFO'].get_FIFO_INT_SIZE(), 4)
        self.assertGreaterEqual(self.chip['TLU'].TRIGGER_COUNTER, 14)

        data = self.chip['FIFO'].get_data()
        self.assertEqual(data[0], 0x80000000 + 10)
        self.assertEqual(data[1], 0x80000000 + 11)
        self.assertEqual(data[2], 0x80000000 + 12)
        self.assertEqual(data[3], 0x80000000 + 13)

    def test_tlu_trigger_handshake(self):
        self.chip['TLU'].TRIGGER_COUNTER = 0
        self.chip['TLU'].TRIGGER_MODE = 3
        # not used when EN_TLU_VETO is False
        self.chip['TLU'].TRIGGER_VETO_SELECT = 255
        self.chip['TLU'].EN_TLU_VETO = 0
#         self.chip['TLU'].DATA_FORMAT = 2
#         self.chip['TLU'].TRIGGER_LOW_TIMEOUT = 5
#         self.chip['TLU'].TRIGGER_HANDSHAKE_ACCEPT_WAIT_CYCLES = 0
#         self.chip['TLU'].HANDSHAKE_BUSY_VETO_WAIT_CYCLES = 0
        self.chip['TLU'].TRIGGER_ENABLE = True
        self.chip['GPIO'].set_data([0x01])

        readings = 0
        while (self.chip['FIFO'].get_FIFO_INT_SIZE() < 4 and readings < 1000):
            readings += 1

        self.chip['GPIO'].set_data([0x00])  # disable trigger/TLU FSM
        self.chip['TLU'].TRIGGER_ENABLE = False

        self.assertGreaterEqual(self.chip['FIFO'].get_FIFO_INT_SIZE(), 4)
        self.assertGreaterEqual(self.chip['TLU'].TRIGGER_COUNTER, 4)
        self.assertGreaterEqual(self.chip['TLU'].CURRENT_TLU_TRIGGER_NUMBER, 3)

        data = self.chip['FIFO'].get_data()
        self.assertEqual(data[0], 0x80000000)
        self.assertEqual(data[1], 0x80000001)
        self.assertEqual(data[2], 0x80000002)
        self.assertEqual(data[3], 0x80000003)

    def test_tlu_trigger_handshake_veto(self):
        self.chip['TLU'].TRIGGER_COUNTER = 0
        self.chip['TLU'].TRIGGER_MODE = 3
        # used when EN_TLU_VETO is True
        self.chip['TLU'].TRIGGER_VETO_SELECT = 255
        self.chip['TLU'].EN_TLU_VETO = 1
        self.chip['TLU'].TRIGGER_ENABLE = True
        self.chip['GPIO'].set_data([0x01])  # enable trigger/TLU FSM

        readings = 0
        while (self.chip['FIFO'].get_FIFO_INT_SIZE() == 0 and readings < 1000):
            readings += 1

        self.assertEqual(self.chip['FIFO'].get_FIFO_INT_SIZE(), 0)
        self.assertEqual(self.chip['TLU'].TRIGGER_COUNTER, 0)
        self.assertEqual(self.chip['TLU'].CURRENT_TLU_TRIGGER_NUMBER, 0)

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()


if __name__ == '__main__':
    unittest.main()
