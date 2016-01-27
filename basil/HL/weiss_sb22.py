#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
from basil.HL.RegisterHardwareLayer import HardwareLayer


class weissSB22(HardwareLayer):

    '''Driver for the Weiss SB 22 climate chamber.
    A simple protocoll via RS 232 serial port is used with 9600/19200 baud rate and 256 modulo complement check sum.
    Between the different command a delay of 5 seconds should be set according to the manual, but it works at faster rates.
    '''

    _ERROR_CODES = {
        1: "Power cut",
        2: "Communication error",
        3: "Ventilator failure",
        4: "Temperature sensor short",
        5: "Humidity sensor short",
        6: "Sensor short",
        7: "Sensor short",
        8: "Sensor short",
        9: "Chiller prestage failure",
        10: "Chiller final stage failure",
        11: "Water level at minimum",
        12: "Water level below minimum",
        13: "Temperature too high",
        14: "Temperature too low",
        15: "Humidity too high",
        16: "Humidity too low",
        17: "Humidity water heater",
        18: "Test room heater",
        19: "No program memory"
    }

    def __init__(self, intf, conf):
        super(weissSB22, self).__init__(intf, conf)

    def init(self):
        self.slave_address = self._init['address']  # set the device address
        self.min_temp = self._init['min_temp']  # define the minimum temperature one can set, for safety
        self.max_temp = self._init['max_temp']  # define the maximum temperature one can set, for safety
        self.min_humidity = self._init['min_humidity']  # define the minimum humidity one can set, for safety
        self.max_humidity = self._init['max_humidity']  # define the maximum humidity one can set, for safety
        self._temperature = self.get_temperature()  # tmp variable to store last value set, needed since always temp and humidity has to be set
        self._humidity = self.get_humidity()  # tmp variable to store last value set, needed since always temp and humidity has to be set
        self._digital_ch = self.get_digital_ch()  # the digital channels define the functions (humiditiy control, dew protection, ..., in binary coding, 1000000000000000 is temperature control only)

    def get_temperature(self):
        self.write('%d?' % self.slave_address)
        answer = self.read()
        return float(answer[3:8])

    def get_temperature_target(self):
        self.write('%d?' % self.slave_address)
        answer = self.read()
        return float(answer[23:28])

    def get_humidity(self):
        self.write('%d?' % self.slave_address)
        answer = self.read()
        return int(answer[9:11])

    def get_humidity_target(self):
        self.write('%d?' % self.slave_address)
        answer = self.read()
        return int(answer[29:31])

    def get_digital_ch(self):
        self.write('%d?' % self.slave_address)
        answer = self.read()
        return answer[32:48]

    def set_digital_ch(self, channel, value=1):  # Set channel to 0 or 1, functionality acording to manual, Channel is a normal decimal int starting from 1
        actual_channels = list(self.get_digital_ch())
        if value > 0:
            actual_channels[channel - 1] = '1'
        else:
            actual_channels[channel - 1] = '0'
        actual_channels = "".join(actual_channels)
        self._digital_ch = actual_channels
        msg = '%dT%05.1fF%02dR%s' % (self.slave_address, self._temperature, self._humidity, self._digital_ch)
        self.write(msg)
        self.check_for_errors(self.read())

    def set_temperature(self, temperature):
        if temperature < self.min_temp:
            raise RuntimeWarning('Set temperature %f is lower than minimum allowed temperature %f', temperature, self.min_temp)
        if temperature > self.max_temp:
            raise RuntimeWarning('Set temperature %f is higher than maximum allowed temperature %f', temperature, self.max_temp)
        self._temperature = temperature
        msg = '%dT%05.1fF%02dR%s' % (self.slave_address, self._temperature, self._humidity, self._digital_ch)
        self.write(msg)
        self.check_for_errors(self.read())

    def set_humidity(self, humidity):
        if humidity < self.min_humidity:
            raise RuntimeWarning('Set humidity %f is lower than minimum allowed humidity %f', humidity, self.min_humidity)
        if humidity > self.max_humidity:
            raise RuntimeWarning('Set humidity %f is higher than maximum allowed humidity %f', humidity, self.max_humidity)
        self._humidity = humidity
        msg = '%dT%05.1fF%02dR%s' % (self.slave_address, self._temperature, self._humidity, self._digital_ch)
        self.write(msg)
        self.check_for_errors(self.read())

    def write(self, value):
        msg = '\x02' + value  # msg has STX at the beginning
        msg += self._calc_crc(msg)  # CRC for all characters including STX
        msg += '\x03'  # msg has ETX at the end
        self._intf.write(str(msg))

    def read(self):
        answer = self._intf._readline()  # the read termination string has to be set to \x03
        return answer

    def check_for_errors(self, answer):
        if len(answer) > 6:  # error codes are not in the ackowledge strings
            error_code = int(answer[20:22]) if answer[20:22] != '--' else 0
            if error_code > 0:
                raise RuntimeError('Climate chamber error %d: %s', error_code, self._ERROR_CODES[error_code])
        else:  # ack answer
            if answer[2] != '\x06':
                raise RuntimeError('Data transmission not ackowledged')
        if int(answer[1]) != self.slave_address:
            raise RuntimeError('Climate chamber address %s instead of %d', answer[1], self.slave_address)

    def _calc_crc(self, msg):
        ASCII = "0123456789ABCDEF"
        mod_256 = (-(sum(ord(i) for i in msg) % 256) & 0xFF)
        lword = (mod_256 & 0xF0) >> 4
        hword = mod_256 & 0x0F
        return ASCII[lword] + ASCII[hword]
