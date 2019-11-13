import logging
import signal
import time
import datetime
# import random
from threading import Thread, Event  # , Lock, Condition
from array import array
import struct

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
        tcp_to_bus : True  # if True, use TCP to BUS; if False, UDP (RBCP) to BUS

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
        'BUS_WRITE_CNT': {'descr': {'addr': 10, 'size': 32, 'offset': 0}},
        'TCP_WRITE_DLY': {'default': 0, 'descr': {'addr': 14, 'size': 16, 'offset': 0}},
        'TCP_WRITE_CNT': {'descr': {'addr': 16, 'size': 64, 'offset': 0, 'properties': ['readonly']}},
        'TCP_FAILED_WRITE_CNT': {'descr': {'addr': 24, 'size': 64, 'offset': 0, 'properties': ['readonly']}},
        'TCP_RECV_WRITE_CNT': {'descr': {'addr': 32, 'size': 64, 'offset': 0, 'properties': ['readonly']}}
    }


class Test(object):
    def __init__(self):
        self.dut = Dut(conf)
        self.dut.init()
        # fw_version = dut['ETH'].read(0x0000, 1)[0]
        logging.info("Firmware version: %s" % self.dut['REGISTERS'].VERSION)

        signal.signal(signal.SIGINT, self.signal_handler)
        logging.info('Press Ctrl-C to stop')

        self.stop_thread = Event()
        self.total_tcp_err_cnt = 0

    def signal_handler(self, signum, frame):
        logging.info('Pressed Ctrl-C...')
        self.dut['REGISTERS'].TCP_WRITE_DLY = 0  # no TCP data
        self.time_stop = time.time()
        self.stop_thread.set()
        signal.signal(signal.SIGINT, signal.SIG_DFL)  # setting default handler

    def start(self, test_tcp=True, test_bus=True, tcp_write_delay=6, monitor_interval=1.0, deadline=None):
        if not test_tcp and not test_bus:
            return
        self.test_tcp = test_tcp
        self.test_bus = test_bus
        # reset registers
        self.dut['REGISTERS'].RESET
        # setup register values
        # Monitor
        self.monitor_delay = monitor_interval  # Speed of displaying netowrk speed
        # TCP
        self.tcp_readout_delay = 0.1  # Delay between reading TCP buffer
        self.dut['REGISTERS'].TCP_WRITE_DLY = 0  # no TCP data
        self.time_start = time.time()
        self.total_tcp_err_cnt = 0
        self.total_tcp_data_words_read = 0
        self.tcp_exception_cnt = 0
        self.tcp_read_speeds = None
        # BUS
        self.bus_readout_delay = 0.0  # Delay between reading/writing to BUS
        self.total_bus_err_cnt = 0
        self.total_bus_read_write_cnt = 0
        self.bus_exception_cnt = 0
        self.bus_read_write_speeds = None
        # initializing threads
        self.stop_thread.clear()
        self.mon_t = Thread(target=self.monitor, name='Monitor thread', kwargs={})
        self.mon_t.daemon = True
        self.mon_t.start()
        if test_tcp:
            self.tcp_t = Thread(target=self.tcp_read, name='TCP thread', kwargs={})
            self.tcp_t.daemon = True
            self.tcp_t.start()
        if test_bus:
            self.bus_t = Thread(target=self.bus_read_write, name='BUS thread', kwargs={})
            self.bus_t.daemon = True
            self.bus_t.start()
        if test_tcp:
            self.dut['REGISTERS'].TCP_WRITE_DLY = tcp_write_delay  # set TCP write delay: 1 equivalent to write data every clock cycle (1/133MHz=0.0075us=7.5ns)
        self.time_start = time.time()
        self.time_stop = self.time_start + 1.0
        # while loop for signal handler
        while not self.stop_thread.wait(0.05):
            if deadline and self.time_start + deadline < time.time():
                self.signal_handler(None, None)
        self.mon_t.join()
        self.mon_t = None
        logging.info("Stopped Monitor thread")
        if test_tcp:
            self.tcp_t.join()
            self.tcp_t = None
            logging.info("Stopped TCP thread")
        if test_bus:
            self.bus_t.join()
            self.bus_t = None
            logging.info("Stopped BUS thread")

        # some statistics
        logging.info("Total time: %s" % (str(datetime.timedelta(seconds=self.time_stop - self.time_start))))
        if test_tcp:
            logging.info("=== TCP transfer statistics ===")
            logging.info("TCP data error counter: %d" % self.total_tcp_err_cnt)
            logging.info("TCP exception counter: %d" % self.tcp_exception_cnt)
            logging.info("TCP write busy counter: %d" % self.dut['REGISTERS'].TCP_FAILED_WRITE_CNT)
            logging.info("TCP data words: read: %d, expected: %d" % (self.dut['REGISTERS'].TCP_WRITE_CNT * 4 + self.dut['REGISTERS'].TCP_RECV_WRITE_CNT, self.total_tcp_data_words_read * 4))
            if self.total_tcp_data_words_read * 4 / 10.0**6 > 1000000:
                logging.info("Total amount transmitted: %.2f TB" % (self.total_tcp_data_words_read * 4 / 10.0**12))
            elif self.total_tcp_data_words_read * 4 / 10.0**6 > 1000:
                logging.info("Total amount transmitted: %.2f GB" % (self.total_tcp_data_words_read * 4 / 10.0**9))
            else:
                logging.info("Total amount transmitted: %.2f MB" % (self.total_tcp_data_words_read * 4 / 10.0**6))
            total_tcp_avg_read_speed = self.total_tcp_data_words_read * 32 / (self.time_stop - self.time_start) / 10.0**6
            if total_tcp_avg_read_speed < 1.0:
                logging.info("Total average TCP read speed: %.2f kbit/s" % (total_tcp_avg_read_speed * 10**3))
            else:
                logging.info("Total average TCP read speed: %.2f Mbit/s" % (total_tcp_avg_read_speed))
            if self.tcp_read_speeds:
                if np.average(self.tcp_read_speeds) < 1.0:
                    logging.info("TCP read speed (min/median/average/max): %.2f/%.2f/%.2f/%.2f kbit/s" % (np.min(self.tcp_read_speeds) * 10**3, np.median(self.tcp_read_speeds) * 10**3, np.average(self.tcp_read_speeds) * 10**3, np.max(self.tcp_read_speeds) * 10**3))
                else:
                    logging.info("TCP read speed (min/median/average/max): %.2f/%.2f/%.2f/%.2f Mbit/s" % (np.min(self.tcp_read_speeds), np.median(self.tcp_read_speeds), np.average(self.tcp_read_speeds), np.max(self.tcp_read_speeds)))

        if test_bus:
            logging.info("=== BUS transfer statistics ===")
            logging.info("BUS data error counter: %d" % self.total_bus_err_cnt)
            logging.info("BUS exception counter: %d" % self.bus_exception_cnt)
            logging.info("BUS read/write counter: read: %d, expected: %d" % (self.dut['REGISTERS'].BUS_WRITE_CNT, self.total_bus_read_write_cnt * 8))
            if self.total_bus_read_write_cnt * 8 / 10.0**6 > 1000000:
                logging.info("Total amount transmitted: %.2f TB" % (self.total_bus_read_write_cnt * 8 / 10.0**12))
            elif self.total_bus_read_write_cnt * 8 / 10.0**6 > 1000:
                logging.info("Total amount transmitted: %.2f GB" % (self.total_bus_read_write_cnt * 8 / 10.0**9))
            else:
                logging.info("Total amount transmitted: %.2f MB" % (self.total_bus_read_write_cnt * 8 / 10.0**6))
            total_bus_avg_read_speed = self.total_bus_read_write_cnt * 64 / (self.time_stop - self.time_start) / 10.0**6
            if total_bus_avg_read_speed < 1.0:
                logging.info("Total average BUS read/write speed: %.2f kbit/s" % (total_bus_avg_read_speed * 10**3))
            else:
                logging.info("Total average BUS read/write speed: %.2f Mbit/s" % (total_bus_avg_read_speed))
            if self.bus_read_write_speeds:
                if np.average(self.bus_read_write_speeds) < 1.0:
                    logging.info("BUS read/write speed (min/median/average/max): %.2f/%.2f/%.2f/%.2f kbit/s" % (np.min(self.bus_read_write_speeds) * 10**3, np.median(self.bus_read_write_speeds) * 10**3, np.average(self.bus_read_write_speeds) * 10**3, np.max(self.bus_read_write_speeds) * 10**3))
                else:
                    logging.info("BUS read/write speed (min/median/average/max): %.2f/%.2f/%.2f/%.2f Mbit/s" % (np.min(self.bus_read_write_speeds), np.median(self.bus_read_write_speeds), np.average(self.bus_read_write_speeds), np.max(self.bus_read_write_speeds)))

        # close DUT
        self.dut.close()

    def monitor(self):
        logging.info("Started Monitor thread")
        time_read = time.time()
        last_total_tcp_data_words_read = 0
        last_total_bus_read_write_cnt = 0
        while not self.stop_thread.wait(max(0.0, self.monitor_delay - time_read + time.time())):
            tmp_time_read = time.time()
            tmp_total_tcp_data_words_read = self.total_tcp_data_words_read
            tmp_total_bus_read_write_cnt = self.total_bus_read_write_cnt
            if self.test_tcp:
                tcp_read_speed = (tmp_total_tcp_data_words_read - last_total_tcp_data_words_read) * 32 / (tmp_time_read - time_read) / 10**6
                if self.tcp_read_speeds is None:  # add on second iteration
                    self.tcp_read_speeds = []
                else:
                    self.tcp_read_speeds.append(tcp_read_speed)
                if tcp_read_speed < 1.0:
                    logging.info("TCP read speed: %0.2f kbit/s" % (tcp_read_speed * 10**3))
                else:
                    logging.info("TCP read speed: %0.2f Mbit/s" % tcp_read_speed)
            if self.test_bus:
                bus_read_write_speed = (tmp_total_bus_read_write_cnt - last_total_bus_read_write_cnt) * 64 / (tmp_time_read - time_read) / 10**6
                if self.bus_read_write_speeds is None:  # add on second iteration
                    self.bus_read_write_speeds = []
                else:
                    self.bus_read_write_speeds.append(bus_read_write_speed)
                if bus_read_write_speed < 1.0:
                    logging.info("BUS read/write speed: %0.2f kbit/s" % (bus_read_write_speed * 10**3))
                else:
                    logging.info("BUS read/write speed: %0.2f Mbit/s" % bus_read_write_speed)
            time_read = tmp_time_read
            last_total_tcp_data_words_read = tmp_total_tcp_data_words_read
            last_total_bus_read_write_cnt = tmp_total_bus_read_write_cnt
            if self.total_bus_err_cnt > 10 or self.total_tcp_err_cnt > 10:
                self.stop_thread.set()

        logging.info("Stopping Monitor thread...")

    def tcp_read(self):
        logging.info("Started TCP thread")
        fifo_data_last_value = -1
        fifo_was_empty = 0
        time_read = time.time()
        while not self.stop_thread.wait(max(0.0, self.tcp_readout_delay - time_read + time.time())) or fifo_was_empty < 1:
            time_read = time.time()
            try:
                fifo_data = self.dut['SITCP_FIFO'].get_data()
            except Exception as e:
                logging.error(e)
                self.tcp_exception_cnt += 1
            else:
                if fifo_data.shape[0]:
                    self.total_tcp_data_words_read += fifo_data.shape[0]
                    if fifo_data[0] != fifo_data_last_value + 1:
                        logging.warning("TCP not increased by 1 between readouts")
                        self.total_tcp_err_cnt += 1
                    err_cnt = np.count_nonzero(np.diff(fifo_data) != 1)
                    if err_cnt:
                        logging.warning("TCP data not increased by 1: errors=%d" % err_cnt)
                        self.total_tcp_err_cnt += err_cnt
                    fifo_data_last_value = fifo_data[-1]
                elif self.stop_thread.is_set():
                    fifo_was_empty += 1
            if self.stop_thread.is_set():
                time.sleep(max(0.0, self.tcp_readout_delay - time_read + time.time()))
        logging.info("Stopping TCP thread...")

    def bus_read_write(self):
        logging.info("Started BUS thread")
        time_read = time.time()
        while not self.stop_thread.wait(max(0.0, self.bus_readout_delay - time_read + time.time())):
            time_read = time.time()
            write_value = int(np.random.randint(2**64, size=None, dtype=np.uint64))  # random.randint(0, 2**64 - 1)
            try:
                self.dut['REGISTERS'].TEST_DATA = write_value
            except Exception as e:
                logging.error(e)
                self.bus_exception_cnt += 1
            else:
                try:
                    read_value = self.dut['REGISTERS'].TEST_DATA
                except Exception as e:
                    logging.error(e)
                    self.bus_exception_cnt += 1
                else:
                    self.total_bus_read_write_cnt += 1
                    if read_value != write_value:
                        logging.warning("BUS data not correct: read: %s, expected: %s" % (array('B', struct.unpack("BBBBBBBB", struct.pack("Q", read_value))), array('B', struct.unpack("BBBBBBBB", struct.pack("Q", write_value)))))
                        self.total_bus_err_cnt += 1
        logging.info("Stopping BUS thread...")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description='Testing MMC3 Ethernet Interface %s\nExample: python test_eth.py -t 1.0 -d 6 --no-bus', formatter_class=argparse.RawTextHelpFormatter)
    parser.add_argument('-w', '--deadline', type=float, metavar='<deadline>', action='store', help='timeout in seconds before application exits')
    parser.add_argument('-i', '--interval', type=float, metavar='<interval time>', action='store', help='time interval in seconds for the monitor')
    parser.add_argument('-d', '--delay', type=int, metavar='<clock cycles>', action='store', help='clock cycles between TCP writes')
    parser.add_argument('--no-bus', dest='no_bus', action='store_true', help='disable BUS tests')
    parser.add_argument('--no-tcp', dest='no_tcp', action='store_true', help='disable TCP downstream tests')
    parser.set_defaults(no_m26_jtag_configuration=False)
    args = parser.parse_args()

    config = {}

    if args.deadline is not None:
        config["deadline"] = args.deadline
    if args.interval is not None:
        config["monitor_interval"] = args.interval
    if args.delay is not None:
        config["tcp_write_delay"] = args.delay
    if args.no_bus:
        config["test_bus"] = False
    if args.no_tcp:
        config["test_tcp"] = False

    test = Test()
    test.start(**config)
