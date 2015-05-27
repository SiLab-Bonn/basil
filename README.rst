===============================================
basil
===============================================

|travis-status|  |rtd-status|  |landscape-status|  |Gitter-status|

.. |travis-status| image:: https://travis-ci.org/SiLab-Bonn/basil.svg?branch=developemnt
    :target: https://travis-ci.org/SiLab-Bonn/basil
    :alt: Build status

.. |rtd-status| image:: https://readthedocs.org/projects/basil/badge/?version=latest
    :target: http://basil.rtfd.org
    :alt: Documentation
 
.. |landscape-status| image:: https://landscape.io/github/SiLab-Bonn/basil/development/landscape.svg?style=flat
   :target: https://landscape.io/github/SiLab-Bonn/basil/development
   :alt: Code Health
   
.. |Gitter-status| image:: https://badges.gitter.im/Join%20Chat.svg
   :target: https://gitter.im/SiLab-Bonn/basil?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge
   :alt: Gitter
  
Basil is a modular Rapid Data Acquisition System Design and Testing Framwork. 
It consists of different hardware components, FPGA firmware modulus and a Python based contol software.

Documentation
=============

Documentation can be found under: http://basil.rtfd.org

Installation
=============

.. code-block:: bash

    pip install -e "git+https://github.com/SiLab-Bonn/basil.git@development#egg=basil&subdirectory=host"

Support
=======

Basil mailing list: `subscribe <https://e-groups.cern.ch/e-groups/EgroupsSubscription.do?egroupName=basil-devel>`_

Features
============
Firmware:
  - very simple single master bus definition
  - multiple basic modules (SPI, SEQ, GPIO, I2C)
  - multiple interfaces (UART, USB2, USB3, Ethernet)
Software:
  - layer structure following hardware
  - generation based on yaml file
  - register abstract layer (RAL)
  - simulator interface allows software test against simulated RTL (thanks to `cocotb <https://github.com/potentialventures/cocotb>`_)

License
============

If not stated otherwise.

Host Software:
  The host software is distributed under the BSD 3-Clause ("BSD New" or "BSD Simplified") License.

FPGA Firmware:
  The FPGA software is distributed under the GNU Lesser General Public License, version 3.0 (LGPLv3).
