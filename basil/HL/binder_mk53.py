#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import struct

from basil.HL.RegisterHardwareLayer import HardwareLayer

# MODBus function codes
FUNCTION_READN = 0x03  # read n words
FUNCTION_READN_ALT = 0x04  # read n words, does not occur
FUNCTION_WRITE = 0x06  # write word
FUNCTION_WRITEN = 0x10  # write n words

# Operation addresses
ADDR_CURTEMP = 0x11a9
ADDR_DOOROPEN = 0x1007  # does not work, wrong address?
ADDR_SETPOINT = 0x1077
ADDR_MANSETPT = 0x1581
ADDR_BASICSETPT = 0x156f
ADDR_MODE = 0x1a22

# Error codes
ERROR_CODES = {
    1: "Invalid function",
    2: "Invalid parameter address",
    3: "Pparameter value outside range of values",
    4: "Slave not ready",
    5: "Write access to parameter denied"
}


class binderMK53(HardwareLayer):

    '''Driver for the Binder MK 53 climate chamber.
    A protocoll _similar_ to MODBus via RS 422 serial port is used with 9600 baud rate.
    Credits to ecree-solarflare with some further information at https://github.com/ecree-solarflare/ovenctl
    '''

    def __init__(self, intf, conf):
        super(binderMK53, self).__init__(intf, conf)

    def init(self):
        self.slave_address = self._init['address']  # set the device address
        self.min_temp = self._init['min_temp']  # define the minimum temperature one can set, for safety
        self.max_temp = self._init['max_temp']  # define the maximum temperature one can set, for safety

    def get_temperature(self):
        return self._decode_float(self.read(ADDR_CURTEMP, 2))

    def get_temperature_target(self):
        return self._decode_float(self.read(ADDR_SETPOINT, 2))

    def get_door_open(self):  # FIXME: does not work with tested model
        return bool(self.read(ADDR_DOOROPEN, 1)[0])

    def get_mode(self):
        mode = self.read(ADDR_MODE, 1)[0]
        modes = []
        if mode & 0x1000:
            modes.append("basic")
        if mode & 0x0800:
            modes.append("manual")
        if mode & 0x0400:
            modes.append("auto")
        if not len(modes):
            modes.append("idle")
        return modes

    def set_temperature(self, temperature):
        if temperature < self.min_temp:
            raise RuntimeWarning('Set temperature %f is lower than minimum allowed temperature %f', temperature, self.min_temp)
        if temperature > self.max_temp:
            raise RuntimeWarning('Set temperature %f is higher than maximum allowed temperature %f', temperature, self.max_temp)
        self.write(ADDR_MANSETPT, self._encode_float(temperature))
        self.write(ADDR_BASICSETPT, self._encode_float(temperature))

    def read(self, addr, n_words):  # read n words
        read_req = self._make_read_request(addr, n_words)
        self._intf.write(read_req)
        exp_length = 5 + (n_words * 2)
        resp = self._intf.read(exp_length)
        is_err, err_code = self._parse_error_response(resp)
        if is_err:
            RuntimeWarning('Error code %d: %s', err_code[err_code])
        data = self._parse_read_response(resp)
        return data

    def write(self, addr, value):  # write n words with acknowledge
        write_req = self._make_write_request(addr, value)
        self._intf.write(write_req)
        resp_len = 8
        resp = self._intf.read(resp_len)

        is_err, err_code = self._parse_error_response(resp)
        if is_err:
            RuntimeWarning('Error code %d: %s', err_code[err_code])
        resp_addr, resp_words = self._parse_write_response(resp)
        if not (resp_addr == addr) and (resp_words == len(value)):
            raise RuntimeWarning('Write check failed')

    def _parse_read_response(self, msgbytes):
        if len(msgbytes) < 3:
            raise RuntimeWarning('Read data is too short', len(msgbytes))
        _, func, n_bytes = struct.unpack('>BBB', msgbytes[:3])
        if func not in [FUNCTION_READN, FUNCTION_READN_ALT]:
            raise RuntimeWarning('Wrong function returned')
        if n_bytes & 1:
            raise RuntimeWarning("Odd number of bytes read")
        if len(msgbytes) < 5 + n_bytes:
            raise RuntimeWarning('Read data is too short', len(msgbytes))
        crc, = struct.unpack('<H', msgbytes[3 + n_bytes:5 + n_bytes])
        checkcrc = self._calc_crc16(msgbytes[:3 + n_bytes])
        if crc != checkcrc:
            raise RuntimeWarning('Checksum of read data wrong')
        n_words = n_bytes >> 1
        words = []
        for word in xrange(n_words):
            words.extend(struct.unpack('>H', msgbytes[3 + word * 2:5 + word * 2]))
        return words

    def _parse_write_response(self, msgbytes):
        if len(msgbytes) < 8:
            raise RuntimeWarning('Message too short', len(msgbytes))
        crc, = struct.unpack('<H', msgbytes[6:8])
        _, func, addr, value = struct.unpack('>BBHH', msgbytes[:6])
        if func != FUNCTION_WRITEN:
            raise RuntimeWarning('Wrong write function returned')
        checkcrc = self._calc_crc16(msgbytes[:6])
        if crc != checkcrc:
            raise RuntimeWarning('Checksum of read after write data wrong')
        return addr, value

    def _parse_error_response(self, msgbytes):  # string -> (bool, int)
        if len(msgbytes) < 5:
            return False, None
        crc, = struct.unpack('<h', msgbytes[3:5])
        _, func, ecode = struct.unpack('>BBB', msgbytes[:3])
        if not func & 0x80:
            return False, None
        checkcrc = self._calc_crc16(msgbytes[:3])
        if crc != checkcrc:
            raise RuntimeWarning(crc, checkcrc, msgbytes)
        return True, ecode

    def _make_write_request(self, addr, words):
        n_words = len(words)
        msg = struct.pack('>BBHHB', self.slave_address, FUNCTION_WRITEN, addr, n_words, n_words * 2)
        for word in words:
            msg += struct.pack('>H', word)
        return msg + struct.pack('<H', self._calc_crc16(msg))

    def _make_read_request(self, addr, n_words):
        msg = struct.pack('>BBHH', self.slave_address, FUNCTION_READN, addr, n_words)
        return msg + struct.pack('<H', self._calc_crc16(msg))

    def _encode_float(self, value):
        words = struct.unpack('>HH', struct.pack('>f', value))
        return words[1], words[0]

    def _decode_float(self, value):
        return struct.unpack('>f', struct.pack('>HH', value[1], value[0]))[0]

    def _calc_crc16(self, msg):
        crc = 0xffff
        for byte in msg:
            crc ^= ord(byte)
            for _ in xrange(8):  # loop bits
                sbit = crc & 1
                crc >>= 1
                crc ^= sbit * 0xA001
        return crc
