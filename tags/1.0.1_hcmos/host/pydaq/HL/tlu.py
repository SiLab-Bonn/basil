#
# ------------------------------------------------------------
# Copyright (c) SILAB , Physics Institute of Bonn University
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev:: 1                    $:
#  $Author:: TheresaObermann    $:
#  $Date:: 2013-10-09 10:58:06 #$:
#

from HL.HardwareLayer import HardwareLayer

import struct
import array

trigger_modes = {
    0: 'external trigger',
    1: 'TLU no handshake',
    2: 'TLU simple handshake',
    3: 'TLU trigger data handshake'
}

class tlu(HardwareLayer):
    '''
    TLU controller interface
    '''
    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)


    '''
    Resets the TLU controller module inside the FPGA, base adress zero
    '''                                   
    def reset(self):
        self._intf.write(self._conf['base_addr'], [0])

    '''
    Initialise the TLU controller module
    '''                                   
    def init(self):
        self.reset()
        
#    '''
#    Sets the mode , at which adresse is this???
#    '''                                   
#    def set_mode(self , addr, data):
#        self._intf.write(self._conf['base_addr'] + 16 + addr, data)

    def get_tlu_trigger_number(self):
        '''Reading most recent TLU trigger data/number.
        '''
        trigger_number_array = self._intf.read(self._conf['base_addr'] + 4, size=4)
        return struct.unpack('I', trigger_number_array)[0]
    
    def get_trigger_number(self):
        '''Reading internal trigger counter.
        '''
        trigger_number_array = self._intf.read(self._conf['base_addr'] + 8, size=4)
        return struct.unpack('I', trigger_number_array)[0]
    
#    def set_trigger_number(self, value=0):
    def set_trigger_number(self, value):
        '''Writing ???? internal trigger counter.
        '''
        trigger_number = array.array('B', struct.pack('I', value))
        self._intf.write(self._conf['base_addr'] + 8, data=trigger_number)

    def configure_trigger_fsm(self, mode=0, trigger_data_msb_first=False, disable_veto=False, trigger_data_delay=0, trigger_clock_cycles=16, enable_reset=False, invert_lemo_trigger_input=False, trigger_low_timeout=0):
        '''Setting up external trigger mode and TLU trigger FSM.
    
        Parameters
        ----------
        mode : string
            TLU handshake mode. External trigger has to be enabled in command FSM. From 0 to 3.
            0: External trigger (LEMO RX0 only, TLU port disabled (TLU port/RJ45)).
            1: TLU no handshake (automatic detection of TLU connection (TLU port/RJ45)).
            2: TLU simple handshake (automatic detection of TLU connection (TLU port/RJ45)).
            3: TLU trigger data handshake (automatic detection of TLU connection (TLU port/RJ45)).
        trigger_data_msb_first : bool
            Setting endianness of TLU trigger data.
        disable_veto : bool
            Disabling TLU veto support.
        trigger_data_delay : int
            Addition wait cycles before latching TLU trigger data. From 0 to 15.
        trigger_clock_cycles : int
            Number of clock cycles sent to TLU to clock out TLU trigger data. The number of clock cycles is usually (bit length of TLU trigger data + 1). From 0 to 31.
        enable_reset : bool
            Enable resetting of internal trigger counter when TLU asserts reset signal.
        invert_lemo_trigger_input : bool
            Enable inverting of LEMO RX0 trigger input.
        trigger_low_timeout : int
            Enabling timeout for waiting for de-asserting TLU trigger signal. From 0 to 255.
        '''
        reg_1 = (mode & 0x03)
        if trigger_data_msb_first:
            reg_1 |= 0x04
        else:
            reg_1 &= ~0x04
        if disable_veto:
            reg_1 |= 0x08
        else:
            reg_1 &= ~0x08
        reg_1 = ((trigger_data_delay & 0x0f) << 4) | (reg_1 & 0x0f)
        reg_2 = (trigger_clock_cycles & 0x1F)  # 0 = 32 clock cycles
        if enable_reset:
            reg_2 |= 0x20
        else:
            reg_2 &= ~0x20
        if invert_lemo_trigger_input:
            reg_2 |= 0x40
        else:
            reg_2 &= ~0x40
        reg_3 = trigger_low_timeout
        self._intf.write(self._conf['base_addr'] + 1, data=[reg_1, reg_2, reg_3])  # overwriting registers