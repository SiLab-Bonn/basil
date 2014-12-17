#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import yaml
import numpy as np
import time

from basil.dut import Dut  

stream = open("lx9.yaml", 'r')
cnfg = yaml.load(stream)
chip = Dut(cnfg)
chip.init()

chip['GPIO']['LED1'] = 1
chip['GPIO']['LED2'] = 1
chip['GPIO']['LED3'] = 0
chip['GPIO']['LED4'] = 0
chip['GPIO'].write()