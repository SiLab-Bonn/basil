#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# SVN revision information:
#  $Rev::                       $:
#  $Author::                    $:
#  $Date::                      $:
#
#Initial version by Chris Higgs <chris.higgs@potentialventures.com>
#

"""
Simulation library for SiLibUSB devices

Could be monkey-patched in based on an environment variable to avoid having to
modify software.

Communicate via a socket to the simulator

"""
import sys
import os
import socket
import array

from SimSiLibUsbProtocol import WriteExternalRequest, ReadExternalRequest, ReadExternalResponse, ReadFastBlockRequest, ReadFastBlockResponse, PickleInterface

__version__ = "0.0.2"

class SiUSBDevice(object):

    """Simulation library to emulate SiUSBDevices"""

    def __init__(self, device=None, simulation_host='localhost', simulation_port=12345):
        self._sock = None
        self.simulation_host = simulation_host
        self.simulation_port = simulation_port

    def GetFWVersion(self):
        return __version__

    def GetName(self):
        return "Simulated Device"

    def GetBoardId(self):
        return "%s:%d" % (self.simulation_host, self.simulation_port)

    def DownloadXilinx(self, bitfile):
        """We hijack this call to perform the socket connect"""
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._sock.connect((self.simulation_host, self.simulation_port))
        self._iface = PickleInterface(self._sock)
        return True

    def WriteExternal(self, address, data):
        req = WriteExternalRequest(address, data)
        self._iface.send(req)

    def ReadExternal(self, address, size):
        req = ReadExternalRequest(address, size)
        self._iface.send(req)
        resp = self._iface.recv()
        if not isinstance(resp, ReadExternalResponse):
            raise ValueError("Communication error with Simulation: got %s" % repr(resp))
        return array.array('B', resp.data)

    def FastBlockRead(self, size):
        req = ReadFastBlockRequest(size)
        self._iface.send(req)
        resp = self._iface.recv()
        if not isinstance(resp, ReadFastBlockResponse):
            raise ValueError("Communication error with Simulation: got %s" % repr(resp))
        return array.array('B', resp.data)
    
    def FastBlockWrite(self, size):
        raise NotImplementedError("To be implemented.")
        
    def WriteI2C(self, address, data):
        print 'SiUSBDevice:WriteI2C', address, data #raise NotImplementedError("To be implemented.")
        
    def ReadI2C(self, address, size):
        print 'SiUSBDevice:ReadI2C' #raise NotImplementedError("To be implemented.")
        return array.array('B', range(size)) 
    