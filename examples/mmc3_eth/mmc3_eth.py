# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import time
from basil.dut import Dut

chip = Dut("mmc3_eth.yaml")
chip.init()

for i in range(8):
    chip['GPIO_LED']['LED'] = 0x01 << i
    chip['GPIO_LED'].write()
    print('LED:', chip['GPIO_LED'].get_data())
    time.sleep(1)
