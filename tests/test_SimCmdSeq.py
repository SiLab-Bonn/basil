#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

import unittest
import os

import numpy as np

from basil.dut import Dut
from basil.utils.sim.utils import cocotb_compile_and_run, cocotb_compile_clean

max_cmd_byte_size = 2048
max_cmd_size = max_cmd_byte_size * 8
max_rec_size = 2048 * 8 * 4
rec_add_size = 100

cnfg_yaml = """
transfer_layer:
  - name  : INTF
    type  : SiSim
    init:
        host : localhost
        port  : 12345

hw_drivers:
  - name      : PULSE_GEN
    type      : pulse_gen
    interface : INTF
    base_addr : 0x0000

  - name      : CMD_SEQ
    type      : cmd_seq
    interface : INTF
    base_addr : 0x1000

  - name      : SEQ_REC
    type      : seq_rec
    interface : INTF
    mem_size  : {}
    base_addr : 0x2000

""".format(max_rec_size)


class TestSimSeq(unittest.TestCase):
    def setUp(self):
        cocotb_compile_and_run([os.path.join(os.path.dirname(__file__), 'test_SimCmdSeq.v')])

        self.chip = Dut(cnfg_yaml)
        self.chip.init()

    @unittest.skip("saving CPU time")
    def test_basic_io(self):
        self.chip['CMD_SEQ']['OUTPUT_MODE'] = 0
        self.chip['CMD_SEQ']['OUTPUT_ENABLE'] = 0x01
        self.chip['SEQ_REC']['EN_EXT_START'] = 1
        self.chip['CMD_SEQ']['EN_EXT_TRIGGER'] = 1
        self.chip['PULSE_GEN']['DELAY'] = 1
        self.chip['PULSE_GEN']['WIDTH'] = 1

        for cmd_pattern in [0x00, np.random.randint(1, 255), 0xFF]:
            for cmd_size in [0, 1, 2, np.random.randint(3, max_cmd_size - 1), max_cmd_size - 1, max_cmd_size]:
                # cmd_size of 0 will not start cmd_seq
                if isinstance(cmd_pattern, list):
                    write_cmd_pattern = list(cmd_pattern)  # copy
                    write_cmd_pattern.extend(np.random.randint(0, 256, size=max_cmd_byte_size - len(write_cmd_pattern)))
                    self.chip['CMD_SEQ'].set_data(data=write_cmd_pattern, addr=0)
                else:
                    write_cmd_pattern = [cmd_pattern] * max_cmd_byte_size
                    self.chip['CMD_SEQ'].set_data(data=write_cmd_pattern, addr=0)
                ret = self.chip['CMD_SEQ'].get_data(size=max_cmd_byte_size)
                np.testing.assert_array_equal(ret, write_cmd_pattern)
                # self.assertListEqual(ret.tolist(), write_cmd_pattern)
                self.chip['CMD_SEQ']['CMD_SIZE'] = cmd_size

                rec_size = cmd_size + rec_add_size
                self.chip['SEQ_REC']['SIZE'] = rec_size
                self.chip['PULSE_GEN']['START']

                while not self.chip['CMD_SEQ']['READY']:
                    pass
                while not self.chip['SEQ_REC']['READY']:
                    pass

                ret = self.chip['SEQ_REC'].get_data(size=rec_size)
                expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
                expected_bits = np.unpackbits(expected_arr).flatten()[:cmd_size]
                expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
                np.testing.assert_array_equal(ret, expected_bits)
                # self.assertListEqual(ret.tolist(), expected_bits.tolist())

    @unittest.skip("saving CPU time")
    def test_repeat(self):
        self.chip['CMD_SEQ']['OUTPUT_MODE'] = 0
        self.chip['CMD_SEQ']['OUTPUT_ENABLE'] = 0x01
        self.chip['SEQ_REC']['EN_EXT_START'] = 1
        self.chip['CMD_SEQ']['EN_EXT_TRIGGER'] = 1
        self.chip['PULSE_GEN']['DELAY'] = 1
        self.chip['PULSE_GEN']['WIDTH'] = 1

        for cmd_pattern in [0x00, np.random.randint(0, 256, size=max_cmd_byte_size).tolist(), 0xFF]:
            for cmd_size in [0, 1, 2, np.random.randint(3, max_cmd_size - 1), max_cmd_size - 1, max_cmd_size]:  # 0 will prevent writing command
                # cmd_size of 0 will not start cmd_seq
                for cmd_repeat in [1, 2, 3]:
                    # when cmd_repeat is 0 -> infinite loop
                    if isinstance(cmd_pattern, list):
                        write_cmd_pattern = list(cmd_pattern)  # copy
                        write_cmd_pattern.extend(np.random.randint(0, 256, size=max_cmd_byte_size - len(write_cmd_pattern)))
                        self.chip['CMD_SEQ'].set_data(data=write_cmd_pattern, addr=0)
                    else:
                        write_cmd_pattern = [cmd_pattern] * max_cmd_byte_size
                        self.chip['CMD_SEQ'].set_data(data=write_cmd_pattern, addr=0)
                    self.chip['CMD_SEQ']['CMD_SIZE'] = cmd_size
                    self.chip['CMD_SEQ']['CMD_REPEAT'] = cmd_repeat

                    rec_size = cmd_size * cmd_repeat + rec_add_size
                    self.chip['SEQ_REC']['SIZE'] = rec_size
                    self.chip['PULSE_GEN']['START']

                    while not self.chip['CMD_SEQ']['READY']:
                        pass
                    while not self.chip['SEQ_REC']['READY']:
                        pass

                    ret = self.chip['SEQ_REC'].get_data(size=rec_size)
                    expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
                    expected_bits = np.unpackbits(expected_arr).flatten()[:cmd_size]
                    expected_bits = np.tile(expected_bits, cmd_repeat)
                    expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
                    np.testing.assert_array_equal(ret, expected_bits)
                    # self.assertTrue(ret.tolist(), expected_bits.tolist())

    @unittest.skip("saving CPU time")
    def test_start_sequnce(self):
        cmd_pattern = np.random.randint(0, 256, size=max_cmd_byte_size).tolist()
        if isinstance(cmd_pattern, list):
            write_cmd_pattern = list(cmd_pattern)  # copy
            write_cmd_pattern.extend(np.random.randint(0, 256, size=max_cmd_byte_size - len(write_cmd_pattern)))
            self.chip['CMD_SEQ'].set_data(data=write_cmd_pattern, addr=0)
        else:
            write_cmd_pattern = [cmd_pattern] * max_cmd_byte_size
            self.chip['CMD_SEQ'].set_data(data=write_cmd_pattern, addr=0)

        self.chip['CMD_SEQ']['OUTPUT_MODE'] = 0
        self.chip['CMD_SEQ']['OUTPUT_ENABLE'] = 0x01
        self.chip['SEQ_REC']['EN_EXT_START'] = 1
        self.chip['CMD_SEQ']['EN_EXT_TRIGGER'] = 1
        self.chip['PULSE_GEN']['DELAY'] = 1
        self.chip['PULSE_GEN']['WIDTH'] = 1

        for cmd_size in [1, 2, np.random.randint(3, max_cmd_size - 1), max_cmd_size - 1, max_cmd_size]:
            # cmd_size of 0 will not start cmd_seq
            for cmd_repeat in [1, 2, 3]:
                # when cmd_repeat is 0 -> infinite loop
                for cmd_start_sequnce_length in [0, 1, np.random.randint(1, cmd_size + 2), cmd_size - 1, cmd_size, cmd_size + 1]:
                    # if cmd_start_sequnce_length > cmd_size, cmd_seq will not start
                    self.chip['CMD_SEQ']['CMD_SIZE'] = cmd_size
                    self.chip['CMD_SEQ']['CMD_REPEAT'] = cmd_repeat
                    self.chip['CMD_SEQ']['START_SEQUENCE_LENGTH'] = cmd_start_sequnce_length
                    self.chip['CMD_SEQ']['STOP_SEQUENCE_LENGTH'] = 0

                    if cmd_start_sequnce_length <= cmd_size:
                        rec_size = cmd_start_sequnce_length + (cmd_size - cmd_start_sequnce_length) * cmd_repeat + rec_add_size
                    else:
                        rec_size = rec_add_size
                    self.chip['SEQ_REC']['SIZE'] = rec_size
                    self.chip['PULSE_GEN']['START']

                    while not self.chip['CMD_SEQ']['READY']:
                        pass
                    while not self.chip['SEQ_REC']['READY']:
                        pass

                    ret = self.chip['SEQ_REC'].get_data(size=rec_size)
                    expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
                    expected_bits = np.unpackbits(expected_arr).flatten()[:cmd_size]
                    if cmd_start_sequnce_length <= cmd_size:
                        expected_bits = np.r_[expected_bits, np.tile(expected_bits[cmd_start_sequnce_length:], cmd_repeat - 1)]
                    else:
                        expected_bits = np.tile(expected_bits, 0)
                    expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
                    np.testing.assert_array_equal(ret, expected_bits)
                    # self.assertListEqual(ret.tolist(), expected_bits.tolist())

    @unittest.skip("saving CPU time")
    def test_stop_sequence(self):
        cmd_pattern = np.random.randint(0, 256, size=max_cmd_byte_size).tolist()
        if isinstance(cmd_pattern, list):
            write_cmd_pattern = list(cmd_pattern)  # copy
            write_cmd_pattern.extend(np.random.randint(0, 256, size=max_cmd_byte_size - len(write_cmd_pattern)))
            self.chip['CMD_SEQ'].set_data(data=write_cmd_pattern, addr=0)
        else:
            write_cmd_pattern = [cmd_pattern] * max_cmd_byte_size
            self.chip['CMD_SEQ'].set_data(data=write_cmd_pattern, addr=0)

        self.chip['CMD_SEQ']['OUTPUT_MODE'] = 0
        self.chip['CMD_SEQ']['OUTPUT_ENABLE'] = 0x01
        self.chip['SEQ_REC']['EN_EXT_START'] = 1
        self.chip['CMD_SEQ']['EN_EXT_TRIGGER'] = 1
        self.chip['PULSE_GEN']['DELAY'] = 1
        self.chip['PULSE_GEN']['WIDTH'] = 1

        for cmd_size in [1, 2, np.random.randint(3, max_cmd_size - 1), max_cmd_size - 1, max_cmd_size]:
            # cmd_size of 0 will not start cmd_seq
            for cmd_repeat in [1, 2, 3]:
                # when cmd_repeat is 0 -> infinite loop
                for cmd_stop_sequnce_length in [0, 1, np.random.randint(1, cmd_size + 2), cmd_size - 1, cmd_size, cmd_size + 1]:
                    # if cmd_stop_sequnce_length > cmd_size, cmd_seq will not start
                    self.chip['CMD_SEQ']['CMD_SIZE'] = cmd_size
                    self.chip['CMD_SEQ']['CMD_REPEAT'] = cmd_repeat
                    self.chip['CMD_SEQ']['START_SEQUENCE_LENGTH'] = 0
                    self.chip['CMD_SEQ']['STOP_SEQUENCE_LENGTH'] = cmd_stop_sequnce_length

                    if cmd_stop_sequnce_length <= cmd_size:
                        rec_size = (cmd_size - cmd_stop_sequnce_length) * cmd_repeat + cmd_stop_sequnce_length * (cmd_repeat if cmd_stop_sequnce_length == 0 else 1) + rec_add_size
                    else:
                        rec_size = rec_add_size
                    self.chip['SEQ_REC']['SIZE'] = rec_size
                    self.chip['PULSE_GEN']['START']

                    while not self.chip['CMD_SEQ']['READY']:
                        pass
                    while not self.chip['SEQ_REC']['READY']:
                        pass

                    ret = self.chip['SEQ_REC'].get_data(size=rec_size)
                    expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
                    expected_bits = np.unpackbits(expected_arr).flatten()[:cmd_size]
                    if cmd_stop_sequnce_length <= cmd_size:
                        expected_bits = np.r_[np.tile(expected_bits[:cmd_size if (cmd_stop_sequnce_length == 0) else -cmd_stop_sequnce_length], cmd_repeat), expected_bits[cmd_size if (cmd_stop_sequnce_length == 0) else -cmd_stop_sequnce_length:]]
                    else:
                        expected_bits = np.tile(expected_bits, 0)
                    expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
                    np.testing.assert_array_equal(ret, expected_bits)
                    # self.assertListEqual(ret.tolist(), expected_bits.tolist())

    # @unittest.skip("saving CPU time")
    def test_start_and_stop_sequence(self):
        cmd_pattern = np.random.randint(0, 256, size=max_cmd_byte_size).tolist()
        if isinstance(cmd_pattern, list):
            write_cmd_pattern = list(cmd_pattern)  # copy
            write_cmd_pattern.extend(np.random.randint(0, 256, size=max_cmd_byte_size - len(write_cmd_pattern)))
            self.chip['CMD_SEQ'].set_data(data=write_cmd_pattern, addr=0)
        else:
            write_cmd_pattern = [cmd_pattern] * max_cmd_byte_size
            self.chip['CMD_SEQ'].set_data(data=write_cmd_pattern, addr=0)

        self.chip['CMD_SEQ']['OUTPUT_MODE'] = 0
        self.chip['CMD_SEQ']['OUTPUT_ENABLE'] = 0x01
        self.chip['SEQ_REC']['EN_EXT_START'] = 1
        self.chip['CMD_SEQ']['EN_EXT_TRIGGER'] = 1
        self.chip['PULSE_GEN']['DELAY'] = 1
        self.chip['PULSE_GEN']['WIDTH'] = 1

        cmd_size = 1
        # cmd_size of 0 will not start cmd_seq
        cmd_repeat = 1
        # when cmd_repeat is 0 -> infinite loop
        cmd_start_sequnce_length = 1
        cmd_stop_sequnce_length = 0
        # if cmd_start_sequnce_length + cmd_stop_sequnce_length > cmd_size, cmd_seq will not start
        self.chip['CMD_SEQ']['CMD_SIZE'] = cmd_size
        self.chip['CMD_SEQ']['CMD_REPEAT'] = cmd_repeat
        self.chip['CMD_SEQ']['START_SEQUENCE_LENGTH'] = cmd_start_sequnce_length
        self.chip['CMD_SEQ']['STOP_SEQUENCE_LENGTH'] = cmd_stop_sequnce_length

        rec_size = 1 + rec_add_size
        self.chip['SEQ_REC']['SIZE'] = rec_size
        self.chip['PULSE_GEN']['START']

        while not self.chip['CMD_SEQ']['READY']:
            pass
        while not self.chip['SEQ_REC']['READY']:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
        expected_bits = np.unpackbits(expected_arr).flatten()[:cmd_size]
        expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
        np.testing.assert_array_equal(ret, expected_bits)
        # self.assertListEqual(ret.tolist(), expected_bits.tolist())

        cmd_start_sequnce_length = 0
        cmd_stop_sequnce_length = 1
        self.chip['CMD_SEQ']['START_SEQUENCE_LENGTH'] = cmd_start_sequnce_length
        self.chip['CMD_SEQ']['STOP_SEQUENCE_LENGTH'] = cmd_stop_sequnce_length

        self.chip['PULSE_GEN']['START']

        while not self.chip['CMD_SEQ']['READY']:
            pass
        while not self.chip['SEQ_REC']['READY']:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
        expected_bits = np.unpackbits(expected_arr).flatten()[:cmd_size]
        expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
        np.testing.assert_array_equal(ret, expected_bits)
        # self.assertListEqual(ret.tolist(), expected_bits.tolist())

        cmd_start_sequnce_length = 1
        cmd_stop_sequnce_length = 1
        self.chip['CMD_SEQ']['START_SEQUENCE_LENGTH'] = cmd_start_sequnce_length
        self.chip['CMD_SEQ']['STOP_SEQUENCE_LENGTH'] = cmd_stop_sequnce_length

        self.chip['PULSE_GEN']['START']

        while not self.chip['CMD_SEQ']['READY']:
            pass
        while not self.chip['SEQ_REC']['READY']:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
        expected_bits = np.unpackbits(expected_arr).flatten()[:0]
        expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
        np.testing.assert_array_equal(ret, expected_bits)
        # self.assertListEqual(ret.tolist(), expected_bits.tolist())

        cmd_repeat = 2
        cmd_start_sequnce_length = 1
        cmd_stop_sequnce_length = 0
        self.chip['CMD_SEQ']['CMD_REPEAT'] = cmd_repeat
        self.chip['CMD_SEQ']['START_SEQUENCE_LENGTH'] = cmd_start_sequnce_length
        self.chip['CMD_SEQ']['STOP_SEQUENCE_LENGTH'] = cmd_stop_sequnce_length

        self.chip['PULSE_GEN']['START']

        while not self.chip['CMD_SEQ']['READY']:
            pass
        while not self.chip['SEQ_REC']['READY']:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
        expected_bits = np.unpackbits(expected_arr).flatten()[:cmd_size]
        expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
        np.testing.assert_array_equal(ret, expected_bits)
        # self.assertListEqual(ret.tolist(), expected_bits.tolist())

        cmd_start_sequnce_length = 0
        cmd_stop_sequnce_length = 1
        self.chip['CMD_SEQ']['START_SEQUENCE_LENGTH'] = cmd_start_sequnce_length
        self.chip['CMD_SEQ']['STOP_SEQUENCE_LENGTH'] = cmd_stop_sequnce_length

        self.chip['PULSE_GEN']['START']

        while not self.chip['CMD_SEQ']['READY']:
            pass
        while not self.chip['SEQ_REC']['READY']:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
        expected_bits = np.unpackbits(expected_arr).flatten()[:cmd_size]
        expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
        np.testing.assert_array_equal(ret, expected_bits)
        # self.assertListEqual(ret.tolist(), expected_bits.tolist())

        cmd_start_sequnce_length = 1
        cmd_stop_sequnce_length = 1
        self.chip['CMD_SEQ']['START_SEQUENCE_LENGTH'] = cmd_start_sequnce_length
        self.chip['CMD_SEQ']['STOP_SEQUENCE_LENGTH'] = cmd_stop_sequnce_length

        self.chip['PULSE_GEN']['START']

        while not self.chip['CMD_SEQ']['READY']:
            pass
        while not self.chip['SEQ_REC']['READY']:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
        expected_bits = np.unpackbits(expected_arr).flatten()[:0]
        expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
        np.testing.assert_array_equal(ret, expected_bits)
        # self.assertListEqual(ret.tolist(), expected_bits.tolist())

        cmd_size = 2
        cmd_repeat = 1
        cmd_start_sequnce_length = 1
        cmd_stop_sequnce_length = 0
        self.chip['CMD_SEQ']['CMD_SIZE'] = cmd_size
        self.chip['CMD_SEQ']['CMD_REPEAT'] = cmd_repeat
        self.chip['CMD_SEQ']['START_SEQUENCE_LENGTH'] = cmd_start_sequnce_length
        self.chip['CMD_SEQ']['STOP_SEQUENCE_LENGTH'] = cmd_stop_sequnce_length

        rec_size = 2 + rec_add_size
        self.chip['SEQ_REC']['SIZE'] = rec_size
        self.chip['PULSE_GEN']['START']

        while not self.chip['CMD_SEQ']['READY']:
            pass
        while not self.chip['SEQ_REC']['READY']:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
        expected_bits = np.unpackbits(expected_arr).flatten()[:cmd_size]
        expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
        np.testing.assert_array_equal(ret, expected_bits)
        # self.assertListEqual(ret.tolist(), expected_bits.tolist())

        cmd_start_sequnce_length = 0
        cmd_stop_sequnce_length = 1
        self.chip['CMD_SEQ']['START_SEQUENCE_LENGTH'] = cmd_start_sequnce_length
        self.chip['CMD_SEQ']['STOP_SEQUENCE_LENGTH'] = cmd_stop_sequnce_length

        self.chip['PULSE_GEN']['START']

        while not self.chip['CMD_SEQ']['READY']:
            pass
        while not self.chip['SEQ_REC']['READY']:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
        expected_bits = np.unpackbits(expected_arr).flatten()[:cmd_size]
        expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
        np.testing.assert_array_equal(ret, expected_bits)
        # self.assertListEqual(ret.tolist(), expected_bits.tolist())

        cmd_start_sequnce_length = 1
        cmd_stop_sequnce_length = 1
        self.chip['CMD_SEQ']['START_SEQUENCE_LENGTH'] = cmd_start_sequnce_length
        self.chip['CMD_SEQ']['STOP_SEQUENCE_LENGTH'] = cmd_stop_sequnce_length

        self.chip['PULSE_GEN']['START']

        while not self.chip['CMD_SEQ']['READY']:
            pass
        while not self.chip['SEQ_REC']['READY']:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
        expected_bits = np.unpackbits(expected_arr).flatten()[:cmd_size]
        expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
        np.testing.assert_array_equal(ret, expected_bits)
        # self.assertListEqual(ret.tolist(), expected_bits.tolist())

        cmd_start_sequnce_length = 2
        cmd_stop_sequnce_length = 0
        self.chip['CMD_SEQ']['START_SEQUENCE_LENGTH'] = cmd_start_sequnce_length
        self.chip['CMD_SEQ']['STOP_SEQUENCE_LENGTH'] = cmd_stop_sequnce_length

        self.chip['PULSE_GEN']['START']

        while not self.chip['CMD_SEQ']['READY']:
            pass
        while not self.chip['SEQ_REC']['READY']:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
        expected_bits = np.unpackbits(expected_arr).flatten()[:cmd_size]
        expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
        np.testing.assert_array_equal(ret, expected_bits)
        # self.assertListEqual(ret.tolist(), expected_bits.tolist())

        cmd_start_sequnce_length = 0
        cmd_stop_sequnce_length = 2
        self.chip['CMD_SEQ']['START_SEQUENCE_LENGTH'] = cmd_start_sequnce_length
        self.chip['CMD_SEQ']['STOP_SEQUENCE_LENGTH'] = cmd_stop_sequnce_length

        self.chip['PULSE_GEN']['START']

        while not self.chip['CMD_SEQ']['READY']:
            pass
        while not self.chip['SEQ_REC']['READY']:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
        expected_bits = np.unpackbits(expected_arr).flatten()[:cmd_size]
        expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
        np.testing.assert_array_equal(ret, expected_bits)
        # self.assertListEqual(ret.tolist(), expected_bits.tolist())

        cmd_start_sequnce_length = 2
        cmd_stop_sequnce_length = 1
        self.chip['CMD_SEQ']['START_SEQUENCE_LENGTH'] = cmd_start_sequnce_length
        self.chip['CMD_SEQ']['STOP_SEQUENCE_LENGTH'] = cmd_stop_sequnce_length

        self.chip['PULSE_GEN']['START']

        while not self.chip['CMD_SEQ']['READY']:
            pass
        while not self.chip['SEQ_REC']['READY']:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
        expected_bits = np.unpackbits(expected_arr).flatten()[:0]
        expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
        np.testing.assert_array_equal(ret, expected_bits)
        # self.assertListEqual(ret.tolist(), expected_bits.tolist())

        cmd_start_sequnce_length = 1
        cmd_stop_sequnce_length = 2
        self.chip['CMD_SEQ']['START_SEQUENCE_LENGTH'] = cmd_start_sequnce_length
        self.chip['CMD_SEQ']['STOP_SEQUENCE_LENGTH'] = cmd_stop_sequnce_length

        self.chip['PULSE_GEN']['START']

        while not self.chip['CMD_SEQ']['READY']:
            pass
        while not self.chip['SEQ_REC']['READY']:
            pass

        ret = self.chip['SEQ_REC'].get_data(size=rec_size)
        expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
        expected_bits = np.unpackbits(expected_arr).flatten()[:0]
        expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
        np.testing.assert_array_equal(ret, expected_bits)
        # self.assertListEqual(ret.tolist(), expected_bits.tolist())

        for _ in range(1):
            cmd_size = np.random.randint(2, max_cmd_size + 1)
            # cmd_size of 0 will not start cmd_seq
            cmd_repeat = np.random.randint(1, 4)
            # when cmd_repeat is 0 -> infinite loop
            cmd_start_sequnce_length = np.random.randint(0, cmd_size + 1)
            cmd_stop_sequnce_length = np.random.randint(0, cmd_size - cmd_start_sequnce_length + 1)
            self.chip['CMD_SEQ']['CMD_SIZE'] = cmd_size
            self.chip['CMD_SEQ']['CMD_REPEAT'] = cmd_repeat
            self.chip['CMD_SEQ']['START_SEQUENCE_LENGTH'] = cmd_start_sequnce_length
            self.chip['CMD_SEQ']['STOP_SEQUENCE_LENGTH'] = cmd_stop_sequnce_length

            rec_size = cmd_start_sequnce_length + (cmd_size - cmd_stop_sequnce_length - cmd_start_sequnce_length) * cmd_repeat + cmd_stop_sequnce_length + rec_add_size
            self.chip['SEQ_REC']['SIZE'] = rec_size
            self.chip['PULSE_GEN']['START']

            while not self.chip['CMD_SEQ']['READY']:
                pass
            while not self.chip['SEQ_REC']['READY']:
                pass

            ret = self.chip['SEQ_REC'].get_data(size=rec_size)
            expected_arr = np.array(write_cmd_pattern, dtype=np.uint8)
            cmd_bits = np.unpackbits(expected_arr).flatten()[:cmd_size]
            expected_bits = np.r_[cmd_bits[:cmd_start_sequnce_length]]
            expected_bits = np.r_[expected_bits, np.tile(cmd_bits[cmd_start_sequnce_length:cmd_size if (cmd_stop_sequnce_length == 0) else -cmd_stop_sequnce_length], cmd_repeat)]
            expected_bits = np.r_[expected_bits, cmd_bits[cmd_size if (cmd_stop_sequnce_length == 0) else -cmd_stop_sequnce_length:]]
            expected_bits = np.r_[expected_bits, [0] * (rec_size - len(expected_bits))]
            np.testing.assert_array_equal(ret, expected_bits)
            # self.assertListEqual(ret.tolist(), expected_bits.tolist())

    def tearDown(self):
        self.chip.close()  # let it close connection and stop simulator
        cocotb_compile_clean()


if __name__ == '__main__':
    unittest.main()
