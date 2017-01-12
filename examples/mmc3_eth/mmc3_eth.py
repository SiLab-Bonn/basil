# ------------------------------------------------------------
# SiTCP throughput test
# Reads data for a couple of seconds and displays the data rate
#
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import time
from basil.dut import Dut

chip = Dut("mmc3_eth.yaml")
chip.init()

chip['GPIO_LED']['LED'] = 0x01  #start data source

testduration = 10
total_len = 0
tick = 0
tick_old = 0
start_time = time.time()

while time.time() - start_time < testduration:
    data = chip['SRAM'].get_data()
    total_len += len(data)*4*8
    time.sleep(0.01)
    tick = int(time.time() - start_time)
    if tick != tick_old:
        print tick
        tick_old = tick

print ('Bytes received:', total_len, '  data rate:', round((total_len/1e6/testduration),2), ' Mbit/s')

chip['GPIO_LED']['LED'] = 0x00  #stop data source
