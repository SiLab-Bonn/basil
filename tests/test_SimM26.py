#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest
import os
from basil.dut import Dut
from basil.utils.sim.utils import cocotb_compile_and_run, cocotb_compile_clean
from basil.utils.BitLogic import BitLogic
import numpy as np

cnfg_yaml = """
transfer_layer:
  - name  : intf
    type  : SiSim
    init:
        host : localhost
        port  : 12345

hw_drivers:
  - name      : SEQ_GEN
    type      : seq_gen
    interface : intf
    mem_size  : 8192
    base_addr : 0x1000

  - name      : M26_RX
    type      : m26_rx
    interface : intf
    base_addr : 0x3000

  - name      : fifo
    type      : sram_fifo
    interface : intf
    base_addr : 0x8000
    base_data_addr: 0x80000000
    
registers:
  - name        : SEQ
    type        : TrackRegister
    hw_driver   : SEQ_GEN
    seq_width   : 8
    seq_size    : 8192
    tracks  :
      - name     : MKD
        position : 0
      - name     : DATA0
        position : 1
      - name     : DATA1
        position : 2

"""


class TestSimM26(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.dirname(__file__) + '/test_SimM26.v'])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    def test_io(self):

        self.chip['SEQ']['MKD'][0] = 1
        self.chip['SEQ']['MKD'][1] = 1
        self.chip['SEQ']['MKD'][2] = 1
        self.chip['SEQ']['MKD'][3] = 1
        
        header0 = BitLogic(16)
        header1 = BitLogic(16)
        header0[:] = 0x5555
        header1[:] = 0xDAAA
        header0.reverse()
        header1.reverse()
        
        self.chip['SEQ']['DATA0'][0:16] = header0[:]
        self.chip['SEQ']['DATA1'][0:16] = header1[:]
 
        fcnt0 = BitLogic(16)
        fcnt1 = BitLogic(16)
        fcnt0[:] = 0xffaa
        fcnt1[:] = 0xaa55
        fcnt0.reverse()
        fcnt1.reverse()
        
        self.chip['SEQ']['DATA0'][16:32] = fcnt0[:]
        self.chip['SEQ']['DATA1'][16:32] = fcnt1[:]
        
        datalen0 = BitLogic(16)
        datalen1 = BitLogic(16)
        datalen0[:] = 0x0004
        datalen1[:] = 0x0004
        datalen0.reverse()
        datalen1.reverse()
        
        self.chip['SEQ']['DATA0'][32:48] = datalen0[:]
        self.chip['SEQ']['DATA1'][32:48] = datalen1[:]
        

        for i in range(4):
            data0 = BitLogic(16)
            data1 = BitLogic(16)
            data0[:] = i*2
            data1[:] = i*2+1
            data0.reverse()
            data1.reverse()
            self.chip['SEQ']['DATA0'][48+i*16:48+16+i*16] = data0[:]
            self.chip['SEQ']['DATA1'][48+i*16:48+16+i*16] = data1[:]

        self.chip['SEQ'].write(16*(4+4))
        self.chip['SEQ'].set_repeat(4)
        self.chip['SEQ'].set_size(16*(4+12))
        
        self.chip['M26_RX'].set_en(True)
        
        self.chip['SEQ'].start()
        
        
        while(not self.chip['SEQ'].is_done()):
            pass

        ret = self.chip['fifo'].get_fifo_size()
        self.assertEqual(ret, 14*4*4)
        
        ret = self.chip['fifo'].get_data()

        exp = np.zeros((14,), dtype=np.uint32)
        exp[0] = 0x00010000 | 0x5555
        exp[1] = 0xDAAA
        exp[2] = 0xffaa
        exp[3] = 0xaa55
        exp[4] = 0x0004
        exp[5] = 0x0004
        for i in range(4):
            exp[6+i*2] = i*2
            exp[7+i*2] = i*2+1
        
        exp = np.tile(exp, 4)

        np.testing.assert_array_equal(exp, ret)

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()

if __name__ == '__main__':
    unittest.main()
