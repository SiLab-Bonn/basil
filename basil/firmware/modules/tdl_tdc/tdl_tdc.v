/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
 
`include "tdl_tdc/sw_interface.v"
`include "tdl_tdc/tdl_tdc_core.v"

module tdl_tdc #(
	parameter BASEADDR = 32'h0000,
	parameter HIGHADDR = 32'h0000,
	parameter ABUSWIDTH = 32,
	parameter DATA_IDENTIFIER = 4'b0100
) (
	input wire BUS_CLK,
	input wire [ABUSWIDTH-1:0] bus_add,
	inout wire [7:0] bus_data,
	input wire bus_rst,
	input wire bus_wr,
	input wire bus_rd,

	input wire CLK480,
	input wire CLK160,
	input wire CALIB_CLK,
	input wire tdc_in,
	input wire trig_in,

	input wire [15:0] timestamp,
	input wire arm_tdc,
	input wire ext_en,

	input wire fifo_read,
	output wire fifo_empty,
	output wire [31:0] fifo_data

);

localparam VERSION = 8'b00000010;

wire inv_trig_in;
wire inv_sig_in;

// CLK synchronous enable, arm and reset
wire en_tdc, arm_flag, rst;
// configuration register signals
wire en_arm_mode, en_calib_mode, en_write_trigger_distance, en_write_timestamp, en_no_trig_err;


wire [31:0] event_count;
wire [7:0] tdc_miss_cnt;
reg [7:0] fifo_over_cnt;
wire cdc_fifo_write;
wire [32-1:0] word_to_cdc_fifo;

tdc_core #(
	.DATA_IDENTIFIER(DATA_IDENTIFIER)
) i_tdc_core (
	.CLK_FAST(CLK480),
	.CLK(CLK160),
	.CALIB_CLK(CALIB_CLK),
	.rst(rst),
	.sig_in(inv_sig_in ? ~tdc_in : tdc_in),
	.trig_in(inv_trig_in ? ~trig_in : trig_in),
	.timestamp(timestamp),
	.en(en_tdc),
	.arm_flag(arm_flag),
	.en_write_timestamp(en_write_timestamp),
	.en_arm_mode(en_arm_mode),
	.en_write_trigger_distance(en_write_trigger_distance),
	.en_calib_mode(en_calib_mode),
	.en_no_trig_err(en_no_trig_err),

	.out_valid(cdc_fifo_write),
	.out_word(word_to_cdc_fifo),
	.tdc_miss_cnt(tdc_miss_cnt),
	.event_cnt(event_count)
);

// Now we need to transfer clock domains to Bus
wire cdc_fifo_empty;
wire cdc_fifo_full;
wire [32-1:0] cdc_data_out;
wire generic_fifo_full;
wire bus_clk_rst, bus_clk_rst_long;
reg [2:0] bus_clk_rst_counter = 0;
// The syncfifo somehow needs a longer reset signal for the read reset. In
// simulation, it tristates if only a flag is set for a single BUS_CLK cycle.
always @(posedge BUS_CLK) begin
	if (bus_clk_rst)
		bus_clk_rst_counter <= 3'b111;
	else if (bus_clk_rst_counter != 0)
		bus_clk_rst_counter <= bus_clk_rst_counter - 1;
end
assign bus_clk_rst_long = |bus_clk_rst_counter;

cdc_syncfifo #(.DSIZE(32), .ASIZE(2)) clock_sync_fifo (
	.wdata(word_to_cdc_fifo),
	.wclk(CLK160),
	.winc(cdc_fifo_write),
	.wrst(rst),
	.rclk(BUS_CLK),
	.rrst(bus_clk_rst_long),
	.rinc(!generic_fifo_full),

	.wfull(cdc_fifo_full),
	.rempty(cdc_fifo_empty),
	.rdata(cdc_data_out)
);

always @(posedge CLK160) begin
	if (rst)
		fifo_over_cnt <= 0;
	else if (cdc_fifo_full && cdc_fifo_write && (fifo_over_cnt < 255))
		fifo_over_cnt <= fifo_over_cnt + 1;
	else
		fifo_over_cnt <= fifo_over_cnt;
end

gerneric_fifo #(
	.DATA_SIZE(32),
	.DEPTH(512)
) fifo_i (
	.clk(BUS_CLK),
	.reset(bus_clk_rst),
	.write(!cdc_fifo_empty),
	.read(fifo_read),
	.data_in(cdc_data_out),

	.full(generic_fifo_full),
	.empty(fifo_empty),
	.data_out(fifo_data[31:0]),
	.size()
);

tdc_sw_interface #(
	.VERSION(VERSION),
	.BASEADDR(BASEADDR),
	.HIGHADDR(HIGHADDR),
	.ABUSWIDTH(ABUSWIDTH)
) i_tdc_sw_interface (
	.BUS_CLK(BUS_CLK),
	.CLK(CLK160),
	.bus_wr(bus_wr),
	.bus_rd(bus_rd),
	.bus_rst(bus_rst),
	.ext_en(ext_en),
	.ext_arm(arm_tdc),
	.bus_data(bus_data),
	.bus_add(bus_add),
	.event_count(event_count),
	.fifo_lost_data_cnt(fifo_over_cnt),
	.tdc_miss_cnt(tdc_miss_cnt),

	.tdc_enabled(en_tdc),
	.tdc_rst(rst),
	.bus_clk_rst(bus_clk_rst),
	.arm_flag(arm_flag),
	.en_write_timestamp(en_write_timestamp),
	.en_arm(en_arm_mode),
	.en_trig_distance_mode(en_write_trigger_distance),
	.en_calib_mode(en_calib_mode),
	.en_no_trig_err(en_no_trig_err),
	.en_inv_trig_in(inv_trig_in),
	.en_inv_sig_in(inv_sig_in)
);

endmodule
