FPGA example builds
===================

Each FPGA example has a ``Makefile`` and ``run.tcl`` in its build-script
folder. HDL and constraints remain in the source tree; Vivado ``.xpr`` and
ISE ``.xise`` projects are generated under ``build/fpga/<example>/``.
Run the following commands from the Basil repository root with the appropriate
vendor tools on ``PATH``:

.. list-table:: Build-script directories
   :header-rows: 1

   * - Example
     - Directory passed to ``make -C``
     - Tool
   * - BDAQ53
     - ``examples/bdaq53/firmware/vivado``
     - Vivado
   * - BDAQ Core
     - ``examples/bdaq_core/firmware/vivado``
     - Vivado
   * - TDC BDAQ
     - ``examples/tdc_bdaq/firmware/vivado``
     - Vivado
   * - MMC3
     - ``examples/MMC3``
     - Vivado
   * - MMC3 Ethernet
     - ``examples/mmc3_eth/firmware/vivado``
     - Vivado
   * - MIO3 Ethernet / GPAC
     - ``examples/mio3_eth_gpac/firmware/vivado``
     - Vivado
   * - Ethernet test
     - ``examples/test_eth/firmware_test_eth/vivado``
     - Vivado
   * - MIO
     - ``examples/MIO/ise``
     - ISE
   * - MIO pixel
     - ``examples/mio_pixel/firmware/ise``
     - ISE
   * - MIO SRAM test
     - ``examples/mio_sram_test/firmware/ise``
     - ISE
   * - LX9
     - ``examples/lx9/device/ise``
     - ISE

For example::

    make -C examples/bdaq_core/firmware/vivado
    make -C examples/MIO/ise

The default target ``synthesize`` builds through bitstream generation.
``clean`` removes only that example's directory beneath ``build/fpga/``.
``VIVADO`` and ``XTCLSH`` can override the tool executable, for example::

    make -C examples/MIO/ise XTCLSH=/path/to/ISE/bin/lin64/xtclsh

Source the vendor environment before launching these commands. The ISE builds
still require ISE: Spartan-3 and Spartan-6 devices are not supported by Vivado.
The example scripts derive source paths from their own location rather than
from the shell's working directory. Launching through Make also puts the
vendor's startup journals and logs under ``build/fpga/``.

External inputs
---------------

Ethernet examples require separately supplied Bee Beans Technologies SiTCP
sources and netlists. These vendor inputs are not included in Basil.
The BDAQ and TDC Makefiles download them into ``firmware/SiTCP/`` before
building. MMC3 Ethernet and the Ethernet test have an explicit ``download``
target, which puts them in ``firmware/src/SiTCP/``::

    make -C examples/mmc3_eth/firmware/vivado download synthesize

Current Vivado builds use the V110 EDIF netlist
``SiTCP_XC7K_32K_BBT_V110.edf`` rather than its older ``.ngc`` counterpart.
MIO3 Ethernet / GPAC retains its original V80 Verilog dependency under
``firmware/src/SiTCP/``; supply the matching legacy vendor distribution.
LX9 retains its Spartan-6 V80 Verilog and NGC inputs under ``device/src/SiTCP/``;
the Kintex-7 download helper does not supply these.

The converted projects provide ``check`` and ``project`` targets. ``check``
uses ordinary ``tclsh`` to validate input paths without synthesis; ``project``
uses Vivado or ISE to recreate the project without running the build::

    make -C examples/MMC3 check
    make -C examples/MMC3 project

The original BDAQ and TDC scripts retain their existing full-build flow.
Creating a project or checking its inputs does not establish that a legacy
example passes synthesis, timing, or hardware tests with a newer tool release.
Changes made to generated projects in a GUI must be reflected in ``run.tcl``
if they should persist after recreation.
