#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#


from array import array

import numpy as np
from bitarray import bitarray


def logging(fn):
    def wrapped(*args, **kargs):
        print('loging: {}'.format(locals()))
#         if args:
#             print("loging: arguments: " + str(args))
#         if kargs:
#             print("loging: kargs: " + str(kargs))
        return fn(*args, **kargs)
    return wrapped


def lsbits(b):
    return (b * 0x0202020202 & 0x010884422010) % 1023


def bitvector_to_byte_array(bitvector):
    bsize = len(bitvector)
    size_bytes = int(((bsize - 1) / 8) + 1)
    bs = tobytes(array('B', bitvector.vector))[0:size_bytes]
    bitstream_swap = ''
    for b in bs:
        bitstream_swap += chr(lsbits(b))
    return array('B', bitstream_swap)


def bitarray_to_byte_array(bitarr):
    ba = bitarray(bitarr, endian=bitarr.endian())
    ba.reverse()  # this flip the byte order and the bit order of each byte
    bs = np.fromstring(ba.tobytes(), dtype=np.uint8)  # byte padding happens here, bitarray.tobytes()
    bs = (bs * 0x0202020202 & 0x010884422010) % 1023
    return array('B', bs.astype(np.uint8))

# Python 2/3 compatibility function for array.tobytes function
try:
    array.tobytes
except AttributeError:  # Python 2
    def tobytes(v):
        return v.tostring()
else:  # Python 3
    def tobytes(v):
        return v.tobytes()
