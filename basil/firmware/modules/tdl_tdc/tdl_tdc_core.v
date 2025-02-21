/**
 * ------------------------------------------------------------
 * Copyright (c) All rights reserved
 * SiLab, Institute of Physics, University of Bonn
 * ------------------------------------------------------------
 */
 
`include "tdl_tdc/tdl_supersampler.v"
`include "tdl_tdc/counter/slimfast_multioption_counter.v"
`include "tdl_tdc/controller.v"
`include "tdl_tdc/priority_encoder.v"
`include "tdl_tdc/word_broker.v"
`include "tdl_tdc/utils/delay_n.v"


module tdc_core #(
	parameter DATA_IDENTIFIER = 4'b0100
)(
	// All inputs should be synchronous to CLK.
	input wire CLK_FAST,
	input wire CLK,
	input wire CALIB_CLK,
	input wire sig_in,
	input wire trig_in,
	input wire en,
	input wire rst,
	input wire arm_flag,
	input wire en_write_timestamp,
	input wire en_arm_mode,
	input wire en_write_trigger_distance,
	input wire en_calib_mode,
	input wire en_no_trig_err,
	input wire [15:0] timestamp,

	output wire [31:0] out_word,
	output wire out_valid,
	output wire [7:0] tdc_miss_cnt,
	output wire [31:0] event_cnt
);



localparam dlyline_bits = 96; // TODO: should this be a localparam?
localparam clk_ratio = 3;
// The following numbers of bits should add up to 33, as the bus is 32 bit and
// there is a one bit counter overflow flag
localparam corsebits = 17; // corse counter width, one bit of which is overflow flag.
localparam encodebits = 7; // fine, pure tdl precision
localparam fine_time_bits = 2; // We need that clk_ratio <= 2^fine_time_bits
localparam state_bits = 4;
localparam word_type_bits = 3; // TODO: this isn't yet parametric



// corse counter.
wire [corsebits-1:0] corse_count;
wire counter_count, counter_reset;
// TODO: should clip_reset be set?
slimfast_multioption_counter #(.clip_count(0), .clip_reset(1), .outputwidth(corsebits), .size(corsebits-1) ) corse_counter (
.countClock(CLK),
.count(counter_count && ~corse_count[corsebits-1]),
.reset(counter_reset),
.countout(corse_count));

// TLU timestamp sampling
reg [15:0] signal_timestamp;
reg [15:0] reset_timestamp;
always @(posedge counter_count) begin
	signal_timestamp <= timestamp;
end
always @(posedge rst) begin
	reset_timestamp <= timestamp;
end

// Test signal generator
wire sig_calib;
clock_divider #(.DIVISOR(14)) calib_sig_gen (
	.CLK(CALIB_CLK),
	.RESET(1'b0),
	.CE(),
	.CLOCK(sig_calib)
);


// Input mux addresses for more verbose code
// For 4 inputs, 2 bits are sufficient
localparam input_mux_bits = 2;
// These need to be in sync with the controller
localparam TRIG_IN = 0;
localparam SIG_IN = 1;
localparam SIG_IN_B = 2;
localparam CALIB_OSC = 3;

// Input mux
(* mark_debug = "true" *)
reg tdl_input;
(* mark_debug = "true" *)
wire [input_mux_bits-1:0] input_mux_addr;
// The mux address that the controller computes might contain glitches which
// this buffer removes
reg [input_mux_bits-1:0] input_mux_addr_buf;
always @ (posedge CLK) 
	input_mux_addr_buf <= input_mux_addr;
always @(*) begin
	case(input_mux_addr_buf)
		TRIG_IN: tdl_input <= trig_in;
		SIG_IN: tdl_input <= sig_in;
		SIG_IN_B: tdl_input <= ~sig_in;
		CALIB_OSC: tdl_input <= sig_calib;
	endcase
end

(* mark_debug = "true" *)
wire [dlyline_bits-1:0] selected_sample;
wire [1:0] hit_status;
wire [fine_time_bits -1:0] fine_time;
tdl_and_detector #(.clk_ratio(3), .fine_time_bits(fine_time_bits)) i_tdl(
	.CLK_FAST(CLK_FAST),
	.CLK_SLOW(CLK),
	.sig_in(tdl_input),

	.sample(selected_sample),
	.fine_time(fine_time),
	.hit_status(hit_status)
);

(* mark_debug = "true" *)
wire [state_bits - 1 : 0] tdc_state;
controller #(.state_bits(state_bits), .mux_bits(input_mux_bits)) i_controller(
	.CLK(CLK),
	.rst(rst),
	.hit_status(hit_status),
	.tdl_status(tdl_input),
	.arm_flag(arm_flag),
	.en(en),
	.en_arm_mode(en_arm_mode),
	.en_calib_mode(en_calib_mode),
	.en_write_trigger_distance(en_write_trigger_distance),

	.counter_count(counter_count),
	.counter_reset(counter_reset),
	.tdc_state(tdc_state),
	.miss_cnt(tdc_miss_cnt),
	.event_cnt(event_cnt),
	.mux_addr(input_mux_addr)
);

(* mark_debug = "true" *)
wire [encodebits-1 :0] tdl_time;
priority_encoder encoder (
	.CLK(CLK),
	.sample(selected_sample),
	.position_out(tdl_time));

// The previous module needs n cycles to do the computation so the remaining data is
// delayed by the same amount.
(* mark_debug = "true" *)
wire [fine_time_bits-1:0] fine_time_delayed;
(* mark_debug = "true" *)
wire [state_bits-1:0] tdc_state_delayed;
(* mark_debug = "true" *)
wire [corsebits-1:0] corse_time_delayed; 


// The state is actually one cycle behind the selected sample, so we delay it
// less.
delay_n #(.n(4-1), .width(state_bits)) state_pipe(
	.CLK(CLK),
	.signal(tdc_state),
	.delayed_signal(tdc_state_delayed)
);
// Since the state machine controls the counter, it is also one cycle behind
// the selected sample.
delay_n #(.n(4-1), .width(corsebits)) corse_time_pipe(
	.CLK(CLK),
	.signal(corse_count[corsebits-1:0]), // We don't need the overflow bit
	.delayed_signal(corse_time_delayed)
);

delay_n #(.n(4), .width(fine_time_bits)) fine_time_pipe(
	.CLK(CLK),
	.signal(fine_time),
	.delayed_signal(fine_time_delayed)
);

// This module assembles the data output based on the tdc state transitions
word_broker #(
	.DATA_IDENTIFIER(DATA_IDENTIFIER),
	.state_bits(state_bits),
	.counter_bits(corsebits),
	.fine_time_bits(fine_time_bits),
	.encodebits(encodebits)
)  i_broker (
	.CLK(CLK),
	.corse_count(corse_time_delayed), 
	.fine_time(fine_time_delayed),
	.tdl_time(tdl_time),
	.tdc_state(tdc_state_delayed),
	.en_write_timestamp(en_write_timestamp),
	.en_no_trig_err(en_no_trig_err),
	.signal_timestamp(signal_timestamp),
	.reset_timestamp(reset_timestamp),

	.out_valid(out_valid),
	.out_word(out_word)
);
endmodule
