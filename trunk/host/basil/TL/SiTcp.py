#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

#TODO: TCP support (use internal queuing?) http://stackoverflow.com/questions/17140339/gevent-using-queue-get-and-socket-recv-at-the-same-time

import socket
import select
import struct
from array import array

from basil.TL.TransferLayer import TransferLayer

class SiTcp (TransferLayer):
    '''SiTcp
    '''
    
    RBCP_VER = 0xff
    RBCP_CMD_WR = 0x80
    RBCP_CMD_RD = 0xC0
    RBCP_ID = 0xa5
    RBCP_MAX_SIZE = 255

    BASE_TCP = 0x100000000
    
    _sock = None

    def __init__(self, conf):
        super(SiUsb, self).__init__(conf)

    def init(self, **kwargs):
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self._sock.setblocking(0)

    def _write_single(self, addr, data):
        request = array('B', struct.pack('>BBBBI', self.RBCP_VER, self.RBCP_CMD_WR, self.RBCP_ID, len(data), addr))
        request += data

        self._sock.sendto(request,(self._init['ip'], self._init['udp_port']))
        ready = select.select([self._sock], [], [], 0.1)
        if not ready[0]:
            raise IOError('SiTcp:Write - Timeout')
        
        ack = self._sock.recv(1024)
        
        if( len(ack) < 8):
            raise IOError('SiTcp:Write - Packet is too short')
        
        if( (0x0f & ord(ack[1])) != 0x8 ):
            raise IOError('SiTcp:Write - Bus error')
        
        #CHECK ID?
        
    def write(self, addr, data):
      
        buff = array('B', data)
        chunks = lambda l, n: [l[x: x + n] for x in xrange(0, len(l), n)]
        new_addr = addr
        for req in chunks(buff, self.RBCP_MAX_SIZE):
            self._write_single(new_addr, req)
            new_addr += len(req)

    def read_single(self, addr, size):
        request = array('B', struct.pack('>BBBBI', self.RBCP_VER, self.RBCP_CMD_WR, self.RBCP_ID, size, addr))
        
        self._sock.sendto(request,(self._init['ip'], self._init['udp_port']))
        ready = select.select([self._sock], [], [], 0.1)
        if not ready[0]:
            raise IOError('SiTcp:Read - Timeout')
        
        ack =  self._sock.recv(4096)
        
        if( len(ack) != size + 8):
            raise IOError('SiTcp:Read - Wrong packet size')
        
        if( (0x0f & ord(ack[1])) != 0x8 ):
            raise IOError('SiTcp:Read - Bus error')
        
        #CHECK ID?
        return array('B',ack[8:])

    def read(self, addr, size):
        ret = array('B')
        if size > self.RBCP_MAX_SIZE:
            new_addr = addr
            next_size = self.RBCP_MAX_SIZE
            while next_size < size:
                ret += self._read_single(new_addr, self.RBCP_MAX_SIZE)
                new_addr = addr + next_size
                next_size = next_size + self.RBCP_MAX_SIZE
    
            ret += self._read_single(new_addr - self.RBCP_MAX_SIZE, size + self.RBCP_MAX_SIZE - next_size)
    
        else:
            ret += self._read_single(addr, size)
    
        return ret

    #def get_configuration(self):
        #conf = dict(self._init)
        #conf['board_id'] = self._sidev.board_id
        #return conf

        