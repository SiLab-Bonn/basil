#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest
from unittest.mock import Mock

from basil.HL.tektronix_oscilloscope import TektronixOscilloscope, response_value


class TestTektronixOscilloscope(unittest.TestCase):
    def setUp(self):
        self.intf = Mock()
        self.intf.query.side_effect = self._query
        self.scope = TektronixOscilloscope(self.intf, {"name": "scope"})
        self.scope._scpi_commands = {
            "set_data_encoding": "DATa:ENCdg",
            "set_data_width": "DATa:WIDth",
            "channel 1": {"get_data": "DATA:SOURCE CH1;:CURVe?"},
            "channel 2": {"get_data": "DATA:SOURCE CH2;:CURVe?"},
        }
        self.scope._scpi_query_fmt = None
        self.scope._formatting_enabled = False

    @staticmethod
    def _query(command):
        responses = {
            "ACQuire:STATE?": "ACQUIRE:STATE 1",
            "horizontal:recordlength?": "HORIZONTAL:RECORDLENGTH 3",
            "WFMOutpre:XINCR?": "WFMOUTPRE:XINCR 1e-9",
            "WFMOutpre:PT_OFF?": "WFMOUTPRE:PT_OFF 1",
            "WFMOutpre:XZERO?": "WFMOUTPRE:XZERO 5e-9",
            "WFMOutpre:XUNIT?": 'WFMOUTPRE:XUNIT "s"',
            "WFMOutpre:YZEro?": "WFMOUTPRE:YZERO 0.1",
            "WFMOutpre:YMUlt?": "WFMOUTPRE:YMULT 0.5",
            "WFMOutpre:YOFF?": "WFMOUTPRE:YOFF 2",
            "CH1:SCALE?": "CH1:SCALE 0.2",
            "CH1:POSITION?": "CH1:POSITION 0",
            "CH2:SCALE?": "CH2:SCALE 0.2",
            "CH2:POSITION?": "CH2:POSITION 0",
            "DATA:SOURCE CH1;:CURVe?": "1,2,3\n",
            "DATA:SOURCE CH2;:CURVe?": "1,2,3\n",
        }
        return responses[command]

    def test_get_waveforms_captures_channels_under_one_stop(self):
        waveforms = self.scope.get_waveforms((1, 2))

        self.assertEqual(list(waveforms), [1, 2])
        self.assertEqual(waveforms[1].raw_data, [1, 2, 3])
        self.assertEqual(waveforms[1].data, [-0.4, 0.1, 0.6])
        self.assertAlmostEqual(waveforms[1].x_scale.slope, 1e-9)
        self.assertAlmostEqual(waveforms[1].x_scale.offset, 4e-9)
        self.assertEqual(waveforms[1].x_scale.unit, "s")

        writes = [call.args[0] for call in self.intf.write.call_args_list]
        self.assertEqual(writes.count("ACQuire:STATE STOP"), 1)
        self.assertEqual(writes[-1], "ACQuire:STATE 1")
        self.assertIn("data:source CH1", writes)
        self.assertIn("data:source CH2", writes)
        self.assertIn("DATa:WIDth 2", writes)
        self.assertFalse(any("CHCH" in command for command in writes))

    def test_get_waveform_preserves_legacy_return_shape(self):
        channel, data, x_scale, y_scale = self.scope.get_waveform(channel=1)

        self.assertEqual(channel, 1)
        self.assertEqual(data, [-0.4, 0.1, 0.6])
        self.assertAlmostEqual(x_scale.offset, 4e-9)
        self.assertEqual(y_scale.top, 1.0)
        self.assertEqual(y_scale.bottom, -1.0)

    def test_response_value_accepts_terse_and_verbose_responses(self):
        self.assertEqual(response_value("0"), "0")
        self.assertEqual(response_value("ACQuire:STATE ON"), "ON")


if __name__ == "__main__":
    unittest.main()
