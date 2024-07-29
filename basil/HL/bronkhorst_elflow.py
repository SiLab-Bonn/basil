#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging
import time
import struct

from basil.HL.RegisterHardwareLayer import HardwareLayer


logger = logging.getLogger(__name__)


class Bronkhorst_ELFLOW(HardwareLayer):
    ''' Bronkhorst ELFLOW
    Manual can be found here https://www.bronkhorst.com/getmedia/77a1438f-e547-4a79-95ad-53e81fd38a97/917027-Manual-RS232-interface.pdf
    '''

    CMDS = {
        'get_valve_opening': ':06800472417241\r\n',  # These bytes will make the flow meter send back the opening
        'measure_flow': ':06800401210120\r\n',  # These bytes will measure the gas flow through the valve in %
        'read_max_capacity': ':068004014D014D\r\n',  # These bytes will read the maximum capacity of the current flow
        'read_control_mode': ':06800401040104',  # these bytes will give what control mode is on
        'set_control_mode': ':0580010104',
    }


    def __init__(self, intf, conf):
        self.debug = 0
        self.node = "80"
        super(Bronkhorst_ELFLOW, self).__init__(intf, conf)

    def init(self):
        super(Bronkhorst_ELFLOW, self).init()

    def write(self, cmd):
        cmd_s = ""
        for c in cmd:
            cmd_s = cmd_s + "%02X" % c
        cmd_s = ":%02X%s%s" % (len(cmd) + 1, self.node, cmd_s)
        if self.debug != 0:
            logger.debug("ELFLOW.write() %s" % str(cmd_s))
        self._intf.write(cmd_s)

    def read(self):
        ret_s = self._intf.read()
        if self.debug != 0:
            logger.debug("ELFLOW.read() %s" % str(ret_s))
        if len(ret_s) < 5 or ret_s[0] != ":" or ret_s[3:5] != self.node:
            logger.debug("ELFLOW.read() format error ret=%s" % str(ret_s))
            return []
        ret_len = int(ret_s[1:3])
        if ret_len * 2 != len(ret_s[3:-2]):
            logger.debug("ELFLOW.read() data lenth error ret=%s" % str(ret_s))
            return []
        ret = []
        for i in range(ret_len - 1):
            ret.append(int(ret_s[5 + 2 * i:5 + 2 * (i + 1)], 16))
        return ret


    def get_opening(self):
        self._intf.write(self.CMDS['get_valve_opening'])

    def get_flow(self):
        self._intf.write(self.CMDS['measure_flow'])
        self._intf.readline().decode()
        reading = self._intf.readline().decode()[11:-2]
        print(reading)
        int_flow = int(reading, 16)
        print(int_flow)



    def get_max_cap(self):
        self._intf.write(self.CMDS['read_max_capacity'])

    def set_setpoint(self, value):

        if not isinstance(value, int):
            raise ValueError(f"Given value has to be of type integer, is {type(value)}!")

        cmd = [1, 1, 0x21, (value >> 8) & 0xFF, value & 0xFF]
        self.write(cmd)
        ret = self.read()
        if len(ret) != 3:
            logger.debug("ELFLOW.set_setpoint() data lenth error ret=%s" % str(ret))
            return -1
        elif ret[0] == 0 and ret[1] == 0 and ret[2] == 5:
            return 0
        else:
            logger.debug("ELFLOW.set_setpoint() ret error ret=%s" % str(ret))
            return -1

    def get_setpoint(self):
        cmd = [4, 1, 0x21, 1, 0x21]
        # 06800401210121\r\n
        self.write(cmd)
        ret = self.read()
        if len(ret) != 5:
            logger.debug("ELFLOW.set_setpoint() data lenth error ret=%s" % str(ret))
            return -1
        elif ret[0] == 2 and ret[1] == cmd[1] and ret[2] == cmd[2]:
            return ((ret[3] << 8) & 0xFF00) | (ret[4] & 0xFF)
        else:
            logger.debug("ELFLOW.set_setpoint() ret error ret=%s" % str(ret))
            return -1

    def set_control_mode(self, value):
        """ 0 setpoint source RS232
            3 valve close
            4 freeze valuve out
            8 valve fully open
            20 valve steering (valve=setpoint)"""
        cmd = [1, 1, 4, value & 0xFF]
        self.write(cmd)
        ret = self.read()
        if len(ret) != 3:
            logger.debug("ELFLOW.set_setpoint() data lenth error ret=%s" % str(ret))
            return -1
        elif ret[0] == 0 and ret[1] == 0 and ret[2] == 4:
            return 0
        else:
            logger.debug("ELFLOW.set_setpoint() ret error ret=%s" % str(ret))
            return -1

    def get_control_mode(self):
        cmd = [4, 1, 1, 1, 4]
        self.write(cmd)
        ret = self.read()
        if len(ret) != 4:
            logger.debug("ELFLOW.set_setpoint() data lenth error ret=%s" % str(ret))
            return -1
        elif ret[0] == 2 and ret[1] == cmd[1] and ret[2] == cmd[2]:
            return ret[3]
        else:
            logger.debug("ELFLOW.set_setpoint() ret error ret=%s" % str(ret))
            return -1

    def set_valve_output(self, value):
        cmd = [1, 114, 0x41, (value >> 24) & 0xFF, (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF]
        self.write(cmd)
        ret = self.read()
        if len(ret) != 3:
            logger.debug("ELFLOW.set_valve_output() data lenth error ret=%s" % str(ret))
            return -1
        elif ret[0] == 0 and ret[1] == 0 and ret[2] == 7:
            return 0
        else:
            logger.debug("ELFLOW.set_valve_output() ret error ret=%s" % str(ret))
            return -1

    def get_valve_output(self):
        cmd = [4, 114, 0x41, 114, 0x41]
        self.write(cmd)
        ret = self.read()
        if len(ret) != 7:
            logger.debug("ELFLOW.set_setpoint() data lenth error ret=%s" % str(ret))
            return -1
        elif ret[0] == 2 and ret[1] == cmd[1] and ret[2] == cmd[2]:
            return ((ret[3] << 24) & 0xFF000000) | ((ret[4] << 16) & 0xFF0000) | ((ret[5] << 8) & 0xFF00) | (ret[6] & 0xFF)
        else:
            logger.debug("ELFLOW.get_valve_output() ret error ret=%s" % str(ret))
            return -1

    def set_controller_speed(self, value):
        value = struct.unpack('<I', struct.pack('<f', value))[0]
        cmd = [1, 114, 0x40 + 30, (value >> 24) & 0xFF, (value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF]
        self.write(cmd)
        ret = self.read()
        if len(ret) != 3:
            logger.debug("ELFLOW.set_controller_speed() data lenth error ret=%s" % str(ret))
            return -1
        elif ret[0] == 0 and ret[1] == 0 and ret[2] == 7:
            return 0
        else:
            logger.debug("ELFLOW.set_controller_speed() ret error ret=%s" % str(ret))
            return -1

    def get_controller_speed(self):
        cmd = [4, 114, 0x41, 114, 0x40 + 30]
        self.write(cmd)
        ret = self.read()
        if len(ret) != 7:
            logger.debug("ELFLOW.set_setpoint() data lenth error ret=%s" % str(ret))
            return -1
        elif ret[0] == 2 and ret[1] == cmd[1] and ret[2] == cmd[2]:
            return struct.unpack('!f', chr(ret[3]) + chr(ret[4]) + chr(ret[5]) + chr(ret[6]))[0]
        else:
            logger.debug("ELFLOW.get_valve_output() ret error ret=%s" % str(ret))
            return -1

    def get_measure(self):
        cmd = [4, 1, 0x21, 1, 0x20]
        # 06800401210120\r\n
        self.write(cmd)
        ret = self.read()
        if len(ret) != 5:
            logger.debug("ELFLOW.set_setpoint() data lenth error ret=%s" % str(ret))
            return -1
        elif ret[0] == 2 and ret[1] == cmd[1] and ret[2] == cmd[2]:
            return ((ret[3] << 8) & 0xFF00) | (ret[4] & 0xFF)
        else:
            logger.debug("ELFLOW.get_valve_output() ret error ret=%s" % str(ret))
            return -1

    def get_max_capacity(self):
        cmd = [4, 1, 0x4D, 1, 0x4D]
        # 068004014D014D\r\n
        self.write(cmd)
        ret = self.read()
        print(ret)
