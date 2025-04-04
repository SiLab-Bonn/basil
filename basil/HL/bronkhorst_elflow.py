#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging
import struct
import time

from basil.HL.RegisterHardwareLayer import HardwareLayer


logger = logging.getLogger(__name__)


class Bronkhorst_ELFLOW(HardwareLayer):
    ''' Bronkhorst ELFLOW
    Manual can be found here:
    https://www.bronkhorst.com/getmedia/77a1438f-e547-4a79-95ad-53e81fd38a97/917027-Manual-RS232-interface.pdf
    and here: https://www.bronkhorst.com/getmedia/257147fc-7f5d-4628-9a47-0533cf68ac08/917099-Manual-EL-FLOW-Select.pdf
    '''

    CMDS = {
        'get_measure_flow': ':06800401210120',
        'get_capacity': ':068004014D014D',
        'get_control_mode': ':06800401040104',
        'set_control_mode': ':0580010104',
        'set_setpoint': ':0680010121',
        'get_setpoint': ':06800401210121',
        'get_valve': ':06800472417241',
    }

    def __init__(self, intf, conf):
        self.debug = 0
        self.node = "80"
        super(Bronkhorst_ELFLOW, self).__init__(intf, conf)
        self.pre_time = time.time()

    def init(self):
        super(Bronkhorst_ELFLOW, self).init()

    def write(self, cmd):
        if time.time() - self.pre_time < 1.0:
            time.sleep(1.0)
        self._intf.write(str(cmd))
        self.pre_time = time.time()

    def read(self):
        ret = self._intf.read()
        if len(ret) < 2 or ret[-2:] != "\r\n":
            logger.warning("read() termination error")
        return ret.strip()

    def get_valve_output(self):
        self._intf.write(self.CMDS['get_valve'])
        ret = int(self.read()[11:], 16)
        return ret * 61.7 / 10345949  # converts int in percentage

    def set_setpoint(self, value):
        """value range from 0 - 32000
        """

        if not isinstance(value, int):
            raise ValueError(f"Given value has to be of type integer, is {type(value)}!")

        if value > 32000:
            raise ValueError(f"The valid range is 0 to 32000, the set value is {value}!. Setting setpoint to 32000")
            value = 32000

        hex_val = hex(value)[2:]        # [2:] to remove the 0x from the beginning of the hex number
        command = f"{self.CMDS['set_setpoint']}" + f"{hex_val.zfill(4)}"  # hex should have at least 4 digits
        self._intf.write(command)
        ret = self.read()
        return ret

    def get_setpoint(self):
        self._intf.write(self.CMDS['get_setpoint'])
        ret = self.read()
        answer = int(ret[11:], 16)  # read from the 11th digits to translate what point is set
        return answer

    def set_mode(self, value):
        """ 0 setpoint source RS232
            3 valve close
            4 freeze valve out
            8 valve fully open
            20 valve steering """
        hex_val = hex(value)[2:]        # [2:] to remove the 0x from the beginning of the hex number
        command = f"{self.CMDS['set_control_mode']}" + f"{hex_val.zfill(2)}"  # hex should have at least two digits
        self._intf.write(command)
        ret = self.read()
        return ret

    def get_mode(self):
        self._intf.write(self.CMDS['get_control_mode'])
        ret = self.read()
        answer = int(ret[11:], 16)        # read from the 11th digits to translate what mode is on
        return answer

    def get_flow(self):
        """This should give the flow in l/min
        """
        # first get the max capacity in capacity unit
        # the max capacity depends on e.g the fluid, which can be changed
        # cap_100 represents the maximum flow through the fully open valve measured in the capacity unit of the chosen fluid
        # Capacity unit is a command, which returns the used unit in hex
        self._intf.write(self.CMDS['get_capacity'])
        ret = self.read()
        cap_100 = struct.unpack('!f', bytes.fromhex(ret[11:]))[0]  # read from the 11th digits to translate what the capacity is

        # now measure the flow
        self._intf.write(self.CMDS['get_measure_flow'])
        ret1 = self.read()
        answer = int(ret1[11:], 16)  # convert reply from hex to integer

        val = answer / 32000 * cap_100
        return val
