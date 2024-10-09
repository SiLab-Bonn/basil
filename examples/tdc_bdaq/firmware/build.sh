#/bin/sh
# This script downloads the SiTCP Ethernet IP core, creates a vivado project and starts the synthesis.
# The bitfile is copied to the `output` directory.
python fw_utils.py
cd vivado
time vivado -mode batch -source run.tcl -notrace
