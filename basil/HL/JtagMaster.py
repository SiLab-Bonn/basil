#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import yaml
import numpy as np

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer
from basil.RL.StdRegister import StdRegister
from basil.utils.BitLogic import BitLogic
from basil.HL.spi import spi

class JtagMaster(RegisterHardwareLayer):
    '''
    SPI based JTAG interface
    '''
    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                'READY': {'descr': {'addr': 1, 'size': 1, 'properties': ['ro']}},
                'START': {'descr': {'addr': 1, 'size': 8, 'properties': ['writeonly']}},
                'SIZE': {'descr': {'addr': 3, 'size': 16}},
                'WAIT': {'descr': {'addr': 5, 'size': 32}},
                'WORD_COUNT': {'descr': {'addr': 9, 'size': 16}},
                'OPERATION': {'descr': {'addr': 11, 'size': 16}},
                'EN': {'descr': {'addr': 13, 'size': 1}},
                'MEM_BYTES': {'descr': {'addr': 14, 'size': 16, 'properties': ['ro']}}}

    _require_version = "==1"

    def __init__(self, intf, conf):
        super(JtagMaster, self).__init__(intf, conf)
        self._mem_offset = 16  # in bytes
        self._memout_offset = 0
        self._memin_offset = 16

    def init(self):
        super(JtagMaster, self).init()
        self._mem_bytes = self.MEM_BYTES

    def reset(self):
        '''
        Soft reset the module.
        '''
        self.RESET = 0

    def start(self):
        '''
        Starts the shifting data
        '''
        self.START = 0

    def set_size(self, value):
        '''
        Number of clock cycles for shifting in data
        ex. length of matrix shift register (number of pixels daisy chained)
        '''
        self.SIZE = value

    def get_size(self):
        '''
        Get size of shift register length
        '''
        return self.SIZE

    def set_wait(self, value):
        '''
        Sets time delay between repetitions in clock cycles
        '''
        self.WAIT = value

    def get_wait(self):
        '''
        Gets time delay between repetitions in clock cycles
        '''
        return self.WAIT

    def set_word_count(self, value):
        '''
        Number of word of mem size to send
        '''
        self.WORD_COUNT = value

    def get_word_count(self):
        '''
        Gets Number of word of mem size to send
        '''
        return self.WORD_COUNT

    def set_operation(self, value):
        '''
        If 0: IR_SCAN
        If 1: DR_SCAN
        Other: No operations
        '''
        self.OPERATION = value

    def get_operation(self):
        '''
        Gets operation number
        If 0: IR_SCAN
        If 1: DR_SCAN
        Other: No operations
        '''
        return self.OPERATION

    def set_en(self, value):
        '''
        Enable start on external EXT_START signal (inside FPGA)
        '''
        self.EN = value

    def get_en(self):
        '''
        Gets state of enable.
        '''
        return self.EN

    def is_done(self):
        '''
        Get the status of transfer/sequence.
        '''
        return self.is_ready

    @property
    def is_ready(self):
        return self.READY

    def get_mem_size(self):
        return self.MEM_BYTES

    def set_data(self, data, addr=0):
        '''
        Sets data for outgoing stream
        '''
        if self._mem_bytes < len(data):
            raise ValueError('Size of data (%d bytes) is too big for memory (%d bytes)' % (len(data), self._mem_bytes))
        self._intf.write(self._conf['base_addr'] + self._mem_offset + addr, data)

    # This needs to be changed to return written value
    def get_data(self, size=None, addr=None):
        '''
        Gets data for incoming stream
        '''
        # readback memory offset
        if addr is None:
            addr = self._mem_bytes

        if size and self._mem_bytes < size:
            raise ValueError('Size is too big')

        if size is None:
            return self._intf.read(self._conf['base_addr'] + self._mem_offset + addr, self._mem_bytes)
        else:
            return self._intf.read(self._conf['base_addr'] + self._mem_offset + addr, size)

    def scan_ir(self, data):
        """
        Data must be a list of BitLogic
        """
        if type(data[0]) == BitLogic :
            pass
        else:
            raise TypeError("Type of data not supported: got", type(data[0]) ," and support only Bitlogic")

        # Set value to pass all data
        bit_number = sum(len(x) for x in data) # calculate number of bit to transmit
        if bit_number < self._mem_bytes * 8: 
            self.set_size(bit_number)
        else:
            raise ValueError("Size is too big for memory: got %d and memory is: %d" % bit_number, self._mem_bytes * 8)

        data_byte = self._bitlogic2bytes(data)
        self.set_data(data_byte[::-1])
        
        self.set_word_count(1)
        self.set_operation(0)

        self.start()
        while not self.is_ready:
            pass
        
        received_data = self.get_data(size=len(data_byte))
        ret = self._bytes2bitlogic(received_data, bit_number)
        rlist = self._split_bitlogic(ret, data)

        return rlist

    def scan_dr(self, data, words=1):
        """
        Data must be a list of BitLogic or string of raw data
        """
        if type(data[0]) == BitLogic or type(data[0]) == str:
            pass
        else:
            raise TypeError("Type of data not supported: got", type(data[0]) ," and support only str and Bitlogic")

        bit_number = sum(len(x) for x in data)
        if bit_number < self._mem_bytes * 8: 
            self.set_size(bit_number)
        else:
            raise ValueError("Size is too big for memory: got %d and memory is: %d" % bit_number, self._mem_bytes * 8)
        
        self.set_operation(1)
        self.set_word_count(words)
        if type(data[0]) == BitLogic:
            data_byte = self._bitlogic2bytes(data)
            self.set_data(data_byte[::-1])
        else:
            data_byte = self._raw_data2bytes(data)
            self.set_data(data_byte)
    
        self.start()
        while not self.is_ready:
            pass

        received_data = self.get_data(size=len(data_byte))
        ret = self._bytes2bitlogic(received_data, bit_number)
        rlist = self._split_bitlogic(ret, data)

        return rlist

    def _bitlogic2bytes(self, data):
        bitlogic_to_send = BitLogic()
        size_dev = len(data)
        for dev in range(size_dev):
            bitlogic_to_send.extend(data[dev])
        bitlogic_to_send.fill()
        bitlogic_to_send.reverse()
        data_byte = bitlogic_to_send.tobytes()
        return data_byte
    
    def _bytes2bitlogic(self, data, bit_number):
        ret = [BitLogic()]
        for i in range(len(data)):
            b = BitLogic.from_value(data[i], fmt='B')
            b.reverse()
            ret[0].extend(b)
        return ret[0][bit_number-1::]

    def _split_bitlogic(self, data_to_split, original_data):
        rlist = []
        last_data_len = 0
        for i in original_data:
            rlist.append(data_to_split[len(i) - 1 + last_data_len:last_data_len])
            last_data_len = last_data_len + len(i)
        return rlist

    def _raw_data2bytes(self, data):
        all_data = ''
        for i in data:
            all_data = i + all_data
        # inversion needed for JTAG
        all_data = all_data[::-1]
        # pad with zero if not a multiple of 8
        if len(all_data) % 8 != 0:
            all_data = all_data + '0' * (8 - (len(all_data) % 8))
        # convert string to byte
        size = len(all_data) // 8
        data_byte = int(all_data, 2).to_bytes(size, 'big')
        return data_byte