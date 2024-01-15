import logging
from basil.HL.arduino_ntc_readout import NTCReadout

import numpy as np

logger = logging.getLogger(__name__)


class EnvironmentReadout(NTCReadout):
    """Class to read from Arduino temperature or humidity/pressure sensor setup"""

    def __init__(self, intf, conf):
        self.CMDS.update({
            'analog_read': 'A'})
        
        super(EnvironmentReadout, self).__init__(intf, conf)

        self.fixed_resistors = self._init.get('resistors')
        if not isinstance(self.fixed_resistors, list):
            self.fixed_resistors = [float(self.fixed_resistors)] * 8 if self.fixed_resistors is not None else [None] * 8

        self.adc_range = float(self._init.get('adc_range', 1023))
        self.operating_voltage = float(self._init.get('operating_voltage', 5.0))

        self.humidity_pin = int(self._init.get('humidity_pin', -1))
        self.pressure_pin = int(self._init.get('pressure_pin', -1))

        self.steinharthart_params = dict(self._init.get('steinharthart_params', {
            "A": 0.0,
            "B": 0.0,
            "C": 0.0,
            "D": 0.0,
            "R25": 0.0,
        }))

        self.humidity_params = dict(self._init.get('humidity_params', {
            "slope": 0.0,
            "offset": 0.0,
        }))
        
        self.humidity_temp_correction_params = dict(self._init.get('humidity_temp_correction_params', {
            "slope": 0.0,
            "offset": 0.0,
        }))

        self.pressure_params = dict(self._init.get('pressure_params', {
            "slope": 0.0,
            "offset": 0.0,
        }))

    def setFixedResistance(self, pin, resistance):
        self.fixed_resistors[pin] = resistance

    def getResistance(self, sensor, adc_range=None):
        analog_read = self.analog_read(sensor)

        # Make int sensors to list
        sensor = sensor if isinstance(sensor, list) else [sensor]

        if adc_range is None:
            adc_range = self.adc_range

        return {s: self.fixed_resistors[s] / (adc_range / analog_read[s] - 1.0) if abs(adc_range / analog_read[s] - 1) > 0.01 else None for s in sensor}
    
    def getVoltage(self, sensor, adc_range=None):
        analog_read = self.analog_read(sensor)
        
        # Make int sensors to list
        sensor = sensor if isinstance(sensor, list) else [sensor]

        if adc_range is None:
            adc_range = self.adc_range

        return {s: analog_read[s] * (self.operating_voltage / adc_range) for s in sensor}

    def steinhartHart(self, R, A, B, C, D, R25=10e3):
        E = np.log(R/R25)

        return 1.0/(A + B*E + C*E**2 + D*E**3) - 273.15       

    def temperature(self, sensor, adc_range=None):
        # Make int sensors to list
        sensor = sensor if isinstance(sensor, list) else [sensor]

        if adc_range is None:
            adc_range = self.adc_range
            
        resistances = self.getResistance(sensor, adc_range)

        return {s: self.steinhartHart(resistances[s], **self.steinharthart_params) if resistances[s] is not None else None for s in sensor}
    
    def humidity(self, temperature_correction=None, adc_range=None):
        if self.humidity_pin < 0:
            logger.warning('No humidity pin specified!')
            return
        
        voltage = self.getVoltage(self.humidity_pin, adc_range)[self.humidity_pin]

        RH = (voltage - self.humidity_params['offset']) / self.humidity_params['slope']

        if temperature_correction is not None:
            RH = RH / (self.humidity_temp_correction_params['slope'] * temperature_correction + self.humidity_temp_correction_params['offset'])

        return max(float(RH), 0.0)
    
    def pressure(self, adc_range=None):
        if self.pressure_pin < 0:
            logger.warning('No pressure pin specified!')
            return
        
        voltage = self.getVoltage(self.pressure_pin, adc_range)[self.pressure_pin]

        return self.pressure_params['slope'] * voltage - self.pressure_params['offset'];
    
    def analog_read(self, sensor):
        return self._get_measurement(sensor, kind='analog_read')
    