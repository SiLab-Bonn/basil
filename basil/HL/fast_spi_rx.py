#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class fast_spi_rx(RegisterHardwareLayer):
    """Fast SPI interface with variable data width support.

    The module outputs 32-bit words containing:
    - IDENTIFIER (4 bits)
    - Frame counter (28 - DATA_SIZE bits)
    - SPI data (DATA_SIZE bits)

    The DATA_SIZE parameter must match the DATA_SIZE parameter used in the
    FPGA firmware (fast_spi_rx_core.v).
    """

    _registers = {
        "RESET": {"descr": {"addr": 0, "size": 8, "properties": ["writeonly"]}},
        "VERSION": {"descr": {"addr": 0, "size": 8, "properties": ["ro"]}},
        "EN": {"descr": {"addr": 2, "size": 1, "offset": 0}},
        "LOST_COUNT": {"descr": {"addr": 3, "size": 8, "properties": ["ro"]}},
        "FIFO_DATA": {"descr": {"addr": 4, "size": 32, "properties": ["ro"]}},
    }
    _require_version = "==0"

    def __init__(self, intf, conf):
        super(fast_spi_rx, self).__init__(intf, conf)
        # DATA_SIZE: number of bits for SPI data in the FIFO output
        # Must match the DATA_SIZE parameter in the FPGA firmware
        self._data_size = conf.get("DATA_SIZE", 16)  # default 16 for backward compatibility
        if self._data_size < 1 or self._data_size > 28:
            raise ValueError("DATA_SIZE must be between 1 and 28")

    @property
    def data_size(self):
        """Return the configured DATA_SIZE."""
        return self._data_size

    def reset(self):
        """Soft reset the module."""
        self.RESET = 0

    def set_en(self, value):
        self.EN = value

    def get_en(self):
        return self.EN

    def get_lost_count(self):
        return self.LOST_COUNT

    def get_data_size(self):
        """Return the configured DATA_SIZE."""
        return self._data_size

    def parse_word(self, word):
        """Parse a 32-bit FIFO word into (identifier, frame_counter, spi_data) tuples.

        Args:
            word: A 32-bit integer from the FIFO.

        Returns:
            tuple: (identifier, frame_counter, spi_data)
        """
        identifier = (word >> 28) & 0xF
        spi_data = word & ((1 << self._data_size) - 1)
        frame_counter_bits = 28 - self._data_size
        if frame_counter_bits > 0:
            frame_counter = (word >> self._data_size) & ((1 << frame_counter_bits) - 1)
        else:
            frame_counter = 0
        return identifier, frame_counter, spi_data

    def get_parsed_data(self):
        """Read and parse FIFO data into (frame_counter, spi_data)."""
        word = self.FIFO_DATA  # Uses register access, reads 4 bytes from addr 4
        if word is None:
            return None, None
        spi_data = word & ((1 << self._data_size) - 1)
        frame_counter_bits = 28 - self._data_size
        if frame_counter_bits > 0:
            frame_counter = (word >> self._data_size) & ((1 << frame_counter_bits) - 1)
        else:
            frame_counter = 0
        return frame_counter, spi_data
