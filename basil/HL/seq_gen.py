#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class seq_gen(RegisterHardwareLayer):
    """Sequence generator controller interface for seq_gen FPGA module."""

    _registers = {
        "RESET": {"descr": {"addr": 0, "size": 8, "properties": ["writeonly"]}},
        "VERSION": {"descr": {"addr": 0, "size": 8, "properties": ["ro"]}},
        "READY": {"descr": {"addr": 1, "size": 1, "properties": ["ro"]}},
        "START": {"descr": {"addr": 1, "size": 8, "properties": ["writeonly"]}},
        "EN_EXT_START": {"descr": {"addr": 2, "size": 1}},
        "CLK_DIV": {"descr": {"addr": 3, "size": 8}},
        "SIZE": {"descr": {"addr": 4, "size": 32}},
        "WAIT": {"descr": {"addr": 8, "size": 32}},
        "REPEAT": {"descr": {"addr": 12, "size": 32}},
        "REPEAT_START": {"descr": {"addr": 16, "size": 32}},
        "NESTED_START": {"descr": {"addr": 20, "size": 32}},
        "NESTED_STOP": {"descr": {"addr": 24, "size": 32}},
        "NESTED_REPEAT": {"descr": {"addr": 28, "size": 32}},
        "MEM_BYTES": {"descr": {"addr": 32, "size": 32, "properties": ["ro"]}},
    }
    _require_version = "==3"

    def __init__(self, intf, conf):
        super(seq_gen, self).__init__(intf, conf)
        self._seq_mem_offset = 64  # in bytes

    def init(self):
        super(seq_gen, self).init()
        self._seq_mem_size = self.get_mem_size()

    def reset(self):
        """Soft reset the sequencer. Clears internal counters and output state on the next clock edge. Must have a rising edge on the sequencer clock before new data is written to memory."""
        self.RESET = 0

    def start(self):
        """Start the sequencer. Writes to the START register (addr 1). The sequence begins on the next SEQ_CLK edge after the write. Only effective when DONE/READY is high (sequence not already running)."""
        self.START = 0

    def set_size(self, value):
        """Set the number of output words in the sequence. Each word contains OUT_BITS (one sample per track). Addresses 4-7."""
        self.SIZE = value

    def get_size(self):
        """Return the configured sequence size in output words."""
        return self.SIZE

    def set_wait(self, value):
        """Set wait cycles inserted between repetitions. Only applies when REPEAT > 0. Addresses 8-11."""
        self.WAIT = value

    def get_wait(self):
        """Return the configured wait cycles between repetitions."""
        return self.WAIT

    def set_clk_divide(self, value):
        """Set the clock division factor for SEQ_CLK. The sequencer advances one step every CLK_DIV + 1 clock cycles. Default: 1 (divide by 1, i.e. full rate). Address 3."""
        self.CLK_DIV = value

    def get_clk_divide(self):
        """Return the clock division factor."""
        return self.CLK_DIV

    def set_repeat_start(self, value):
        """Set the repeat start position. When repeating, the sequence jumps to this position instead of starting from 0. Addresses 16-19."""
        self.REPEAT_START = value

    def get_repeat_start(self):
        """Return the repeat start position."""
        return self.REPEAT_START

    def set_repeat(self, value):
        """Set the repeat count. 0 = repeat forever. The sequence repeats from REP_START (or 0) each time. Addresses 12-15."""
        self.REPEAT = value

    def get_repeat(self):
        """Return the repeat count."""
        return self.REPEAT

    def is_done(self):
        """Return True if the sequencer has finished its sequence (including all repeats), False if running. Aliases is_ready."""
        return self.is_ready

    @property
    def is_ready(self):
        """Read the DONE/READY register (addr 1, bit 0). Returns True when the sequencer
        is idle and ready to accept a new start trigger. While the sequence is running
        (including all configured repetitions) this reads False.

        The ``@property`` decorator makes this an attribute-like access — call it
        without parentheses as ``daq["seq0"].is_ready``, not ``.is_ready()``.

        ``.is_done()`` and ``.get_done()`` are aliases that return the same value.
        """
        return self.READY

    def get_done(self):
        """Alias for is_ready. Returns True if sequencer is finished."""
        return self.is_ready

    def set_en_ext_start(self, value):
        """Enable or disable external start via the SEQ_EXT_START pin. When enabled (1), the SEQ_EXT_START pin rising edge triggers the sequence. When disabled (0), only software .start() works. Address 2."""
        self.EN_EXT_START = value

    def get_en_ext_start(self):
        """Return whether external start is enabled."""
        return self.EN_EXT_START

    def set_nested_start(self, value):
        """Set the nested loop start position. Addresses 20-23."""
        self.NESTED_START = value

    def get_nested_start(self):
        return self.NESTED_START

    def set_nested_stop(self, value):
        """Set the nested loop stop position. Addresses 24-27."""
        self.NESTED_STOP = value

    def get_nested_stop(self):
        return self.NESTED_STOP

    def set_nested_repeat(self, value):
        """Set the nested loop repeat count. 0 = disabled. Addresses 28-31."""
        self.NESTED_REPEAT = value

    def get_nested_repeat(self):
        return self.NESTED_REPEAT

    def get_mem_size(self):
        return self.MEM_BYTES

    def set_data(self, data, addr=0):
        """Write sequencer memory (the pattern data) via the bus interface at the memory offset. Data is interleaved per track by the TrackRegister RL. Args are bytes to write and optional byte address offset."""
        if self._seq_mem_size < len(data):
            raise ValueError(
                "Size of data (%d bytes) is too big for memory (%d bytes)" % (len(data), self._seq_mem_size)
            )
        self._intf.write(self._conf["base_addr"] + self._seq_mem_offset + addr, data)

    def get_data(self, size=None, addr=0):
        """Read sequencer memory (the pattern data) via the bus interface. Returns bytes. Args are number of bytes to read and optional byte address offset."""
        if size and self._seq_mem_size < size:
            raise ValueError("Size is too big")
        if not size:
            return self._intf.read(self._conf["base_addr"] + self._seq_mem_offset + addr, self._seq_mem_size)
        else:
            return self._intf.read(self._conf["base_addr"] + self._seq_mem_offset + addr, size)
