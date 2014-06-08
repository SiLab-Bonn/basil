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

import os
import socket
import logging

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from cocotb.result import TestError

from SimSiLibUsbDriver import FullSpeedBus
from SimSiLibUsbProtocol import WriteExternalRequest, ReadExternalRequest, ReadExternalResponse, PickleInterface

@cocotb.test()
def socket_test(dut, debug=True):
    """Testcase that uses a socket to drive the DUT"""

    host = os.getenv("SIMULATION_HOST")
    port = os.getenv("SIMULATION_PORT")

    if host is None or port is None:
        dut.log.error("SIMULATION_HOST and SIMULATION_PORT environment variables must be set")
        raise TestError("Unable to open a socket")
    port = int(port)

    if debug:
        dut.log.setLevel(logging.DEBUG)

    # Kick off a clock generator
    cocotb.fork(Clock(dut.FCLK_IN, 5000).start())
    bus = FullSpeedBus(dut, dut.FCLK_IN)

    yield RisingEdge(dut.FCLK_IN)
    for _ in range(1000):
	#while dut.BUS_RST.value:
        yield RisingEdge(dut.FCLK_IN)

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((host, port))
    s.listen(1)

    while True:
        dut.log.info("Waiting for incoming connection on %s:%d" % (host, port))
        client, sockname = s.accept()
        dut.log.info("New connection from %s:%d" % (sockname[0], sockname[1]))
        iface = PickleInterface(client)

        while True:
            yield RisingEdge(dut.FCLK_IN)
            try:
                req = iface.try_recv()
            except EOFError:
                dut.log.info("Remote client closed the connection")
                client.close()
                break
            if req is None: continue

            dut.log.debug("Received: %s" % str(req))

            if isinstance(req, WriteExternalRequest):
                for index, byte in enumerate(req.data):
                    yield bus.write_external(req.address + index, byte)

            elif isinstance(req, ReadExternalRequest):
                result = []
                for byte in xrange(req.size):
                    val = yield bus.read_external(req.address + byte)
                    result.append(val)
                iface.send(ReadExternalResponse(result))
            else:
                raise NotImplementedError("Unsupported request type: %s" % str(type(req)))



@cocotb.test(skip=True)
def bringup_test(dut):
    """Initial test to see if simulation works"""

    # Kick off a clock generator
    cocotb.fork(Clock(dut.FCLK_IN, 5000).start())
    bus = FullSpeedBus(dut, dut.FCLK_IN)

    yield RisingEdge(dut.FCLK_IN)
    while dut.BUS_RST.value:
        yield RisingEdge(dut.FCLK_IN)

    yield bus.write_external(0, 0)
    for i in range(100):
        yield RisingEdge(dut.FCLK_IN)
    yield bus.write_external(3, 0x7f)
    for i in range(100):
        yield RisingEdge(dut.FCLK_IN)
