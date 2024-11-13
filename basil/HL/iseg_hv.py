#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging

from basil.HL.HardwareLayer import HardwareLayer

logger = logging.getLogger(__name__)


class IsegHV(HardwareLayer):
    """
    Python RS232 interface for various ISEG HV power supplies (SHQ-Series, NQH-Series, etc.)
    https://iseg-hv.com/download/AC_DC/SHQ/iseg_manual_SHQ-RS-232-Programmers-Guide.pdf
    https://iseg-hv.com/download/SYSTEMS/NIM/NHQ/NHQ-RS-232-Programmers-Guide.pdf
    """

    # Command references from protocol
    CMDS = {
        "get_identifier": "#",
        "set_answer_delay": "W={value}",
        "get_answer_delay": "W",
        "get_voltage": "U{channel}",
        "get_current": "I{channel}",
        "get_voltage_limit": "M{channel}",
        "get_current_limit": "N{channel}",
        "get_source_voltage": "D{channel}",
        "set_voltage": "D{channel}={value}",
        "get_ramp_speed": "V{channel}",
        "set_ramp_speed": "V{channel}={value}",
        "start_voltage_ramp": "G{channel}",
        "set_current_trip": "L{channel}={value}",  # Same functionality as set_current_trip_mA
        "get_current_trip": "L{channel}",  # Same functionality as get_current_trip_mA
        "set_current_trip_mA": "LB{channel}={value}",
        "get_current_trip_mA": "LB{channel}",
        "set_current_trip_muA": "LS{channel}={value}",
        "get_current_trip_muA": "LS{channel}",
        "get_status_word": "S{channel}",
        "get_module_status": "T{channel}",
        "set_autostart": "A{channel}={value}",
        "get_autostart": "A{channel}",
    }

    FORMATS = {
        "get_voltage_meas": lambda val: f"{val[:-3]}e{val[-3:]}",
        "get_current_meas": lambda val: f"{val[:-3]}e{val[-3:]}",
        "get_voltage_set": lambda val: f"{val[:-3]}e{val[-3:]}",
        "get_current_trip": lambda val: f"{val[:-3]}e{val[-3:]}",
    }

    ERRORS = {
        "????": "Syntax error in command",
        "?WCN": "Wrong channel number",
        "?TOT": "Timeout error (Unit will re-initialise)",
    }

    STATUS = {
        "ON": "Output voltage according to set voltage",
        "OFF": "Channel front panel switch off",
        "MAN": "Channel is on, set to manual mode",
        "ERR": "V_MAX or I_MAX was exceeded",
        "INH": "Inhibit signal was / is active",
        "QUA": "Quality of output voltage no guaranteed at present",
        "L2H": "Output voltage increasing",
        "H2L": "Output voltage decreasing",
        "LAS": "Look at status (only after G-command)",
        "TRP": "Current trip was active",
    }

    def __init__(self, intf, conf):
        super(IsegHV, self).__init__(intf, conf)

        # Store current channel number; default to channel 1
        self._channel = None

        # Store number of channels
        self.n_channel = self._init.get("n_channel", 1)
        self.channel = self._init.get("channel", 1)

        # Voltage which is considered the high voltage
        self.high_voltage = self._init.get("high_voltage", None)

        # Software-side voltage limit, set via self.v_lim property
        self._voltage_limit = self._init.get("v_lim", None)

        if self._voltage_limit is not None:
            self.voltage_limit = self._init.get("voltage_limit", None)

    def init(self):
        """Set up the power supply"""
        # self.write("")  # Synchronize: sometimze needed

        # Important: The manual states that the default answer delay is 3 ms.
        # When querying the answer_delay property, it returns sometimes 0 although only values in between 1 and 255 ms are valid.
        # Queries take very long which leads to serial timeouts. I suspect the default value on firmware side is in fact 255 ms (not 3 ms).
        # Therefore, setting the answer_delay as first thing in the __init__ is sometimes required
        self.answer_delay = 1  # ms

        # # Add error response for attempting to set voltage too high
        self.ERRORS[f"? UMAX={self.get_voltage_limit}"] = (
            "Set voltage exceeds voltage limit"
        )

    def get_current(self):
        """
        Actual current flowing at output of self.channel in A

        Returns
        -------
        float
            Output current in A
        """
        return float(self._get_set_property(prop="get_current_meas"))

    def get_voltage(self):
        """
        Actual voltage at self.channel output in V

        Returns
        -------
        float
            Output voltage in V
        """
        return float(self._get_set_property(prop="get_voltage_meas"))

    def set_voltage(self, voltage):
        # Check hardware voltage limit
        if abs(voltage) > abs(self.voltage_limit):
            raise ValueError(
                f"Voltage of {voltage}V too high! Maximum voltage is {self.voltage_limit} V"
            )

        # Get module status for checks
        ms = self.get_module_status()

        # Issue warning if PSU is in different polarity as value
        if ms[5] == "1" and voltage < 0:
            raise ValueError(
                f"Power supply polarity is set to positive but target voltage of {voltage}V is negative!"
            )
        elif ms[5] == "0" and voltage > 0:
            raise ValueError(
                f"Power supply polarity is set to negative but target voltage of {voltage}V is positive!"
            )

        # Check software voltage limit
        if self._voltage_limit is not None:
            if (ms[5] == "1" and voltage > self._voltage_limit) or (
                ms[5] == "0" and voltage < self._voltage_limit
            ):
                raise ValueError(
                    f"Voltage of {voltage}V too high! Increase *v_lim={self._v_lim}V* to enable higher voltage!"
                )

        # Issue warning if PSU is in manual mode
        # Then voltage can only be changed manually, at the device
        if ms[6] == "1":
            logging.warning(
                "Power supply in manual mode; voltage changes have no effect!"
            )

        self._get_set_property(prop="set_voltage", value=abs(voltage))

    def get_source_voltage(self):
        """
        Target voltage of self.channel output in V
        This is the voltage which is set using self.voltage property

        Returns
        -------
        float
            Target voltage in V
        """
        return float(self._get_set_property(prop="get_source_voltage"))

    def get_hardware_voltage_limit(self):
        """
        Return current hardware-side voltage limit of self.channel in V

        Returns
        -------
        float
            Voltage limit in V
        """
        # Property get_v_lim returns voltage limit as percentage of max voltage
        return (
            int(self._get_set_property(prop="get_voltage_limit"))
            / 100.0
            * float(self.V_MAX[:-1])
        )

    def get_voltage_limit(self):
        """
        Software-side voltage limit, initially None. If set, a check will happen before each voltage change

        Returns
        -------
        float, None
            Software-side voltage limit
        """
        return self._voltage_limit

    def set_voltage_limit(self, voltage_limit):
        self._voltage_limit = (
            voltage_limit if voltage_limit is None else float(voltage_limit)
        )

    def get_current_limit(self):
        """
        Return current limit of self.channel in A

        Returns
        -------
        float
            Current limit in A
        """
        # Property get_i_lim returns voltage limit as percentage of max current
        return (
            int(self._get_set_property(prop="get_current_limit")) / 100.0 * float(self.I_MAX[:-2])
        )

    def get_current_trip(self, resolution="mA"):
        """
        Read current trip/limit, if 0 -> no trip

        Returns
        -------
        float
            Current trip
        """
        if resolution == "muA":
            return float(self._get_set_property(prop="get_current_trip_muA"))
        else:
            return float(self._get_set_property(prop="get_current_trip_mA"))

    def set_current_trip(self, ct, resolution="mA"):
        if resolution == "muA":
            self._get_set_property(prop="set_current_trip_muA", value=ct)
        else:
            self._get_set_property(prop="set_current_trip_mA", value=ct)

    def start_voltage_ramp(self):
        """
        Manually initiate the change of the voltage.
        Only needed if self.autostart is False
        """
        self._get_set_property(prop="start_voltage_ramp")

    def get_current_channel(self):
        return self._channel

    def set_current_channel(self, ch):
        if not 1 <= ch <= self.n_channel:
            raise ValueError(f"Channel number must be 1 <= channel <= {self.n_channel}")
        self._channel = ch

    def get_identifier(self):
        """
        Read module identifier; return format is "UNIT_NUMBER;SOFTWARE_REL;V_MAX;I_MAX"

        Returns
        -------
        str
            Module identifier
        """
        return self._get_set_property(prop="get_identifier")

    def get_ramp_speed(self):
        """
        Read the output voltage ramping speed in V/s.
        Valid values are 1 up to and including 255 V/s

        Returns
        -------
        int
            Ramp speed of output voltage
        """
        return int(self._get_set_property(prop="get_ramp_speed"))

    def set_ramp_speed(self, rs):
        if not 1 <= rs <= 255:
            raise ValueError("Ramp speed must be 1 <= ramp_speed <= 255 V/s")
        self._get_set_property(prop="set_ramp_speed", value=rs)

    def get_answer_delay(self):
        """
        answer delay (better 'delay') in between two output characters from the power supply in milliseconds.
        Valid values are 1 up to and including 255 ms

        Returns
        -------
        int
            answer delay in ms (uint8)
        """
        return int(self._get_set_property(prop="get_answer_delay"))

    def set_answer_delay(self, bt):
        if not 1 <= bt <= 255:
            raise ValueError("answer delay must be 1 <= answer_delay <= 255 ms")
        self._get_set_property(prop="set_answer_delay", value=bt)

    def get_autostart(self):
        """
        Whether output voltage changes automatically after setting value via self.voltage property.
        Alternatively, call self.start_voltage_ramp method to initaite voltagte change manually.
        self._get_set_property(prop='get_autostart') -> 008: autostart is active
        self._get_set_property(prop='get_autostart') -> 000: autostart is inactive

        Returns
        -------
        bool
            Wheter autostart is active
        """
        return self._get_set_property(prop="get_autostart") == "008"

    def set_autostart(self, state):
        self._get_set_property(prop="set_autostart", value=8 if state else 0)

    def get_polarity(self):
        return 1 if self.module_status[5] == "1" else -1

    def get_status_word(self):
        """
        Read status word of self.channel
        See self.STATUS and self.status_description

        Returns
        -------
        str
            Status word
        """
        return self._get_set_property(prop="get_status_word")

    def get_status_description(self):
        """
        Read description corresponding to self.status_word

        Returns
        -------
        str
            Status description
        """
        status_word = self.status_word
        for status in self.STATUS:
            if status in status_word:
                return f"{status_word}: {self.STATUS[status]}"
        return "No description"

    def get_module_status(self):
        """
        Read module status of self.channel
        Return value is uint8, use '{:08b}'.format(value) to get bits

        Returns
        -------
        int
            Value of status
        """
        return "{:08b}".format(int(self._get_set_property(prop="get_module_status")))

    def get_module_description(self):
        """
        Read module status and print out desciptive string from it

        Returns
        -------
        str
            Module description string
        """

        def module_msg(bit, prefix, t_msg, f_msg=""):
            return f"{prefix} " + (t_msg if bit == "1" else f_msg) + "\n"

        _description = {
            0: dict(prefix="", t_msg="Quality of output voltage not given at present"),
            1: dict(prefix="", t_msg="V_MAX or I_MAX is / was exceeded"),
            2: dict(prefix="INHIBIT signal", t_msg="is / was active", f_msg="inactive"),
            3: dict(prefix="KILL_ENABLE is", t_msg="on", f_msg="off"),
            4: dict(prefix="Front-panel HV-ON switch is", t_msg="OFF", f_msg="ON"),
            5: dict(prefix="Polarity set to", t_msg="positive", f_msg="negative"),
            6: dict(prefix="Control via", t_msg="manual", f_msg="RS-232 interface"),
            7: dict(
                prefix="Display dialled to",
                t_msg="voltage measurement",
                f_msg="current measurement",
            ),
        }

        module_description = ""
        for i, bit in enumerate(self.module_status):
            module_description += module_msg(bit=bit, **_description[i])
        return module_description

    def _get_set_property(self, prop, value=None):

        if "{channel}" in self.CMDS[prop] and "{value}" in self.CMDS[prop]:
            cmd = self.CMDS[prop].format(channel=self.channel, value=value)
        elif "{channel}" in self.CMDS[prop]:
            cmd = self.CMDS[prop].format(channel=self.channel)
        elif "{value}" in self.CMDS[prop]:
            cmd = self.CMDS[prop].format(value=value)
        else:
            cmd = self.CMDS[prop]

        result = self.query(cmd)

        return self.FORMATS[prop](result) if prop in self.FORMATS else result

    def read(self):
        """
        Reads from serial port until self.READ_TERMINATION byte is encountered.
        This is equivalent to serial.Serial.readline() but respects timeouts
        If the rad value is found in self.ERROS dict, raise a RuntimeError. If not just return read value

        Returns
        -------
        str
            Decoded, stripped string, read from serial port

        Raises
        ------
        RuntimeError
            Value read from serial bus is an error
        """
        read_value = str(self._intf.read()).strip()

        if read_value in self.ERRORS:
            raise RuntimeError(self.ERRORS[read_value])

        return read_value

    def write(self, msg):
        self._intf.write(msg)

    def query(self, msg):
        """
        Queries a message *msg* and reads the answer

        Parameters
        ----------
        msg : str, bytes
            Message to be queried

        Returns
        -------
        str
            Decoded, stripped string, read from serial port
        """
        # ASCII protocol mirrors msg first, then sends reply, eg:
        # SEND -> request_some_data  // command string
        # RECV -> request_some_data  // recv the command string on first read
        # RECV -> actual data        // recv the actual data
        echo = str(self._intf.query(msg)).strip()
        if echo != msg:
            raise RuntimeError(
                f"Issued command ({msg}) and echoed command ({echo}) differ."
            )
        return self.read()

    def on(self):
        try:
            self.voltage = float(self.high_voltage)
        except TypeError:
            raise ValueError(
                "High voltage is not set. Set *high_voltage* attribute to numerical value"
            )

    def off(self):
        self.set_voltage(0)

    def get_on(self):
        return "0" if self.get_module_status()[4] == "1" else "1"

    def set_voltage_range(self): # Not implemented
        ...

    def set_current(self): # Not implemented
        ...

    def source_current(self): # Not implemented
        ...

    def soruce_volt(self): # Not implemented
        ...
        
    @property
    def UNIT_NUMBER(self):
        return self.identifier().split(";")[0]

    @property
    def SOFTWARE_REL(self):
        return self.identifier().split(";")[1]

    @property
    def V_MAX(self):
        return self.identifier().split(";")[2]

    @property
    def I_MAX(self):
        return self.identifier().split(";")[3]

    #### BEWLOW DEPRECATED ####

    @property
    def hv_on(self):
        """
        Use 'on' method instead
        """
        self.on()

    @property
    def hv_off(self):
        """
        Use 'off' method instead
        """
        self.off()

    @property
    def polarity(self):
        """
        Use 'get_polarity' method instead
        """
        return self.get_polarity()

    @property
    def autostart(self):
        """
        Use 'get_autostart' method instead
        """
        return self.get_autostart()

    @autostart.setter
    def autostart(self, state):
        """
        Use 'set_autostart' method instead
        """
        self.set_autostart(state)

    @property
    def answer_delay(self):
        """
        Use 'get_answer_delay' method instead
        """
        return self.get_answer_delay()

    @answer_delay.setter
    def answer_delay(self, bt):
        """
        Use 'set_answer_delay' method instead
        """
        self.set_answer_delay(bt)

    @property
    def ramp_speed(self):
        """
        Use 'get_ramp_speed' method instead
        """
        return self.get_ramp_speed()

    @ramp_speed.setter
    def ramp_speed(self, rs):
        """
        Use 'set_ramp_speed' method instead
        """
        self.set_ramp_speed(rs)

    @property
    def channel(self):
        """
        Use 'get_current_channel' method instead
        """
        return self.get_current_channel()

    @channel.setter
    def channel(self, ch):
        """
        Use 'set_current_channel' method instead
        """
        self.set_current_channel(ch)

    @property
    def current_trip(self):
        """
        Use 'get_current_trip' method instead.
        This property will use the mA resolution!
        """
        return self.get_current_trip()

    @current_trip.setter
    def current_trip(self, ct):
        """
        Use 'set_current_trip' method instead
        This setter will use the mA resolution!
        """
        self.set_current_trip(ct)

    @property
    def voltage(self):
        """
        Use 'get_voltage' method instead
        """
        return self.get_voltage()

    @property
    def current(self):
        """
        Use 'get_current' method instead
        """
        return self.get_current()

    @property
    def voltage_target(self):
        """
        Use 'get_source_voltage' method instead
        """
        return self.get_source_voltage()

    @property
    def v_lim(self):
        return self.get_voltage_limit()

    @v_lim.setter
    def v_lim(self, voltage_limit):
        self.set_voltage_limit(voltage_limit)

    @property
    def voltage_limit(self):
        """
        Use 'get_hardware_voltage_limit' method instead
        """
        return self.get_hardware_voltage_limit()

    @property
    def identifier(self):
        """
        Use 'get_identifier' method instead
        """
        return self.get_identifier()

    @property
    def status_word(self):
        """
        Use 'get_status_word' method instead
        """
        return self.get_status_word()

    @property
    def module_status(self):
        """
        Use 'get_module_status' method instead
        """
        return self.get_module_status()

    @property
    def module_description(self):
        """
        Use 'get_module_description' method instead
        """
        return self.get_module_description()

    @property
    def status_description(self):
        """
        Use 'get_status_description' method instead
        """
        return self.get_status_description()
