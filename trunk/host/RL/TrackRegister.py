#
# ------------------------------------------------------------
# Copyright (c) SILAB , Physics Institute of Bonn University
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#

from RL.RegisterLayer import RegisterLayer
from BitVector import BitVector
from utils import utils


class TrackRegister(RegisterLayer):
    '''Tracking register
    '''
    def __init__(self, driver, conf):
        RegisterLayer.__init__(self, driver, conf)
        self._tracks = dict()

        for track in self._conf['tracks']:
                bv = BitVector(size=self._conf["seq_size"])
                self._tracks[track['name']] = bv

    def __getitem__(self, items):
        if items in self._tracks:
            return  self._tracks[items]
        else:
            raise ValueError('Item does not exist')

    def __setitem__(self, key, value):
        self._tracks[key] = value

    def clear(self):
        'Clear tracks in memory - all zero'
        for track in self._tracks:
            self._tracks[track].reset(0)

    def write(self, size=-1):
        if size == -1:
            size = self._conf["seq_size"]

        bv = BitVector(size=self._conf["seq_width"] * size)
        for i in xrange(size):
            for track in self._conf['tracks']:
                bit = 0
                if self._conf["seq_width"] >= 8:
                    bit = i * self._conf["seq_width"] + self._conf["seq_width"] - 1 - track['position']
                elif self._conf["seq_width"] == 4:
                    if i % 2 == 0:
                        bit = (i + 1) * self._conf["seq_width"] + self._conf["seq_width"] - 1 - track['position']
                    else:
                        bit = (i - 1) * self._conf["seq_width"] + self._conf["seq_width"] - 1 - track['position']
                else:
                    raise NotImplementedError("To be implemented.")
                bv[bit] = self._tracks[track['name']][i]

        ba = utils.bitvector_to_byte_array(bv)
        self._drv.set_data(ba)  # TODO: this probably has to be done different way
