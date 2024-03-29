module word_broker  (
	input wire CLK,
	input wire [counter_bits-1:0] corse_time,
	input wire [fine_time_bits-1:0] fine_time,
	input wire [encodebits-1:0] tdl_time,
	input wire [state_bits-1:0] tdc_state,
	input wire en_write_timestamp,
	input wire en_write_trigger_distance,
	input wire en_no_trig_err, // This is not implemented as there are no trig errors in this design. The tdl expects bubble errors.
	input wire [15:0] timestamp,

	output reg out_valid,
	output reg [32-1:0] out_word,
);


localparam DATA_IDENTIFIER = 4'b0100;
localparam word_type_bits = 3;

// Word type identifier
localparam TRIGGERED_WORD = word_type_bits'd0;
localparam  RISING_WORD = word_type_bits'd1;
localparam FALLING_WORD = word_type_bits'd2;
localparam TIMESTAMP_WORD = word_type_bits'd3;
localparam COUNTER_OVERFLOW_WORD = word_type_bits'd4;
localparam CALBI_WORD = word_type_bits'd5;
localparam MISS_WORD = word_type_bits'd6;
localparam RESET_WORD = word_type_bits'd7;

// TDC states
localparam IDLE = 0;
localparam TRIGGERED = 1;
localparam RIS_EDGE = 2;
localparam FAL_EDGE = 3;
localparam COUNTER_OVERFLOW = 4;
localparam FIFO_FULL = 5;
localparam MISSED = 6;
localparam CALIB = 7;
localparam CALIB_HIT = 8;
localparam RESET = 9;



parameter state_bits = 4;
parameter counter_bits;
parameter encodebits = 7;
parameter fine_time_bits;

reg [state_bits-1:0] previous_state;
always @(posedge CLK) begin
	previous_state <= tdc_state;
end

always @(posedge CLK) begin
	case({previous_state, tdc_state})
		{IDLE,TRIGGERED}: begin
			if(en_write_trigger_distance) begin
				out_valid <= 1;
				out_word <= {DATA_IDENTIFIER, TRIGGERED_WORD, corse_time, fine_time, tdl_time};
			end
			else begin
				out_valid <= 0;
				out_word <= 0;
			end
		end
		{TRIGGERED,RIS_EDGE}: begin
			out_valid <= 1;
			out_word <= {DATA_IDENTIFIER, RISING_WORD, corse_time, fine_time, tdl_time};
		end
		{RIS_EDGE,FAL_EDGE}: begin
			out_valid <= 1;
			out_word <= {DATA_IDENTIFIER, FALLING_WORD, corse_time, fine_time, tdl_time};
		end
		{FAL_EDGE,IDLE}: begin
			if(en_write_timestamp) begin
				out_valid <= 1;
				out_word <= {DATA_IDENTIFIER, TIMESTAMP_WORD,  timestamp, 9'b0};
			end
			else begin
				out_valid <= 0;
				out_word <= 0;
			end
		end
		{COUNTER_OVERFLOW, IDLE}: begin
			out_valid <= 1;
			out_word <= {DATA_IDENTIFIER, COUNTER_OVERFLOW_WORD, 25'b0};
		end
		{MISSED, IDLE}: begin
			out_valid <= 1;
			out_word <= {DATA_IDENTIFIER, MISS_WORD, 25'b0};
		end
		{RESET, IDLE}: begin
			out_valid <=;
			out_word <= {DATA_IDENTIFIER, RESET_WORD, 25'b0};
		end
		{CALIB, CALIB_HIT}: begin
			out_valid <= 1;
			out_word <= {DATA_IDENTIFIER, CALIB_WORD,16'b0,  fine_time, tdl_time};
		end
		default: begin
			out_valid <= 0;
			out_word <= 0;
		end
	endcase
end

