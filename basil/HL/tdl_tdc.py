#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from basil.HL.RegisterHardwareLayer import RegisterHardwareLayer
import numpy as np


class tdl_tdc(RegisterHardwareLayer):
    '''TDC controller interface
    '''

    GHZ_S_FREQ = 0.48
    CLK_DIV = 3
    word_type_codes = {0 : 'TRIGGERED', 
                     1 : 'RISING',
                     2 : 'FALLING',
                     3 : 'TIMESTAMP',
                     4 : 'CALIB',
                     5 : 'MISS',
                     6 : 'RST'}

    _registers = {'RESET': {'descr': {'addr': 0, 'size': 7, 'offset': 1, 'properties': ['writeonly']}},
                  'VERSION': {'descr': {'addr': 0, 'size': 8, 'properties': ['ro']}},
                  'ENABLE': {'descr': {'addr': 1, 'size': 1, 'offset': 0}},
                  'ENABLE_EXTERN': {'descr': {'addr': 1, 'size': 1, 'offset': 1}},
                  'EN_ARMING': {'descr': {'addr': 1, 'size': 1, 'offset': 2}},
                  'EN_WRITE_TIMESTAMP': {'descr': {'addr': 1, 'size': 1, 'offset': 3}},
                  'EN_TRIGGER_DIST': {'descr': {'addr': 1, 'size': 1, 'offset': 4}},
                  'EN_NO_WRITE_TRIG_ERR': {'descr': {'addr': 1, 'size': 1, 'offset': 5}},
                  'EN_INVERT_TDC': {'descr': {'addr': 1, 'size': 1, 'offset': 6}},
                  'EN_INVERT_TRIGGER': {'descr': {'addr': 1, 'size': 1, 'offset': 7}},
                  'EVENT_COUNTER': {'descr': {'addr': 2, 'size': 32, 'properties': ['ro']}},
                  'LOST_DATA_COUNTER': {'descr': {'addr': 6, 'size': 8, 'properties': ['ro']}},
                  'TDL_MISS_COUNTER' : {'descr' : {'addr': 7, 'size': 8, 'porperties' :['ro']}},
                  'EN_CALIBRATION_MOD': {'descr': {'addr': 8, 'size': 1, 'offset': 0}}}

    _require_version = "==2"

    calib_vector = np.ones(92)
    calib_sum = np.sum(calib_vector)

    def __init__(self, intf, conf):
        super(tdl_tdc, self).__init__(intf, conf)

    def get_tdc_value(self, word):
        # The last 7 bit are tdl data, the first 7 bits are word type and source, so 18 bits are counter information
        # Of these, the last two bits are timing wrt. the fast clock and the first 16 wrt. to the slow clock
        return self.CLK_DIV*((word >> 9) & 0x0FFFF)  + (((word >> 7) & 0x3))

    def get_word_type(self, word):
        return (word >> (32 - 7) & 0b111) 

    def is_calib_word(self, word):
        return self.get_word_type(word) == 4

    def is_time_word(self, word):
        return self.get_word_type(word) in [0, 1, 2,]

    def get_raw_tdl_values(self, word):
        return word & 0b1111111

    def tdl_to_time(self, tdl_value) :
        sample_proportion = np.sum(self.calib_vector[0:tdl_value-1])/self.calib_sum
        return sample_proportion * 1/self.GHZ_S_FREQ

    def set_calib_values(self,  calib_values) :
        calib_values = np.append(calib_values,np.arange(92))
        data_sort, value_counts = np.unique(calib_values % 128, return_counts = True)
        self.calib_vector = value_counts
        self.calib_sum = np.sum(value_counts)

    def tdc_word_to_time(self, word) :
        if isinstance(word, dict) :
            word = word['raw_word']
        if (not self.is_time_word(word)) :
            word_type = self.word_type_codes[self.get_word_type(word)]
            raise ValueError('can not convert tdc word of type %s to time' % word_type )
        tdc_value = self.get_tdc_value(word)
        tdc_time = 1/self.GHZ_S_FREQ * tdc_value
        return tdc_time - self.tdl_to_time(self.get_raw_tdl_values(word))

    def disassemble_tdc_word(self, word):
        # Shift away the 32 - 7 data bits and grab 3 bit word type
        word_type = self.word_type_codes[self.get_word_type(word)]
        if word_type in ['CALIB', 'TRIGGERED', 'RISING', 'FALLING'] :
            return {'source_id' : (word >> (32 - 4)),
                    'word_type' : word_type,
                    'tdl_value' : word & 0b1111111,
                    'fine_time_value' : self.get_tdc_value(word) % self.CLK_DIV,
                    'fast_clk_value' : self.get_tdc_value(word),
                    'raw_word' : word}
        elif word_type == 'TIMESTAMP' :
            return {'source_id' : (word >> (32 - 4)),
                    'word_type' : word_type,
                    'timestamp' : (word >> 9) & 0xFFFF,
                    'raw_word'  : word}
        else :
            return {'source_id' : (word >> (32 - 4)),
                    'word_type' : word_type,
                    'raw_word'  : word}

    
    def reset(self):
        self.RESET = 0

    def get_lost_data_counter(self):
        return self.LOST_DATA_COUNTER

    def missed_data_counter(self):
        return self.TDL_MISS_COUNTER

    def set_en(self, value):
        self.ENABLE = value

    def get_en(self):
        return self.ENABLE

    def set_en_extern(self, value):
        self.ENABLE_EXTERN = value

    def get_en_extern(self):
        return self.ENABLE_EXTERN

    def set_arming(self, value):
        self.EN_ARMING = value

    def get_arming(self):
        return self.EN_ARMING

    def set_write_timestamp(self, value):
        self.EN_WRITE_TIMESTAMP = value

    def get_write_timestamp(self):
        return self.EN_WRITE_TIMESTAMP

    def get_event_counter(self):
        return self.EVENT_COUNTER

