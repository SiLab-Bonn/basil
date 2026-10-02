SCRIPT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
REPO_ROOT := $(abspath $(SCRIPT_DIR)/../..)
BUILD_DIR := $(REPO_ROOT)/build/fpga/MMC3
VIVADO ?= vivado

.PHONY: all synthesize project check clean
all: synthesize

synthesize:
	mkdir -p "$(BUILD_DIR)"
	cd "$(BUILD_DIR)" && $(VIVADO) -mode batch -notrace -source "$(SCRIPT_DIR)/run.tcl"

project:
	mkdir -p "$(BUILD_DIR)"
	cd "$(BUILD_DIR)" && $(VIVADO) -mode batch -notrace -source "$(SCRIPT_DIR)/run.tcl" -tclargs --project-only

check:
	tclsh "$(SCRIPT_DIR)/run.tcl" --check

clean:
	rm -rf "$(BUILD_DIR)"
