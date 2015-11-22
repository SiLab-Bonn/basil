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
    
        cocotb_compile_and_run(
            [get_basil_dir()+'/firmware/modules/gpio/gpio.v', 
            get_basil_dir()+'/firmware/modules/utils/reset_gen.v', 
            get_basil_dir()+'/firmware/modules/utils/bus_to_ip.v', 
            get_basil_dir()+'/firmware/modules/rrp_arbiter/rrp_arbiter.v', 
            get_basil_dir()+'/firmware/modules/utils/ODDR_sim.v', 
            get_basil_dir()+'/firmware/modules/utils/generic_fifo.v', 
            get_basil_dir()+'/firmware/modules/sram_fifo/sram_fifo_core.v', get_basil_dir()+'/firmware/modules/sram_fifo/sram_fifo.v', 
            os.path.dirname(__file__) + '/../firmware/src/sram_test.v',
            os.path.dirname(__file__) + '/../tests/tb.v'], 
            top_level = 'tb',
            sim_bus='basil.utils.sim.SiLibUsbBusDriver'
            )
    
        cnfg = {}

        with open(os.path.dirname(__file__) + '/../sram_test.yaml', 'r') as f:
            cnfg = yaml.load(f)
            
        # change to simulation interface
        cnfg['transfer_layer'][0]['type'] = 'SiSim' 

        self.chip = Dut(cnfg)
        self.chip.init()

    def test(self):
        
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
        
        ret = np.hstack((ret,self.chip['fifo'].get_data())) 

        x = np.arange(175*4,  dtype=np.uint8)
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
        
        ret = np.hstack((ret,self.chip['fifo'].get_data())) 
        
        x = np.arange(245*4,  dtype=np.uint8)
        x.dtype = np.uint32
        
        self.assertTrue(np.alltrue(ret == x))
        
    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()

if __name__ == '__main__':
    unittest.main()
      
