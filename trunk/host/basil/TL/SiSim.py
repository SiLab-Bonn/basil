#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# An interface to HDL simulator thatnks to cocotb [http://cocotb.readthedocs.org/]
#

import socket
import array
import time

from basil.TL.TransferLayer import TransferLayer
from basil.utils.sim.Protocol import WriteRequest, ReadRequest, ReadResponse, PickleInterface

class SiSim (TransferLayer):

    def __init__(self, conf):
        super(SiSim, self).__init__(conf)
        self._sock = None
        
    def init(self):
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        
        host = 'localhost'
        if 'host' in self._init.keys():
            host = self._init['host']
        
        port = 12345
        if 'port' in self._init.keys():
            port = self._init['port']
        
        # try few times for simulator to setup
        try_cnt = 60
        while(self._sock.connect_ex((host, port)) != 0):
            time.sleep(0.5)
            try_cnt -= 1
            if( try_cnt < 1):
                raise IOError("No connection to simulation server.")
                 
        self._iface = PickleInterface(self._sock) #exeption?

    def write(self, addr, data):
        ad = array.array('B', data)
        req = WriteRequest(addr, ad)
        self._iface.send(req)

    def read(self, addr, size):
        req = ReadRequest(addr, size)
        self._iface.send(req)
        resp = self._iface.recv()
        if not isinstance(resp, ReadResponse):
            raise ValueError("Communication error with Simulation: got %s" % repr(resp))
        return array.array('B', resp.data)

    def close(self):
        self._sock.close() 
