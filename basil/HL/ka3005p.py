#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

"""Driver for the Korad KA3005P programmable DC power supply."""

import logging
from time import sleep

from basil.HL.HardwareLayer import HardwareLayer

logger = logging.getLogger(__name__)


class ka3005p(HardwareLayer):
    """Driver for the Korad KA3005P programmable DC power supply.

    Communicates over a serial (RS-232) interface. Up to 30 V / 5 A.
    """

    def __init__(self, intf, conf):
        super(ka3005p, self).__init__(intf, conf)

    def init(self):
        """Initialize the power supply.

        Sets a safe current limit of 100 mA to protect the DUT.
        """
        super(ka3005p, self).init()
        self.set_current(0.1)

    def set_voltage(self, voltage):
        """Set the output voltage.

        Args:
            voltage: Output voltage in volts. Clipped to 30 V max.
        """
        if voltage > 30:
            voltage = 30
        cmd = "VSET1:%.2f" % round(voltage, 2)
        self._intf.write(cmd)
        sleep(0.05)

    def set_current(self, current):
        """Set the output current limit.

        Args:
            current: Current limit in amps. Clipped to 5 A max.
        """
        if current > 5:
            current = 5
        cmd = "ISET1:%.3f" % round(current, 3)
        self._intf.write(cmd)
        sleep(0.05)

    def enable_output(self):
        """Enable the DC output (OUT1)."""
        self._intf.write("OUT1")
        sleep(0.5)

    def disable_output(self):
        """Disable the DC output (OUT0)."""
        self._intf.write("OUT0")
        sleep(0.1)

    def get_voltage(self):
        """Read back the actual output voltage.

        Returns:
            float: Output voltage in volts.
        """
        self._intf.write("VOUT1?")
        sleep(0.1)
        response = self._intf.read()
        return float(response)

    def get_current(self):
        """Read back the actual output current.

        Returns:
            float: Output current in amps.
        """
        self._intf.write("IOUT1?")
        sleep(0.1)
        response = self._intf.read()
        return float(response)
