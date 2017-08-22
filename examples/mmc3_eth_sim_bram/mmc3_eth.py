# ------------------------------------------------------------
# SiTCP throughput test
# Reads data for a couple of seconds and displays the data rate
#
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import unittest
import os, sys
import time
from basil.dut import Dut
from basil.utils.sim.utils import cocotb_compile_and_run, cocotb_compile_clean


doprint=True


class TestSimMMC3Eth(unittest.TestCase):
    def setUp(self):
        sys.path = [os.path.dirname(os.getcwd())] + sys.path
        proj_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

        cocotb_compile_and_run(
           sim_files = [proj_dir + '/mmc3_eth_sim_bram/mmc3_eth_tb.v'],
           top_level = 'tb'
        )

        #cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), 'mmc3_eth_tb.v')])

        self.chip = Dut("mmc3_eth.yaml")
        self.chip.init()


    def test(self):
        testduration = 1
        total_len = 0
        tick = 0
        tick_old = 0
        start_time = time.time()

        self.chip['GPIO_LED']['LED'] = 0x01  #start data source
        self.chip['GPIO_LED'].write()

        while time.time() - start_time < testduration:
            data = self.chip['FIFO'].get_data()
            total_len += len(data)*4*8
            time.sleep(0.01)
            tick = int(time.time() - start_time)
            if tick != tick_old:
                print tick
                tick_old = tick

        if doprint==True:
            print data[1:128]

        print ('Bytes received:', total_len, '  data rate:', round((total_len/1e6/testduration),2), ' Mbit/s')

        self.chip['GPIO_LED']['LED'] = 0x00  #stop data source
        self.chip['GPIO_LED'].write()


    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        #cocotb_compile_clean()


if __name__ == '__main__':
    unittest.main()
