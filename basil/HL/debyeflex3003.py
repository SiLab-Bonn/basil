#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging

from basil.HL.RegisterHardwareLayer import HardwareLayer


logger = logging.getLogger(__name__)


class debyeflex3003(HardwareLayer):

    """Driver for the ISO-DEBYEFLEX 3003 X-Ray tube.
    A simple protocol via RS 232 serial port is used with 9600 baud rate.
    """

    def __init__(self, intf, conf):
        super(debyeflex3003, self).__init__(intf, conf)

    def init(self):
        super(debyeflex3003, self).init()

    def read(self):
        ret = self._intf.read()
        if ret[-1:] != "\r":
            logger.warning("debyeflex3003.read() termination error")
        return ret[1:-1]

    def write(self, cmd):
        self._intf.write(str(cmd))

    def get_nominal_current(self):
        """Read nominal current in mA.
        """
        self.write("CN")
        curr = self.read()
        return int(curr) / 1000.

    def get_actual_current(self):
        """Read actual current in mA.
        """
        self.write("CA")
        curr = self.read()
        return int(curr) / 1000.

    def set_current(self, curr):
        """Set current in mA
        """
        if curr > 80 or curr < 0:
            raise ValueError("Illegal value for tube current (0 - 80 mA)")
        else:
            self.write("SC:{:02d}".format(int(curr)))
            logger.info("Set tube current to {:.1f} mA".format(self.get_nominal_current()))

    def get_nominal_voltage(self):
        """Read nominal voltage in kV.
        """
        self.write("VN")
        vol = self.read()
        return int(vol) / 1000.

    def get_actual_voltage(self):
        """Read actual voltage in kV.
        """
        self.write("VA")
        vol = self.read()
        return int(vol) / 1000.

    def set_voltage(self, vol):
        """Set high voltage in kV
        """
        if vol > 60 or vol < 0:
            raise ValueError("Illegal value for tube voltage (0 - 60 kV)")
        else:
            self.write("SV:{:02d}".format(vol))
            logger.info("Set tube voltage to {:.1f} kV".format(self.get_nominal_voltage()))

    def set_highvoltage_on(self):
        self.write("HV:1")

    def set_highvoltage_off(self):
        self.write("HV:0")

    def open_shutter(self, shutter=1):
        """Open the shutter with given number. Only shuttter=1 supported from hardware currently
        """
        if not isinstance(shutter, int):
            raise TypeError("Invalid type for shutter number")
        elif shutter > 4 or shutter < 1:
            raise ValueError("Invalid value for shutter number")
        else:
            self.write("OS:{:1d}".format(shutter))
            logger.info("Opened shutter number {:1d}".format(shutter))

    def close_shutter(self, shutter=1):
        """Close the shutter with given number. Only shuttter=1 supported from hardware currently
        """
        if not isinstance(shutter, int):
            raise TypeError("Invalid type for shutter number")
        elif shutter > 4 or shutter < 1:
            raise ValueError("Invalid value for shutter number")
        else:
            self.write("CS:{:1d}".format(shutter))
            logger.info("Closed shutter number {:1d}".format(shutter))

    def activate_timer(self, shutter=1):
        """Activate the timer for a given shutter number
        """
        if not isinstance(shutter, int):
            raise TypeError("Invalid type for shutter number")
        elif shutter > 4 or shutter < 1:
            raise ValueError("Invalid value for shutter number")
        else:
            self.write("TS:{:1d}".format(shutter))
            logger.info("Started timer number {:1d}".format(shutter))

    def deactivate_timer(self, shutter=1):
        """Deactivate the timer for a given shutter number
        """
        if not isinstance(shutter, int):
            raise TypeError("Invalid type for shutter number")
        elif shutter > 4 or shutter < 1:
            raise ValueError("Invalid value for shutter number")
        else:
            self.write("TE:{:1d}".format(shutter))
            logger.info("Stopped timer number {:1d}".format(shutter))

    def set_timer(self, timer=1, dur=3600):
        """Set the timer with the given number (corresponds to shutter number) to the given duration (in s)
        """
        if not isinstance(timer, int):
            raise TypeError("Invalid type for timer number")
        elif not isinstance(dur, int):
            raise TypeError("Illegal type for duration")
        elif timer > 4 or timer < 1:
            raise ValueError("Invalid value for timer number")
        else:
            h = dur // 3600
            m = (dur % 3600) // 60
            s = (dur % 3600) % 60
            self.write("TP:{:1d},{:02d},{:02d},{:02d}".format(timer, h, m, s))
            time = self.get_nominal_time(timer)
            logger.info("Set timer number {:1d} to {:02d}:{:02d}:{:02d} (HH:MM:SS)".format(
                timer, time // 3600, (time % 3600) // 60, (time % 3600) % 60)
            )

    def get_actual_time(self, timer=1):
        """Get the actual time of the given timer in s
        """
        if not isinstance(timer, int):
            raise TypeError("Invalid type for timer number")
        elif timer > 4 or timer < 1:
            raise ValueError("Invalid value for timer number (1, 2, 3, 4)")
        else:
            self.write("TA:{:1d}".format(timer))
            time = self.read()
            return int(time)

    def get_nominal_time(self, timer=1):
        """Get the nominal time of the given timer in s
        """
        if not isinstance(timer, int):
            raise TypeError("Invalid type for timer number")
        elif timer > 4 or timer < 1:
            raise ValueError("Invalid value for timer number (1, 2, 3, 4)")
        else:
            self.write("TN:{:1d}".format(timer))
            time = self.read()
            return int(time)

    def lock_keyboard(self):
        """Locks the hardware keyboard on the device. Only STOP key still works.
        """
        self.write("KB:0")

    def unlock_keyboard(self):
        self.write("KB:1")

    def get_status(self, status_word):
        """ Get a pre-selected range of status parameters
        """
        self.write("SR:{:02d}".format(status_word))
        response = self.read()
        status = bin(int(response[7:10]))[2:].zfill(8)  # Convert response to 8 char long string of binary values
        logger.info("Status word {:02d}: {:8s}".format(status_word, status))
        return status
