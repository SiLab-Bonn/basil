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
    word_type_codes = {0: 'TRIGGERED',
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

GHZ_S_FREQ = 0.48
CLK_DIV = 3


chip = Dut("tdc_bdaq.yaml")
chip.init()
chip['TDL_TDC'].reset()


chip['CONTROL']['EN'] = 0
chip['CONTROL'].write()

logging.info("Starting data test ...")

chip['CONTROL']['EN'] = 1
chip['CONTROL'].write()

chip['TDL_TDC'].RESET =1

print(chip['TDL_TDC'].get_en_extern())
print(chip['TDL_TDC'].get_arming())
chip['TDL_TDC'].EN_TRIGGER_DIST = 0
chip['TDL_TDC'].ENABLE = 1
chip['TDL_TDC'].RESET=0
chip['TDL_TDC'].EN_TRIGGER_DIST = 1
collected_data = np.empty(0, dtype=np.uint32)
test_duration = 3
start_time = time.time()

chip['TDL_TDC'].EN_CALIBRATION_MOD = 1
print(chip['TDL_TDC'].EN_CALIBRATION_MOD)

while time.time() - start_time < test_duration:
    time.sleep(.01)

    fifo_data = chip['FIFO'].get_data()
    data_size = len(fifo_data)
    collected_data = np.concatenate((collected_data,fifo_data), dtype=np.uint32)
    for word_int in fifo_data[-1:] :
        word_dict = chip['TDL_TDC'].disassemble_tdc_word(word_int)
        print(word_dict)


chip['TDL_TDC'].EN_CALIBRATION_MOD = 0
chip['TDL_TDC'].RESET=1
chip['FIFO'].get_data()

chip['CONTROL']['EN'] = 0  # stop data source
chip['CONTROL'].write()

calib_data_indices = chip['TDL_TDC'].is_calib_word(collected_data)
print(calib_data_indices)

calib_vector = np.ones(92)
calib_sum = np.sum(calib_vector)

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

if any(calib_data_indices) :
    calib_values = chip['TDL_TDC'].get_raw_tdl_values(np.array(collected_data[calib_data_indices]))
    print(calib_values[-20:])
    chip['TDL_TDC'].set_calib_values(calib_values)
    logging.info("Calibration set using %s samples" % len(calib_values))

    #histogram_plots(calib_values[0:int(np.floor(len(calib_values)*1/3))]) 
    #histogram_plots(calib_values[0:int(np.floor(len(calib_values)*2/3))]) 
    #histogram_plots(calib_values)






collected_rising = []
collected_falling = []
chip['CONTROL']['EN'] = 1  # start data source
chip['CONTROL'].write()
chip['FIFO'].get_data()

chip['TDL_TDC'].EN_CALIBRATION_MOD = 0
chip['TDL_TDC'].RESET=1
time.sleep(0.1)
chip['TDL_TDC'].RESET=0
chip['FIFO'].get_data()
logging.info("Ready for measurements")
chip['TDL_TDC'].EN_TRIGGER_DIST = 1
chip['TDL_TDC'].EN_WRITE_TIMESTAMP = 0
chip['FIFO'].get_data()

delta_t = 0

def reject_outliers(data, m=2):
    return data[abs(data - np.median(data)) < m]
def plot_histogram(collected, title):
        d = 0.010
        left_of_first_bin = np.min(collected) - float(d)/2
        right_of_last_bin = np.max(collected) + float(d)/2
        plt.hist(collected, np.arange(left_of_first_bin, right_of_last_bin + d, d))
        plt.ylabel(title)
        plt.xlabel('ns')

while True :
    time.sleep(.01)

    fifo_data = chip['FIFO'].get_data()
    data_size = len(fifo_data)
    for word_int in fifo_data[-8:] :
        word_dict = chip['TDL_TDC'].disassemble_tdc_word(word_int)
        if (word_dict['word_type'] in ['TRIGGERED', 'RISING', 'FALLING']) :
            if (word_dict['word_type'] == 'TRIGGERED') :
                delta_t = chip['TDL_TDC'].tdc_word_to_time(word_dict)

            word_time = chip['TDL_TDC'].tdc_word_to_time(word_dict) - delta_t

            if (word_dict['word_type'] == 'RISING'):
                delta_t += word_time
            print('%s Time: %.3f, Delta Time: %.3f' % (word_dict['word_type'], chip['TDL_TDC'].tdc_word_to_time(word_dict), word_time)) 
            print(word_dict)

            if(word_dict['word_type'] == 'RISING') :
                collected_rising.append(word_time)
            elif(word_dict['word_type'] == 'FALLING') :
                collected_falling.append(word_time)

#    if(len(collected_falling) * len(collected_rising) > 0 and len(collected_falling) % 40 == 39) :
#        rising = np.array(collected_rising)
#        falling = np.array(collected_falling)
#        rising_no_outliers = reject_outliers(rising)
#        falling_no_outliers = reject_outliers(falling)
#        n_outliers = len(collected_rising) - len(rising_no_outliers) + len(collected_falling) - len(falling_no_outliers)
#        logging.info("%i outliers removed" % n_outliers)
#        logging.info("Rising std: %.3f" % np.std(rising_no_outliers))
#        logging.info("Falling std: %.3f" % np.std(falling_no_outliers))
#        plt.subplot(2, 1, 1)
#        plot_histogram(collected_rising, '# rising edge')
#        plt.subplot(2, 1, 2)
#        plot_histogram(collected_falling, '# falling edge')
#        plt.tight_layout()
#        plt.show()




