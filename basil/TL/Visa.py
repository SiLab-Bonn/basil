#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import pyvisa as visa
import logging
import time

from basil.TL.TransferLayer import TransferLayer
from pyvisa.errors import VisaIOError

logger = logging.getLogger(__name__)


class Visa(TransferLayer):
    '''Transfer layer for a Virtual Instrument Software Architecture (VISA) provided by pyVisa.
    Several interfaces are available (GPIB, RS232, USB, Ethernet). To be able to use pyVisa without
    the proprietary NI-VISA driver a pyVisa backend pyVisa-py can be used.
    GPIB under linux is not supported via pyVisa-py right now.
    '''

    def __init__(self, conf):
        super(Visa, self).__init__(conf)
        self._resource = None

    def init(self):
        '''
        Initialize the device.
        Parameters of visa.ResourceManager().open_resource()
        '''
        super(Visa, self).init()
        backend = self._init.get('backend', '')  # Empty string means std. backend (NI VISA)
        rm = visa.ResourceManager(backend)
        try:
            logger.info('BASIL VISA TL with %s backend found the following devices: %s', backend, ", ".join(rm.list_resources()))
        except NotImplementedError:  # some backends do not always implement the list_resources function
            logger.info('BASIL VISA TL with %s backend', backend)

        self._resource = rm.open_resource(**{key: value for key, value in self._init.items() if key not in ("backend",)})

    def close(self):
        super(Visa, self).close()
        self._resource.close()

    def write(self, data):
        self._resource.write(data)

    def read(self):
        if self._resource.read_termination == "":
            ret = ""
            while True:
                try:
                    ret += self._resource.read_bytes(1).decode(self._resource._encoding)
                except VisaIOError:
                    break
        else:
            ret = self._resource.read()
        return ret

    def query(self, data, max_tries=10000):
        if self._resource.read_termination == "":
            self.write(data)
            time.sleep(self._resource.query_delay)
            ret = ""
            for _ in range(max_tries):
                try:
                    ret += self._resource.read_bytes(1).decode(self._resource._encoding)
                except VisaIOError:
                    break
        else:
            ret = self._resource.query(data)
        return ret
