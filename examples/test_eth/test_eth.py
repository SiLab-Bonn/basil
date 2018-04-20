import logging
import signal
import time
import random
from threading import Thread, Event  # , Lock, Condition

import numpy as np

from basil.dut import Dut
from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer

conf = '''
name    : test_eth
version : 1.0

transfer_layer:
  - name  : ETH
    type  : SiTcp
    init:
        ip : "192.168.10.16"
        udp_port : 4660
        tcp_port : 24
        tcp_connection : True

hw_drivers:
  - name      : SITCP_FIFO
    type      : sitcp_fifo
    interface : ETH

  - name      : REGISTERS
    type      : test_eth
    interface : ETH
    base_addr : 0x0

'''

stop_thread = False


class test_eth(RegisterHardwareLayer):
    '''Register Hardware Layer.

    Implementation of advanced register operations.
    '''
    _registers = {
        'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
        'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['readonly']}},
        'SETUP': {'default': 0, 'descr': {'addr': 1, 'size': 8, 'offset': 0}},
        'TEST_DATA': {'descr': {'addr': 2, 'size': 64, 'offset': 0}},
        'UDP_WRITE_CNT': {'descr': {'addr': 10, 'size': 32, 'offset': 0}},
        'TCP_WRITE_DLY': {'default': 0, 'descr': {'addr': 14, 'size': 16, 'offset': 0}},
        'TCP_WRITE_CNT': {'descr': {'addr': 16, 'size': 64, 'offset': 0, 'properties': ['readonly']}},
        'TCP_FAILED_WRITE_CNT': {'descr': {'addr': 24, 'size': 64, 'offset': 0, 'properties': ['readonly']}}
    }


class Test(object):
    def __init__(self):
        self.dut = Dut(conf)
        self.dut.init()
        # fw_version = dut['ETH'].read(0x0000, 1)[0]
        print "Firmware version: ", self.dut['REGISTERS'].VERSION

        signal.signal(signal.SIGINT, self.signal_handler)
        logging.info('Press Ctrl-C to stop')

        self.stop_thread = Event()
        self.total_data_err_cnt = 0

    def signal_handler(self, signum, frame):
        logging.info('Pressed Ctrl-C...')
        self.stop_thread.set()
        signal.signal(signal.SIGINT, signal.SIG_DFL)  # setting default handler

    def start(self, test_tcp=True, test_udp=True):
        # reset registers
        self.dut['REGISTERS'].RESET
        # setup register values
        self.monitor_delay = 3.0  # Speed of displaying netowrk speed
        self.tcp_readout_delay = 0.1  # Delay between reading TCP buffer
        self.dut['REGISTERS'].TCP_WRITE_DLY = 6  # set TCP write delay: 1 equivalent to write data every clock cycle (1/133MHz=0.0075us=7.5ns)
        self.total_data_err_cnt = 0
        self.total_data_words_read = 0
        self.udp_readout_delay = 0.0  # Delay between reading/writing UDP
        self.total_udp_err_cnt = 0
        self.total_udp_read_write_cnt = 0

        self.stop_thread.clear()
        self.mon_t = Thread(target=self.monitor, name='Monitor thread', kwargs={})
        self.mon_t.daemon = True
        self.tcp_t = Thread(target=self.tcp_read, name='TCP thread', kwargs={})
        self.tcp_t.daemon = True
        self.udp_t = Thread(target=self.udp_read_write, name='UDP thread', kwargs={})
        self.udp_t.daemon = True
        self.mon_t.start()
        if test_tcp:
            self.tcp_t.start()
        if test_udp:
            self.udp_t.start()
        while not self.stop_thread.wait(0.05):
            pass
        self.tcp_t.join()
        logging.info("Stopped Monitor thread")
        self.tcp_t.join()
        logging.info("Stopped TCP thread")
        self.udp_t.join()
        logging.info("Stopped UDP thread")
        self.tcp_t = None
        # some statistics
        if test_tcp:
            logging.info("TCP transfer statistics:")
            logging.info("TCP total data error counter: %d" % self.total_data_err_cnt)
            logging.info("TCP total data words: expected: %d / read: %d" % (self.dut['REGISTERS'].TCP_WRITE_CNT, self.total_data_words_read))
            logging.info("TCP total data words failed: %d" % self.dut['REGISTERS'].TCP_FAILED_WRITE_CNT)
            if self.total_data_words_read * 4 / 10.0**6 > 1000000:
                logging.info("Total amount transmitted: %.2f TB" % (self.total_data_words_read * 4 / 10.0**12))
            elif self.total_data_words_read * 4 / 10.0**6 > 1000:
                logging.info("Total amount transmitted: %.2f GB" % (self.total_data_words_read * 4 / 10.0**9))
            else:
                logging.info("Total amount transmitted: %.2f MB" % (self.total_data_words_read * 4 / 10.0**6))

        if test_udp:
            logging.info("UDP transfer statistics:")
            logging.info("UDP total data words failed: %d" % self.total_udp_err_cnt)
            logging.info("UDP total read/write counter: expected: %d / read: %d" % (self.total_udp_read_write_cnt, self.dut['REGISTERS'].UDP_WRITE_CNT))
            if self.total_udp_read_write_cnt * 8 / 10.0**6 > 1000000:
                logging.info("Total amount transmitted: %.2f TB" % (self.total_udp_read_write_cnt * 8 / 10.0**12))
            elif self.total_udp_read_write_cnt * 8 / 10.0**6 > 1000:
                logging.info("Total amount transmitted: %.2f GB" % (self.total_udp_read_write_cnt * 8 / 10.0**9))
            else:
                logging.info("Total amount transmitted: %.2f MB" % (self.total_udp_read_write_cnt * 8 / 10.0**6))
        # close DUT
        self.dut.close()

    def monitor(self):
        logging.info("Started Monitor thread")
        time_read = time.time()
        last_total_data_words_read = 0
        last_total_udp_read_write_cnt = 0
        while not self.stop_thread.wait(max(0.0, self.monitor_delay - time_read + time.time())):
            tmp_time_read = time.time()
            tmp_total_data_words_read = self.total_data_words_read
            tmp_total_udp_read_write_cnt = self.total_udp_read_write_cnt
            logging.info("TCP write speed: %0.2f Mbit/s" % ((tmp_total_data_words_read - last_total_data_words_read) * 32 / (tmp_time_read - time_read) / 10**6))
            logging.info("UDP read/write speed: %0.2f Mbit/s" % ((tmp_total_udp_read_write_cnt - last_total_udp_read_write_cnt) * 64 / (tmp_time_read - time_read) / 10**6))
            time_read = tmp_time_read
            last_total_data_words_read = tmp_total_data_words_read
            last_total_udp_read_write_cnt = tmp_total_udp_read_write_cnt

        logging.info("Stopping Monitor thread...")

    def tcp_read(self):
        logging.info("Started TCP thread")
        fifo_data_last_value = -1
        fifo_was_empty = 0
        time_read = time.time()
        while not self.stop_thread.wait(max(0.0, self.tcp_readout_delay - time_read + time.time())) or fifo_was_empty < 1:
            time_read = time.time()
            if self.stop_thread.is_set():
                self.dut['REGISTERS'].TCP_WRITE_DLY = 0
            fifo_data = self.dut['SITCP_FIFO'].get_data()
            if fifo_data.shape[0]:
                self.total_data_words_read += fifo_data.shape[0]
                if fifo_data[0] != fifo_data_last_value + 1:
                    logging.warning("TCP not increased by 1 between readouts")
                    self.total_data_err_cnt += (np.abs(fifo_data[0] - fifo_data_last_value + 1))
                err_cnt = np.count_nonzero(np.diff(fifo_data) != 1)
                if err_cnt:
                    logging.warning("TCP data not increased by 1: errors=%d" % err_cnt)
                    self.total_data_err_cnt += err_cnt
                fifo_data_last_value = fifo_data[-1]
            elif self.stop_thread.is_set():
                fifo_was_empty += 1
            if self.stop_thread.is_set():
                time.sleep(max(0.0, self.tcp_readout_delay - time_read + time.time()))
        logging.info("Stopping TCP thread...")

    def udp_read_write(self):
        logging.info("Started UDP thread")
        time_read = time.time()
        while not self.stop_thread.wait(max(0.0, self.udp_readout_delay - time_read + time.time())):
            time_read = time.time()
            write_value = random.randint(0, 2**64 - 1)
            self.dut['REGISTERS'].TEST_DATA = write_value
            read_value = self.dut['REGISTERS'].TEST_DATA
            self.total_udp_read_write_cnt += 8
            if read_value != write_value:
                logging.warning("UDP data not correct: read: %d / expected: %d" % (read_value, write_value))
                self.total_udp_err_cnt += 1
            write_value = (write_value + 1) % 2**64  # set max value
        self.dut['REGISTERS'].TEST_DATA = 0
        self.total_udp_read_write_cnt += 8
        logging.info("Stopping UDP thread...")


if __name__ == "__main__":
    test = Test()
    test.start()
