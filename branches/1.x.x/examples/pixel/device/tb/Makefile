
PWD=$(shell pwd)

BASIL = ../../../../../../basil
XILINX_INSTALL = /c/Xilinx/14.7/ISE_DS
XILINX_SRC = $(XILINX_INSTALL)/ISE/verilog/src
	
VERILOG_SOURCES = \
				  $(BASIL)/trunk/device/modules/utils/*.v \
				  $(BASIL)/trunk/device/modules/tdc_s3/*.v \
				  $(BASIL)/trunk/device/modules/sram_fifo/*.v \
				  $(BASIL)/trunk/device/modules/fast_spi_rx/*.v \
				  $(BASIL)/trunk/device/modules/seq_gen/seq_gen_core.v \
				  $(BASIL)/trunk/device/modules/seq_gen/seq_gen.v \
				  $(BASIL)/trunk/device/modules/rrp_arbiter/*.v \
				  $(BASIL)/trunk/device/modules/tb/silbusb.v \
				  pixel_tb.v \
				  $(XILINX_SRC)/unisims/IFDDRRSE.v \
				  $(XILINX_SRC)/unisims/BUFG.v \
				  $(XILINX_SRC)/unisims/OFDDRRSE.v \
				  $(XILINX_SRC)/unisims/DCM.v \
				  $(XILINX_SRC)/unisims/FDDRRSE.v \
				  $(XILINX_SRC)/unisims/FDRSE.v \
				  $(XILINX_SRC)/unisims/IBUF.v \
				  $(XILINX_SRC)/unisims/OBUF.v \
				  $(XILINX_SRC)/glbl.v \
				  ../src/*.v 

comp:
	echo $(XILINX_SRC)
	iverilog -D_IVERILOG_ -I$(BASIL)/trunk/device/modules/utils -I$(BASIL)/trunk/device/modules/tb -o output.vvp  $(VERILOG_SOURCES)
	
sim:
	vvp output.vvp
	
show:
	gtkwave uut.vcd

clean:
	rm -f *.vvp; rm -rf *.vcd
 


