#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab , Physics Institute of Bonn University
# ------------------------------------------------------------
#

import unittest

import yaml

from basil.dut import Dut


class TestClass(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        setup_file = open("test_StdRegister.yaml", 'r')
        cls.cnfg = yaml.load(setup_file)
        cls.dut = Dut(cls.cnfg)
        cls.dut.init()

    def test_init_simple(self):
        self.dut['TEST1'].write()
        mem = dict()
        #mem[0] = 0  # reset
        mem[8] = 0  # has an offset of 8 bytes
        mem[9] = 0
        mem[10] = 0
        mem[11] = 0
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST1'][0] = 1
        self.dut['TEST1'].write()
        mem[11] = 1
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST1'][31] = 1
        self.dut['TEST1'].write()
        mem[8] = 0x80
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST1'] = 0
        self.dut['TEST1'].write()
        mem[8] = 0
        mem[11] = 0
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST1'] = 0xa55a8001
        self.dut['TEST1'].write()
        mem[8] = 0xa5
        mem[9] = 0x5a
        mem[10] = 0x80
        mem[11] = 0x01
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST1'] = 0
        self.dut['TEST1'][11:4] = 0xff
        self.dut['TEST1'].write()
        mem[8] = 0x0
        mem[9] = 0x0
        mem[10] = 0x0f
        mem[11] = 0xf0
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

    def test_bit_order(self):
        self.dut['TEST2'].write()
        mem = dict()
        #mem[0] = 0  # reset
        mem[8] = 0
        mem[9] = 0
        mem[10] = 0
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['VINJECT'] = 0x01
        self.dut['TEST2'].write()
        mem[8] = 0x08
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['VINJECT'] = 0x02
        self.dut['TEST2'].write()
        mem[8] = 0x10
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['VINJECT'] = 0x04
        self.dut['TEST2'].write()
        mem[8] = 0x04
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['VINJECT'] = 0x08
        self.dut['TEST2'].write()
        mem[8] = 0x20
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['VINJECT'] = 0
        self.dut['TEST2']['VINJECT'][0] = 1
        self.dut['TEST2'].write()
        mem[8] = 0x04
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

    def test_repeat(self):
        self.dut['dummy_tl'].mem = dict()
        #self.dut['TEST2'] = 0
        self.dut['TEST2']['VINJECT'] = 0
        self.dut['TEST2'].write()
        mem = dict()
        mem[8] = 0
        mem[9] = 0
        mem[10] = 0
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['COLUMN'][0]['EnR'] = 1
        self.dut['TEST2'].write()
        mem[9] = 0x02
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['COLUMN'][1]['DACR'] = 1
        self.dut['TEST2'].write()
        mem[10] = 0x10
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

    def test_default(self):
        self.cnfg['registers'][1]['fields'][0]['default'] = 0x01#VINJECT
        self.dut = Dut(self.cnfg)
        self.dut.init()
        
        mem = dict()
        #mem[0] = 0  # reset
        mem[8] = 0x08
        mem[9] = 0
        mem[10] = 0
        self.dut['TEST2'].write()
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)
        

if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(TestClass)
    unittest.TextTestRunner(verbosity=2).run(suite)
