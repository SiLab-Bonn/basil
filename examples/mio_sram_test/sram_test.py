# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import time
from basil.dut import Dut

chip = Dut("sram_test.yaml")
chip.init()

ret = chip['fifo'].get_fifo_size()
print ret


