#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# A transfer layer for SiTCP Ethernet. More information: http://sitcp.bbtech.co.jp
#

import logging

import socket
import select
import struct
import re
from array import array
from threading import Thread
from threading import RLock as Lock

from basil.TL.SiTransferLayer import SiTransferLayer

logger = logging.getLogger(__name__)


class SiTcp(SiTransferLayer):
    '''SiTcp transport layer.
    '''

    RBCP_VER = 0xff
    RBCP_CMD_WR = 0x80
    RBCP_CMD_RD = 0xC0
    RBCP_ID = 0xa5
    RBCP_MAX_SIZE = 255

    UDP_TIMEOUT = 10.0
    UDP_RETRANSMIT_CNT = 0  # TODO

    BASE_DATA_TCP = 0x100000000
    BASE_FAKE_FIFO_TCP = 0x200000000  # above this read will return size of local TCP fifo (4 bytes)

    def __init__(self, conf):
        super(SiTcp, self).__init__(conf)
        self._sock_udp = None
        self._sock_tcp = None
        self._udp_lock = Lock()
        self._tcp_lock = Lock()
        self._tcp_readout_interval = 0.05
        self._tcp_readout_thread = None
        self._tcp_read_buff = None

    def reset(self):
        with self._tcp_lock:
            self._tcp_read_buff = array('B')

    def reset_fifo(self):
        with self._tcp_lock:
            fifo_size = self._get_tcp_data_size()
            fifo_int_size = (fifo_size - (fifo_size % 4)) / 4
            del_size = fifo_int_size * 4
            self._tcp_read_buff = self._tcp_read_buff[del_size:]

    def init(self):
        super(SiTcp, self).init()
        self.reset()
        self._sock_udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        # self._sock_udp.setblocking(0)
        self._sock_tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        # start readout thread if TCP connection is set
        if self._init['tcp_connection']:
            self._sock_tcp.connect((self._init['ip'], self._init['tcp_port']))
            self._sock_tcp.setblocking(0)
            self._tcp_readout_thread = Thread(target=self._tcp_readout, name='TcpReadoutThread', kwargs={})
            self._tcp_readout_thread.daemon = True  # exiting program even when thread is alive
            self._stop = False
            self._tcp_readout_thread.start()

    def _write_single(self, addr, data):
        request = array('B', struct.pack('>BBBBI', self.RBCP_VER, self.RBCP_CMD_WR, self.RBCP_ID, len(data), addr))
        request += data
        self._sock_udp.sendto(request, (self._init['ip'], self._init['udp_port']))
        ready = select.select([self._sock_udp], [], [], self.UDP_TIMEOUT)
        if not ready[0]:
            raise IOError('SiTcp:_write_single - Timeout')
        ack = self._sock_udp.recv(1024)
        if len(ack) < 8:
            raise IOError('SiTcp:_write_single - Packet is too short')
        if array('B', ack)[8:] != data:
            print data, array('B', ack)[8:]
            raise IOError('SiTcp:_write_single - Data error')
        if (0x0f & ord(ack[1])) != 0x8:
            raise IOError('SiTcp:_write_single - Bus error')
        if ord(ack[2]) != self.RBCP_ID:
            raise IOError('SiTcp:_write_single - Wrong ID')

    def write(self, addr, data):
        if addr < self.BASE_DATA_TCP:

            def chunks(array, max_len):
                index = 0
                while index < len(array):
                    yield array[index: index + max_len]
                    index += max_len

            buff = array('B', data)
            with self._udp_lock:
                new_addr = addr
                for req in chunks(buff, self.RBCP_MAX_SIZE):
                    self._write_single(new_addr, req)
                    new_addr += len(req)
        elif addr < self.BASE_FAKE_FIFO_TCP:
            with self._tcp_lock:
                self._sock_tcp.sendall(data)  # chunking?
        # resetting SiTcp buffer
        # the buffer may contain random (?) data words after setting
        # up of the TCP socket and stating of the readout thread
        elif addr == self.BASE_FAKE_FIFO_TCP:
            self.reset_fifo()
        else:
            logger.warning("SiTcp:write - Invalid address %s" % hex(addr))

    def _read_single(self, addr, size):
        request = array('B', struct.pack('>BBBBI', self.RBCP_VER, self.RBCP_CMD_RD, self.RBCP_ID, size, addr))
        self._sock_udp.sendto(request, (self._init['ip'], self._init['udp_port']))
        ready = select.select([self._sock_udp], [], [], self.UDP_TIMEOUT)
        if not ready[0]:
            raise IOError('SiTcp:_read_single - Timeout')
        ack = self._sock_udp.recv(4096)
        if len(ack) != size + 8:
            print len(ack), size + 8
            raise IOError('SiTcp:_read_single - Wrong packet size')
        if (0x0f & ord(ack[1])) != 0x8:
            raise IOError('SiTcp:_read_single - Bus error')
        if ord(ack[2]) != self.RBCP_ID:
            raise IOError('SiTcp:_read_single - Wrong ID')
        return array('B', ack[8:])

    def read(self, addr, size):
        if addr < self.BASE_DATA_TCP:
            ret = array('B')
            with self._udp_lock:
                if size > self.RBCP_MAX_SIZE:
                    new_addr = addr
                    next_size = self.RBCP_MAX_SIZE
                    while next_size < size:
                        ret += self._read_single(new_addr, self.RBCP_MAX_SIZE)
                        new_addr = addr + next_size
                        next_size = next_size + self.RBCP_MAX_SIZE
                    ret += self._read_single(new_addr, size + self.RBCP_MAX_SIZE - next_size)
                else:
                    ret += self._read_single(addr, size)
            return ret
        elif addr < self.BASE_FAKE_FIFO_TCP:
            return self._get_tcp_data(size)
        elif addr == self.BASE_FAKE_FIFO_TCP:
            from basil.HL.sram_fifo import sram_fifo
            version = int(re.findall(r'\d+', sram_fifo._require_version)[-1])
            del sram_fifo
            return array('B', chr(version))
        else:  # this is to fake a HL fifo. Is there better way? Definitely...
            if size == 4:
                return array('B', struct.pack('I', self._get_tcp_data_size()))
            else:
                return array('B', '\x00' * size)  # FIXME: workaround for SRAM module registers
#                 logger.warning("SiTcp:read - Invalid address %s" % hex(addr))

    def _tcp_readout(self):
        while not self._stop:
            try: # TODO: temporary fix
                ready = select.select([self._sock_tcp], [], [], self._tcp_readout_interval)
                if ready[0]:
                    with self._tcp_lock:
                        data = self._sock_tcp.recv(1024 * 8 * 64)
                        self._tcp_read_buff.extend(array('B', data))
            except AttributeError:
                pass

    def _get_tcp_data_size(self):
        with self._tcp_lock:
            size = len(self._tcp_read_buff)
        return size

    def _get_tcp_data(self, size):
        with self._tcp_lock:
            ret_size = min((size, self._get_tcp_data_size()))
            ret = self._tcp_read_buff[:ret_size]
            self._tcp_read_buff = self._tcp_read_buff[ret_size:]
        return ret
    
    def close(self):
        super(SiTcp, self).close()
        self._stop = True
        self._tcp_readout_thread.join()
        self._sock_udp.close()
        self._sock_tcp.close()
