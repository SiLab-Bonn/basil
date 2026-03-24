===============================================
Basil
===============================================

|gha-status|  |rtd-status|

.. |gha-status| image:: https://github.com/SiLab-Bonn/basil/workflows/Regression%20Tests/badge.svg
    :target: https://github.com/silab-bonn/basil/actions?query=workflow%3A%22Regression+Tests%22
    :alt: Build status

.. |rtd-status| image:: https://readthedocs.org/projects/basil/badge/?version=latest
    :target: http://basil.rtfd.org
    :alt: Documentation

Basil is a modular data acquisition (DAQ) framework built for the characterization of `monolithic <https://en.wikipedia.org/wiki/Monolithic_active_pixel_sensor>`_ and `hybrid <https://en.wikipedia.org/wiki/Hybrid_pixel_detector>`_ pixel detectors. It comprises a library of HDL modules (written in Verilog) for custom FPGA readout boards, paired with a collection of Python code that control the hardware over TCP from a host PC.

Features
========
Firmware:
  - very simple single master bus definition
  - multiple basic modules (SPI, SEQ, GPIO, I2C, JTAG)
  - multiple interfaces (UART, USB2, USB3, Ethernet)
Software:
  - layer structure following hardware
  - generation based on yaml file
  - register abstract layer (RAL)
  - simulator interface allows software test against simulated RTL (thanks to `cocotb <https://github.com/cocotb/cocotb>`_)

Installation
============

Install via PyPI:

.. code-block:: bash

    pip install basil-daq

.. note::

    The PyPI package may be outdated. Installing from source (below) is recommended to get the latest version.

Or install from source:

.. code-block:: bash

    git clone https://github.com/SiLab-Bonn/basil.git
    cd basil
    pip install -e .

Support
=======

Please use GitHub's `issue tracker <https://github.com/SiLab-Bonn/basil/issues>`_ for bug reports/feature requests/questions.

*For CERN users*: Feel free to subscribe to the `basil mailing list <https://e-groups.cern.ch/e-groups/EgroupsSubscription.do?egroupName=basil-devel>`_

Documentation
=============

Documentation can be found under: https://basil.rtfd.org

Example Projects
================
- `TJ-Monopix2 <https://github.com/SiLab-Bonn/tj-monopix2-daq>`_ - DAQ for TJ-Monopix2 depleted monolithic pixel sensor
- `BDAQ53 <https://gitlab.cern.ch/silab/bdaq53>`_ - Readout system for ATLAS ITkPix (RD53) chips
- `LF-Monopix2 <https://github.com/SiLab-Bonn/lf-monopix2-daq>`_ - DAQ for LF-Monopix2 depleted monolithic pixel sensor
- `FRIDA <https://github.com/kcaisley/frida>`_ - DAQ for FRIDA, an ADC test array for frame-based imaging detectors

License
=======

If not stated otherwise.

Host Software:
  The host software is distributed under the BSD 3-Clause ("BSD New" or "BSD Simplified") License.

FPGA Firmware:
  The FPGA code is distributed under the GNU Lesser General Public License, version 3.0 (LGPLv3).
