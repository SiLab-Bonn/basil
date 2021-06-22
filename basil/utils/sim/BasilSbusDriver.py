#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

# pylint: disable=pointless-statement, expression-not-assigned


from cocotb.binary import BinaryValue
from cocotb.triggers import RisingEdge, ReadOnly
from cocotb_bus.drivers import BusDriver


class BasilSbusDriver(BusDriver):
    """Abastract away interactions with the control bus."""

    _signals = ["BUS_CLK", "BUS_RST", "BUS_DATA_IN", "BUS_DATA_OUT", "BUS_ADD", "BUS_RD", "BUS_WR"]
    _optional_signals = ["BUS_BYTE_ACCESS"]

    def __init__(self, entity):
        BusDriver.__init__(self, entity, "", entity.BUS_CLK)

        # Create an appropriately sized high-impedance value
        self._high_impedance = BinaryValue(n_bits=len(self.bus.BUS_DATA_IN))
        self._high_impedance.binstr = "Z" * len(self.bus.BUS_DATA_IN)

        # Create an appropriately sized high-impedance value
        self._x = BinaryValue(n_bits=len(self.bus.BUS_ADD))
        self._x.binstr = "x" * len(self.bus.BUS_ADD)

        self._has_byte_acces = False

    async def init(self):
        # Defaults
        self.bus.BUS_RST <= 1
        self.bus.BUS_RD <= 0
        self.bus.BUS_WR <= 0
        self.bus.BUS_ADD <= self._x
        self.bus.BUS_DATA_IN <= self._high_impedance

        for _ in range(8):
            await RisingEdge(self.clock)

        self.bus.BUS_RST <= 0

        for _ in range(2):
            await RisingEdge(self.clock)

        # why this does not work? hasattr(self.bus, 'BUS_BYTE_ACCESS'):
        try:
            getattr(self.bus, "BUS_BYTE_ACCESS")
        except Exception:
            self._has_byte_acces = False
        else:
            self._has_byte_acces = True

    async def read(self, address, size):
        result = []

        await RisingEdge(self.clock)

        if size == 0:
            return result

        self.bus.BUS_RD <= 1
        self.bus.BUS_ADD <= address

        byte = 0

        while byte < size:

            await RisingEdge(self.clock)

            if self._has_byte_acces and self.bus.BUS_BYTE_ACCESS.value.integer == 0:
                byte += 4
            else:
                byte += 1

            self.bus.BUS_ADD <= address + byte
            if byte >= size:
                self.bus.BUS_RD <= 0

            await ReadOnly()

            value = self.bus.BUS_DATA_OUT.value

            if self._has_byte_acces and self.bus.BUS_BYTE_ACCESS.value.integer == 0:
                result.append(value.integer & 0x000000FF)
                result.append((value.integer & 0x0000FF00) >> 8)
                result.append((value.integer & 0x00FF0000) >> 16)
                result.append((value.integer & 0xFF000000) >> 24)
            elif len(value) == 8:
                result.append(value.integer & 0xFF)
            else:
                result.append(value[24:31].integer & 0xFF)

        await RisingEdge(self.clock)

        self.bus.BUS_ADD <= self._x
        self.bus.BUS_RD <= 0

        return result

    async def write(self, address, data):

        await RisingEdge(self.clock)

        for index, byte in enumerate(data):
            self.bus.BUS_DATA_IN <= byte
            self.bus.BUS_WR <= 1
            self.bus.BUS_ADD <= address + index

            await RisingEdge(self.clock)

        if self._has_byte_acces and self.bus.BUS_BYTE_ACCESS.value.integer == 0:
            raise NotImplementedError("BUS_BYTE_ACCESS for write to be implemented.")

        self.bus.BUS_ADD <= self._x
        self.bus.BUS_DATA_IN <= self._high_impedance
        self.bus.BUS_WR <= 0
