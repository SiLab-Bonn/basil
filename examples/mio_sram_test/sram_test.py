# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import numpy as np

from basil.dut import Dut


chip = Dut("sram_test.yaml")
chip.init()


def test_sram(count=10000):
    i = 0
    error = 0

    for k in range(count):

        # chip['CONTROL']['COUNTER_EN'] = 1
        # chip['CONTROL'].write()
        # chip['CONTROL']['COUNTER_EN'] = 0
        # chip['CONTROL'].write()

        chip['pulse'].set_delay(1)
        chip['pulse'].set_width((k + 1) % 3000)
        chip['pulse'].start()

        ret = chip['fifo'].get_data()

        x = np.arange(i * 4, (i + ret.shape[0]) * 4, dtype=np.uint8)
        x.dtype = np.uint32
        i += ret.shape[0]

        ok = np.alltrue(ret == x)

        # print 'OK?', ok, ret.shape[0], i, k, chip['fifo'].get_read_error_counter()
        if not ok:
            error += 1

    return error


def test_direct(count=10000):
    i = 0
    error = 0

    for k in range(count):

        chip['CONTROL']['COUNTER_DIRECT'] = 1
        chip['CONTROL'].write()

        size = (k + 1) % 5000
        base_data_addr = chip['fifo']._conf['base_data_addr']

        ret = chip['intf'].read(base_data_addr, size=size)

        x = np.arange(i, i + size, dtype=np.uint8)
        i += size

        ok = np.alltrue(ret == x)

        # if k % 1000 == 1:
        #    print k, error

        if not ok:
            error += 1

    chip['CONTROL']['COUNTER_DIRECT'] = 0
    chip['CONTROL'].write()
    return error


def test_register(count=10000):
    error = 0
    for i in range(count):
        data = np.array([(i * 4 + 3) % 255, (i * 4 + 2) % 255, (i * 4 + 1) % 255, (i * 4) % 255])
        chip['gpio_pattern_drv'].set_data(data)
        ret = chip['gpio_pattern_drv'].get_data()

        ok = np.alltrue(data == ret)

        if not ok:
            error += 1

    return error


if __name__ == "__main__":
    print 'test_register ...', 'errors:', test_register()
    print 'test_direct ...', 'errors:', test_direct()
    print 'test_sram ...', 'errors:', test_sram()
