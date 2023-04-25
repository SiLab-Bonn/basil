#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
import logging
import time
from types import MethodType
from time import sleep
from basil.HL.scpi import scpi


logger = logging.getLogger(__name__)


def _write_with_delay(orig_write, delay=0.2):
    # First arg needed for passing instance
    def wrapper(orig_inst, msg):
        orig_write(msg)
        sleep(delay)

    return wrapper


class keithley6517A(scpi):
    """
    Interface to the Keithley 6517A electrometer with additional functionality.
    Manual: https://download.tek.com/manual/6517A_900_01C.pdf
    """

    def __init__(self, intf, conf):
        super(keithley6517A, self).__init__(intf, conf)

        self._setup_for_current_measurement = False
        self._setup_for_voltage_measurement = False
        self._setup_for_resistance_measurement = False
        self._prev_read_ts = None
        self._read_settle_time = 0.5

    def init(self):
        super(keithley6517A, self).init()
        # Overwrite TL write to add a delay after each write; Keithley 6517A needs this because otherwise errors occur
        self._intf.write = MethodType(_write_with_delay(self._intf.write), self._intf)

    def get_read(self):
        if self._prev_read_ts is not None: 
            elapsed_secs = time.time() - self._prev_read_ts
            if elapsed_secs < self._read_settle_time:
                logger.warning(f"Keithley 6517A may need increased settling time (currently {elapsed_secs:.2f} s) in between reads for precise measurements!")
        self._prev_read_ts = time.time()
        return super(keithley6517A, self).get_read()

    def setup_current_measurement(self, current_range=None, current_limit=None, voltage_range=None, filter=('REP', 10)):
        # See manual p.2-23 ff.
        # Enable zero check before switching functions
        self.zero_check_on()
        # Select current measurement function
        self.select_current()
        # Set lowest range (20 pA) to do zero correction, works by scaling
        self.set_current_range(20e-12)
        # Zero correct
        self.zero_correct_on()
        if current_range is None:
            # Now enable auto range for conveinience
            self.set_current_autorange()
        else:
            self.set_current_range(current_range)
        # Disable zero check
        self.zero_check_off()
        # Set filter to measure average
        self.set_current_filter_type(filter[0])
        self.set_current_filter_count(filter[1])
        self.current_filter_on()
        # No continouous trigger
        self.trigger_conti_off()
        if voltage_range is not None:
            self.set_source_range(voltage_range)
        if current_limit is not None:
            self.set_current_limit(current_limit)

        self._setup_for_current_measurement = True
        self._setup_for_voltage_measurement = False
        self._setup_for_resistance_measurement = False

    def get_current(self):
        if not self._setup_for_current_measurement:
            self.setup_current_measurement()
        res = self.get_read().split(',')[0][:-4]
        return float(res)
