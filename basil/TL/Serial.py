#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import logging

import serial

from basil.TL.TransferLayer import TransferLayer

logger = logging.getLogger(__name__)


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
        super(Serial, self).init()
        self.read_termination = self._init.get('read_termination', None)
        self.write_termination = self._init.get('write_termination', self.read_termination)
        try:
            self.read_termination = bytes(self.read_termination, 'utf-8')
            self.write_termination = bytes(self.write_termination, 'utf-8')
        except TypeError as e:
            logger.debug(e)
        self.timeout = self._init.get('timeout', None)  # timeout of 0 returns immediately

        self._port = serial.Serial(**{key: value for key, value in self._init.items() if key not in ("read_termination", "write_termination")})

    def close(self):
        super(Serial, self).close()
        self._port.close()

    def write(self, data):
        if self.write_termination is None:
            try:
                self._port.write(bytes(data, 'utf-8'))
            except TypeError:  # Python 2.7
                self._port.write(bytes(data))
        else:
            try:
                self._port.write(bytes(data, 'utf-8') + self.write_termination)
            except TypeError:  # Python 2.7
                self._port.write(bytes(data + self.write_termination))

    def read(self, size=None):
        if size is None:
            return self._readline()
        return bytearray(self._port.read(size))

    def query(self, data):
        if self._port.inWaiting():
            logger.warning("Found %d bytes in the input buffer of interface %s which will be flushed" % (self._port.inWaiting(), self.name))
            self._port.flushInput()
        self.write(data)
        return self._readline()

    def _readline(self):  # http://stackoverflow.com/questions/16470903/pyserial-2-6-specify-end-of-line-in-readline
        # catch a few cases:
        # 1. termination of None will never return
        # 2. termination of "" will return immediately
        # 3. timeout of None will never return
        if not self.read_termination and self.timeout is None:
            raise RuntimeError('Requested serial read will not terminate due to missing termination string and missing timeout')

        data = bytearray()
        count = len(self.read_termination) if self.read_termination else 0
        while data[-count:] != self.read_termination:  # termination of "" returns immediately
            character = self._port.read(1)
            data += character
            if not character:
                break
        return data.decode('utf-8', errors='ignore')
