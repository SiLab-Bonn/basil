SCRIPT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
REPO_ROOT := $(abspath $(SCRIPT_DIR)/../../../..)
BUILD_DIR := $(REPO_ROOT)/build/fpga/mio_sram_test
XTCLSH ?= xtclsh

.PHONY: all synthesize project check clean
all: synthesize

synthesize:
	mkdir -p "$(BUILD_DIR)"
	cd "$(BUILD_DIR)" && $(XTCLSH) "$(SCRIPT_DIR)/run.tcl"

project:
	mkdir -p "$(BUILD_DIR)"
	cd "$(BUILD_DIR)" && $(XTCLSH) "$(SCRIPT_DIR)/run.tcl" --project-only

check:
	tclsh "$(SCRIPT_DIR)/run.tcl" --check

clean:
	rm -rf "$(BUILD_DIR)"
