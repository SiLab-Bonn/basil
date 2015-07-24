#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.RL.RegisterLayer import RegisterLayer
import numpy as np
import math


class NTCRegister(RegisterLayer):
    """ Register class for NTCRegister
    <sample yaml file>
        registers:
          - name        : CCPD_Vdda
            type        : NTCRegister
            hw_driver   : GPAC
            NTC_type    : TDK_NTCG16H
            arg_names   : [value]
            arg_add     : {'channel': 'ISRC0'}
    """
    def __init__(self, driver, conf):
        RegisterLayer.__init__(self, driver, conf)

        if "NTC_type" not in self._conf:
            self._conf["NTC_type"] = "TDK_NTCG16H"

        if self._conf["NTC_type"] == "TDK_NTCG16H":
            self.R_RATIO = np.array([18.85, 14.429, 11.133, 8.656, 6.779, 5.346, 4.245, 3.393, 2.728, 2.207, 1.796, 1.47, 1.209, 1.0, 0.831, 0.694, 0.583, 0.491, 0.416, 0.354, 0.302, 0.259, 0.223, 0.192, 0.167, 0.145, 0.127, 0.111, 0.0975, 0.086, 0.076, 0.0674, 0.0599, 0.0534])
            self.B_CONST = np.array([3140, 3159, 3176, 3194, 3210, 3226, 3241, 3256, 3270, 3283, 3296, 3308, 3320, 3332, 3343, 3353, 3363, 3373, 3382, 3390, 3399, 3407, 3414, 3422, 3428, 3435, 3441, 3447, 3453, 3458, 3463, 3468, 3473, 3478])
            self.TEMP = np.arange(-40 + 273.15, 130 + 273.15, 5)
            self.R0 = 10000  # R at 25C
        else:
            raise ValueError('%s is not supported.' % self._conf["NTC_type"])

    def get_temperature(self, unit="K"):
        i = self._drv.get_current(self._conf["arg_add"]["channel"], unit="A")
        v = self._drv.get_voltage(self._conf["arg_add"]["channel"], unit="V")
        r_ratio = abs(v / i / self.R0)
        arg = np.argwhere(self.R_RATIO <= r_ratio)

        if len(arg) == 0:
            j = -1
        else:
            j = arg[0]

        k = 1.0 / (math.log(r_ratio / self.R_RATIO[j]) / self.B_CONST[j] + 1 / self.TEMP[j])[0]

        if unit == "C":
            return k - 273.15
        elif unit == "K":
            return k
        else:
            raise ValueError("Unit must be K or C")
