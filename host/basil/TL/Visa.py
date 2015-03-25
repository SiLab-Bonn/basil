#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import visa

from basil.TL.TransferLayer import TransferLayer


class SiVisa(TransferLayer):

    '''Transfer layer for a Virtual Instrument Software Architecture (VISA) provided by pyVisa.
    Several interfaces are available (GPIB, RS232, USB, Ethernet). To be able to use pyVisa without
    the proprietary NI-VISA driver a pyVisa backend pyVisa-py is used.
    GPIB under linux is not supported via pyVisa-py right now and linux-gpib does not
    compile on modern kernels right now. Thus no GPIB linux support on modern systems.
    '''

    def __init__(self, conf):
        super(TransferLayer, self).__init__(conf)
        self._port = None

    def init(self):
        '''
        Initialize the device.
        Parameters of visa.ResourceManager().open_resource()
        '''
        backend = self._init.pop('backend', '')
        rm = visa.ResourceManager(backend)
        self._resource = rm.open_resource(**self._init)

    def write(self, data):
        self._resource.write(data)

    def read(self):
        self._resource.read()

    def ask(self, data):
        return self._resource.query(data)
