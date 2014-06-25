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


from basil.dut import Dut
from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer
from basil.TL.Dummy import Dummy


class MyRegisterHardwareLayer(RegisterHardwareLayer):
    '''Register Hardware Layer.

    Implementation of advanced register operations.
    '''
    _registers = {'REG1': {'default': 12, 'current': None, 'descr': {'addr': 0, 'size': 15, 'offset': 0}},
                  'REG2': {'default': 1, 'current': None, 'descr': {'addr': 1, 'size': 1, 'offset': 7}},
                  'REG3': {'default': 2 ** 16 - 1, 'current': None, 'descr': {'addr': 2, 'size': 16, 'offset': 0}},
                  'REG4_ro': {'default': 0, 'descr': {'addr': 4, 'size': 8, 'properties': ['readonly']}},
                  'REG5_wo': {'default': 0, 'descr': {'addr': 5, 'size': 8, 'properties': ['writeonly']}},
    }


class TestRegisterHardwareLayer(unittest.TestCase):
    def setUp(self):
        self.dut = Dut('test_RegisterHardwareLayer.yaml')
        self.dut._hardware_layer['test_register'] = MyRegisterHardwareLayer(self.dut['test_register']._intf, self.dut['test_register']._conf)
        self.dut.init()

    def test_get_dut_configuration(self):
        self.dut['test_register'].set_default()
        conf = self.dut.get_configuration()
        self.assertDictEqual({'test_register': {'REG1': 12, 'REG2': 1, 'REG3': 65535, 'REG4_ro': 0}, 'dummy_tl': {}}, conf)

    def test_get_configuration(self):
        self.dut.set_configuration('test_RegisterHardwareLayer_configuration.yaml')
        conf = self.dut['test_register'].get_configuration()
        self.assertDictEqual({'REG1': 0, 'REG2': 1, 'REG3': 2, 'REG4_ro': 0}, conf)

    def test_set_configuration(self):
        self.dut.set_configuration('test_RegisterHardwareLayer_configuration.yaml')
        self.assertDictEqual({0: 0, 1: 128, 2: 2, 3: 0, 5: 5}, self.dut['dummy_tl'].mem)

    def test_read_only(self):
        self.assertRaises(IOError, self.dut['test_register']._set, 'REG4_ro', value=0)

    def test_write_only(self):
        self.assertRaises(IOError, self.dut['test_register']._get, 'REG5_wo')

    def test_set_default(self):
        self.dut['test_register'].set_default()
        self.assertDictEqual({0: 12, 1: 128, 2: 255, 3: 255, 5: 0}, self.dut['dummy_tl'].mem)

    def test_set_attribute_add(self):
        mem = self.dut['dummy_tl'].mem
        val = self.dut['test_register']._registers['REG1']['default']
        self.dut['test_register'].REG1 = val  # 12
        self.dut['test_register'].REG1 += 1  # 13
        mem[0] = 13
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

    def test_write_read_reg(self):
        for reg in ['REG1', 'REG2', 'REG3']:
            val = self.dut['test_register']._registers[reg]['default']
            self.dut['test_register']._set(reg, val)
            ret_val = self.dut['test_register']._get(reg)
            self.assertEqual(ret_val, val)
        self.assertDictEqual({0: 12, 1: 128, 2: 255, 3: 255}, self.dut['dummy_tl'].mem)

    def test_set_attribute_by_value(self):
        mem = self.dut['dummy_tl'].mem
        self.dut['test_register'].REG2 = 0
        mem[1] += 128
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

    def test_set_attribute_by_string(self):
        mem = self.dut['dummy_tl'].mem
        self.dut['test_register'].REG3 = '1010101010101010'
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

if __name__ == '__main__':
    unittest.main()
