// /**
// * ------------------------------------------------------------
// * Copyright (c) All rights reserved
// * SiLab, Institute of Physics, University of Bonn
//
// * ------------------------------------------------------------
// */

`timescale 1ps / 1ps

`include "utils/clock_multiplier.v"
`include "utils/clock_divider.v"

`include "seq_gen/seq_gen.v"
`include "seq_gen/seq_gen_core.v"
`include "utils/ramb_8_to_n.v"

`include "tdl_tdc/tdc.v"

`include "bram_fifo/bram_fifo_core.v"
`include "bram_fifo/bram_fifo.v"

`include "utils/bus_to_ip.v"


module tb (
	input wire           BUS_CLK,
	input wire           BUS_RST,
	input wire   [31:0]  BUS_ADD,
	inout wire   [31:0]  BUS_DATA,
	input wire           BUS_RD,
	input wire           BUS_WR,
	output wire          BUS_BYTE_ACCESS
);

localparam SEQ_GEN_BASEADDR = 32'h0000;
localparam SEQ_GEN_HIGHADDR = 32'h8000 - 1;

localparam TDC_BASEADDR = 32'h8000;
localparam TDC_HIGHADDR = 32'h8100 - 1;

localparam FIFO_BASEADDR = 32'h8300;
localparam FIFO_HIGHADDR = 32'h8400 - 1;

localparam FIFO_BASEADDR_DATA = 32'h6000_0000;
localparam FIFO_HIGHADDR_DATA = 32'h7000_0000 - 1;

localparam ABUSWIDTH = 32;
assign BUS_BYTE_ACCESS = BUS_ADD < 32'h6000_0000 ? 1'b1 : 1'b0;

wire TDC_TRIGGER_IN, TDC_ARM, TDC_EXT_EN;
wire [2:0] TDC_IN;
wire [3:0] NOT_CONNECTED;
wire [7:0] SEQ_OUT;
assign NOT_CONNECTED = SEQ_OUT[7:4];
assign TDC_TRIGGER_IN = SEQ_OUT[0];
// Use same TDC for all TDC modules
assign TDC_IN[0] = SEQ_OUT[1];
assign TDC_IN[1] = SEQ_OUT[1];
assign TDC_IN[2] = SEQ_OUT[1];
assign TDC_ARM = SEQ_OUT[2];
assign TDC_EXT_EN = SEQ_OUT[3];

wire  CLK_160, CLK_480, CLK_160_TO_DCM,

DCM #(
	.CLKFX_MULTIPLY(20),
	.CLKFX_DIVIDE(3)
) i_dcm_1 (
	.CLK0(), .CLK180(), .CLK270(), .CLK2X(), .CLK2X180(), .CLK90(),
	.CLKDV(), .CLKFX(CLK_160_TO_DCM), .CLKFX180(), .LOCKED(), .PSDONE(), .STATUS(),
	.CLKFB(1'b0), .CLKIN(BUS_CLK), .DSSEN(1'b0), .PSCLK(1'b0), .PSEN(1'b0), .PSINCDEC(1'b0), .RST(1'b0)
);

DCM #(
	.CLKFX_MULTIPLY(3),
	.CLKFX_DIVIDE(1),
	.CLKDV_DIVIDE(1)
) i_dcm_2 (
	.CLK0(), .CLK180(), .CLK270(), .CLK2X(), .CLK2X180(), .CLK90(),
	.CLKDV(CLK_160), .CLKFX(CLK_480), .CLKFX180(), .LOCKED(), .PSDONE(), .STATUS(),
	.CLKFB(1'b0), .CLKIN(CLK_160_TO_DCM), .DSSEN(1'b0), .PSCLK(1'b0), .PSEN(1'b0), .PSINCDEC(1'b0), .RST(1'b0)
);


seq_gen #(
	.BASEADDR(SEQ_GEN_BASEADDR),
	.HIGHADDR(SEQ_GEN_HIGHADDR),
	.ABUSWIDTH(ABUSWIDTH),
	.MEM_BYTES(8 * 8 * 1024),
	.OUT_BITS(8)
) i_seq_gen (
	.BUS_CLK(BUS_CLK),
	.BUS_RST(BUS_RST),
	.BUS_ADD(BUS_ADD),
	.BUS_DATA(BUS_DATA[7:0]),
	.BUS_RD(BUS_RD),
	.BUS_WR(BUS_WR),
	.SEQ_EXT_START(),
	.SEQ_CLK(CLK_480),
	.SEQ_OUT(SEQ_OUT)
);


wire [2:0] TDC_FIFO_EMPTY;
wire [31:0] TDC_FIFO_DATA [2:0];
wire [2:0] TDC_FIFO_READ;
// First TDC module: creates fast sampled trigger signal to use it for other TDC modules.
tdc #(
.BASEADDR(TDC_BASEADDR),
.HIGHADDR(TDC_HIGHADDR),
.ABUSWIDTH(ABUSWIDTH),
.DATA_IDENTIFIER(4'b0000)
) i_tdc (
	.BUS_CLK(BUS_CLK),
	.bus_add(BUS_ADD),
	.bus_data(BUS_DATA[7:0]),
	.bus_rst(BUS_RST),
	.bus_wr(BUS_WR),
	.bus_rd(BUS_RD),

	.CLK480(CLK480),
	.CLK160(CLK160),
	.CALIB_CLK(CLK125RX),
	.tdc_in(TDC_IN[0]),
	.trig_in(TDC_TRIGGER_IN),

	.timestamp(16'd42),
	.ext_en(TDC_EXT_EN),
	.arm_tdc(TDC_ARM),
	.fifo_read(TDC_FIFO_READ[0]),

	.fifo_empty(TDC_FIFO_EMPTY[0]),
	.fifo_data(TDC_FIFO_DATA[0])
);
// Additional TDC modules: Use the fast sampled trigger signal from first TDC module.
genvar i;
generate
	for (i = 1; i < 3; i = i + 1) begin: tdc_gen
		tdc #(
			.BASEADDR(TDC_BASEADDR + 32'h0100*i),
			.HIGHADDR(TDC_HIGHADDR + 32'h0100*i),
			.ABUSWIDTH(ABUSWIDTH),
			.DATA_IDENTIFIER(4'b0000)
		) i_tdc (
			.BUS_CLK(BUS_CLK),
			.bus_add(BUS_ADD),
			.bus_data(BUS_DATA[7:0]),
			.bus_rst(BUS_RST),
			.bus_wr(BUS_WR),
			.bus_rd(BUS_RD),

			.CLK480(CLK480),
			.CLK160(CLK160),
			.CALIB_CLK(CLK125RX),
			.tdc_in(TDC_IN[i]),
			.trig_in(TDC_TRIGGER_IN),

			.timestamp(16'd42),
			.ext_en(TDC_EXT_EN),
			.arm_tdc(TDC_ARM),
			.fifo_read(TDC_FIFO_READ[i]),

			.fifo_empty(TDC_FIFO_EMPTY[i]),
			.fifo_data(TDC_FIFO_DATA[i])
		);
	end
endgenerate


wire FIFO_READ [2:0], FIFO_EMPTY [2:0], FIFO_FULL [2:0];
wire [31:0] FIFO_DATA [2:0];
genvar k;
generate
	for (k = 0; k < 3; k = k + 1) begin: bram_fifo_gen
		assign FIFO_DATA[k] = TDC_FIFO_DATA[k];
		assign FIFO_EMPTY[k] = TDC_FIFO_EMPTY[k];
		assign TDC_FIFO_READ[k] = FIFO_READ[k];

		bram_fifo #(
			.BASEADDR(FIFO_BASEADDR + 32'h0100*k),
			.HIGHADDR(FIFO_HIGHADDR + 32'h0100*k),
			.BASEADDR_DATA(FIFO_BASEADDR_DATA + 32'h1000_0000*k),
			.HIGHADDR_DATA(FIFO_HIGHADDR_DATA + 32'h1000_0000*k),
			.ABUSWIDTH(ABUSWIDTH)
		) i_out_fifo (
			.BUS_CLK(BUS_CLK),
			.BUS_RST(BUS_RST),
			.BUS_ADD(BUS_ADD),
			.BUS_DATA(BUS_DATA),
			.BUS_RD(BUS_RD),
			.BUS_WR(BUS_WR),

			.FIFO_READ_NEXT_OUT(FIFO_READ[k]),
			.FIFO_EMPTY_IN(FIFO_EMPTY[k]),
			.FIFO_DATA(FIFO_DATA[k]),

			.FIFO_NOT_EMPTY(),
			.FIFO_FULL(FIFO_FULL[k]),
			.FIFO_NEAR_FULL(),
			.FIFO_READ_ERROR()
		);
	end
endgenerate


initial begin
	$dumpfile("tdc.vcd");
	$dumpvars(0);
end

endmodule
