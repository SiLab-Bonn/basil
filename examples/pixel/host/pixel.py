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

#create configuration pattern

#settings for global reg 
chip['GLOBAL_REG']['global_readout_enable'] = 1
chip['GLOBAL_REG']['NCout2'] = 1

#print type(chip['GLOBAL_REG'][:]), len(chip['SEQ']['SHIFT_IN'][0:176]), chip['GLOBAL_REG']

#define patter for every ouput 
#set global register  
chip['SEQ']['SHIFT_IN'][0:176] = chip['GLOBAL_REG'][:]
chip['SEQ']['GLOBAL_SHIFT_EN'][0:176] = True

chip['SEQ']['GLOBAL_CTR_LD'][178:179] = True
chip['SEQ']['GLOBAL_DAC_LD'][178:179] = True

#set pixel register
chip['SEQ']['SHIFT_IN'][180:180+128] = chip['PIXEL_REG'][:]
chip['SEQ']['PIXEL_SHIFT_EN'][180:180+128] = True

chip['GLOBAL_REG']['global_readout_enable'] = 0
chip['SEQ']['SHIFT_IN'][210:386] = chip['GLOBAL_REG'][:]
chip['SEQ']['GLOBAL_SHIFT_EN'][210:386] = True

chip['SEQ']['GLOBAL_CTR_LD'][390:391] = True
chip['SEQ']['GLOBAL_DAC_LD'][390:391] = True

#inject
chip['SEQ']['INJECTION'][400:401] = True

chip['SEQ'].write()

chip['SEQ_GEN'].set_size(450) # define size of pattern
chip['SEQ_GEN'].set_repeat(1)

chip['PIXEL_RX'].set_en(True) #enable reciver

chip['SEQ_GEN'].start()

#while chip['SEQ_GEN'].is_ready == False:
#    time.sleep(0.01)
    
rxd = chip['DATA'].get_data() #get data from sram fifo
#print rxd

data0 = rxd.astype(np.uint8) # Change type to unsigned int 8 bits and take from rxd only the last 8 bits
data1 = np.right_shift(rxd, 8).astype(np.uint8) # Rightshift rxd 8 bits and take again last 8 bits
data = np.reshape(np.vstack((data1, data0)), -1, order='F') # data is now a 1 dimensional array of all bytes read from the FIFO
bdata = np.unpackbits(data).reshape(-1,352)
sum =  np.sum(bdata, axis=0)
sum = sum[::-1] # reverse the array

#print sum


    

