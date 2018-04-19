import logging
import signal
import time
from threading import Thread  # , Event, Lock, Condition

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
        'UDP_WRITE_CNT': {'descr': {'addr': 2, 'size': 32, 'offset': 0}},
        'TCP_WRITE_DLY': {'default': 0, 'descr': {'addr': 6, 'size': 32, 'offset': 0}},
        'TCP_WRITE_CNT': {'descr': {'addr': 10, 'size': 32, 'offset': 0, 'properties': ['readonly']}},
        'TCP_FAILED_WRITE_CNT': {'descr': {'addr': 14, 'size': 32, 'offset': 0, 'properties': ['readonly']}}
    }


class Test(object):
    def __init__(self):
        self.dut = Dut(conf)
        self.dut.init()
        # fw_version = dut['ETH'].read(0x0000, 1)[0]
        print "Firmware version: ", self.dut['REGISTERS'].VERSION

        signal.signal(signal.SIGINT, self.signal_handler)
        logging.info('Press Ctrl-C to stop')

        self.stop_thread = False
        self.total_data_err_cnt = 0

    def signal_handler(self, signum, frame):
        logging.info('Pressed Ctrl-C...')
        signal.signal(signal.SIGINT, signal.SIG_DFL)  # setting default handler
        self.stop_thread = True

    def start(self, test_tcp=True, test_udp=True):
        # reset registers
        self.dut['REGISTERS'].RESET
        # setup register values
        self.dut['REGISTERS'].TCP_WRITE_DLY = 5  # set delay: 1 equivalent to 1/133MHz=0.0075us=7.5ns
        self.total_data_err_cnt = 0
        self.tatal_data_words_read = 0
        self.udp_delay = 0.0
        self.total_udp_err_cnt = 0
        self.tatal_udp_read_write_cnt = 0

        self.tcp_t = Thread(target=self.tcp_read, name='TCP thread', kwargs={})
        self.tcp_t.daemon = True
        self.udp_t = Thread(target=self.udp_read_write, name='UDP thread', kwargs={})
        self.udp_t.daemon = True
        if test_tcp:
            self.tcp_t.start()
        if test_udp:
            self.udp_t.start()
        while not self.stop_thread:
            time.sleep(0.05)
        self.tcp_t.join()
        logging.info("Stopped TCP thread")
        self.udp_t.join()
        logging.info("Stopped UDP thread")
        self.tcp_t = None
        # some statistics
        if test_tcp:
            logging.info("TCP total data error counter: %d" % self.total_data_err_cnt)
            logging.info("TCP total data words: expected: %d / read: %d" % (self.dut['REGISTERS'].TCP_WRITE_CNT, self.tatal_data_words_read))
            logging.info("TCP total data words failed: %d" % self.dut['REGISTERS'].TCP_FAILED_WRITE_CNT)
        if test_udp:
            logging.info("UDP total data words failed: %d" % self.total_udp_err_cnt)
            logging.info("UDP total read/write counter: expected: %d / read: %d" % (self.tatal_udp_read_write_cnt, self.dut['REGISTERS'].UDP_WRITE_CNT))
        # close DUT
        self.dut.close()

    def tcp_read(self):
        logging.info("Started TCP thread")
        fifo_data_last_value = -1
        while True:
            time_read = time.time()
            if self.stop_thread:
                self.dut['REGISTERS'].TCP_WRITE_DLY = 0
            fifo_data = self.dut['SITCP_FIFO'].get_data()
            if fifo_data.shape[0]:
                self.tatal_data_words_read += fifo_data.shape[0]
                if fifo_data[0] != fifo_data_last_value + 1:
                    logging.warning("TCP not increased by 1 between readouts")
                    self.total_data_err_cnt += (np.abs(fifo_data[0] - fifo_data_last_value + 1))
                err_cnt = np.count_nonzero(np.diff(fifo_data) != 1)
                if err_cnt:
                    logging.warning("TCP data not increased by 1: errors=%d" % err_cnt)
                    self.total_data_err_cnt += err_cnt
                logging.info("TCP data words: %d" % fifo_data.shape[0])
                fifo_data_last_value = fifo_data[-1]
            elif self.stop_thread:
                break
            time.sleep(max(0.0, 1.0 - time_read + time.time()))
        logging.info("Stopping TCP thread...")

    def udp_read_write(self):
        logging.info("Started UDP thread")
        udp_data_last_value = 0
        while True:
            time_read = time.time()
            if self.stop_thread:
                self.dut['REGISTERS'].SETUP = 0
                break
            self.dut['REGISTERS'].SETUP = udp_data_last_value
            read_value = self.dut['REGISTERS'].SETUP
            self.tatal_udp_read_write_cnt += 1
            if read_value != udp_data_last_value:
                logging.warning("UDP data not correct: read: %d / expected: %d" % (read_value, udp_data_last_value))
                self.tota_udp_err_cnt += 1
            udp_data_last_value = (udp_data_last_value + 1)%256  # set max value
            time.sleep(max(0.0, self.udp_delay - time_read + time.time()))
        logging.info("Stopping UDP thread...")

if __name__ == "__main__":
    test = Test()
    test.start()
