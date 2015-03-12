#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import serial

from basil.TL.TransferLayer import TransferLayer


class SiSerial(TransferLayer):

    '''Transfer layer of serial device using the pySerial module.
    '''

    def __init__(self, conf):
        super(TransferLayer, self).__init__(conf)
        self._port = None

    def init(self):
        '''
        Initialize serial device.
        Parameters of serial.Serial: http://pyserial.sourceforge.net/pyserial_api.html
        Plus termination string parameter eol
        '''
        self.eol = self._init.pop('eol', '')
        self._port = serial.Serial(**self._init)

    def write(self, data):
        self._port.write(data + self.eol)

    def read(self, size=None):
        self._port.readline(limit=size)

    def ask(self, data):
        self.write(data)
        return self._port.readline()
