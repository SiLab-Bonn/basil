from time import sleep
from basil.HL.RegisterHardwareLayer import HardwareLayer


class ArduinoBase(HardwareLayer):

    CMD_DELIMITER = ':'

    CMDS = {
        'communication_delay': 'D'
    }

    ERRORS = {
        'error': "An error occured"
    }

    @property
    def communication_delay(self):
        """
        The communication delay between two commands to the Arduino

        Returns
        -------
        int
            Communication delay in milliseconds
        """
        return int(self.query(self.create_command(self.CMDS['communication_delay'])))

    @communication_delay.setter
    def communication_delay(self, comm_delay):
        """
        Sets the communication delay property

        Parameters
        ----------
        comm_delay : int
            Communication delay in milliseconds
        """
        self._set_and_retrieve(cmd='communication_delay', val=comm_delay)

    def __init__(self, intf, conf):
        super(ArduinoBase, self).__init__(intf, conf)
        self.CMDS = {**ArduinoBase.CMDS, **self.CMDS}
        self.ERRORS = {**ArduinoBase.ERRORS, **self.ERRORS}

    def reset_buffers(self):
        """
        Sleep for a bit and reset buffers to reset serial
        """
        sleep(0.5)
        self._intf._port.reset_input_buffer()
        self._intf._port.reset_output_buffer()

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
        self.write(msg)
        return self.read()

    def _set_and_retrieve(self, cmd, val, exception_=RuntimeError):
        """
        Sets and retrieves a value on the Arduino firmware, represented by self.CMDS[cmd]
        The firmware is expected to return the value which was set.

        Parameters
        ----------
        cmd : str
            Command string in self.CMDS
        val : int, float, str
            The value to set
        exception_ : Exception, optional
            The exception to raise if the set and retrieved value differ, by default RuntimeError

        Raises
        ------
        exception_
            Exception is raised when set and retrieved values differ
        """
        # The self.CMDS['cmd'].lower() invokes the setter, self.CMDS['cmd'] the getter
        ret_val = self.query(self.create_command(self.CMDS[cmd].lower(), val))

        # Perform check
        success = True
        try:
            if isinstance(val, int):
                success = int(ret_val) == val
            elif isinstance(val, float):
                success = float(ret_val) == val
            else:
                success = ret_val == val
        except ValueError:
            success = False

        if not success:
            exception_message = f"Retrieved value for command {cmd} ({ret_val}, '{type(ret_val)}') different from set value ({val}, '{type(val)}')"
            raise exception_(exception_message)

    def create_command(self, *args):
        """
        Create command string according to specified format.
        Arguments to this function are formatted and separated using self._DELIM

        Examples:

        self.create_command('W', 0x03, 0xFF) -> 'W:3:255:'
        self.create_command('R', 0x03) -> 'R:3:'

        Returns
        -------
        str
            Formatted command string
        """
        return f'{self.CMD_DELIMITER.join(str(a) for a in args)}{self.CMD_DELIMITER}'.encode()
