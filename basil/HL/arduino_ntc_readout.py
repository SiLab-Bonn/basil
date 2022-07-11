import logging
from basil.HL.arduino_base import ArduinoBase


logger = logging.getLogger(__name__)


class NTCReadout(ArduinoBase):
    """Class to read from Arduino temperature sensor setup"""

    CMDS = {
        'temp': 'T',
        'samples': 'S',
        'beta': 'B',
        'nominal_res': 'O',
        'nominal_temp': 'C',
        'res': 'R',
        'restore': 'X'
    }

    ERRORS = {
        '999': "Invalid NTC pin",
        'error': "Serial transmission error"  # Custom return code for unsuccesful serial communciation
    }

    @property
    def n_samples(self):
        return int(self.query(self.create_command(self.CMDS['samples'])))

    @n_samples.setter
    def n_samples(self, n_samples):
        self._set_and_retrieve(cmd='samples', val=int(n_samples))

    @property
    def beta_coefficient(self):
        return float(self.query(self.create_command(self.CMDS['beta'])))

    @beta_coefficient.setter
    def beta_coefficient(self, beta_coefficient):
        self._set_and_retrieve(cmd='beta', val=float(beta_coefficient))

    @property
    def nominal_resistance(self):
        return float(self.query(self.create_command(self.CMDS['nominal_res'])))

    @nominal_resistance.setter
    def nominal_resistance(self, nominal_res):
        self._set_and_retrieve(cmd='nominal_res', val=float(nominal_res))

    @property
    def nominal_temperature(self):
        return float(self.query(self.create_command(self.CMDS['nominal_temp'])))

    @nominal_temperature.setter
    def nominal_temperature(self, nominal_temp):
        self._set_and_retrieve(cmd='nominal_temp', val=float(nominal_temp))

    @property
    def resistance(self):
        return float(self.query(self.create_command(self.CMDS['res'])))

    @resistance.setter
    def resistance(self, resistance):
        self._set_and_retrieve(cmd='res', val=float(resistance))

    def __init__(self, intf, conf):
        super(NTCReadout, self).__init__(intf, conf)
        # Store temperature limits of NTC thermistor
        self.ntc_limits = tuple(self._init.get('ntc_limits', (-55, 120)))

    def restore_defaults(self):
        """
        Restores default values in the firmware which correspond to this classes properties
        """
        self._set_and_retrieve(cmd='restore', val=int(111))  # *val* can be any int, just used to test that the command was received

    def get_temp(self, sensor):
        """Gets temperature of sensor where 0 <= sensor <= 7 is the physical pin number of the sensor on
        the Arduino analog pin. Can also be a list of ints."""

        # Make int sensors to list
        sensor = sensor if isinstance(sensor, list) else [sensor]

        # Write command to read all these sensors
        self.write(self.create_command(self.CMDS['temp'], *sensor))

        # Get result; make sure we get the correct amount of results
        result = {s: float(self.read()) for s in sensor}

        for sens in result:
            if not self.ntc_limits[0] <= result[sens] <= self.ntc_limits[1]:
                msg = f"NTC {sens} out of calibration range (NTC_{sens}={result[sens]} °C, NTC_range={self.ntc_limits} °C)."
                logger.warning(msg)

        return result
