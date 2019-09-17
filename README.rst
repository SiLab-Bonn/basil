===============================================
Basil
===============================================

|travis-status|  |rtd-status|  |landscape-status|

.. |travis-status| image:: https://travis-ci.org/SiLab-Bonn/basil.svg?branch=master
    :target: https://travis-ci.org/SiLab-Bonn/basil
    :alt: Build status

.. |rtd-status| image:: https://readthedocs.org/projects/basil/badge/?version=latest
    :target: http://basil.rtfd.org
    :alt: Documentation

.. |landscape-status| image:: https://landscape.io/github/SiLab-Bonn/basil/master/landscape.svg?style=flat
   :target: https://landscape.io/github/SiLab-Bonn/basil/master
   :alt: Code Health

Basil is a modular data acquisition system and system testing framework in Python.

It also provides generic FPGA firmware modules for different hardware platforms and drivers for wide range of lab appliances.

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
  - simulator interface allows software test against simulated RTL (thanks to `cocotb <https://github.com/potentialventures/cocotb>`_)

Installation
============

Clone the repository to get a copy of the source code (for developers):

.. code-block:: bash

    git clone https://github.com/SiLab-Bonn/basil.git
    cd basil
    pip install -e .

or install via PyPI into the Python's site-packages folder (for non-developers):

.. code-block:: bash

    pip install basil_daq==version

where version is a version number (e.g., 3.0.1)

or install from git, when no PyPI package is available (for non-developers):

.. code-block:: bash

    pip install git+https://github.com/SiLab-Bonn/basil.git@branch

where branch is a branch name or tag (e.g., master or v3.0.1).

Check `.travis.yml <.travis.yml>`_ for installation/testing hints.

Support
=======

Please use GitHub's `issue tracker <https://github.com/SiLab-Bonn/basil/issues>`_ for bug reports/feature requests/questions.

*For CERN users*: Feel free to subscribe to the `basil mailing list <https://e-groups.cern.ch/e-groups/EgroupsSubscription.do?egroupName=basil-devel>`_

Documentation
=============

Documentation can be found under: https://basil.rtfd.org

Example Projects:
=================
- `pyBAR <https://github.com/SiLab-Bonn/pyBAR>`_ - Bonn ATLAS Readout in Python
- `MCA <https://github.com/SiLab-Bonn/MCA>`_ - Multi Channel Analyzer
- `fe65_p2 <https://github.com/SiLab-Bonn/fe65_p2>`_ - DAQ for FE65P2 prototype

License
=======

If not stated otherwise.

Host Software:
  The host software is distributed under the BSD 3-Clause ("BSD New" or "BSD Simplified") License.

FPGA Firmware:
  The FPGA code is distributed under the GNU Lesser General Public License, version 3.0 (LGPLv3).
