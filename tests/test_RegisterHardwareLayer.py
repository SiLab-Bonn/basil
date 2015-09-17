#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest

from basil.dut import Dut
from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


_test_init = {
    'REG_test_init': 15,
    'REG1': 120,
    'REG_byte_array': [4, 3, 2, 1]
}


class test_RegisterHardwareLayer(RegisterHardwareLayer):
    '''Register Hardware Layer.

    Implementation of advanced register operations.
    '''
    _registers = {
        'REG1': {'default': 12, 'descr': {'addr': 0, 'size': 15, 'offset': 0}},
        'REG2': {'default': 1, 'descr': {'addr': 1, 'size': 1, 'offset': 7}},
        'REG3': {'default': 2 ** 16 - 1, 'descr': {'addr': 2, 'size': 16, 'offset': 0}},
        'REG4_ro': {'default': 0, 'descr': {'addr': 4, 'size': 8, 'properties': ['readonly']}},
        'REG5_wo': {'default': 0, 'descr': {'addr': 5, 'size': 8, 'properties': ['writeonly']}},
        'REG_test_init': {'descr': {'addr': 6, 'size': 8}},
        'REG_byte_array': {'default': [1, 2, 3, 4], 'descr': {'addr': 16, 'size': 4, 'properties': ['bytearray']}}
    }


class TestRegisterHardwareLayer(unittest.TestCase):
    def setUp(self):
        self.dut = Dut('test_RegisterHardwareLayer.yaml')
        self.dut.init()

    def test_lazy_programming(self):
        self.dut['test_register'].set_default()
        self.assertDictEqual({0: 12, 1: 128, 2: 255, 3: 255, 5: 0, 16: 1, 17: 2, 18: 3, 19: 4}, self.dut['dummy_tl'].mem)
        self.dut['test_register'].REG5_wo = 255
        self.assertDictEqual({0: 12, 1: 128, 2: 255, 3: 255, 5: 255, 16: 1, 17: 2, 18: 3, 19: 4}, self.dut['dummy_tl'].mem)
        self.dut['test_register'].REG5_wo  # get value from write-only register, but this will write zero instead
        self.assertDictEqual({0: 12, 1: 128, 2: 255, 3: 255, 5: 0, 16: 1, 17: 2, 18: 3, 19: 4}, self.dut['dummy_tl'].mem)

    def test_get_configuration(self):
        self.dut.set_configuration('test_RegisterHardwareLayer_configuration.yaml')
        conf = self.dut['test_register'].get_configuration()
        self.assertDictEqual({'REG1': 0, 'REG2': 1, 'REG3': 2, 'REG_test_init': 0, 'REG_byte_array': [1, 2, 3, 4]}, conf)

    def test_set_configuration(self):
        self.dut.set_configuration('test_RegisterHardwareLayer_configuration.yaml')
        self.assertDictEqual({0: 0, 1: 128, 2: 2, 3: 0, 5: 5, 16: 1, 17: 2, 18: 3, 19: 4}, self.dut['dummy_tl'].mem)

    def test_read_only(self):
        self.assertRaises(IOError, self.dut['test_register']._set, 'REG4_ro', value=0)

#     def test_write_only(self):
#         self.assertRaises(IOError, self.dut['test_register']._get, 'REG5_wo')

    def test_write_only_lazy_programming(self):
        self.dut['test_register'].set_default()
        self.assertDictEqual({0: 12, 1: 128, 2: 255, 3: 255, 5: 0, 16: 1, 17: 2, 18: 3, 19: 4}, self.dut['dummy_tl'].mem)
        self.dut['test_register'].REG5_wo = 20
        self.assertDictEqual({0: 12, 1: 128, 2: 255, 3: 255, 5: 20, 16: 1, 17: 2, 18: 3, 19: 4}, self.dut['dummy_tl'].mem)
        self.dut['test_register'].REG5_wo
        self.assertDictEqual({0: 12, 1: 128, 2: 255, 3: 255, 5: 0, 16: 1, 17: 2, 18: 3, 19: 4}, self.dut['dummy_tl'].mem)
        self.assertIs(None, self.dut['test_register']._get('REG5_wo'))

    def test_set_default(self):
        self.dut['test_register'].set_default()
        self.assertDictEqual({0: 12, 1: 128, 2: 255, 3: 255, 5: 0, 16: 1, 17: 2, 18: 3, 19: 4}, self.dut['dummy_tl'].mem)

    def test_set_attribute_add(self):
        val = self.dut['test_register']._registers['REG1']['default']
        self.dut['test_register'].REG1 = val  # 12
        mem = self.dut['dummy_tl'].mem.copy()
        self.dut['test_register'].REG1 += 1  # 13
        mem[0] = 13
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

    def test_write_read_reg(self):
        for reg in ['REG1', 'REG2', 'REG3']:
            val = self.dut['test_register']._registers[reg]['default']
            self.dut['test_register']._set(reg, val)
            ret_val = self.dut['test_register']._get(reg)
            self.assertEqual(ret_val, val)
        self.assertDictEqual({0: 12, 1: 128, 2: 255, 3: 255, 5: 0, 16: 1, 17: 2, 18: 3, 19: 4}, self.dut['dummy_tl'].mem)

    def test_set_attribute_by_value(self):
        self.dut['test_register'].set_default()
        self.assertDictEqual({0: 12, 1: 128, 2: 255, 3: 255, 5: 0, 16: 1, 17: 2, 18: 3, 19: 4}, self.dut['dummy_tl'].mem)
        self.dut['test_register'].REG2 = 0
        mem = self.dut['dummy_tl'].mem.copy()
        mem[1] = 0
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

    def test_set_attribute_by_string(self):
        mem = self.dut['dummy_tl'].mem.copy()
        self.dut['test_register'].REG3 = '1010101010101010'  # dfghfghdfghgfdghf
        mem[2] = 170
        mem[3] = 170
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

    def test_get_attribute_by_string(self):
        self.dut['test_register'].REG3 = '1010101010101010'  # 43690
        self.assertEqual(43690, self.dut['test_register'].REG3)

    def test_set_attribute_too_long_string(self):
        val = '11010101010101010'  # 17 bit
        self.assertRaises(ValueError, self.dut['test_register']._set, 'REG3', value=val)

    def test_set_attribute_dict_access(self):
        self.dut['test_register']['REG1'] = 27306  # 27306
        self.assertEqual(27306, self.dut['test_register']['REG1'])

    def test_set_attribute_too_big_val(self):
        val = 2 ** 16  # max 2 ** 16 - 1
        self.assertRaises(ValueError, self.dut['test_register']._set, 'REG3', value=val)

    def test_set_by_function(self):
        self.dut['test_register'].set_REG1(27308)
        self.assertEqual(27308, self.dut['test_register']['REG1'])

    def test_get_by_function(self):
        self.dut['test_register']['REG1'] = 27305  # 27306
        ret = self.dut['test_register'].get_REG1()
        self.assertEqual(ret, self.dut['test_register']['REG1'])

    def test_init_with_dict(self):
        self.dut['test_register'].set_default()
        self.dut.init({'test_register': _test_init})
        conf = self.dut.get_configuration()
        self.assertDictEqual({'test_register': {'REG1': 120, 'REG2': 1, 'REG3': 65535, 'REG_test_init': 15, 'REG_byte_array': [4, 3, 2, 1]}, 'dummy_tl': {}}, conf)

    def test_get_dut_configuration(self):
        self.dut['test_register'].set_default()
        conf = self.dut.get_configuration()
        self.assertDictEqual({'test_register': {'REG1': 12, 'REG2': 1, 'REG3': 65535, 'REG_test_init': 0, 'REG_byte_array': [1, 2, 3, 4]}, 'dummy_tl': {}}, conf)

    def test_get_set_value(self):
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
