#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

"""
This script is used to communicate with the chiller julabo fp50
"""

import logging
import time

from basil.HL.RegisterHardwareLayer import HardwareLayer


logger = logging.getLogger(__name__)


class julaboFP50(HardwareLayer):
    ''' Driver for the Julabo FP50 chiller.
    A simple protocol via crossed null modem serial port is used with baud rate of 9600.
    '''

    def __init__(self, intf, conf):
        super(julaboFP50, self).__init__(intf, conf)
        self.pre_time = time.time()

    def init(self):
        super(julaboFP50, self).init()

    def read(self):
        ret = self._intf.read()
        if len(ret) < 2 or ret[-2:] != "\r\n":
            logger.warning("read() termination error")
        return ret[:-2]

    def write(self, cmd):
        if time.time() - self.pre_time < 1.0:
            time.sleep(1.0)
        self._intf.write(str(cmd))
        self.pre_time = time.time()

    def get_version(self):
        ''' Read identifier
        '''
        self.write("version")
        ret = self.read()
        return ret

    def start_chiller(self):
        ''' Start chiller
        '''
        self.write("out_mode_05 1")

    def stop_chiller(self):
        ''' Stop chiller
        '''
        self.write("out_mode_05 0")

    def get_status(self):
        ''' Get status
        '''
        self.write("status")
        ret = self.read()
        logger.debug("status:{:s}".format(ret))
        try:
            tmp = ret.split(" ", 1)
            status = int(tmp[0])
            status_str = tmp[1:]
        except (ValueError, AttributeError):
            logger.warning("get_status() wrong format: {}".format(repr(ret)))
            status = -99
            status_str = ret
        return status, status_str

    def get_set_temp(self):
        '''get the set temperature
        '''
        self.write("in_sp_00")
        ret = self.read()
        return float(ret)

    def set_temp(self, temp):
        '''set the temperature to a value
        '''
        self.write(f"out_sp_00={temp}")

    def get_temp(self):
        '''get the current temperature in chiller
        '''
        self.write("in_pv_00")
        ret = self.read()
        return float(ret)
