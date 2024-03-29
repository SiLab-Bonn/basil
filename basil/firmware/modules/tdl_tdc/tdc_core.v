module tdc_core(
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
	input wire FIFO_READ,
	input wire [15:0] timestamp,

	output reg [1 + corsebits+encodebits+2-1:0] FIFO_DATA,
	output reg FIFO_EMPTY,
	output reg [7:0] tdc_miss_cnt,
	output reg [7:0] fifo_over_cnt,
	output reg [31:0] event_cnt,
);



localparam corsebits = 17; // corse counter width, one bit of which is overflow flag.
localparam encodebits = 7; // fine, pure tdl precision
localparam fine_time_bits = 2; // We need that clk_ratio <= 2^fine_time_bits
localparam state_bits = 4;
localparam input_mux_bits = 2;

// corse counter.
wire [corsebits-1:0] corse_count;
wire counter_count, counter_reset;
// TODO: should clip_reset be set?
slimfast_multioption_counter #(.clip_count(0), .clip_reset(1), .outputwidth(corsebits), .size(corsebits-1) ) corse_counter (
.countClock(CLK),
.count(counter_count),
.reset(counter_reset),
.countout(corse_count));

// Test signal generator
wire sig_calib;
clk_divide #(CLK_DIVISOR = 6) calib_sig_gen (
	.CLK_IN(CALIB_CLK),
	.calib_sig(sig_calib)
);


// Input mux addresses for more verbose code
// These need to be in sync with the controller
localparam TRIG_IN = 0;
localparam SIG_IN = 1;
localparam SIG_IN_B = 2;
localparam CALIB_OSC = 3;

// Input mux
reg tdl_input
(* mark_debug = "true")
wire [input_mux_bits-1:0] input_mux_addr;
always @(*) begin
	case(input_mux_addr)
		TRIG_IN: tdl_input <= trig_in;
		SIG_IN: tdl_input <= sig_in;
		SIG_IN_B: tdl_input <= ~sig_in;
		CALIB_OSC: tdl_input <= sig_calib;
	endcase
end

(* mark_debug = "true")
wire [dlyline_bits-1:0] selected_sample;
wire [1:0] hit_status;
wire [fine_time_bits -1:0] fine_time;
tdl_and_detector #(.clock_ratio(4), .encodebits(encodebits), .fine_time_bits(fine_time_bits)) i_tdl(
	.CLK_FAST(CLK_FAST),
	.CLK_SLOW(CLK),
	.sig_in(tdl_input),

	.sample(selected_sample),
	.fine_time(fine_time),
	.hit_status(hit_status),
);

(* mark_debug = "true")
wire [state_bits - 1 : 0] tdc_state;
controller #(.state_bits(state_bits), .mux_bits(input_mux_bits)) i_controller(
	.CLK(CLK),
	.rst(rst),
	.hit_status(hit_status),
	.cdc_fifo_full(cdc_fifo_full),
	.arm_flag(arm_flag),
	.en(en),
	.en_arm_mode(en_arm_mode),
	.en_calib_mode(en_calib_mode),
	.counter_overflow(),

	.counter_count(counter_count),
	.counter_reset(counter_reset),
	.tdc_state(tdc_state),
	.miss_cnt(tdc_miss_cnt),
	.event_cnt(event_cnt),
	.mux_addr(input_mux_addr)
);

localparam encodebits = 7;
wire [encodebits-1 :0] tdl_time;
priority_encoder_only encoder (
	.CLK(CLK),
	.sample(selected_sample),
	.position_out(tdl_time));

// The previous module needs n cycles to do the computation so the remaining data is
// delayed by the same amount.
wire [fine_time_bits-1:0] fine_time_delayed;
wire [state_bits-1:0] tdc_state_delayed;

delay_n #(.n(4), .width(state_bits)) state_pipe(
	.CLK(CLK),
	.signal(tdc_state),
	.delayed_signal(tdc_state_delayed)
);

delay_n #(.n(4), .width(fine_time_bits)) fine_time_pipe(
	.CLK(CLK),
	.signal(fine_time),
	.delayed_signal(fine_time_delayed)
);

// This module assembles the data output based on the tdc state transitions
wire cdc_fifo_write;
wire [32-1:0] word_to_cdc_fifo;
word_broker #(.state_bits(state_bits),
	.rst(rst),
	.counter_bits(corsebits-1),
	.fine_time_bits(fine_time_bits),
	.encodebits(encodebits)
)  i_broker (
	.CLK(CLK),
	.corse_time(corse_count[corsebits-2:0]), // We don't need the overflow bit
	.fine_time(fine_time_delayed),
	.tdl_time(tdl_time_delayed),
	.tdc_state(tdc_state_delayed),
	.en_write_timestamp(en_write_timestamp),
	.en_write_trigger_distance(en_write_trigger_distance),
	.en_no_trig_err(en_no_trig_err),
	.timestamp(timestamp),

	.out_valid(fifo_write),
	.out_word(word_to_fifo),
	.fifo_over_cnt(fifo_over_cnt)
);

reg [7:0] fifo_over_cnt;
always @(posedge CLK) begin
	if(rst)
		fifo_over_cnt = 0;
	else if(cdc_fifo_full && fifo_write && (fifo_over_cnt < 255))
		fifo_over_cnt = fifo_over_cnt + 1
end

// Now we need to transfer clock domains to Bus
wire cdc_fifo_empty;
wire cdc_fifo_full;
wire fifo_full;
wire [32-1:0] code_BUS;
cdc_syncfifo #(.DSIZE(32), .ASIZE(2)) clock_sync_fifo (
	.wdata(word_to_cdc_fifo),
	.wclk(CLK),
	.winc(cdc_fifo_write),
	.wrst(rst),
	.rclk(BUS_CLK),
	.rrst(1'b0),
	.rinc(!fifo_full),

	.wfull(cdc_fifo_full),
	.rempty(cdc_fifo_empty),
	.rdata(cdc_data_out)
);

gerneric_fifo #(
	.DATA_SIZE(32),
	.DEPTH(512)
) fifo_i (
	.clk(BUS_CLK),
	.reset(RST_LONG),
	.write(!cdc_fifo_empty),
	.read(FIFO_READ),
	.data_in(cdc_data_out),

	.full(fifo_full),
	.empty(FIFO_EMPTY),
	.data_out(FIFO_DATA[31:0]),
	.size()
);
