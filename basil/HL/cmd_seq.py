#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer


output_modes = {
    'PE': 0,  # positive edge (default)
    'NE': 1,  # negative edge
    'MC': 2,  # Manchester Code IEEE 802.3 (for capacitively coupled transmission)
    'MC_THOMAS': 3  # Manchester Code G.E. Thomas
}


class cmd_seq(RegisterHardwareLayer):
    '''FEI4 Command Sequencer Controller Interface for cmd_seq FPGA module.
    '''

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 8, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'START': {'descr': {'addr': 1, 'size': 8, 'properties': ['writeonly']}},
                  'READY': {'descr': {'addr': 1, 'size': 1, 'properties': ['ro']}},
                  'EN_EXT_TRIGGER': {'descr': {'addr': 2, 'size': 1, 'offset': 0}},
                  'OUTPUT_MODE': {'descr': {'addr': 2, 'size': 2, 'offset': 1}},
                  'CLOCK_GATE': {'descr': {'addr': 2, 'size': 1, 'offset': 3}},
                  'CMD_PULSE': {'descr': {'addr': 2, 'size': 1, 'offset': 4}},
                  'CMD_SIZE': {'descr': {'addr': 3, 'size': 16}},
                  'CMD_REPEAT': {'descr': {'addr': 5, 'size': 32}},
                  'START_SEQUENCE_LENGTH': {'descr': {'addr': 9, 'size': 16}},
                  'STOP_SEQUENCE_LENGTH': {'descr': {'addr': 11, 'size': 16}}}
    _require_version = "==0"

    def __init__(self, intf, conf):
        super(cmd_seq, self).__init__(intf, conf)
        self._cmd_mem_offset = 16  # in bytes
        try:
            self._cmd_mem_size = conf['mem_size'] - self._cmd_mem_offset  # in bytes
        except KeyError:
            self._cmd_mem_size = 2048  # default is 2048 bytes, user should be aware of address ranges in FPGA

    def reset(self):
        self.RESET = 0

    def start(self):
        self.START = 0

    def is_done(self):
        return self.is_ready

    @property
    def is_ready(self):
        return self.READY

    def set_ext_trigger(self, value):
        self.EN_EXT_TRIGGER = value

    def set_output_mode(self, value):
        self.OUTPUT_MODE = value

    def set_clock_gate(self, value):
        self.CLOCK_GATE = value

    def set_cmd_pulse(self, value):
        self.CMD_PULSE = value

    def get_size(self):
        return self.CMD_SIZE

    def set_size(self, value):
        self.CMD_SIZE = value

    def get_repeat(self):
        return self.CMD_REPEAT

    def set_repeat(self, value):
        self.CMD_REPEAT = value

    def get_start_seq_length(self):
        return self.START_SEQUENCE_LENGTH

    def set_start_seq_length(self, value):
        self.START_SEQUENCE_LENGTH = value

    def get_stop_seq_length(self):
        return self.STOP_SEQUENCE_LENGTH

    def set_stop_seq_length(self, value):
        self.STOP_SEQUENCE_LENGTH = value

    def set_data(self, data, addr=0):
        if self._cmd_mem_size < len(data):
            raise ValueError('Size of data (%d bytes) is too big for memory (%d bytes)' % (len(data), self._cmd_mem_size))
        self._intf.write(self._conf['base_addr'] + self._cmd_mem_offset + addr, data)

    def get_data(self, size=None, addr=0):
        if self._cmd_mem_size < size:
            raise ValueError('Size is too big')
        if not size:
            return self._intf.read(self._conf['base_addr'] + self._cmd_mem_offset + addr, self._cmd_mem_size)
        else:
            return self._intf.read(self._conf['base_addr'] + self._cmd_mem_offset + addr, size)
