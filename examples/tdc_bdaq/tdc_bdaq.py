# ------------------------------------------------------------
# SiTCP throughput test
# Reads data for a couple of seconds and displays the data rate
#
# Copyright (c) All rights reserved
# SiLab, Physics Institute, University of Bonn
# ------------------------------------------------------------
#
import logging
import time

import numpy as np
import matplotlib.pyplot as plt

from basil.dut import Dut


def disassemble_tdc_word(word):
#       TRIGGERED_WORD = 3'd0;
#       RISING_WORD = 3'd1;
#       FALLING_WORD = 3'd2;
#       TIMESTAMP_WORD = 3'd3;
#       COUNTER_OVERFLOW_WORD = 3'd4;
#       CALIB_WORD = 3'd5;
#       MISS_WORD = 3'd6;
#       RESET_WORD = 3'd7;



    word_type_codes = {0 : 'TRIGGERED', 
                     1 : 'RISING',
                     2 : 'FALLING',
                     3 : 'TIMESTAMP',
                     4 : 'OVFLOW',
                     5 : 'CALIB',
                     6 : 'MISS',
                     7 : 'RST'}
    # Shift away the 32 - 7 data bits and grab 3 bit word type
    return {'source_id' : (word >> (32 - 4)),
            'word_type' : word_type_codes[(word >> (32 - 7)) & 0b111],
            'tdl_value' : word & 0b1111111,
            'fine_value' : (word >> 7) & 0b11,
            'corse_value' : (word >> 9) & 0xFFFF}



chip = Dut("tdc_bdaq.yaml")
chip.init()
chip['TDL_TDC'].reset()


chip['CONTROL']['EN'] = 0
chip['CONTROL'].write()

logging.info("Starting data test ...")

chip['CONTROL']['EN'] = 1
chip['CONTROL'].write()

print(chip['TDL_TDC'].get_en_extern())
print(chip['TDL_TDC'].get_arming())
chip['TDL_TDC'].EN_TRIGGER_DIST = 1
chip['TDL_TDC'].ENABLE = 1
chip['TDL_TDC'].EN_CALIBRATION_MOD = 1
print(chip['TDL_TDC'].EN_CALIBRATION_MOD)

collected_data = np.empty(0, dtype=np.uint32)
testduration = 2
start_time = time.time()

while time.time() - start_time < testduration:
    time.sleep(.01)

    fifo_data = chip['FIFO'].get_data()
    print(fifo_data)
    data_size = len(fifo_data)
    collected_data = np.concatenate((collected_data,fifo_data), dtype=np.uint32)
    for word_int in fifo_data[-4:] :
        word_dict = disassemble_tdc_word(word_int)
        print(word_dict)



chip['CONTROL']['EN'] = 0  # stop data source
chip['CONTROL'].write()

formatted_data = [disassemble_tdc_word(word) for word in collected_data]
calib_data = [ word for word in formatted_data if word['word_type'] == 'CALIB']

calib_values = np.array([w['tdl_value'] + 128 * w['fine_value'] for w in calib_data])

print(calib_values[-20:])


logging.info("creating plots")
def histogram_plots(data):
    if max(data) - min(data) < 1000:
        d = 1
        left_of_first_bin = data.min() - float(d)/2
        right_of_last_bin = data.max() + float(d)/2
        _ = plt.hist(data, np.arange(left_of_first_bin,right_of_last_bin + d, d))
    else:
        #data = np.random.choice(data,,replace=False)
        _ = plt.hist(data, 1000)
    plt.title("Histogram of TDL code density")
    plt.show()
histogram_plots(calib_values) # 9 bit, which is tdl_module precision
histogram_plots(calib_values % 128) # 7 bit, which is actual tdl precision
