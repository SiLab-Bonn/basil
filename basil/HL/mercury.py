#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
from basil.HL.RegisterHardwareLayer import HardwareLayer
import logging
import time

logger = logging.getLogger(__name__)
# logger.setLevel(logging.DEBUG)


class Mercury(HardwareLayer):
    '''Driver for the Physiks Instruments Mercury Controller.
    A protocoll via RS 232 serial port is used with 9600/19200/38400/115200 baud rate. The baud rate
    can be set with dip switches, as well as a hardware address to distinguish several
    devices on one line. Keep in mind that the address that is set via the DIP switches corresponds to (board number + 1). Check p.45 of the overall manual below on how to properly set the address of each controller and what the corresponding board number is. The write termination is CR and the read ends with '\r', '\n', '\x03'.
    Therefore '\x03' has to be set a read termination in the transport layer! And a read termination
    of 0.1 s should be set!
    Despite the manual telling SCPI compatibility, this is not correct for our devices with our
    firmware. The manual explaining every "native" command: https://twiki.cern.ch/twiki/pub/ILCBDSColl/Phase2Preparations/MercuryNativeCommands_MS176E101.pdf
    The overall manual: https://www.le.infn.it/~chiodini/allow_listing/pi/Manuals/C-863_Benutzerhandbuch_Kurzversion_MS205Dqu200.pdf'''

    def __init__(self, intf, conf):
        super(Mercury, self).__init__(intf, conf)

    def init(self):
        super(Mercury, self).init()
        self._board_numbers = []
        for b in range(16):  # Check all possible board numbers
            self.write(bytearray.fromhex("01%d" % (b + 30)) + "TB".encode())  # Tell board number
            if self.get_board_number(b):
                self._board_numbers.append(b)

    def write(self, value):
        msg = value + '\r'.encode()  # msg has CR at the end
        self._intf.write(msg)

    def read(self):
        answer = self._intf._readline()  # the read termination string has to be set to \x03
        return answer

    def _write_command(self, command, board_number=None):
        if board_number is not None:
            self.write(bytearray.fromhex("01%d" % (board_number + 30)) + command.encode())
        else:
            for b in self._board_numbers:
                self.write(bytearray.fromhex("01%d" % (b + 30)) + command.encode())

    def get_board_number(self, board_number):
        self._write_command("TB", board_number)
        return self.read()

    def motor_on(self, board_number=None):
        self._write_command("MN", board_number)

    def motor_off(self, board_number=None):
        self._write_command("MF", board_number)

    def LL(self, board_number=None):  # logic active low
        self._write_command("LL", board_number)

    def set_home(self, board_number=None):  # Defines the current position as 0
        self._write_command("DH", board_number)

    def go_home(self, board_number=None):  # Moves motor to zero position
        self._write_command("GH", board_number)

    def get_position(self, board_number=None):
        self._write_command("TP", board_number)
        return int(self.read()[2:-3])

    def get_channel(self, board_number=None):
        self._write_command("TS", board_number)
        return self.read()

    def set_position(self, value, precision=100, board_number=None, wait=False):
        self._write_command("MA%d" % value, board_number)
        if wait is True:
            pos = self._wait(board_number)
            if abs(pos - value) <= precision:
                logger.debug("At position {pos}, Target at {target}".format(pos=pos, target=value))
            else:
                logger.warning("Target not reached! Target: {target}, actual position: {pos}, precision: {pre}".format(target=value, pos=pos, pre=precision))

    def move_relative(self, value, precision=100, board_number=None, wait=False):
        target = self.get_position(board_number) + value
        self._write_command("MR%d" % value, board_number)
        if wait is True:
            pos = self._wait(board_number)
            if abs(pos - target) <= precision:
                logger.debug("At position {pos}, Target at {target}".format(pos=pos, target=target))
            else:
                logger.warning("Target not reached! Target: {target}, actual position: {pos}, precision: {pre}".format(target=target, pos=pos, pre=precision))

    def abort(self, board_number=None):
        self._write_command("AB", board_number)

    def find_edge(self, n, board_number=None):
        self._write_command("FE%d" % n, board_number)
        pos = self._wait(board_number)
        logger.debug("Edge found at position: {pos}".format(pos=pos))

    def _wait(self, board_number=None):  # waits until motor stops moving
        logger.debug("Moving! Starting position: {pos}".format(pos=self.get_position(board_number)))
        done = False
        while done is False:
            time.sleep(0.1)
            a = self.get_position(board_number)
            time.sleep(1)
            b = self.get_position(board_number)
            if a == b:
                done = True
            else:
                time.sleep(0.5)
        return b
