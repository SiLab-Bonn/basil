from basil.HL.arduino_base import ArduinoBase


class I2CTransmissionError(ValueError):
    pass


class SerialToI2C(ArduinoBase):

    CMDS = {
        'write': 'W',
        'read': 'R',
        'address': 'A',
        'check': 'T'
    }

    ERRORS = {
        'error': "Serial transmission error"  # Custom return code for unsuccesful serial communciation
    }

    # Check https://www.arduino.cc/en/Reference/WireEndTransmission
    I2C_RETURN_CODES = {
        '0': "Success",
        '1': "Data too long to fit in transmit buffer",
        '2': "Received NACK on transmit of address",
        '3': "Received NACK on transmit of data",
        '4': "Other error"
    }

    @property
    def i2c_address(self):
        """
        Read back the I2C address property from the firmware.

        Returns
        -------
        int
            I2C address
        """
        return int(self.query(self.create_command(self.CMDS['address'])))

    @i2c_address.setter
    def i2c_address(self, addr):
        """
        Set the I2C address of the device on the bus to talk to.

        Parameters
        ----------
        addr : int
            I2C address

        Raises
        ------
        I2CTransmissionError
            If the set address on the Arduino does not match with what has been sent
        """
        self._set_and_retrieve(cmd='address', val=int(addr), exception_=I2CTransmissionError)

    def __init__(self, intf, conf):
        super(SerialToI2C, self).__init__(intf, conf)

    def query_i2c(self, msg):
        """
        Queries a message *msg* and reads the i2c return code.
        Checks the return code of the Arduino Wire.endTransmission.
        Additional data after the query can be retrive using a self.read

        Parameters
        ----------
        msg : str, bytes
            Message to be queried

        Returns
        -------
        str
            I2C return code as in self.I2C_RETURN_CODES

        Raises
        ------
        NotImplementedError
            return_code is unknown
        I2CTransmissionError
            dedicated error code from Wire library
        """
        try:
            i2c_return_code = self.query(msg)

            if i2c_return_code != '0':
                if i2c_return_code not in self.I2C_RETURN_CODES:
                    raise NotImplementedError(f"Unknown return code {i2c_return_code}")
                raise I2CTransmissionError(self.I2C_RETURN_CODES[i2c_return_code])

            return i2c_return_code

        except RuntimeError:
            self.reset_buffers()  # Serial error, just reset buffers

    def read_register(self, reg):
        """
        Read data from register *reg*

        Parameters
        ----------
        reg : int
            Register to read from

        Returns
        -------
        int
            Data read from *reg*
        """
        self.query_i2c(self.create_command(self.CMDS['read'], reg))
        return int(self.read())

    def write_register(self, reg, data):
        """
        Write *data* to register *reg*

        Parameters
        ----------
        reg : int
            Register to write to
        data : int
            Data to write to register *reg*
        """
        self.query_i2c(self.create_command(self.CMDS['write'], reg, data))

    def check_i2c_connection(self):
        """
        Checks the i2c connection from arduino to bus device
        """
        self.query_i2c(self.create_command(self.CMDS['check']))
