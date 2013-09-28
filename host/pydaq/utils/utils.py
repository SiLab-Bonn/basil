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

import array


def logging(fn):

    def wrapped(*args, **kargs):
        print 'loging:', locals()
        #if args:
        #    print("loging: arguments: " + str(args))
        #if kargs:
        #    print("loging: kargs: " + str(kargs))

        return fn(*args, **kargs)
    return wrapped


def bitvector_to_byte_array(bitvector):
    bsize = len(bitvector)
    size_bytes = ((bsize - 1) / 8) + 1
    
    bs = array.array('B', bitvector.vector.tostring())[0:size_bytes]
    bitstream_swap = ''
    lsbits = lambda b: (b * 0x0202020202 & 0x010884422010) % 1023
    for b in bs:
        bitstream_swap += chr(lsbits(b))

    return array.array('B', bitstream_swap)
