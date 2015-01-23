#
# ------------------------------------------------------------
# Copyright (c) All rights reserved
# SiLab, Institute of Physics, University of Bonn
# ------------------------------------------------------------
#

PWD=$(shell pwd)

SIMULATION_HOST?=localhost
SIMULATION_PORT?=12345
SIMULATION_BUS?=basil.utils.sim.SiLibUsbBusDriver
#SIMULATION_END_ON_DISCONNECT?=1

export SIMULATION_HOST
export SIMULATION_PORT
export SIMULATION_BUS
export SIMULATION_END_ON_DISCONNECT

BASIL = ../../../../../../basil
# Must have XILINX set as an environment variable.
# i.e. export XILINX=~/Xilinx/14.7/ISE_DS
#XILINX_SRC = $(XILINX)/ISE/verilog/src
XILINX_SRC = ./XILINX
    
VERILOG_SOURCES = \
                  $(BASIL)/trunk/device/modules/utils/*.v \
                  $(BASIL)/trunk/device/modules/tdc_s3/*.v \
                  $(BASIL)/trunk/device/modules/sram_fifo/*.v \
                  $(BASIL)/trunk/device/modules/fast_spi_rx/*.v \
                  $(BASIL)/trunk/device/modules/seq_gen/seq_gen_core.v \
                  $(BASIL)/trunk/device/modules/seq_gen/seq_gen.v \
                  $(BASIL)/trunk/device/modules/rrp_arbiter/*.v \
                  $(BASIL)/trunk/device/modules/gpio/gpio.v \
                  $(BASIL)/trunk/device/modules/tb/silbusb.v \
                  $(PWD)/pixel_cocotb.v \
                  $(XILINX_SRC)/unisims/IFDDRRSE.v \
                  $(XILINX_SRC)/unisims/BUFG.v \
                  $(XILINX_SRC)/unisims/OFDDRRSE.v \
                  $(XILINX_SRC)/unisims/DCM.v \
                  $(XILINX_SRC)/unisims/FDDRRSE.v \
                  $(XILINX_SRC)/unisims/FDRSE.v \
                  $(XILINX_SRC)/unisims/IBUF.v \
                  $(XILINX_SRC)/unisims/OBUF.v \
                  $(XILINX_SRC)/glbl.v \
                  $(PWD)/../src/*.v 

EXTRA_ARGS = -I$(BASIL)/trunk/device/modules/tb -D_IVERILOG_

TOPLEVEL = pixel_cocotb
MODULE   = basil.utils.sim.Test

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim
 

