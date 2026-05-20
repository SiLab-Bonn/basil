#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
"""Serial programming interface (SPI) driver for FPGA-based SPI modules."""

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class spi(RegisterHardwareLayer):
    """Implement serial programming interface (SPI) driver."""

    _registers = {
        "RESET": {"descr": {"addr": 0, "size": 8, "properties": ["writeonly"]}},
        "VERSION": {"descr": {"addr": 0, "size": 8, "properties": ["ro"]}},
        "READY": {"descr": {"addr": 1, "size": 1, "properties": ["ro"]}},
        "START": {"descr": {"addr": 1, "size": 8, "properties": ["writeonly"]}},
        "SIZE": {"descr": {"addr": 3, "size": 16}},
        "WAIT": {"descr": {"addr": 5, "size": 32}},
        "REPEAT": {"descr": {"addr": 9, "size": 32}},
        "EN": {"descr": {"addr": 13, "size": 1}},
        "MEM_BYTES": {"descr": {"addr": 14, "size": 16, "properties": ["ro"]}},
    }
    _require_version = "==2"

    def __init__(self, intf, conf):
        """Initialize SPI driver."""
        super(spi, self).__init__(intf, conf)
        self._spi_mem_offset = 16  # in bytes

    def init(self):
        """Initialize hardware layer and query memory bytes."""
        super(spi, self).init()
        self._mem_bytes = self.MEM_BYTES

    def reset(self):
        """Soft reset the SPI module. Aborts any in-progress transfer, clears internal state."""
        self.RESET = 0

    def start(self):
        """Start shifting data."""
        self.START = 0

    def set_size(self, value):
        """Set the number of clock cycles for shifting in data.

        For example, length of matrix shift register (number of pixels daisy chained).
        """
        self.SIZE = value

    def get_size(self):
        """Get size of shift register length."""
        return self.SIZE

    def set_wait(self, value):
        """Set the time delay between repetitions in clock cycles.

        Time delay between repetitions in clock cycles.
        """
        self.WAIT = value

    def get_wait(self):
        """Get time delay between repetitions in clock cycles."""
        return self.WAIT

    def set_repeat(self, value):
        """Set the number of repetitions of the sequence with delay 'wait'.

        If 0: Repeat sequence forever.
        Otherwise: Number of repetitions of sequence with delay 'wait'.
        """
        self.REPEAT = value

    def get_repeat(self):
        """Get number of repetitions of sequence with delay 'wait' (if 0 --> repeat forever)."""
        return self.REPEAT

    def set_en(self, value):
        """Enable start on external EXT_START signal (inside FPGA).

        When enabled, the SPI transfer starts on the external EXT_START signal.
        """
        self.EN = value

    def get_en(self):
        """Return the enable state."""
        return self.EN

    def is_done(self):
        """Return True if the SPI transfer is complete, False if still in progress.

        Aliases is_ready.
        """
        return self.is_ready

    @property
    def is_ready(self):
        """Read the DONE/READY register at address 1. Returns True when the transfer is complete, False while shifting."""
        return self.READY

    def get_mem_size(self):
        """Return the SPI memory size in bytes (from MEM_BYTES register at address 14-15). This is the maximum single transfer size."""
        return self.MEM_BYTES

    def set_data(self, data, addr=0):
        """Write data to the SPI transmit memory at the bus memory offset.

        Data bytes are shifted out MSB-first on SDI.

        Args:
            data (bytes): Data to write.
            addr (int, optional): Byte offset into memory.

        """
        if self._mem_bytes < len(data):
            raise ValueError("Size of data (%d bytes) is too big for memory (%d bytes)" % (len(data), self._mem_bytes))
        self._intf.write(self._conf["base_addr"] + self._spi_mem_offset + addr, data)

    # This needs to be changed to return written value
    def get_data(self, size=None, addr=None):
        """Read data from the SPI receive memory at the bus memory offset.

        Incoming bytes captured from SDO are stored here.

        Args:
            size (int, optional): Number of bytes to read (default all).
            addr (int, optional): Byte offset into memory.

        """
        # readback memory offset
        if addr is None:
            addr = self._mem_bytes

        if size and self._mem_bytes < size:
            raise ValueError("Size is too big")

        if size is None:
            return self._intf.read(self._conf["base_addr"] + self._spi_mem_offset + addr, self._mem_bytes)
        else:
            return self._intf.read(self._conf["base_addr"] + self._spi_mem_offset + addr, size)
