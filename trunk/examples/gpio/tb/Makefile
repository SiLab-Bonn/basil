PWD = $(shell pwd)

SIMULATION_HOST?=localhost
SIMULATION_PORT?=12345

export SIMULATION_HOST
export SIMULATION_PORT

VERILOG_SOURCES = $(PWD)/../../../device/modules/utils/reset_gen.v \
                  $(PWD)/../../../device/modules/utils/bus_to_ip.v \
                  $(PWD)/../../../device/modules/gpio/gpio8.v \
                  $(PWD)/../src/example.v \
                  $(PWD)/example_top.v

TOPLEVEL = example_top
MODULE   = basil.utils.SimSiLibUsbTest

include $(COCOTB)/makefiles/Makefile.inc
include $(COCOTB)/makefiles/Makefile.sim

