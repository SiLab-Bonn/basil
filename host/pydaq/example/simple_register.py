import yaml

import sys
sys.path.append('../')

from pydaq import Dut

setup_file = open("simple_register.yaml", 'r')
cnfg = yaml.load(setup_file)

chip = Dut(cnfg)

print(chip['TEST'])
print(chip['REG'])


chip['REG'][0] = 1
chip['REG']['VPULSE'][5] = 1
#chip['REG']['VPULSE'] = 1

#chip['REG']['COL'][0] = 1 # does not work yet

chip['REG']['COL'][0]['B'] = 1

chip['REG']['VINJECT'] = 1
chip['REG']['VINJECT'][0] = 1

print(chip['REG'])
print('VINJECT', str(chip['REG']['VINJECT']))




