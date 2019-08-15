#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging
import array
from struct import pack
from time import sleep

import serial

from basil.TL.TransferLayer import TransferLayer

logger = logging.getLogger(__name__)


class SiUart(TransferLayer):
    _ser = None

    def __init__(self, conf):
        super(SiUart, self).__init__(conf)

    def init(self):
        super(SiUart, self).init()
        self._init.setdefault('board_id', None)
        self._init.setdefault('avoid_download', False)
        if self._init['board_id'] and int(self._init['board_id']) >= 0:
            self._ser = serial.Serial()
            if 'port' in self._init.keys():
                self._ser.setPort(self._init['port'])
            if 'baudrate' in self._init.keys():
                self._ser.setBaudrate(self._init['baudrate'])
            if 'parity' in self._init.keys() and self._init["parity"] == 0:
                self._ser.setParity(serial.PARITY_NONE)
            if 'stopbits' in self._init.keys():
                self._ser.setStopbits(self._init['stopbits'])
            if 'bytesize' in self._init.keys():
                self._ser.setByteSize(self._init['bytesize'])
            if 'timeout' in self._init.keys():
                self._ser.setTimeout(self._init['timeout'])

            self._ser.open()
            if not self._ser.isOpen():
                raise IOError("Port at %s not open" % self._ser.port)
        else:
            logger.info('Found board')

    def __del__(self):
        self._ser.close()

    def write(self, addr, data):
        logger.debug("------------ writing ------------")
        logger.debug('Addr: %s \tdata: %s', addr, data)
        done = False

        a = array.array('B', 'a') + array.array('B', pack("<I", addr))
        self._ser.write(a)
        if "OK" in self._ser.readall():
            logger.debug("Addr is okay")

        length_bytes = array.array('B', 'l') + array.array('B', pack("<I", len(data)))
        self._ser.write(length_bytes)
        if "OK" in self._ser.readall():
            logger.debug("Length is okay")

        w = array.array('B', 'w') + array.array('B', data)
        self._ser.write(w)
        while self._ser.outWaiting() > 0:
            logger.debug("writing ...")
        sleep(0.3)
        if "OK" in self._ser.readall():
            done = True
            logger.debug("Writing finished")
            return done

        raise Exception("Write serial port failed.")

    def read(self, addr, size):
        logger.debug("------------ reading ------------")
        logger.debug('Addr: %s \tSize: %s', addr, size)

        a = array.array('B', 'a') + array.array('B', pack("<I", addr))
        self._ser.write(a)
        if "OK" in self._ser.readall():
            logger.debug("Addr is okay")

        length_bytes = array.array('B', 'l') + array.array('B', pack("<I", size))
        self._ser.write(length_bytes)
        if "OK" in self._ser.readall():
            logger.debug("Length is okay")

        r = array.array('B', 'r')
        self._ser.write(r)
        dataOut = self._ser.read(size)
        while self._ser.inWaiting() > 0:
            logger.info("reading ...")
        sleep(0.3)
        if "OK" in self._ser.read():
            a = array.array('B', dataOut)
            logger.debug("Reading finished")
            return a
        raise Exception("Read serial port failed")

    def close(self):
        super(SiUart, self).close()
        self._ser.close()
        logger.debug("_serial _port closed successfully")
