#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging
import numpy as np
import math

from basil.HL.RegisterHardwareLayer import HardwareLayer


class NTCRegister(HardwareLayer):
    """ Register class for NTCRegister
    <sample yaml file>
        hw_drivers:
          - name        : CCPD_Vdda
            type        : NTCRegister
            hw_driver   : GPAC
            NTC_type    : TDK_NTCG16H
            arg_names   : [value]
            arg_add     : {'channel': 'ISRC0'}
    """
    def __init__(self, intf, conf):
        super(NTCRegister, self).__init__(intf, conf)

    def init(self):
        if "NTC_type" not in self._conf:
            self._conf["NTC_type"] = "TDK_NTCG16H"

        logging.debug("Initializing NTC " + self._conf["NTC_type"] + " on channel " + self._conf["arg_add"]["channel"])

        if self._conf["NTC_type"] == "TDK_NTCG16H":
            self.R_RATIO = np.array([18.85, 14.429, 11.133, 8.656, 6.779, 5.346, 4.245, 3.393, 2.728, 2.207, 1.796, 1.47, 1.209, 1.0, 0.831, 0.694, 0.583, 0.491, 0.416, 0.354, 0.302, 0.259, 0.223, 0.192, 0.167, 0.145, 0.127, 0.111, 0.0975, 0.086, 0.076, 0.0674, 0.0599, 0.0534])
            self.B_CONST = np.array([3140, 3159, 3176, 3194, 3210, 3226, 3241, 3256, 3270, 3283, 3296, 3308, 3320, 3332, 3343, 3353, 3363, 3373, 3382, 3390, 3399, 3407, 3414, 3422, 3428, 3435, 3441, 3447, 3453, 3458, 3463, 3468, 3473, 3478])
            self.TEMP = np.arange(-40 + 273.15, 130 + 273.15, 5)
            self.R0 = 10000  # R at 25C
        elif self._conf["NTC_type"] == "130KT1608T":
            self.R_RATIO = np.array([221.9, 125.1, 73.38, 44.72, 28.16, 18.25, 12.14, 10.00, 8.283, 5.781, 4.120, 2.996, 2.214, 1.665, 1.451, 1.271, 0.9832, 0.7707, 0.6114, 0.5469])
            self.B_CONST = np.array([3435.0] * len(self.R_RATIO))
            self.TEMP = np.array([233.145, 243.15, 253.15, 263.15, 273.15, 283.15, 293.15, 298.15, 303.15, 313.15, 323.15, 333.15, 343.15, 353.15, 358.15, 363.15, 373.15, 383.15, 393.15, 398.15])
            self.R0 = 1000  # R at 25C
            self._intf.set_current(self._conf["arg_add"]["channel"], -50, unit="uA")
        else:
            raise ValueError('NTC_type %s is not supported.' % self._conf["NTC_type"])

    def get_temperature(self, unit="K"):
        i = self._intf.get_current(self._conf["arg_add"]["channel"], unit="mA")
        v = self._intf.get_voltage(self._conf["arg_add"]["channel"], unit="mV")

        r_ratio = abs((v / i) / self.R0)
        arg = np.argwhere(self.R_RATIO <= r_ratio)

        if len(arg) == 0:
            j = -1
        else:
            j = arg[0]

        k = 1.0 / (math.log(r_ratio / self.R_RATIO[j]) / self.B_CONST[j] + 1 / self.TEMP[j])[0]
        logging.info("Temperature (C): %f", k - 273.15)

        if unit == "C":
            return k - 273.15
        elif unit == "K":
            return k
        else:
            raise ValueError("Unit must be K or C")
