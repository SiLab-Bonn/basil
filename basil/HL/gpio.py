#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

"""GPIO hardware layer for Basil."""

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class gpio(RegisterHardwareLayer):
    """GPIO interface."""

    def __init__(self, intf, conf):
        """Initialize GPIO interface."""
        self._registers = {
            "RESET": {"descr": {"addr": 0, "size": 8, "properties": ["writeonly"]}},
            "VERSION": {"descr": {"addr": 0, "size": 8, "properties": ["ro"]}},
        }
        self._require_version = "==0"

        self._size = 8
        if "size" in conf.keys():
            self._size = conf["size"]

        io_bytes = int(((self._size - 1) / 8) + 1)

        self._registers["INPUT"] = {"descr": {"addr": 1, "size": io_bytes, "properties": ["ro", "byte_array"]}}
        self._registers["OUTPUT"] = {
            "descr": {"addr": 2 + io_bytes - 1, "size": io_bytes, "properties": ["byte_array"]}
        }
        self._registers["OUTPUT_EN"] = {
            "descr": {"addr": 3 + 2 * (io_bytes - 1), "size": io_bytes, "properties": ["byte_array"]}
        }
        # __init__() after updating register
        super(gpio, self).__init__(intf, conf)

    def init(self):
        """Initialize the hardware."""
        super(gpio, self).init()
        if "output_en" in self._init:
            self.OUTPUT_EN = self._init["output_en"]

    def reset(self):
        """Soft reset the module."""
        self.RESET = 0

    def set_output_en(self, value):
        """
        Set the output enable mask. Each bit enables output mode for the corresponding pin (1=output, 0=high-impedance/input). Requires IO_TRI to be configured in the firmware parameter."""
        self.OUTPUT_EN = value

    def get_output_en(self):
        """Return the output enable mask. Each bit indicates whether the corresponding pin is in output mode (1) or input mode (0)."""
        return self.OUTPUT_EN

    def set_data(self, value):
        """
        Set the GPIO OUTPUT register. Writes the full IO_WIDTH byte to the FPGA, driving output pins to the specified logic levels. Typically used via StdRegister .write() for field-level access."""
        self.OUTPUT = value

    def get_data(self):
        """Read the GPIO INPUT register. Returns the current logic levels on all pins as a byte array. Reads the physical pin state regardless of direction configuration."""
        return self.INPUT
