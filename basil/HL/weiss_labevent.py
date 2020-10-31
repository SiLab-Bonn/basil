#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging

from basil.HL.RegisterHardwareLayer import HardwareLayer


class weissLabEvent(HardwareLayer):
    '''
        Driver for Weiss LabEvent T/210/70/5 climate chamber. Commands extracted from
        https://github.com/IzaakWN/ClimateChamberMonitor/blob/master/chamber_commands.py
    '''

    RETURN_CODES = {
        1: "Command is accepted and executed.",
        -5: "Command number transmitted is unidentified!",
        -6: "Too few or incorrect parameters entered!",
        -8: "Data could not be read!",
    }

    STATUS_CODES = {
        1: 'Test not running (Idle)',
        3: 'Test running',
        4: 'Warnings present',
        8: 'Alarms present'
    }

    def __init__(self, intf, conf):
        super(weissLabEvent, self).__init__(intf, conf)

    def init(self):
        super(weissLabEvent, self).init()

        info = self.get_info()
        if info != 'LabEvent T/210/70/5':
            logging.error('Not the expected climatechamber! Expected {0}, got {1}'.format('LabEvent T/210/70/5', info))

    def query(self, cmd):
        ret = self._intf.query(cmd, buffer_size=512)[0]
        dat = [d.decode('ascii') for d in ret.split(b'\xb6')]

        code = int(dat[0])
        try:
            data = dat[1]
        except IndexError:
            data = None
        logging.debug('Return code {0}: {1}'.format(code, self.RETURN_CODES[code]))
        if code != 1:
            logging.error('Return code {0}: {1}'.format(code, self.RETURN_CODES[code]))

        return code, data

    def _get_feature_status(self, id):
        feature_name = self.query(b'14010\xb61\xb61\xb6' + str(id).encode('ascii'))[1]
        feature_status = self.query(b'14003\xb61\xb61\xb6' + str(id).encode('ascii'))[1]
        logging.debug('Feature {0} has status {1}'.format(feature_name, feature_status))
        return bool(int(feature_status))

    def _set_feature_status(self, id, value):
        return self.query(b'14001\xb61\xb61\xb6' + str(id).encode('ascii') + b'\xb6' + str(int(value)).encode('ascii'))

    def get_info(self):
        return self.query(b'99997\xb61\xb61')[1]

    def get_status(self):
        status_code = int(self.query(b'10012\xb61\xb61')[1])
        status = '{0}: {1}'.format(status_code, self.STATUS_CODES[status_code])
        return status

    def start_manual_mode(self):
        if not self.query(b'14001\xb61\xb61\xb61')[0] == 1:
            logging.error('Could not start manual mode!')

    def stop_manual_mode(self):
        if not self.query(b'14001\xb61\xb61\xb60')[0] == 1:
            logging.error('Could not stop manual mode!')

    def get_temperature(self):
        return float(self.query(b'11004\xb61\xb61')[1])

    def set_temperature(self, target):
        if not self.query(b'11001\xb61\xb61\xb6' + str(target).encode('ascii'))[0] == 1:
            logging.error('Could not set temperature!')

    def get_temperature_setpoint(self):
        return float(self.query(b'11002\xb61\xb61')[1])

    def get_air_dryer(self):
        return self._get_feature_status(8)

    def set_air_dryer(self, value):
        if not self._set_feature_status(8, value)[0] == 1:
            logging.error('Could not set air dryer!')
