#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import struct

from basil.HL.binder_mk53 import binderMK53

# MODBus function codes
FUNCTION_READN = 0x03  # read n words
FUNCTION_READN_ALT = 0x04  # read n words, does not occur
FUNCTION_WRITE = 0x06  # write word
FUNCTION_WRITEN = 0x10  # write n words

# Error codes
ERROR_CODES = {
    1: "Invalid function",
    2: "Invalid parameter address",
    3: "Pparameter value outside range of values",
    4: "Slave not ready",
    5: "Write access to parameter denied"
}


class binderMK56(binderMK53):

    '''Driver for the Binder MK 53 climate chamber.
    A protocoll _similar_ to MODBus via RS 422 serial port is used with 9600 baud rate.
    Credits to ecree-solarflare with some further information at https://github.com/ecree-solarflare/ovenctl
    '''

    def __init__(self, intf, conf):
        super(binderMK56, self).__init__(intf, conf)

    def init(self):
        super(binderMK56, self).init()
        self.ADDR_CURTEMP = 0x1004
        self.ADDR_SETPOINT = 0x10b2
        self.ADDR_MANSETPT = 0x114c

        self.slave_address = self._init['address']  # set the device address
        self.min_temp = self._init['min_temp']  # define the minimum temperature one can set, for safety
        self.max_temp = self._init['max_temp']  # define the maximum temperature one can set, for safety

    def get_door_open(self):
        raise NotImplementedError("Get Door not available for MK56.")

    def get_mode(self):
        raise NotImplementedError("Get Mode not available for MK56.")

    def set_temperature(self, temperature, reps=10):
        if temperature < self.min_temp:
            raise RuntimeWarning('Set temperature %f is lower than minimum allowed temperature %f' % (temperature, self.min_temp))
        if temperature > self.max_temp:
            raise RuntimeWarning('Set temperature %f is higher than maximum allowed temperature %f' % (temperature, self.max_temp))
        for _ in range(reps):
            try:
                self.write(self.ADDR_MANSETPT, self._encode_float(temperature))
                break
            except RuntimeWarning:
                pass


    def _parse_read_response(self, msgbytes):
        if len(msgbytes) < 3:
            raise RuntimeWarning('Read data is too short: %d' % len(msgbytes))
        _, func, n_bytes = struct.unpack('>BBB', msgbytes[:3])
        if func not in [FUNCTION_READN, FUNCTION_READN_ALT]:
            raise RuntimeWarning('Wrong function returned')
        if n_bytes & 1:
            raise RuntimeWarning("Odd number of bytes read")
        if len(msgbytes) < 5 + n_bytes:
            raise RuntimeWarning('Read data is too short: %d' % len(msgbytes))
        crc = struct.unpack('<H', msgbytes[3 + n_bytes:5 + n_bytes])
        checkcrc = (self._calc_crc16(msgbytes[:3 + n_bytes]), )
        if crc != checkcrc:
            raise RuntimeWarning('Checksum of read data wrong')
        n_words = n_bytes >> 1
        words = []
        for word in range(n_words):
            words.extend(struct.unpack('>H', msgbytes[3 + word * 2:5 + word * 2]))
        return words

    def _parse_write_response(self, msgbytes):
        if len(msgbytes) < 8:
            raise RuntimeWarning('Message too short: %d' % len(msgbytes))
        crc = struct.unpack('<H', msgbytes[6:8])
        _, func, addr, value = struct.unpack('>BBHH', msgbytes[:6])
        if func != FUNCTION_WRITEN:
            raise RuntimeWarning('Wrong write function returned')
        checkcrc = (self._calc_crc16(msgbytes[:6]), )
        if crc != checkcrc:
            raise RuntimeWarning('Checksum of read after write data wrong')
        return addr, value

    def _parse_error_response(self, msgbytes):  # string -> (bool, int)
        if len(msgbytes) < 5:
            return False, None
        crc = struct.unpack('<H', msgbytes[3:5])
        _, func, ecode = struct.unpack('>BBB', msgbytes[:3])
        if not func & 0x80:
            return False, None
        checkcrc = (self._calc_crc16(msgbytes[:3]), )
        if crc != checkcrc:
            raise RuntimeWarning('CRC Error: %s - %s (bytes: %s)' % (str(crc), str(checkcrc), str(msgbytes)))
        return True, ecode

