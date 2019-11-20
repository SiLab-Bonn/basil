#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
from basil.HL.RegisterHardwareLayer import HardwareLayer


class Mercury(HardwareLayer):
    '''Driver for the Physiks Instruments Mercury Controller.
    A protocoll via RS 232 serial port is used with 9600/19200/38400/115200 baud rate. The baud rate
    can be set with dip switches, as well as a hardware address to distinguish several
    devices on one line. The write termination is CR and the read ends with '\r', '\n', '\x03'.
    Therefore '\x03' has to be set a read termination in the transport layer! And a read termination
    of 0.1 s should be set!
    Despite the manual telling SCPI compatibility, this is not correct for our devices with our
    firmware.
    '''

    def __init__(self, intf, conf):
        super(Mercury, self).__init__(intf, conf)

    def init(self):
        super(Mercury, self).init()
        self._addresses = []
        for a in range(16):  # Check all possible addresses
            self.write(bytearray.fromhex("01%d" % (a + 30)) + "TB".encode())  # Tell board address
            if self.get_address(a):
                self._addresses.append(a)

    def write(self, value):
        msg = value + '\r'.encode()  # msg has CR at the end
        self._intf.write(msg)

    def read(self):
        answer = self._intf._readline()  # the read termination string has to be set to \x03
        return answer

    def _write_command(self, command, address=None):
        if address:
            self.write(bytearray.fromhex("01%d" % (address + 30)) + command.encode())
        else:
            for a in self._addresses:
                self.write(bytearray.fromhex("01%d" % (a + 30)) + command.encode())

    def get_address(self, address):
        self._write_command("TB", address)
        return self.read()

    def get_position(self, address=None):
        self._write_command("TP", address)
        return int(self.read()[2:-3])

    def get_channel(self, address=None):
        self._write_command("TS", address)
        return self.read()

    def set_position(self, value, address=None):
        self._write_command("MA%d" % value, address)

    def move_relative(self, value, address=None):
        self._write_command("MR%d" % value, address)
