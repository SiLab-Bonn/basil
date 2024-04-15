`include "tdl_tdc/sw_interface.v"
`include "tdl_tdc/tdc_core.v"

module tdc #(
	parameter BASEADDR = 16'h0000,
	parameter HIGHADDR = 16'h0000,
	parameter ABUSWIDTH = 16,
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

localparam VERSION = 0;

wire inv_trig_in;
wire inv_sig_in;

// CLK synchronous enable, arm and reset
wire en_tdc, arm_flag, rst;
// configuration register signals
wire en_arm_mode, en_calib_mode, en_write_trigger_distance, en_write_timestamp, en_no_trig_err;


wire [31:0] event_count;
wire [7:0] tdc_miss_cnt, fifo_over_cnt;
tdc_core i_tdc_core (
	.CLK_FAST(CLK480),
	.CLK(CLK160),
	.BUS_CLK(BUS_CLK),
	.bus_rst(bus_rst),
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
	.FIFO_READ(fifo_read),


	.FIFO_DATA(fifo_data),
	.FIFO_EMPTY(fifo_empty),
	.tdc_miss_cnt(tdc_miss_cnt),
	.fifo_over_cnt(fifo_over_cnt),
	.event_cnt(event_count)
);

tdc_sw_interface #(.VERSION(VERSION),
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
