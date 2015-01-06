#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest
import yaml
import array
import time
import subprocess
from basil.dut import Dut
from basil.utils.sim.utils import cocotb_compile_and_run, cocotb_compile_clean
import numpy as np

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
    mem_bytes : 16

  - name      : spi_rx
    type      : fast_spi_rx
    interface : intf
    base_addr : 0x2000
   
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
class TestSimGpio(unittest.TestCase):
    def setUp(self):
        
        cocotb_compile_and_run(['test_SimSpi.v'])
        
        cnfg = yaml.load(cnfg_yaml)
        self.chip = Dut(cnfg)
        
        self.chip.init()
    
    def test_io(self):
        size = self.chip['spi'].get_size()
        self.chip['gpio'].reset()
        self.assertEqual(size, 16*8)
        
        self.chip['spi'].set_data(range(16))
        ret = self.chip['spi'].get_data(size=16, addr=0) #to read back what was written
        self.assertEqual(ret.tolist(), range(16))
        
        self.chip['spi'].set_data(range(16))
        ret = self.chip['spi'].get_data(addr=0) #to read back what was written
        self.assertEqual(ret.tolist(), range(16))
        
        self.chip['spi'].start()
        while(not self.chip['spi'].is_done()):
            time.sleep(0.1)
        
        ret = self.chip['spi'].get_data() # read back what was received (looped)
        self.assertEqual(ret.tolist(), range(16))
        
        #spi_rx
        ret = self.chip['spi_rx'].get_en()
        self.assertEqual(ret, False)
        
        self.chip['spi_rx'].set_en(True)
        ret = self.chip['spi_rx'].get_en()
        self.assertEqual(ret, True)
        
        self.chip['spi'].start()
        while(not self.chip['spi'].is_done()):
            time.sleep(0.1)
        
        ret = self.chip['fifo'].get_fifo_size()
        self.assertEqual(ret, 32)
        
        ret = self.chip['fifo'].get_data()
        
        data0 = ret.astype(np.uint8)
        data1 = np.right_shift(ret, 8).astype(np.uint8) 
        data = np.reshape(np.vstack((data1, data0)), -1, order='F') 
        self.assertEqual(data.tolist(), range(16))
        
    def tearDown(self):
        self.chip.close() # let it close connection and stop simulator
        cocotb_compile_clean()

if __name__ == '__main__':
    unittest.main()
