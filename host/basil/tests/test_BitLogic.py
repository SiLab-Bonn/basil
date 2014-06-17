#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#

import unittest

from basil.utils.BitLogic import BitLogic
from bitarray import bitarray
import struct
from array import array


class TestBitLogic(unittest.TestCase):
    def setUp(self):
        pass

    def test_from_value_format(self):
        bl = BitLogic.from_value(2232744712, fmt='I')
        self.assertEqual(bl, bitarray('10000101000101001111101100001000'[::-1]))

    def test_from_bit_str(self):
        bl = BitLogic('10000101000101001111101100001000', endian='big')  # 2232744712
        self.assertEqual(bl, bitarray('10000101000101001111101100001000'[::-1]))

    def test_from_value_long_long(self):
        if struct.calcsize("P") == 4:  # 32-bit
            self.assertRaises(struct.error, BitLogic.from_value, 57857885568556688222588556, fmt='Q')
        else:
            bl = BitLogic.from_value(4772894553230993930 * 2, fmt='Q')
            self.assertEqual(bl, bitarray('1000010001111001011101001001110111010111011101011101010000010100'[::-1]))

    def test_from_value_with_size_bigger(self):
        bl = BitLogic.from_value(2232744712, size=70, fmt='Q')
        self.assertEqual(bl, bitarray('10000101000101001111101100001000'[::-1] + '0' * 38))

    def test_from_value_with_size_smaller(self):
        bl = BitLogic.from_value(259, size=9, fmt='Q')
        self.assertEqual(bl, bitarray('100000011'[::-1]))

    def test_to_value(self):
        value = 12
        bl = BitLogic.from_value(value, size=16, fmt='I')
        ret_val = bl.tovalue()
        self.assertEqual(ret_val, value)

    def test_get_item(self):
        bl = BitLogic.from_value(259, size=9, fmt='Q')
        self.assertEqual(bl[0], True)
        self.assertEqual(bl[1], True)
        self.assertEqual(bl[2], False)
        self.assertEqual(bl[3], False)
        self.assertEqual(bl[4], False)
        self.assertEqual(bl[5], False)
        self.assertEqual(bl[6], False)
        self.assertEqual(bl[7], False)
        self.assertEqual(bl[8], True)

    def test_endianness(self):
        '''changing the bit order of each byte
        '''
        bl = BitLogic.from_value(259, size=9, fmt='Q', endian='big')
        self.assertEqual(bl[0], False)
        self.assertEqual(bl[1], False)
        self.assertEqual(bl[2], False)
        self.assertEqual(bl[3], False)
        self.assertEqual(bl[5], False)
        self.assertEqual(bl[6], True)
        self.assertEqual(bl[7], True)
        self.assertEqual(bl[8], False)

    def test_get_item_with_slice(self):
        bl = BitLogic.from_value(12, size=9, fmt='Q')
        self.assertEqual(bl[3:1], bitarray('011'))
        self.assertEqual(bl[:], bitarray('001100000'))
        self.assertEqual(bl[bl.length():], bitarray('001100000'))
        self.assertEqual(bl[len(bl):], bitarray('001100000'))
        self.assertEqual(bl[len(bl):0], bitarray('001100000'))

    def test_set_item(self):
        bl = BitLogic.from_value(8, size=9, fmt='Q')
        self.assertEqual(bl[3], True)
        self.assertEqual(bl[2], False)
        self.assertEqual(bl[4], False)
        bl[2] = True
        self.assertEqual(bl[3], True)
        self.assertEqual(bl[2], True)
        self.assertEqual(bl[4], False)
        bl[4] = []
        self.assertEqual(bl[3], True)
        self.assertEqual(bl[2], True)
        self.assertEqual(bl[4], False)
        bl[4] = [1, 2, 3]
        self.assertEqual(bl[3], True)
        self.assertEqual(bl[2], True)
        self.assertEqual(bl[4], True)

    def test_set_item_with_slice(self):
        ba = bitarray('001100000')
        ba[1:3] = bitarray('11')
        self.assertEqual(ba[:], bitarray('011100000'))
        bl = BitLogic.from_value(12, size=9, fmt='Q')
        self.assertEqual(bl[:], bitarray('001100000'))
        bl[2:1] = bitarray('10')
        self.assertEqual(bl[:], bitarray('010100000'))
        bl[2:1] = bitarray('01')
        self.assertEqual(bl[:], bitarray('001100000'))
        bl[:] = 5
        self.assertEqual(bl[:], bitarray('101000000'))
        bl[5:3] = 5
        self.assertEqual(bl[:], bitarray('101101000'))
        bl[4:4] = bitarray('1')
        self.assertEqual(bl[:], bitarray('101111000'))
        bl[4:4] = 0
        self.assertEqual(bl[:], bitarray('101101000'))

    def test_init_to_zero(self):
        bl = BitLogic(55)
        self.assertEqual(bl, bitarray(55 * '0'))

if __name__ == '__main__':
    unittest.main()
