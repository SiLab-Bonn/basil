#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest

from basil.dut import Dut


class TestHardwareLayer(unittest.TestCase):
    def setUp(self):
        self.dut = Dut('test_HardwareLayer.yaml')

    def test_write_read_reg(self):
        for val in range(256):
            self.dut['test_register'].set_value(val, 0, size=8, offset=0)
            ret_val = self.dut['test_register'].get_value(0, size=8, offset=0)
            self.assertEqual(ret_val, val)

    def test_write_read_reg_with_bit_str(self):
        val = '00110110'  # 54
        self.dut['test_register'].set_value(val, 0, size=8, offset=0)
        ret_val = self.dut['test_register'].get_value(0, size=8, offset=0)
        self.assertEqual(ret_val, int(val, base=2))

    def test_write_read_reg_with_offset(self):
        for offset in range(32):
            val = 131
            self.dut['test_register'].set_value(val, 0, size=8, offset=offset)
            ret_val = self.dut['test_register'].get_value(0, size=8, offset=offset)
            self.assertEqual(ret_val, val)

    def test_write_read_reg_with_size(self):
        for size in range(8, 33):
            val = 131
            self.dut['test_register'].set_value(val, 0, size=size, offset=7)
            ret_val = self.dut['test_register'].get_value(0, size=size, offset=7)
            self.assertEqual(ret_val, val)

    def test_wrong_size(self):
        self.assertRaises(ValueError, self.dut['test_register'].set_value, 131, addr=0, size=7, offset=7)

if __name__ == '__main__':
    unittest.main()
