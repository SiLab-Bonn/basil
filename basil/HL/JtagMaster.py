#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer
from basil.utils.BitLogic import BitLogic
from bitarray import bitarray
import numpy as np


class JtagMaster(RegisterHardwareLayer):
    """
    SPI based JTAG interface
    """

    _registers = {
        "RESET": {"descr": {"addr": 0, "size": 8, "properties": ["writeonly"]}},
        "VERSION": {"descr": {"addr": 0, "size": 8, "properties": ["ro"]}},
        "READY": {"descr": {"addr": 1, "size": 1, "properties": ["ro"]}},
        "START": {"descr": {"addr": 1, "size": 8, "properties": ["writeonly"]}},
        "SIZE": {"descr": {"addr": 3, "size": 16}},
        "WAIT": {"descr": {"addr": 5, "size": 32}},
        "WORD_COUNT": {"descr": {"addr": 9, "size": 16}},
        "COMMAND": {"descr": {"addr": 11, "size": 16}},
        "EN": {"descr": {"addr": 13, "size": 1}},
        "MEM_BYTES": {"descr": {"addr": 14, "size": 16, "properties": ["ro"]}},
    }

    _require_version = "==1"

    jtag_command = {"INSTRUCTION": 0, "DATA": 1}

    def __init__(self, intf, conf):
        super(JtagMaster, self).__init__(intf, conf)
        self._mem_offset = 16  # in bytes
        self._memout_offset = 0
        self._memin_offset = 16

    def init(self):
        super(JtagMaster, self).init()
        self._mem_bytes = self.MEM_BYTES

    def reset(self):
        """
        Soft reset the module.
        """
        self.RESET = 0
        while not self.READY:
            pass

    def start(self):
        """
        Starts the shifting data
        """
        self.START = 0

    def set_command(self, value):
        """
        IR_SCAN or DR_SCAN
        """
        self.COMMAND = self.jtag_command[value]

    def get_command(self):
        """
        IR_SCAN or DR_SCAN
        """
        return list(self.jtag_command.keys())[self.COMMAND]

    def set_data(self, data, addr=0):
        """
        Sets data for outgoing stream
        """
        if self._mem_bytes < len(data):
            raise ValueError("Size of data (%d bytes) is too big for memory (%d bytes)" % (len(data), self._mem_bytes))
        self._intf.write(self._conf["base_addr"] + self._mem_offset + addr, data)

    # This needs to be changed to return written value
    def get_data(self, size=None, addr=None):
        """
        Gets data for incoming stream
        """
        # readback memory offset
        if addr is None:
            addr = self._mem_bytes

        if size and self._mem_bytes < size:
            raise ValueError("Size is too big")

        if size is None:
            return self._intf.read(self._conf["base_addr"] + self._mem_offset + addr, self._mem_bytes)
        else:
            return self._intf.read(self._conf["base_addr"] + self._mem_offset + addr, size)

    def scan_ir(self, data, readback=True):
        """
        Data must be a list of BitLogic
        """

        bit_number = self._test_input(data)
        self.SIZE = bit_number

        if type(data[0]) == BitLogic:
            data_byte = self._bitlogic2bytes(data)
        else:
            data_byte = self._raw_data2bytes(data)

        self.set_data(data_byte)

        self.WORD_COUNT = 1
        self.set_command("INSTRUCTION")
        self.start()
        while not self.READY:
            pass

        if readback:
            received_data = self.get_data(size=len(data_byte))
            return self._bytes2bitlogic(received_data, bit_number, data)

    def scan_dr(self, data, readback=True, word_size=None):
        """
        Data must be a list of BitLogic or string of raw data
        """

        bit_number = self._test_input(data, word_size)

        self.set_command("DATA")

        if word_size is None:
            self.SIZE = bit_number
            self.WORD_COUNT = 1
        else:
            self.WORD_COUNT = bit_number // word_size
            self.SIZE = word_size

        if type(data[0]) == BitLogic:
            data_byte = self._bitlogic2bytes(data)
        else:
            data_byte = self._raw_data2bytes(data)

        self.set_data(data_byte)

        self.start()
        while not self.READY:
            pass

        if readback:
            received_data = self.get_data(size=len(data_byte))
            return self._bytes2bitlogic(received_data, bit_number, data)

    def _test_input(self, data, word_size=None):
        """
        Test input data and return length in bits
        """

        if not isinstance(data, list):
            raise ValueError("Input data must be a list of BitLogic or str")

        if type(data[0]) not in [BitLogic, str]:
            raise TypeError("Type of data not supported: got", type(data[0]), " and support only str and Bitlogic")

        bit_number = sum(len(x) for x in data)
        if bit_number > self._mem_bytes * 8:
            raise ValueError("Size is too big for memory: got %d and memory is: %d" % (bit_number, self._mem_bytes * 8))

        if word_size is not None and bit_number % word_size != 0:
            raise ValueError("Number of bits doesn't match word_size. %d bits remaining" % (bit_number % word_size))

        return bit_number

    def _bitlogic2bytes(self, data):
        original_string = ""
        for dev in range(len(data)):
            device_string = data[dev].to01()
            original_string += device_string[::-1]  # We want the original string of the Bitlogic, not the reversed one
        data_bitarray = bitarray(original_string)
        return data_bitarray.tobytes()

    def _bytes2bitlogic(self, data, bit_number, original_data):
        data_byte = np.byte(data)
        tmp = bitarray()
        tmp.frombytes(data_byte.tobytes())
        binary_string = tmp.to01()

        rlist = []

        last_data_len = 0
        for i in original_data:
            rlist.append(BitLogic(binary_string[last_data_len:len(i) + last_data_len]))
            last_data_len += len(i)

        return rlist

    def _raw_data2bytes(self, data):

        all_data = "".join(data)

        # pad with zero if not a multiple of 8
        if len(all_data) % 8 != 0:
            all_data += "0" * (8 - (len(all_data) % 8))

        # convert string to byte
        return bytes(int(all_data[i:i + 8], 2) for i in range(0, len(all_data), 8))
