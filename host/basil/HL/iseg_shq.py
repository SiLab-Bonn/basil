#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging

from pyiseg import IsegShqCom, status_words

from basil.HL.HardwareLayer import HardwareLayer


class IsegShq(HardwareLayer):
    '''Python interface for ISEG SHQ series

    Example:
    --------
    hw_drivers:
      - name      : SHQ
        type      : iseg_shq
        interface : None
        init      :
            port            : COM1
            trip_current_ma : 0
            trip_current_ua : 0
            ramp_speed      : 2
    registers:
      - name      : HV
        type      : FunctionalRegister
        hw_driver : SHQ
        arg_names : [value]
        arg_add   : {'channel': 1}

    Usage:
    ------
    dut = basil.DUT(config.yaml)
    dut.init()
    dut['HV'].set_voltage(value=10.0)
    '''

    def __init__(self, intf, conf):
        super(IsegShq, self).__init__(intf, conf)

    def init(self):
        self.iseg = IsegShqCom(port_num=self._init['port'])
        self.iseg.init_iseg()
        for ch in self.iseg.channel_list:
            # default values
            if 'trip_current_ma' in self._conf:
                self.iseg.write_i_trip_ma(channel=ch, current=self._init['trip_current_ma'])
            if 'trip_current_ua' in self._conf:
                self.iseg.write_i_trip_ua(channel=ch, current=self._init['trip_current_ua'])
            if 'ramp_speed' in self._conf:
                self.iseg.write_v_ramp(channel=ch, ramp_speed=self._init['ramp_speed'])
            self.trip_reset(channel=ch)

    def set_voltage(self, channel, value=0, unit='V', ramp_speed=None):
        if unit == 'raw':
            raw = value
        elif unit == 'V':
            raw = value
        elif unit == 'mV':
            raw = value * 0.001
        else:
            raise TypeError("Invalid unit type.")
        if ramp_speed:
            self.write_v_ramp(self, channel=channel, ramp_speed=ramp_speed)
        self.iseg.write_v_set(channel, raw)
        logging.info('Ramping voltage...')
        self.iseg.write_start_ramp(channel)
        while True:
            status = self.iseg.read_status_word(channel=channel)
            if status == 'L2H' or status == 'H2L':
                pass
            elif status == 'ON':
                break
            else:
                logging.warning('CH%d: ramping voltage failed with status %s (%s)', channel, status, status_words[status])
                break
        logging.info('Finished ramping voltage')

    def get_voltage(self, channel, unit='V'):
        raw = self.iseg.read_voltage(channel)
        if unit == 'raw':
            return raw
        elif unit == 'V':
            return raw
        elif unit == 'mV':
            return raw * 1000.0
        else:
            raise TypeError("Invalid unit type.")

    def get_current(self, channel, unit='A'):
        raw = self.iseg.read_current(channel)
        if unit == 'raw':
            return raw
        elif unit == 'A':
            return raw
        elif unit == 'mA':
            return raw * 1000.0
        elif unit == 'uA':
            return raw * 1000000.0
        elif unit == 'nA':
            return raw * 1000000000.0
        else:
            raise TypeError("Invalid unit type.")

    def trip_reset(self, channel):
        loop_cnt = 0
        while True:
            status = self.iseg.read_status_word(channel=channel)
            if status == 'ON' or status == 'OFF':
                break
            if loop_cnt >= 3:
                logging.warning('CH%d: status %s (%s) after trip reset', channel, status, status_words[status])
                break
            loop_cnt += 1
