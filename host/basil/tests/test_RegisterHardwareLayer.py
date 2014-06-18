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

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer
from basil.TL.Dummy import Dummy


class MyHardwareLayer(RegisterHardwareLayer):
    '''Register Hardware Layer.

    Implementation of advanced register operations.
    '''
    _registers = {'REG1': {'default': 12, 'current': None, 'descr': {'addr': 0, 'size': 15, 'offset': 0}},
                  'REG2': {'default': 1, 'current': None, 'descr': {'addr': 1, 'size': 1, 'offset': 7}},
                  'REG3': {'default': 2 ** 16 - 1, 'current': None, 'descr': {'addr': 2, 'size': 16, 'offset': 0}},
    }


class TestRegisterHardwareLayer(unittest.TestCase):
    def setUp(self):
        dummy = Dummy(conf=None)
        self.hl = MyHardwareLayer(dummy, {'base_addr': 0})

    def test_set_default(self):
        self.hl.set_default()
        self.assertDictEqual({0: 12, 1: 128, 2: 255, 3: 255}, self.hl._intf.mem)

    def test_set_attribute_add(self):
        mem = self.hl._intf.mem
        val = self.hl._registers['REG1']['default']
        self.hl.REG1 = val  # 12
        self.hl.REG1 += 1  # 13
        mem[0] = 13
        self.assertDictEqual(mem, self.hl._intf.mem)

    def test_write_read_reg(self):
        for reg in self.hl._registers.iterkeys():
            val = self.hl._registers[reg]['default']
            self.hl.set(reg, val)
            ret_val = self.hl.get(reg)
            self.assertEqual(ret_val, val)
        self.assertDictEqual({0: 12, 1: 128, 2: 255, 3: 255}, self.hl._intf.mem)

    def test_set_attribute_by_value(self):
        mem = self.hl._intf.mem
        self.hl.REG2 = 0
        mem[1] += 128
        self.assertDictEqual(mem, self.hl._intf.mem)

    def test_set_attribute_by_string(self):
        mem = self.hl._intf.mem
        self.hl.REG3 = '1010101010101010'
        mem[2] = 170
        mem[3] = 170
        self.assertDictEqual(mem, self.hl._intf.mem)

    def test_get_attribute_by_string(self):
        self.hl.REG3 = '1010101010101010'  # 43690
        self.assertEqual(43690, self.hl.REG3)

    def test_set_attribute_too_long_string(self):
        val = '11010101010101010'  # 17 bit
        self.assertRaises(ValueError, self.hl.set, 'REG3', value=val)

    def test_set_attribute_dict_access(self):
        self.hl['REG1'] = 27306  # 27306
        self.assertEqual(27306, self.hl['REG1'])

    def test_set_attribute_too_big_val(self):
        val = 2 ** 16  # max 2 ** 16 - 1
        self.assertRaises(ValueError, self.hl.set, 'REG3', value=val)

if __name__ == '__main__':
    unittest.main()
