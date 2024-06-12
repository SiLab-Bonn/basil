module word_broker  #(
	parameter state_bits = 4,
	parameter counter_bits = 10,
	parameter encodebits = 7,
	parameter fine_time_bits = 2
)(
	input wire CLK,
	input wire [counter_bits-1:0] corse_count,
	input wire [fine_time_bits-1:0] fine_time,
	input wire [encodebits-1:0] tdl_time,
	input wire [state_bits-1:0] tdc_state,
	input wire en_write_timestamp,
	input wire en_no_trig_err, // This is not implemented as there are no trig errors in this design. The tdl expects bubble errors.
	input wire [15:0] signal_timestamp,
	input wire [15:0] reset_timestamp,

	output reg out_valid,
	output reg [32-1:0] out_word
);




localparam DATA_IDENTIFIER = 4'b0100;
localparam word_type_bits = 3; 

// Word type codes
localparam [word_type_bits-1:0] TRIGGERED_WORD = 0;
localparam [word_type_bits-1:0] RISING_WORD = 1;
localparam [word_type_bits-1:0] FALLING_WORD = 2;
localparam [word_type_bits-1:0] TIMESTAMP_WORD = 3;
localparam [word_type_bits-1:0] CALIB_WORD = 4;
localparam [word_type_bits-1:0] MISS_WORD = 5;
localparam [word_type_bits-1:0] RESET_WORD = 6;

// function [state_bits-1:0] int_to_gray;
// 	input [state_bits-1:0] int;
// 	begin
// 		int_to_gray = int ^ (int >> 1);
// 	end
// endfunction
// TDC states
localparam [state_bits-1:0] IDLE = 0;
localparam [state_bits-1:0] IDLE_TRIG = 1;
localparam [state_bits-1:0] TRIGGERED = 2;
localparam [state_bits-1:0] RIS_EDGE = 3;
localparam [state_bits-1:0] FAL_EDGE = 4;
localparam [state_bits-1:0] FIFO_FULL = 5;
localparam [state_bits-1:0] MISSED = 6;
localparam [state_bits-1:0] CALIB = 7;
localparam [state_bits-1:0] CALIB_HIT = 8;
localparam [state_bits-1:0] RESET = 9;


wire counter_overflow;
assign counter_overflow = corse_count[counter_bits-1];
wire [15:0] corse_time;
assign corse_time = corse_count[counter_bits-1:0];


reg [state_bits-1:0] previous_state;
always @(posedge CLK) begin
	previous_state <= tdc_state;
end

always @(posedge CLK) begin
	case({previous_state, tdc_state})
		{IDLE_TRIG, TRIGGERED}: begin
			out_valid <= 1;
			out_word <= {DATA_IDENTIFIER, TRIGGERED_WORD, corse_time, fine_time, tdl_time};
		end
		{IDLE, RIS_EDGE}: begin
			out_valid <= 1;
			out_word <= {DATA_IDENTIFIER, RISING_WORD, corse_time, fine_time, tdl_time};
		end
		{TRIGGERED,RIS_EDGE}: begin
			out_valid <= 1;
			if (~counter_overflow)
				out_word <= {DATA_IDENTIFIER, RISING_WORD, corse_time, fine_time, tdl_time};
			else 
				out_word <= {DATA_IDENTIFIER, RISING_WORD, {(counter_bits-1){1'b1}}, {fine_time_bits{1'b1}}, tdl_time};
		end
		{RIS_EDGE,FAL_EDGE}: begin
			out_valid <= 1;
			if (~counter_overflow)
				out_word <= {DATA_IDENTIFIER, FALLING_WORD, corse_time, fine_time, tdl_time};
			else
				out_word <= {DATA_IDENTIFIER, FALLING_WORD, {(counter_bits-1){1'b1}}, {fine_time_bits{1'b1}}, tdl_time};
		end
		{FAL_EDGE,IDLE}: begin
			if(en_write_timestamp) begin
				out_valid <= 1;
				out_word <= {DATA_IDENTIFIER, TIMESTAMP_WORD,  signal_timestamp, 9'b0};
			end
			else begin
				out_valid <= 0;
				out_word <= 0;
			end
		end
		{FAL_EDGE,IDLE_TRIG}: begin
			if(en_write_timestamp) begin
				out_valid <= 1;
				out_word <= {DATA_IDENTIFIER, TIMESTAMP_WORD,  signal_timestamp, 9'b0};
			end
			else begin
				out_valid <= 0;
				out_word <= 0;
			end
		end
		{MISSED, IDLE}: begin
			out_valid <= 1;
			out_word <= {DATA_IDENTIFIER, MISS_WORD, 25'b0};
		end
		{RESET, IDLE}: begin
			out_valid <= 1;
			out_word <= {DATA_IDENTIFIER, RESET_WORD, reset_timestamp, 9'b0};
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

endmodule
