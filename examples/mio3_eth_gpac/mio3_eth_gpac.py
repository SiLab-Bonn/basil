# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.dut import Dut

chip = Dut("mio3_eth_gpac.yaml")
chip.init()

chip['VDD'].set_current_limit(80, unit='mA')
chip['VDD'].set_voltage(1.3, unit='V')
chip['VDD'].set_enable(True)

chip['CONTROL']['LED'] = 0xa5

chip['CONTROL'].write()

