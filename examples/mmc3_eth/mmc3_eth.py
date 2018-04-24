# ------------------------------------------------------------
# SiTCP throughput test
# Reads data for a couple of seconds and displays the data rate
#
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import logging
import time

import numpy as np

from basil.dut import Dut


chip = Dut("mmc3_eth.yaml")
chip.init()

chip['CONTROL']['EN'] = 0
chip['CONTROL'].write()

logging.info("Starting data test ...")

chip['CONTROL']['EN'] = 1
chip['CONTROL'].write()

start = 0
for i in range(10):

    time.sleep(1)

    fifo_data = chip['FIFO'].get_data()
    data_size = len(fifo_data)
    data_gen = np.linspace(start, data_size - 1 + start, data_size, dtype=np.int32)

    comp = (fifo_data == data_gen)
    logging.info(str((i, " OK?:", comp.all(), float(32 * data_size) / pow(10, 6), "Mbit")))
    start += data_size

chip['CONTROL']['EN'] = 0  # stop data source
chip['CONTROL'].write()

logging.info("Starting speed test ...")

testduration = 10
total_len = 0
tick = 0
tick_old = 0
start_time = time.time()

chip['CONTROL']['EN'] = 1
chip['CONTROL'].write()

while time.time() - start_time < testduration:
    data = chip['FIFO'].get_data()
    total_len += len(data) * 4 * 8
    time.sleep(0.01)
    tick = int(time.time() - start_time)
    if tick != tick_old:
        logging.info("Time: %f s" % (time.time() - start_time))
        tick_old = tick

chip['CONTROL']['EN'] = 0x0  # stop data source
chip['CONTROL'].write()

logging.info(str(('Bytes received:', total_len, '  data rate:', round((total_len / 1e6 / testduration), 2), ' Mbits/s')))
