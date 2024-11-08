#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

from array import array
import numpy as np
from bitarray import bitarray
import os.path
import git
import fileinput


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
    bs = np.frombuffer(ba.tobytes(), dtype=np.uint8)  # byte padding happens here, bitarray.tobytes()
    bs = (bs * np.uint64(0x0202020202) & 0x010884422010) % 1023
    return array('B', bs.astype(np.uint8))


def get_si_tcp(rel_path=''):
    ''' Download SiTCP/SiTCP10G sources from the official github repo and apply patches
    '''

    sitcp_repo = r'https://github.com/BeeBeansTechnologies/SiTCP_Netlist_for_Kintex7'
    sitcp_10G_repo = r'https://github.com/BeeBeansTechnologies/SiTCPXG_Netlist_for_Kintex7'

    def line_prepender(filename, line):
        with open(filename, 'rb+') as f:
            content = f.read()
            f.seek(0, 0)
            add = bytearray()
            add.extend(map(ord, line))
            add.extend(map(ord, '\n'))
            f.write(add + content)

    sitcp_folder = os.path.join(os.path.os.getcwd(), rel_path, 'SiTCP/')

    # Only download if the SiTCP git repository is not present 
    if not os.path.isdir(os.path.join(sitcp_folder, '.git')):
        print('Downloading SiTCP')

        # Has to be moved to be allowed to use existing folder for git checkout
        git.Repo.clone_from(url=sitcp_repo,
                            to_path=sitcp_folder, branch='master')
        # Patch sources, see README of bdaq53
        line_prepender(filename=sitcp_folder + 'TIMER.v', line=r'`default_nettype wire')
        line_prepender(filename=sitcp_folder + 'WRAP_SiTCP_GMII_XC7K_32K.V', line=r'`default_nettype wire')
        for line in fileinput.input([sitcp_folder + 'WRAP_SiTCP_GMII_XC7K_32K.V'], inplace=True):
            print(line.replace("assign\tMY_IP_ADDR[31:0]\t= (~FORCE_DEFAULTn | (EXT_IP_ADDR[31:0]==32'd0) \t? DEFAULT_IP_ADDR[31:0]\t\t: EXT_IP_ADDR[31:0]\t\t);",
                                'assign\tMY_IP_ADDR[31:0]\t= EXT_IP_ADDR[31:0];'), end='')
    else:  # update if existing
        print('SiTCP already present. Checking for updates')
        g = git.cmd.Git(sitcp_folder)
        g.pull()

    sitcp_10G_folder = os.path.join(os.path.os.getcwd(), rel_path, 'SiTCP10G/')
    # Only download if the SiTCP10G git repository is not present 
    if not os.path.isdir(os.path.join(sitcp_10G_folder, '.git')):
        print('Downloading SiTCP10G')

        # Has to be moved to be allowed to use existing folder for git checkout
        git.Repo.clone_from(url=sitcp_10G_repo,
                            to_path=sitcp_10G_folder, branch='master')
        # Patch sources, see README of bdaq53
        for line in fileinput.input([sitcp_10G_folder + 'WRAP_SiTCPXG_XC7K_128K.v'], inplace=True):
            print(line.replace("\t\t.MY_IP_ADDR	\t\t\t\t\t(MY_IP_ADDR[31:0]	\t\t\t),\t// in\t: My IP address[31:0]",
                               "\t\t.MY_IP_ADDR	\t\t\t\t\t({8'd192, 8'd168, 8'd100, 8'd12}),\t// in\t: My IP address[31:0]"), end='')

    else:  # update if existing
        print('SiTCP10G already present. Checking for updates')
        g = git.cmd.Git(sitcp_10G_folder)
        g.pull()


# Python 2/3 compatibility function for array.tobytes function


try:
    array.tobytes
except AttributeError:  # Python 2
    def tobytes(v):
        return v.tostring()
else:  # Python 3
    def tobytes(v):
        return v.tobytes()
