SCRIPT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
REPO_ROOT := $(abspath $(SCRIPT_DIR)/../../../..)
BUILD_DIR := $(REPO_ROOT)/build/fpga/tdc_bdaq

# Targets
.PHONY: all clean

# Run the main process
all: download synthesize

# Download SiTCP to the base directory
download:
	@echo "Downloading SiTCP library"
	cd "$(SCRIPT_DIR)" && python -c "from basil.utils import utils; utils.get_si_tcp('..')"

# Start synthesis
synthesize:
	@echo "Starting firmware synthesis"
	mkdir -p "$(BUILD_DIR)"
	cd "$(BUILD_DIR)" && vivado -mode batch -source "$(REPO_ROOT)/examples/tdc_bdaq/firmware/vivado/run.tcl" -notrace

# Clean generated files
clean:
	@echo "Removing generated Vivado files"
	rm -rf "$(BUILD_DIR)"
