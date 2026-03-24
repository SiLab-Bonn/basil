############
Overview
############

Basil is a modular data acquisition (DAQ) framework developed by `SiLab <https://silab-bonn.github.io/>`_ for the characterization of `monolithic <https://en.wikipedia.org/wiki/Monolithic_active_pixel_sensor>`_ and `hybrid <https://en.wikipedia.org/wiki/Hybrid_pixel_detector>`_ pixel detectors. It comprises a library of HDL modules (written in Verilog) for custom FPGA readout boards, paired with a collection of Python code that control the hardware over TCP/IP from a host PC.

Features
===========================

Firmware:
  - very simple single master `bus definition`_
  - multiple `basic modules <https://github.com/SiLab-Bonn/basil/tree/master/basil/firmware/modules>`_ (ex. SPI, SEQ)
  - multiple `interfaces <https://github.com/SiLab-Bonn/basil/tree/master/basil/TL>`_ (UART, USB2, USB3, Ethernet)
Software:
  - layer structure following hardware
  - generation based on yaml file
  - register abstract layer (RAL)
  - simulator interface allows software test against simulated RTL (thanks to `cocotb <https://github.com/cocotb/cocotb>`_ )


.. _`bus definition`: firmware.html#basil-bus

Installation
========================

.. code-block:: bash

  pip install basil-daq

or for development from source:

.. code-block:: bash

  git clone https://github.com/SiLab-Bonn/basil.git
  cd basil
  pip install -e .


Simulation
========================

Basil has a simulation interface (SiSim) which allows communication with a simulator as if talking to real hardware, thanks to `cocotb <https://github.com/cocotb/cocotb>`_.

To run a simulation you need:
  - a Verilog simulator (e.g. `Icarus <https://github.com/steveicarus/iverilog>`_ )
  - `cocotb <https://github.com/cocotb/cocotb>`_ library
  - set interface type to SiSim

Basil unit tests make extensive use of this feature. See the tests folder.

License
=====================

If not stated otherwise:

Host Software:
  The host software is distributed under the BSD 3-Clause ("BSD New" or "BSD Simplified") License.

FPGA Firmware:
  The FPGA firmware is distributed under the GNU Lesser General Public License, version 3.0 (LGPLv3).


.. toctree::
   :hidden:

   self
   hardware
   firmware
   software
   modules
   examples
