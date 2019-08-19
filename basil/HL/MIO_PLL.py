#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging

from basil.HL.HardwareLayer import HardwareLayer
import six

logger = logging.getLogger(__name__)


class MIO_PLL(HardwareLayer):
    '''
    CY22150 PLL

    Output frequency range: 80 kHz to 200 MHz

    Physical connection on MIO board:
     - 48 MHz reference clock input from USB uC
     - LCK1 PLL clock output connected to FPGA (LOC P9, GCLK2)

    Use yaml configuration:

    - name      : MIO_PLL
      type      : MIO_PLL
      interface : USB
      base_addr : 0x00000
      pll_frequency : 40 # [MHz]

    '''
    # slave address
    CY22150_BASE_ADDR                = 0xD2
    # register addresses
    CY22150_ADD_CLKOE                = 0x09  # clock output enable control
    CY22150_ADD_DIV1                 = 0x0c  # PLL post divider 1 (for LCLK 1-4)
    CY22150_ADD_INPDRV               = 0x12  # input oscillator drive control
    CY22150_ADD_INPCAP               = 0x13  # input oscillator load capacitance (for crystal use only)
    CY22150_ADD_CHG_PB               = 0x40  # charge pump + PLL feedback divider
    CY22150_ADD_PB                   = 0x41  # PLL feedback divider
    CY22150_ADD_PO_Q                 = 0x42  # reference input clock divider
    CY22150_ADD_XS1                  = 0x44  # output crosspoint switch matrix
    CY22150_ADD_XS2                  = 0x45  # output crosspoint switch matrix
    CY22150_ADD_XS3                  = 0x46  # output crosspoint switch matrix
    CY22150_ADD_DIV2                 = 0x47  # PLL post divider 2 (for CLK 5,6)
    # bit locations
    CY22150_LCLK1_EN                 = 0x01  # only one output used on MIO board
    CY22150_LCLK2_EN                 = 0x02
    CY22150_LCLK3_EN                 = 0x04
    CY22150_LCLK4_EN                 = 0x08
    CY22150_CLK5_EN                  = 0x10
    CY22150_CLK6_EN                  = 0x20
   # constants
    CY22150_DEF_INPDRV               = 0x28  # input range for 48 MHz reference clock oszillator
    CY22150_DEF_INPCAP               = 0x00  # no load capacitor
    CY22150_FREF_FX                  = 48.0  # reference clock, from USB controller

    q_counter = 0
    p_counter = 0
    q_total   = 0
    p_total   = 0
    p_0       = 0
    div       = 0
    div1N     = 0
    div1SRC   = 0
    div2N     = 8
    div2SRC   = 0
    clk1SRC   = 0
    clk2SRC   = 0
    clk3SRC   = 0
    clk4SRC   = 0
    clk5SRC   = 0
    clk6SRC   = 0
    chg_pump  = 0
    fref = CY22150_FREF_FX
    pll_frequency = 40  # some default

    def __init__(self, intf, conf):
        super(MIO_PLL, self).__init__(intf, conf)

        self._base_addr = conf['base_addr']
        self.pll_frequency = conf['pll_frequency']
        self.CY22150_ADD = self.CY22150_BASE_ADDR

    def init(self):
        super(MIO_PLL, self).init()
        self._set_register_value(self.CY22150_ADD_CLKOE, self.CY22150_LCLK1_EN)  # enable LCLK1 output
        self._set_register_value(self.CY22150_ADD_INPDRV, self.CY22150_DEF_INPDRV)  # reference clock frequency range
        self._set_register_value(self.CY22150_DEF_INPCAP, 0)  # no load capacitors
        self.setFrequency(self.pll_frequency)

    def close(self):
        super(MIO_PLL, self).close()
        self._set_register_value(self.CY22150_ADD_CLKOE, 0)  # disable LCLK1 output

    def setFrequency(self, value):  # value in MHz
        if float(value) < 0.08 or float(value) > 200.0:
            raise ValueError('[MIO_PLL ERROR] PLL frequency (' + str(value) + ' MHz) out of range. Allowed range: 80 kHz to 200 MHz')
        if self._calculateParameters(value):
            self._updateRegisters()
            return True
        else:
            return False

    def _set_register_value(self, register, value):
        self._intf.write(self._base_addr + self.CY22150_ADD, (register, value))

    def _calculateParameters(self, fout):
        q_d_f = 0

        '''
        fout = fref * (p_total / q_total) * (1 / div)

        p_total = 2 * ((p_counter + 4) + p_0)     [16..1023]
        q_total = q_counter + 2                   [2..129]
        div = [2,(3),4..127]

        constraints:

        f_ref * p_total / q_total = [100..400] MHz
        f_ref / q_total > 0.25 MHz
        '''
        for self.q_counter in range(128):
            self.q_total = self.q_counter + 2
            if (self.fref / self.q_total) < 0.25:  # PLL constraint
                break
            for self.div in range(2, 128):
                q_d_f = self.q_total * self.div * fout
                if float(q_d_f).is_integer() and q_d_f > (15 * self.fref):  # = f0 * p
                    if (int(q_d_f) % int(self.fref)) == 0:  # p, q, and d found
                        self.p_total = q_d_f / self.fref
                        while self.p_total <= 16:  # counter constraint
                            self.p_total = self.p_total * 2
                            self.div = self.div * 2
                            if self.div > 127:
                                break
                            if self.p_total > 1023:
                                break
                        if ((self.fref * self.p_total / self.q_total) < 100 or (self.fref * self.p_total / self.q_total) > 400):  # PLL constraint
                            break
                        if int(self.p_total) % 2 == 0:
                            self.p_0 = 0
                        else:
                            self.p_0 = 1
                        self.p_counter = ((int(self.p_total) - self.p_0) / 2) - 4  # set p counter value

                        if self.div == 2:
                            self.clk1SRC = 0x02
                            self.div1N = 4
                        else:
                            if self.div == 3:
                                self.clk1SRC = 0x03
                                self.div1N = 6
                            else:
                                self.clk1SRC = 0x01
                                self.div1N = self.div

                        if self.p_total <= 44:
                            self.chg_pump = 0
                        else:
                            if self.p_total <= 479:
                                self.chg_pump = 1
                            else:
                                if self.p_total <= 639:
                                    self.chg_pump = 2
                                else:
                                    if self.p_total <= 799:
                                        self.chg_pump = 3
                                    else:
                                        if self.p_total <= 1023:
                                            self.chg_pump = 4
                        ftest = self.fref * self.p_total / self.q_total * 1 / self.div
                        fvco = self.fref * self.p_total / self.q_total
                        logger.info('PLL frequency set to ' + str(ftest) + ' MHz' + ' (VCO @ ' + str(fvco) + ' MHz)')
                        return True
        logger.error('MIO_PLL: Could not find PLL parameters for {}MHz'.format(fout))
        return False

    def _updateRegisters(self):
        temp = (self.div1SRC << 7) | (0x7f & self.div1N)
        self._set_register_value(self.CY22150_ADD_DIV1, temp)  # post divider 1

        temp = (self.div2SRC << 7) | (0x7f & self.div2N)
        self._set_register_value(self.CY22150_ADD_DIV2, temp)  # post divider 2

        temp = 0xC0 | (((0x07 & self.chg_pump) << 2) | ((0x0300 & int(self.p_counter)) >> 8))
        self._set_register_value(self.CY22150_ADD_CHG_PB, temp)  # charge pump & p divider

        temp = (0xff & int(self.p_counter))
        self._set_register_value(self.CY22150_ADD_PB, temp)  # p divider

        temp = ((0x01 & self.p_0) << 7) | (0x07f & self.q_counter)
        self._set_register_value(self.CY22150_ADD_PO_Q, temp)  # p_0 & q divider

        temp = (self.clk1SRC << 5) | (self.clk2SRC << 2) | ((0x03 & self.clk3SRC) >> 1)
        self._set_register_value(self.CY22150_ADD_XS1, temp)  # clock source

        temp = (self.clk3SRC << 7) | (self.clk4SRC << 4) | (self.clk5SRC << 1) | ((0x01 & self.clk6SRC) >> 2)
        self._set_register_value(self.CY22150_ADD_XS2, temp)  # clock source

        temp = (self.clk6SRC << 6) | 0x3f
        self._set_register_value(self.CY22150_ADD_XS3, temp)  # clock source
