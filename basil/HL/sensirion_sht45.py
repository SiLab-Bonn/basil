# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import logging
import struct

from basil.HL.SensirionBridgeDevice import SensirionBridgeI2CDevice

logger = logging.getLogger(__name__)
logging.getLogger("sensirion_shdlc_driver.connection").setLevel(logging.ERROR)


class sensirionSHT45(SensirionBridgeI2CDevice):
    """
    Driver for the Sensirion SHT45 temperature and humidity sensor (SHT4x family).

    Unlike the SHT3x/SHT85, the SHT4x only supports single-shot measurements
    (no periodic/ART mode and no status register).

    Measurements can be performed in three repeatability modes:
    low (default) (0.2°C, 0.21%RH), medium (0.12°C, 0.21%RH), high (0.1°C, 0.08%RH)
    with respective drawbacks in readout speed and power consumption.

    The dew point can be estimated using humidity and temperature.

    The sensor has an integrated heater (20/110/200 mW) that can be activated
    for 0.1s or 1s. A heater command always performs a high-repeatability
    measurement right before the heater is switched off again and returns
    that reading; there is no separate heater on/off command.
    """

    def __init__(self, intf, conf):
        super(sensirionSHT45, self).__init__(intf, conf)

    def init(self):
        super(sensirionSHT45, self).init(0x44)

        try:
            import crcmod
            self.crc_func = crcmod.mkCrcFun(0x131, initCrc=0xFF, rev=False, xorOut=0x00)
        except ImportError:
            logger.warning("You have to install the package 'crcmod'! Transmission errors will not be caught.")
            self.crc_func = lambda x: 0

        self.repeatability = self._init.get("repeatability", "low")

    def _read(self, command, read_n_words=0, timeout_us=20e3, n_tries=10):
        for _ in range(n_tries):
            rx_data = super(sensirionSHT45, self)._read(command, read_n_words * 3, timeout_us)
            data = [0] * read_n_words
            for i in range(read_n_words):
                if self.crc_func(rx_data[i * 3: (i + 1) * 3]):
                    break
                else:
                    data[i] = struct.unpack(">H", rx_data[i * 3: i * 3 + 2])[0]
            else:
                return data
            continue
        raise Exception("Checksum repeatedly ({0}x) wrong".format(n_tries), rx_data)

    def _write(self, command):
        super(sensirionSHT45, self)._write(command)

    def _perform_measurement(self, read_n_words=2):
        # command byte, max measurement duration in us (see datasheet Table 4)
        params = {
            "low": ([0xE0], 1700),
            "medium": ([0xF6], 4500),
            "high": ([0xFD], 8200),
        }[self.repeatability]
        return self._read(params[0], read_n_words=read_n_words, timeout_us=params[1])

    def get_temperature(self):
        data = self._perform_measurement(read_n_words=2)
        return self._to_temperature(data)

    def get_humidity(self):
        data = self._perform_measurement(read_n_words=2)
        return self._to_humidity(data)

    def get_temperature_and_humidity(self):
        data = self._perform_measurement(read_n_words=2)
        return self._to_temperature(data), self._to_humidity(data)

    def get_dew_point(self):
        T, RH = self.get_temperature_and_humidity()
        return self.to_dew_point(T, RH)

    def measure_with_heater(self, power="high", duration="short"):
        """
        Fire the integrated heater and return the T/RH reading taken with
        high repeatability just before the heater switches off again.

        power: "low" (20mW), "medium" (110mW) or "high" (200mW)
        duration: "short" (0.1s) or "long" (1s)

        Note: the heater is rated for a maximum on-time of 1s and should not
        be fired back-to-back without a cool-down; see the datasheet.
        """
        cmd, timeout_us = {
            "high": {"long": ([0x39], 1.1e6), "short": ([0x32], 0.11e6)},
            "medium": {"long": ([0x2F], 1.1e6), "short": ([0x24], 0.11e6)},
            "low": {"long": ([0x1E], 1.1e6), "short": ([0x15], 0.11e6)},
        }[power][duration]

        data = self._read(cmd, read_n_words=2, timeout_us=timeout_us)
        return self._to_temperature(data), self._to_humidity(data)

    def get_serial_number(self):
        data = self._read([0x89], read_n_words=2, timeout_us=1e3)
        return (data[0] << 16) | data[1]

    # This soft-reset re-initializes all registers.
    # A general call reset (not implemented here) also resets the sensor.
    def reset_sensor(self):
        self._write([0x94])

    def _to_temperature(self, data):
        return -45 + 175 * (float(data[0]) / (2 ** 16 - 1))

    def _to_humidity(self, data):
        RH = -6 + 125 * (float(data[1]) / (2 ** 16 - 1))
        return min(max(RH, 0), 100)

    def to_dew_point(self, T, RH):
        """returns the dew point using an approximation
        approximation specified by Sensirion:
        http://irtfweb.ifa.hawaii.edu/~tcs3/tcs3/Misc/Dewpoint_Calculation_Humidity_Sensor_E.pdf
        """
        import numpy as np
        if RH == 0:
            RH = self._to_humidity((0, 1))  # lowest non-zero rel. humidity
        H = (np.log10(RH) - 2) / 0.4343 + (17.62 * T) / (243.12 + T)
        Dp = 243.12 * H / (17.62 - H)
        return Dp