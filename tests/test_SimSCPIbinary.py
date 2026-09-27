import os
import unittest

import yaml
import numpy as np

from basil.dut import Dut

test_ascii_stream = "7.50743E-08,7.48907E-08,7.51024E-08,7.52273E-08,7.50416E-08,7.52534E-08,7.51035E-08,7.51142E-08,7.50377E-08,7.50383E-08,7.52236E-08,7.51461E-08,7.48099E-08,7.52440E-08,7.48978E-08,7.52257E-08,7.52558E-08,7.50827E-08,7.47307E-08,7.54547E-08,7.50775E-08,7.50997E-08,7.49254E-08,7.50603E-08,7.51198E-08,7.51688E-08,7.49996E-08,7.52538E-08,7.50843E-08,7.52863E-08,7.51728E-08,7.50796E-08,7.51795E-08,7.49799E-08,7.50695E-08,7.52655E-08,7.50175E-08,7.51024E-08,7.48423E-08,7.50621E-08"

k2602def_yaml = os.path.join(os.path.dirname(__file__), 'test_keithley_binary.yaml')

# noinspection compatibility
cnfg_yaml = f'''
transfer_layer:
  - name     : Visa
    type     : Visa
    init     :
        resource_name : ASRL1::INSTR
        read_termination : "\\n"
        write_termination : "\\r\\n"
        backend : "{k2602def_yaml}@sim"

hw_drivers:
  - name      : Sourcemeter
    type      : scpi
    interface : Visa
    init      :
        device : Keithley 2602a
        enable_formatting: true
        enable_binary_commands: true
        binary_mode: true
'''
test_binary_stream = b"#0\x00\x00\x00`\x11\'t>\x00\x00\x00\xc0s\x1at>\x00\x00\x00@\x00)t>\x00\x00\x00\x00\x961t>\x00\x00\x00\xc0\xd2$t>\x00\x00\x00`a3t>\x00\x00\x00 \x13)t>\x00\x00\x00\xe0\xcf)t>\x00\x00\x00\x80\x8d$t>\x00\x00\x00\x00\x98$t>\x00\x00\x00\x00U1t>\x00\x00\x00\xe0\x01,t>\x00\x00\x00\xe0\xe5\x14t>\x00\x00\x00\xa0\xbb2t>\x00\x00\x00\x80\xf1\x1at>\x00\x00\x00\xc0x1t>\x00\x00\x00@\x8b3t>\x00\x00\x00@\xa6\'t>\x00\x00\x00`u\x0ft>\x00\x00\x00`5At>\x00\x00\x00\x00J\'t>\x00\x00\x00\x00\xd0(t>\x00\x00\x00\x00\xd6\x1ct>\x00\x00\x00\x00\x1c&t>\x00\x00\x00`2*t>\x00\x00\x00`\x90-t>\x00\x00\x00\x80\xf0!t>\x00\x00\x00\xa0g3t>\x00\x00\x00\x80\xc1\'t>\x00\x00\x00 \xa45t>\x00\x00\x00\xa0\xd7-t>\x00\x00\x00\xa0o\'t>\x00\x00\x00 M.t>\x00\x00\x00`\x94 t>\x00\x00\x00`\xbd&t>\x00\x00\x00 54t>\x00\x00\x00 +#t>\x00\x00\x00@\x00)t>\x00\x00\x00@ \x17t>\x00\x00\x00`;&t>\n"



expected_test_result = [
    7.50743183e-08,
    7.48907354e-08,
    7.51024487e-08,
    7.52273763e-08,
    7.50416547e-08,
    7.52534888e-08,
    7.51035216e-08,
    7.51142508e-08,
    7.50377183e-08,
    7.50383151e-08,
    7.52236815e-08,
    7.51461968e-08,
    7.48099112e-08,
    7.52440670e-08,
    7.48978835e-08,
    7.52257137e-08,
    7.52558691e-08,
    7.50827809e-08,
    7.47307567e-08,
    7.54547145e-08,
    7.50775371e-08,
    7.50997060e-08,
    7.49254241e-08,
    7.50603704e-08,
    7.51198499e-08,
    7.51688489e-08,
    7.49996900e-08,
    7.52538440e-08,
    7.50843299e-08,
    7.52863869e-08,
    7.51728990e-08,
    7.50796758e-08,
    7.51795781e-08,
    7.49799014e-08,
    7.50695435e-08,
    7.52655254e-08,
    7.50175744e-08,
    7.51024487e-08,
    7.48423332e-08,
    7.50621538e-08
]

n = 40

# will only simulate the case that binary readout is enabled!
# no test for switching it off dynamically as the simulation framework pyvisa does not allow for such complex requests.
# but first of all I will need the output of the SMU as it is to be expected!
class TestSimScpiBinary(unittest.TestCase):
    def setUp(self):
        self.cfg = yaml.safe_load(cnfg_yaml)
        self.device = Dut(self.cfg)
        self.device.init()
        self.smu_format = "ASCII"
        self.interesting_message = False

        # Will need to Monkey-Patch the implementation as subclassing is not working due to internals.
        self._orig_write = self.device["Sourcemeter"]._intf._resource.write
        self._orig_query = self.device["Sourcemeter"]._intf._resource.query
        self._orig_query_binary_values = self.device["Sourcemeter"]._intf._resource.query_binary_values
        self._orig_read_raw = self.device["Sourcemeter"]._intf._resource._read_raw
        _orig_write = self._orig_write
        _orig_query = self._orig_query
        _orig_query_binary_values = self._orig_query_binary_values
        _orig_read_raw = self._orig_read_raw

        def write(message):
            print("THIS IS A WRITE TEST!")
            # Intercept the format configuration command
            if 'FORMAT.DATA' in message.upper():
                if 'BIN' in message.upper() or 'REAL' in message.upper():
                    self.smu_format = "BINARY"
                else:
                    self.smu_format = "ASCII"
                return "OK"
            if "printbuffer(1, smua.measure.count, smua.nvbuffer1)" in message.lower() or \
                    "printbuffer(2, smua.measure.count, smua.nvbuffer1)" in message.lower() or \
                    "printbuffer(1, smub.measure.count, smub.nvbuffer1)" in message.lower() or \
                    "printbuffer(2, smub.measure.count, smub.nvbuffer1)" in message.lower() or \
                    "printbuffer(1, smua.measure.count, smua.nvbuffer2)" in message.lower() or \
                    "printbuffer(2, smua.measure.count, smua.nvbuffer2)" in message.lower() or \
                    "printbuffer(1, smub.measure.count, smub.nvbuffer2)" in message.lower() or \
                    "printbuffer(2, smub.measure.count, smub.nvbuffer2)" in message.lower():
                self.interesting_message = True
                if isinstance(message, bytes):
                    return len(message)
                return len(message.encode())
            # Fall back to standard YAML behaviour for other writes
            return _orig_write(message)

        def read_raw(*args, **kwargs):
            # Intercept the identical query syntax and branch based state
            if self.interesting_message:
                self.interesting_message = False
                if self.smu_format == "BINARY":
                    # Example: Return IEEE 488.2 arbitrary block data
                    # #I4 followed by 4 bytes representing float 1.0 (e.g.
                    return bytearray(test_binary_stream)
                else:
                    # Return standard ASCII string representation
                    return test_ascii_stream.encode()

            # Fall back to standard YAML queries for everything else
            return _orig_read_raw(*args, **kwargs)

        self.device["Sourcemeter"]._intf._resource.write = write
        self.device["Sourcemeter"]._intf._resource._read_raw = read_raw

        # Check that formatting is present
        self.assertTrue(self.device["Sourcemeter"].has_formatting)
        # Check that formatting is enabled after init
        self.assertTrue(self.device["Sourcemeter"].formatting_enabled)

    def tearDown(self):
        self.device.close()

    def test_read_voltage(self):
        voltage = self.device["Sourcemeter"].get_voltage(channel=1)
        self.assertEqual(voltage, "-5.124E-05")

    def test_read_voltage_unformatted(self):
        # Check that formatting is enabled
        self.assertTrue(self.device["Sourcemeter"].formatting_enabled)

        # Disable formatting
        self.device["Sourcemeter"].disable_formatting()
        voltage = self.device["Sourcemeter"].get_voltage(channel=1).split(",")[0]
        self.assertEqual(voltage, "-5.124E-05")

        # Check that formatting is disabled
        self.assertFalse(self.device["Sourcemeter"].formatting_enabled)

        # Enable formatting
        self.device["Sourcemeter"].enable_formatting()

    def test_read_current(self):
        voltage = self.device["Sourcemeter"].get_current(channel=1)
        self.assertEqual(voltage, "-5.124E-05")

    def test_read_current_unformatted(self):
        # Check that formatting is enabled
        self.assertTrue(self.device["Sourcemeter"].formatting_enabled)

        # Disable formatting
        self.device["Sourcemeter"].disable_formatting()
        voltage = self.device["Sourcemeter"].get_current(channel=1).split(",")[0]
        self.assertEqual(voltage, "-5.124E-05")

        # Check that formatting is disabled
        self.assertFalse(self.device["Sourcemeter"].formatting_enabled)

        # Enable formatting
        self.device["Sourcemeter"].enable_formatting()

    def test_read_current_binary(self):
        # Check that binary is enabled
        self.assertTrue(self.device["Sourcemeter"].has_binary_command)
        self.assertTrue(self.device["Sourcemeter"].binary_query_enabled)

        # set the device to binary
        self.device["Sourcemeter"].binary_format()

        voltages = self.device["Sourcemeter"].get_multi_current(channel=1, binary_enabled=True, data_points=n)
        if voltages.shape[0] > n:
            offset = int(voltages.shape[0] % n)
            shift = int(voltages.shape[0] // n)
            voltages = voltages[offset::shift]
        self.assertTrue(np.allclose(voltages, expected_test_result))

    def test_measure_current_binary(self):
        # Check that binary is enabled
        self.assertTrue(self.device["Sourcemeter"].has_binary_command)
        self.assertTrue(self.device["Sourcemeter"].binary_query_enabled)

        # set the device to binary
        self.device["Sourcemeter"].binary_format()

        voltages = self.device["Sourcemeter"].get_advanced_current(channel=2, binary_enabled=True, data_points=n)
        if voltages.shape[0] > n:
            offset = int(voltages.shape[0] % n)
            shift = int(voltages.shape[0] // n)
            voltages = voltages[offset::shift]
        self.assertTrue(np.allclose(voltages, expected_test_result))

    def test_read_current_ascii(self):
        # Check that binary is enabled
        self.assertTrue(self.device["Sourcemeter"].has_binary_command)
        self.device["Sourcemeter"].disable_binary_query()
        self.assertFalse(self.device["Sourcemeter"].binary_query_enabled)

        # set the device to binary
        self.device["Sourcemeter"].text_format()

        voltages = self.device["Sourcemeter"].get_multi_current(channel=1, data_points=n)
        voltages = np.array(voltages.split(','), dtype=np.float64)
        self.assertTrue(np.allclose(voltages, expected_test_result))

    def test_measure_current_ascii(self):
        # Check that binary is enabled
        self.assertTrue(self.device["Sourcemeter"].has_binary_command)
        self.assertTrue(self.device["Sourcemeter"].binary_query_enabled)

        # set the device to binary
        self.device["Sourcemeter"].text_format()

        voltages = self.device["Sourcemeter"].get_advanced_current(channel=2, data_points=n)
        voltages = np.array(voltages.split(','), dtype=np.float64)
        self.assertTrue(np.allclose(voltages, expected_test_result))

    def test_read_voltage_binary(self):
        # Check that binary is enabled
        self.assertTrue(self.device["Sourcemeter"].has_binary_command)
        self.assertTrue(self.device["Sourcemeter"].binary_query_enabled)

        # set the device to binary
        self.device["Sourcemeter"].binary_format()

        voltages = self.device["Sourcemeter"].get_multi_voltage(channel=1, binary_enabled=True, data_points=n)
        if voltages.shape[0] > n:
            offset = int(voltages.shape[0] % n)
            shift = int(voltages.shape[0] // n)
            voltages = voltages[offset::shift]
        self.assertTrue(np.allclose(voltages, expected_test_result))

    def test_measure_voltage_binary(self):
        # Check that binary is enabled
        self.assertTrue(self.device["Sourcemeter"].has_binary_command)
        self.assertTrue(self.device["Sourcemeter"].binary_query_enabled)

        # set the device to binary
        self.device["Sourcemeter"].binary_format()

        voltages = self.device["Sourcemeter"].get_advanced_voltage(channel=2, binary_enabled=True, data_points=n)
        if voltages.shape[0] > n:
            offset = int(voltages.shape[0] % n)
            shift = int(voltages.shape[0] // n)
            voltages = voltages[offset::shift]
        self.assertTrue(np.allclose(voltages, expected_test_result))

    def test_read_voltage_ascii(self):
        # Check that binary is enabled
        self.assertTrue(self.device["Sourcemeter"].has_binary_command)
        self.device["Sourcemeter"].disable_binary_query()
        self.assertFalse(self.device["Sourcemeter"].binary_query_enabled)

        # set the device to binary
        self.device["Sourcemeter"].text_format()

        voltages = self.device["Sourcemeter"].get_multi_voltage(channel=1, data_points=n)
        voltages = np.array(voltages.split(','), dtype=np.float64)
        self.assertTrue(np.allclose(voltages, expected_test_result))

    def test_measure_voltage_ascii(self):
        # Check that binary is enabled
        self.assertTrue(self.device["Sourcemeter"].has_binary_command)
        self.assertTrue(self.device["Sourcemeter"].binary_query_enabled)

        # set the device to binary
        self.device["Sourcemeter"].text_format()

        voltages = self.device["Sourcemeter"].get_advanced_voltage(channel=2, data_points=n)
        voltages = np.array(voltages.split(','), dtype=np.float64)
        self.assertTrue(np.allclose(voltages, expected_test_result))

if __name__ == '__main__':
    unittest.main()
