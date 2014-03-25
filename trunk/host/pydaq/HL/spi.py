#
# ------------------------------------------------------------
# Copyright (c) SILAB , Physics Institute of Bonn University
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#

from HL.HardwareLayer import HardwareLayer
from struct import pack, unpack


class spi(HardwareLayer):
    '''
    Serial programming interface.
    Together with a GPIO module it is used to configure the local registers of the pixel matrix
    Assigns bits like in the following example
    dut['name of SR as defined in YAML config file'][bit position] = value
    '''
    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)

    def reset(self):
        self._intf.write(self._conf['base_addr'], [0])

    def init(self):
        self.reset()
        
    def start(self):
        '''
        Starts the shifting in of data
        '''
        self._intf.write(self._conf['base_addr'] + 1, [0])
        
    def set_size(self, value):
        '''
        Overwrites the size defined in YAML config file
        Number of clock cycles for shifting in data
        length of matrix shift register (number of pixels daisy chained)
        '''
        self._intf.write(self._conf['base_addr'] + 3, unpack('BBBB', pack('>L', value))[2:4])

    def get_size(self):
        '''
        Get size of shift register length
        '''
        ret = self._intf.read(self._conf['base_addr'] + 3, 2)
        return ret[0] * (2 ** 8) + ret[1]

    def set_wait(self, value):
        '''
        Defines time delay between repititions in clock cycles (80ns)
        '''
        self._intf.write(self._conf['base_addr'] + 5, unpack('BBBB', pack('>L', value))[2:4])

    def get_wait(self):
        '''
        Gets time delay between repititions in clock cycles (80ns)
        '''
        ret = self._intf.read(self._conf['base_addr'] + 5, 2)
        return ret[0] * (2 ** 8) + ret[1]

    def set_repeat(self, value):
        '''
        If 0: Repeat sequence forever
        Other: Number of repititions of sequence with delay 'wait'
        '''
        self._intf.write(self._conf['base_addr'] + 7, [value])

    def get_repeat(self):
        '''
        Gets Number of repititions of sequence with delay 'wait' (if 0 --> repeat forever)
        '''
        return self._intf.read(self._conf['base_addr'] + 7, 1)[0]

    def is_done(self):
        return True if (self._intf.read(self._conf['base_addr'] + 1, 1)[0] & 0x01) else False

    def set_data(self, addr, data):
        self._intf.write(self._conf['base_addr'] + 8 + addr, data)
        
    def get_data(self, addr=0, size=None):
        if(size == None):
            size = self._conf['mem_bytes']

        return self._intf.read(self._conf['base_addr'] + 8 + self._conf['mem_bytes'], size)
