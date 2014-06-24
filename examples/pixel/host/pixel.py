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
from bitarray import bitarray

from basil.dut import Dut

# rename Dut to Pixel
class Pixel(Dut):
    
    def program_global_reg(self):
        
        self.cler_strobes()
        
        gr_size = len(self['GLOBAL_REG'][:]) #get the size
        self['SEQ']['SHIFT_IN'][0:gr_size] = self['GLOBAL_REG'][:] # this will be shifted out
        self['SEQ']['INJECTION'][0:gr_size] = self['GLOBAL_REG'][:] # this will be shifted out
        self['SEQ']['GLOBAL_SHIFT_EN'][0:gr_size] = bitarray( gr_size * '1') #this is to enable clock
        self['SEQ']['GLOBAL_CTR_LD'][gr_size+1:gr_size+2] = bitarray("1") # load signals
        self['SEQ']['GLOBAL_DAC_LD'][gr_size+1:gr_size+2] = bitarray("1")

        # those function will run on driver SEQ_GEN but this is python magic
        self['SEQ'].write(gr_size+3) #write pattern to memeory
        
        self.run_seq(gr_size+3)
    
    def program_pixel_reg(self):
        
        self.cler_strobes()
        
        px_size = len(self['PIXEL_REG'][:]) #get the size
        self['SEQ']['SHIFT_IN'][0:px_size] = self['PIXEL_REG'][:] # this will be shifted out
        self['SEQ']['INJECTION'][0:px_size] = self['PIXEL_REG'][:] # this will be shifted out
        self['SEQ']['PIXEL_SHIFT_EN'][0:px_size] = bitarray( px_size * '1') #this is to enable clock
        
        self['SEQ'].write(px_size+1) #write pattern to memeory(add 1 bit more so there is 0 at the end other way will stay high)
        
        self.run_seq(px_size+1)
            
    def run_seq(self, size):
        self['SEQ'].set_size(size)  # set size
        self['SEQ'].set_repeat(1) # set reapet
        self['SEQ'].start() # start
        
        i = 0
        while not chip['SEQ'].get_done():
            time.sleep(0.01)
            print "Wait for done...",i
            i = i + 1

    def cler_strobes(self):
        #reset some stuff
        self['SEQ']['GLOBAL_SHIFT_EN'].setall(False)
        self['SEQ']['GLOBAL_CTR_LD'].setall(False)
        self['SEQ']['GLOBAL_DAC_LD'].setall(False)
        self['SEQ']['PIXEL_SHIFT_EN'].setall(False)
        
        
# Read in the configuration YAML file
stream = open("pixel.yaml", 'r')
cnfg = yaml.load(stream)

# Create the Pixel object
chip = Pixel(cnfg)

try:      
    # Initialize the chip
    chip.init()
except NotImplementedError: # this is to make simulation not fail
    print 'chip.init() :: NotImplementedError'
    
# turn on the adapter card's power
chip['PWR']['EN_VD1'] = 1
chip['PWR']['EN_VD2'] = 1
chip['PWR']['EN_VA1'] = 1
chip['PWR']['EN_VA2'] = 1
chip['PWR'].write()

# Set the output voltage on the pins
chip['PWRAC'].set_voltage("VDDD1",1.2)
print "VDDD1", chip['PWRAC'].get_voltage("VDDD1"), chip['PWRAC'].get_current("VDDD1")

# set inputs to chip
# all inputs must end up assigned to a field in chip['SEQ']
# when chip['SEQ'] is set up, call
# chip['SEQ'].write(num_bits)
# chip['SEQ_GEN'].set_size(num_bits)
# chip['SEQ_GEN'].set_repeat(0->forever, n->n times)
# chip['SEQ_GEN'].start()

#settings for global register
chip['GLOBAL_REG']['global_readout_enable'] = 1# size = 1 bit
chip['GLOBAL_REG']['SRDO_load'] = 0# size = 1 bit
chip['GLOBAL_REG']['NCout2'] = 1# size = 1 bit
chip['GLOBAL_REG']['count_hits_not'] = 0# size = 1
chip['GLOBAL_REG']['count_enable'] = 1# size = 1
chip['GLOBAL_REG']['count_clear_not'] = 0# size = 1
chip['GLOBAL_REG']['S0'] = 1# size = 1
chip['GLOBAL_REG']['S1'] = 0# size = 1
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

print "program global register..."
chip.program_global_reg()


chip['PIXEL_RX'].set_en(True) #enable receiver it work only if pixel register is enabled/clocked

#set something to pixel register
#chip['PIXEL_REG'][2] = 1
#chip['PIXEL_REG'][3] = 1

chip['PIXEL_REG'][:] = bitarray('1'*128)
chip['PIXEL_REG'][0] = 0

print "program pixel register..."
chip.program_pixel_reg()


#chip['SEQ']['PIXEL_SHIFT_EN'][0:6] = bitarray("011111")
#chip['SEQ']['INJECTION'][0:6] = bitarray("101010")


#define pattern for every output 
#set global register
#
#chip['SEQ']['SHIFT_IN'][0:144] = chip['GLOBAL_REG'][:]
#chip['SEQ']['GLOBAL_SHIFT_EN'][0:144] = True
#
#chip['SEQ']['GLOBAL_CTR_LD'][146:147] = True
#chip['SEQ']['GLOBAL_DAC_LD'][146:147] = True
#
##set pixel register
#chip['PIXEL_REG'][12] = True #just for test
#chip['SEQ']['SHIFT_IN'][180:180+128] = chip['PIXEL_REG'][:]
#chip['SEQ']['PIXEL_SHIFT_EN'][180:180+128] = True
#
#chip['GLOBAL_REG']['global_readout_enable'] = 0
#chip['SEQ']['SHIFT_IN'][310:486] = chip['GLOBAL_REG'][:]
#chip['SEQ']['GLOBAL_SHIFT_EN'][310:486] = True
#
#chip['SEQ']['GLOBAL_CTR_LD'][490:491] = True
#chip['SEQ']['GLOBAL_DAC_LD'][490:491] = True
#
##inject
#chip['SEQ']['INJECTION'][500:501] = True
#
#print "chip['SEQ'].write(550) writes pattern"
#chip['SEQ'].write(550)
#
#chip['SEQ_GEN'].set_size(550) # define size of pattern
#chip['SEQ_GEN'].set_repeat(1)
#
# required to receive input

#
#print "chip['SEQ_GEN'].start()"
#chip['SEQ_GEN'].start()

#i = 0
#while chip['SEQ_GEN'].is_ready == False:
#    time.sleep(0.01)
#    print "Wait for done...",i
#    i = i + 1 


print "chip['DATA'].get_fifo_size() = ", chip['DATA'].get_fifo_size()
    
print "chip['DATA'].get_data()"
rxd = chip['DATA'].get_data() #get data from sram fifo
print "rxd = ", rxd

data0 = rxd.astype(np.uint8) # Change type to unsigned int 8 bits and take from rxd only the last 8 bits
data1 = np.right_shift(rxd, 8).astype(np.uint8) # Rightshift rxd 8 bits and take again last 8 bits
data = np.reshape(np.vstack((data1, data0)), -1, order='F') # data is now a 1 dimensional array of all bytes read from the FIFO
bdata = np.unpackbits(data)#.reshape(-1,128)

print "data = ", data
print "bdata = ", bdata
#sum =  np.sum(bdata, axis=0)
#sum = sum[::-1] # reverse the array
#print sum
