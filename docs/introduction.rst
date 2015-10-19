############
Introduction
############

Basil is a modular readout framework intended to allow simple and fast data acquisition systems (DAQ) design. It consists of different hardware components, FPGA firmware modulus and a Python based control software.

Features
===========================

Firmware:
  - very simple single master `bus definition`_
  - multiple `basic modules <https://github.com/SiLab-Bonn/basil/tree/master/firmware/modules>`_ (ex. SPI, SEQ)
  - multiple `interfaces <https://github.com/SiLab-Bonn/basil/tree/master/basil/TL>`_ (UART, USB2, USB3, Ethernet)
Software:
  - layer structure following hardware
  - generation based on yaml file
  - register abstract layer (RAL)
  - simulator interface allows software test against simulated RTL (thanks to `cocotb <https://github.com/potentialventures/cocotb>`_ )


.. _`bus definition`: firmware.html#basil-bus

Installation
========================

From host folder run:

.. code-block:: bash

  python setup.py install
  
or
  
.. code-block:: bash

  pip install -e "git+https://github.com/SiLab-Bonn/basil.git#egg=basil&subdirectory=host"
  
  
Simulation
========================

Thank to `Chris Higgs <https://github.com/chiggs>`_  basil has a simulation interface (SiSim) with allow communication with simulator as if talking to real hardware.

To make simulation one need:
  - verilog simulator (ex. `Icarus <https://github.com/steveicarus/iverilog>`_ )
  - `cocotb <https://github.com/potentialventures/cocotb>`_ library
  - set interface type to SiSim
  - set $COCOTB environment variable to path to cocotb

Basil unit tests make extensive use of this feature. See tests folder.

License
=====================

If not stated otherwise.

Host Software:
  The host software is distributed under the BSD 3-Clause (“BSD New” or “BSD Simplified”) License.

FPGA Firmware:
  The FPGA software is distributed under the GNU Lesser General Public License, version 3.0 (LGPLv3).
