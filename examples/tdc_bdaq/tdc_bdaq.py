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
from tqdm import tqdm

import numpy as np
from scipy import stats
import matplotlib.pyplot as plt

from basil.dut import Dut
from basil.HL import si570


def disassemble_tdc_word(word):
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

si570_conf = {'name': 'si570', 'type': 'bdaq53.si570', 'interface': 'intf', 'base_addr': 0xba, 'init': {'frequency': 160}}
si570_clk = si570.si570(chip['i2c'], si570_conf)
time.sleep(0.1)
si570_clk.init()
time.sleep(0.1)

chip['TDL_TDC'].reset()


chip['CONTROL']['EN'] = 0
chip['CONTROL'].write()

logging.info("Starting TDC...")

chip['CONTROL']['EN'] = 1
chip['CONTROL'].write()

chip['TDL_TDC'].RESET =1

chip['TDL_TDC'].EN_TRIGGER_DIST = 0
chip['TDL_TDC'].ENABLE = 1
chip['TDL_TDC'].RESET=0
chip['TDL_TDC'].EN_TRIGGER_DIST = 1

collected_data = np.empty(0, dtype=np.uint32)
calib_duration = 3
start_time = time.time()

chip['TDL_TDC'].EN_CALIBRATION_MODE = 1

while time.time() - start_time < calib_duration:
    time.sleep(.01)

    fifo_data = chip['FIFO'].get_data()
    data_size = len(fifo_data)
    collected_data = np.concatenate((collected_data,fifo_data), dtype=np.uint32)


chip['TDL_TDC'].EN_CALIBRATION_MODE = 0

chip['TDL_TDC'].RESET=1
chip['FIFO'].get_data()

chip['CONTROL']['EN'] = 0  # stop data source
chip['CONTROL'].write()

calib_data_indices = chip['TDL_TDC'].is_calib_word(collected_data)
print(calib_data_indices)


if any(calib_data_indices) :
    calib_values = chip['TDL_TDC'].get_raw_tdl_values(np.array(collected_data[calib_data_indices]))
    print(calib_values[-20:])
    chip['TDL_TDC'].set_calib_values(calib_values)
    #chip['TDL_TDC'].plot_calib_values(calib_values)
    logging.info("Calibration set using %s samples" % len(calib_values))







collected_rising = []
collected_falling = []
chip['CONTROL']['EN'] = 1  # start data source
chip['CONTROL'].write()
chip['FIFO'].get_data()

chip['TDL_TDC'].RESET=1
time.sleep(0.1)
chip['FIFO'].get_data()
logging.info("Ready for measurements")
chip['TDL_TDC'].EN_TRIGGER_DIST = 1
chip['TDL_TDC'].EN_WRITE_TIMESTAMP = 0

delta_t = 0
def reject_outliers(data, m=2):
    return data[abs(data - np.median(data)) < m]


def load_and_start_trig_seq(trig_dis_cycles):
    # 10/0.125Ghz = 80ns
    sig_cycles = 10

    kilo_trig_cycles = int(np.floor(trig_dis_cycles / 1000))
    need_kilo_cycles = 0
    if kilo_trig_cycles > 0:
        need_kilo_cycles = 1
    remain_trig_cycles = trig_dis_cycles % 1000

    trig_total = remain_trig_cycles + need_kilo_cycles*1000

    chip['SEQ'].reset()
    while not chip['SEQ'].is_ready:
        pass
    chip['SEQ'].SIZE = sig_cycles + trig_total + 1
    chip['SEQ']['TDC_IN'][:] = False
    chip['SEQ']['TDC_IN'][trig_total:sig_cycles + trig_total ] = True
    chip['SEQ']['TDC_TRIGGER_IN'][0:20] = True
    chip['SEQ'].write(sig_cycles + trig_total + 1)

    chip['SEQ'].REPEAT = 1
    # This repeat window isn't optimal as the trigger signal is repeated.
    # However, once first registered, the repeated trigger signal will
    # be ignored by the TDC implementation.
    chip['SEQ'].NESTED_START = 0
    chip['SEQ'].NESTED_STOP = 1000
    chip['SEQ'].NESTED_REPEAT = kilo_trig_cycles 

    chip['SEQ'].START

seq_clk_GHZ = 0.15625
N_measure = 500
current_measurements = np.zeros(N_measure)
measured = []
stds = []
actual = []
for i in tqdm(range(10, 4000, 100)):
    for j in range(N_measure):

        load_and_start_trig_seq(i)
        while not chip['SEQ'].is_ready:
            time.sleep(0.0001)
            pass
        fifo_size = chip['FIFO']._intf._get_tcp_data_size()
        fifo_int_size = int((fifo_size - (fifo_size % 4)) / 4) 
        while fifo_int_size < 2:
            time.sleep(0.0001)
            fifo_size = chip['FIFO']._intf._get_tcp_data_size()
            fifo_int_size = int((fifo_size - (fifo_size % 4)) / 4) 
        fifo_data = chip['FIFO'].get_data()
        times = chip['TDL_TDC'].tdc_word_to_time(fifo_data)
        current_measurements[j] = times[1] - times[0]
    actual.append(i/seq_clk_GHZ)
    std = np.std(current_measurements)
    print('Actual time: %5.3f Measured time: %5.3f Difference: %.3f Std %.3f' % (i/seq_clk_GHZ, times[1] - times[0], times[1] - times[0] - i/seq_clk_GHZ, std))
    measured.append(np.mean(current_measurements))
    stds.append(std)
    print()
actual = np.asarray(actual)
measured = np.asarray(measured)
stds = np.asarray(stds)
res = stats.linregress(actual, measured - actual)
print(f"R-squared: {res.rvalue**2:.6f}")
print('Intercept: %f' % (res.intercept))
print('Slope: %.6e' % (res.slope))
plt.errorbar(actual, measured - actual, yerr=stds)
plt.plot(actual, res.intercept + res.slope * actual, 'r')
plt.show()

plt.plot(actual, stds)
plt.show()




