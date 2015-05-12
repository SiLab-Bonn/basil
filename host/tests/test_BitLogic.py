#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest
from bitarray import bitarray
import struct

from basil.utils.BitLogic import BitLogic


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

    def test_from_value_with_int_bigger_than_size(self):
        self.assertRaises(ValueError, BitLogic.from_value, 8, size=3, fmt='Q')

    def test_from_value_with_funny_size(self):
        self.assertRaises(ValueError, BitLogic.from_value, 8, size='123', fmt='Q')

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

    def test_endianness_of_string_assignment(self):
        '''test indexing
        '''
        bl_1 = BitLogic('11001000')
        bl_2 = BitLogic(8)
        bl_2[:] = '11001000'
        self.assertEqual(bl_1, bl_2)

    def test_wrong_size_of_string_assignment(self):
        '''test assignment of wrong length bit string
        '''
        bl_2 = BitLogic(8)

        def assign_fails_slice_all():
            bl_2[:] = '110010000'

        def assign_fails_slice_part_1():
            bl_2[3:] = '11110'

        def assign_fails_slice_part_2():
            bl_2[:4] = '11110'

        def assign_fails_slice_part_3():
            bl_2[4:2] = '11110'

        def assign_fails_slice_part_4():
            bl_2[4:2] = '1'

        self.assertRaises(ValueError, assign_fails_slice_all)
        self.assertRaises(ValueError, assign_fails_slice_part_1)
        self.assertRaises(ValueError, assign_fails_slice_part_2)
        self.assertRaises(ValueError, assign_fails_slice_part_3)
        self.assertRaises(ValueError, assign_fails_slice_part_4)

    def test_indexing(self):
        '''test indexing
        '''
        bl = BitLogic.from_value(128, size=8, fmt='Q', endian='little')
        self.assertEqual(bl[7], True)
        self.assertEqual(bl[7:7], bitarray('1'))
        self.assertEqual(bl[-1], True)
        self.assertEqual(bl[0], False)
        self.assertEqual(bl[0:0], bitarray('0'))

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

        def assign_index(value):
            bl[4] = value

        self.assertRaises(IndexError, lambda val: assign_index(val), [])
        self.assertRaises(IndexError, lambda val: assign_index(val), [1, 2])
        self.assertRaises(IndexError, lambda val: assign_index(val), [True])
        self.assertRaises(IndexError, lambda val: assign_index(val), [False])
        self.assertRaises(IndexError, lambda val: assign_index(val), [True, False])

        def assign_slice(value):
            bl[2:1] = value

        self.assertRaises(IndexError, lambda val: assign_slice(val), [])
        self.assertRaises(IndexError, lambda val: assign_slice(val), [1, 2])
        self.assertRaises(IndexError, lambda val: assign_slice(val), [True])
        self.assertRaises(IndexError, lambda val: assign_slice(val), [False])
        self.assertRaises(IndexError, lambda val: assign_slice(val), [True, False])

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
        bl[5:3] = 7
        self.assertEqual(bl[:], bitarray('101111000'))
        bl[5:3] = 0
        self.assertEqual(bl[:], bitarray('101000000'))
        bl[4:4] = bitarray('1')
        self.assertEqual(bl[:], bitarray('101010000'))
        bl[4:4] = 0
        self.assertEqual(bl[:], bitarray('101000000'))
        bl[8:8] = 1
        self.assertEqual(bl[:], bitarray('101000001'))
        bl[0:0] = 0
        self.assertEqual(bl[:], bitarray('001000001'))
        bl[3:] = '1111'
        self.assertEqual(bl[:], bitarray('111100001'))
        bl[:4] = '11111'
        self.assertEqual(bl[:], bitarray('111111111'))
        bl[2:1] = '00'
        self.assertEqual(bl[:], bitarray('100111111'))
        bl[4:] = 0x0
        self.assertEqual(bl[:], bitarray('000001111'))
        bl[:] = 2 ** 8
        self.assertEqual(bl[:], bitarray('000000001'))
        bl[7] = True
        self.assertEqual(bl[:], bitarray('000000011'))
        bl[8] = False
        self.assertEqual(bl[:], bitarray('000000010'))
        bl[8:8] = True
        self.assertEqual(bl[:], bitarray('000000011'))
        bl[0:0] = True
        self.assertEqual(bl[:], bitarray('100000011'))

    def test_init_to_zero(self):
        bl = BitLogic(55)
        self.assertEqual(bl, bitarray(55 * '0'))

    def test_get_type_slicing_and_indexing(self):
        bl = BitLogic('01000000')
        self.assertIsInstance(bl[3:], bitarray)
        self.assertIsInstance(bl[:3], bitarray)
        self.assertIsInstance(bl[:], bitarray)
        self.assertIsInstance(bl[3:1], bitarray)
        self.assertIsInstance(bl[1:1], bitarray)
        self.assertIsInstance(bl[2:2], bitarray)
        self.assertIsInstance(bl[1], bool)
        self.assertIsInstance(bl[2], bool)

    def test_get_slicing_and_indexing(self):
        bl = BitLogic('10000110')
        self.assertFalse(bl[0])
        self.assertTrue(bl[1])
        self.assertTrue(bl[2])
        self.assertFalse(bl[3])
        self.assertFalse(bl[4])
        self.assertFalse(bl[5])
        self.assertFalse(bl[6])
        self.assertTrue(bl[7])
        self.assertEqual(bl[3:0], bitarray('0110'))
        self.assertEqual(bl[3:0], bitarray('0110'))
        self.assertEqual(bl[3:], bitarray('0110'))
        self.assertEqual(bl[:3], bitarray('00001'))
        self.assertEqual(bl[:], bitarray('01100001'))

    def test_set_slicing_and_indexing(self):
        bl = BitLogic('00000000')
        bl[3:1] = True
        self.assertEqual(bl, bitarray('01110000'))
        bl = BitLogic('11111111')
        bl[3:1] = False
        self.assertEqual(bl, bitarray('10001111'))
        bl = BitLogic('00000000')
        bl[3:1] = 1
        self.assertEqual(bl, bitarray('01000000'))
        bl = BitLogic('11111111')
        bl[3:1] = 0
        self.assertEqual(bl, bitarray('10001111'))

        bl = BitLogic('00000000')

        def assign_slice(value):
            bl[3:1] = value

        self.assertRaises(ValueError, lambda val: assign_slice(val), '1')
        self.assertRaises(ValueError, lambda val: assign_slice(val), bitarray('1'))
        # this has to fail
#         bl = BitLogic('00000000')
#         bl[3:1] = '1'
#         self.assertEqual(bl, bitarray('01000000'))
#         bl = BitLogic('11111111')
#         bl[3:1] = '0'
#         self.assertEqual(bl, bitarray('00000000'))
#         bl = BitLogic('00000000')
#         bl[3:1] = bitarray('1')
#         self.assertEqual(bl, bitarray('01000000'))
#         bl = BitLogic('11111111')
#         bl[3:1] = bitarray('0')
#         self.assertEqual(bl, bitarray('00000000'))

        bl = BitLogic('00000000')
        bl[1] = True
        self.assertEqual(bl, bitarray('01000000'))
        bl = BitLogic('11111111')
        bl[1] = False
        self.assertEqual(bl, bitarray('10111111'))
        bl = BitLogic('00000000')
        bl[1] = 1
        self.assertEqual(bl, bitarray('01000000'))
        bl = BitLogic('11111111')
        bl[1] = 0
        self.assertEqual(bl, bitarray('10111111'))
        bl = BitLogic('00000000')
        bl[1] = '1'
        self.assertEqual(bl, bitarray('01000000'))
        bl = BitLogic('11111111')
        bl[1] = '0'
        self.assertEqual(bl, bitarray('10111111'))
        bl = BitLogic('00000000')
        bl[1] = bitarray('1')
        self.assertEqual(bl, bitarray('01000000'))
        bl = BitLogic('11111111')
        bl[1] = bitarray('0')
        self.assertEqual(bl, bitarray('10111111'))

        bl = BitLogic('00000000')
        bl[1:1] = True
        self.assertEqual(bl, bitarray('01000000'))
        bl = BitLogic('11111111')
        bl[1:1] = False
        self.assertEqual(bl, bitarray('10111111'))
        bl = BitLogic('00000000')
        bl[1:1] = 1
        self.assertEqual(bl, bitarray('01000000'))
        bl = BitLogic('11111111')
        bl[1:1] = 0
        self.assertEqual(bl, bitarray('10111111'))
        bl = BitLogic('00000000')
        bl[1:1] = '1'
        self.assertEqual(bl, bitarray('01000000'))
        bl = BitLogic('11111111')
        bl[1:1] = '0'
        self.assertEqual(bl, bitarray('10111111'))
        bl = BitLogic('00000000')
        bl[1:1] = bitarray('1')
        self.assertEqual(bl, bitarray('01000000'))
        bl = BitLogic('11111111')
        bl[1:1] = bitarray('0')
        self.assertEqual(bl, bitarray('10111111'))

    def test_set_item_negative(self):
        bl = BitLogic('00000000')
        bl[-3] = True
        self.assertEqual(bl, bitarray('00000100'))
        bl[-3] = False
        self.assertEqual(bl, bitarray('00000000'))
        bl[-3:-3] = True
        self.assertEqual(bl, bitarray('00000100'))
        bl[-3:-3] = False
        self.assertEqual(bl, bitarray('00000000'))
        bl[-3] = 1
        self.assertEqual(bl, bitarray('00000100'))
        bl[-3] = 0
        self.assertEqual(bl, bitarray('00000000'))
        bl[-3:-3] = 1
        self.assertEqual(bl, bitarray('00000100'))
        bl[-3:-3] = 0
        self.assertEqual(bl, bitarray('00000000'))
        bl[-3] = '1'
        self.assertEqual(bl, bitarray('00000100'))
        bl[-3] = '0'
        self.assertEqual(bl, bitarray('00000000'))
        bl[-3:-3] = '1'
        self.assertEqual(bl, bitarray('00000100'))
        bl[-3:-3] = '0'
        self.assertEqual(bl, bitarray('00000000'))

        bl[-1] = True
        self.assertEqual(bl, bitarray('00000001'))
        bl[-1] = False
        self.assertEqual(bl, bitarray('00000000'))
        bl[-1:-1] = True
        self.assertEqual(bl, bitarray('00000001'))
        bl[-1:-1] = False
        self.assertEqual(bl, bitarray('00000000'))
        bl[-1] = 1
        self.assertEqual(bl, bitarray('00000001'))
        bl[-1] = 0
        self.assertEqual(bl, bitarray('00000000'))
        bl[-1:-1] = 1
        self.assertEqual(bl, bitarray('00000001'))
        bl[-1:-1] = 0
        self.assertEqual(bl, bitarray('00000000'))
        bl[-1] = '1'
        self.assertEqual(bl, bitarray('00000001'))
        bl[-1] = '0'
        self.assertEqual(bl, bitarray('00000000'))
        bl[-1:-1] = '1'
        self.assertEqual(bl, bitarray('00000001'))
        bl[-1:-1] = '0'
        self.assertEqual(bl, bitarray('00000000'))

        bl[-8] = True
        self.assertEqual(bl, bitarray('10000000'))
        bl[-8] = False
        self.assertEqual(bl, bitarray('00000000'))
        bl[-8:-8] = True
        self.assertEqual(bl, bitarray('10000000'))
        bl[-8:-8] = False
        self.assertEqual(bl, bitarray('00000000'))
        bl[-8] = 1
        self.assertEqual(bl, bitarray('10000000'))
        bl[-8] = 0
        self.assertEqual(bl, bitarray('00000000'))
        bl[-8:-8] = 1
        self.assertEqual(bl, bitarray('10000000'))
        bl[-8:-8] = 0
        self.assertEqual(bl, bitarray('00000000'))
        bl[-8] = '1'
        self.assertEqual(bl, bitarray('10000000'))
        bl[-8] = '0'
        self.assertEqual(bl, bitarray('00000000'))
        bl[-8:-8] = '1'
        self.assertEqual(bl, bitarray('10000000'))
        bl[-8:-8] = '0'
        self.assertEqual(bl, bitarray('00000000'))

        bl[-7:-8] = 2
        self.assertEqual(bl, bitarray('01000000'))
        bl[-2:-3] = 2
        self.assertEqual(bl, bitarray('01000010'))
        bl[-1:-2] = 2
        self.assertEqual(bl, bitarray('01000001'))

if __name__ == '__main__':
    unittest.main()
