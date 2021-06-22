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
from cocotb.binary import BinaryValue
from cocotb.triggers import RisingEdge, ReadOnly, Timer
from cocotb_bus.drivers import BusDriver


class SiLibUsbBusDriver(BusDriver):

    _signals = ["FCLK_IN", "BUS_DATA", "ADD", "RD_B", "WR_B", "FD", "FREAD", "FSTROBE", "FMODE"]

    BASE_ADDRESS_I2C = 0x00000
    HIGH_ADDRESS_I2C = BASE_ADDRESS_I2C + 256

    BASE_ADDRESS_EXTERNAL = 0x10000
    HIGH_ADDRESS_EXTERNAL = 0x10000 + 0x10000

    BASE_ADDRESS_BLOCK = 0x0001000000000000
    HIGH_ADDRESS_BLOCK = 0xFFFFFFFFFFFFFFFF

    def __init__(self, entity):
        BusDriver.__init__(self, entity, "", entity.FCLK_IN)

        # Create an appropriately sized high-impedance value
        self._high_impedance = BinaryValue(n_bits=len(self.bus.BUS_DATA))
        self._high_impedance.binstr = "Z" * len(self.bus.BUS_DATA)

        # Create an appropriately sized high-impedance value
        self._x = BinaryValue(n_bits=16)
        self._x.binstr = "x" * 16

    async def init(self):
        # Defaults
        # self.bus.BUS_RST<= 1
        self.bus.RD_B <= 1
        self.bus.WR_B <= 1
        self.bus.ADD <= 0
        self.bus.FREAD <= 0
        self.bus.FSTROBE <= 0
        self.bus.FMODE <= 0
        self.bus.BUS_DATA <= self._high_impedance
        self.bus.FD <= self._high_impedance

        # wait for reset
        for _ in range(200):
            await RisingEdge(self.clock)

    async def read(self, address, size):
        result = []
        if address >= self.BASE_ADDRESS_I2C and address < self.HIGH_ADDRESS_I2C:
            self.entity._log.warning("I2C address space supported in simulation!")
            for byte in range(size):
                result.append(0)
        elif address >= self.BASE_ADDRESS_EXTERNAL and address < self.HIGH_ADDRESS_EXTERNAL:
            for byte in range(size):
                val = await self.read_external(address - self.BASE_ADDRESS_EXTERNAL + byte)
                result.append(val)
        elif address >= self.BASE_ADDRESS_BLOCK and address < self.HIGH_ADDRESS_BLOCK:
            for byte in range(size):
                val = await self.fast_block_read()
                result.append(val)
        else:
            self.entity._log.warning("This address space does not exist!")

        return result

    async def write(self, address, data):
        if address >= self.BASE_ADDRESS_I2C and address < self.HIGH_ADDRESS_I2C:
            self.entity._log.warning("I2C address space supported in simulation!")
        elif address >= self.BASE_ADDRESS_EXTERNAL and address < self.HIGH_ADDRESS_EXTERNAL:
            for index, byte in enumerate(data):
                await self.write_external(address - self.BASE_ADDRESS_EXTERNAL + index, byte)
        elif address >= self.BASE_ADDRESS_BLOCK and address < self.HIGH_ADDRESS_BLOCK:
            raise NotImplementedError("Unsupported request")
            # self._sidev.FastBlockWrite(data)
        else:
            self.entity._log.warning("This address space does not exist!")

    async def read_external(self, address):
        """Copied from silusb.sv testbench interface"""
        self.bus.RD_B <= 1
        self.bus.ADD <= self._x
        self.bus.BUS_DATA <= self._high_impedance
        for _ in range(5):
            await RisingEdge(self.clock)

        await RisingEdge(self.clock)
        self.bus.ADD <= address + 0x4000

        await RisingEdge(self.clock)
        self.bus.RD_B <= 0
        await RisingEdge(self.clock)
        self.bus.RD_B <= 0
        await ReadOnly()
        result = self.bus.BUS_DATA.value.integer
        await RisingEdge(self.clock)
        self.bus.RD_B <= 1

        await RisingEdge(self.clock)
        self.bus.RD_B <= 1
        self.bus.ADD <= self._x

        await RisingEdge(self.clock)

        for _ in range(5):
            await RisingEdge(self.clock)

        return result

    async def write_external(self, address, value):
        """Copied from silusb.sv testbench interface"""
        self.bus.WR_B <= 1
        self.bus.ADD <= self._x

        for _ in range(5):
            await RisingEdge(self.clock)

        await RisingEdge(self.clock)
        self.bus.ADD <= address + 0x4000
        self.bus.BUS_DATA <= int(value)
        await Timer(1)  # This is hack for iverilog
        self.bus.ADD <= address + 0x4000
        self.bus.BUS_DATA <= int(value)
        await RisingEdge(self.clock)
        self.bus.WR_B <= 0
        await Timer(1)  # This is hack for iverilog
        self.bus.BUS_DATA <= int(value)
        self.bus.WR_B <= 0
        await RisingEdge(self.clock)
        self.bus.WR_B <= 0
        await Timer(1)  # This is hack for iverilog
        self.bus.BUS_DATA <= int(value)
        self.bus.WR_B <= 0
        await RisingEdge(self.clock)
        self.bus.WR_B <= 1
        self.bus.BUS_DATA <= self._high_impedance
        await Timer(1)  # This is hack for iverilog
        self.bus.WR_B <= 1
        self.bus.BUS_DATA <= self._high_impedance
        await RisingEdge(self.clock)
        self.bus.WR_B <= 1
        self.bus.ADD <= self._x

        for _ in range(5):
            await RisingEdge(self.clock)

    async def fast_block_read(self):
        await RisingEdge(self.clock)
        self.bus.FREAD <= 1
        self.bus.FSTROBE <= 1
        await ReadOnly()
        result = self.bus.FD.value.integer
        await RisingEdge(self.clock)
        self.bus.FREAD <= 0
        self.bus.FSTROBE <= 0
        await RisingEdge(self.clock)
        return result
