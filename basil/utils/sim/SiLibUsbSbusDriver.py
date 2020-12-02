#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# Initial version by Chris Higgs <chris.higgs@potentialventures.com>
#

# pylint: disable=pointless-statement, expression-not-assigned

"""
Abastract away interactions with the control bus
"""
import cocotb
from cocotb.binary import BinaryValue
from cocotb.triggers import RisingEdge, ReadOnly, Timer
from cocotb.drivers import BusDriver
from cocotb.result import ReturnValue
from cocotb.clock import Clock


class SiLibUsbSbusDriver(BusDriver):

    _signals = ["FCLK_IN", "BUS_DATA_IN", "BUS_DATA_OUT", "ADD", "RD_B", "WR_B", "FD", "FREAD", "FSTROBE", "FMODE"]

    BASE_ADDRESS_I2C = 0x00000
    HIGH_ADDRESS_I2C = BASE_ADDRESS_I2C + 256

    BASE_ADDRESS_EXTERNAL = 0x10000
    HIGH_ADDRESS_EXTERNAL = 0x10000 + 0x10000

    BASE_ADDRESS_BLOCK = 0x0001000000000000
    HIGH_ADDRESS_BLOCK = 0xffffffffffffffff

    def __init__(self, entity):
        BusDriver.__init__(self, entity, "", entity.FCLK_IN)

        # Create an appropriately sized high-impedance value
        self._high_impedance = BinaryValue(n_bits=len(self.bus.BUS_DATA_IN))
        self._high_impedance.binstr = "Z" * len(self.bus.BUS_DATA_IN)

        # Create an appropriately sized high-impedance value
        self._x = BinaryValue(n_bits=16)
        self._x.binstr = "x" * 16

        # Kick off a clock generator
        cocotb.fork(Clock(self.clock, 20800).start())

    @cocotb.coroutine
    def init(self):
        # Defaults
        # self.bus.BUS_RST<= 1
        self.bus.RD_B <= 1
        self.bus.WR_B <= 1
        self.bus.ADD <= 0
        self.bus.FREAD <= 0
        self.bus.FSTROBE <= 0
        self.bus.FMODE <= 0
        self.bus.BUS_DATA_IN <= self._high_impedance
        self.bus.FD <= self._high_impedance

        # wait for reset
        for _ in range(200):
            yield RisingEdge(self.clock)

    @cocotb.coroutine
    def read(self, address, size):
        result = []
        if(address >= self.BASE_ADDRESS_I2C and address < self.HIGH_ADDRESS_I2C):
            self.entity._log.warning("I2C address space supported in simulation!")
            for byte in range(size):
                result.append(0)
        elif(address >= self.BASE_ADDRESS_EXTERNAL and address < self.HIGH_ADDRESS_EXTERNAL):
            for byte in range(size):
                val = yield self.read_external(address - self.BASE_ADDRESS_EXTERNAL + byte)
                result.append(val)
        elif(address >= self.BASE_ADDRESS_BLOCK and address < self.HIGH_ADDRESS_BLOCK):
            for byte in range(size):
                val = yield self.fast_block_read()
                result.append(val)
        else:
            self.entity._log.warning("This address space does not exist!")

        return result

    @cocotb.coroutine
    def write(self, address, data):
        if(address >= self.BASE_ADDRESS_I2C and address < self.HIGH_ADDRESS_I2C):
            self.entity._log.warning("I2C address space supported in simulation!")
        elif(address >= self.BASE_ADDRESS_EXTERNAL and address < self.HIGH_ADDRESS_EXTERNAL):
            for index, byte in enumerate(data):
                yield self.write_external(address - self.BASE_ADDRESS_EXTERNAL + index, byte)
        elif(address >= self.BASE_ADDRESS_BLOCK and address < self.HIGH_ADDRESS_BLOCK):
            raise NotImplementedError("Unsupported request")
            # self._sidev.FastBlockWrite(data)
        else:
            self.entity._log.warning("This address space does not exist!")

    @cocotb.coroutine
    def read_external(self, address):
        """Copied from silusb.sv testbench interface"""
        self.bus.RD_B <= 1
        self.bus.ADD <= self._x
        self.bus.BUS_DATA_IN <= self._high_impedance
        for _ in range(5):
            yield RisingEdge(self.clock)

        yield RisingEdge(self.clock)
        self.bus.ADD <= address + 0x4000

        yield RisingEdge(self.clock)
        self.bus.RD_B <= 0
        yield RisingEdge(self.clock)
        self.bus.RD_B <= 0
        yield ReadOnly()
        result = self.bus.BUS_DATA_OUT.value.integer
        yield RisingEdge(self.clock)
        self.bus.RD_B <= 1

        yield RisingEdge(self.clock)
        self.bus.RD_B <= 1
        self.bus.ADD <= self._x
        self.bus.BUS_DATA_IN <= self._high_impedance

        yield RisingEdge(self.clock)

        for _ in range(5):
            yield RisingEdge(self.clock)

        raise ReturnValue(result)

    @cocotb.coroutine
    def write_external(self, address, value):
        """Copied from silusb.sv testbench interface"""
        self.bus.WR_B <= 1
        self.bus.ADD <= self._x
        self.bus.BUS_DATA_IN <= self._high_impedance

        for _ in range(5):
            yield RisingEdge(self.clock)

        yield RisingEdge(self.clock)
        self.bus.ADD <= address + 0x4000
        self.bus.BUS_DATA_IN <= int(value)
        yield Timer(1)  # This is hack for iverilog
        self.bus.ADD <= address + 0x4000
        self.bus.BUS_DATA_IN <= int(value)
        yield RisingEdge(self.clock)
        self.bus.WR_B <= 0
        yield Timer(1)  # This is hack for iverilog
        self.bus.BUS_DATA_IN <= int(value)
        self.bus.WR_B <= 0
        yield RisingEdge(self.clock)
        self.bus.WR_B <= 0
        yield Timer(1)  # This is hack for iverilog
        self.bus.BUS_DATA_IN <= int(value)
        self.bus.WR_B <= 0
        yield RisingEdge(self.clock)
        self.bus.WR_B <= 1
        self.bus.BUS_DATA_IN <= self._high_impedance
        yield Timer(1)  # This is hack for iverilog
        self.bus.WR_B <= 1
        self.bus.BUS_DATA_IN <= self._high_impedance
        yield RisingEdge(self.clock)
        self.bus.WR_B <= 1
        self.bus.ADD <= self._x
        self.bus.BUS_DATA_IN <= self._high_impedance

        for _ in range(5):
            yield RisingEdge(self.clock)

    @cocotb.coroutine
    def fast_block_read(self):
        yield RisingEdge(self.clock)
        self.bus.FREAD <= 1
        self.bus.FSTROBE <= 1
        yield ReadOnly()
        result = self.bus.FD.value.integer
        yield RisingEdge(self.clock)
        self.bus.FREAD <= 0
        self.bus.FSTROBE <= 0
        yield RisingEdge(self.clock)
        raise ReturnValue(result)
