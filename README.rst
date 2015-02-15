===============================================
basil
===============================================

|travis-status|  |rtd-status| 

.. |travis-status| image:: https://travis-ci.org/SiLab-Bonn/basil.svg?branch=master
    :target: https://travis-ci.org/SiLab-Bonn/basil
    :alt: Build status

.. |rtd-status| image:: https://readthedocs.org/projects/basil/badge/?version=latest
    :target: http://basil.rtfd.org
    :alt: Documentation
 
Basil is a modular readout framework intended to allow simple and fast data acquisition systems (DAQ) design. 
It consists of different hardware components, FPGA firmware modulus and a Python based contol software.

Documentation
=============

Documenttion can be found under: http://basil.rtfd.org

Support
=======

Basil mailing list: `subscribe <https://e-groups.cern.ch/e-groups/EgroupsSubscription.do?egroupName=basil-devel>`_

Features
============
Firmware:
  - very simple single master bus definition
  - multiple basic modules (SPI, SEQ)
  - multiple interfaces (UART, USB2, USB3, Ethernet)
Software:
  - layer structure following hardware
  - generation based on yaml file
  - register abstract layer (RAL)
  - simulator interface allows software test against simulated RTL (thanks to `cocotb <https://github.com/potentialventures/cocotb>`_ )

License
============

If not stated otherwise.

Host Software:
  The host software is distributed under the BSD 3-Clause (“BSD New” or “BSD Simplified”) License.

FPGA Firmware:
  The FPGA software is distributed under the GNU Lesser General Public License, version 3.0 (LGPLv3).
