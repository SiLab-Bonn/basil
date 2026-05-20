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

    Captured data is read via the dedicated FIFO output ports (not the register
    bus). At the system level, these feed into a SiTCP FIFO stream accessed
    through daq["fifo0"].get_data().
    """

    _registers = {
        "RESET": {"descr": {"addr": 0, "size": 8, "properties": ["writeonly"]}},
        "VERSION": {"descr": {"addr": 0, "size": 8, "properties": ["ro"]}},
        "EN": {"descr": {"addr": 2, "size": 1, "offset": 0}},
        "LOST_COUNT": {"descr": {"addr": 3, "size": 8, "properties": ["ro"]}},
    }
    _require_version = "==0"

    def __init__(self, intf, conf):
        super(fast_spi_rx, self).__init__(intf, conf)
        # DATA_SIZE: number of bits for SPI data in the FIFO output
        # Must match the DATA_SIZE parameter in the FPGA firmware
        self._data_size = conf.get("DATA_SIZE", 16)  # default 16 for backward compatibility
        if self._data_size < 1 or self._data_size > 28:
            raise ValueError("DATA_SIZE must be between 1 and 28")

    def set_size(self, value):
        """Set the Python-only DATA_SIZE attribute tracking the SPI data width in bits.

        Must match the DATA_SIZE parameter set in the FPGA firmware (fast_spi_rx_core.v).
        Valid range: 1-28.
        """
        if value < 1 or value > 28:
            raise ValueError("DATA_SIZE must be between 1 and 28")
        self._data_size = value

    def get_size(self):
        """Return the DATA_SIZE (SPI data width in bits) used for parsing captured words."""
        return self._data_size

    def reset(self):
        """Soft reset the module. Clears internal counters and shift registers on the next SEQ_CLK edge."""
        self.RESET = 0

    def set_en(self, value):
        """Arm/disarm capture. When enabled, serial data on SDI is captured on each rising edge of SEQ_CLK while SEN is high."""
        self.EN = value

    def get_en(self):
        """Return whether capture is armed (True) or disarmed (False)."""
        return self.EN

    def get_lost_count(self):
        """Return the count of lost data words due to CDC FIFO overflow. Non-zero indicates the capture rate exceeded the readout rate."""
        return self.LOST_COUNT

    def parse_word(self, word):
        """Parse a 32-bit FIFO word into (identifier, frame_counter, spi_data).

        The split between frame counter and captured data is determined
        by get_size(). Useful for parsing words read via daq["fifo0"].get_data().

        Args:
            word: A 32-bit integer from the fast_spi_rx output FIFO.

        Returns:
            tuple: (identifier, frame_counter, spi_data)
        """
        data_size = self.get_size()
        identifier = (word >> 28) & 0xF
        spi_data = word & ((1 << data_size) - 1)
        frame_counter_bits = 28 - data_size
        if frame_counter_bits > 0:
            frame_counter = (word >> data_size) & ((1 << frame_counter_bits) - 1)
        else:
            frame_counter = 0
        return identifier, frame_counter, spi_data
