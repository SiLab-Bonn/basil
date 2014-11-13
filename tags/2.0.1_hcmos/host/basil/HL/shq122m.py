#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev:: 261                   $:
#  $Author:: jejan              $:
#  $Date:: 2014-06-06 15:16:45 #$:
#
import time
import Queue
import math

from basil.HL.HardwareLayer import HardwareLayer

import iseg_shq


# # class for debug
# class Queue.Queue()Message_q():
#     def __init__(self):
#         pass
#     def put(self, message):
#         print message
#     def close(self):
#         pass

class shq122m(HardwareLayer):
    '''interface for iseg SHQ 122M
        ###### yaml file #####
        hw_drivers:
          - name      : SHQ
            type      : shq122m
            interface : None
            port : \\.\COM5
       registers:     
          - name        : HV
            type        : FunctionalRegister
            hw_driver   : SHQ
            arg_names   : [ value ]
            arg_add     : { 'channel': 1}
    '''

    def __init__(self, intf, conf):
        super(shq122m, self).__init__(intf, conf)

    def init(self):
        self.s = iseg_shq.IsegShqCom(message_q=Queue.Queue(), port_num=self._init['port'])
        self.s.init_iseg()
        self.info = self.s.read_identifier()

    def set_voltage(self, channel=1, value=0, unit='mV', verror=0.1, timeout=1):
        if unit == 'raw':
            raw = value
        elif unit == 'V':
            raw = value
        elif unit == 'mV':
            raw = value * 0.001
        else:
            raise TypeError("Invalid unit type.")
        self.s.write_v_set(channel, raw)
        self.s.write_start_ramp(channel)
        start_time = time.time()
        
        while self.s.read_status_word() != 'ON' or abs(self.s.read_voltage()+raw) > verror or math.isnan(self.s.read_current()):
            self.s.read_status_word()
            self.s.write_v_set(voltage=raw)
            self.s.write_start_ramp()
            time.sleep(0.001)
            
            if time.time()-start_time > timeout:
                raise Exception("shq122m timeout")

    def get_voltage(self, channel=1, unit='mV'):
        raw = self.s.read_voltage(channel)
        if unit == 'raw':
            return raw
        elif unit == 'V':
            return raw
        elif unit == 'mV':
            return raw * 1000
        else:
            raise TypeError("Invalid unit type.")

    def get_current(self, channel=1, unit='mA'):
        raw = self.s.read_current(channel)
        if unit == 'raw':
            return raw
        elif unit == 'A':
            return raw
        elif unit == 'mA':
            return raw * 1000
        elif unit == 'uA':
            return raw * 1000000
        else:
            raise TypeError("Invalid unit type.")
