# Basil

[![Build status](https://github.com/SiLab-Bonn/basil/workflows/Regression%20Tests/badge.svg)](https://github.com/silab-bonn/basil/actions?query=workflow%3A%22Regression+Tests%22)
[![Documentation](https://readthedocs.org/projects/basil/badge/?version=latest)](http://basil.rtfd.org)

Basil is a modular data acquisition (DAQ) framework developed by [SiLab](https://silab-bonn.github.io/) for the characterization of [monolithic](https://en.wikipedia.org/wiki/Monolithic_active_pixel_sensor) and [hybrid](https://en.wikipedia.org/wiki/Hybrid_pixel_detector) pixel detectors. It comprises a library of HDL modules (written in Verilog) for custom FPGA readout boards, paired with a collection of Python code that control the hardware over USB, Ethernet, or serial interfaces from a host PC. Basil also includes Python drivers for common lab instruments such as power supplies, oscilloscopes, and other bench equipment.

## Features

**Firmware:**
- Very simple single master bus definition
- Multiple basic modules (SPI, SEQ, GPIO, I2C, JTAG)
- Multiple interfaces (UART, USB2, USB3, Ethernet)

**Software:**
- Layer structure following hardware
- Generation based on YAML file
- Register abstract layer (RAL)
- Simulator interface allows software test against simulated RTL (thanks to [cocotb](https://github.com/cocotb/cocotb))

## Installation

Install via PyPI:

```bash
pip install basil-daq
```

> **Note:** The PyPI package may be outdated. Installing from source (below) is recommended to get the latest version.

Or install from source:

```bash
git clone https://github.com/SiLab-Bonn/basil.git
cd basil
pip install -e .
```

## Support

Please use GitHub's [issue tracker](https://github.com/SiLab-Bonn/basil/issues) for bug reports/feature requests/questions.

*For CERN users*: Feel free to subscribe to the [basil mailing list](https://e-groups.cern.ch/e-groups/EgroupsSubscription.do?egroupName=basil-devel).

## Documentation

Documentation can be found at: https://basil.rtfd.org

## Example Projects

- [TJ-Monopix2](https://github.com/SiLab-Bonn/tj-monopix2-daq) - DAQ for TJ-Monopix2 depleted monolithic pixel sensor
- [BDAQ53](https://gitlab.cern.ch/silab/bdaq53) - Readout system for ATLAS ITkPix (RD53) chips
- [LF-Monopix2](https://github.com/SiLab-Bonn/lf-monopix2-daq) - DAQ for LF-Monopix2 depleted monolithic pixel sensor
- [FRIDA](https://github.com/kcaisley/frida) - DAQ for FRIDA, an ADC test array for frame-based imaging detectors

## License

If not stated otherwise:

**Host Software:**
The host software is distributed under the BSD 3-Clause ("BSD New" or "BSD Simplified") License.

**FPGA Firmware:**
The FPGA code is distributed under the GNU Lesser General Public License, version 3.0 (LGPLv3).
