############
Firmware
############

Simulation primitives
=====================

The models in ``basil/firmware/modules/utils`` are standalone functional
approximations. The 7-series interfaces follow UG953, including parameter and
positional port order. They do not require AMD simulation binaries or
``glbl``. They omit global GSR/GTS startup behavior, electrical effects,
SDF delays, timing checks and timing notifiers.

IDDR and ODDR support every functional parameter: edge mode, initial values,
clock/data inversion and synchronous/asynchronous reset and set. Reset wins
over set, including asynchronous reset-to-set handoff without a clock edge.
Unknown control inputs hold state; unknown data is captured when controls are
valid. Directed tests run with both Basil and AMD models when
``BASIL_UNISIM_DIR`` points to Vivado's ``data/verilog/src/unisims`` directory.
Those tests cover specific traces; they do not prove complete equivalence.

Other models retain these limitations:

* BUFG, IBUF, IBUFG, OBUF, OBUFDS, IOBUF, IBUFDS and IBUFGDS model digital
  buffer behavior. Drive strength, I/O standards, power settings and slew
  attributes do not model analog behavior. IBUFDS/IBUFGDS include floating-input
  bias behavior; IOBUF models high impedance and contention.
* IBUFDS_GTE2 uses a simplified differential input, enable and divide-by-two
  implementation. Enable changes and invalid differential pairs can differ
  from UNISIM's event behavior. Clock receiver configuration is not electrical.
* IDELAYCTRL asserts ready after four reference-clock rising edges following
  reset. It does not reproduce UNISIM's calibration or reference-clock loss
  detection. ``SIM_DEVICE`` does not select a separate device implementation.
* IDELAYE2/ODELAYE2 support fixed, variable and loaded counts, optional count
  pipelining, clock inversion and data-source selection. Their single scheduled
  delay uses an approximate tap interval from ``REFCLK_FREQUENCY``; it does
  not reproduce UNISIM's discrete frequency bands, tap-chain pulse filtering,
  or switching taps while a transition is in flight. High-performance and
  signal-pattern attributes do not change the digital delay approximation.
* OSERDESE2 supports the implemented SDR/DDR widths and 10-bit cascade.
  Unsupported widths, tristate combinations and byte grouping stop simulation.
  Its simple word-loading and serialization pipeline is not cycle-identical
  to AMD's binary-backed implementation. The cited third-party serializer
  supplied a cascade wiring example, not primitive behavioral internals.
* PLLE2_BASE/PLLE2_ADV approximate clock frequency, phase, duty cycle, reset,
  powerdown, input selection and dynamic reconfiguration. They do not model
  the feedback loop, analog lock/jitter behavior, compensation, bandwidth,
  reference-jitter settings or startup-wait semantics. Use UNISIM when those
  distinctions matter.

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

**Single write:** Assert ``BUS_WR`` for one cycle while placing the address and data on the bus.

.. raw:: html

    <script type="WaveDrom">
    { signal : [
      { name: "BUS_CLK",  wave: "p.." },
      { name: "BUS_WR",  wave: "010" },
      { name: "BUS_RD",  wave: "0.." },
      { name: "BUS_ADD",  wave: "x4x",   data: "addr" },
      { name: "BUS_DATA", wave: "x5x",   data: "data" },
    ]}
    </script>

**Single read:** Assert ``BUS_RD`` for one cycle with the address. Module responds with data on the following cycle.

.. raw:: html

    <script type="WaveDrom">
    { signal : [
      { name: "BUS_CLK",  wave: "p..." },
      { name: "BUS_WR",  wave: "0..." },
      { name: "BUS_RD",  wave: "010." },
      { name: "BUS_ADD",  wave: "x4x.",   data: "addr" },
      { name: "BUS_DATA", wave: "xx5x",   data: "data" },
    ]}
    </script>
