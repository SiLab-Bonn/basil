#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#
#Initial version by Chris Higgs <chris.higgs@potentialventures.com>
#

"""
Abastract away interactions with the control bus
"""
import cocotb
from cocotb.binary import BinaryValue
from cocotb.triggers import Lock, RisingEdge, ReadOnly, Timer
from cocotb.drivers import BusDriver
from cocotb.result import ReturnValue
from cocotb.clock import Clock

class BasilBusDriver(BusDriver):

    _signals = ["BUS_CLK", "BUS_RST", "BUS_DATA", "BUS_ADD", "BUS_RD", "BUS_WR"]

    def __init__(self, entity):
        BusDriver.__init__(self, entity, "", entity.BUS_CLK)

        # Create an appropriately sized high-impedence value
        self._high_impedence = BinaryValue(bits=len(self.bus.BUS_DATA))
        self._high_impedence.binstr = "Z"*len(self.bus.BUS_DATA)

        # Create an appropriately sized high-impedence value
        self._x = BinaryValue(bits=len(self.bus.BUS_ADD))
        self._x.binstr = "x"*len(self.bus.BUS_ADD)

        # Kick off a clock generator
        cocotb.fork(Clock(self.clock, 5000).start())
    
        
    @cocotb.coroutine
    def init(self):
        # Defaults
        self.bus.BUS_RST  <= 1
        self.bus.BUS_RD   <= 0
        self.bus.BUS_WR   <= 0
        self.bus.BUS_ADD  <= self._x
        self.bus.BUS_DATA <= self._high_impedence
     
        for i in range(5):
            yield RisingEdge(self.clock)
        
        self.bus.BUS_RST  <= 0
        
        for i in range(5):
            yield RisingEdge(self.clock)

    @cocotb.coroutine
    def read(self, address, size):
        result = []
        
        self.bus.BUS_DATA   <= self._high_impedence
        self.bus.BUS_ADD    <= self._x
        self.bus.BUS_RD     <= 0
        
        yield RisingEdge(self.clock)
        
        for byte in xrange(size):
            #self.bus.BUS_DATA   <= self._high_impedence
            self.bus.BUS_RD     <= 1
            self.bus.BUS_ADD    <= address + byte
            #yield Timer(500) # This is hack for iverilog
            self.bus.BUS_RD     <= 1
            self.bus.BUS_ADD    <= address + byte
            yield RisingEdge(self.clock)
            if(byte != 0):
                result.append(self.bus.BUS_DATA.value.integer)
        
        self.bus.BUS_RD     <= 0
        yield RisingEdge(self.clock)
        result.append(self.bus.BUS_DATA.value.integer)
        
        self.bus.BUS_ADD    <= self._x
        self.bus.BUS_DATA   <= self._high_impedence
        yield RisingEdge(self.clock)
        
        raise ReturnValue(result)
    
    @cocotb.coroutine
    def write(self, address, data):
    
        self.bus.BUS_ADD    <= self._x
        self.bus.BUS_DATA   <= self._high_impedence
        self.bus.BUS_WR     <= 0
        
        yield RisingEdge(self.clock)
        
        for index, byte in enumerate(data):
            self.bus.BUS_DATA   <= byte
            self.bus.BUS_WR     <= 1
            self.bus.BUS_ADD    <= address + index
            yield Timer(1) # This is hack for iverilog
            self.bus.BUS_DATA   <= byte
            self.bus.BUS_WR     <= 1
            self.bus.BUS_ADD    <= address + index
            yield RisingEdge(self.clock)
            
        self.bus.BUS_DATA   <= self._high_impedence
        self.bus.BUS_ADD    <= self._x
        self.bus.BUS_WR     <= 0
        
        yield RisingEdge(self.clock)
        



