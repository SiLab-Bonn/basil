#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


class pulse_gen(RegisterHardwareLayer):
    """Pulse generator"""

    _registers = {
        "RESET": {"descr": {"addr": 0, "size": 8, "properties": ["writeonly"]}},
        "VERSION": {"descr": {"addr": 0, "size": 8, "properties": ["ro"]}},
        "READY": {"descr": {"addr": 1, "size": 1, "properties": ["ro"]}},
        "START": {"descr": {"addr": 1, "size": 8, "properties": ["writeonly"]}},
        "EN": {"descr": {"addr": 2, "size": 1}},
        "DELAY": {"descr": {"addr": 3, "size": 32}},
        "WIDTH": {"descr": {"addr": 7, "size": 32}},
        "REPEAT": {"descr": {"addr": 11, "size": 32}},
    }
    _require_version = "==3"

    def __init__(self, intf, conf):
        super(pulse_gen, self).__init__(intf, conf)

    def start(self):
        """
        Software start of pulse at random time
        """
        self.START = 0

    def reset(self):
        """Soft reset the pulse generator. Clears internal state on the next clock edge."""
        self.RESET = 0

    def set_delay(self, value):
        """
        Set the pulse delay in clock cycles from start.
        The delay is relative to the start trigger (software .start() or EXT_START pin).
        """
        self.DELAY = value

    def get_delay(self):
        """Return the pulse delay in clock cycles."""
        return self.DELAY

    def set_width(self, value):
        """
        Pulse width in terms of clock cycles
        """
        self.WIDTH = value

    def get_width(self):
        """Return the pulse width in clock cycles."""
        return self.WIDTH

    def set_repeat(self, value):
        """Set the repeat count. 0 = repeat forever. The pulse repeats with the configured DELAY and WIDTH each time. Max 255."""
        self.REPEAT = value

    def get_repeat(self):
        """Return the repeat count."""
        return self.REPEAT

    def is_done(self):
        """Return True if the pulse generator has finished all repetitions, False if still active. Alias of is_ready."""
        return self.is_ready

    @property
    def is_ready(self):
        """Read the READY register (addr 1, bit 0). Returns True when the pulse generator
        is idle and ready to accept a new start trigger. While the pulse is running
        (including all configured repetitions) this reads False.

        The `@property` decorator makes this an attribute-like access — call it
        without parentheses as ``daq["pulse0"].is_ready``, not ``.is_ready()``.

        `.is_done()` is an alias that returns the same value.
        """
        return self.READY

    def set_en(self, value):
        """
        If true: The pulse comes with a fixed delay with respect to the external trigger (EXT_START).
        If false: The pulse comes only at software start.
        """
        self.EN = value

    def get_en(self):
        """
        Return info if pulse starts with a fixed delay w.r.t. shift register finish signal (true) or if it only starts with .start() (false)
        """
        return self.EN
