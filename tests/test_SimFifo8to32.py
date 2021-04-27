#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest
import pytest
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
  - name      : FIFO
    type      : bram_fifo
    interface : INTF
    base_addr : 0x8000
    base_data_addr: 0x80000000
"""


class TestSimFifo8to32(unittest.TestCase):
    def __init__(self, testname, tb='test_SimFifo8to32.v', bus_drv='basil.utils.sim.BasilBusDriver', bus_split=False):
        super(TestSimFifo8to32, self).__init__(testname)
        self._test_tb = tb
        self._sim_bus = bus_drv
        self._bus_split_def = ()
        if bus_split is not False:
            if bus_split == 'sbus':
                self._bus_split_def = ("BASIL_SBUS",)
            elif bus_split == 'top':
                self._bus_split_def = ("BASIL_TOPSBUS",)

    def setUp(self):
        cocotb_compile_and_run(sim_files=[os.path.join(os.path.dirname(__file__), self._test_tb)], sim_bus=self._sim_bus, extra_defines=self._bus_split_def)

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    def test_io(self):
        for i in range(4):
            self.chip['INTF'].write(0x1000, [i])

        data = []
        iterations = 1000
        i = 0
        while not len(data) == 1:
            if i >= iterations:
                break
            data.extend(self.chip['FIFO'].get_data())
            i += 1
        assert data[0] == 50462976

        self.chip['INTF'].write(0x1000, [4, 5, 6, 7])

        data = []
        iterations = 1000
        i = 0
        while not len(data) == 1:
            if i >= iterations:
                break
            data.extend(self.chip['FIFO'].get_data())
            i += 1
        assert data[0] == 117835012

        self.chip['INTF'].write(0x1000, range(8))

        data = []
        iterations = 1000
        i = 0
        while not len(data) == 2:
            if i >= iterations:
                break
            data.extend(self.chip['FIFO'].get_data())
            i += 1
        assert data[0] == 50462976
        assert data[1] == 117835012

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()


# TODO: add sbus versions of used modules
# @pytest.mark.verilator
# class TestSimFifo8to32Sbus(TestSimFifo8to32):
#     def __init__(self, testname):
#         super(TestSimFifo8to32Sbus, self).__init__(testname=testname, tb='test_SimFifo8to32.v', bus_drv='basil.utils.sim.BasilSbusDriver', bus_split='sbus')


@pytest.mark.verilator
class TestSimFifo8to32SbusTop(TestSimFifo8to32):
    def __init__(self, testname):
        super(TestSimFifo8to32SbusTop, self).__init__(testname=testname, tb='test_SimFifo8to32.v', bus_drv='basil.utils.sim.BasilSbusDriver', bus_split='top')


if __name__ == '__main__':
    unittest.main()
