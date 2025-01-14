#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

"""
This script is used to communicate with the chiller julabo fp50
"""

import logging
import time

from basil.HL.HardwareLayer import HardwareLayer


logger = logging.getLogger(__name__)


class julabo1000F(HardwareLayer):
    ''' Driver for the Julabo Magio MS-1000F chiller.
    A simple protocol via crossed null modem serial port is used with baud rate of 9600.
    All commands were taken from Julabo Magio MS-1000F manual.
    '''

    CMDS = {'get_temp': 'in_sp_00',
            'set_temp': 'out_sp_00',
            'get_curr_temp': 'in_pv_00',
            'get_fluid_level': 'in_pv_16',
            'get_version': 'version',
            'get_status': 'status',
            'start': 'out_mode_05 1',
            'stop': 'out_mode_05 0',
            'set_power': 'out_sp_10',
            'get_power': 'in_sp_10',
            'get_curr_power': 'in_pv_01',
            'get_actuator_source': 'in_mode_11',
            'set_actuator_source': 'out_mode_11'
            }

    def __init__(self, intf, conf):
        super(julabo1000F, self).__init__(intf, conf)
        self.pre_time = time.time()

    def init(self):
        super(julabo1000F, self).init()

    def read(self):
        ret = self._intf.read()
        if len(ret) < 2 or ret[-2:] != "\r\n":
            logger.warning("read() termination error")
        return ret[:-2]

    def write(self, cmd):
        if time.time() - self.pre_time < 1.0:
            time.sleep(1.0)
        self._intf.write(str(cmd))
        self.pre_time = time.time()

    def get_version(self):
        ''' Read identifier
        '''
        self.write(self.CMDS['get_version'])
        ret = self.read()
        return ret

    def start_chiller(self):
        ''' Start chiller
        '''
        self.write(self.CMDS['start'])

    def stop_chiller(self):
        ''' Stop chiller
        '''
        self.write(self.CMDS['stop'])

    def get_status(self):
        ''' Get status
        '''
        self.write(self.CMDS['get_status'])
        ret = self.read()
        logger.debug("status:{:s}".format(ret))
        try:
            tmp = ret.split(" ", 1)
            status = int(tmp[0])
            status_str = tmp[1:]
        except (ValueError, AttributeError):
            logger.warning("get_status() wrong format: {}".format(repr(ret)))
            status = -99
            status_str = ret
        return status, status_str

    def get_set_temp(self):
        '''get the set temperature
        '''
        self.write(self.CMDS['get_temp'])
        ret = self.read()
        return float(ret)

    def set_temp(self, temp):
        '''set the temperature
        '''
        self.write(f"{self.CMDS['set_temp']} {temp}")

    def get_temp(self):
        '''get the current temperature in chiller
        '''
        self.write(self.CMDS['get_curr_temp'])
        ret = self.read()
        return float(ret)

    def set_power(self, variable):
        '''Set the power for heater/cooler via serial interface (positive value for heating, negative value for cooling)
        '''
        self.write(f"{self.CMDS['set_power']} {variable}")

    def get_power(self):
        '''get the current power for heater/cooler
        '''
        self.write(self.CMDS['get_curr_power'])
        ret = self.read()
        return float(ret)

    def get_set_power(self):
        '''get the power for heater/cooler set via serial interface
        '''
        self.write(self.CMDS['get_power'])
        ret = self.read()
        return float(ret)

    def get_mode(self):
        '''get the source for the actuating variable. 0=Thermostat, 1=Serial, 2=Analog (EPROG)
        '''
        self.write(self.CMDS['get_actuator_source'])
        ret = self.read()
        return int(ret)

    def set_mode(self, variable):
        '''Set the source for the actuating variable. 0=Thermostat, 1=Serial, 2=Analog (EPROG)
        '''
        self.write(f"{self.CMDS['set_actuator_source']} {variable}")
