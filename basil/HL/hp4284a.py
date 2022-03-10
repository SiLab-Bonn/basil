#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import logging
from basil.HL.scpi import scpi


def get_meas_func(self, meas_func):
    """
    Function that dynamically generates property getters for measurement functions defined in hp4284A.MEAS_FUNCS

    Parameters
    ----------
    meas_func : str
        Name of measurement function; all keys of self.MEAS_FUNCS are valid
    """

    def property_getter(self):
        """
        Generate the property getter function

        Returns
        -------
        tuple
            Tuple of floats; primary and secondary measurment quantities according to the respective *meas_func*

        Raises
        ------
        KeyError
            *meas_func* is unkown aka not a key of self.MEAS_FUNCS
        RuntimeError
            The measurement status indicates an error
        """
        # Check if *meas_func* is valid
        if meas_func not in self.MEAS_FUNCS:
            raise KeyError(f"Unknown measurment function {meas_func}")

        # Check current function; if needed change functions
        if meas_func != self.get_meas_func().strip():
            logging.info(f"Setting measurement function to {meas_func}")
            self.set_meas_func(meas_func)

        # Check if a manual trigger is needed and trigger if so
        self._check_trigger()

        # Get primary and secondary measurement quantities as well as the measurement status
        primary_meas, secondary_meas, meas_status = self.get_value().strip().split(',')

        # Check status
        if meas_status != '+0':
            if meas_status not in self.ERROR_STATES:
                err_msg = f"Unknown measurement status {meas_status} retrieved"
            else:
                err_msg = self.ERROR_STATES[meas_status]
            raise RuntimeError(err_msg)

        return (float(primary_meas), float(secondary_meas))

    return property_getter


class hp4284A(scpi):
    """
    Interface to the Hewlett-Packard Precision LCR-meter with additional functionality.
    Manual: https://wiki.epfl.ch/carplat/documents/hp4284a_lcr_manual.pdf
    """

    # Available measurement functions; see manual 8-24, p.264
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

    # Measurement error states; see manual 7-8, p.208
    ERROR_STATES = {
        '-1': "No data (in the data buffer memory)",
        '+1': "Analog bridge is unbalanced",
        '+2': "A/D converter is not working",
        '+3': "Signal source overloaded",
        '+4': "ALC unable to regulate"
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

    def __init__(self, intf, conf):
        super(hp4284A, self).__init__(intf, conf)

        # Add getters for all measurement functions
        for mf in self.MEAS_FUNCS:
            self.__add_meas_func_getters(meas_func=mf, getter_func=get_meas_func(self, mf))

    @classmethod
    def __add_meas_func_getters(cls, meas_func, getter_func):
        """
        Classmethod that adds property getters for a given getter function

        Parameters
        ----------
        meas_func : str
            Name of the measurment function. This name corresponds to the property name aka cls.meas_func
        getter_func : callable
            The getter function of the corresponding meas_func
        """
        setattr(cls, meas_func, property(getter_func))

    def _is_min_max(self, val):
        return val in ('MIN', 'MAX')

    def _check_trigger(self):
        if self.get_trigger_mode().strip() == 'HOLD':
            self.trigger()
