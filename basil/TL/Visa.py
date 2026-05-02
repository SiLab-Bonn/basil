#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import pyvisa as visa
import numpy as np
import logging
import time

from basil.TL.TransferLayer import TransferLayer
from pyvisa.errors import VisaIOError
from basil.utils.utils import log_exception

# get the IterableType
try:
    from collections import Iterable as IterableType
except ImportError:
    # python 3.10 and above
    from collections.abc import Iterable as IterableType

logger = logging.getLogger(__name__)


class Visa(TransferLayer):
    '''Transfer layer for a Virtual Instrument Software Architecture (VISA) provided by pyVisa.
    Several interfaces are available (GPIB, RS232, USB, Ethernet). To be able to use pyVisa without
    the proprietary NI-VISA driver a pyVisa backend pyVisa-py can be used.
    GPIB under linux is not supported via pyVisa-py right now.
    '''

    propagation_exception = ("backend", "binary_mode", "enable_logging", "visa_log_level")

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
        self._use_binary_mode = self._init.get('binary_mode', False)
        if self._init.get('enable_logging', False):
            visa.log_to_screen(self._init.get('visa_log_level', logging.ERROR))
        rm = visa.ResourceManager(backend)
        try:
            logger.info('BASIL VISA TL with %s backend found the following devices: %s', backend,
                        ", ".join(rm.list_resources()))
        except NotImplementedError:  # some backends do not always implement the list_resources function
            log_exception(logger, 'BASIL VISA TL WITH %s backend', backend, level=logging.INFO)
            # logger.info('BASIL VISA TL with %s backend', backend)

        # make interface compatible with other transfer layers (serial)
        if "baudrate" in self._init.keys():
            self._init["baud_rate"] = self._init.pop("baudrate")

        self._resource = rm.open_resource(
            **{key: value for key, value in self._init.items() if key not in self.propagation_exception})

    def __enter__(self):
        self.init()
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        if exc_type is not None:
            if isinstance(exc_value, IterableType):
                for e_type, e, e_trace in zip(exc_type, exc_value, traceback):
                    log_exception(logger, "While handling communication with the lab device an error occurred.",
                                  exc_value=(e_type, e, e_trace))
            else:
                log_exception(logger, "While handling communication with the lab device an error occurred.",
                              exc_value=(exc_type, exc_value, traceback))
        self.close()
        return False

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
        elif self._use_binary_mode:
            # when providing the correct keyword arguments, this should allow for parsing of binary data and faster readout of multiple data
            ret = self._resource.query_binary_values(data, datatype='f', container=np.ndarray, is_big_endian=False, )
        else:
            ret = self._resource.query(data)
        return ret

    def query_binary(self, data, data_type='f', max_tries=10000):
        ''' Use a dedicated handler to query binary data from the device. This could speed up acquiring large datasets.'''
        # TODO: merge this into query()
        if not self._use_binary_mode or self._resource.read_termination == "":
            logger.warning("query_binary() is not supported for this device.")
            return self.query(data, max_tries)
        return self._resource.query_binary_values(data, datatype=data_type, container=np.ndarray, is_big_endian=False, )