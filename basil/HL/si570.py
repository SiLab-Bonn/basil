#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging

from basil.HL.HardwareLayer import HardwareLayer
from basil.RL.StdRegister import StdRegister


logger = logging.getLogger(__name__)


class si570(HardwareLayer):
    def __init__(self, intf, conf):
        si570_reg = {
            "name": "Si570",
            "type": "StdRegister",
            "driver": "none",
            "size": 48,
            "fields": [
                {"name": "RFREQ", "size": 38, "offset": 37},
                {"name": "N1", "size": 7, "offset": 44},
                {"name": "HS_DIV", "size": 3, "offset": 47},
            ],
        }
        super(si570, self).__init__(intf, conf)
        self._base_addr = conf["base_addr"]
        self._reg = StdRegister(driver=None, conf=si570_reg)
        self._freq = conf["init"]

    def init(self):
        super(si570, self).init()
        self.frequency_change(float(self._init["frequency"]))

    def reset(self):
        self._intf.write(0xBA, [135])
        RECALL = self._intf.read(0xBA, 1)
        self._intf.write(0xBA, [135] + [RECALL[0] | 0b1])

    def frequency_change(self, freq):  # freq in MHz
        f0 = 156.25

        self.reset()

        HS_DIV, N1, RFREQ = self.read_registers()

        fxtal = float(f0 * HS_DIV * N1) / (float(RFREQ) / 2 ** 28)

        new_fdco = freq * HS_DIV * N1

        if 4850.0 > new_fdco or new_fdco > 5670.0:
            logger.debug("Si570: large frequency change, recalculating HSDIV, N1")
            found_new_values = False
            HS_DIV_avaiable = [11, 9, 7, 6, 5, 4]
            N1_avaiable = list(range(2, 129, 2))
            N1_avaiable.insert(0, 1)
            for hs in HS_DIV_avaiable:
                for n in N1_avaiable:
                    fdco = freq * 1e6 * hs * n
                    if (fdco >= 4.85e9) & (
                        fdco <= 5.67e9
                    ):  # fdco range defined by manufacturer
                        HS_DIV = hs
                        N1 = n
                        found_new_values = True
                if found_new_values:
                    break
            else:  # if correct HS_DIV and N1 were not found
                raise ValueError("The Si570 reference frequency is too low or to high")
            new_fdco = freq * HS_DIV * N1

        new_RFREQ_freq = new_fdco / fxtal
        new_RFREQ = int(new_RFREQ_freq * 2 ** 28)

        self.modify_register(HS_DIV, N1, new_RFREQ)
        logger.info(
            "Changed Si570 reference frequency to %s MHz", new_fdco / (HS_DIV * N1)
        )

    def modify_register(self, HS_DIV, N1, RFREQ):
        # Preparation of the array that needs to be send
        self._reg["HS_DIV"] = HS_DIV - 4
        self._reg["N1"] = N1 - 1
        self._reg["RFREQ"] = RFREQ

        self._intf.write(0xBA, [137])
        dco_freeze = self._intf.read(0xBA, 1)

        self._intf.write(0xBA, [135])
        new_freq_flag = self._intf.read(0xBA, 1)

        # Freeze the DCO
        self._intf.write(0xBA, [137] + [dco_freeze[0] | 0b10000])
        # Write the new frequency configuration
        self._intf.write(0xBA, [7] + self._reg.tobytes().tolist())
        # Unfreeze the DCO
        self._intf.write(0xBA, [137] + [dco_freeze[0] & 0b01111])
        # Assert the NewFreq bit
        self._intf.write(0xBA, [135] + [new_freq_flag[0] | 0b01000000])

    def read_registers(self):
        self._intf.write(0xBA, [7])
        reg_val = self._intf.read(0xBA, 6)

        HS_DIV = (reg_val[0] & 0xE0) >> 5
        HS_DIV += 4

        N1 = ((reg_val[0] & 0x1F) << 2) | ((reg_val[1] & 0xC0) >> 6)
        N1 += 1

        RFREQ = (
            ((reg_val[1] & 0x3F) << 32)
            | reg_val[2] << 24
            | reg_val[3] << 16
            | reg_val[4] << 8
            | reg_val[5]
        )

        return HS_DIV, N1, RFREQ
