#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#


import logging as logging_util
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


def log_exception(logger: logging_util.Logger, msg, *args, level=logging_util.ERROR, e=None, **kwargs):
    """
            Convenience method for logging an ERROR with exception information.
            """
    if not (isinstance(e, Exception) or e is None):
        raise TypeError("e must be an instance of Exception or None")
    if isinstance(logger, logging_util.Logger):
        raise TypeError("logger must be an instance of logging.Logger")

    reraise = kwargs.pop('reraise', False)
    if reraise and e is None:
        raise ValueError("reraise=True requires e to be set")

    exc_info = kwargs.pop('exc_info', True)
    if exc_info and e is not None:
        exc_info = e
    logger.log(level, msg, *args, exc_info=exc_info, **kwargs)

    if reraise:
        raise e


def basil_config():
    """Convenience method for setting up the logging module for use with basil.
    Could be used from the main script of the particular application.
    """
    logging.basicConfig(level=logging_util.INFO,
                        format="%(asctime)s - %(name)s - [%(levelname)-8s] (%(threadName)-10s) %(message)s")


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
    # current download on silab is using bitarr.endian
    ba = bitarray(bitarr, endian=bit_endian(bitarr))
    ba.reverse()  # this flip the byte order and the bit order of each byte
    # current instance on silab is using np.fromstring; but this should not make any difference!
    bs = np.frombuffer(ba.tobytes(), dtype=np.uint8)  # byte padding happens here, bitarray.tobytes()
    bs = (bs * hex_conversion(0x0202020202) & 0x010884422010) % 1023
    return array('B', bs.astype(np.uint8))


# Python 2/3 compatibility function for array.tobytes function


if callable(bitarray.endian):
    # installed version is prior to 3.4.0
    def bit_endian(bitarr):
        return bitarr.endian()

    def hex_conversion(num):
        return num

else:
    # bitarray version is at least 3.4.0
    def bit_endian(bitarr):
        return bitarr.endian

    def hex_conversion(num):
        return np.uint64(num)


try:
    array.tobytes
except AttributeError:  # Python 2
    def tobytes(v):
        return v.tostring()
else:  # Python 3
    def tobytes(v):
        return v.tobytes()
