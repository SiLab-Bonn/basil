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
import time

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
    size      : 64

  - name      : timestamp
    type      : timestamp
    interface : INTF
    base_addr : 0x1000


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
  - name        : timestamp_value
    type        : StdRegister
    hw_driver   : GPIO
    size        : 64
    fields:
      - name    : OUT3
        size    : 16
        offset  : 63
      - name    : OUT2
        size    : 24
        offset  : 47
      - name    : OUT1
        size    : 24
        offset  : 23
"""


class TestSimTimestamp(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), 'test_SimTimestamp.v')])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()
        self.debug=0

    def test_io(self):
        self.chip['timestamp'].reset()
        self.chip['GPIO'].reset()

        self.chip['FIFO'].reset()
        ret = self.chip['FIFO'].get_FIFO_SIZE()
        self.assertEqual(ret, 0)

        # trigger timestamp
        self.chip['PULSE_GEN'].set_DELAY(0x105)
        self.chip['PULSE_GEN'].set_WIDTH(10)
        self.chip['PULSE_GEN'].set_REPEAT(1)
        self.assertEqual(self.chip['PULSE_GEN'].get_DELAY(), 0x105)
        self.assertEqual(self.chip['PULSE_GEN'].get_WIDTH(), 10)
        self.assertEqual(self.chip['PULSE_GEN'].get_REPEAT(), 1)

        self.chip['PULSE_GEN'].start()
        while(not self.chip['PULSE_GEN'].is_ready):
            pass
        
        ## get data from FIFO
        ret = self.chip['FIFO'].get_FIFO_SIZE()
        self.assertEqual(ret, 3*4)

        ret = self.chip['FIFO'].get_data()
        self.assertEqual(len(ret), 3)

        ## check with GPIO
        ret2 = self.chip['GPIO'].get_data()
        self.assertEqual(len(ret2), 8)

        for i,r in enumerate(ret):
            self.assertEqual(r&0xF0000000, 0x50000000)
            self.assertEqual(r&0xF000000, 0x1000000*(3-i))

        if self.debug:
            print hex(ret[0]&0xFFFFFF) ,hex(0x10000*ret2[5]+0x100*ret2[6]+ret2[7])
            print hex(ret[1]&0xFFFFFF) ,hex(0x10000*ret2[2]+0x100*ret2[3]+ret2[4])
            print hex(ret[2]&0xFFFFFF) ,hex(0x100*ret2[0]+ret2[1])

        self.assertEqual(ret[2]&0xFFFFFF,0x10000*ret2[5]+0x100*ret2[6]+ret2[7])
        self.assertEqual(ret[1]&0xFFFFFF,0x10000*ret2[2]+0x100*ret2[3]+ret2[4])
        self.assertEqual(ret[1]&0xFFFFFF,0x100*ret2[0]+ret2[1])

    
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
        time.sleep(5)
        cocotb_compile_clean()

if __name__ == '__main__':
    unittest.main()
