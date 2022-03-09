#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.scpi import scpi


def get_meas_func(self, meas_func):

    def property_getter(self):
        if meas_func not in self.MEAS_FUNCS:
            raise KeyError(f"Unknown measurment function {meas_func}")

        # Trigger measurement
        self.trigger()

        if meas_func != self.get_meas_func():
            self.set_meas_func(meas_func)

        return tuple(float(val) for val in self.get_value().split(','))
    
    return property_getter


class hp4284A(scpi):
    """
    Interface to the Hewlett-Packard Precision LCR-meter with additional functionality
    """

    # Available measurement functions
    # See https://wiki.epfl.ch/carplat/documents/hp4284a_lcr_manual.pdf
    MEAS_FUNCS = {
        'CPD': "Set function to C_p-D",
        'CPQ': "Set function to C_p-Q",
        'CPG': "Set function to C_p-G",
        'CPRP': "Set function to C_p-R_p",
        'CSD': "Set function to C_s-D",
        'CSQ': "Set function to C_s-Q",
        'CSRS': "Set function to C_s-R_s",
        'LPQ': "Set function to L_p-Q",
        'LPD': "Set function to L_p-D",
        'LPG': "Set function to L_p-G",
        'LPRP': "Set function to L_r-R_p",
        'LSD': "Set function to L_s-D",
        'LSQ': "Set function to L_s-Q",
        'LSRS': "Set function to L_s-R_s",
        'RX': "Set function to R-X",
        'ZTD': "Set function to Z-Theta(deg)",
        'ZTR': "Set function to Z-Theta(rad)",
        'GB': "Set function to G-B",
        'YTD': "Set function to Y-Theta(deg)",
        'YTR': "Set function to Y-Theta(rad)"
    }

    @property
    def ac_voltage(self):
        """
        Read AC voltage

        Returns
        -------
        float
            AC voltage in V
        """
        return float(self.get_ac_voltage())

    @ac_voltage.setter
    def ac_voltage(self, ac):
        """
        Setter of ac_voltage property

        Parameters
        ----------
        ac : float, str
            AC voltage in V. Allowed string values 'MIN'/'MAX' for min/max values.
        """
        self.set_ac_voltage(f'{ac}' if self._is_min_max(ac) else f'{ac} V')

    @property
    def frequency(self):
        """
        Read frequency in Hz

        Returns
        -------
        float
            Frequency in Hz
        """
        return float(self.get_frequency())

    @frequency.setter
    def frequency(self, freq):
        """
        Setter of frequency property

        Parameters
        ----------
        freq : float, str
            Frequency in Hz. Allowed string values 'MIN'/'MAX' for min/max values.
        """
        self.set_frequency(f'{freq}' if self._is_min_max(freq) else f'{freq}HZ')

    @property
    def capacitance(self):
        """
        Getter of capacitance measurement. Checks if corresponding measurement function is set.

        Returns
        -------
        float
            Capacitance

        Raises
        ------
        ValueError
            Measurement function is not set to measure capacitance
        """
        # Check if we selected a function that measures capacitance
        meas_func = self.get_meas_func()

        if 'C' not in meas_func:
            raise ValueError(f"Measurement function is {meas_func}: {self.MEAS_FUNCS[meas_func]}. Cannot measure capacitance.")

        self.trigger()

        return float(self.get_value().split(',')[0])

    @property
    def resistance(self):
        """
        Getter of resistance measurement. Checks if corresponding measurement function is set.

        Returns
        -------
        float
            Resistance

        Raises
        ------
        ValueError
            Measurement function is not set to measure resistance
        """
        # Check if we selected a function that measures capacitance
        meas_func = self.get_meas_func()

        if 'R' not in meas_func:
            raise ValueError(f"Measurement function is {meas_func}: {self.MEAS_FUNCS[meas_func]}. Cannot measure capacitance.")

        self.trigger()

        return float(self.get_value().split(',')[1])

    @property
    def impedance(self):
        """
        Getter of impedance measurement. Checks if corresponding measurement function is set.

        Returns
        -------
        float
            Impedance

        Raises
        ------
        ValueError
            Measurement function is not set to measure impedance
        """
        # Check if we selected a function that measures capacitance
        meas_func = self.get_meas_func()

        if 'Z' not in meas_func:
            raise ValueError(f"Measurement function is {meas_func}: {self.MEAS_FUNCS[meas_func]}. Cannot measure capacitance.")

        self.trigger()

        return float(self.get_value().split(',')[0])

    def __init__(self, intf, conf):
        super(hp4284A, self).__init__(intf, conf)

        # Add getters for all measurement functions
        for mf in self.MEAS_FUNCS:
            self.__add_meas_func_getters(meas_func=mf, getter_func=get_meas_func(self, mf))

    @classmethod
    def __add_meas_func_getters(cls, meas_func, getter_func):
        setattr(cls, meas_func, property(getter_func))

    def _is_min_max(self, val):
        return val in ('MIN', 'MAX')
