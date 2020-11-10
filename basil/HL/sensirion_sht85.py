# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import numpy as np
import logging

from basil.HL.SensirionBridgeDevice import SensirionBridgeI2CDevice

logger = logging.getLogger(__name__)


class sensirionSHT85(SensirionBridgeI2CDevice):
    '''
    Driver for the Sensirion SHT85 temperature and humidity sensor.
    Measurements can be performed in three repeatability modes:
    low (0.15°C 0.21%RH) (default), medium (0.08°C 0.15%RH), high (0.04°C 0.08%RH)
    with respective drawbacks in readout speed and power cosumption.
    The dew point can be estimated using humidity and temperature.
    Readout may also be performed asynchronously:
    The sensor can measure periodicly with 0.5, 1, 2, 4 or 10 measurements per second.
    A non-blocking call to the asynchrounous read function may return None if no data is available.
    In ART mode the humidity response is accelerated.
    A heater may be turned on for debugging purposes.
    '''

    def __init__(self, intf, conf):
        super(sensirionSHT85, self).__init__(intf, conf)

    def init(self):
        super(sensirionSHT85, self).init(0x44)

        try:
            import crcmod
            self.crc_func = crcmod.mkCrcFun(0x131, initCrc=0xFF, rev=False, xorOut=0x00)
        except ImportError:
            logger.warning("You have to install the package 'crcmod'! Transmission errors will not be caught.")
            self.crc_func = lambda x: 0

        self.repeatability = self._init.get('repeatability', 'low')

    def _read(self, command, read_n_words=0, timeout_us=20e3, n_tries=10):
        for _ in range(n_tries):
            rx_data = super(sensirionSHT85, self)._read(command, read_n_words * 3, timeout_us)
            data = [0] * read_n_words
            for i in range(read_n_words):
                if self.crc_func(rx_data[i * 3:(i + 1) * 3]):
                    break
                else:
                    data[i] = int.from_bytes(rx_data[i * 3: i * 3 + 2], byteorder='big')
            else:
                return data
            continue
        raise Exception('Checksum repeatedly ({0}x) wrong'.format(n_tries), rx_data)

    def _write(self, command):
        super(sensirionSHT85, self)._write(command)

    def _perform_measurement(self, read_n_words=2):
        data = {
            "low": self._read([0x24, 0x16], read_n_words=read_n_words, timeout_us=4500),
            "medium": self._read([0x24, 0x0B], read_n_words=read_n_words, timeout_us=6500),
            "high": self._read([0x24, 0x00], read_n_words=read_n_words, timeout_us=15500),
        }[self.repeatability]
        return data

    def get_temperature(self):
        data = self._perform_measurement(read_n_words=1)
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

    def start_asynchronous_read(self, measurments_per_second=1, ART=False):
        if ART:
            cmd = [0x2B, 0x32]
        else:
            cmd = {
                "low": {
                    0.5: [0x20, 0x2F],
                    1: [0x21, 0x2D],
                    2: [0x22, 0x2B],
                    4: [0x23, 0x29],
                    10: [0x27, 0x2A],
                }[measurments_per_second],
                "medium": {
                    0.5: [0x20, 0x24],
                    1: [0x21, 0x26],
                    2: [0x22, 0x20],
                    4: [0x23, 0x22],
                    10: [0x27, 0x21],
                }[measurments_per_second],
                "high": {
                    0.5: [0x20, 0x32],
                    1: [0x21, 0x30],
                    2: [0x22, 0x36],
                    4: [0x23, 0x34],
                    10: [0x27, 0x37],
                }[measurments_per_second]
            }[self.repeatability]
        self._write(cmd)

    def read_asynchronous(self, timeout_us=0):
        try:
            data = self._read([0xE0, 0x00], read_n_words=2, timeout_us=timeout_us)
            return self._to_temperature(data), self._to_humidity(data)
        except self.TimeoutError:
            return None, None

    def stop_asynchronous_read(self):
        self._write([0x30, 0x93])

    def asynchronous(self, measurments_per_second=1, ART=False):
        class Asynchronous:
            def __enter__(self_a):
                self.start_asynchronous_read(measurments_per_second, ART)
                return self_a

            def __exit__(self_a, exc_type, exc_val, exc_tb):
                self.stop_asynchronous_read()

            def read(self_a):
                return self.read_asynchronous()

            def read_synchronous(self_a, timeout_us=100e3):
                return self.read_asynchronous(timeout_us)
        return Asynchronous()

    def _get_status(self):
        return self._read([0xF3, 0x2D], read_n_words=1, timeout_us=0)

    def enable_heater(self):
        self._write([0x30, 0x6D])

    def disable_heater(self):
        self._write([0x30, 0x66])

    def is_heater_on(self):
        return self._get_status()[0] & (1 << 13) > 0

    # This soft-reset re-initializes all registers
    def reset_sensor(self):
        self._write([0x30, 0xA2])

    def _to_temperature(self, data):
        return -45 + 175 * (data[0] / (2**16 - 1))

    def _to_humidity(self, data):
        return 100 * (data[1] / (2**16 - 1))

    def to_dew_point(self, T, RH):
        if T < 0:
            T_n = 243.12
            m = 17.6
        else:
            T_n = 272.62
            m = 22.46
        a = np.log(RH / 100.0) + m * T / (T_n + T)
        return T_n * a / (m - a)
