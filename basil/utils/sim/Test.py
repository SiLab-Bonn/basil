#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# Initial version by Chris Higgs <chris.higgs@potentialventures.com>
#


import logging
import os
import socket
import yaml

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock

from basil.utils.sim.Protocol import WriteRequest, ReadRequest, ReadResponse, PickleInterface


def get_bus():
    bus_name_path = os.getenv("SIMULATION_BUS", "basil.utils.sim.BasilBusDriver")
    bus_name = bus_name_path.split(".")[-1]
    return getattr(__import__(bus_name_path, fromlist=[bus_name]), bus_name)


def import_driver(path):
    name = path.split(".")[-1]
    return getattr(__import__(path, fromlist=[name]), name)


@cocotb.test(skip=False)
async def test(dut, debug=False):
    """Testcase that uses a socket to drive the DUT"""

    host = os.getenv("SIMULATION_HOST", "localhost")
    port = os.getenv("SIMULATION_PORT", "12345")
    bus_clk_freq = int(os.getenv("SIMULATION_BUS_CLK_PERIOD", "5000"))
    bus_transaction_wait = int(os.getenv("SIMULATION_TRANSACTION_WAIT", "50000"))
    bus_clock = bool(int(os.getenv("SIMULATION_BUS_CLOCK", "1")))

    if debug:
        dut._log.setLevel(logging.DEBUG)

    bus = get_bus()(dut)

    dut._log.info(f"Using bus driver : {type(bus).__name__}")
    dut._log.info(f"Bus clock : {bus_clock}")
    dut._log.info(f"Bus clock period : {bus_clk_freq}")
    dut._log.info(f"Bus transaction wait : {bus_transaction_wait}")

    sim_modules = []
    sim_modules_data = os.getenv("SIMULATION_MODULES", "")
    if sim_modules_data:
        sim_modules_yml = yaml.safe_load(sim_modules_data)
        for mod in sim_modules_yml:
            mod_import = import_driver(mod)
            kargs = dict(sim_modules_yml[mod])
            sim_modules.append(mod_import(dut, **kargs))
            dut._log.info("Using simulation modules : %s  arguments: %s" % (mod, kargs))

    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    try:
        s.bind((host, int(port)))
        s.listen(1)
    except Exception:
        s.close()
        s = None
        raise

    # Kick off a clock generator
    if bus_clock:
        cocotb.fork(Clock(bus.clock, bus_clk_freq).start())

    # start sim_modules
    for mod in sim_modules:
        cocotb.fork(mod.run())

    await bus.init()

    while True:
        dut._log.info("Waiting for incoming connection on %s:%d" % (host, int(port)))
        clientsocket, socket_address = s.accept()
        dut._log.info("New connection from %s:%d" % (socket_address[0], socket_address[1]))
        iface = PickleInterface(clientsocket)

        while True:
            # uncomment for constantly advancing clock
            # await RisingEdge(bus.clock)

            try:
                req = iface.try_recv()
            except EOFError:
                dut._log.info("Remote server closed the connection")
                clientsocket.shutdown(socket.SHUT_RDWR)
                clientsocket.close()
                break
            if req is None:
                continue

            dut._log.debug("Received: %s" % str(req))

            # add few clocks
            # for _ in range(10):
            #    await RisingEdge(bus.clock)
            await Timer(bus_transaction_wait)

            if isinstance(req, WriteRequest):
                await bus.write(req.address, req.data)
            elif isinstance(req, ReadRequest):
                result = await bus.read(req.address, req.size)
                resp = ReadResponse(result)
                dut._log.debug("Send: %s" % str(resp))
                iface.send(resp)
            else:
                raise NotImplementedError("Unsupported request type: %s" % str(type(req)))

            # add few clocks
            # for _ in range(10):
            #    await RisingEdge(bus.clock)
            await Timer(bus_transaction_wait)

        if os.getenv("SIMULATION_END_ON_DISCONNECT"):
            break

    s.shutdown(socket.SHUT_RDWR)
    s.close()
