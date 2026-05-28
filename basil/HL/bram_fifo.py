#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging
from time import sleep

import numpy as np

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer

logger = logging.getLogger(__name__)


class bram_fifo(RegisterHardwareLayer):
    """BRAM-backed FIFO controller.

    The corresponding firmware module stores incoming 32-bit FIFO words in
    FPGA BRAM. The regular ``base_addr`` configuration key addresses the
    control registers, while ``base_data_addr`` must point to the 32-bit data
    window used by :meth:`get_data`.

    ``FIFO_SIZE`` reports the amount of buffered data in bytes. The driver
    rounds this down to complete 32-bit words before reading data.
    """

    _registers = {
        "RESET": {"descr": {"addr": 0, "size": 8, "properties": ["writeonly"]}},
        "VERSION": {"descr": {"addr": 0, "size": 8, "properties": ["ro"]}},
        "ALMOST_FULL_THRESHOLD": {"descr": {"addr": 1, "size": 8}},
        "ALMOST_EMPTY_THRESHOLD": {"descr": {"addr": 2, "size": 8}},
        "READ_ERROR_COUNTER": {"descr": {"addr": 3, "size": 8, "properties": ["ro"]}},
        "FIFO_SIZE": {"descr": {"addr": 4, "size": 32, "properties": ["ro"]}},
    }
    _require_version = "==2"

    def __init__(self, intf, conf):
        """Create a BRAM FIFO driver.

        Parameters
        ----------
        intf : basil transfer layer
            Interface used for control-register and data-window access.
        conf : dict
            Driver configuration. Requires ``base_addr`` for the control
            registers and ``base_data_addr`` for the FIFO data window.
        """
        super(bram_fifo, self).__init__(intf, conf)

    def reset(self):
        """Soft-reset the FIFO and wait briefly for the firmware to settle."""
        self.RESET = 0
        sleep(0.01)  # wait some time for initialization

    @property
    def FIFO_INT_SIZE(self):
        """Get FIFO size in units of integers (32 bit).

        Returns
        -------
        fifo_size : int
            FIFO size in units of integers (32 bit).
        """
        fifo_size = self.FIFO_SIZE
        # sometimes reading of FIFO size happens during writing to BRAM, but we want to have a multiplicity of 32 bits
        return int((fifo_size - (fifo_size % 4)) / 4)

    def get_FIFO_INT_SIZE(self):
        """Get FIFO size in units of integers (32 bit).

        Returns
        -------
        fifo_size : int
            FIFO size in units of integers (32 bit).
        """
        return self.FIFO_INT_SIZE

    def get_data(self):
        """Read all currently buffered complete 32-bit words.

        The method reads ``FIFO_SIZE`` twice and uses the smaller value to
        avoid requesting more data while the FIFO size is changing. Data are
        read from ``base_data_addr`` and returned as little-endian unsigned
        32-bit integers.

        Returns
        -------
        array : numpy.ndarray
            Array of unsigned 32-bit FIFO words.
        """
        fifo_int_size_1 = self.FIFO_INT_SIZE
        fifo_int_size_2 = self.FIFO_INT_SIZE
        if fifo_int_size_1 > fifo_int_size_2:
            fifo_int_size = fifo_int_size_2  # use smaller chunk
            logger.warning("Reading wrong FIFO size. Expected: %d <= %d" % (fifo_int_size_1, fifo_int_size_2))
        else:
            fifo_int_size = fifo_int_size_1  # use smaller chunk
        return np.frombuffer(
            self._intf.read(self._conf["base_data_addr"], size=4 * fifo_int_size), dtype=np.dtype("<u4")
        )  # size in number of bytes
