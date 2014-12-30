#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest
import subprocess
import os
import time
import yaml
from basil.dut import Dut
from basil.utils.sim.utils import cocotb_makefile

class TestSimGpio(unittest.TestCase):
    def setUp(self):

        #this is compile files it will not run simulation -> error
        file = open('Makefile','w')
        file.write(cocotb_makefile(['test_SimGpio.v'], top_level='none'))
        file.close()
        subprocess.call("make", shell=True) 
        
        file = open('Makefile','w')
        file.write(cocotb_makefile(['test_SimGpio.v']))
        file.close()
        subprocess.Popen(['make']) #run in background
        time.sleep(1)
        
        stream = open("test_SimGpio.yaml", 'r')
        cnfg = yaml.load(stream)
        self.chip = Dut(cnfg)
        self.chip.init()
        
    def test_write(self):
        
        self.chip['PWR']['EN_VD1'] = 1
        self.chip['PWR']['EN_VD2'] = 1
        self.chip['PWR']['EN_VA1'] = 0
        self.chip['PWR']['EN_VA2'] = 1
        self.chip['PWR'].write()
        
        ret = self.chip['gpio'].get_data()
        
        self.assertEqual(0x0e, ret[0])
    
    def tearDown(self):
        self.chip.close() # let it close connection and stop simulator
        time.sleep(1)
        subprocess.call('make clean', shell=True)
        subprocess.call('rm -f Makefile', shell=True)

if __name__ == '__main__':
    unittest.main()
