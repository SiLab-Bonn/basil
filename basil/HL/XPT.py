#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#


import yaml
from array import array
from basil.HL.HardwareLayer import HardwareLayer
from struct import pack, unpack_from
import logging


class I2C_INTF(HardwareLayer):
    '''
    Use basil implementation of i2c.
    '''

    def __init__(self, intf, conf):
        super(I2C_INTF, self).__init__(intf, conf)
        self._base_addr = conf['base_addr']

    def init(self):
        super(I2C_INTF, self).init()

    def _set_reg(self, addr, val):
        self._intf.write(self._base_addr, array('B', pack('BB', addr, val)))

    def _get_reg(self, addr):
        self._intf.write(self._base_addr, array('B', pack('B', addr)))
        return unpack_from('B', self._intf.read(self._base_addr, size=1))[0]


class MuxPca9540B(HardwareLayer):
    '''PCA 9540B

    I2C Bus Multiplexer (GPAC).
    '''
    PCA9540B_BASE_ADD = 0xE0  # generic slave address
    PCA9540B_SEL_CH0 = 0x04  # select channel 0
    PCA9540B_SEL_CH1 = 0x05  # select channel 1
    PCA9540B_SEL_NONE = 0x00  # de-select channels

    def __init__(self, intf, conf):
        super(MuxPca9540B, self).__init__(intf, conf)
        self._base_addr = conf['base_addr']
        self.PCA9540B_ADD = self.PCA9540B_BASE_ADD

    def _set_i2c_mux(self, bus):
        self._intf.write(self._base_addr, array('B', pack('B', bus)))

    def _get_i2c_mux(self):
        return unpack_from('B', self._intf.read(self._base_addr | 1, size=1))[0]


class GpioPca9554(HardwareLayer):
    '''PCA 9554

    GPIO extension (GPAC).
    '''
    PCA9554_BASE_ADD = 0x40  # generic slave address
    PCA9554_CFG = 0x03  # configuration register: 1 -> input (default), 0 -> output
    PCA9554_POL = 0x02  # polarity inversion register
    PCA9554_OUT = 0x01  # output port register
    PCA9554_IN = 0x00  # input port register (internal pull-up)

    def __init__(self, intf, conf):
        super(GpioPca9554, self).__init__(intf, conf)
        self._base_addr = conf['base_addr']
        self.PCA9554_ADD = self.PCA9554_BASE_ADD
        self.GPIO_CFG = 0x00

    def init(self):
        super(GpioPca9554, self).init()
        self._intf.write(self._base_addr + self.PCA9554_ADD, (self.PCA9554_CFG, self.GPIO_CFG))
        self._intf.write(self._base_addr + self.PCA9554_ADD, (self.PCA9554_OUT, 0x00))

    def _write_output_port_select(self, value):
        self._intf.write(self._base_addr + self.PCA9554_ADD,
                         array('B', pack('BB', self.PCA9554_CFG, value)))  # configure output lines

    def _read_input_port(self):
        self._intf.write(self._base_addr + self.PCA9554_ADD, array('B', pack('B', self.PCA9554_IN)))  # set command byte
        return unpack_from('B', self._intf.read(self._base_addr + self.PCA9554_ADD | 1, size=1))[0]  # read input lines

    def _write_output_port(self, value):
        self._intf.write(self._base_addr + self.PCA9554_ADD,
                         array('B', pack('BB', self.PCA9554_OUT, value)))  # write output lines

    def _read_output_port(self):
        self._intf.write(self._base_addr + self.PCA9554_ADD, array('B', pack('B', self.PCA9554_OUT)))
        return unpack_from('B', self._intf.read(self._base_addr + self.PCA9554_ADD | 1, size=1))[0]

    def _set_output_port(self, mask):
        self._write_output_port(mask | self._read_output_port())

    def _clear_output_port(self, mask):
        self._write_output_port(~mask & self._read_output_port())

    def _get_input_port(self, mask):
        return True if ((mask & self._read_input_port()) == mask) else False


class ADN_XPT(I2C_INTF):
    '''
    XPT Functionality, works for ADN4605 & ADN4604.
    General procedure:
    - Reset
    - Input-to-output assignment including:
        -Input configuration
        -Output configuration
    - Termination if not handled during I/O config
    - XPT core update
    '''

    def __init__(self, intf, conf):
        super().__init__(intf, conf)
        self.lookup = {}
        self.map = {}
        self.name = conf['name']
        self.addr = conf['base_addr']
        self.output_channels = []
        self.select_table = 0

    def init(self, register_map):
        '''
        Set up helper maps and select an output table if desired
        '''
        with open(register_map, 'r') as map_:
            # register lookup table with register properties (addr, offset, default ...)
            self.lookup = yaml.safe_load(map_)

        for key in self.lookup:  # set up register dict with everything but output channel assignment
            if key != 'Output_Channels':
                self.map[key] = {}
                for reg in self.lookup[key]:
                    self.map[key][reg['name']] = reg

        self.output_channels = [channel for channel in self.lookup["Output_Channels"]]
        # List of available output channels for given XPT.
        # self.select_table = self.output_table(write = False) #Query current output table. Upon power up should be 0.

    def write_register(self, cat, regname, val):
        '''
        Write register. Register category and name are used to fetch addr, addr offset from register lookup.
        Write operation only into relevant bits of the register using a mask. Logging of register address,
        content, write mask, data written and new register content.
        '''
        addr = self.get_addr(cat, regname)
        mask = self._calculate_mask(cat, regname)
        reg_read = self._get_reg(addr)
        val = (reg_read & ~mask) | ((val << self.map[cat][regname]['offset']) & mask)
        logging.debug('Writing in register %s (address %s). Register content: %s' % (cat + " " + regname, hex(addr),
                                                                                     format(reg_read, '#010b')))
        logging.debug('Use mask: %s. Write data: %s' % (format(mask, '#010b'), format(val, '#010b')))
        self._set_reg(addr, val)
        logging.debug('Register content after writing: %s' % format(self._get_reg(addr), '#010b'))

    def read_register(self, cat, regname):
        '''
        Read register, analog to writing.
        '''
        addr = self.get_addr(cat, regname)
        mask = self._calculate_mask(cat, regname)
        reg_read = (self._get_reg(addr) & mask) >> self.map[cat][regname]['offset']
        logging.info("Reading register %s (address %s). Masked register content: %s" % (
            cat + " " + regname, hex(addr), format(reg_read, '#010b')))
        return reg_read

    def _calculate_mask(self, cat, regname):
        mask = (pow(2, self.map[cat][regname]['size']) - 1) << self.map[cat][regname]['offset']
        return mask

    def get_addr(self, cat, regname):
        return self.map[cat][regname]['address']

    def reset(self):
        '''
        Global XPT reset to defaults.
        '''
        self.write_register('General', 'Reset', 1)

    def xpt_update(self):
        '''
        Updates XPT core. Needs to be done after changing of channel assignment.
        '''
        return self.write_register('General', 'XPT_Update', 1)

    def output_table(self, write=False, table=0):
        '''
        Either set an output table (0 or 1), or retrieve the current table.
        '''
        if not write:
            self.select_table = self.read_register('General', 'Table_Select')
            return self.select_table
        elif write:
            self.select_table = table
            self.write_register('General', 'Table_Select', self.select_table)
        else:
            raise Exception

    def assign_output(self, channel="OUT0", val=0):
        '''
        Assign an input channel to a given output channel. Input channels are expected as integers.
        '''
        if isinstance(channel, int):
            if self.name == 'ADN4605':
                channel = self.output_channels[channel]
            elif self.name == 'ADN4604':
                channel = self.output_channels[channel]
            else:
                raise NotImplementedError
        if self.select_table == 0:  # Selecting table
            self.table = 'XPT_Map0'
        elif self.select_table == 1:
            self.table = 'XPT_Map1'
        return self.write_register(self.table, channel, val)

    def tx_config(self, register, channel='OUT0', val=0, write=True):
        '''
        Configure TX channels. Available register blocks: TX_Drive_Control, TX_Sign_Control, TX_Lane_Control.
        '''
        if isinstance(channel, int):
            channel = self.output_channels[channel]
        if channel not in self.map[register].keys():
            logging.info("Invalid %s Register: %s" % (register, channel))
            raise ValueError
        if not write:
            return self.read_register(register, channel)
        elif write:
            return self.write_register(register, channel, val)

    def rx_config(self, register, channel='IN0', val=0, write=True):
        '''
        Configure RX channels. Available register blocks: RX_EQ_Control, RX_Sign_Control.
        Retrieve current config.
        '''
        if channel not in self.map[register].keys():
            logging.info("Invalid %s Register: %s" % (register, channel))
            raise ValueError
        if not write:
            return self.read_register(register, channel)
        elif write:
            return self.write_register(register, channel, val)

    def set_termination(self):
        '''
        Set rx and tx termination for XPT.
        '''
        for key in self.map["TX_Termination_Control"]:
            self.tx_termination(key, val=0, write=True)
        if self.name == "ADN4605":  # ADN4604 has no RX term
            for key in self.map["RX_Termination_Control"]:
                self.rx_termination(key, val=0, write=True)

    def tx_termination(self, output='TXA_TERM0', write=False, val=0):
        '''
        Set/get tx termination. 0 is termination active.
        '''
        if output not in self.map["TX_Termination_Control"].keys():
            logging.info("Invalid Tx Termination Control Register")
            raise ValueError
        if not write:
            return self.read_register('TX_Termination_Control', output)
        elif write:
            return self.write_register('TX_Termination_Control', output, val)

    def rx_termination(self, base_addr, output='RXA_TERM0', write=False, val=0):
        '''
        Set/get rx termination. 0 is termination active.
        '''
        if self.name == 'ADN4604':
            pass
        elif self.name == 'ADN4605':
            if output not in self.map["RX_Termination_Control"].keys():
                logging.info("Invalid Rx Termination Control Register")
                raise ValueError
            if not write:
                return self.read_register('RX_Termination_Control', output)
            elif write:
                return self.write_register('RX_Termination_Control', output, val)

    def io_config(self, conf):
        """Map input pins to the XP outputs according to specifications in the eos_config.yaml.
        In addition, configure the XP outputs: TX_Lane_Control, TX_Sign_Control and
        TX_Drive_Control. TX_Lane_Control and TX_Drive_Control offer broadcast."""
        if self.name == 'ADN4605':
            for key, value in conf['AURORA_IN'].items():
                if value is not None:
                    self.assign_output(channel=key, val=value)
                    self.tx_config("TX_Lane_Control", key, 0b01001000, True)
                    self.tx_config("TX_Drive_Control", key, 0b11, True)
                    # if "BC" not in key: # Hack for no broadcast in tx sign control. Default usually sufficient
                    #    self.tx_config("TX_Sign_Control", key, 0, True)
                elif value is None:  # But why?
                    pass
                else:
                    raise NotImplementedError
            self.input_config()

        elif self.name == 'ADN4604':
            for key, value in conf['CMD_IN'].items():

                if not value == "None":
                    # print(key,value)
                    # print(value==True)
                    self.assign_output(channel=key, val=value)
                    self.tx_config("TX_basic_control", key, 0xff, True)
                    self.rx_termination("RX_EQ_Control", key, 1, True)
                elif value == "None":  # But why?
                    pass
                else:
                    raise NotImplementedError

        elif self.name == 'ADN4604_DATA':
            for key, value in conf['AURORA_IN'].items():
                if value is not None:
                    self.assign_output(channel=key, val=value)
                    self.tx_config("TX_basic_control", key, 0b00110000, True)
                    # self.tx_config("TX_Drive0_Control", key, 0b10001000, True)
                elif value is None:  # But why?
                    pass
                else:
                    raise NotImplementedError
            self.input_config()

        elif self.name == 'ADN4604_CMD':
            for key, value in conf['CMD_IN'].items():
                if value is not None:
                    self.assign_output(channel=key, val=value)
                    self.tx_config("TX_basic_control", key, 0b00110000, True)
                    # self.tx_config("TX_Drive1_Control", key, 0b10001000, True)
                elif value is None:  # But why?
                    pass
                else:
                    raise NotImplementedError
            self.input_config()

        elif self.name == 'ADN4604_MOD':
            for key, value in conf['MODULE_IN'].items():
                if value is not None:
                    self.assign_output(channel=key, val=value)
                    self.tx_config("TX_basic_control", key, 0b00110000, True)
                    # self.tx_config("TX_Drive1_Control", key, 0b10001000, True)
                elif value is None:  # But why?
                    pass
                else:
                    raise NotImplementedError
            self.input_config()

    def get_output_status(self, channel='OUT0'):
        '''
        Query output channel assignment.
        '''
        if isinstance(channel, int):
            channel = self.output_channels[channel]
        return self.read_register('XPT_Status', channel)

    def input_config(self):
        """Configure XP inputs. Available settings are RX_EQ_Control and RX_Sign_Control.
        RX_EQ_Control can be used as broadcast. RX_Sign_Control has to be done
        on an input-by-input basis."""
        for key in self.map["RX_EQ_Control"].keys():
            if "BC" in key:  # Use BCAST
                self.rx_config('RX_EQ_Control', key, val=0b00000011, write=True)
            elif "BC" not in key:  # Use a different map for input equalizer / inverter. Not implemented
                self.rx_config('RX_EQ_Control', key, val=0, write=True)

        # if self.name == 'ADN4604_CMD': # need to invert CMD signal for QMS card
        #     for key in self.map["RX_Sign_Control"].keys():
        #         self.rx_config('RX_Sign_Control', key, val = 0x00, write = True)


if __name__ == '__main__':
    pass
