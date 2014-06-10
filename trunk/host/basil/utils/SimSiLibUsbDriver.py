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
Abastract away interactions with the control bus
"""
import cocotb
from cocotb.binary import BinaryValue
from cocotb.triggers import Lock, RisingEdge, ReadOnly
from cocotb.drivers import BusDriver
from cocotb.result import ReturnValue

class FullSpeedBus(BusDriver):

    _signals = ["BUS_DATA", "ADD", "RD_B", "WR_B", "FD", "FREAD", "FSTROBE", "FMODE"]

    def __init__(self, entity, clock):
        BusDriver.__init__(self, entity, "", clock)

        # Create an appropriately sized high-impedence value
        self._high_impedence = BinaryValue(bits=len(self.bus.BUS_DATA))
        self._high_impedence.binstr = "Z"*len(self.bus.BUS_DATA)

        # Create an appropriately sized high-impedence value
        self._x = BinaryValue(bits=16)
        self._x.binstr = "x"*16

        # Defaults
        self.bus.RD_B   <= 1
        self.bus.WR_B   <= 1
        self.bus.ADD    <= 0
        self.bus.FREAD  <= 0
        self.bus.FSTROBE<= 0;
        self.bus.FMODE  <= 0;  
        self.bus.BUS_DATA <= self._high_impedence
        self.bus.FD <= self._high_impedence
        
    @cocotb.coroutine
    def read_external(self, address):
        """Copied from silusb.sv testbench interface"""
        self.bus.RD_B           <= 1
        self.bus.ADD            <= self._x
        self.bus.BUS_DATA       <= self._high_impedence

        for i in range(5):
            yield RisingEdge(self.clock)

        yield RisingEdge(self.clock)
        self.bus.ADD            <= address + 0x4000

        yield RisingEdge(self.clock)
        self.bus.RD_B           <= 0
        yield RisingEdge(self.clock)
        self.bus.RD_B           <= 0
        yield ReadOnly()
        result = self.bus.BUS_DATA.value.integer
        #print "read_external result", result
        yield RisingEdge(self.clock)
        self.bus.RD_B           <= 1
        
        yield RisingEdge(self.clock)
        self.bus.RD_B           <= 1
        self.bus.ADD            <= self._x

        yield RisingEdge(self.clock)
        #result = self.bus.BUS_DATA.value.integer
        
        for _ in range(5):
            yield RisingEdge(self.clock)
        
        raise ReturnValue(result)

 
    @cocotb.coroutine
    def write_external(self, address, value):
        """Copied from silusb.sv testbench interface"""
        self.bus.WR_B           <= 1
        self.bus.ADD            <= self._x

        for i in range(5):
            yield RisingEdge(self.clock)

        yield RisingEdge(self.clock)
        self.bus.ADD            <= address + 0x4000
        self.bus.BUS_DATA       <= value
        yield RisingEdge(self.clock)
        self.bus.WR_B           <= 0
        yield RisingEdge(self.clock)
        self.bus.WR_B           <= 0
        yield RisingEdge(self.clock)
        self.bus.WR_B           <= 1
        self.bus.BUS_DATA       <= self._high_impedence
        yield RisingEdge(self.clock)
        self.bus.WR_B           <= 1
        self.bus.ADD            <= self._x

        for _ in range(5):
            yield RisingEdge(self.clock)

    @cocotb.coroutine
    def fast_block_read(self):
        yield RisingEdge(self.clock)
        self.bus.FREAD  <= 1
        self.bus.FSTROBE<= 1
        yield RisingEdge(self.clock)
        self.bus.FREAD  <= 0
        self.bus.FSTROBE<= 0
        yield ReadOnly()
        result = self.bus.FD.value.integer
        yield RisingEdge(self.clock)
        raise ReturnValue(result)

