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


i = 0
error = 0

if True:
    for k in range(10000):

        # chip['CONTROL']['COUNTER_EN'] = 1
        # chip['CONTROL'].write()
        # chip['CONTROL']['COUNTER_EN'] = 0
        # chip['CONTROL'].write()

        chip['pulse'].set_delay(1)
        chip['pulse'].set_width((k + 1) % 3000)
        # chip['pulse'].set_width(4000)

        chip['pulse'].start()

        # time.sleep(0.01)

        ret = chip['fifo'].get_data()

        x = np.arange(i * 4, (i + ret.shape[0]) * 4, dtype=np.uint8)
        x.dtype = np.uint32
        i += ret.shape[0]

        ok = np.alltrue(ret == x)
        print 'OK?', ok, ret.shape[0], i, k, chip['fifo'].get_read_error_counter()
        if not ok:
            error += 1
            print 'ret', ret, hex(ret[0]), hex(ret[-60]), hex(ret[-3]), hex(ret[-2]), hex(ret[-1])
            print 'x', x, hex(x[0]), hex(x[-2]), hex(x[-1])
            break

    print 'error?', error


if False:
    for k in range(1000000):

        chip['CONTROL']['COUNTER_DIRECT'] = 1
        chip['CONTROL'].write()

        size = (k + 1) % 5000
        base_data_addr = chip['fifo']._conf['base_data_addr']

        ret = chip['intf'].read(base_data_addr, size=size)

        x = np.arange(i, i + size, dtype=np.uint8)
        i += size

        ok = np.alltrue(ret == x)
        if k % 1000 == 1:
            print k, error

        if not ok:
            print 'OK?', ok, size, k
            error += 1

    print 'error?', error
