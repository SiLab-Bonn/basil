#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab , Physics Institute of Bonn University
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#

from HL.HardwareLayer import HardwareLayer

import struct
import array


class tdc_s3(HardwareLayer):
    '''
    TDC controller interface
    '''
    def __init__(self, intf, conf):
        HardwareLayer.__init__(self, intf, conf)

    '''
    Resets the TDC controller module inside the FPGA, base adress zero
    '''                                   
    def reset(self):
        self._intf.write(self._conf['base_addr'], [0])

    '''
    Initialise the TDC controller module
    '''
    def init(self):
        self.reset()

    def set_en(self, enable):
        current = self._intf.read(self._conf['base_addr'] + 1, 1)[0]
        self._intf.write(self._conf['base_addr'] + 1, [(current & 0xfe) | enable])
        
    def get_en(self):
        return True if (self._intf.read(self._conf['base_addr'] + 1, 1)[0] & 0x01) else False
    
    def set_exten(self, enable):
        current = self._intf.read(self._conf['base_addr'] + 1, 4)
        self._intf.write(self._conf['base_addr'] + 1, [(current[3] & 0xfe) | enable,current[2],current[1],current[0]])
        
    def get_exten(self):
        return True if (self._intf.read(self._conf['base_addr'] + 1, 4)[3] & 0x01) else False

    