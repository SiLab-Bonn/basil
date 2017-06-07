#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import serial

from basil.TL.TransferLayer import TransferLayer


class Serial(TransferLayer):
    '''Transfer layer of serial device using the pySerial module.
    '''

    def __init__(self, conf):
        super(Serial, self).__init__(conf)
        self._port = None

    def init(self):
        '''
        Initialize serial device.
        Parameters of serial.Serial: http://pyserial.sourceforge.net/pyserial_api.html
        Plus termination string parameter eol
        '''
        self.read_termination = self._init.pop('read_termination', None)
        self.write_termination = self._init.pop('write_termination', self.read_termination)
        self.timeout = self._init['timeout'] if 'timeout' in self._init else None

        self._port = serial.Serial(**self._init)

    def close(self):
        self._port.close()

    def write(self, data):
        if self.write_termination is None:
            self._port.write(bytes(data))
        else:
            self._port.write(bytes(data + self.write_termination))

    def read(self, size=None):
        if size is None:
            return self._readline()
        return self._port.read(size)

    def query(self, data):
        self.write(data)
        return self._readline()

    def _readline(self):  # http://stackoverflow.com/questions/16470903/pyserial-2-6-specify-end-of-line-in-readline
        if self.read_termination == '' and self.timeout is None:
            raise RuntimeError('Requested serial read will not terminate due to missing termination string and missing time out')

        data = bytearray()
        count = len(self.read_termination) if self.read_termination else 0
        while data[-count:] != self.read_termination:
            character = self._port.read(1)
            data += character
            if not character:
                break
        return bytes(data)
