#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest
import yaml

from bitarray import bitarray

from basil.dut import Dut


cnfg_yaml = """
transfer_layer:
    - name  : dummy_tl
      type  : Dummy
      init:
          mem : {0: 2, 14: 4} # module version for init of spi and mem bytes

hw_drivers:
  - name      : spi_module
    type      : spi
    interface : dummy_tl
    base_addr : 0x0

registers:
  - name        : TEST1
    type        : StdRegister
    hw_driver   : spi_module
    size        : 32

  - name        : TEST2
    type        : StdRegister
    hw_driver   : spi_module
    size        : 20
    fields  :
          - name     : VINJECT
            size     : 6
            offset   : 19
            bit_order: [5,4,3,1,0,2]
            default  : 0
          - name     : VPULSE
            size     : 6
            offset   : 13
          - name     : EN
            size     : 2
            offset   : 7
          - name     : COLUMN
            offset   : 5
            size     : 3
            repeat   : 2
            fields   :
              - name     : EnR
                size     : 1
                offset   : 2
              - name     : DACR
                size     : 2
                offset   : 1
"""


class TestClass(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.cnfg = yaml.safe_load(cnfg_yaml)
        cls.dut = Dut(cls.cnfg)
        cls.dut['spi_module']._require_version = "==2"
        cls.dut.init()
        cls.dut['spi_module']._mem_bytes = 4

    def test_mem_bytes(self):
        self.dut.init()
        self.dut['spi_module']._mem_bytes = 4
        self.assertEqual(4, self.dut['spi_module'].MEM_BYTES)
        self.assertRaises(ValueError, self.dut['spi_module'].set_data, [1, 2, 3, 4, 5])

    def test_init_simple(self):
        self.dut['TEST1'].write()
        mem = dict()
#         mem[0] = 0  # reset
#         mem[0] = 1
        mem[16] = 0  # has an offset of 16 bytes
        mem[17] = 0
        mem[18] = 0
        mem[19] = 0
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST1'][0] = 1
        self.dut['TEST1'].write()
        mem[19] = 1
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST1'][31] = 1
        self.dut['TEST1'].write()
        mem[16] = 0x80
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST1'] = 0
        self.dut['TEST1'].write()
        mem[16] = 0
        mem[19] = 0
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST1'] = 0xa55a8001
        self.dut['TEST1'].write()
        mem[16] = 0xa5
        mem[17] = 0x5a
        mem[18] = 0x80
        mem[19] = 0x01
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST1'] = 0
        self.dut['TEST1'][11:4] = 0xff
        self.dut['TEST1'].write()
        mem[16] = 0x0
        mem[17] = 0x0
        mem[18] = 0x0f
        mem[19] = 0xf0
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST1'] = 0
        self.dut['TEST1'][11:4] = '10000001'
        self.dut['TEST1'].write()
        mem[16] = 0x0
        mem[17] = 0x0
        mem[18] = 0x08
        mem[19] = 0x10
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST1'] = 0
        self.dut['TEST1'][11:4] = bitarray('00011000')
        self.dut['TEST1'].write()
        mem[16] = 0x0
        mem[17] = 0x0
        mem[18] = 0x01
        mem[19] = 0x80
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

    def test_bit_order(self):
        self.dut['TEST2'].write()
        mem = dict()
#         mem[0] = 0  # reset
        mem[0] = 2
        mem[14] = 4
        mem[16] = 0
        mem[17] = 0
        mem[18] = 0
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['VINJECT'] = 0x01
        self.dut['TEST2'].write()
        mem[16] = 0x08
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['VINJECT'] = 0x02
        self.dut['TEST2'].write()
        mem[16] = 0x10
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['VINJECT'] = 0x04
        self.dut['TEST2'].write()
        mem[16] = 0x04
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['VINJECT'] = 0x08
        self.dut['TEST2'].write()
        mem[16] = 0x20
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['VINJECT'] = 0
        self.dut['TEST2']['VINJECT'][0] = 1
        self.dut['TEST2'].write()
        mem[16] = 0x04
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

    def test_repeat(self):
        self.dut['dummy_tl'].mem = dict()
#         self.dut['TEST2'] = 0
        self.dut['TEST2']['VINJECT'] = 0
        self.dut['TEST2']['VPULSE'] = 0
        self.dut['TEST2'].write()
        mem = dict()
#         mem[0] = 1
        mem[16] = 0
        mem[17] = 0
        mem[18] = 0
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['COLUMN'][0]['EnR'] = 1
        self.dut['TEST2'].write()
        mem[17] = 0x02
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['COLUMN'][1]['DACR'] = 1
        self.dut['TEST2'].write()
        mem[18] = 0x10
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

    def test_default(self):
        self.cnfg['registers'][1]['fields'][0]['default'] = 0x01  # VINJECT
        self.dut = Dut(self.cnfg)
        self.dut['spi_module']._require_version = "==2"
        self.dut.init()
        self.dut['spi_module']._mem_bytes = 32
        mem = dict()
#         mem[0] = 0  # reset
        mem[0] = 2
        mem[14] = 4
        mem[16] = 0x08
        mem[17] = 0
        mem[18] = 0
        self.dut['TEST2'].write()
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

    def test_fields(self):
        self.dut['dummy_tl'].mem = dict()
        self.dut['TEST2']['VINJECT'] = 0
        self.dut['TEST2']['VPULSE'] = 0
        self.dut['TEST2'].write()
        mem = dict()
#         mem[0] = 1
        mem[16] = 0
        mem[17] = 0
        mem[18] = 0
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['VPULSE'] = 0x5
        self.dut['TEST2'].write()
        mem = dict()
        mem[16] = 0
        mem[17] = 0x50
        mem[18] = 0
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['VPULSE'] = bitarray('100001')
        self.dut['TEST2'].write()
        mem = dict()
        mem[16] = 0x02
        mem[17] = 0x10
        mem[18] = 0
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['VPULSE'] = '100001'
        self.dut['TEST2'].write()
        mem = dict()
        mem[16] = 0x02
        mem[17] = 0x10
        mem[18] = 0
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)

        self.dut['TEST2']['VPULSE'] = 0b100011
        self.dut['TEST2'].write()
        mem = dict()
        mem[16] = 0x02
        mem[17] = 0x30
        mem[18] = 0
        self.assertDictEqual(mem, self.dut['dummy_tl'].mem)


if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(TestClass)
    unittest.TextTestRunner(verbosity=2).run(suite)
