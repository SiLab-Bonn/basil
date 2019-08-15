# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#


from basil.dut import Dut

chip = Dut("simple_register_example.yaml")

print(chip['TEST'])
print(chip['REG'])

# chip['REG'][0] = 1
chip['REG']['VPULSE'][5] = 1
# chip['REG']['VPULSE'] = 1

# chip['REG']['COLUMN'][0] = 1 # does not work yet
# chip['REG'][0] = 1 # does not work yet

chip['REG']['COLUMN'][0]['EnR'] = 1
chip['REG']['COLUMN'][0]['DACR'] = 3

chip['REG']['VINJECT'] = 3
print(chip['REG'])

chip['REG']['VINJECT'][0] = 1
print(chip['REG'])

print('VINJECT {}'.format(str(chip['REG']['VINJECT'])))
