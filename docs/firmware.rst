############
Firmware
############

The FPGA firmware is built around a simple single-master bus connecting a set of standard modules. Control modules (SPI, GPIO) configure the DUT, while data-taking modules (receivers, TDCs) pass 32-bit words through an arbiter into a FIFO that the host can continuously read. Each word carries a source identifier so the host can demultiplex data from different modules.

.. graphviz::

    digraph {
        rankdir=LR;
        splines=polyline;
        nodesep=0.5;
        ranksep=0.8;
        node [shape=box, fixedsize=true, width=0.75, height=0.4];
        j1 [shape=point, width=0.01];
        j2 [shape=point, width=0.01];
        j3 [shape=point, width=0.01];
        j4 [shape=point, width=0.01];
        j5 [shape=point, width=0.01];
        Interface [fixedsize=true, width=0.9, height=0.4];
        Interface -> j3 [color=blue, arrowhead=none, dir=back];
        j1 -> j2 [color=blue, arrowhead=none];
        j2 -> j3 [color=blue, arrowhead=none];
        j3 -> j4 [color=blue, arrowhead=none];
        j4 -> j5 [color=blue, arrowhead=none];
        j1 -> SPI   [color=blue, headport=w, tailport=e];
        j2 -> GPIO  [color=blue, headport=w, tailport=e];
        j3 -> RX    [color=blue, headport=w, tailport=e];
        j4 -> TDC   [color=blue, headport=w, tailport=e];
        j5 -> FIFO  [color=blue, headport=w, tailport=e];
        RX -> Arbiter [color=green, headport=n, tailport=e];
        TDC -> Arbiter [color=green, headport=w, tailport=e];
        Arbiter -> FIFO [color=green, headport=e, tailport=s];
        { rank=same; j1; j2; j3; j4; j5; }
        { rank=same; SPI; GPIO; RX; TDC; FIFO; }
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
