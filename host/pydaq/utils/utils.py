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
    bs = array.array('B', bitvector.vector.tostring())
    bitstream_swap = ''
    lsbits = lambda b: (b * 0x0202020202 & 0x010884422010) % 1023
    for b in bs:
        bitstream_swap += chr(lsbits(b))

    return array.array('B', bitstream_swap)
