# Targets
.PHONY: all download synthesize clean

# Run the main process
all: synthesize

# Download SiTCP to the base directory
download:
	@echo "Downloading SiTCP library"
	@python -c "from basil.utils import utils; utils.get_si_tcp('..')"

# Start synthesis
synthesize: download
	@echo "Starting firmware synthesis"
	vivado -mode batch -source run.tcl -notrace

# Clean generated files
clean:
	@echo "Removing generated Vivado files"
	rm -f *.log *.jou *.str
	rm -rf designs reports output .Xil .ngc2edfcache ipcore.*
