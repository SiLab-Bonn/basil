############
Firmware
############

HDL checks
==========

Install the Python bindings with ``pip install -e .[hdl-lint]`` and download
native tools with the shared installer::

    bash tools/install.sh verible "$PWD/build/tools/verible"
    bash tools/install.sh oss-cad-suite "$PWD/build/tools/oss-cad-suite"
    export PATH="$VIRTUAL_ENV/bin:$PWD/build/tools/verible/bin:$PWD/build/tools/oss-cad-suite/bin:$PATH"

The installer uses pinned, checksum-verified prebuilt packages; it does not
compile tools. Keep the project's Python environment ahead of the native tool
bundles on ``PATH`` so simulation uses the project's Cocotb installation.
Local commands and the separate CI jobs use the same four checks::

    python tools/run.py verilator-lint
    python tools/run.py slang-lint
    python tools/run.py verible-format
    python tools/run.py verible-lint

Verilator elaborates designs and reports connection, width, driver and latch
issues while enforcing Verilog-2005 and rejecting implicit nets. Slang provides
an independent check of names, types, parameters and elaboration. Verible
formatting standardizes whitespace and layout; Verible lint checks source
conventions and constructs that formatting alone cannot check.
``verible-format`` applies formatting and exits unsuccessfully when files
changed, so the same command catches uncommitted formatting changes in CI.

``tools/sources.py`` reads the shared ``[sources.hdl]`` section of
``pyproject.toml``; tool-specific arguments remain under ``[tool.verilator]``,
``[tool.slang]``, ``[tool.verible-format]`` and ``[tool.verible-lint]``.
Tool logs go under ``build/log/``, simulation output under ``build/sim/``,
pytest cache and JUnit output under ``build/tests/``, and coverage reports
under ``build/cov/``. Pytest's built-in temporary-directory option also keeps
standalone primitive simulations under ``build/sim/pytest/``.

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
* IBUFDS_GTE2 follows the functional UNISIM receiver: I drives O, enable is
  sampled when I changes, and the divider retains its phase while disabled.
  IB and clock receiver attributes do not add electrical behavior.
* IDELAYCTRL measures the reference-clock period and deasserts ready when an
  opposite clock edge is missing. Reset gates ready independently of that
  measurement. The model covers 7-series functional calibration, not physical
  calibration time or a separate UltraScale delay implementation.
* IDELAYE2/ODELAYE2 support fixed, variable and loaded counts, optional count
  pipelining, clock inversion and data-source selection. Their 32-tap chains
  use UNISIM's 78/52/39 ps intervals in the supported reference-frequency
  bands, with a 600 ps output delay. Short pulses and switching taps during a
  transition are modeled. Unknown controls hold counts; unknown count inputs
  retain the last complete value. High-performance and signal-pattern
  attributes do not add electrical behavior. Startup before the delay chain
  settles is not guaranteed to reproduce UNISIM's global initialization.
* OSERDESE2 supports the implemented SDR/DDR widths and 10-bit cascade.
  Unsupported widths, tristate combinations and byte grouping stop simulation.
  Its simple word-loading and serialization pipeline is not cycle-identical
  to AMD's ``secureip`` implementation. The cited third-party serializer
  supplied a cascade wiring example, not primitive behavioral internals.
  DDR tristate width 1 also differs on release of reset with ``SRVAL_TQ=1``;
  the optional vendor comparison marks that known difference explicitly.
* PLLE2_BASE/PLLE2_ADV approximate clock frequency, phase, duty cycle, reset,
  powerdown, input selection and dynamic reconfiguration. They do not model
  the feedback loop, analog lock/jitter behavior, compensation, bandwidth,
  reference-jitter settings or startup-wait semantics. Use UNISIM when those
  distinctions matter.

Verification
------------

Interface tests check all 17 primitive declarations, including positional
port order and parameter types/widths. Functional tests cover buffers,
DDR edge/reset modes, GTE receiver/divider events, delay controls and tap
transitions, serializer words/tristate/attributes, and PLL output frequency,
phase, duty cycle, reset, powerdown and dynamic reconfiguration.

For optional comparisons with an installed Vivado 2025.2 library, run::

    BASIL_UNISIM_DIR=/path/to/Vivado/data/verilog/src/unisims python -m pytest \
        tests/test_SimDdr.py tests/test_SimXilinxInterfaces.py \
        tests/test_SimXilinxAccuracy.py

The accuracy tests compare directed and seeded DDR/delay traces and PLL
steady-state measurements. Set ``BASIL_XSIM=1`` with ``xvlog``, ``xelab`` and
``xsim`` on PATH to also check serializer attributes against ``unisims_ver``
and ``secureip``. Vendor sources and binaries remain external. Serializer
attribute comparisons do not establish equivalence of its word-loading
latency, cascade or unsupported modes.

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
