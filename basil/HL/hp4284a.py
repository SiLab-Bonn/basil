#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.scpi import scpi


class hp4284A(scpi):
    """
    Interface to the Hewlett-Packard Precision LCR-meter with additional functionality
    """

    MEASURE_MODES = ('CPRP', 'ZTD')

    @property
    def frequency(self):
        return float(self.get_frequency())
    
    @frequency.setter
    def frequency(self, freq):
        self.set_frequency(f'{freq}' if freq in ('MIN', 'MAX') else f'{freq}HZ')

    def capacitance(self):
        if self.get_meas_quantity() != self.MEASURE_MODES[0]:
            raise ValueError('')

    def __init__(self, intf, conf):
        super().__init__(intf, conf)
