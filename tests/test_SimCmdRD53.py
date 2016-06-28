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
from time import sleep


cnfg_yaml = """
transfer_layer:
  - name  : intf
    type  : SiSim
    init:
        host : localhost
        port  : 12345

hw_drivers:
  - name      : cmd
    type      : cmd_rd53
    interface : intf
    base_addr : 0x0000

"""


class TestSimSpi(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), 'test_SimCmdRD53.v')])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    def test_io(self):

        self.chip['cmd'].reset()
        self.chip['cmd'].set_syncmode(0)    #0: Send sync patterns forever, 1: Send sync pattern only once after timeout

        print('Mem size=',self.chip['cmd'].get_mem_size())
        print('CMD size=',self.chip['cmd'].get_cmd_size())

        memsize = self.chip['cmd'].get_mem_size()

        self.chip['cmd'].start()

        #load 256 Bytes to block memory, read back and compare
        indata = list(range(256))
        self.chip['cmd'].set_data(indata)
        ret = self.chip['cmd'].get_data(size=len(indata))
        self.assertEqual(ret.tolist(), indata)

        #set memory range and start
        self.chip['cmd'].set_size(64)
        self.chip['cmd'].start()
        while(not self.chip['cmd'].is_done()):
             pass

        #set memory range and start
        self.chip['cmd'].set_size(32)
        self.chip['cmd'].start()
        while(not self.chip['cmd'].is_done()):
             pass


    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()

if __name__ == '__main__':
    unittest.main()
