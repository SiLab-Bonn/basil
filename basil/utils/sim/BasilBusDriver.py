#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
# Initial version by Chris Higgs <chris.higgs@potentialventures.com>
#

# pylint: disable=pointless-statement, expression-not-assigned


from cocotb.binary import BinaryValue
from cocotb.triggers import RisingEdge, Timer
from cocotb_bus.drivers import BusDriver


class BasilBusDriver(BusDriver):
    """Abastract away interactions with the control bus."""

    _signals = ["BUS_CLK", "BUS_RST", "BUS_DATA", "BUS_ADD", "BUS_RD", "BUS_WR"]
    _optional_signals = ["BUS_BYTE_ACCESS"]

    def __init__(self, entity):
        BusDriver.__init__(self, entity, "", entity.BUS_CLK)

        # Create an appropriately sized high-impedence value
        self._high_impedence = BinaryValue(n_bits=len(self.bus.BUS_DATA))
        self._high_impedence.binstr = "Z" * len(self.bus.BUS_DATA)

        # Create an appropriately sized high-impedence value
        self._x = BinaryValue(n_bits=len(self.bus.BUS_ADD))
        self._x.binstr = "x" * len(self.bus.BUS_ADD)

        self._has_byte_acces = False

    async def init(self):
        # Defaults
        self.bus.BUS_RST <= 1
        self.bus.BUS_RD <= 0
        self.bus.BUS_WR <= 0
        self.bus.BUS_ADD <= self._x
        self.bus.BUS_DATA <= self._high_impedence

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

        self.bus.BUS_DATA <= self._high_impedence
        self.bus.BUS_ADD <= self._x
        self.bus.BUS_RD <= 0

        await RisingEdge(self.clock)

        byte = 0
        while byte <= size:
            if byte == size:
                self.bus.BUS_RD <= 0
            else:
                self.bus.BUS_RD <= 1

            self.bus.BUS_ADD <= address + byte

            await RisingEdge(self.clock)

            if byte != 0:
                if self._has_byte_acces and self.bus.BUS_BYTE_ACCESS.value.integer == 0:
                    result.append(self.bus.BUS_DATA.value.integer & 0x000000FF)
                    result.append((self.bus.BUS_DATA.value.integer & 0x0000FF00) >> 8)
                    result.append((self.bus.BUS_DATA.value.integer & 0x00FF0000) >> 16)
                    result.append((self.bus.BUS_DATA.value.integer & 0xFF000000) >> 24)
                else:
                    #    result.append(self.bus.BUS_DATA.value[24:31].integer & 0xff)
                    if len(self.bus.BUS_DATA.value) == 8:
                        result.append(self.bus.BUS_DATA.value.integer & 0xFF)
                    else:
                        result.append(self.bus.BUS_DATA.value[24:31].integer & 0xFF)

            if self._has_byte_acces and self.bus.BUS_BYTE_ACCESS.value.integer == 0:
                byte += 4
            else:
                byte += 1

        self.bus.BUS_ADD <= self._x
        self.bus.BUS_DATA <= self._high_impedence
        await RisingEdge(self.clock)

        return result

    async def write(self, address, data):

        self.bus.BUS_ADD <= self._x
        self.bus.BUS_DATA <= self._high_impedence
        self.bus.BUS_WR <= 0

        await RisingEdge(self.clock)

        for index, byte in enumerate(data):
            self.bus.BUS_DATA <= byte
            self.bus.BUS_WR <= 1
            self.bus.BUS_ADD <= address + index
            await Timer(1)  # This is hack for iverilog
            self.bus.BUS_DATA <= byte
            self.bus.BUS_WR <= 1
            self.bus.BUS_ADD <= address + index

            await RisingEdge(self.clock)

        if self._has_byte_acces and self.bus.BUS_BYTE_ACCESS.value.integer == 0:
            raise NotImplementedError("BUS_BYTE_ACCESS for write to be implemented.")

        self.bus.BUS_DATA <= self._high_impedence
        self.bus.BUS_ADD <= self._x
        self.bus.BUS_WR <= 0

        await RisingEdge(self.clock)
