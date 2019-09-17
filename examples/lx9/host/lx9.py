#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#


import yaml
import time

import numpy as np
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

        gr_size = len(self['GLOBAL_REG'][:])  # get the size
        self['SEQ']['SHIFT_IN'][0:gr_size] = self['GLOBAL_REG'][:]  # this will be shifted out
        self['SEQ']['GLOBAL_SHIFT_EN'][0:gr_size] = bitarray(gr_size * '1')  # this is to enable clock
        self['SEQ']['GLOBAL_CTR_LD'][gr_size + 1:gr_size + 2] = bitarray("1")  # load signals
        self['SEQ']['GLOBAL_DAC_LD'][gr_size + 1:gr_size + 2] = bitarray("1")

        # Execute the program (write bits to output pins)
        # + 1 extra 0 bit so that everything ends on LOW instead of HIGH
        self._run_seq(gr_size + 3)

    def program_pixel_reg(self, enable_receiver=True):
        """
        Send the pixel register to the chip and store the output.

        Loads the values of self['PIXEL_REG'] onto the chip.
        Includes enabling the clock, and loading the Control (CTR)
        and DAC shadow registers.

        if(enable_receiver), stores the output (by byte) in
        self['DATA'], retrievable via `chip['DATA'].get_data()`.

        """

        self._clear_strobes()

        # enable receiver it work only if pixel register is enabled/clocked
        self['PIXEL_RX'].set_en(enable_receiver)

        px_size = len(self['PIXEL_REG'][:])  # get the size
        self['SEQ']['SHIFT_IN'][0:px_size] = self['PIXEL_REG'][:]  # this will be shifted out
        self['SEQ']['PIXEL_SHIFT_EN'][0:px_size] = bitarray(px_size * '1')  # this is to enable clock

        print('px_size = {}'.format(px_size))

        self._run_seq(px_size + 1)  # add 1 bit more so there is 0 at the end other way will stay high

    def _run_seq(self, size):
        """
        Send the contents of self['SEQ'] to the chip and wait until it finishes.

        """

        # Write the sequence to the sequence generator (hw driver)
        self['SEQ'].write(size)  # write pattern to memory

        self['SEQ'].set_size(size)  # set size
        self['SEQ'].set_repeat(1)  # set repeat
        for _ in range(1):
            self['SEQ'].start()  # start

            while not self['SEQ'].get_done():
                # time.sleep(0.1)
                print("Wait for done...")

    def _clear_strobes(self):
        """
        Resets the "enable" and "load" output streams to all 0.

        """
        # reset some stuff
        self['SEQ']['GLOBAL_SHIFT_EN'].setall(False)
        self['SEQ']['GLOBAL_CTR_LD'].setall(False)
        self['SEQ']['GLOBAL_DAC_LD'].setall(False)
        self['SEQ']['PIXEL_SHIFT_EN'].setall(False)
        self['SEQ']['INJECTION'].setall(False)


print("Start")

stream = open("lx9.yaml", 'r')
cnfg = yaml.safe_load(stream)
chip = Pixel(cnfg)
chip.init()


chip['GPIO']['LED1'] = 1
chip['GPIO']['LED2'] = 0
chip['GPIO']['LED3'] = 0
chip['GPIO']['LED4'] = 0
chip['GPIO'].write()


# settings for global register (to input into global SR)
# can be an integer representing the binary number desired,
# or a bitarray (of the form bitarray("10101100")).
chip['GLOBAL_REG']['global_readout_enable'] = 0  # size = 1 bit
chip['GLOBAL_REG']['SRDO_load'] = 0  # size = 1 bit
chip['GLOBAL_REG']['NCout2'] = 0  # size = 1 bit
chip['GLOBAL_REG']['count_hits_not'] = 0  # size = 1
chip['GLOBAL_REG']['count_enable'] = 0  # size = 1
chip['GLOBAL_REG']['count_clear_not'] = 0  # size = 1
chip['GLOBAL_REG']['S0'] = 0  # size = 1
chip['GLOBAL_REG']['S1'] = 0  # size = 1
chip['GLOBAL_REG']['config_mode'] = 3  # size = 2
chip['GLOBAL_REG']['LD_IN0_7'] = 0  # size = 8
chip['GLOBAL_REG']['LDENABLE_SEL'] = 0  # size = 1
chip['GLOBAL_REG']['SRCLR_SEL'] = 0  # size = 1
chip['GLOBAL_REG']['HITLD_IN'] = 0  # size = 1
chip['GLOBAL_REG']['NCout21_25'] = 0  # size = 5
chip['GLOBAL_REG']['column_address'] = 0  # size = 6
chip['GLOBAL_REG']['DisVbn'] = 0  # size = 8
chip['GLOBAL_REG']['VbpThStep'] = 0  # size = 8
chip['GLOBAL_REG']['PrmpVbp'] = 0  # size = 8
chip['GLOBAL_REG']['PrmpVbnFol'] = 0  # size = 8
chip['GLOBAL_REG']['vth'] = 0  # size = 8
chip['GLOBAL_REG']['PrmpVbf'] = 0  # size = 8

print("program global register...")
chip.program_global_reg()

# settings for pixel register (to input into pixel SR)
# can be an integer representing the binary number desired,
# or a bitarray (of the form bitarray("10101100")).

chip['PIXEL_REG'][:] = bitarray('1111111010001100' * 8)
print(chip['PIXEL_REG'])
#chip['PIXEL_REG'][0] = 0

print("program pixel register...")
chip.program_pixel_reg()

time.sleep(0.5)
# Get output size in bytes
print("chip['DATA'].get_FIFO_SIZE() = {}".format(chip['DATA'].get_FIFO_SIZE()))

rxd = chip['DATA'].get_data()  # get data from sram fifo
print(rxd)

data0 = rxd.astype(np.uint8)  # Change type to unsigned int 8 bits and take from rxd only the last 8 bits
data1 = np.right_shift(rxd, 8).astype(np.uint8)  # Rightshift rxd 8 bits and take again last 8 bits
data = np.reshape(np.vstack((data1, data0)), -1, order='F')  # data is now a 1 dimensional array of all bytes read from the FIFO
bdata = np.unpackbits(data)

print("data = {}".format(data))
print("bdata = {}".format(bdata))
