############
Firmware
############

The FPGA firmware is built around a simple single-master bus connecting a set of standard modules. Control modules (SPI, GPIO) configure the DUT, while data-taking modules (receivers, TDCs) pass 32-bit words through an arbiter into a FIFO that the host can continuously read. Each word carries a source identifier so the host can demultiplex data from different modules.

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

Timing diagrams
================

The bus signals are ``BUS_CLK``, ``BUS_WR``, ``BUS_RD``, ``BUS_ADD`` (address), and ``BUS_DATA``. Writes and reads each complete in a single clock cycle.

**Single write:** assert ``BUS_WR`` for one cycle while placing the address and data on the bus.

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

**Single read:** assert ``BUS_RD`` for one cycle with the address. The module responds with data on the following cycle.

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

