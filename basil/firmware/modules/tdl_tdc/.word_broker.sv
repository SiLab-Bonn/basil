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
	output reg [32-1:0] out_word
);


localparam DATA_IDENTIFIER = 4'b0100;
localparam WORD_TYPE_BITS = 3; // TODO: This parameter can't be changed

// Word type codes
localparam TRIGGERED_WORD = 3'd0;
localparam RISING_WORD = 3'd1;
localparam FALLING_WORD = 3'd2;
localparam TIMESTAMP_WORD = 3'd3;
localparam COUNTER_OVERFLOW_WORD = 3'd4;
localparam CALIB_WORD = 3'd5;
localparam MISS_WORD = 3'd6;
localparam RESET_WORD = 3'd7;


parameter state_bits = 4;
parameter counter_bits = 10;
parameter encodebits = 7;
parameter fine_time_bits = 2;

reg [state_bits-1:0] previous_state;
always @(posedge CLK) begin
	previous_state <= tdc_state;
end

always @(posedge CLK) begin
	case({previous_state, tdc_state})
		{IDLE, TRIGGERED}: begin
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
			out_valid <= 1;
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

endmodule
