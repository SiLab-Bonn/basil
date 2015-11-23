# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import time
from basil.dut import Dut
import numpy as np

chip = Dut("sram_test.yaml")
chip.init()

chip['CONTROL']['COUNTER_EN'] = 1
chip['CONTROL'].write()

chip['CONTROL']['COUNTER_EN'] = 0
chip['CONTROL'].write()
        
ret = chip['fifo'].get_data()


x = np.arange(ret.shape[0]*4,  dtype=np.uint8)
x.dtype = np.uint32

print 'OK?', np.alltrue(ret == x)

