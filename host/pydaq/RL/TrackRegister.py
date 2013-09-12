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
        raise NotImplementedError("To be implemented.")

    def write(self, size=-1):
        if size == -1:
            size = self._conf["seq_size"]

        bv = BitVector(size=self._conf["seq_width"] * size)
        for i in xrange(size):
            for track in self._conf['tracks']:
                bit = i * self._conf["seq_width"] + 16 - 1 - track['position']
                bv[bit] = self._tracks[track['name']][i]
        
        ba = utils.bitvector_to_byte_array(bv)
        self._drv.set_data(0, ba)  # TODO: this probably has to be done diffrent way
