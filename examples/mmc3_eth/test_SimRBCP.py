# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import time
import random
from basil.dut import Dut

chip = Dut("mmc3_eth.yaml")
chip.init()

addr_b1 = int('0xff',16)
addr_b2 = int('0xff',16)
addr_b3 = int('0xfc',16)
addr_b4 = int('0x00',16)

num=16;
offset=0;


#read whole memory
for i in range(256/num):
    addr = addr_b1*(2**24) + addr_b2*(2**16) + addr_b3*(2**8) + addr_b4
    data = range(offset,offset+num)   
    #data = [random.randint(0,255) for r in xrange(num)]

    print '\n#reading from base address ', hex(addr);

    ret1 = chip._transfer_layer['intf'].read(addr,num)
    print ret1

    #print '\n#writing data: ',data
    #chip._transfer_layer['intf'].write(addr, data)

    addr_b4 += int(num)
    offset += num


#configure eeprom with flags and ip address according to SiTCP documentation
addr = int('0xfffffcff',16)
data = [int('0x00',16)]
print ("\n#writing data: %s to address %s" % (data, hex(addr)))
chip._transfer_layer['intf'].write(addr, data)
ret = chip._transfer_layer['intf'].read(addr,len(data))
print ('\n#read back: \n', ret)

addr = int('0xfffffc18',16)
data = [192,168,10,16]
print ("\n#writing data: %s to address %s" % (data, hex(addr)))
chip._transfer_layer['intf'].write(addr, data)
ret = chip._transfer_layer['intf'].read(addr,len(data))
print ('\n#read back: \n', ret)

