#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import visa
import logging

from basil.TL.TransferLayer import TransferLayer


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
        backend = self._init.pop('backend', '')  # Empty string means std. backend (NI VISA)
        rm = visa.ResourceManager(backend)
        try:
            logging.info('BASIL VISA TL with %s backend found the following devices: %s', backend, rm.list_resources())
        except NotImplementedError:  # some backends do not always implement the list_resources function
            logging.info('BASIL VISA TL instanciated with %s backend', backend)
        self._resource = rm.open_resource(**self._init)

    def close(self):
        self._resource.close()

    def write(self, data):
        self._resource.write(data)

    def read(self):
        self._resource.read()

    def query(self, data):
        return self._resource.query(data)
