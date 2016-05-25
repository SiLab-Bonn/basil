#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# A transfer layer for SiTcp Ethernet more: http://sitcp.bbtech.co.jp

import socket
import select
import struct
from array import array
from threading import Thread, Lock
from basil.TL.SiTransferLayer import SiTransferLayer


class SiTcp(SiTransferLayer):
    '''SiTcp
    '''

    RBCP_VER = 0xff
    RBCP_CMD_WR = 0x80
    RBCP_CMD_RD = 0xC0
    RBCP_ID = 0xa5
    RBCP_MAX_SIZE = 255

    UDP_TIMEOUT = 0.5
    UDP_RETRANSMIT_CNT = 0  # TODO

    BASE_DATA_TCP = 0x100000000
    BASE_FAKE_FIFO_TCP = 0x200000000  # above this read will return size of local TCP fifo (4 bytes)

    def __init__(self, conf):
        super(SiTcp, self).__init__(conf)
        self._sock_udp = None

        self._sock_tcp = None
        self._tcp_readout_thread = None
        self.tmp = 0

    def init(self):

        self._udp_lock = Lock()
        self._sock_udp = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        # self._sock_udp.setblocking(0)

        self._tcp_lock = Lock()
        self._tcp_read_buff = array('B')
        self._sock_tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        if(self._init['tcp_connection']):
            self._sock_tcp.connect((self._init['ip'], self._init['tcp_port']))
            self._sock_tcp.setblocking(0)

            self._tcp_readout_thread = Thread(target=self._tcp_readout, name='TcpReadoutThread', kwargs={})
            self._tcp_readout_thread.daemon = True
            self._tcp_readout_thread.start()

    def _write_single(self, addr, data):
        request = array('B', struct.pack('>BBBBI', self.RBCP_VER, self.RBCP_CMD_WR, self.RBCP_ID, len(data), addr))
        request += data

        self._sock_udp.sendto(request, (self._init['ip'], self._init['udp_port']))
        ready = select.select([self._sock_udp], [], [], self.UDP_TIMEOUT)
        if not ready[0]:
            raise IOError('SiTcp:Write - Timeout')

        ack = self._sock_udp.recv(1024)

        if(len(ack) < 8):
            raise IOError('SiTcp:Write - Packet is too short')

        if(array('B', ack)[8:] != data):
            raise IOError('SiTcp:Write - Data error')

        if((0x0f & ord(ack[1])) != 0x8):
            raise IOError('SiTcp:Write - Bus error')

        if(ord(ack[2]) != self.RBCP_ID):
            raise IOError('SiTcp:Write - Wrong ID')

    def write(self, addr, data):
        if addr < self.BASE_DATA_TCP:
            self._udp_lock.acquire()
            buff = array('B', data)
            chunks = lambda l, n: [l[x: x + n] for x in xrange(0, len(l), n)]
            new_addr = addr
            for req in chunks(buff, self.RBCP_MAX_SIZE):
                self._write_single(new_addr, req)
                new_addr += len(req)
            self._udp_lock.release()
        elif addr < self.BASE_FAKE_FIFO_TCP:
            self._sock_tcp.sendall(data)  # chunking?

    def _read_single(self, addr, size):
        request = array('B', struct.pack('>BBBBI', self.RBCP_VER, self.RBCP_CMD_RD, self.RBCP_ID, size, addr))

        self._sock_udp.sendto(request, (self._init['ip'], self._init['udp_port']))
        ready = select.select([self._sock_udp], [], [], self.UDP_TIMEOUT)
        if not ready[0]:
            raise IOError('SiTcp:Read - Timeout')

        ack = self._sock_udp.recv(4096)

        if(len(ack) != size + 8):
            raise IOError('SiTcp:Read - Wrong packet size')

        if((0x0f & ord(ack[1])) != 0x8):
            raise IOError('SiTcp:Read - Bus error')

        if(ord(ack[2]) != self.RBCP_ID):
            raise IOError('SiTcp:Read - Wrong ID')

        return array('B', ack[8:])

    def read(self, addr, size):

        if addr < self.BASE_DATA_TCP:
            self._udp_lock.acquire()
            ret = array('B')
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

            self._udp_lock.release()

            return ret
        elif addr < self.BASE_FAKE_FIFO_TCP:
            return self._get_tcp_data(size)
        else:  # this is to fake a HL fifo. Is there better way?
            if(size == 4):
                return array('B', struct.pack('I', self._get_tcp_data_size()))
            else:
                return array('B', '\x02' * size)

    def _tcp_readout(self):
        while True:
            ready = select.select([self._sock_tcp], [], [], 1)
            if(ready[0]):
                self._tcp_lock.acquire()
                data = self._sock_tcp.recv(1024 * 8)
                self._tcp_read_buff.extend(array('B', data))
                self._tcp_lock.release()

    def _get_tcp_data_size(self):
        self._tcp_lock.acquire()
        size = len(self._tcp_read_buff)
        self._tcp_lock.release()
        return size

    def _get_tcp_data(self, size):
        ret_size = min((size, self._get_tcp_data_size()))
        self._tcp_lock.acquire()
        ret = self._tcp_read_buff[:ret_size]
        self._tcp_read_buff = self._tcp_read_buff[ret_size:]
        self._tcp_lock.release()
        return ret
