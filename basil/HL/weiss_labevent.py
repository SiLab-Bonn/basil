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
        Driver for Weiss LabEvent T/210/70/5 climate chamber.
    '''

    RETURN_CODES = {
        1: "Command is accepted and executed.",
        -5: "Command number transmitted is unidentified!",
        -6: "Too few or incorrect parameters entered!",
        -8: "Data could not be read!",
    }

    def __init__(self, intf, conf):
        super(weissLabEvent, self).__init__(intf, conf)

    def init(self):
        super(weissLabEvent, self).init()

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

    def get_temperature(self):
        return float(self.query(b'11004\xb61\xb61')[1])

    def start_manual_mode(self):
        if not self.query(b'14001\xb61\xb61\xb61')[0] == 1:
            logging.error('Could not start manual mode!')

    def set_temperature(self, target):
        self.query(b'11001\xb61\xb61\xb6' + str(target).encode('ascii'))
