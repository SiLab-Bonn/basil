############
Firmware
############

FPGA firmware consists of very simple single master bus definition and set of standard modules used by DAQ systems.

Typical firmware consists of a basil bus connecting all modules. Control modules which provide configuration to DUT (like SPI/GPIO) and data taking modules (like data receivers). Received data (32 bit) are stored in the FIFO (large extremal memory) and can be continuously pulled from host application. Data from different modules are identified by source codding in 32bit data words.

.. graphviz::

   digraph {
     rankdir=LR;
     node [shape=box];

     Interface -> SPI [color=blue, dir=both, label="bus"];
     Interface -> GPIO [color=blue, dir=both];
     Interface -> RX [color=blue, dir=both, label="bus"];
     Interface -> TDC [color=blue, dir=both];
     Interface -> FIFO [color=blue, dir=both];
     TDC -> Arbiter [color=green, label="data"];
     RX -> Arbiter [color=green];
     Arbiter -> FIFO [color=green];
   }

basil bus
=========

single write
  .. raw:: html

    <script type="WaveDrom">
    { signal : [
      { name: "BUS_CLK",  wave: "p.." },
      { name: "BUS_WR",  wave: "010" },
      { name: "BUS_RD",  wave: "0.." },
      { name: "BUS_ADD",  wave: "x3x",   data: "data" },
      { name: "BUS_DATA", wave: "x4x",   data: "addr" },
    ]}
    </script>


single read
  .. raw:: html

    <script type="WaveDrom">
    { signal : [
      { name: "BUS_CLK",  wave: "p..." },
      { name: "BUS_WR",  wave: "0..." },
      { name: "BUS_RD",  wave: "010." },
      { name: "BUS_ADD",  wave: "xx5x",   data: "data" },
      { name: "BUS_DATA", wave: "x4xx",   data: "addr" },
    ]}
    </script>

