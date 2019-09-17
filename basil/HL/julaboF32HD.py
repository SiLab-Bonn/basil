#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging
import time

from basil.HL.RegisterHardwareLayer import HardwareLayer


logger = logging.getLogger(__name__)


class julaboF32HD(HardwareLayer):
    ''' Driver for the Julabo F32-HD chiller.
    A simple protocol via RS 232 serial port is used with 4800 baud rate.
    '''

    def __init__(self, intf, conf):
        super(julaboF32HD, self).__init__(intf, conf)
        self.pre_time = time.time()

    def init(self):
        super(julaboF32HD, self).init()

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

    def get_identifier(self):
        ''' Read identifier
        '''
        self.write("version")
        ret = self.read()
        return ret

    def start_thermostat(self, start=True):
        ''' Start chiller
        '''
        if start is True:
            self.write("out_mode_05 1")
        else:
            self.write("out_mode_05 0")

    def stop_thermostat(self):
        ''' Stop chiller
        '''
        self.start_thermostat(False)

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
