#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import struct

from basil.HL.binder_mk53 import binderMK53


class binderMK56(binderMK53):
    """Driver for the Binder MK 56 climate chamber.
    A protocoll _similar_ to MODBus via RS 422 serial port is used with 9600 baud rate.
    Credits to ecree-solarflare with some further information at https://github.com/ecree-solarflare/ovenctl
    """

    ADDR_CURTEMP = 0x1004
    ADDR_SETPOINT = 0x10b2
    ADDR_MANSETPT = 0x114c

    def get_door_open(self):
        raise NotImplementedError("Get Door not available for MK56.")

    def get_mode(self):
        raise NotImplementedError("Get Mode not available for MK56.")

    def set_temperature(self, temperature, reps=10):
        if temperature < self.min_temp:
            raise RuntimeWarning(
                f'Set temperature {temperature} is lower than minimum allowed temperature {self.min_temp}')
        if temperature > self.max_temp:
            raise RuntimeWarning(
                f'Set temperature {temperature} is higher than maximum allowed temperature {self.max_temp}')
        for _ in range(reps):
            try:
                self.write(self.ADDR_MANSETPT, self._encode_float(temperature))
                break
            except RuntimeWarning:
                pass

    def _parse_read_response(self, msgbytes):
        if len(msgbytes) < 3:
            raise ValueError(f'Read data is too short: {len(msgbytes)}')
        _, func, n_bytes = struct.unpack('>BBB', msgbytes[:3])
        if func not in [self.FUNCTION_READN, self.FUNCTION_READN_ALT]:
            raise ValueError('Wrong function returned')
        if n_bytes & 1:
            raise ValueError("Odd number of bytes read")
        if len(msgbytes) < 5 + n_bytes:
            raise ValueError(f'Read data is too short: {len(msgbytes)}')
        crc = struct.unpack('<H', msgbytes[3 + n_bytes:5 + n_bytes])
        checkcrc = (self._calc_crc16(msgbytes[:3 + n_bytes]),)
        if crc != checkcrc:
            raise ValueError('Checksum of read data wrong')
        n_words = n_bytes >> 1
        words = []
        for word in range(n_words):
            words.extend(struct.unpack('>H', msgbytes[3 + word * 2:5 + word * 2]))
        return words

    def _parse_write_response(self, msgbytes):
        if len(msgbytes) < 8:
            raise ValueError(f'Message too short: {len(msgbytes)}')
        crc = struct.unpack('<H', msgbytes[6:8])
        _, func, addr, value = struct.unpack('>BBHH', msgbytes[:6])
        if func != self.FUNCTION_WRITEN:
            raise ValueError('Wrong write function returned')
        checkcrc = (self._calc_crc16(msgbytes[:6]),)
        if crc != checkcrc:
            raise ValueError('Checksum of read after write data wrong')
        return addr, value

    def _parse_error_response(self, msgbytes):  # string -> (bool, int)
        if len(msgbytes) < 5:
            return False, None
        crc = struct.unpack('<H', msgbytes[3:5])
        _, func, ecode = struct.unpack('>BBB', msgbytes[:3])
        if not func & 0x80:
            return False, None
        checkcrc = (self._calc_crc16(msgbytes[:3]),)
        if crc != checkcrc:
            raise ValueError(f'CRC Error: {str(crc)} - {str(checkcrc)} (bytes: {str(msgbytes)})')
        return True, ecode
