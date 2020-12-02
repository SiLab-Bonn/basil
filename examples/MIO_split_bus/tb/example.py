# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import time
from basil.dut import Dut

chip = Dut("example.yaml")
chip.init()

for i in range(5):
    chip['GPIO_LED']['LED'] = 0x01 << i
    chip['GPIO_LED'].write()
    time.sleep(1)
