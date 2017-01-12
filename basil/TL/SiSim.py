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
import logging
from threading import Lock

from basil.TL.SiTransferLayer import SiTransferLayer
from basil.utils.sim.Protocol import WriteRequest, ReadRequest, ReadResponse, PickleInterface


class SiSim(SiTransferLayer):

    def __init__(self, conf):
        super(SiSim, self).__init__(conf)
        self._sock = None

    def init(self):
        super(SiSim, self).init()
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

        host = 'localhost'
        if 'host' in self._init.keys():
            host = self._init['host']

        port = 12345
        if 'port' in self._init.keys():
            port = self._init['port']

        # try few times for simulator to setup
        try_cnt = 60
        if 'timeout' in self._init.keys():
            try_cnt = self._init['timeout']

        while(self._sock.connect_ex((host, port)) != 0):
            logging.debug("Trying to connect to simulator.")
            time.sleep(1)
            try_cnt -= 1
            if(try_cnt < 1):
                raise IOError("No connection to simulation server.")

        self._iface = PickleInterface(self._sock)  # exeption?

        self._lock = Lock()

    def write(self, addr, data):
        ad = array.array('B', data)
        req = WriteRequest(addr, ad)

        with self._lock:
            self._iface.send(req)

    def read(self, addr, size):
        req = ReadRequest(addr, size)

        with self._lock:
            self._iface.send(req)
            resp = self._iface.recv()

        if not isinstance(resp, ReadResponse):
            raise ValueError("Communication error with Simulation: got %s" % repr(resp))
        return array.array('B', resp.data)

    def close(self):
        self._sock.close()
