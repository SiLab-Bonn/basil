#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.scpi import scpi
from collections import namedtuple
from enum import Enum
from pyvisa.errors import VisaIOError

Identity = namedtuple("Identity", "company, model, serial, config")
XScale = namedtuple("XScale", "slope, offset, unit")
YScale = namedtuple("YScale", "top, bottom")
FeatureTable = namedtuple("FeatureTable", "name, entries")
Waveform = namedtuple("Waveform", "data, x_scale, y_scale")


class WaveType(Enum):
    ANALOG = 1
    DIGITAL = 2
    MATH = 3


JobParameters = namedtuple(
    "JobParameters",
    ["wave_type", "channel_name", "encoding", "bit_nr", "data_type", "record_length"],
)


class WaveformCollection:
    def __init__(self):
        self.idn = None
        self.data = {}

    @property
    def sources(self):
        return list(self.data.keys())

    def __getitem__(self, item):
        return self.data[item]

    def __len__(self):
        return len(self.data.keys())


class TektronixOscilloscope(scpi):
    """This class is heavily inspired by:
    https://github.com/tektronix/curvequery/blob/release/curvequery/_tek_series_mso_curve_feat.py"""

    def _make_jobs(self, channel=1):
        """Scan the instrument for available sources of data construct a list of jobs"""

        encoding_table = {
            WaveType.MATH: ("FPBinary", 16, "f"),
            WaveType.DIGITAL: ("RIBinary", 16, "h"),
            WaveType.ANALOG: ("RIBinary", 16, "h"),
        }
        channel_table = {
            WaveType.MATH: lambda x: x,
            WaveType.DIGITAL: lambda x: "_".join([x.split("_")[0], "DALL"]),
            WaveType.ANALOG: lambda x: x,
        }

        results = {}
        sources = ['CH' + str(channel)]
        for source in sources:
            if source.split("_")[0] not in results:
                # Determine the type of waveform and set key interface parameters
                wave_type = self._classify_waveform(source)
                channel = channel_table[wave_type](source)
                encoding, bit_nr, datatype = encoding_table[wave_type]

                # Set the start and stop point of the record
                rec_len = int(self._intf.query("horizontal:recordlength?").strip())

                # Keep track of each super channel and math source that has been handled
                results[source.split("_")[0]] = JobParameters(
                    wave_type, channel, encoding, bit_nr, datatype, rec_len
                )
        return results

    def _classify_waveform(self, source):
        if source[0:4] == "MATH":
            wave_type = WaveType.MATH
        elif "_" in source:
            wave_type = WaveType.DIGITAL
        else:
            wave_type = WaveType.ANALOG
        return wave_type

    def _get_xscale(self):
        """Get the horizontal scale of the instrument"""

        # This function will generate a VISA timeout if there is no waveform data
        # available and the channel is enabled.
        result = None
        try:
            xincr = self._intf.query("WFMOutpre:XINCR?").strip()
        except VisaIOError:
            pass
        else:
            # collect more horizontal data
            pt_off = self._intf.query("WFMOutpre:PT_OFF?").strip()
            xzero = self._intf.query("WFMOutpre:XZERO?").strip()
            xunit = self._intf.query("WFMOutpre:XUNIT?").strip()

            # calculate horizontal scale
            slope = float(xincr)
            offset = float(pt_off) * -slope + float(xzero)
            unit = xunit.strip('"')
            result = XScale(slope, offset, unit)
        return result

    def _get_yscale(self, channel=1):
        scale = float(self._intf.query("{}:SCALE?".format('CH' + str(channel))))
        position = float(self._intf.query("{}:POSITION?".format('CH' + str(channel))))
        top = scale * (5 - position)
        bottom = scale * (-5 - position)
        return YScale(top=top, bottom=bottom)

    def _has_data_available(self, source):
        """Checks that the source seems to have actual data available for download.
        This function should be called before performing a curve query."""
        # Use "display:global:CH{x}:state?" to determine if the channel is displayed
        # and available for download
        if source == "NONE":
            return False
        return bool(int(self._intf.query("display:global:{}:state?".format(source))))

    def _setup_curve_query(self, parameters, channel=1):
        """Setup the instrument for the curve query operation"""

        # extract the job parameters
        wave_type, channel, encoding, bit_nr, datatype, rec_len = parameters['CH' + str(channel)]

        # Switch to the source and setup the data encoding
        self._intf.write("data:source {}".format('CH' + channel))
        self.set_data_encoding('ascii')
        self._intf.write("WFMOUTPRE:BIT_NR {}".format(bit_nr))

        # Set the start and stop point of the record
        rec_len = self._intf.query("horizontal:recordlength?").strip()
        self._intf.write("data:start 1")
        self._intf.write("data:stop {}".format(rec_len))
        return wave_type

    def _post_process_analog(self, source_data, x_scale, channel=1):
        """Post processes analog channel data"""

        # Normal analog channels must have the vertical scale and offset applied
        offset = float(self._intf.query("WFMOutpre:YZEro?"))
        scale = float(self._intf.query("WFMOutpre:YMUlt?"))
        source_data = [scale * i + offset for i in source_data]

        # Include y-scale information with analog channel waveforms
        y_scale = self._get_yscale(channel=channel)

        return channel, source_data, x_scale, y_scale

    def get_waveform(self, channel=1):
        """Returns an iterator that yields the source data from the oscilloscope"""

        jobs = self._make_jobs(channel=channel)

        # remember the state of the acquisition system and then stop acquiring waveforms
        acq_state = self._intf.query("ACQuire:STATE?").strip()
        self._intf.write("ACQuire:STATE STOP")
        wave_type = self._setup_curve_query(jobs, channel=channel)

        # Horizontal scale information
        x_scale = self._get_xscale()
        ret_val = None
        if x_scale is not None:
            source_data = [int(i) for i in self.get_data(channel=channel).replace('\n', '').split(',')]
            if wave_type is WaveType.ANALOG:
                ret_val = self._post_process_analog(source_data, x_scale, channel=channel)
            else:
                raise NotImplementedError(f"Analysis for type {wave_type} data not yet implemented!")

        # # Restore the acquisition state
        self._intf.write("ACQuire:STATE {}".format(acq_state))
        return ret_val
