#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev:: 261                   $:
#  $Author:: jejan              $:
#  $Date:: 2014-06-06 15:16:45 #$:
#

import unittest

from basil.HL.HardwareLayer import HardwareLayer
from basil.TL.Dummy import Dummy


class TestHardwareLayer(unittest.TestCase):
    def setUp(self):
        dummy = Dummy(conf=None)
        self.hl = HardwareLayer(dummy, {'base_addr': 0})

    def test_write_read_reg(self):
        for val in range(256):
            self.hl._set(val, 0, size=8, offset=0)
            ret_val = self.hl._get(0, size=8, offset=0)
            self.assertEqual(ret_val, val)

    def test_write_read_reg_with_offset(self):
        for offset in range(32):
            val = 131
            self.hl._set(val, 0, size=8, offset=offset)
            ret_val = self.hl._get(0, size=8, offset=offset)
            self.assertEqual(ret_val, val)

    def test_write_read_reg_with_size(self):
        for size in range(8, 33):
            val = 131
            self.hl._set(val, 0, size=size, offset=7)
            ret_val = self.hl._get(0, size=size, offset=7)
            self.assertEqual(ret_val, val)

    def test_wrong_size(self):
        self.assertRaises(ValueError, self.hl._set, 131, addr=0, size=7, offset=7)

if __name__ == '__main__':
    unittest.main()
