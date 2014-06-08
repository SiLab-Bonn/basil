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

from SimSiLibUsbProtocol import WriteExternalRequest, ReadExternalRequest, ReadExternalResponse, PickleInterface

__version__ = "0.0.1"

_simulation_host = os.getenv("SIMULATION_HOST")
_simulation_port = os.getenv("SIMULATION_PORT")

if _simulation_host is None or _simulation_port is None:
    raise ImportError("Unable to use SimSiLibUSB: Need to set SIMULATION_HOST and SIMULATION_PORT env vars")
else:
    _simulation_port = int(_simulation_port)

class SiUSBDevice(object):

    """Simulation library to emulate SiUSBDevices"""

    def __init__(self, device=None):
        self._sock = None

    def GetFWVersion(self):
        return __version__

    def GetName(self):
        return "Simulated Device"

    def GetBoardId(self):
        return "%s:%d" % (_simulation_host, _simulation_port)

    def DownloadXilinx(self, bitfile):
        """We hijack this call to perform the socket connect"""
        self._sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._sock.connect((_simulation_host, _simulation_port))
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
        return resp.data

