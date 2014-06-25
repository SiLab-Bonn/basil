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

class Pixel(Dut):
    """
    A class for communicating with a pixel chip.

    """
    
    def program_global_reg(self):
        """
        Send the global register to the chip.

        Loads the values of self['GLOBAL_REG'] onto the chip.
        Includes enabling the clock, and loading the Control (CTR)
        and DAC shadow registers.

        """
        
        self._clear_strobes()
        
        gr_size = len(self['GLOBAL_REG'][:]) #get the size
        self['SEQ']['SHIFT_IN'][0:gr_size] = self['GLOBAL_REG'][:] # this will be shifted out
        self['SEQ']['GLOBAL_SHIFT_EN'][0:gr_size] = bitarray( gr_size * '1') #this is to enable clock
        self['SEQ']['GLOBAL_CTR_LD'][gr_size+1:gr_size+2] = bitarray("1") # load signals
        self['SEQ']['GLOBAL_DAC_LD'][gr_size+1:gr_size+2] = bitarray("1")

        # Write the sequence to the sequence generator (hw driver)
        self['SEQ'].write(gr_size+3) #write pattern to memory
        
        # Execute the program (write bits to output pins)
        # + 1 extra 0 bit so that everything ends on LOW instead of HIGH
        self._run_seq(gr_size+3)
    
    def program_pixel_reg(self, enable_receiver=True):
        """
        Send the pixel register to the chip and store the output.

        Loads the values of self['GLOBAL_REG'] onto the chip.
        Includes enabling the clock, and loading the Control (CTR)
        and DAC shadow registers.

        if(enable_receiver), stores the output (by byte) in
        self['DATA'], retrievable via `chip['DATA'].get_data()`.

        """
        
        self._clear_strobes()

        #enable receiver it work only if pixel register is enabled/clocked
        chip['PIXEL_RX'].set_en(enable_receiver) 

        px_size = len(self['PIXEL_REG'][:]) #get the size
        self['SEQ']['SHIFT_IN'][0:px_size] = self['PIXEL_REG'][:] # this will be shifted out
        self['SEQ']['PIXEL_SHIFT_EN'][0:px_size] = bitarray( px_size * '1') #this is to enable clock
        
        self['SEQ'].write(px_size+1) #write pattern to memeory(add 1 bit more so there is 0 at the end other way will stay high)
        
        self._run_seq(px_size+1)
            
    def _run_seq(self, size):
        """
        Send the contents of self['SEQ'] to the chip and wait until it finishes.

        """
        self['SEQ'].set_size(size)  # set size
        self['SEQ'].set_repeat(1) # set reapet
        self['SEQ'].start() # start
        
        while not chip['SEQ'].get_done():
            time.sleep(0.01)
            print "Wait for done..."

    def _clear_strobes(self):
        """
        Resets the "enable" and "load" output streams to all 0.

        """
        #reset some stuff
        self['SEQ']['GLOBAL_SHIFT_EN'].setall(False)
        self['SEQ']['GLOBAL_CTR_LD'].setall(False)
        self['SEQ']['GLOBAL_DAC_LD'].setall(False)
        self['SEQ']['PIXEL_SHIFT_EN'].setall(False)
        
if __name__ == "__main__":
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

    #settings for global register (to input into global SR)
    # can be an integer representing the binary number desired,
    # or a bitarray (of the form bitarray("10101100")).
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


    #settings for pixel register (to input into pixel SR)
    # can be an integer representing the binary number desired,
    # or a bitarray (of the form bitarray("10101100")).

    chip['PIXEL_REG'][:] = bitarray('1'*128)
    chip['PIXEL_REG'][0] = 0

    print "program pixel register..."
    chip.program_pixel_reg()

    # Get output size in bytes
    print "chip['DATA'].get_fifo_size() = ", chip['DATA'].get_fifo_size()
        
    # Get output in bytes
    print "chip['DATA'].get_data()"
    rxd = chip['DATA'].get_data() #get data from sram fifo
    print "rxd = ", rxd
    print "rxd(hex) = ", map(hex, rxd)

    data0 = rxd.astype(np.uint8) # Change type to unsigned int 8 bits and take from rxd only the last 8 bits
    data1 = np.right_shift(rxd, 8).astype(np.uint8) # Rightshift rxd 8 bits and take again last 8 bits
    data = np.reshape(np.vstack((data1, data0)), -1, order='F') # data is now a 1 dimensional array of all bytes read from the FIFO
    bdata = np.unpackbits(data)#.reshape(-1,128)

    print "data = ", data
    print "bdata = ", bdata

    print 'ids=', np.right_shift(np.bitwise_and(rxd, 0x0fff0000), 16)
