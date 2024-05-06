#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
from basil.HL.RegisterHardwareLayer import HardwareLayer

import time


class Mercury(HardwareLayer):
    '''Driver for the Physiks Instruments Mercury Controller.
    A protocoll via RS 232 serial port is used with 9600/19200/38400/115200 baud rate. The baud rate
    can be set with dip switches, as well as a hardware address to distinguish several
    devices on one line. The write termination is CR and the read ends with '\r', '\n', '\x03'.
    Therefore '\x03' has to be set a read termination in the transport layer! And a read termination
    of 0.1 s should be set!
    Despite the manual telling SCPI compatibility, this is not correct for our devices with our
    firmware. The manual explaining every "native" command: https://twiki.cern.ch/twiki/pub/ILCBDSColl/Phase2Preparations/MercuryNativeCommands_MS176E101.pdf
    The overall manual: https://www.le.infn.it/~chiodini/allow_listing/pi/Manuals/C-863_Benutzerhandbuch_Kurzversion_MS205Dqu200.pdf'''

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

    def motor_on(self, address=None):
        self._write_command("MN", address)

    def motor_off(self, address=None):
        self._write_command("MF", address)

    def LL(self, address=None):  # logic active low
        self._write_command("LL", address)

    def set_home(self, address=None):  # Defines the current position as 0
        self._write_command("DH", address)

    def go_home(self, address=None):  # Moves motor to zero position
        self._write_command("GH", address)

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

    def abort(self, address=None):
        self._write_command("AB", address)

    def find_edge(self, n, address=None):
        self._write_command("FE%d" % n, address)

    def wait_pos(self, target, precision, address):   # waits/prints position until desired precision is reached
        print("Moving motore from:", self.get_position(address), "to" ,target)  # absolute target
        done = False
        while done is False:
            pos=self.get_position(address)
            print("motor at", pos, "moving to", target)
            if abs(pos-target) <= precision:
                done = True
            else:
                time.sleep(0.5)
        return pos
        
    def wait_FE(self, address):  # waits until motor stops moving
        print(self.get_position(address),"Moving")
        done = False
        while done is False:
            a=self.get_position(address)
            time.sleep(1)
            b=self.get_position(address)
            if a == b:
                done=True
            else:
                time.sleep(0.5)
        return b