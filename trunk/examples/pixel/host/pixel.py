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

import yaml
import numpy as np
import time

from basil.dut import Dut
class Pixel(Dut):
    pass

##

stream = open("pixel.yaml", 'r')
cnfg = yaml.load(stream)
chip = Pixel(cnfg)

chip.init()


print 'play with diodes'
for i in range(16):
    chip['PWR']['LED'] = i
    time.sleep(0.5)
    chip['PWR'].write()

#create configuration pattern

#settings for global reg 
chip['GLOBAL_REG']['global_readout_enable'] = 0# size = 1 bit
chip['GLOBAL_REG']['SRDO_load'] = 0# size = 1 bit
chip['GLOBAL_REG']['NCout2'] = 0# size = 1 bit
chip['GLOBAL_REG']['count_hits_not'] = 0# size = 1
chip['GLOBAL_REG']['count_enable'] = 0# size = 1
chip['GLOBAL_REG']['count_clear_not'] = 0# size = 1
chip['GLOBAL_REG']['S0'] = 1# size = 1
chip['GLOBAL_REG']['S1'] = 1# size = 1
chip['GLOBAL_REG']['config_mode'] = 0# size = 2
chip['GLOBAL_REG']['LD_IN0_7'] = 0# size = 8
chip['GLOBAL_REG']['LDENABLE_SEL'] = 0# size = 1
chip['GLOBAL_REG']['SRCLR_SEL'] = 0# size = 1
chip['GLOBAL_REG']['HITLD_IN'] = 0# size = 1
chip['GLOBAL_REG']['NCout21_25'] = 0# size = 5
chip['GLOBAL_REG']['column_address'] = 0# size = 6
chip['GLOBAL_REG']['DisVbn'] = 0# size = 8
chip['GLOBAL_REG']['VbpThStep'] = 0# size = 8
chip['GLOBAL_REG']['PrmpVbp'] = 0# size = 8
chip['GLOBAL_REG']['PrmpVbnFol'] = 0# size = 8
chip['GLOBAL_REG']['vth'] = 0# size = 8
chip['GLOBAL_REG']['PrmpVbf'] = 0# size = 8


#define patter for every output 
#set global register

chip['SEQ']['SHIFT_IN'][0:144] = chip['GLOBAL_REG'][:]
chip['SEQ']['GLOBAL_SHIFT_EN'][0:144] = True

#chip['SEQ']['GLOBAL_SHIFT_EN'][:] = True

#print 'A', chip['GLOBAL_REG'][:], len(chip['SEQ']['SHIFT_IN'][0:176]), type(chip['GLOBAL_REG'][:])
#print 'B', chip['SEQ']['SHIFT_IN'][:200].to01()

chip['SEQ']['GLOBAL_CTR_LD'][146:147] = True
chip['SEQ']['GLOBAL_DAC_LD'][146:147] = True

#set pixel register
chip['PIXEL_REG'][12] = True #just for test
chip['SEQ']['SHIFT_IN'][180:180+128] = chip['PIXEL_REG'][:]
chip['SEQ']['PIXEL_SHIFT_EN'][180:180+128] = True

chip['GLOBAL_REG']['global_readout_enable'] = 0
chip['SEQ']['SHIFT_IN'][310:486] = chip['GLOBAL_REG'][:]
chip['SEQ']['GLOBAL_SHIFT_EN'][310:486] = True

chip['SEQ']['GLOBAL_CTR_LD'][490:491] = True
chip['SEQ']['GLOBAL_DAC_LD'][490:491] = True

#inject
chip['SEQ']['INJECTION'][500:501] = True

print "chip['SEQ'].write(550) writes pattern"
chip['SEQ'].write(550)

chip['SEQ_GEN'].set_size(550) # define size of pattern
chip['SEQ_GEN'].set_repeat(1)

chip['PIXEL_RX'].set_en(True) #enable receiver

print "chip['SEQ_GEN'].start()"
chip['SEQ_GEN'].start()

i = 0
while chip['SEQ_GEN'].is_ready == False:
    time.sleep(0.01)
    print "Wait for done...",i
    i = i + 1 
    
print "chip['DATA'].get_fifo_size()", chip['DATA'].get_fifo_size()
    
print "chip['DATA'].get_data()"
rxd = chip['DATA'].get_data() #get data from sram fifo
print "rxd = ", rxd

data0 = rxd.astype(np.uint8) # Change type to unsigned int 8 bits and take from rxd only the last 8 bits
data1 = np.right_shift(rxd, 8).astype(np.uint8) # Rightshift rxd 8 bits and take again last 8 bits
data = np.reshape(np.vstack((data1, data0)), -1, order='F') # data is now a 1 dimensional array of all bytes read from the FIFO
bdata = np.unpackbits(data).reshape(-1,128)

print "data = ", data
print "bdata = ", bdata
sum =  np.sum(bdata, axis=0)
sum = sum[::-1] # reverse the array
#print sum
